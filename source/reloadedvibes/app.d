/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.app;

import std.algorithm : each, map;
import std.datetime : dur;
import std.file : exists, isDir;
import std.getopt;
import std.path : absolutePath, buildNormalizedPath;
import std.stdio : stdout, stderr;

import vibe.core.core : runTask, sleep;
import vibe.core.log : LogLevel, setLogLevel;
import vibe.http.server : HTTPListener;

import reloadedvibes.action;
import reloadedvibes.server;
import reloadedvibes.utils;
import reloadedvibes.watcher;

enum appName = "Reloaded Vibes";

int main(string[] args)
{
    immutable argc = args.length;

    bool optPrintVersionInfo;
    string optSocketService = "127.0.0.1:3001";
    bool optDisableService = false;
    string[] optWatchDirectories = [];
    string[] optActions = [];
    string optSocketWebServer;
    string optDocumentRootWebServer;
    bool optNoInjectWebServer;

    GetoptResult opt;

    try
    {
        // dfmt off
        opt = getopt(
            args,
            config.passThrough,
            "s|socket", "Socket to bind the notification service to", &optSocketService,
            "w|watch", "Paths to watch", &optWatchDirectories,
            "a|action", "Commandlines to execute before reloading", &optActions,
            "n|noservice", "Disable the notification service\n", &optDisableService,

            "S|webserver", "<addr>:<port>  Enables the built-in webserver", &optSocketWebServer,
            "d|htdocs", "Document root for the built-in webserver", &optDocumentRootWebServer,
            "j|noinject", "Disables script tag injection for HTML files\n", &optNoInjectWebServer,

            "version", "Display the version of this program.", &optPrintVersionInfo,
        );
       // dfmt on
    }
    catch (Exception ex)
    {
        stderr.writeln(ex.msg);
        return 1;
    }

    // -- Help?
    if ((argc == 1) || opt.helpWanted)
    {
        printHelp(args[0], opt);
        return 0;
    }
    else if (optPrintVersionInfo)
    {
        printVersionInfo();
        return 0;
    }

    debug
    {
        setLogLevel(LogLevel.diagnostic);
    }
    else
    {
        setLogLevel(LogLevel.warn);
    }

    Socket service;
    Watcher watcher;
    Socket webserver;
    HTTPListener[] listeners;
    void delegate()[] doInit;

    // -- Watcher
    if (optWatchDirectories.length == 0)
    {
        stderr.writeln("No directory to watch specified, use --watch to pass one");
        return 1;
    }

    auto watchDirectories = optWatchDirectories.map!(x => x.absolutePath.buildNormalizedPath());

    watcher = new Watcher(watchDirectories);

    // -- Service
    if (!optDisableService)
    {
        if (!tryParseSocket(optSocketService, service))
        {
            stderr.writeln("Bad service socket specified");
            return 1;
        }

        doInit ~= { listeners ~= registerService(service, watcher); };
    }
    else
    {
        optNoInjectWebServer = true;
    }

    if (optActions.length > 0)
    {
        auto awcl = fromCommandLines(watcher, optActions);

        // Initial execution
        // Since the action is usually some preprocessor or something,
        // it should also get executed on application launch
        doInit ~= {
            stdout.writeln("\nPre-executing actions...");
            awcl.notify();

            runTask(delegate() @trusted {
                while (true)
                {
                    awcl.query();
                    sleep(dur!"msecs"(200));
                }
            });
        };
    }

    // -- Webserver
    if (optSocketWebServer !is null)
    {
        if (!tryParseSocket(optSocketWebServer, webserver))
        {
            stderr.writeln("Bad webserver socket specified");
            return 1;
        }

        if (optDocumentRootWebServer is null)
        {
            stderr.writeln("No document root specified, use --htdocs to do so");
            return 1;
        }

        if (!optDocumentRootWebServer.exists || !optDocumentRootWebServer.isDir)
        {
            stderr.writeln("Bad document root specified");
            return 1;
        }

        optDocumentRootWebServer = optDocumentRootWebServer.absolutePath.buildNormalizedPath();

        if (optNoInjectWebServer)
        {
            doInit ~= {
                listeners ~= registerStaticWebserver(webserver, optDocumentRootWebServer);
            };
        }
        else
        {
            doInit ~= {
                listeners ~= registerStaticWebserver(webserver, optDocumentRootWebServer, service);
            };
        }
    }

    // -- Print info

    stdout.writeln(appName, "\n");

    watchDirectories.each!(dir => stdout.writeln("Watching:                ", dir));

    if (!optDisableService)
    {
        stdout.writeln();
        stdout.writeln("Notification service:    http://", service.toString);
    }

    if (optSocketWebServer !is null)
    {
        // dfmt off
        stdout.writeln();
        stdout.writeln("Built-in webserver:      http://", webserver.toString);
        stdout.writeln("Serving:                 ", optDocumentRootWebServer);
        stdout.writeln("Script injection:        ", ((optNoInjectWebServer) ? "disabled" : "enabled"));
        // dfmt on
    }

    stdout.writeln();
    optActions.each!(act => stdout.writeln("Action:                  ", act));

    stdout.writeln();

    // -- Run
    doInit.each!(x => x());
    run(listeners);
    return 0;
}

void printHelp(string args0, GetoptResult opt)
{
    // Ideally, this help text will not exceed a size of
    // 80x23, so that it's fully visible on an 80x24 terminal.

    size_t getIndent()
    {
        immutable l = args0.length + 5;
        return (l <= 29) ? l : 8;
    }

    string makeIndent()
    {
        enum indent = "                             ";
        return indent[0 .. getIndent()];
    }

    immutable indent = makeIndent();

    // dfmt off
    defaultGetoptPrinter(
        appName ~ "\n\n  Usage:\n    " ~ args0 ~ " <options>\n\n  Example:\n    "
            ~ args0 ~ " --socket=127.0.0.1:3001\n"
            ~ indent ~ "--watch=./src            --watch=./sass\n"
            ~ indent ~ "--action=\"npm run build\" --action=\"./refreshDB.sh\""
            ~ "\n\nAvailable options:\n==================",
        opt.options
    );
}

void printVersionInfo()
{
    stdout.write(import("version.txt"));
}
