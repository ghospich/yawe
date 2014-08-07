yawe
====

Yawe - yet another webm encoder


Installation
============

Enter in repository directory and then.

```
sudo ln -s $PWD/yawe /usr/bin
mkdir ~/.mpv/lua_deps
ln -s $PWD/capture.lua ~/.mpv/lua/capture.lua
ln -s $PWD/path.lua ~/.mpv/lua_deps/capture.lua
```

Usage
=====

Press `a` key in mpv-player to start segment, and press `a` key again to end segment.
After that script will show you command, that you should execute.
Paste this command to free terminal and it'll start encoding!
