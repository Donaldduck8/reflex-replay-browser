-- PlaySeek v1.2 made by GoaLitiuM, v1.2b edit by Donald for Replay Browser
-- 
-- Shorthand command for play <demo> and re_seek_to <timestamp>
-- and mutes the audio during seeking to reduce audio glitching.
--
-- basic usage:
--   ui_playseek_to_proper <demo> <timestamp>
-- toggle autoplay after seeking:
--   ui_playseek_autoplay <1/0>
-- adjust the delay when automute gets disabled shortly after seeking
--   ui_playseek_automute_time <time in seconds>
--

require "base/internal/ui/reflexcore"
PlaySeek =
{
    canPosition = false,
    canHide = false,
	seekTimestamp = nil,
	oldVolume = nil,
	volumeTimer = nil,
};
registerWidget("PlaySeek");

function PlaySeek:initialize()
    widgetCreateConsoleVariable("to", "string", "")
	widgetCreateConsoleVariable("autoplay", "int", 0)
	widgetCreateConsoleVariable("automute_time", "float", 1.5)
end 

function PlaySeek:draw()
	-- seek and adjust volume during following frames
	if self.seekTimestamp then
		consolePerformCommand("re_seek_to " .. self.seekTimestamp)
		if (consoleGetVariable("ui_playseek_autoplay") ~= 0) then
			consolePerformCommand("re_speed 1")
		end
		self.seekTimestamp = nil
		return
	elseif self.oldVolume then
		if self.volumeTimer == nil then
			-- skip lagged frame
			self.volumeTimer = 0
			return
		end
		
		self.volumeTimer = self.volumeTimer + deltaTimeRaw
		if self.volumeTimer >= consoleGetVariable("ui_playseek_automute_time") then
			consolePerformCommand("s_volume " .. self.oldVolume)
			self.oldVolume = nil
			self.volumeTimer = nil
		end
		
		return
	end
	
	local value = consoleGetVariable("ui_playseek_to")
	if value == "" then return end
	 
	local i = 1
	local args = {}

	local index = string.find(value, "%s[%S]*$")
	local timestamp = string.sub(value, index + 1)
	local demo = string.sub(value, 0, index - 1)
	
	if demo then
		-- workaround the annoying sound looping while seeking
		self.oldVolume = consoleGetVariable("s_volume")
		consolePerformCommand("s_volume 0")

		if (string.lower(replayName) ~= string.lower(demo)) then
			consolePerformCommand("play " .. demo)
		end
		
		if timestamp then
			self.seekTimestamp = timestamp
		end
	else
		consolePrint("usage: ui_playseek_to <demo> <timestamp>")
	end
	
	widgetSetConsoleVariable("to", "")
end 