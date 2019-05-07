/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.server;

import vibe.d;
import reloadedvibes.script;
import reloadedvibes.utils;

HTTPListener registerService(Socket s)
{
    void index(scope HTTPServerRequest, scope HTTPServerResponse res) @safe
    {
        immutable scriptTag = s.buildScriptLoaderHTML();
        render!("index.dt", scriptTag)(res);
    }

    void script(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        immutable disableMsg = (("quiet" in req.query()) !is null);
        res.writeBody(s.buildScript(disableMsg), 200, "application/javascript");
    }

    void test(scope HTTPServerRequest, scope HTTPServerResponse res)
    {
        immutable scriptURL = s.buildScriptURL();
        render!("test.dt", scriptURL)(res);
    }

    void webSocket(scope WebSocket sock)
    {
        if (sock.connected)
        {
            auto msg = sock.receiveText();
            if (msg != "ReloadedVibes::Init;")
            {
                sock.close(WebSocketCloseReason.unsupportedData);
                return;
            }
            sock.send(msg);
        }
        while (sock.connected)
        {
            auto msg = sock.receiveText();
            sock.send(msg);
        }
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
