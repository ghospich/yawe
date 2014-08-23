function isabs(path)
    return string.sub(path, 1, 1) == '/' or string.sub(path, 1, 1) == '\\' or string.sub(path, 2, 2) == ':'
end

function trim(s)
  return s:match "^%s*(.-)%s*$"
end

function exec(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

function join(p1, p2)
    if is_windows then sep = '\\' else sep = '/' end
    if isabs(p2) then return p2 end
    local endc = string.sub(p1, #p1, #p1)
    if endc ~= '/' and endc ~= '\\' then
        p1 = p1..sep
    end
    return p1..p2
end

function abspath(path)
    local currendir = os.getenv("PWD")
    if not isabs(path) then
        return join(currendir,path)
    else
        return path
    end
end

function one_empty(argname, number)
    if number == 1 then
        return ''
    else
        return '-' ..argname.. ' ' ..number.. ' '
    end
end

CACHED_ARGUMENTS = {}

function escape_argument(arg)
    if CACHED_ARGUMENTS[arg] ~= nil then
        return CACHED_ARGUMENTS[arg]
    else
strtoexec = string.format([=[
printf %%q "$(cat << 'EOF_nVGbpoq'
%s
EOF_nVGbpoq
)"
]=], arg)
        result = trim(exec(strtoexec))
        CACHED_ARGUMENTS[arg] = result
        return result
    end
end

DIRNAME = trim(exec('dirname "$(readlink ~/.mpv/lua/yawe-mpv.lua || readlink ~/.config/mpv/lua/yawe-mpv.lua)"'))
TERM = trim(exec('grep TERM "' ..DIRNAME.. '/yawe.config" | cut -d = -f 2'))
OUTDIR = trim(exec('grep OUTDIR "' ..DIRNAME.. '/yawe.config" | cut -d = -f 2'))
SHELL = trim(exec('getent passwd $LOGNAME | cut -d: -f7'))
if TERM == "" then
    TERM = "xterm"
end

if OUTDIR == "" then
    OUTDIR = "~"
end

if SHELL == "" then
    SHELL = "bash"
end

SHELL_BASENAME = trim(exec('basename "'..SHELL..'"'))


ZDOTDIR = nil
TDIR = nil

function giveToUser(cmd)
    if SHELL_BASENAME == "zsh" then
        if (ZDOTDIR == nil) and (TDIR == nil) then
            ZDOTDIR = trim(exec('zsh -c \'[[ -e "$ZDOTDIR" ]] || ZDOTDIR="$HOME"; echo "$ZDOTDIR"\''))
            TDIR = trim(exec('zsh -c \'TDIR="$(mktemp -qd --suffix _YAWE_ZSH)"; [[ -e "$ZDOTDIR" ]] || ZDOTDIR="$HOME"; ln -s "$ZDOTDIR/.zshenv" "$TDIR"; ln -s "$ZDOTDIR/.zprofile" "$TDIR"; ln -s "$ZDOTDIR/.zlogin" "$TDIR"; echo "$TDIR"\''))
        end

templatecmd =
[=[
tee %s/.zshrc > /dev/null << 'EOF_1z9aG5E'
. %s/.zshrc;cd %s;NTDN=1;zle-line-init(){if test $NTDN -eq 1;then;LBUFFER="$(cat << 'EOF_RLPzIRz'
%s
EOF_RLPzIRz)";NTDN=0;fi }
EOF_1z9aG5E
ZDOTDIR=%s %s -e zsh & disown
]=]

        execthis = string.format(templatecmd, TDIR, ZDOTDIR, OUTDIR, cmd, TDIR, TERM)
    else
templatecmd =
[=[
%s -e bash -c "$(cat << 'EOF_zNwWe9B'
cd %s;read -e -p "$ " -i "$(cat << 'EOF_YZAlFtU'
%s
EOF_YZAlFtU
)" && eval "$REPLY"; exec %s
EOF_zNwWe9B
)" & disown
]=]
        execthis = string.format(templatecmd, TERM, OUTDIR, cmd, SHELL)
    end
    os.execute(execthis)
end

function getCurrentSubtitle()
    local tracktable = mp.get_property_native("track-list", {})
    for n = 1, #tracktable do
        if tracktable[n].type == "sub" then
            if tracktable[n].selected then
                if tracktable[n].external == true then
                    return tracktable[n]["external-filename"]
                else
                    return "on"
                end
            end
        end
    end
    return "off"
end

capture = {}

function capture.handler()
    local gp = mp.get_property
    local gpn = mp.get_property_number
    local c = capture
    if c.start == nil then
        c.start = gp("time-pos")
        print("Ok, waiting for second a-key press")
    elseif c.finish == nil then
        c.finish = gp("time-pos")
        local length = c.finish - c.start
        local fullpath = abspath(mp.get_property("path"))
        local subs = getCurrentSubtitle()
        local subsline = nil

        local aidline = one_empty("aid", gpn("aid"))

        if subs == "off" then
            subsline = ""
        elseif subs == "on" then
            subsline = string.format('-subs on %s', one_empty("sid", gpn("sid")))
        else
            subsline = string.format('-subs %s ', escape_argument(abspath(subs)))
        end

        giveToUser(string.format('yawe -ss %.3f -t %.3f %s%s%s',
            c.start, length, aidline, subsline, escape_argument(fullpath)))

        print("Go ahead, execute it!")

        c.start = nil
        c.finish = nil
    end
end
mp.add_key_binding("a", "capture", capture.handler)


function shutdown_event(event)
    if (SHELL_BASENAME == "zsh") and (not (TDIR == nil)) then
        exec('rm -rf "'..TDIR..'"')
    end
end

mp.register_event("shutdown", shutdown_event)
