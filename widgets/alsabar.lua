
--[[
                                                  
     Licensed under GNU General Public License v2 
      * (c) 2013, Luke Bonham                     
      * (c) 2013, Rman                            
                                                  
--]]

local newtimer     = require("lain.helpers").newtimer

local awful        = require("awful")
local beautiful    = require("beautiful")
local naughty      = require("naughty")

local io           = { popen  = io.popen }
local math         = { modf   = math.modf }
local string       = { format = string.format,
                       match  = string.match,
                       rep    = string.rep }
local tonumber     = tonumber

local setmetatable = setmetatable

-- ALSA volume bar
-- lain.widgets.alsabar
local alsabar = {
    channel = "Master",
    step    = "1.26dB",--2%",

    colors = {
        background = beautiful.bg_normal,
        mute       = "#EB8F8F",
        unmute     = "#A4CE8A"
    },

    terminal = terminal or "xterm",
    mixer    = terminal .. " -e alsamixer",

    notifications = {
        --############################
        --font      = beautiful.font:sub(beautiful.font:find(""), beautiful.font:find(" ")),
        --font_size = "11",
        --color     = beautiful.fg_normal,
        --bar_size  = 18,
        --screen    = 1
        --############################
                
        	    icons =
	       {
		  -- the first item is the 'muted' icon
		  "/home/philipp/Pictures/vol/16.png",
		  "/home/philipp/Pictures/vol/15.png",
		  "/home/philipp/Pictures/vol/14.png",
		  "/home/philipp/Pictures/vol/13.png",
		  "/home/philipp/Pictures/vol/12.png",
		  "/home/philipp/Pictures/vol/11.png",
		  "/home/philipp/Pictures/vol/10.png",
		  "/home/philipp/Pictures/vol/09.png",
		  "/home/philipp/Pictures/vol/08.png",
		  "/home/philipp/Pictures/vol/07.png",
		  "/home/philipp/Pictures/vol/06.png",
		  "/home/philipp/Pictures/vol/05.png",
		  "/home/philipp/Pictures/vol/04.png",
		  "/home/philipp/Pictures/vol/03.png",
		  "/home/philipp/Pictures/vol/02.png",
		  "/home/philipp/Pictures/vol/01.png",
		  "/home/philipp/Pictures/vol/00.png",
		 
		  --"/usr/share/icons/gnome/48x48/status/audio-volume-muted.png",
		  -- the rest of the items correspond to intermediate volume levels - you can have as many as you want (but must be >= 1)
		  --"/usr/share/icons/gnome/48x48/status/audio-volume-low.png",
		  --"/usr/share/icons/gnome/48x48/status/audio-volume-medium.png",
		  --"/usr/share/icons/gnome/48x48/status/audio-volume-high.png"
	       },
	    font = "Monospace 10", -- must be a monospace font for the bar to be sized consistently
	    icon_size = 96,--48,
	    bar_size = 25 -- adjust to fit your font if the bar doesn't fit
    },

    _current_level = 0,
    _muted         = false
}



local function worker(args)
    local args = args or {}
    local timeout = args.timeout or 4
    local settings = args.settings or function() end
    local width = args.width or 63
    local height = args.heigth or 1
    local ticks = args.ticks or false
    local ticks_size = args.ticks_size or 7
    local vertical = args.vertical or false

    alsabar.channel = args.channel or alsabar.channel
    alsabar.step = args.step or alsabar.step
    alsabar.colors = args.colors or alsabar.colors
    alsabar.notifications = args.notifications or alsabar.notifications

    alsabar.bar = awful.widget.progressbar()

    alsabar.bar:set_background_color(alsabar.colors.background)
    alsabar.bar:set_color(alsabar.colors.unmute)
    alsabar.tooltip = awful.tooltip({ objects = { alsabar.bar } })
    alsabar.bar:set_width(width)
    alsabar.bar:set_height(height)
    alsabar.bar:set_ticks(ticks)
    alsabar.bar:set_ticks_size(ticks_size)
    alsabar.bar:set_vertical(vertical)

    function alsabar.update()
        -- Get mixer control contents
        local f = io.popen("amixer -M get " .. alsabar.channel)
        local mixer = f:read("*a")
        f:close()

        -- Capture mixer control state:          [5%] ... ... [on]
        local volu, mute = string.match(mixer, "([%d]+)%%.*%[([%l]*)")

        if volu == nil then
            volu = 0
            mute = "off"
        end

        alsabar._current_level = tonumber(volu)
        alsabar.bar:set_value(alsabar._current_level / 100)

        if not mute and tonumber(volu) == 0 or mute == "off"
        then
            alsabar._muted = true
            alsabar.tooltip:set_text (" [Muted] ")
            alsabar.bar:set_color(alsabar.colors.mute)
        else
            alsabar._muted = false
            alsabar.tooltip:set_text(string.format(" %s: %s %% ", alsabar.channel, volu))
            alsabar.bar:set_color(alsabar.colors.unmute)
        end

        volume_now = {}
        volume_now.level = tonumber(volu)
        volume_now.status = mute
        settings()
    end

    newtimer("alsabar", timeout, alsabar.update)

    alsabar.bar:buttons (awful.util.table.join (
          awful.button ({}, 3, function()
            awful.util.spawn(alsabar.mixer, false)
            --awful.util.spawn ("pavucontrol", false)
          end),
          awful.button ({}, 1, function()
            awful.util.spawn(string.format("amixer set %s toggle", alsabar.channel), false)
            alsabar.update()
          end),
          awful.button ({}, 4, function()
            awful.util.spawn(string.format("amixer set %s %s+", alsabar.channel, alsabar.step), false)
            alsabar.update()
          end),
          awful.button ({}, 5, function()
            awful.util.spawn(string.format("amixer set %s %s-", alsabar.channel, alsabar.step), false)
            alsabar.update()
          end)
    ))

    return alsabar
