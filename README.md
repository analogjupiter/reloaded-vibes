# Reloaded Vibes [![D Code Club - Discord server](https://discordapp.com/api/guilds/242094594181955585/widget.png?style=shield)](https://discord.gg/BmXVTNu)

**Reloaded Vibes** is a smart auto-reloading service and server for (web) development.

It watches a directory for changes and notifies web browsers (or other client applications) through its WebSocket server.
This way those clients can respond to the change and e.g. reload the page so that they'll display the recent changes made by the user.


#### Are you're tired of hitting the refresh button again and again while developing?
Then *Reloaded Vibes* is the app you're looking for:
It watches your project for changes and automatically triggers a refresh in your web browser.
Moreover, it's possible to execute command lines before.
This allows to schedule the runs of preprocessors (like *Sass* or *Less*) and source compilers or any other apps and scripts.


#### Plain and simple

This is *Reloaded Vibes* main design goal.
It's achieved by not using complicated config or recipe files. Instead everything is configured by command line arguments.


#### What's more?

It features a built-in webserver for serving static files.
Utilizing it's *script-injection feature* it can automatically insert the script loader into your HTML pages,
so you don't have to take care of it manually.


## Usage


### Command line

```
./reloaded-vibes --watch=<DIRECTORY TO WATCH> --action=<COMMANDLINE>
```

| Option | Example values | Explanation |
| ------ | -------------- | ----------- |
| `--watch=<DIR>` | `source`, `../` | Directories to watch changes. |
| `--action=<CMD>` | `"npm run build"`,<br/>`./myScript.sh`| Command lines to execute before triggering a refresh. |


#### Multiple directories or actions

```
./reloaded-vibes --watch=<DIR_1> --watch=<DIR_2> --action=<CMD_1> --action=<CMD_2>
```

Just specify the respective arguments multiple times.


#### Custom socket for the notification service

```
./reloaded-vibes --watch=<DIRECTORY TO WATCH> --socket=<SOCKET>
```

| Option | Example values | Explanation |
| ------ | -------------- | ----------- |
| `--socket=<SOCKET>` | `127.0.0.1:3001`,<br/>`[::1]:3001` | Socket to bind the notification service to. |


#### Built-in webserver

```
./reloaded-vibes --watch=<DIRECTORY TO WATCH> --webserver=<SOCKET> --htdocs=<DOCUMENT ROOT>
```

| Option | Example values | Explanation |
| ------ | -------------- | ----------- |
| `--webserver=<SOCKET>` | `127.0.0.1:3002`,<br/>`[::1]:3002` | Socket to bind the built-in webserver to. |
| `--htdocs=<DIR>` | `public/`,<br/>`/var/www/mysite` | Document root path for the built-in webserver. |
| `--noinject` | | Disables injection of the script loader. |


##### Automatic script-injection

Injects a script loader (`<script></script>`) into HTML files that allows the automatical setup of *Reloaded Vibes*.
Those will need a `.html` file extension, plus a `</body>` closing tag.

This feature is enabled by default for the built-in webserver. Pass `--noinject` to disable it.


#### No service ("offline") mode

```
./reloaded-vibes --watch=<DIRECTORY TO WATCH> --action=<COMMANDLINE> --noservice
```

| Option | Example values | Explanation |
| ------ | -------------- | ----------- |
| `--noservice` | | Disables to notification service. *Reloaded Vibes* will still watch for changes and execute the specified actions. |


### Website

Copy the following code into your webpage's HTML `<body>` and adjust the URL specified in the `src` attribute.

```html
<script src="http://<NOTIFICATION SERVICE>/reloaded-vibes.js"></script>
```

You can also open the notification service's index page in your browser
and copy the pre-configured `<script>` tag from there.

Alternative: see the **automatic script-injection** of the built-in webserver.


## Setup

### Prerequisites

1. Install your favorite D compiler
1. Check whether DUB came bundled with it. If not, install DUB.


### Build

```
git clone https://github.com/voidblaster/reloaded-vibes.git
cd reloaded-vibes
dub build
```

You can find the built executable inside the `bin/` directory


## Acknowledgements

- rejectedsoftware
    - [vibe.d](http://vibe-d.dub.pm/)
        - *vibe.d is a high-performance asynchronous I/O, concurrency and web application toolkit written in D.*
        - License: [MIT](https://github.com/vibe-d/vibe.d/blob/v0.8.6-alpha.1/LICENSE.txt)
        - Copyright (c) 2012-2019, rejectedsoftware e.K.
- Jan Jurzitza ([@WebFreak001](https://github.com/WebFreak001))
    - [FSWatch](https://github.com/WebFreak001/FSWatch)
        - *A cross-platform folder & file watching library using win32, inotify or std.file*
        - License: [BSL-1.0](LICENSE_1_0.txt)
        - Copyright © 2016, webfreak
- Viktor ([@dayllenger](https://github.com/dayllenger))


## Packaging

Please note that while *Reloaded Vibes* is available under the *Boost Software License 1.0*,
its dependency *vibe.d* is licensed under the terms of the MIT public license.
