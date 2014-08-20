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

        RTCMD='cd ' ..OUTDIR.. ';NTDN=1;zle-line-init(){if test $NTDN -eq 1;then;LBUFFER="' ..cmd.. '";NTDN=0;fi }'
        execthis = "echo '. " ..ZDOTDIR.. "/.zshrc;" ..RTCMD.. "' > '" ..TDIR.. "/.zshrc'; ZDOTDIR='" ..TDIR.. "' "..TERM.." -e zsh & disown"
    else
        inside = 'cd ' ..OUTDIR.. '; read -e -p "$ " -i "' ..cmd.. '" && eval "$REPLY"; exec ' ..SHELL
        execthis = TERM .. " -e bash -c '" ..inside.. "' & disown"
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
            subsline = string.format('-subs \\"%s\\" ', abspath(subs))
        end

        giveToUser(string.format('yawe -ss %.3f -t %.3f %s%s\\"%s\\"',
            c.start, length, aidline, subsline, fullpath))

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
