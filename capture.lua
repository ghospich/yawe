-- save as ~/.mpv/lua/capture.lua (new mpv versions)
-- or use as mpv --lua=/path/to/capture.lua
-- usage: press «a» at start and at end of fragment
-- will print commands for ffmpeg and mpv


capture = {}

package.path = package.path .. ';' .. os.getenv('HOME') .. '/.mpv/lua_deps/?.lua;'
require "path"

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
        local fullpath = path.abspath(mp.get_property("path"), os.getenv("PWD"))
        local subs = getCurrentSubtitle()
        local subsline = nil

        if subs == "off" then
            subsline = ""
        elseif subs == "on" then
            subsline = string.format("-subs on -sid %d ", gpn("sid"))
        else
            subsline = string.format("-subs '%s' ", path.abspath(subs, os.getenv("PWD")))
        end

        io.write(string.format("\n\nyawe -ss %.3f -t %.3f -aid %d %s'%s'\n\n",
            c.start, length, gpn("aid"), subsline, fullpath))
        c.start = nil
        c.finish = nil
    end
end
mp.add_key_binding("a", "capture", capture.handler)
