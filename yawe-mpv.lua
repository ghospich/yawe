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

TERM = trim(exec('grep TERM "$(dirname "$(readlink ~/.mpv/lua/yawe-mpv.lua)")/yawe.config" | cut -d = -f 2'))
SHELL = trim(exec('getent passwd $LOGNAME | cut -d: -f7'))

if TERM == "" then
    TERM = "xterm"
end

if SHELL == "" then
    SHELL = "bash"
end

function giveToUser(cmd)
    inside = 'read -e -p "$ " -i "' ..cmd.. '" && eval "$REPLY"; exec ' ..SHELL
    execthis = TERM .. " -e bash -c '" ..inside.. "' & disown"
    os.execute(execthis)
end

function getCurrentSubtitle()
    local tracktable = mp.get_property_native("track-list", {})
    for n = 1, #tracktable do
        if not (tracktable[n].type == "unknown") then
            if mp.get_property_number("sid") == tracktable[n].id then
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

        if subs == "off" then
            subsline = ""
        elseif subs == "on" then
            subsline = string.format('-subs on -sid %d ', gpn("sid"))
        else
            subsline = string.format('-subs \\"%s\\" ', abspath(subs))
        end

        giveToUser(string.format('yawe -ss %.3f -t %.3f -aid %d %s\\"%s\\"',
            c.start, length, gpn("aid"), subsline, fullpath))

        print("Go ahead, execute it!")

        c.start = nil
        c.finish = nil
    end
end
mp.add_key_binding("a", "capture", capture.handler)
