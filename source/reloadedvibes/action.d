/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.action;

import std.stdio : stderr, stdout;
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
    enum sepLine = "-------------------------------------------------------------------------------";
    enum segmentPre = "----{ ";
    enum segmentPost = " }";
    enum segmentsLength = (segmentPre.length + segmentPost.length);
    enum embeddedCMDMaxLength = 79 - segmentsLength;

    string[] sep = new string[commandLines.length];

    foreach (idx, cmd; commandLines)
    {
        if (cmd.length >= embeddedCMDMaxLength)
        {
            sep[idx] = sepLine ~ "\n" ~ cmd ~ "\n" ~ sepLine ~ "\n";
            continue;
        }

        immutable rest = embeddedCMDMaxLength - cmd.length;
        sep[idx] = segmentPre ~ cmd ~ segmentPost ~ sepLine[0 .. rest] ~ "\n";
    }

    return new ActionWatcherClient(w, delegate() @trusted {
        foreach (idx, cmd; commandLines)
        {
            try
            {
                stdout.writeln("\n", sep[idx]);
                immutable exitCode = spawnShell(cmd).wait();

                if (exitCode != 0)
                {
                    stderr.writeln("\n", sepLine,
                        "\nAction {" ~ cmd ~ "} failed with exit code ", exitCode);
                }
            }
            catch (Exception ex)
            {
                stderr.writeln("\n", sepLine, "\nAction {" ~ cmd ~ "} failed: ", ex.msg);
            }
            finally
            {
                stdout.writeln("\n");
            }
        }
    });
}
