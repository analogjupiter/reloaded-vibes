/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.server;

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
            sleep(dur!"msecs"(500));
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