end


-- {{{ Notifications for state of volume
function alsabar.notify()

--####################
--alsabar.update()

--    local preset = {
--        title   = "",
--        text    = "",
--        timeout = 4,
--        screen  = alsabar.notifications.screen,
--        font    = alsabar.notifications.font .. " " ..
--                  alsabar.notifications.font_size,
--        fg      = alsabar.notifications.color
--    }

--    if alsabar._muted
--    then
--        preset.title = alsabar.channel .. " - Muted"
--    else
--        preset.title = alsabar.channel .. " - " .. alsabar._current_level .. "%"
--    end

--    int = math.modf((alsabar._current_level / 100) * alsabar.notifications.bar_size)
--    preset.text = "["
--                .. string.rep("|", int)
--                .. string.rep(" ", alsabar.notifications.bar_size - int)
--                .. "]"

--    if alsabar._notify ~= nil then
--        alsabar._notify = naughty.notify ({
--            replaces_id = alsabar._notify.id,
--            preset      = preset,
--        })
--    else
--        alsabar._notify = naughty.notify ({
--            preset = preset,
--        })
--    end
--####################

-- begin customized notifications
     	local preset =
	{
--		height = 75,
--		width = 300,
		font = alsabar.notifications.font,
		timeout = 1.5,
		opacity = 0.9,
		--border_width = 12,			--specified in rc.lua
		--border_color = '#2B292E',		--specified in rc.lua
		hover_timeout    	= nil,
		
	}
	local i = 1;
	while alsabar.notifications.icons[i + 1] ~= nil
	do
		i = i + 1
	end
	if i >= 2
	then
		preset.icon_size = alsabar.notifications.icon_size
		if alsabar._muted or alsabar._current_level == 0
		then
			preset.icon = alsabar.notifications.icons[1]
		elseif alsabar._current_level == 100
		then
			preset.icon = alsabar.notifications.icons[i]
		else
			local int = math.modf (alsabar._current_level / 100 * (i - 1))
			preset.icon = alsabar.notifications.icons[int + 2]
		end
	end
	if alsabar._muted
	then
		preset.title = alsabar.channel .. " - Muted"
	elseif alsabar._current_level == 0
	then
		preset.title = alsabar.channel .. " - 0% (muted)"
		preset.text = "[" .. string.rep (" ", alsabar.notifications.bar_size) .. "]"
	elseif alsabar._current_level == 100
	then
		preset.title = alsabar.channel .. " - 100% (max)"
		preset.text = "[" .. string.rep ("|", alsabar.notifications.bar_size) .. "]"
	else
		local int = math.modf (alsabar._current_level / 100 * alsabar.notifications.bar_size)
		preset.title = alsabar.channel .. " - " .. alsabar._current_level .. "%"
		preset.text = "[" .. string.rep ("|", int) .. string.rep (" ", alsabar.notifications.bar_size - int) .. "]"
	end
	if alsabar._notify ~= nil
	then
		
		alsabar._notify = naughty.notify (
		{
			replaces_id = alsabar._notify.id,
			preset = preset
		})
	else
		alsabar._notify = naughty.notify ({ preset = preset })
	end
-- end customized notifications
end 
--}}}

return setmetatable(alsabar, { __call = function(_, ...) return worker(...) end })
