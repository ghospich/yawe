yawe
====

Yawe - yet another webm encoder


Installation
============

Make yawe script available from interactive terminal. Add it to your `.bashrc`, or add repo dir in `PATH`, or symlink yawe to /usr/bin

```bash
sudo ln -s /path/to/repo/yawe /usr/bin
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

Then symlink yawe-mpv.lua script to your mpv directory
```bash
ln -s /path/to/repo/yawe-mpv.lua ~/.mpv/lua/yawe-mpv.lua
```

Configuration
=============

Create file `yawe.config` in repo dir, and define needed variables.
They would be sourced by main script.

See all available options in `yawe` script. Also you can set options:
- `TERM` - your prefered terminal.
- `OUTDIR` - directory where to store webms.

Usage
=====

Press `a` key in mpv-player to start segment, and press `a` key again to end segment.
After that script will show you command, that you should execute.
Edit this command and start encoding!
