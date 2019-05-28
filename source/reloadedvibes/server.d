/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.server;

import std.file : exists;
import std.datetime : dur;
import std.stdio : File;
import std.string : endsWith;

import vibe.core.core;
import vibe.core.path;
import vibe.core.sync;
import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;
import vibe.http.websockets;

import reloadedvibes.script;
import reloadedvibes.utils;
import reloadedvibes.watcher;

static TaskMutex tm;

static this()
{
    tm = new TaskMutex();
}

HTTPListener registerService(Socket s, Watcher w)
{
    void index(scope HTTPServerRequest, scope HTTPServerResponse res) @safe
    {
        immutable scriptTag = s.buildScriptLoaderHTML();
        render!("index.dt", scriptTag)(res);
    }

    void script(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        immutable disableMsg = (("quiet" in req.query()) !is null);
        res.writeBody(s.buildScript(disableMsg), 200, "application/javascript; charset=utf-8");
    }

    void test(scope HTTPServerRequest, scope HTTPServerResponse res)
    {
        immutable scriptURL = s.buildScriptURL();
        render!("test.dt", scriptURL)(res);
    }

    void webSocket(scope WebSocket ws)
    {
        if (ws.connected)
        {
            auto msg = ws.receiveText();
            if (msg != "ReloadedVibes::Init;")
            {
                ws.close(WebSocketCloseReason.unsupportedData);
                return;
            }
            ws.send(msg);
        }

        WatcherClient wcl = new WatcherClient(w);

        do
        {
            synchronized (tm)
            {
                if (wcl.query())
                {
                    ws.send("ReloadedVibes::Trigger;");
                }
            }
            sleep(dur!"msecs"(200));
        }
        while (ws.connected);

        wcl.unregister();
    }

    auto router = new URLRouter();
    router.get("/", &index);
    router.get("/test", &test);
    router.get("/reloaded-vibes.js", &script);
    router.get("/reloaded-vibes.ws", handleWebSockets(&webSocket));

    auto settings = new HTTPServerSettings();
    settings.port = s.port;
    settings.bindAddresses = [s.address];
    return listenHTTP(settings, router);
}

HTTPListener registerStaticWebserver(Socket s, string docroot) @safe
{
    auto settings = new HTTPServerSettings();
    settings.port = s.port;
    settings.bindAddresses = [s.address];
    return listenHTTP(settings, serveStaticFiles(docroot));
}

HTTPListener registerStaticWebserver(Socket s, string docroot, Socket nfService) @safe
{
    immutable htd = NativePath(docroot);

    void injectingServer(scope HTTPServerRequest req, scope HTTPServerResponse res) @trusted
    {
        auto p = req.requestPath;
        string pString = p.toString;

        if (pString.endsWith("/"))
        {
            p = InetPath(pString[1 .. $] ~ "index.html");
        }
        else
        {
            p = InetPath(pString[1 .. $]);
        }

        try
        {
            p.normalize();
        }
        catch (Exception)
        {
            res.statusCode = 400;
        }

        if (p.absolute)
        {
            res.statusCode = 500;
            return;
        }

        if (!p.empty && p.bySegment.front.name == "..")
        {
            res.statusCode = 400;
            return;
        }

        NativePath file = (htd ~ p);
        immutable fileS = file.toString;
        if (fileS.exists && fileS.endsWith(".html"))
        {
            res.headers["Content-Type"] = "text/html";
            auto b = res.bodyWriter;

            auto f = File(file.toString, "r");
            ubyte[1] buffer;

            Outer: while (!f.eof)
            {
                if (f.rawRead(buffer).length == 0)
                {
                    break;
                }
                if (buffer[0] != '<')
                {
                    b.write(buffer);
                    continue;
                }

                static immutable chars = "/body>";
                ubyte[6] buffer2;

                static foreach (i, c; chars)
                {
                    if (f.rawRead(buffer2[i .. (i + 1)]).length == 0)
                    {
                        b.write(buffer);
                        b.write(buffer2[0 .. i]);
                        break Outer;
                    }
                    if (buffer2[i] != c)
                    {
                        b.write(buffer);
                        b.write(buffer2[0 .. (i + 1)]);
                        continue Outer;
                    }
                }

                // inject
                b.write(cast(ubyte[])(nfService.buildScriptLoaderHTML()));
                b.write(buffer);
                b.write(buffer2);
            }

            return;
        }

        sendFile(req, res, file);
    }

    auto settings = new HTTPServerSettings();
    settings.port = s.port;
    settings.bindAddresses = [s.address];

    return listenHTTP(settings, &injectingServer);
}

void run(HTTPListeners)(HTTPListeners listeners)
{
    scope (exit)
    {
        foreach (HTTPListener h; listeners)
        {
            h.stopListening();
        }
    }
    runEventLoop();
}
