/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.action;

import std.stdio : stderr;
import std.process : spawnShell, wait;
import reloadedvibes.watcher;

alias Action = void delegate() @safe;

final class ActionWatcherClient : WatcherClient
{
    private
    {
        Action _action;
    }

    public this(Watcher w, Action action) @safe pure nothrow
    {
        super(w);
        this._action = action;
    }

    public override void notify() @safe
    {
        this._action();
        this.setNotified();
    }
}

ActionWatcherClient fromCommandLines(Watcher w, string[] commandLines)
{
    return new ActionWatcherClient(w, delegate() @trusted {
        foreach (cmd; commandLines)
        {
            try
            {
                immutable exitCode = spawnShell(cmd).wait();

                if (exitCode != 0)
                {
                    stderr.writeln("Action {" ~ cmd ~ "} failed with exit code ", exitCode);
                }
            }
            catch (Exception ex)
            {
                stderr.writeln("Action {" ~ cmd ~ "} failed: ", ex.msg);
            }
        }
    });
}
