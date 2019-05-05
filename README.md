# Reloaded Vibes [![D Code Club - Discord server](https://discordapp.com/api/guilds/242094594181955585/widget.png?style=shield)](https://discord.gg/BmXVTNu)

## Prerequisites

1. Install your favorite D compiler
1. Check whether DUB came bundled with it. If not, install DUB.
1. You'll need some crypto development library installed for usage with `vibe-d:tls`. (e.g. on Ubuntu you can go for: `apt install libssl-dev`)


## Build

```
dub build
```

If this command leads to linker errors, make sure you've got some crypto lib installed.
If you're sure that's the case and you're on a Posix system, try:

```
dub build --override-config=vibe-d:tls/openssl-1.1
```
