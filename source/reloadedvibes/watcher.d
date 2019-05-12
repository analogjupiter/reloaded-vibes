/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.watcher;

import std.algorithm : remove;
import fswatch;

final class Watcher
{
    private
    {
        FileWatch*[] _fws = [];
        WatcherClient[] _cs;
    }

    public this(string[] directories)
    {
        foreach (dir; directories)
        {
            this._fws ~= new FileWatch(dir, true);
        }
    }

    private
    {
        void registerClient(WatcherClient c) @safe pure nothrow
        {
            this._cs ~= c;
        }

        void unregisterClient(WatcherClient c)
        {
            this._cs = this._cs.remove!(x => x == c);
        }

        void query()
        {
            bool notify = false;

            foreach (fw; this._fws)
            {
                if (fw.getEvents().length > 0)
                {
                    notify = true;
                }
            }

            if (notify)
            {
                foreach (c; this._cs)
                {
                    c.notify();
                }
            }
        }
    }
}

class WatcherClient
{
    private
    {
        Watcher _w;
        bool _notified = false;
    }

    public
    {
        Watcher watcher()
        {
            return this._w;
        }
    }

    public final this(Watcher w) @safe pure nothrow
    {
        this._w = w;
        this._w.registerClient(this);
    }

    public final
    {
        bool query()
        {
            if (this._notified)
            {
                this._notified = false;
                return true;
            }

            this._w.query();

            if (this._notified)
            {
                this._notified = false;
                return true;
            }

            return false;
        }

        void unregister()
        {
            this._w.unregisterClient(this);
        }
    }

    protected
    {
        void notify()
        {
            this.setNotified();
        }

        void setNotified() @safe pure nothrow @nogc
        {
            this._notified = true;
        }
    }
}

final class ActionWatcherClient : WatcherClient
{
    private
    {
        string _action;
    }

    public this(Watcher w, string action) @safe pure nothrow
    {
        super(w);
        this._action = action;
    }

    public override void notify() @safe
    {
        import std.process : spawnShell, wait;

        spawnShell(this._action).wait();
        this.setNotified();
    }
}
