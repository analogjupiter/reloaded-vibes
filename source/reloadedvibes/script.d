/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.script;

import std.conv : to;
import reloadedvibes.utils;

@safe pure:

string buildScript(Socket socketRV, bool quiet = false) nothrow
{
    immutable msg = ((quiet) ? buildQuietVarLine!true() : buildQuietVarLine!false());
    return "(function(){" ~ socketRV.buildURLVarLine() ~ msg ~ scriptBody ~ "})();";
}

string buildURLVarLine(Socket socketRV) nothrow
{
    return "let rvURL = 'ws://" ~ socketRV.toString ~ "/reloaded-vibes.ws';";
}

string buildQuietVarLine(bool quiet)()
{
    return "let rvQuiet = " ~ ((quiet) ? "true" : "false") ~ ";";
}

string buildScriptURL(Socket socketRV) nothrow
{
    return "http://" ~ socketRV.toString ~ "/reloaded-vibes.js";
}

string buildScriptLoaderHTML(Socket socketRV) nothrow
{
    return `<script src="` ~ socketRV.buildScriptURL() ~ `"></script>`;
}

private:

enum scriptBody = import("script.js");
