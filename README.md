yawe
====

Yawe - yet another webm encoder


Installation
============

Make yawe script available from interactive terminal. Add it to your `.bashrc`, add repo dir in `PATH`, or symlink yawe to /usr/bin

```bash
cd /path/to/repo
sudo ln -s $PWD/yawe /usr/bin
```
or
```bash
$ $EDITOR ~/.bashrc
alias yawe="/path/to/repo/yawe"
```
or
```bash
$ $EDITOR ~/.bashrc
PATH=$PATH:"/path/to/repo"
```

Then symlink capture.lua script to your mpv directory
```bash
ln -s $PWD/capture.lua ~/.mpv/lua/capture.lua
```

Configuration
=============

Create file `yawe.config` in repo dir, and define needed variables.
They would be sourced by main script.

See all available options in `yawe` script. Also you can set option `TERM` - your prefered terminal.

Usage
=====

Press `a` key in mpv-player to start segment, and press `a` key again to end segment.
After that script will show you command, that you should execute.
Paste this command to noy occupied terminal and it'll start encoding!
