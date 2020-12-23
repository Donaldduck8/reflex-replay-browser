--------------------------------------------------------------------------------
-- This is a modification of the official Menu.lua Reflex script.
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"
require "base/internal/ui/menus/MenuBar"
require "base/internal/ReplayBrowserData"


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Menu =
{
	canPosition = false,
	canHide = false,
	--isMenu = false,

	modeKey = nil,
	modes = nil,
	menuBarIntensity = 0,

	profileRotationVelocity = 0,
	profileRotation = 0,
	profileMouseX = 0,

	quickplayMmIntensity = 0,
	mmStatusText = "",
	mmStatusTextNotEmpty = "",

	comboBoxDataDisplayMode = {},
	comboBoxDataAdapter = {},
	comboBoxDataResolution = {},
	comboBoxDataRefreshRate = {},
	comboBoxDataMaxFPS = {},
	comboBoxDataGraphicsPreset = {},
	comboBoxDataScoreHook = {},
	comboBoxDataBindFor = {},
	comboBoxDataGunModel = {},
	comboBoxDataGibDuration = {},
	comboBoxDataColorOverride = {},
	comboBoxDataProvingGrounds = {},
	comboBoxDataRagdollDuration = {},
	comboBoxDataTrainingLeaderboard = {},

	scrollBarDataFriends = {},
	scrollBarDataWatchMMList = {},
	scrollBarDataServerBrowser = {},
	scrollBarDataInventoryMelee = {},
	scrollBarDataWidgetSelection = {},
	scrollBarDataAddonSelection = {},
	scrollBarDataWidgetProperties = {},
	scrollBarDataTrainingMap = {},
	scrollBarDataTrainingBotsMap = {},

	selected_r_resolution_fullscreen = nil;
	selected_r_resolution_windowed = nil;
	selected_r_fullscreen = nil;
	selected_r_refreshrate = nil;

	selected_server_address = nil;
	selected_server_col = "Ping";

	selected_inventory_definition_id = nil;

	selected_widget_name = nil;
	selected_addon_foldername = nil;

	selected_training_leaderboard = nil;

	inventorySpamRefresh = nil;

	pulseBonusExperienceTimer = 0;

	replayBrowserTable = {};
	replayBrowserCursorDirs = {};
};
registerWidget("Menu");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:initialize()
	widgetCreateConsoleVariable("show_widget_properties_height", "int", 0);
	widgetCreateConsoleVariable("training_multiplayer", "int", 0);
	widgetCreateConsoleVariable("show_server_locked", "int", 1);
	widgetCreateConsoleVariable("show_server_empty", "int", 1);
	widgetCreateConsoleVariable("show_server_old", "int", 0);
	widgetCreateConsoleVariable("show_server_mm", "int", 0);
	widgetCreateConsoleVariable("startbot1", "string", "none");
	widgetCreateConsoleVariable("startbot2", "string", "none");
	widgetCreateConsoleVariable("startbot3", "string", "none");
	widgetCreateConsoleVariable("startbot4", "string", "none");
	widgetCreateConsoleVariable("startbot5", "string", "none");
	widgetCreateConsoleVariable("startbot6", "string", "none");
	widgetCreateConsoleVariable("startbot7", "string", "none");
	widgetCreateConsoleVariable("startbot8", "string", "none");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ui2MatchButton(useworkshop, mapname, mapid, mode, x, y, w, h, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local col = optargs.color or Color(0,0,0,0);
	local bgcoltype = optargs.bgcoltype == nil and UI2_COLTYPE_BUTTON or optargs.bgcoltype;

	local cornerRadius = 5.0;
	local tw = 0;
	local iw = 0;

	local m = {};
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
		m.hoverAmount = 0;
		col = Color(
			col.r * 0.5,
			col.g * 0.5,
			col.b * 0.5,
			col.a);
	else
		m = mouseRegion(x, y, w, h, optionalId);
	end
	nvgSave();

	-- lookup map table by name
	local maptable = nil;
	if useworkshop then
		-- lookup from workshop query
		maptable = nil;
		if workshopSpecificMap ~= nil and workshopSpecificMap.id == mapid then
			maptable = workshopSpecificMap;
		end

		-- if not found, do a query
		if maptable == nil and not workshopIsQueryingSpecificMap() then
			workshopQuerySpecificMap(mapid);
		end		
	else
		-- lookup from local maps
		for k, v in pairs(maps) do
			if v.title == mapname then
				maptable = v;
				break;
			end
		end
	end

	if maptable == nil then
		maptable = {};
		maptable.previewImageName = "";
		maptable.title = "";
		maptable.minPlayers = 2;
		maptable.maxPlayers = 4;
	end

	-- bg
	local col = ui2FormatColor(bgcoltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();
	
	-- left thumbnail
	local iheight = h-20;
	local iwidth = iheight * 4 / 3;
	local ix = x + 10;
	local iy = y + 10;
	if maptable ~= nil then
		nvgBeginPath();
		nvgRect(ix, iy, iwidth, iheight);
		nvgFillImagePattern(maptable.previewImageName, ix-iwidth*.25, iy-iheight*.25, iwidth*1.5, iheight*1.5, 0, intensity*255); -- (center quarter of image)
		nvgFill();
	end

	-- mapname
	local nameText = string.len(maptable.title) > 0 and maptable.title or mapname;
	local fontx = ix + iwidth + 10;
	local fonty = y + h*0.5 - 20;
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(fontx, fonty, string.upper(nameText), NULL);

	-- prepare some mode arrays
	local modeNames = {};
	local modeShortNames = {};
	local i = 1;
	for k, v in pairs(gamemodes) do
		modeNames[i] = v.name;
		modeShortNames[i] = v.shortName;
		i = i + 1;
	end
	local modeName = modeNames[FindIndex(mode, modeShortNames)]; -- convert "ffa" -> "FREE FOR ALL"

	-- mode
	intensity = intensity * 0.8;
	local fonty = fonty + 20;
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(fontx, fonty, modeName, NULL);
	
	-- mode
	local fonty = fonty + 20;
	local text = maptable.minPlayers .. " - " .. maptable.maxPlayers .. " Players";
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(fontx, fonty, text, NULL);
	
	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick");
	end

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ui2MutatorButton(mutators, x, y, w, h, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local col = optargs.color or Color(0,0,0,0);
	local bgcoltype = optargs.bgcoltype == nil and UI2_COLTYPE_BUTTON or optargs.bgcoltype;

	local cornerRadius = 5.0;
	local tw = 0;
	local iw = 0;

	local m = {};
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
		m.hoverAmount = 0;
		col = Color(
			col.r * 0.5,
			col.g * 0.5,
			col.b * 0.5,
			col.a);
	else
		m = mouseRegion(x, y, w, h, optionalId);
	end

	nvgSave();
	
	-- bg
	local col = ui2FormatColor(bgcoltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();
	
	nvgIntersectScissor(x, y, w - 5, h);

	local ix = x+7;
	local iy = y+h/2;
	local iconRad = 12;
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);

	-- iterate mutators
	local upperCaseMutators = string.upper(mutators);
	for k, v in pairs(mutatorDefinitions) do
		if string.find(upperCaseMutators, k) ~= nil then
			-- icon
			local iconCol = v.col;
			nvgFillColor(Color(iconCol.r, iconCol.g, iconCol.b, col.a));
			nvgSvg(v.icon, ix + iconRad, iy, iconRad-2);
			ix = ix + iconRad*2+4;
			
			-- name
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
			nvgText(ix, iy, k, NULL);
			ix = ix + nvgTextWidth(k) + 12;
		end
	end
	
	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick");
	end

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawHoverWindow(x, y, breakRowWidth, title, text, icon, iconCol, iconScale, bgCol)
	local hoverIntensity = 1;
	local iconScale = iconScale or 1;
	-- local breakRowWidth = 500;
	-- local text = "hello";

	nvgSave();
			
	ui2FontNormal();
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgTextLineHeight(.8);

	local bounds = nvgTextBoxBounds(breakRowWidth, text);
	local boundsTitle = nvgTextBoxBounds(breakRowWidth, title);
	local w = 90 + math.max(bounds.maxx - bounds.minx, boundsTitle.maxx - boundsTitle.minx)
	local h = (bounds.maxy - bounds.miny) + 30;

	-- bg
	local mx = x;
	local my = y;
	local col = Color(25, 25, 25, 255*hoverIntensity);
	if bgCol ~= nil then
		col.r = bgCol.r
		col.g = bgCol.g
		col.b = bgCol.b
		col.a = bgCol.a*hoverIntensity
	end
	nvgBeginPath();
	nvgRoundedRect(mx, my, w, h, 3);
	nvgFillColor(col);
	nvgFill();

	-- icon
	nvgFillColor(Color(iconCol.r, iconCol.g, iconCol.b, col.a * hoverIntensity));
	nvgSvg(icon, mx+40, my+30, 30 * iconScale * .4);

	-- name
	local iy = my + 18;
	local col = ui2FormatColor(UI2_COLTYPE_TEXT, hoverIntensity, 1, enabled);
	nvgFillColor(col);
	nvgText(mx + 40 + 40, iy, title);

	-- desc
	local iy = my + 42;
	local col = ui2FormatColor(UI2_COLTYPE_TEXT, hoverIntensity * .5, 1, enabled);
	nvgFillColor(col);
	nvgTextBox(mx + 40 + 40, iy, breakRowWidth, text);
	--nvgText(mx + 40 + 40, iy, text);

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ui2VideoButton(imagename, name, author, x, y, w, h, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local col = optargs.color or Color(0,0,0,0);
	local bgcoltype = optargs.bgcoltype == nil and UI2_COLTYPE_BUTTON or optargs.bgcoltype;

	local cornerRadius = 5.0;
	local tw = 0;
	local iw = 0;

	local m = {};
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
		m.hoverAmount = 0;
		col = Color(
			col.r * 0.5,
			col.g * 0.5,
			col.b * 0.5,
			col.a);
	else
		m = mouseRegion(x, y, w, h, optionalId);
	end
	nvgSave();

	-- bg
	local col = ui2FormatColor(bgcoltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();
	
	-- left thumbnail
	local iheight = h-20;
	local iwidth = iheight * 16 / 9;
	local ix = x + 10;
	local iy = y + 10;
	if imagename ~= nil then
		nvgBeginPath();
		nvgRect(ix, iy, iwidth, iheight);
		--nvgFillImagePattern(imagename, ix-iwidth*.25, iy-iheight*.25, iwidth*1.5, iheight*1.5); -- (center quarter of image)
		nvgFillImagePattern(imagename, ix, iy, iwidth, iheight, 0, intensity*255);
		nvgFill();
	end

	-- name
	local fontx = ix + iwidth + 10;
	local fonty = y + h*0.5 - 20;
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(fontx, fonty, string.upper(name), NULL);

	-- author
	intensity = intensity * 0.8;
	local fonty = fonty + 20;
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(fontx, fonty, author, NULL);
	
	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick")
	end

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2ColorPickerButton(x, y, w, h, color, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	
	local m = mouseRegion(x, y, w, h, optionalId);
	
	nvgSave();

	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(Color(color.r, color.g, color.b, color.a * intensity));
	nvgFill();

	if m.hoverAmount ~= 0 then
		nvgStrokeColor(Color(232, 232, 232, 255 * intensity * m.hoverAmount));
		nvgStrokeWidth(2);
		nvgStroke();
	end

	if optargs.icon ~= nil then
		local luma = GetLuma(color);
		local coltype = luma < 127 and UI2_COLTYPE_TEXT or UI2_COLTYPE_BUTTON_BLACK;
		local ix = x + w/2;
		local iy = y + h/2;
		nvgFillColor(ui2FormatColor(coltype, intensity, m.hoverAmount, enabled));
		nvgSvg(optargs.icon, ix, iy, 6);
	end

	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick");
	end

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2ColorPickerIndexed(index, x, y, cols, rows, colors, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;
	local width = 18;
	local stridex = 24;
	local stridey = 24;
	local colIndex = 0;

	local hoverMax = 0;
	local hoverIndex = -1;

	for r = 0, rows-1, 1 do 
		for c = 0, cols-1, 1 do 
			local col = colors[colIndex+1];
			if col ~= nil then
				optargs.optionalId = colIndex;

				if index == colIndex then
					optargs.icon = "internal/ui/icons/tick";
				end
				local select, hoverAmount = ui2ColorPickerButton(x + c * stridex, y + r * stridey, width, width, col, optargs);
				if select then
					index = colIndex;
				end
				optargs.icon = nil;
				if hoverMax < hoverAmount then
					hoverMax = hoverAmount;
					hoverIndex = colIndex;
				end
			end
			colIndex = colIndex + 1;
		end
	end

	return index, hoverIndex;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2Graph(x, y, w, h, xaxis, yaxis, eval, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local plotx = optargs.plotx;

	nvgSave();

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, 0, enabled));
	nvgFill();
	
	-- prep styles
	ui2FontSmall();
	nvgStrokeWidth(1);
	nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));

	--axis
	nvgBeginPath();
	nvgMoveTo(x, y+h);
	nvgLineTo(x+w+10, y+h);
	nvgMoveTo(x, y+h);
	nvgLineTo(x, y-10);
	nvgStroke();

	-- left axis name
	nvgSave();
	nvgTranslate(x-46, y+h/2);
	nvgRotate(-3.1415/2);
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BOTTOM);
	nvgText(0, 0, yaxis.name);
	nvgRestore();

	-- left sections
	for graphy = yaxis.min, yaxis.max, yaxis.step do
		local liney = y + h - ((graphy - yaxis.min) / (yaxis.max - yaxis.min)) * h;

		-- text
		nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
		nvgText(x-10, liney, graphy);

		-- line
		nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));
		nvgBeginPath();
		nvgMoveTo(x, liney);
		nvgLineTo(x-6, liney);
		nvgStroke();

		-- line over
		nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, false));
		nvgBeginPath();
		nvgMoveTo(x, liney);
		nvgLineTo(x+w, liney);
		nvgStroke();	
	end

	-- bottom axis name
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP);
	nvgText(x+w/2, y+h+30, xaxis.name);

	-- bottom sections
	for graphx = xaxis.min, xaxis.max, xaxis.step do
		local linex = x + ((graphx - xaxis.min) / (xaxis.max - xaxis.min)) * w;

		-- text
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP);
		nvgText(linex, y+h+4, graphx);

		-- line
		nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));
		nvgBeginPath();
		nvgMoveTo(linex, y+h);
		nvgLineTo(linex, y+h+6);
		nvgStroke();	
	end

	-- evaluate
	local start = true;
	local controlPointX = nil;
	local controlPointY = nil;
	nvgBeginPath();
	for graphx = xaxis.min, xaxis.max, xaxis.step/10 do
		local linex = x + ((graphx - xaxis.min) / (xaxis.max - xaxis.min)) * w;

		local graphy = eval(graphx);

		local liney = y + h - ((graphy - yaxis.min) / (yaxis.max - yaxis.min)) * h;

		if start then
			start = false;
			nvgMoveTo(linex, liney);
		else
			nvgLineTo(linex, liney);
		end
		
		--nvgBeginPath();
		--nvgCircle(linex, liney, 5);
		--nvgFillColor(ui2FormatColor(UI2_COLTYPE_BUTTON, intensity, 0, enabled));
		--nvgFill();
	end
	local graphIntensity = enabled and 1 * intensity or 0.25 * intensity;
	nvgStrokeWidth(3);
	nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_BUTTON, graphIntensity, 0, true));
	nvgStroke();
	nvgClosePath();

	-- draw a marker on graph at one point?
	if plotx ~= nil and enabled then
		local graphx = plotx;
		local linex = x + ((graphx - xaxis.min) / (xaxis.max - xaxis.min)) * w;
		local graphy = eval(graphx);
		local liney = y + h - ((graphy - yaxis.min) / (yaxis.max - yaxis.min)) * h;
		
		nvgBeginPath();
		nvgCircle(linex, liney, 6);
		nvgFill();
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
__keybind_pulse = 0; -- hmm hidden globals
local function ui2KeyBind(bindCommand, x, y, w, bindState, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local plotx = optargs.plotx;
	local h = 35;

	local c = 255;
	local k = nil;
	if enabled == false then
		c = UI_DISABLED_TEXT;
	else
		k = inputGrabRegion(x, y, w, h, optionalId);
	end

	nvgSave();

	local key = bindReverseLookup(bindCommand, bindState);
	if key == "(unbound)" then
		c = c / 2;
	else
		key = string.upper(key);
	end

	-- pulse bg when have focus
	local bgc = ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, k.hoverAmount, enabled);
	if k.focus then
		local pulseAmount = k.focusAmount;
	
		-- pulse
		pulseAmount = intensity * (math.sin(__keybind_pulse) * 0.5 + 0.5);
		__keybind_pulse = __keybind_pulse + deltaTime * 16;
		
		bgc.r = lerp(bgc.r, 80, pulseAmount);
	end

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(bgc);
	nvgFill();
	
	-- scissor
	ui2FontNormal();
	local tw = nvgTextWidth(key);
	if tw >= w - 5 then
		nvgIntersectScissor(x, y, w - 5, 100);
	end
	
	-- text
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, k.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x+h*0.3, y+h*0.5, key);

	nvgRestore();

	if k.nameKeyPressed ~= nil then
		if key ~= "(unbound)" then
			consolePerformCommand("unbind "..bindState.." "..key);
		end
		consolePerformCommand("bind "..bindState.." "..k.nameKeyPressed.." "..bindCommand);
	end

	return text;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfilePlayer(intensity)
	local optargs = {
		intensity = intensity
	};
	local colWidth = 530;
	local colIndent = 150;

	-- COL 2
	local x = 90;
	local y = -250;
		
	nvgSave();
	
	-- s1 == current settings
	local s1 = {};
	s1.name						= consoleGetVariable("name");
	s1.cl_playercolor1			= consoleGetVariable("cl_playercolor1");
	s1.cl_playercolor2			= consoleGetVariable("cl_playercolor2");
	s1.cl_playercolor3			= consoleGetVariable("cl_playercolor3");
	s1.cl_playermelee			= consoleGetVariable("cl_playermelee");
	s1.cl_playerhead			= consoleGetVariable("cl_playerhead");
	s1.cl_playerlegs			= consoleGetVariable("cl_playerlegs");
	s1.cl_playerarms			= consoleGetVariable("cl_playerarms");
	s1.cl_playertorso			= consoleGetVariable("cl_playertorso");
	s1.cl_playerburstgun		= consoleGetVariable("cl_playerburstgun");
	s1.cl_playershotgun			= consoleGetVariable("cl_playershotgun");
	s1.cl_playergrenadelauncher	= consoleGetVariable("cl_playergrenadelauncher");
	s1.cl_playerplasmarifle		= consoleGetVariable("cl_playerplasmarifle");
	s1.cl_playerrocketlauncher	= consoleGetVariable("cl_playerrocketlauncher");
	s1.cl_playerioncannon		= consoleGetVariable("cl_playerioncannon");
	s1.cl_playerboltrifle		= consoleGetVariable("cl_playerboltrifle");

	-- s2 = new settings
	local s2 = {};

	-- read item ids from cvars
	local items = {};
	items[1] = {
		["slot"] = "melee",
		["instanceId"] = s1.cl_playermelee };
	items[2] = {
		["slot"] = "head",
		["instanceId"] = s1.cl_playerhead };
	items[3] = {
		["slot"] = "arms",
		["instanceId"] = s1.cl_playerarms };
	items[4] = {
		["slot"] = "legs",
		["instanceId"] = s1.cl_playerlegs };
	items[5] = {
		["slot"] = "torso",
		["instanceId"] = s1.cl_playertorso };
	items[6] = {
		["slot"] = "burstgun",
		["instanceId"] = s1.cl_playerburstgun };
	items[7] = {
		["slot"] = "shotgun",
		["instanceId"] = s1.cl_playershotgun };
	items[8] = {
		["slot"] = "grenadelauncher",
		["instanceId"] = s1.cl_playergrenadelauncher };
	items[9] = {
		["slot"] = "plasmarifle",
		["instanceId"] = s1.cl_playerplasmarifle };
	items[10] = {
		["slot"] = "rocketlauncher",
		["instanceId"] = s1.cl_playerrocketlauncher };
	items[11] = {
		["slot"] = "ioncannon",
		["instanceId"] = s1.cl_playerioncannon };
	items[12] = {
		["slot"] = "boltrifle",
		["instanceId"] = s1.cl_playerboltrifle };

	-- lookup definitions from instance ids
	for k, v in pairs(items) do
		local instance = inventoryInstances[v.instanceId];
		if instance ~= nil then
			v.definitionId = instance.definitionId;
			v.name = inventoryDefinitions[instance.definitionId].name;
			v.color = inventoryDefinitions[instance.definitionId].color;
		end
	end

	local hoverColor1 = nil;
	local hoverColor2 = nil;
	local vstride = 55

	-- controls on right (x: 100 => 550)
	y = y - 20
	ui2Label("Name", x, y, optargs);
	s2.name = ui2EditBox(s1.name, x + colIndent, y, colWidth - colIndent, optargs);
	y = y + vstride;	

	ui2Label("Primary", x, y, optargs);
	s2.cl_playercolor1, hoverColor1 = ui2ColorPickerIndexed(s1.cl_playercolor1, x + colIndent, y+10, 16, 4, extendedColors, optargs);
	y = y + 60;
	y = y + vstride;
	
	ui2Label("Secondary", x, y, optargs);
	s2.cl_playercolor2, hoverColor2 = ui2ColorPickerIndexed(s1.cl_playercolor2, x + colIndent, y+10, 16, 4, extendedColors, optargs);
	y = y + 60;
	y = y + vstride;
	
	ui2Label("Glow", x, y, optargs);
	s2.cl_playercolor3, hoverColor3 = ui2ColorPickerIndexed(s1.cl_playercolor3, x + colIndent, y+10, 16, 4, glowColors, optargs);
	y = y + vstride;
	y = y + 10;
	--y = y + 20;

	optargs.enabled = false;
	ui2Label("Cosmetics", x, y, optargs);
	y = y + vstride
	optargs.enabled = true;
	
	optargs.enabled = connectedToSteam;	
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.iconRight = "internal/ui/icons/buttonRightArrow";

	-- draw items
	if connectedToSteam then
		for k = 1, 5 do
			item = items[k]
		
			-- not found, user either sold it or steam inventory list isn't downloaded, just leave
			-- it empty here so they can re-select something else. Don't want to just reset to default
			-- incase this happens unexpectedly during steam connection
			if item.color == nil then
				item.color = Color(0,0,0,0);
				item.name = "";
			end

			-- draw
			if item.color ~= nil then
				optargs.color = Color(item.color.r, item.color.g, item.color.b, item.color.a * intensity);
				optargs.optionalId = k;

				local slotName = FirstToUpper(item.slot);
				ui2Label(slotName, x, y, optargs);

				if ui2Button(item.name, x + colIndent, y, colWidth - colIndent, 35, optargs) then
					-- switch to melee sub screen
					self.modes[4].subKey = 3+k;
	
					-- refresh item list (user may have purchased an item)
					inventoryRefresh();
				end
				y = y + vstride;
			end
		end

		item.color = nil
		ui2Label("Weapons", x, y, optargs);

		local ix = x + colIndent
		for k = 6, 12 do
			item = items[k]
			if item.color == nil then
				item.color = Color(0,0,0,0);
				item.name = "";
			end

			optargs.name = ""
			optargs.icon = "internal/ui/icons/weapon"..(k-4)
			optargs.optionalId = k;
			optargs.iconRight = nil;
			optargs.iconSize = 11;

			local col = Color((item.color.r*232)/255, (item.color.g*232)/255, (item.color.b*232)/255)

			local coltype = {
				base = col,
				hover = Color(math.min(col.r+20, 255), math.min(col.g+20, 255), math.min(col.b+20, 255)),
				pressed = Color(math.max(col.r-20, 0), math.max(col.g-20, 0), math.max(col.b-20, 0)),
				disabled = Color(100, 100, 100, 255)
			};
			optargs.coltype = coltype
			
			if ui2Button("", ix, y, 40, 35, optargs) then
				-- switch to melee sub screen
				self.modes[4].subKey = 3+k;
	
				-- refresh item list (user may have purchased an item)
				inventoryRefresh();
			end
			ix = ix + 56.5
		end
	end

	if not connectedToSteam then
		ui2Label("(No Steam connection found, Inventory unavailable)", x, y, optargs);
	end

	-- apply hovers
	if hoverColor1 ~= nil then
		playerPreviewSetHoverColor1(hoverColor1);
	end
	if hoverColor2 ~= nil then
		playerPreviewSetHoverColor2(hoverColor2);
	end
	if hoverColor3 ~= nil then
		playerPreviewSetHoverColor3(hoverColor3);
	end
		
	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawCrates(intensity)
	local optargs = {
		intensity = intensity
	};
	
	optargs.enabled = connectedToSteam;

	local x = 0;
	local y = 340;
	local canSeeNextPrev = false
		
	nvgSave();
	
	local stringAY = y-670
	local stringBY = y-640
	local stringA = ""
	local stringB = ""

	--
	if connectedToSteam and cratesIsCrateVisible() and cratesGetCrateDefId() ~= nil and inventoryDefinitions[cratesGetCrateDefId()] ~= nil then
		local crateDefId = cratesGetCrateDefId();
		
		local crateCount = 0
		local crateName = inventoryDefinitions[crateDefId].name

		for k, v in pairs(inventoryInstances) do
			if v.definitionId == crateDefId then
				crateCount = crateCount + v.quantity;
			end
		end

		local crateString = crateName;
		if crateCount > 1 then
			crateString = crateString .. " (x" .. crateCount .. ")"
		end

		-- open/buy button
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
		if ui2Button("OPEN", x-60, y+40, 120, 40, optargs) then
			cratesOpenCrate();
		end

		-- open/buy button
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
		if ui2Button("BUY", x-60, y+100, 120, 40, optargs) then
			showAsPopup("BuyCrates")
		end

		-- next/prev button
		local pageCount = cratesGetCratePageCount()
		local pageIndex = cratesGetActiveCratePage()
		local canGoPrev = cratesIsIdleWithCrate() and (pageIndex > 0);
		local canGoNext = cratesIsIdleWithCrate() and (pageIndex + 1 < pageCount);
		-- prev button
		optargs.enabled = canGoPrev;
		optargs.intensity = intensity;
		if ui2Button("PREV", x-200, y+40, 120, 40, optargs) then
			Menu.profileRotation = 0
			cratesSetActiveCratePage(pageIndex-1)
		end
		-- next button
		optargs.enabled = canGoNext;
		optargs.intensity = intensity;
		if ui2Button("NEXT", x+80, y+40, 120, 40, optargs) then
			Menu.profileRotation = 0
			cratesSetActiveCratePage(pageIndex+1)
		end
		optargs.intensity = intensity;
		optargs.enabled = nil;

		stringA = crateString
		stringB = ""
			
	elseif connectedToSteam and cratesIsItemReceivedVisible() then
		local itemReceivedDefId = cratesGetItemReceivedDefId();
		
		if inventoryDefinitions[itemReceivedDefId] ~= nil and inventoryDefinitions[itemReceivedDefId].name ~= nil then
			stringA = inventoryDefinitions[itemReceivedDefId].name
			stringAY = y-670
		end

		-- progress button
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
		if ui2Button("OK", x-60, y+40, 120, 40, optargs) then
			-- reset screen
			cratesSetEnabled(false);
			cratesSetEnabled(true);
			Menu.profileRotation = 0
		end

	elseif connectedToSteam and cratesIsIdleNoCrate() then
		stringA = "Play matches to get crates!"
		stringB = "(No crates owned)"

		-- open/buy button
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
		if ui2Button("BUY", x-60, y, 120, 40, optargs) then
			showAsPopup("BuyCrates")
		end
	end

	optargs.halign = NVG_ALIGN_CENTER;
	optargs.nofont = true;
	nvgFontSize(36);
	nvgFontFace("TitilliumWeb-Regular");
	ui2Label(stringA, x, stringAY, optargs);
	optargs.halign = nil;
	optargs.nofont = nil;

	optargs.halign = NVG_ALIGN_CENTER;
	optargs.nofont = true;
	optargs.enabled = false;
	nvgFontSize(36);
	nvgFontFace("TitilliumWeb-Regular");
	ui2Label(stringB, x, stringBY, optargs);
	optargs.halign = nil;
	optargs.nofont = nil;
	optargs.enabled = nil;
	
	if not connectedToSteam then
		optargs.halign = NVG_ALIGN_CENTER;
		ui2Label("(No Steam connection found, Inventory unavailable)", x, y-40, optargs);
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2BarGraph(x, y, w, h, xaxis, yaxis, bars, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local bgIntensity = optargs.bgIntensity or 1;
	local plotx = optargs.plotx;
	local selectedBar = optargs.selectedBar;

	local hoveringOut = nil;

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, bgIntensity, 0, enabled));
	nvgFill();
	
	-- prep styles
	ui2FontSmall();
	nvgStrokeWidth(1);
	nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 0, enabled));

	--axis
	nvgBeginPath();
	nvgMoveTo(x, y+h);
	nvgLineTo(x+w+10, y+h);
	nvgMoveTo(x, y+h);
	nvgLineTo(x, y-10);
	nvgStroke();

	-- left axis name
	nvgSave();
	nvgTranslate(x-16, y+h/2);
	nvgRotate(-3.1415/2);
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BOTTOM);
	nvgText(0, 0, yaxis.name);
	nvgRestore();

	-- bottom axis name
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP);
	nvgText(x+w/2, y+h+10, xaxis.name);

	-- bars
	local ix = x + 10;
	local iy = y + h;
	local barWidth = 40;
	local barStride = 50;
	local barHeight = h*.9;
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BOTTOM);
	for k, bar in ipairs(bars) do
		local bx = ix;
		local bh = barHeight * bar.value;
		local by = iy - bh;
		local bw = barWidth;
		local m = mouseRegion(bx, by, bw, bh, k);

		local barIntensity = lerp(0.65, 1.0, m.hoverAmount);
		local col = Color(bar.color.r, bar.color.g, bar.color.b);
		col.a = 255 * intensity * barIntensity;

		nvgBeginPath();
		nvgRect(bx, by, bw, bh);
		--nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, 0, enabled));
		nvgFillColor(col);
		nvgFill();
		--nvgStrokeColor(scol);
		--nvgStroke();

		local value = round(bar.value * 100);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
		nvgText(ix + barWidth/2, iy -barHeight * bar.value, value .. "%");

		if optargs.selectedBar == k then
			local rad = 6;
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_BUTTON_BLACK, intensity, m.hoverAmount, enabled));
			nvgSvg("internal/ui/icons/upArrow", ix + barWidth/2, by+bh-10, rad);
		end

		ix = ix + barStride;

		if m.leftUp then
			playSound("internal/ui/sounds/buttonClick")
			selectedBar = k;
		end;

		if m.hoverAmount > 0.5 then 
			hoveringOut = k;
		end;
	end

	return selectedBar, hoveringOut;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileStatistics(intensity)
	local optargs = {
		intensity = intensity
	};
	local colWidth = 530;
	local colIndent = 260;
	local userStats = steamUserStats[steamId];
	if not connectedToSteam then
		userStats = nil;
	end

	-- COL 1
	local x = -620;
	local y = -250;
		
	nvgSave();
	
	optargs.enabled = false;
	ui2Label("General", x, y, optargs);
	optargs.enabled = true;
	y = y + 60;	

	ui2Label("First Game Played:", x, y, optargs);
	if userStats ~= nil then
		local text = userStats.epochFirstGamePlayedTime > 0 and userStats.firstGamePlayedTime or "";
		ui2Label(text, x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Last Game Played:", x, y, optargs);
	if userStats ~= nil then
		local text = userStats.epochLastGamePlayedTime > 0 and userStats.lastGamePlayedTime or "";
		ui2Label(text, x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Games Played:", x, y, optargs);
	if userStats ~= nil then
		ui2Label(CommaValue(userStats.gamesPlayed), x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Wins / Losses:", x, y, optargs);
	if userStats ~= nil then
		local gamesLost = userStats.gamesPlayed - userStats.gamesWon;
		local text = userStats.gamesWon .. " / " .. gamesLost; -- todo: RATIO  98 / 40 (2.1:1)
		ui2Label(text, x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Damage Given / Received:", x, y, optargs);
	if userStats ~= nil then
		local text = userStats.damageGiven .. " / " .. userStats.damageReceived; -- todo: RATIO 98,423 / 160,123 (1:1.5)
		ui2Label(text, x + colIndent, y, optargs);
	end
	y = y + 60;	
	y = y + 60;	
	
	optargs.enabled = false;
	ui2Label("Movement", x, y, optargs);
	optargs.enabled = true;
	y = y + 60;	

	ui2Label("Jump Counter:", x, y, optargs);
	if userStats ~= nil then
		ui2Label(CommaValue(userStats.jumpCounter), x + colIndent, y, optargs);
	end
	y = y + 60;		

	ui2Label("Distance Travelled:", x, y, optargs);
	if userStats ~= nil then
		ui2Label(CommaValue(math.ceil(userStats.distanceTravelled)) .. " units", x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Air Time:", x, y, optargs);
	if userStats ~= nil then
		ui2Label(FormatSecondsToString(math.ceil(userStats.airTime)), x + colIndent, y, optargs);
	end
	y = y + 60;	
	
	-- COL 2
	local x = 90;
	local y = -250;
	local colIndent = 150;
	
	optargs.enabled = false;
	ui2Label("Combat", x, y, optargs);
	optargs.enabled = true;
	y = y + 60;	

	-- bar graph
	if self.statsWeaponHighlighted == nil then
		self.statsWeaponHighlighted = 1;
	end
	local xaxis = {};
	local yaxis = {};
	local bars = {};
	for weaponIndex, weaponDefinition in pairs(weaponDefinitions) do
		bars[weaponIndex] = {};
		bars[weaponIndex].value = 0;
		bars[weaponIndex].color = Color(weaponDefinition.color.r, weaponDefinition.color.g, weaponDefinition.color.b);
		bars[weaponIndex].color.a = 230;
		if userStats ~= nil then
			bars[weaponIndex].value = userStats.weapons[weaponIndex].averageEffectiveness / 100;
		end
	end
	xaxis.name = "Weapon";
	yaxis.name = "Effectiveness";
	optargs.bgIntensity = intensity * .5;
	optargs.selectedBar = self.statsWeaponHighlighted;
	local weaponHoveringOver;
	self.statsWeaponHighlighted, weaponHoveringOver = ui2BarGraph(x, y, 410, 200, xaxis, yaxis, bars, optargs);
	y = y + 300;
	
	-- effectiveness tooltip
	ui2TooltipBox("Effectiveness is how much damage you did compared to how much it could have done. For example: a direct rocket is 100%, a direct Carnage rocket is 400%, a splash rocket may be 50%.", x - 43, y - 284, 600, optargs);

	-- now specifics for selected weapon
	local statsWeaponHighlighted = weaponHoveringOver ~= nil and weaponHoveringOver or self.statsWeaponHighlighted;
	local userStatsWeapon = userStats ~= nil and userStats.weapons[statsWeaponHighlighted] or nil;

	-- title
	local svgName = "internal/ui/icons/weapon"..statsWeaponHighlighted;
	local iconRad = 12;
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 1, optargs.enabled));
	nvgSvg(svgName, x+iconRad, y+35/2, iconRad);
	ui2FontNormal();
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x+iconRad*2+6, y + 35*0.5, weaponDefinitions[statsWeaponHighlighted].name);
	optargs.enabled = true;
	y = y + 60;	

	ui2Label("Kills:" , x, y, optargs);
	if userStatsWeapon ~= nil then
		ui2Label(CommaValue(userStatsWeapon.kills), x + colIndent, y, optargs);
	end
	y = y + 60;	
	
	ui2Label("Damage Done:" , x, y, optargs);
	if userStatsWeapon ~= nil then
		ui2Label(CommaValue(userStatsWeapon.damageDone), x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Hits / Shots:" , x, y, optargs);
	if userStatsWeapon ~= nil then
		local text = CommaValue(userStatsWeapon.hits) .. " / " .. CommaValue(userStatsWeapon.shots);
		ui2Label(text, x + colIndent, y, optargs);
	end
	y = y + 60;	

	ui2Label("Time Held:" , x, y, optargs);
	if userStatsWeapon ~= nil then
		ui2Label(FormatSecondsToString(math.ceil(userStatsWeapon.heldTime)), x + colIndent, y, optargs);
	end
	y = y + 60;	
		
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileAwards(intensity)
	local optargs = {
		intensity = intensity
	};
	local colWidth = 530;
	local colIndent = 150;
	local iconColOff = Color(128, 128, 128, 128);
	local iconColOn = Color(212, 16, 8, 255);
	local iconRad = 20;
	local enabled = true;

	nvgSave();
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE);

	local userStats = steamUserStats[steamId];
	local hoverTable = {};
	local hoverCount = 0;
	
	-- COL 1
	local x = -620;
	local y = -250;
	for k, v in pairs(awardDefinitions) do
		if k < AWARD_XPBONUS then
			local w = nvgTextWidth(v.name) + iconRad+40;
			local m = mouseRegion(x, y, w, 40, k);
			local numberGot = 0;
			if userStats ~= nil then
				numberGot = userStats.awards[k];
			end
		
			-- label
			ui2FontNormal();
			local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled, m.leftHeld);
			local ix = x+iconRad+30;
			nvgFillColor(col);
			nvgText(ix, y+27, v.name);
			ix = ix + nvgTextWidth(v.name);

			-- count
			ui2FontSmall();
			if numberGot > 0 then
				local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, enabled, m.leftHeld);
				nvgFillColor(col);
				nvgText(ix, y+27, " x" .. numberGot);
			end
		
			-- have we got it yet?
			local gotIt = numberGot > 0;
			local col = gotIt and iconColOn or iconColOff;
		
			nvgFillColor(Color(col.r, col.g, col.b, col.a * intensity));
			nvgSvg(v.icon, x+iconRad, y+iconRad, iconRad);

			if m.hoverAmount > 0.5 then
				hoverCount = 1;
				hoverTable[hoverCount] = {};
				hoverTable[hoverCount].m = m;
				hoverTable[hoverCount].v = v;
			end
		
			y = y + 60;	

			if y > 440 then
				y = -250;
				x = x + 320;
			end
		end
	end

	-- draw hover text on top
	--ui2FontSmall();
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgTextLineHeight(.8);
	for h = 1, hoverCount do
		local m = hoverTable[1].m;
		local v = hoverTable[1].v;
		local hoverIntensity = 1; -- intensity * m.hoverAmount;

		local text = v.desc;
		local title = v.name;
		local breakRowWidth = 700;
		local icon = v.icon;
		local iconScale = v.iconScale;

		ui2DrawHoverWindow(self.mouseX + 5, self.mouseY + 5, breakRowWidth, title, text, icon, iconColOn, iconScale);
		
		y = y + 60;	

		if y > 440 then
			y = -250;
			x = x + 300;
		end
	end
		
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawMelee(x, y, row, itemDef, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	-- text
	local name = itemDef.name;
	if itemDef.storeHidden then
		name = name .. " (H)";
	end
	--name = name .. " ("..itemDef.defId..")"
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled);
	col.r = itemDef.color.r;
	col.g = itemDef.color.g;
	col.b = itemDef.color.b;
	ui2FontSmall();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgText(x+w/2, y+h/2, name);

	-- icon
	if itemDef.ownedCount > 0 then
		local ix = x + 17;
		local iy = y + h/2+1;
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
		nvgSvg("internal/ui/icons/tick", ix, iy, 8);
	end

	-- count text
	if itemDef.ownedCount > 1 then
		local text = "x" .. itemDef.ownedCount;
		col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, enabled);
		ui2FontSmall();
		nvgFillColor(col);
		nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BOTTOM);
		nvgText(x+w-5, y+h-3, text);
	end

	return m.leftUp;
end
		
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:inventoryRefreshSpamStart()
	self.inventorySpamRefresh = true;
	self.inventorySpamTimer = 0;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function inventoryDeselected()

	-- stop inventory spam
	Menu.inventorySpamRefresh = false;

	-- clear selection
	Menu.selected_inventory_definition_id = nil;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileGeneric(intensity, cvar, slot)
	local optargs = {
		intensity = intensity,
	};
	nvgSave();

	local name = FirstToUpper(slot);

	-- COL 2
	local colWidth = 540;
	local colIndent = 150;
	local x = 90;
	local y = -250;
	
	-- if selected inventory doesn't fit this slot, de-select it
	if self.selected_inventory_definition_id ~= nil then
		local def = inventoryDefinitions[self.selected_inventory_definition_id];
		if def ~= nil and def.slot ~= slot then
			self.selected_inventory_definition_id  = nil;
		end
	end

	-- inspect instances..
	local definitonsOwned = {};
	local definitonsInstanceIds = {};
	local instanceIdHolding = consoleGetVariable(cvar);
	for k, v in pairs(inventoryInstances) do
		-- count how many we have of this
		if definitonsOwned[v.definitionId] == nil then definitonsOwned[v.definitionId] = 0 end;
		definitonsOwned[v.definitionId] = definitonsOwned[v.definitionId] + 1;

		-- record a single instance of each defId
		definitonsInstanceIds[v.definitionId] = v.instanceId;

		-- if this instance is the one we're currently holding?
		if instanceIdHolding == v.instanceId then
			if self.selected_inventory_definition_id == nil then
				self.selected_inventory_definition_id = v.definitionId;
			end
		end
	end

	-- inspect definitions
	local orderedInventoryDefinitions = {};
	local orderedInventoryDefinitionCount = 0;
	local orderedInventoryDefinitionSelected = nil;
	for k, v in pairs(inventoryDefinitions) do
		if v.slot == slot then
			orderedInventoryDefinitionCount = orderedInventoryDefinitionCount + 1;
			orderedInventoryDefinitions[orderedInventoryDefinitionCount] = v;
			orderedInventoryDefinitions[orderedInventoryDefinitionCount].ownedCount = definitonsOwned[k] and definitonsOwned[k] or 0;
			orderedInventoryDefinitions[orderedInventoryDefinitionCount].defId = k;

			if k == self.selected_inventory_definition_id then
				orderedInventoryDefinitionSelected = orderedInventoryDefinitions[orderedInventoryDefinitionCount];
			end
		end
	end

	-- sort items
	local function SortInventory(a, b)
		if a.quality == b.quality then
			return a.name < b.name;
		end
		return a.quality < b.quality;
	end
	table.sort(orderedInventoryDefinitions, SortInventory);

	optargs.enabled = false;
	ui2Label(name, x, y, optargs);
	y = y + 60;
	optargs.enabled = true;

	-- draw melee
	optargs.itemHeight = 35;
	optargs.itemDrawFunction = ui2DrawMelee;
	optargs.itemPad = 5;
	orderedInventoryDefinitionSelected = ui2ScrollSelection(
		orderedInventoryDefinitions, orderedInventoryDefinitionSelected, x, y, colWidth, 355, self.scrollBarDataInventoryMelee, optargs);
	if orderedInventoryDefinitionSelected ~= nil then
		self.selected_inventory_definition_id = orderedInventoryDefinitionSelected.defId;
	end
	y = y + 355 + 55;

	-- show selected melee
	if self.selected_inventory_definition_id ~= nil then
		playerPreviewSetHoverInventory(slot, self.selected_inventory_definition_id);
	end

	local needToBuy = false;
	local canBuy = true;
	local competitivePointsCost = 0
	if self.selected_inventory_definition_id ~= nil and not definitonsOwned[self.selected_inventory_definition_id] then
		needToBuy = true;
		competitivePointsCost = inventoryDefinitions[self.selected_inventory_definition_id].competitvePointCost;
	end

	-- buy/accept
	optargs.enabled = self.selected_inventory_definition_id ~= nil;
	local buttonText = "Accept"
	if needToBuy then
		if competitivePointsCost > 0 then
			buttonText = string.format("Buy (%d Comp. Points)", competitivePointsCost)
			if competitivePointsCost > inventoryCompetitivePoints then
				optargs.enabled = false
				optargs.hoverText = "You only have " .. inventoryCompetitivePoints .. " Competitive Points";
			end
		else
			buttonText = "Buy (In Store)"
			canBuy = false;	-- can't directly buy this item (probably comes from crates, so don't offer buy button)
		end
	end
	if canBuy and ui2Button(buttonText, x+colWidth-280, y, 280, 35, optargs) then
		if needToBuy then
			if competitivePointsCost > 0 then
				showAsPopup("BuyWithCompetitivePoints", self.selected_inventory_definition_id)
				self.inventorySpamRefresh = true;
				self.inventorySpamTimer = 0;
			else
				inventoryPurchase(self.selected_inventory_definition_id);
				self.inventorySpamRefresh = true;
				self.inventorySpamTimer = 0;
			end
		else
			-- select it
			consolePerformCommand(cvar .. " " .. definitonsInstanceIds[self.selected_inventory_definition_id]);
			
			-- switch back to profile sub screen
			self.modes[4].subKey = 1;
		end
	end
	optargs.enabled = true;
	optargs.hoverText = nil;

	-- cancel
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("Cancel", x+colWidth-420-120, y, 240, 35, optargs) then
		-- switch back to profile sub screen
		self.modes[4].subKey = 1;
	end

	-- description
	y = y + 120;
	if self.selected_inventory_definition_id ~= nil then
		local description = inventoryDefinitions[self.selected_inventory_definition_id].description;
		
		nvgSave();
		ui2FontNormal();
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 1, true));

		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE);
		nvgTextBox(x, y, colWidth, description);
		nvgRestore();
	end

	-- spam inventory refresh? we do this after clicking BUY as we don't get informed when the purchase is completed
	if self.inventorySpamRefresh then
		self.inventorySpamTimer = self.inventorySpamTimer + deltaTimeRaw;
		if self.inventorySpamTimer > 5 then
			inventoryRefresh();
			self.inventorySpamTimer = 0;
		end
	end
		
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileMelee(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playermelee", "melee");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileHead(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerhead", "head");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileLegs(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerlegs", "legs");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileArms(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerarms", "arms");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileTorso(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playertorso", "torso");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileBurstgun(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerburstgun", "burstgun");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileShotgun(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playershotgun", "shotgun");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileGrenadeLauncher(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playergrenadelauncher", "grenadelauncher");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfilePlasmaRifle(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerplasmarifle", "plasmarifle");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileRocketLauncher(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerrocketlauncher", "rocketlauncher");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileIonCannon(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerioncannon", "ioncannon");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawProfileBoltRifle(intensity)
	self:ui2DrawProfileGeneric(intensity, "cl_playerboltrifle", "boltrifle");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsSystem(intensity)	
	local optargs = {
		intensity = intensity
	};
	local col1Width = 650;
	local col1Indent = 250;
	
	-- s1 == current settings
	local s1 = {};
	s1.r_vsync					= consoleGetVariable("r_vsync");
	s1.r_showfps				= consoleGetVariable("r_showfps");
	s1.com_maxfps				= consoleGetVariable("com_maxfps");
	s1.r_resolution_fullscreen	= consoleGetVariable("r_resolution_fullscreen");
	s1.r_resolution_windowed	= consoleGetVariable("r_resolution_windowed");
	s1.r_adapter				= consoleGetVariable("r_adapter");
	s1.r_fullscreen				= consoleGetVariable("r_fullscreen");
	s1.r_refreshrate			= consoleGetVariable("r_refreshrate");
	s1.s_volume					= consoleGetVariable("s_volume");
	s1.s_music_volume			= consoleGetVariable("s_music_volume");
	s1.s_effects_volume			= consoleGetVariable("s_effects_volume");
	s1.s_announcer_volume		= consoleGetVariable("s_announcer_volume");

	-- no r_adapter => use default
	if string.len(s1.r_adapter) <= 0 then
		s1.r_adapter = renderAdapter;
	end

	-- if we don't have a selection then pull in the current values
	if self.selected_r_fullscreen == nil then
		self.selected_r_fullscreen = s1.r_fullscreen;
	end
	if self.selected_r_refreshrate == nil then
		self.selected_r_refreshrate = s1.r_refreshrate;
	end
	if self.selected_r_resolution_fullscreen == nil then
		self.selected_r_resolution_fullscreen = s1.r_resolution_fullscreen;
	end
	if self.selected_r_resolution_windowed == nil then
		self.selected_r_resolution_windowed = s1.r_resolution_windowed;
	end

	-- s2 = new settings
	local s2 = {};
	
	nvgSave();

	-- COL 1
	local x = -620;
	local y = -250;
	ui2Label("Graphics Adapter", x, y, optargs);
	local adapters = {};
	local adapterCount = 0;
	for k, v in pairs(renderAdapters) do
		adapterCount = adapterCount + 1;
		adapters[adapterCount] = v.name;
	end
	local adapterComboX = x + col1Indent;
	local adapterComboY = y;
	local adapterComboComboWidth = col1Width - col1Indent;
	if adapterCount == 1 then
		ui2Label(adapters[1], x+col1Indent, y, optargs);
	elseif adapterCount > 1 then
		if renderAdapter ~= s1.r_adapter then
			local tx = x + col1Width;
			
			nvgFontSize(FONT_SIZE_DEFAULT);
			nvgFontFace(FONT_TEXT);
			nvgFillColor(Color(232,0,0,255*intensity));
			ui2FontNormal();

			nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
			nvgText(tx+4, y+16, "(Requires Restart)");
		end
	end
	y = y + 60;
	
	ui2Label("Display Mode", x, y, optargs);
	local displayMode = self.selected_r_fullscreen ~= 0 and "Fullscreen" or "Windowed";
	local displayModes = { "Fullscreen", "Windowed" };
	local displayComboX = x + col1Indent;
	local displayComboY = y;
	local displayComboWidth = col1Width - col1Indent;
	y = y + 60;

	-- resolution
	local resolutions = {};
	local r = 1;
	for k, v in pairs(renderModes) do
		local s = v.width.."x"..v.height;
		if r <= 1 or resolutions[r-1] ~= s then
			resolutions[r] = s;
			r = r + 1;
		end
	end
	local resolution = self.selected_r_resolution_windowed[1].."x"..self.selected_r_resolution_windowed[2];
	if self.selected_r_fullscreen ~= 0 then
		resolution = self.selected_r_resolution_fullscreen[1].."x"..self.selected_r_resolution_fullscreen[2];
	end
	ui2Label("Resolution", x, y, optargs);
	local resolutionComboX = x+col1Indent;
	local resolutionComboY = y;
	local resolutionComboWidth = col1Width - col1Indent;
	y = y + 60;
	
	-- refresh rate
	local refreshRateSelectedOkay = false;
	local refreshRateFallback = 60;
	local refreshRates = {};
	local r = 1;
	for k, v in pairs(renderModes) do
		if v.width == self.selected_r_resolution_fullscreen[1] and v.height == self.selected_r_resolution_fullscreen[2] then
			refreshRates[r] = string.format("%.2f", v.refreshRate) .. "Hz";
			r = r + 1;

			-- checking if the selected resfresh rate is suitable at this resolution
			if clampTo2Decimal(v.refreshRate) == self.selected_r_refreshrate then
				refreshRateSelectedOkay = true;
			end
			
			-- remember the highest refresh rate to fallback on
			if refreshRateFallback == nil then 
				refreshRateFallback = v.refreshRate;
			elseif refreshRateFallback < v.refreshRate then
				refreshRateFallback = v.refreshRate;
			end				
		end
	end
	if not refreshRateSelectedOkay then
		self.selected_r_refreshrate = refreshRateFallback;
	end
	ui2Label("Refresh Rate", x, y, optargs);
	local refreshRate = string.format("%.2f", self.selected_r_refreshrate) .. "Hz";
	if self.selected_r_fullscreen == 0 then refreshRate = "-" end;
	local refreshRateComboX = x+col1Indent;
	local refreshRateComboY = y;
	local refreshRateComboWidth = col1Width - col1Indent;
	local refreshRateComboEnabled = self.selected_r_fullscreen ~= 0;
	y = y + 60;
	
	-- apply button
	local resDifferent = self.selected_r_fullscreen ~= s1.r_fullscreen;
	if self.selected_r_fullscreen ~= 0 then
		resDifferent = 
			resDifferent or
			self.selected_r_refreshrate ~= clampTo2Decimal(s1.r_refreshrate) or
			self.selected_r_resolution_fullscreen[1] ~= s1.r_resolution_fullscreen[1] or
			self.selected_r_resolution_fullscreen[2] ~= s1.r_resolution_fullscreen[2];
	else
		resDifferent = 
			resDifferent or
			self.selected_r_resolution_windowed[1] ~= s1.r_resolution_windowed[1] or
			self.selected_r_resolution_windowed[2] ~= s1.r_resolution_windowed[2];
	end
	optargs.enabled = resDifferent;
	if ui2Button("APPLY", x+col1Width-200, y, 200, 40, optargs) then
		if self.selected_r_fullscreen == 0 then
			s2.r_resolution_windowed = {};
			s2.r_resolution_windowed[1] = self.selected_r_resolution_windowed[1];
			s2.r_resolution_windowed[2] = self.selected_r_resolution_windowed[2];
		else
			s2.r_resolution_fullscreen = {};
			s2.r_resolution_fullscreen[1] = self.selected_r_resolution_fullscreen[1];
			s2.r_resolution_fullscreen[2] = self.selected_r_resolution_fullscreen[2];
		end

		s2.r_fullscreen = self.selected_r_fullscreen;
		s2.r_refreshrate = self.selected_r_refreshrate;
	end
	optargs.enabled = true;
	y = y + 60;
	y = y + 60;

	ui2Label("Sound Adapter", x, y, optargs);
	ui2Label(soundAdapter, x+col1Indent, y, optargs);
	y = y + 60;
	
	ui2Label("Global Volume", x, y, optargs);
	local newValue = tonumber(ui2EditBox(math.floor(s1.s_volume*100), x+col1Indent+340, y, col1Width - col1Indent-340, optargs));
	if newValue ~= nil and newValue ~= math.floor(s1.s_volume*100) and string.len(newValue) > 0 then
		s2.s_volume = newValue / 100;
	end
	local newSliderValue = ui2Slider(x+col1Indent, y, 320, 0, 1, s1.s_volume, optargs);
	if not isEqual(newSliderValue, s1.s_volume) then
		s2.s_volume = newSliderValue;
	end
	y = y + 60;
	
	ui2Label("Effects Volume", x, y, optargs);
	local newValue = tonumber(ui2EditBox(math.floor(s1.s_effects_volume*100), x+col1Indent+340, y, col1Width - col1Indent-340, optargs));
	if newValue ~= nil and newValue ~= math.floor(s1.s_effects_volume*100) and string.len(newValue) > 0 then
		s2.s_effects_volume = newValue / 100;
	end
	local newSliderValue = ui2Slider(x+col1Indent, y, 320, 0, 1, s1.s_effects_volume, optargs);
	if not isEqual(newSliderValue, s1.s_music_volume) then
		s2.s_effects_volume = newSliderValue;
	end
	y = y + 60;
	
	ui2Label("Announcer Volume", x, y, optargs);
	local newValue = tonumber(ui2EditBox(math.floor(s1.s_announcer_volume*100), x+col1Indent+340, y, col1Width - col1Indent-340, optargs));
	if newValue ~= nil and newValue ~= math.floor(s1.s_announcer_volume*100) and string.len(newValue) > 0 then
		s2.s_announcer_volume = newValue / 100;
	end
	local newSliderValue = ui2Slider(x+col1Indent, y, 320, 0, 1, s1.s_announcer_volume, optargs);
	if not isEqual(newSliderValue, s1.s_music_volume) then
		s2.s_announcer_volume = newSliderValue;
	end
	y = y + 60;
	
	ui2Label("Music Volume", x, y, optargs);
	local newValue = tonumber(ui2EditBox(math.floor(s1.s_music_volume*100), x+col1Indent+340, y, col1Width - col1Indent-340, optargs));
	if newValue ~= nil and newValue ~= math.floor(s1.s_music_volume*100) and string.len(newValue) > 0 then
		s2.s_music_volume = newValue / 100;
	end
	local newSliderValue = ui2Slider(x+col1Indent, y, 320, 0, 1, s1.s_music_volume, optargs);
	if not isEqual(newSliderValue, s1.s_music_volume) then
		s2.s_music_volume = newSliderValue;
	end
	y = y + 60;

	-- COL 2
	local col2Width = 440;
	local x = 180;
	local y = -250;
	y = y + 60;
	
	ui2Label("FPS Cap", x, y, optargs);
	local fpsCapComboOptions = { "60", "90", "125", "144", "167", "200", "250", "333", "500", "1000", "Unlimited" };
	local fpsCap = s1.com_maxfps;
	if fpsCap == 0 then
		fpsCap = "Unlimited";
	end
	local fpsCapComboX = x+col1Indent;
	local fpsCapComboY = y;
	local fpsCapComboWidth = col2Width - col1Indent;
	y = y + 60;
	
	ui2Label("VSync", x, y, optargs);
	s2.r_vsync = ui2CheckBox(s1.r_vsync ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Show FPS", x, y, optargs);
	s2.r_showfps = ui2CheckBox(s1.r_showfps ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;

	-- combo: refreshrate
	optargs.enabled = refreshRateComboEnabled;
	local refreshRateUi = ui2ComboBox(refreshRates, refreshRate, refreshRateComboX, refreshRateComboY, refreshRateComboWidth, self.comboBoxDataRefreshRate, optargs);
	self.selected_r_refreshrate = tonumber(string.sub(refreshRateUi, 0, -3));
	--consolePrint(self.selected_r_refreshrate);
	optargs.enabled = true;

	-- combo: resolution	
	local resolutionUi = ui2ComboBox(resolutions, resolution, resolutionComboX, resolutionComboY, resolutionComboWidth, self.comboBoxDataResolution, optargs);
	local selectedRes = {};
	selectedRes[1], selectedRes[2] = string.match(resolutionUi, "(%d+)x(%d+)")
	selectedRes[1] = tonumber(selectedRes[1]);
	selectedRes[2] = tonumber(selectedRes[2]);
	if self.selected_r_fullscreen ~= 0 then
		self.selected_r_resolution_fullscreen[1] = selectedRes[1];
		self.selected_r_resolution_fullscreen[2] = selectedRes[2];
	else
		self.selected_r_resolution_windowed[1] = selectedRes[1];
		self.selected_r_resolution_windowed[2] = selectedRes[2];
	end

	-- combo: display mode
	local displayModeUi = ui2ComboBox(displayModes, displayMode, displayComboX, displayComboY, displayComboWidth, self.comboBoxDataDisplayMode, optargs);
	self.selected_r_fullscreen = displayModeUi == "Fullscreen" and 1 or 0;
	
	-- combo: adapter	
	if adapterCount > 1 then
		s2.r_adapter = ui2ComboBox(adapters, s1.r_adapter, adapterComboX, adapterComboY, adapterComboComboWidth, self.comboBoxDataAdapter, optargs);
	end
	
	-- combo: FPS cap
	local maxFpsUi = ui2ComboBox(fpsCapComboOptions, fpsCap, fpsCapComboX, fpsCapComboY, fpsCapComboWidth, self.comboBoxDataMaxFPS, optargs);
	if maxFpsUi == "Unlimited" then maxFpsUi = 0 end;
	maxFpsUi = tonumber(maxFpsUi);
	s2.com_maxfps = maxFpsUi;
	
	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsGraphics(intensity)
	local optargs = {
		intensity = intensity
	};
	local col1Width = 650;
	local col1Indent = 250;

	-- graphics presets
	-- low
	local settingsLow = {};
	settingsLow.r_shader_quality			= 0;
	settingsLow.r_texture_quality			= 0;
	settingsLow.r_texture_resolution		= 0;
	settingsLow.r_effect_quality			= 0;
	settingsLow.r_shadow_quality			= 0;
	settingsLow.r_shadow_resolution			= 0;
	settingsLow.r_decals					= 1;
	settingsLow.r_bloom						= 0;
	settingsLow.r_dynamic_lights			= 1;
	settingsLow.r_fxaa						= 0;
	settingsLow.r_smaa						= 0;
	settingsLow.r_hbao						= 0;
	settingsLow.r_sun						= 1;
	settingsLow.r_fog						= 1;
	settingsLow.r_mesh_quality				= 0;
	settingsLow.r_texture_memory_stream_cache = 64;

	-- medium
	local settingsMedium = {};
	settingsMedium.r_shader_quality			= 1;
	settingsMedium.r_texture_quality		= 1;
	settingsMedium.r_texture_resolution		= 1;
	settingsMedium.r_effect_quality			= 1;
	settingsMedium.r_shadow_quality			= 1;
	settingsMedium.r_shadow_resolution		= 0;
	settingsMedium.r_decals					= 1;
	settingsMedium.r_bloom					= 1;
	settingsMedium.r_dynamic_lights			= 1;
	settingsMedium.r_smaa					= 2;
	settingsMedium.r_hbao					= 0;
	settingsMedium.r_sun					= 1;
	settingsMedium.r_fog					= 1;
	settingsMedium.r_mesh_quality			= 1;
	settingsMedium.r_texture_memory_stream_cache = 256;

	-- high
	local settingsHigh = {};
	settingsHigh.r_shader_quality			= 2;
	settingsHigh.r_texture_quality			= 2;
	settingsHigh.r_texture_resolution		= 2;
	settingsHigh.r_effect_quality			= 2;
	settingsHigh.r_shadow_quality			= 1;
	settingsHigh.r_shadow_resolution		= 0;
	settingsHigh.r_decals					= 1;
	settingsHigh.r_bloom					= 1;
	settingsHigh.r_dynamic_lights			= 1;
	settingsHigh.r_smaa						= 3;
	settingsHigh.r_hbao						= 0;
	settingsHigh.r_sun						= 1;
	settingsHigh.r_fog						= 1;
	settingsHigh.r_mesh_quality				= 1;
	settingsHigh.r_texture_memory_stream_cache = 512;

	-- ultra
	local settingsUltra = {};
	settingsUltra.r_shader_quality			= 2;
	settingsUltra.r_texture_quality			= 2;
	settingsUltra.r_texture_resolution		= 2;
	settingsUltra.r_effect_quality			= 2;
	settingsUltra.r_shadow_quality			= 2;
	settingsUltra.r_shadow_resolution		= 1;
	settingsUltra.r_decals					= 1;
	settingsUltra.r_bloom					= 1;
	settingsUltra.r_dynamic_lights			= 1;
	settingsUltra.r_smaa					= 3;
	settingsUltra.r_hbao					= 1;
	settingsUltra.r_sun						= 1;
	settingsUltra.r_fog						= 1;
	settingsUltra.r_mesh_quality			= 2;
	settingsUltra.r_texture_memory_stream_cache = 512;
	
	-- s1 == current settings
	local s1 = {};
	s1.r_hbao						= consoleGetVariable("r_hbao");
	s1.r_shader_quality				= consoleGetVariable("r_shader_quality");
	s1.r_texture_quality			= consoleGetVariable("r_texture_quality");
	s1.r_texture_resolution			= consoleGetVariable("r_texture_resolution");
	s1.r_effect_quality				= consoleGetVariable("r_effect_quality");
	s1.r_shadow_quality				= consoleGetVariable("r_shadow_quality");
	s1.r_shadow_resolution			= consoleGetVariable("r_shadow_resolution");
	s1.r_mesh_quality				= consoleGetVariable("r_mesh_quality");
	s1.r_decals						= consoleGetVariable("r_decals");
	s1.r_bloom						= consoleGetVariable("r_bloom");
	s1.r_fxaa						= consoleGetVariable("r_fxaa");
	s1.r_smaa						= consoleGetVariable("r_smaa");
	s1.r_hbao						= consoleGetVariable("r_hbao");
	s1.r_dynamic_lights				= consoleGetVariable("r_dynamic_lights");
	s1.r_sun						= consoleGetVariable("r_sun");
	s1.r_fog						= consoleGetVariable("r_fog");
	s1.r_texture_memory_stream_cache= consoleGetVariable("r_texture_memory_stream_cache");

	-- s2 = new settings
	local s2 = {};
	
	nvgSave();
	
	-- determine which preset we're on
	local preset = "Custom";
	if tableEqual(settingsLow, s1) then
		preset = "Low";
	elseif tableEqual(settingsMedium, s1) then
		preset = "Medium";
	elseif tableEqual(settingsHigh, s1) then
		preset = "High";
	elseif tableEqual(settingsUltra, s1) then
		preset = "Ultra";
	end

	-- COL 1
	local x = -620;
	local y = -250;
	ui2Label("Graphics Preset", x, y, optargs);
	local graphicsPresetModes = { "Low", "Medium", "High", "Ultra", "Custom" };
	local graphicsPresetComboX = x + col1Indent;
	local graphicsPresetComboY = y;
	local graphicsPresetComboWidth = col1Width - col1Indent;
	y = y + 30;
	y = y + 60;
	
	-- low/med/high selections
	local modesLMH = { [1] = "Low", [2] = "Medium", [3] = "High" };
	local function modeToNumber(mode)
		if mode == "High" then return 2;
		elseif mode == "Medium" then return 1;
		else return 0;
		end
	end
	local function numberToMode(number)
		if number == 2 then return "High" end;
		if number == 1 then return "Medium" end;
		return "Low";
	end
	
	ui2Label("Effect Quality", x, y, optargs);
	s2.r_effect_quality = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_effect_quality), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Shader Quality", x, y, optargs);
	s2.r_shader_quality = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_shader_quality), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Shadow Quality", x, y, optargs);
	s2.r_shadow_quality = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_shadow_quality), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Shadow Resolution", x, y, optargs);
	s2.r_shadow_resolution = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_shadow_resolution), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Texture Quality", x, y, optargs);
	s2.r_texture_quality = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_texture_quality), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Texture Resolution", x, y, optargs);
	s2.r_texture_resolution = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_texture_resolution), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	ui2Label("Texture Stream Cache", x, y, optargs);
	local modeText = "Custom"
	local modesSelection = { [1] = "Medium", [2] = "Custom", [3] = "Medium" } 
	if s1.r_texture_memory_stream_cache == 64 then
		modeText = "Low"
		modesSelection = modesLMH
	elseif s1.r_texture_memory_stream_cache == 256 then
		modeText = "Medium"
		modesSelection = modesLMH
	elseif s1.r_texture_memory_stream_cache == 512 then
		modeText = "High"
		modesSelection = modesLMH
	end
	local r_texture_memory_stream_cache_new = ui2Spinner(modesSelection, modeText, x+col1Indent, y, col1Width - col1Indent, optargs);
	if r_texture_memory_stream_cache_new == "Low" then
		s2.r_texture_memory_stream_cache = 64
	elseif r_texture_memory_stream_cache_new == "Medium" then
		s2.r_texture_memory_stream_cache = 256
	elseif r_texture_memory_stream_cache_new == "High" then
		s2.r_texture_memory_stream_cache = 512
	end		
	y = y + 60;
	
	ui2Label("Mesh Quality", x, y, optargs);
	s2.r_mesh_quality = modeToNumber(ui2Spinner(modesLMH, numberToMode(s1.r_mesh_quality), x+col1Indent, y, col1Width - col1Indent, optargs));
	y = y + 60;
	
	local function modeToNumber(mode)
		if mode == "High" then return 2;
		elseif mode == "Medium" then return 1;
		else return 0;
		end
	end
	local function numberToMode(number)
		if number == 2 then return "High" end;
		if number == 1 then return "Medium" end;
		return "Low";
	end

	-- aa
	local modesAA = { [1] = "None", [2] = "FXAA Low", [3] = "FXAA Medium", [4] = "FXAA High", [5] = "SMAA Low", [6] = "SMAA High", [7] = "SMAA Ultra" };
	local modeAA = "None";
	if s1.r_fxaa == 1 then modeAA = "FXAA Low" end;
	if s1.r_fxaa == 2 then modeAA = "FXAA Medium" end;
	if s1.r_fxaa == 3 then modeAA = "FXAA High" end;
	if s1.r_smaa == 1 then modeAA = "SMAA Low" end;
	if s1.r_smaa == 2 then modeAA = "SMAA High" end;
	if s1.r_smaa == 3 then modeAA = "SMAA Ultra" end;
	ui2Label("Anti-Aliasing", x, y, optargs);
	modeAA = ui2Spinner(modesAA, modeAA, x+col1Indent, y, col1Width - col1Indent, optargs);
	if modeAA == "None" then s2.r_fxaa = 0; s2.r_smaa = 0; end;
	if modeAA == "FXAA Low" then s2.r_fxaa = 1 end;
	if modeAA == "FXAA Medium" then s2.r_fxaa = 2 end;
	if modeAA == "FXAA High" then s2.r_fxaa = 3 end;
	if modeAA == "SMAA Low" then s2.r_smaa = 1 end;
	if modeAA == "SMAA High" then s2.r_smaa = 2 end;
	if modeAA == "SMAA Ultra" then s2.r_smaa = 3 end;

	y = y + 60;

	-- COL 2
	local col2Width = 440; -- 510 is centered properly
	local x = 180;
	local y = -250;
	
	y = y + 30;
	y = y + 60;
	ui2Label("HBAO+", x, y, optargs);
	s2.r_hbao = ui2CheckBox(s1.r_hbao ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Dynamic Lights", x, y, optargs);
	s2.r_dynamic_lights = ui2CheckBox(s1.r_dynamic_lights ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Decals", x, y, optargs);
	s2.r_decals = ui2CheckBox(s1.r_decals ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Bloom", x, y, optargs);
	s2.r_bloom = ui2CheckBox(s1.r_bloom ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Fog", x, y, optargs);
	s2.r_fog = ui2CheckBox(s1.r_fog ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	ui2Label("Sun", x, y, optargs);
	s2.r_sun = ui2CheckBox(s1.r_sun ~= 0, x+col1Indent, y, optargs) and 1 or 0;
	y = y + 60;
	
	-- combos at the end so they overhang
	local presetSelected = ui2ComboBox(graphicsPresetModes, preset, graphicsPresetComboX, graphicsPresetComboY, graphicsPresetComboWidth, self.comboBoxDataGraphicsPreset, optargs);
	if preset ~= presetSelected then
		local t = {};
		if presetSelected == "Low" then t = settingsLow end;
		if presetSelected == "Medium" then t = settingsMedium end;
		if presetSelected == "High" then t = settingsHigh end;
		if presetSelected == "Ultra" then t = settingsUltra end;
		for k, v in pairs(t) do
			s2[k] = v;
		end
	end

	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsGame(intensity)
	
	local optargs = {
		intensity = intensity
	};
	local colWidth = 650;
	local colIndent = 250;

	-- gun model selection
	local gunModelModes =
	{
		["Off"] =
		{ 
			["cl_show_gun"] = 0, 
			["cl_weapon_offset_x"] = 0, 
			["cl_weapon_offset_y"] = -1.5, 
			["cl_weapon_offset_z"] = 7
		},
		["Left-Handed"] =
		{ 
			["cl_show_gun"] = 1, 
			["cl_weapon_offset_x"] = -6.5, 
			["cl_weapon_offset_y"] = -1.5, 
			["cl_weapon_offset_z"] = 7
		},
		["Centered"] =
		{ 
			["cl_show_gun"] = 1, 
			["cl_weapon_offset_x"] = 0, 
			["cl_weapon_offset_y"] = -1.5, 
			["cl_weapon_offset_z"] = 7
		},
		["Right-Handed"] =
		{ 
			["cl_show_gun"] = 1, 
			["cl_weapon_offset_x"] = 6.5, 
			["cl_weapon_offset_y"] = -1.5, 
			["cl_weapon_offset_z"] = 7
		}
	}
	
	local gibDurationModes =
	{
		["Off"] =
		{ 
			["cl_gibs_maxcount"] = 0, 
			["cl_gibs_expire_time"] = 4,
		},
		["Short"] =
		{ 
			["cl_gibs_maxcount"] = 64, 
			["cl_gibs_expire_time"] = 4,
		},
		["Medium"] =
		{ 
			["cl_gibs_maxcount"] = 128, 
			["cl_gibs_expire_time"] = 10,
		},
		["Long"] =
		{ 
			["cl_gibs_maxcount"] = 256, 
			["cl_gibs_expire_time"] = 20,
		}
	}
	
	local ragdollDurationModes =
	{
		["Off"] =
		{ 
			["cl_ragdoll_expire_time"] = 0,
		},
		["Short"] =
		{ 
			["cl_ragdoll_expire_time"] = 5,
		},
		["Medium"] =
		{ 
			["cl_ragdoll_expire_time"] = 10,
		},
		["Long"] =
		{ 
			["cl_ragdoll_expire_time"] = 20,
		}
	}

	-- s1 == current settings
	local s1 = {};
	s1.r_fov						= consoleGetVariable("r_fov");
	s1.r_gamma						= consoleGetVariable("r_gamma");
	s1.cl_show_gun					= consoleGetVariable("cl_show_gun");
	s1.cl_weapon_offset_x			= consoleGetVariable("cl_weapon_offset_x");
	s1.cl_weapon_offset_y			= consoleGetVariable("cl_weapon_offset_y");
	s1.cl_weapon_offset_z			= consoleGetVariable("cl_weapon_offset_z");
	s1.cl_gibs_maxcount				= consoleGetVariable("cl_gibs_maxcount");
	s1.cl_gibs_expire_time			= consoleGetVariable("cl_gibs_expire_time");
	s1.cl_weaponcycle				= consoleGetVariable("cl_weaponcycle");
	s1.r_silhouette					= consoleGetVariable("r_silhouette");
	
	s1.cl_ragdoll_expire_time		= consoleGetVariable("cl_ragdoll_expire_time");
	s1.cl_colors_relative			= consoleGetVariable("cl_colors_relative");
	s1.cl_color_enemy				= consoleGetVariable("cl_color_enemy");
	s1.cl_color_friend				= consoleGetVariable("cl_color_friend");

	-- s2 = new settings
	local s2 = {};
	
	nvgSave();

	-- COL 1
	local x = -620;
	local y = -250;

	--
	s2.r_fov = ui2RowSliderEditBox0Decimals(x, y, colIndent, colWidth, 70, "Field Of View (HOR+)", s1.r_fov, 70, 170, optargs);
	y = y + 60;	

	--
	s2.r_gamma = ui2RowSliderEditBox2Decimals(x, y, colIndent, colWidth, 70, "Gamma", s1.r_gamma, 1.5, 4.0, optargs);
	y = y + 60;	

	-- gun model
	local gunModelValue = "Custom";
	local gunModelKeys = { "Off", "Left-Handed", "Centered", "Right-Handed" };
	for k, v in pairs(gunModelModes) do
		if v.cl_show_gun == s1.cl_show_gun and v.cl_weapon_offset_x == s1.cl_weapon_offset_x and v.cl_weapon_offset_y == s1.cl_weapon_offset_y and v.cl_weapon_offset_z == s1.cl_weapon_offset_z then
			gunModelValue = k;
		end
	end
	local gunModelComboX = x + colIndent;
	local gunModelComboY = y;
	local gunModelComboWidth = colWidth - colIndent;
	ui2Label("Gun Model", x, y, optargs);
	y = y + 60;	

	-- gib duration
	local gibDurationValue = "Custom";
	local gibDurationKeys = { "Off", "Short", "Medium", "Long" };
	for k, v in pairs(gibDurationModes) do
		if v.cl_gibs_maxcount == s1.cl_gibs_maxcount and v.cl_gibs_expire_time == s1.cl_gibs_expire_time then
			gibDurationValue = k;
		end
	end
	local gibDurationComboX = x + colIndent;
	local gibDurationComboY = y;
	local gibDurationComboWidth = colWidth - colIndent;
	ui2Label("Gib Duration", x, y, optargs);
	y = y + 60;	
	
	--
	ui2Label("Ragdoll Duration", x, y, optargs);
	local ragdollDurationValue = "Custom";
	local ragdollDurationKeys = { "Off", "Short", "Medium", "Long" };
	for k, v in pairs(ragdollDurationModes) do
		if v.cl_ragdoll_expire_time == s1.cl_ragdoll_expire_time then
			ragdollDurationValue = k;
		end
	end
	local ragdollDurationComboX = x + colIndent;
	local ragdollDurationComboY = y;
	local ragdollDurationComboWidth = colWidth - colIndent;
	y = y + 60;
	
	--
	ui2Label("Player Silhouettes", x, y, optargs);
	s2.r_silhouette = ui2CheckBox(s1.r_silhouette ~= 0, x+colIndent, y, optargs) and 1 or 0;
	y = y + 60;
	
	--
	local len = ui2Label("Weapon Cycle", x, y, optargs);
	s2.cl_weaponcycle = ui2CheckBox(s1.cl_weaponcycle ~= 0, x+colIndent, y, optargs) and 1 or 0;
	ui2TooltipBox("If enabled, when pressing nextweapon with last weapon equiped, it will cycle back to first weapon", x + len, y, 400, optargs);
	y = y + 60;
	y = y + 60;
	
	--
	optargs.enabled = false;
	ui2Label("Color Overrides", x, y, optargs);
	optargs.enabled = true;
	y = y + 60;

	-- color overrides
	ui2Label("Enabled", x, y, optargs);
	s2.cl_colors_relative = ui2CheckBox(s1.cl_colors_relative ~= 0, x+colIndent, y, optargs) and 1 or 0;
	y = y + 60;	
	
	-- special button setup
	optargs.enabled = s1.cl_colors_relative ~= 0;
	optargs.texttype = "color";
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;

	ui2Label("Friend", x, y, optargs);
	if ui2Button(hexRgbToCol(s1.cl_color_friend), x+colIndent, y, 100, 35, optargs) then
		showAsPopup("ColorPicker", "ff" .. s1.cl_color_friend, "noalpha", "cl_color_friend %s");
	end
	y = y + 60;
		
	ui2Label("Enemy", x, y, optargs);
	if ui2Button(hexRgbToCol(s1.cl_color_enemy), x+colIndent, y, 100, 35, optargs) then
		showAsPopup("ColorPicker", "ff" .. s1.cl_color_enemy, "noalpha", "cl_color_enemy %s");
	end
	y = y + 60;

	-- restore from special button setup
	optargs.enabled = true;
	optargs.texttype = nil;
	optargs.bgcoltype = nil;
	
	-- combos at the end so they overhang
	local ragdollDurationValue = ui2ComboBox(ragdollDurationKeys, ragdollDurationValue, ragdollDurationComboX, ragdollDurationComboY, ragdollDurationComboWidth, self.comboBoxDataRagdollDuration, optargs);
	for k, v in pairs(ragdollDurationModes) do
		if k == ragdollDurationValue then
			for k1, v1 in pairs(v) do
				s2[k1] = v1;
			end
		end
	end
	local gibDurationValue = ui2ComboBox(gibDurationKeys, gibDurationValue, gibDurationComboX, gibDurationComboY, gibDurationComboWidth, self.comboBoxDataGibDuration, optargs);
	for k, v in pairs(gibDurationModes) do
		if k == gibDurationValue then
			for k1, v1 in pairs(v) do
				s2[k1] = v1;
			end
		end
	end
	local gunModelValue = ui2ComboBox(gunModelKeys, gunModelValue, gunModelComboX, gunModelComboY, gunModelComboWidth, self.comboBoxDataGunModel, optargs);
	for k, v in pairs(gunModelModes) do
		if k == gunModelValue then
			for k1, v1 in pairs(v) do
				s2[k1] = v1;
			end
		end
	end
	
	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsBinds(intensity)
	local optargs = {
		intensity = intensity
	};
	local colWidth = 330;
	local colIndent = 190;
	local colStride = 455;
	
	nvgSave();
	
	-- COP TOP
	local x = -620;
	local y = -250;
	ui2Label("Bind For", x, y, optargs);
	local bindForModes = { "Game", "Map Editor", "Replay Editor", };
	local bindForComboX = x + colIndent;
	local bindForComboY = y;
	local bindForComboWidth = colWidth - colIndent;
	if ui2Button("RESET ALL BINDS", x+colWidth+390, y, 200, 35, optargs) then
		showAsPopup("ConfirmResetBinds");
	end

	local scoreHookModes;
	local scoreHookComboX;
	local scoreHookComboY;
	local scoreHookComboWidth;
	
	y = y + 30;
	y = y + 60;
	
	local ytop = y;
	local vstride = 45;

	if self.activeBindFor == "Game" then
		-- COL LEFT	
		y = ytop;
		optargs.enabled = false;
		ui2Label("Player", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Attack", x, y, optargs);
		ui2KeyBind("+attack", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Jump", x, y, optargs);
		ui2KeyBind("+jump", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Crouch", x, y, optargs);
		ui2KeyBind("+crouch", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;
	
		ui2Label("Forward", x, y, optargs);
		ui2KeyBind("+forward", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;
	
		ui2Label("Back", x, y, optargs);
		ui2KeyBind("+back", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Left", x, y, optargs);
		ui2KeyBind("+left", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Right", x, y, optargs);
		ui2KeyBind("+right", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		optargs.enabled = false;
		ui2Label("Spectating", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Next Camera", x, y, optargs);
		ui2KeyBind("cl_camera_next_player", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Prev Camera", x, y, optargs);
		ui2KeyBind("cl_camera_prev_player", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Free Camera", x, y, optargs);
		ui2KeyBind("cl_camera_freecam", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		-- COL MIDDLE
		y = ytop;
		x = x + colStride;
		optargs.enabled = false;
		ui2Label("Weapons", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Next Weapon", x, y, optargs);
		ui2KeyBind("weaponnext", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Prev Weapon", x, y, optargs);
		ui2KeyBind("weaponprev", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Melee", x, y, optargs);
		ui2KeyBind("weapon 1", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Burst Gun", x, y, optargs);
		ui2KeyBind("weapon 2", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Shotgun", x, y, optargs);
		ui2KeyBind("weapon 3", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Grenades", x, y, optargs);
		ui2KeyBind("weapon 4", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Plasma", x, y, optargs);
		ui2KeyBind("weapon 5", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Rockets", x, y, optargs);
		ui2KeyBind("weapon 6", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Ion Cannon", x, y, optargs);
		ui2KeyBind("weapon 7", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Bolt Rifle", x, y, optargs);
		ui2KeyBind("weapon 8", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		-- COL RIGHT
		y = ytop;
		x = x + colStride;

		optargs.enabled = false;
		ui2Label("Chat & Scoreboard", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Chat", x, y, optargs);
		ui2KeyBind("say", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Team Chat", x, y, optargs);
		ui2KeyBind("sayteam", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Party Chat", x, y, optargs);
		ui2KeyBind("sayparty", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Show Scores", x, y, optargs);
		ui2KeyBind("+showscores", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Scores Cursor", x, y, optargs);
		ui2KeyBind("showscorescursor", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Scores Cursor Hook", x, y, optargs);
		scoreHookModes = { "(none)", "Attack", "Jump", };
		scoreHookComboX = x + colIndent;
		scoreHookComboY = y;
		scoreHookComboWidth = colWidth - colIndent;
		--ui2KeyBind("showscorescursor", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		optargs.enabled = false;
		ui2Label("Other", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Vote Yes", x, y, optargs);
		ui2KeyBind("vote_yes", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Vote No", x, y, optargs);
		ui2KeyBind("vote_no", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Ready", x, y, optargs);
		ui2KeyBind("ready", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Toggle Editor", x, y, optargs);
		ui2KeyBind("toggleeditor", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

		ui2Label("Mark Replay", x, y, optargs);
		ui2KeyBind("cl_replaymarker", x+colIndent, y, colWidth-colIndent, "game", optargs);
		y = y + vstride;

	elseif self.activeBindFor == "Map Editor" then
		-- COL LEFT	
		y = ytop;
		optargs.enabled = false;
		ui2Label("Common", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Primary", x, y, optargs);
		ui2KeyBind("+editorprimary", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
	
		ui2Label("Camera Drag", x, y, optargs);
		ui2KeyBind("+editorcameradrag", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
	
		ui2Label("Forward", x, y, optargs);
		ui2KeyBind("+forward", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
	
		ui2Label("Back", x, y, optargs);
		ui2KeyBind("+back", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Left", x, y, optargs);
		ui2KeyBind("+left", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Right", x, y, optargs);
		ui2KeyBind("+right", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		optargs.enabled = false;
		ui2Label("Chat", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Chat", x, y, "me", optargs);
		ui2KeyBind("say", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Team Chat", x, y, "me", optargs);
		ui2KeyBind("sayteam", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		-- COL MIDDLE
		y = ytop;
		x = x + colStride;

		optargs.enabled = false;
		ui2Label("Create / Destroy", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Clone", x, y, optargs);
		ui2KeyBind("editorclone", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Delete", x, y, optargs);
		ui2KeyBind("editordelete", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		optargs.enabled = false;
		ui2Label("Material", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Get Material", x, y, optargs);
		ui2KeyBind("me_getmaterial", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Set Material", x, y, optargs);
		ui2KeyBind("me_setmaterial", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		optargs.enabled = false;
		ui2Label("Other", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Undo", x, y, optargs);
		ui2KeyBind("editorundo", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Redo", x, y, optargs);
		ui2KeyBind("editorredo", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Show Properties", x, y, optargs);
		ui2KeyBind("me_showproperties 1", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Toggle Editor", x, y, optargs);
		ui2KeyBind("toggleeditor", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		y = ytop;
		x = x + colStride;

		optargs.enabled = false;
		ui2Label("Manipulate", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Multi Select", x, y, optargs);
		ui2KeyBind("+editormultiselect", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Move Vertical", x, y, optargs);
		ui2KeyBind("+editorvertical", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Face Modifier", x, y, optargs);
		ui2KeyBind("+editorfacemode", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Vertex Mode", x, y, optargs);
		ui2KeyBind("editortogglevertexmode", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Bridge Mode", x, y, optargs);
		ui2KeyBind("me_startbridge", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Rotate Inc", x, y, optargs);
		ui2KeyBind("me_rotate_inc", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Rotate Dec", x, y, optargs);
		ui2KeyBind("me_rotate_dec", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
		
		ui2Label("Segments Inc", x, y, optargs);
		ui2KeyBind("me_segments_inc", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;

		ui2Label("Segments Dec", x, y, optargs);
		ui2KeyBind("me_segments_dec", x+colIndent, y, colWidth-colIndent, "me", optargs);
		y = y + vstride;
		
	elseif self.activeBindFor == "Replay Editor" then
		
		-- COL LEFT	
		y = ytop;
		optargs.enabled = false;
		ui2Label("Common", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;
	
		ui2Label("Camera Drag", x, y, optargs);
		ui2KeyBind("+editorcameradrag", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;
	
		ui2Label("Forward", x, y, optargs);
		ui2KeyBind("+forward", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;
	
		ui2Label("Back", x, y, optargs);
		ui2KeyBind("+back", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Left", x, y, optargs);
		ui2KeyBind("+left", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;
	
		ui2Label("Strafe Right", x, y, optargs);
		ui2KeyBind("+right", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		-- COL MIDDLE
		y = ytop;
		x = x + colStride;

		optargs.enabled = false;
		ui2Label("Time", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Timeline Drag", x, y, optargs);
		ui2KeyBind("+editortimelinedrag", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		ui2Label("Pause", x, y, optargs);
		ui2KeyBind("re_speed 0", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		ui2Label("Play", x, y, optargs);
		ui2KeyBind("re_speed 1", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		ui2Label("Prev Frame", x, y, optargs);
		ui2KeyBind("re_prev_frame", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		ui2Label("Next Frame", x, y, optargs);
		ui2KeyBind("re_next_frame", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;

		-- COL RIGHT
		y = ytop;
		x = x + colStride;

		optargs.enabled = false;
		ui2Label("Other", x, y, optargs);
		optargs.enabled = true;
		y = y + vstride;

		ui2Label("Toggle Editor", x, y, optargs);
		ui2KeyBind("re_edit_toggle", x+colIndent, y, colWidth-colIndent, "re", optargs);
		y = y + vstride;	

	end
	
	-- combos at the end so they overhang
	self.activeBindFor = ui2ComboBox(bindForModes, self.activeBindFor, bindForComboX, bindForComboY, bindForComboWidth, self.comboBoxDataBindFor, optargs);
	if scoreHookModes ~= nil then
		local scoreHook = consoleGetVariable("showscorescursorhook");
		local scoreHookNew = ui2ComboBox(scoreHookModes, scoreHook, scoreHookComboX, scoreHookComboY, scoreHookComboWidth, self.comboBoxDataScoreHook, optargs);
		if scoreHookNew ~= scoreHook then
			consolePerformCommand("showscorescursorhook " .. scoreHookNew);
		end
	end
		
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsMouse(intensity)
	local optargs = {
		intensity = intensity
	};
	local colWidth = 650;
	local colIndent = 250;
	
	-- s1 == current settings
	local s1 = {};
	s1.m_speed						= consoleGetVariable("m_speed");
	s1.m_invert						= consoleGetVariable("m_invert");
	s1.m_advanced					= consoleGetVariable("m_advanced");
	s1.m_advanced_input_frequency	= consoleGetVariable("m_advanced_input_frequency");
	s1.m_advanced_acceleration		= consoleGetVariable("m_advanced_acceleration");
	s1.m_advanced_sensitivity_cap	= consoleGetVariable("m_advanced_sensitivity_cap");
	s1.m_advanced_sensitivity_cap_min	= consoleGetVariable("m_advanced_sensitivity_cap_min");
	s1.m_advanced_offset			= consoleGetVariable("m_advanced_offset");
	s1.m_advanced_power				= consoleGetVariable("m_advanced_power");
	s1.m_advanced_postscale_x		= consoleGetVariable("m_advanced_postscale_x");
	s1.m_advanced_postscale_y		= consoleGetVariable("m_advanced_postscale_y");
	s1.m_advanced_angle				= consoleGetVariable("m_advanced_angle");
	
	-- s2 = new settings
	local s2 = {};
	
	nvgSave();

	-- COL 1
	local x = -620;
	local y = -250;

	ui2Label("Enabled Advanced Options", 620-300, y, optargs);
	s2.m_advanced = ui2CheckBox(s1.m_advanced ~= 0, 620-35, y, optargs) and 1 or 0;

	s2.m_speed = ui2RowSliderEditBox2Decimals(x, y, colIndent, colWidth, 80, "Sensitivity", s1.m_speed, 1, 50, optargs);
	y = y + 60;

	ui2Label("Invert", x, y, optargs);
	s2.m_invert = ui2CheckBox(s1.m_invert ~= 0, x+colIndent, y, optargs) and 1 or 0;
	y = y + 60;
	y = y + 30;

	colWidth = 340;

	optargs.enabled = false;
	ui2Label("Advanced", x, y, optargs);
	y = y + 60;

	local yaccel = y;
	optargs.enabled = s1.m_advanced ~= 0;

	-- graph
	local xaxis = 
	{
		name = "Movement in a single rawinput packet";
		min = 0;
		max = 100;
		step = 20;
	};
	local sensx, sensy = mouseEvaluateSensitivity(100, 100);
	local ymax = math.max(sensx, sensy);
	sensx, sensy = mouseEvaluateSensitivity(0.001, 0.001);
	ymax = math.max(ymax, math.max(sensx, sensy));
	ymax = math.ceil(ymax * 1.2);
	ymax = math.max(ymax, 1);
	local yaxis = 
	{
		name = "Effective sensitivity";
		min = 0;
		max = ymax;
		step = ymax/5;
	};
	local function eval(x)
		x = math.max(x, 0.1); -- avoid divide by zero at x==0
		local sensx, sensy = mouseEvaluateSensitivity(x, 0);
		return sensx;
	end

	-- plot graph
	local rawx, rawy = mouseGetAverageRawInput();
	optargs.plotx = math.max(math.abs(rawx), math.abs(rawy));
	ui2Graph(x+540, yaccel, 700, 400, xaxis, yaxis, eval, optargs);

	ui2Label("Input Frequency (Hz)", x, y, optargs);
	s2.m_advanced_input_frequency = ui2EditBox0Decimals(s1.m_advanced_input_frequency, x+colIndent, y, colWidth-colIndent, optargs);
	ui2TooltipBox("This should be set to match your mouse frequency rate.", x + colWidth, y, 200, optargs);
	y = y + 60;

	ui2Label("Acceleration", x, y, optargs);
	s2.m_advanced_acceleration = ui2EditBox4Decimals(s1.m_advanced_acceleration, x+colIndent, y, colWidth-colIndent, optargs);
	y = y + 60;
	
	ui2Label("Angle", x, y, optargs);
	s2.m_advanced_angle = ui2EditBox4Decimals(s1.m_advanced_angle, x+colIndent, y, colWidth-colIndent, optargs);
	y = y + 60;
	
	ui2Label("Offset", x, y, optargs);
	s2.m_advanced_offset = ui2EditBox4Decimals(s1.m_advanced_offset, x+colIndent, y, colWidth-colIndent, optargs);
	y = y + 60;
	
	ui2Label("Power", x, y, optargs);
	s2.m_advanced_power = ui2EditBox4Decimals(s1.m_advanced_power, x+colIndent, y, colWidth-colIndent, optargs);
	y = y + 60;
	
	ui2Label("Sensitivity Cap (min/max)", x, y, optargs);
	s2.m_advanced_sensitivity_cap_min = ui2EditBox4Decimals(s1.m_advanced_sensitivity_cap_min, x+colIndent, y, 60, optargs);
	s2.m_advanced_sensitivity_cap = ui2EditBox4Decimals(s1.m_advanced_sensitivity_cap, x+colIndent+70, y, 60, optargs);
	y = y + 60;
	
	ui2Label("Post-Scale (X/Y)", x, y, optargs);
	s2.m_advanced_postscale_x = ui2EditBox4Decimals(s1.m_advanced_postscale_x, x+colIndent, y, 60, optargs);
	s2.m_advanced_postscale_y = ui2EditBox4Decimals(s1.m_advanced_postscale_y, x+colIndent+70, y, 60, optargs);
	y = y + 60;
	
	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawWidget(x, y, row, widget, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	if widget.heading == true then
		col.r = col.r + 50;
		col.g = col.g - 50;
		col.b = col.b - 50;
	end
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	local ix = x + 10;
	if widget.heading ~= true then
		ix = ix + 10;

		nvgStrokeWidth(2);
		nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
		nvgBeginPath();
		nvgMoveTo(ix-10, y+h/2);
		nvgLineTo(ix-8, y+h/2);
		nvgStroke();
	end

	-- text
	enabled = enabled and widget.visible;
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled);
	ui2FontSmall();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, y+h/2, widget.name);

	return m.leftUp;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawAddon(x, y, row, addon, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local isOnWorkshop = addon.workshopId ~= "0";
	local ix = x + 10;
	local iconSize = 30;
	local iconPad = 4;
	local iconTop = y + h/2-25;

	optargs.optionalId = y;

	nvgSave();

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	-- name
	ui2FontNormal();
	if isOnWorkshop then
		-- click => workshop page
		optargs.nofont = true;
		optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
		optargs.enabled = isOnWorkshop;
		local tw = nvgTextWidth(addon.name);
		if ui2Button(addon.name, x, y+4, tw+20, 32, optargs) then
			if addon.workshopId ~= nil then
				launchUrl("steam://url/CommunityFilePage/" .. addon.workshopId)
			end
		end
		optargs.enabled = nil;
		optargs.nofont = nil;
		optargs.bgcoltype = nil;
	else
		-- just text, can't click
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled, m.leftHeld));
		nvgText(x+10, y+h/2-10, addon.name);
	end

	-- common base optargs for icon
	local optargsIcon = {};
	optargsIcon.coltype = UI2_COLTYPE_DIM;
	optargsIcon.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	optargsIcon.nofont = true;
	optargsIcon.iconSize = 9;
	optargsIcon.intensity = optargs.intensity;
	optargsIcon.optionalId = y;
	
	-- workshop addon?
	local iy = y + h/2 - 10;
	local authorY = iy + 5;
	if isOnWorkshop then

		-- author
		local friend = steamFriends[addon.steamIdOwner];
		local ownerName = friend ~= nil and friend.personaName or addon.steamIdOwner;
		optargs.nofont = true;
		optargs.halign = NVG_ALIGN_LEFT;
		optargs.valign = NVG_ALIGN_MIDDLE;
		optargs.coltype = UI2_COLTYPE_TEXT_GREY;
		ui2FontSmall();
		local tw = ui2Label("by ", ix, authorY, optargs);
		optargs.coltype = nil;
		if ui2Url(ownerName, ix + tw, authorY, optargs) then
			launchUrl("steam://url/SteamWorkshopPage/" ..addon.steamIdOwner);
		end
		optargs.nofont = nil;
		optargs.halign = nil;
		optargs.valign = nil;
		optargs.coltype = nil;
	
		-- icons
		ix = x + w - 3 * (iconSize + iconPad);
		if addon.canUpload then
			ix = ix - (iconSize + iconPad);
		end
		if addon.canDownload then
			ix = ix - (iconSize + iconPad);
		end
	
		-- special: upload button
		if addon.canUpload then
			local newUpload = addon.epochTimeUpdatedOnWorkshop ~= addon.epochTimeUpdatedOnDisk;
			optargsIcon.coltype = newUpload and UI2_COLTYPE_UPLOAD or UI2_COLTYPE_DIM;
			optargsIcon.iconLeft = "internal/ui/icons/lowGrav";
			optargsIcon.enabled = connectedToSteam;
			if ui2Button("", ix, iconTop, iconSize, iconSize, optargsIcon) then
				showAsPopup("PublishAddonToWorkshop", addon.workshopId, addon.description, addon.visibility);
			end
			ix = ix + iconSize + iconPad;
		end

		-- special: download button
		if addon.canDownload then
			local newDownload = addon.epochTimeUpdatedOnWorkshop ~= addon.epochTimeUpdatedOnDisk;
			optargsIcon.coltype = newDownload and UI2_COLTYPE_UPLOAD or UI2_COLTYPE_DIM;
			optargsIcon.iconLeft = "internal/ui/icons/download";
			optargsIcon.enabled = connectedToSteam;
			if ui2Button("", ix, iconTop, iconSize, iconSize, optargsIcon) then
				workshopDownloadAddon(addon.workshopId, addon.name);
			end
			ix = ix + iconSize + iconPad;
		end

		-- rate up	
		local votedUp, votedDown, favorite, subscribed = workshopGetMapFlags(addon.workshopId);
		optargsIcon.coltype = votedUp and UI2_COLTYPE_VOTEUP or UI2_COLTYPE_DIM;
		optargsIcon.iconLeft = "internal/ui/icons/thumbsup";
		optargsIcon.enabled = connectedToSteam;
		if ui2Button("", ix, iconTop, iconSize, iconSize, optargsIcon) then
			workshopSetMapVote(addon.workshopId, true);
		end
		ix = ix + iconSize + iconPad;

		-- rate down
		optargsIcon.coltype = votedDown and UI2_COLTYPE_VOTEDOWN or UI2_COLTYPE_DIM;
		optargsIcon.iconLeft = "internal/ui/icons/thumbsdown";
		optargsIcon.enabled = connectedToSteam;
		if ui2Button("", ix+3, iconTop, iconSize, iconSize, optargsIcon) then
			workshopSetMapVote(addon.workshopId, false);
		end
		ix = ix + iconSize + iconPad;
	
		-- don't need subscribe option, having it installed will subscribe you
	else
		optargs.nofont = true;
		optargs.halign = NVG_ALIGN_LEFT;
		optargs.valign = NVG_ALIGN_MIDDLE;
		optargs.coltype = UI2_COLTYPE_TEXT_GREY;
		ui2FontSmall();
		ui2Label("local addon", ix, authorY, optargs);
		optargs.nofont = nil;
		optargs.halign = nil;
		optargs.valign = nil;
		optargs.coltype = nil;
	end
	
	-- uninstall link
	ix = x + w - (iconSize + iconPad);
	optargsIcon.coltype = UI2_COLTYPE_BUTTON_EDITOR;
	optargsIcon.iconLeft = "internal/ui/icons/checkBoxTick";
	optargsIcon.enabled = true;
	if ui2Button("", ix, iconTop, iconSize, iconSize, optargsIcon) then
		showAsPopup("ConfirmUninstallAddon", addon.name, addon.folder);
	end

	-- status text
	local status = nil;
	if not connectedToSteam then
		status = "No Steam Connection";
	elseif addon.errorQuerying then
		status = "Failed to query from workshop";
	elseif addon.queuedForDownload then
		status = "Download queued";
	elseif addon.isDownloading then
		status = string.format("Downloading %.0f%%", 100*addon.downloadPercent);
	elseif addon.epochTimeUpdatedOnWorkshop == addon.epochTimeUpdatedOnDisk then
		status = "Running lastest version";--, updated " .. FormatTimeSince(addon.epochTimeUpdatedOnWorkshop);
	elseif addon.canUpload then
		status = "Last publish was " .. FormatTimeSince(addon.epochTimeUpdatedOnWorkshop);
	elseif addon.canDownload then
		status = "New Version Available!";
	end
	if status ~= nil then
		local ix = x + w - 10;
		local iy = y + h/2 - 3;
		optargs.nofont = true;
		optargs.halign = NVG_ALIGN_RIGHT;
		optargs.valign = NVG_ALIGN_MIDDLE;
		optargs.coltype = UI2_COLTYPE_TEXT_GREY;
		ui2FontSmall();
		ui2Label(status, ix, iy, optargs);
		optargs.nofont = nil;
		optargs.halign = nil;
		optargs.valign = nil;
		optargs.coltype = nil;
	end

	nvgRestore();

	return m.leftUp;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2AnchorSelection(x, y, anchor, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	local anchorSize = 20;
	local newAnchor = {};
	newAnchor.x = anchor.x;
	newAnchor.y = anchor.y;

	local w = anchorSize*3;
	local h = anchorSize*3;
	local m = mouseRegion(x, y, w, h);

	-- bg
	nvgBeginPath();
	nvgRect(x, y, anchorSize*3, anchorSize*3);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, m.hoverAmount, enabled));
	nvgFill();
		
	-- existing selection
	local ox = clamp(anchor.x + 1, 0, 2);
	local oy = clamp(anchor.y + 1, 0, 2);
	local px = x + anchorSize * ox;
	local py = y + anchorSize * oy;
	nvgBeginPath();
	nvgRect(px, py, anchorSize, anchorSize);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgFill();

	-- new selection
	if m.hoverAmount > 0 then
		-- determine new selection
		local offsetx = m.mousex - x;
		local offsety = m.mousey - y;
		local hoverx = math.floor(offsetx / anchorSize);
		local hovery = math.floor(offsety / anchorSize);
		hoverx = clamp(hoverx, 0, 2);
		hovery = clamp(hovery, 0, 2);
	
		px = x + anchorSize * hoverx;
		py = y + anchorSize * hovery;
		
		nvgBeginPath();
		nvgRect(px, py, anchorSize, anchorSize);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_BUTTON, intensity, 1, enabled));
		nvgFill();

		-- make new selection
		if m.leftDown then
			newAnchor.x = hoverx - 1;
			newAnchor.y = hovery - 1;

			playSound("internal/ui/sounds/buttonClick")
		end
	end

	return newAnchor;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByName(a, b)
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsWidgets(intensity)
	local optargs = {
		intensity = intensity
	};
	local x = -620;
	local y = -250;
	local height = 630;
	
	nvgSave();

	-- widget names for selection
	local widgetsFiltered = {};
	local widgetsFilteredCount = 0;
	local widgetsFilteredSelected = nil;
	local addonsWithWidgets = {};
	for k, v in pairs(widgets) do
		local show = false;

		if v.canPosition ~= false then
			show = true;
		end

		if v.canHide ~= false then
			show = true;
		end

		if _G[v.name].drawOptions ~= nil then
			show = true;
		end

		if v.isMenu then
			show = false;
		end

		if show then
			widgetsFilteredCount = widgetsFilteredCount + 1;
			widgetsFiltered[widgetsFilteredCount] = {};
			widgetsFiltered[widgetsFilteredCount].name = v.name;
			widgetsFiltered[widgetsFilteredCount].sort = v.addonName .. ":" .. v.name;
			widgetsFiltered[widgetsFilteredCount].widgetIndex = k

			if v.name == self.selected_widget_name then
				widgetsFilteredSelected = widgetsFiltered[widgetsFilteredCount];
			end

			-- record heading
			addonsWithWidgets[v.addonName] = v.addonName;
		end
	end
	
	-- add headings for widgets
	for k, v in pairs(addonsWithWidgets) do
		widgetsFilteredCount = widgetsFilteredCount + 1;
		widgetsFiltered[widgetsFilteredCount] = {};
		widgetsFiltered[widgetsFilteredCount].name = v;
		widgetsFiltered[widgetsFilteredCount].heading = true;
		widgetsFiltered[widgetsFilteredCount].sort = v;
	end
	
	-- sort widgetsFiltered
	local function SortBySort(a, b)
		return a.sort < b.sort;
	end
	table.sort(widgetsFiltered, SortBySort);

	-- if no selection default to first widget
	if widgetsFilteredSelected == nil and widgetsFilteredCount > 0 then
		widgetsFilteredSelected = widgetsFiltered[1];
	end

	-- draw widgets
	optargs.itemHeight = 25;
	optargs.itemDrawFunction = ui2DrawWidget;
	optargs.itemPad = 5;
	local widgetSelected = ui2ScrollSelection(
		widgetsFiltered, widgetsFilteredSelected, x, y, 240, height, self.scrollBarDataWidgetSelection, optargs);
	
	-- record selection
	self.selected_widget_name = widgetSelected ~= nil and widgetSelected.name or nil;
	
	-- dig out original widget from selection
	local widget = nil;
	if widgetSelected ~= nil and widgetSelected.widgetIndex ~= nil then
		widget = widgets[widgetSelected.widgetIndex]
	end

	-- selection properties
	if widget ~= nil then
		local contentWidth = WIDGET_PROPERTIES_COL_WIDTH + 20;
		local contentHeight = height;
		local contentY = y;
		local colIndent = WIDGET_PROPERTIES_COL_INDENT;
		local colWidth = contentWidth - 20;

		-- properties on right
		local ix = x + 320;
		local iy = contentY;
	
		-- mouse behind everything to catch mousewheel
		local haveScroll = false;
		local mouseWheelScroll = 0;
		local bgMouse = mouseRegion(ix, iy, contentWidth, contentHeight);
		if bgMouse.mouseWheel ~= 0 then
			mouseWheelScroll = bgMouse.mouseWheel;
		end

		-- determine property height required
		local basePropertiesHeight = 0;
		if widget.canHide then
			basePropertiesHeight = basePropertiesHeight + 60; -- visible checkbox
		end
		if widget.canPosition then
			basePropertiesHeight = basePropertiesHeight + 80; -- anchor
			basePropertiesHeight = basePropertiesHeight + 110; -- offset
			basePropertiesHeight = basePropertiesHeight + 60; -- scale
			basePropertiesHeight = basePropertiesHeight + 60; -- zindex
		end
		local userPropertiesHeight = callWidgetGetOptionsHeight(widget.name);
		local propertiesHeight = basePropertiesHeight + userPropertiesHeight;

		-- do we need a scroll selection?
		if propertiesHeight > contentHeight then
			-- shrink content a bit, we need a scrollbar now
			contentWidth = contentWidth - UI_SCROLLBAR_WIDTH;
			ui2ScrollBar(ix+contentWidth, contentY, contentHeight, propertiesHeight, self.scrollBarDataWidgetProperties, optargs);

			iy = iy - self.scrollBarDataWidgetProperties.dragOffsetY;

			-- only draw inside bounds ( cleared with nvgRestore() at end of function )
			nvgScissor(ix, contentY, contentWidth, contentHeight);

			haveScroll = true;
		end

		-- debugging..
		if widgetGetConsoleVariable("show_widget_properties_height") ~= 0 then
			nvgBeginPath();
			nvgRect(ix, iy, contentWidth, basePropertiesHeight);
			nvgFillColor(Color(255, 0, 0, 80));
			nvgFill();
			nvgBeginPath();
			nvgRect(ix, iy+basePropertiesHeight, contentWidth, userPropertiesHeight);
			nvgFillColor(Color(255, 255, 0, 80));
			nvgFill();
		end

		-- visible
		if widget.canHide then
			local newVisible = ui2RowCheckbox(ix, iy, colIndent, "Visible", widget.visible, optargs);
			if newVisible ~= widget.visible then
				if newVisible then
					consolePerformCommand("ui_show_widget " .. widget.name);
				else
					consolePerformCommand("ui_hide_widget " .. widget.name);
				end
			end
			iy = iy + 60;
		end

		if widget.canPosition then
			-- anchor
			ui2Label("Anchor", ix, iy, optargs);
			local value_ui = ui2AnchorSelection(ix+colIndent, iy+5, widget.anchor, optargs);
			if value_ui.x ~= widget.anchor.x or value_ui.y ~= widget.anchor.y then
				consolePerformCommand("ui_set_widget_anchor " .. widget.name .. " " .. value_ui.x .. " " .. value_ui.y);
			end
			iy = iy + 80;

			-- offset
			local newOffset = {};
			newOffset.x = ui2RowSliderEditBox0Decimals(ix, iy, colIndent, colWidth, 80, "Offset", widget.offset.x, -200, 200, optargs);
			iy = iy + 50;
			newOffset.y = ui2RowSliderEditBox0Decimals(ix, iy, colIndent, colWidth, 80, "", widget.offset.y, -200, 200, optargs);
			iy = iy + 60;
			if newOffset.x ~= widget.offset.x or newOffset.y ~= widget.offset.y then
				consolePerformCommand("ui_set_widget_offset " .. widget.name .. " " .. newOffset.x .. " " .. newOffset.y);
			end

			-- scale
			local newScale = ui2RowSliderEditBox2Decimals(ix, iy, colIndent, colWidth, 80, "Scale", widget.scale, .1, 5, optargs);
			if newScale ~= widget.scale then
				consolePerformCommand("ui_set_widget_scale " .. widget.name .. " " .. newScale);
			end
			iy = iy + 60;

			-- z
			local newZIndex = ui2RowSliderEditBox2Decimals(ix, iy, colIndent, colWidth, 80, "Z Index", widget.zIndex, -10, 10, optargs);
			if newZIndex ~= widget.zIndex then
				consolePerformCommand("ui_set_widget_zindex " .. widget.name .. " " .. newZIndex);
			end
			iy = iy + 60;
		end

		-- custom widget options
		callWidgetDrawOptions(widget.name, ix, iy, intensity);

		-- if the mouse wheel scrolled, scroll dragOffsetY for NEXT frame, don't handle it half way down when we get to it
		if mouseWheelScroll ~= 0 and haveScroll then
			local scrollBarData = self.scrollBarDataWidgetProperties;
			-- wheel
			scrollBarData.dragOffsetY = scrollBarData.dragOffsetY - mouseWheelScroll * UI_MOUSE_SCROLL_SPEED;

			-- clamp
			scrollBarData.dragOffsetY = math.min(scrollBarData.dragOffsetY, propertiesHeight - contentHeight);
			scrollBarData.dragOffsetY = math.max(scrollBarData.dragOffsetY, 0);
		end
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawOptionsAddons(intensity)
	local optargs = {
		intensity = intensity
	};
	local x = -620;
	local y = -250;
	local colWidth = 550;
	local colIndent = 250;
	
	nvgSave();
	
	optargs.enabled = false;
	ui2Label("Installed Addons", x, y, optargs);
	optargs.enabled = nil;
	if assetsChangedRestartRequired then
		local text = "New assets found, restart required";
		optargs.bgcoltype = UI2_COLTYPE_BUTTON;
		ui2Tooltip(text, x+266, y+2, optargs)
		optargs.bgcoltype = nil;
	end
	y = y + 60;

	-- find selected
	local selected = nil;
	for k, v in ipairs(addons) do
		if v.folder == self.selected_addon_foldername then
			selected = v;
		end
	end

	-- draw installed addons
	local addonsHeight = 430;
	optargs.itemHeight = 60;
	optargs.itemDrawFunction = ui2DrawAddon;
	optargs.itemPad = 5;
	selected = ui2ScrollSelection(addons, selected, x, y, 600, addonsHeight, self.scrollBarDataAddonSelection, optargs);
	if selected ~= nil then
		self.selected_addon_foldername = selected.folder;
	end
	y = y + addonsHeight + 35;

	-- explore
	if ui2Button("Explore Workshop",x, y, 300, 35, optargs) then
		showAsPopup("AddonPicker");
	end

	ui2TooltipBox("Addons from workshop are 3rd party and may effect your Reflex install, use with care!", x + 306, y, 300, optargs);

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2JoinButton(textTitle, textQueue, x, y, w, h, optargs)
	local optargs = optargs or {};
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local optionalId = optargs.optionalId or 0;
	local intensity = optargs.intensity or 1;
	local teamIndex = optargs.teamIndex or 1;
	
	local m = mouseRegion(x, y, w, h, optionalId);
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
	end

	nvgSave();

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, m.hoverAmount, enabled, m.leftHeld));
	nvgFill();

	-- band
	local col = Color(teamColors[teamIndex].r, teamColors[teamIndex].g, teamColors[teamIndex].b);
	col.r = lerp(col.r * .9, col.r, m.hoverAmount);
	col.g = lerp(col.g * .9, col.g, m.hoverAmount);
	col.b = lerp(col.b * .9, col.b, m.hoverAmount);
	col.a = 255 * intensity;
	nvgBeginPath();
	nvgRect(x, y, 20, h);
	nvgFillColor(col);
	nvgFill();

	-- text color
	local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgFillColor(col);
		
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	local fontx = x + w*0.5;
		
	local fonty = y + h*0.5-14;
	ui2FontNormal();
	nvgText(fontx, fonty, textTitle);

	local fonty = y + h*0.5+14;
	ui2FontSmall();
	nvgText(fontx, fonty, textQueue);

	-- hover text
	local hoverText = optargs.hoverText;
	if hoverText ~= nil then
		nvgSave()
		nvgResetScissor()

		-- calculate bounds
		ui2FontSmall();
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		local breakRowWidth = 280;
		local bounds = nvgTextBoxBounds(breakRowWidth, hoverText);
		local tx = x+w+18;
		local ty = y+h/2;

		-- add padding
		bounds.minx = bounds.minx - 5;
		bounds.miny = bounds.miny - 3;
		bounds.maxx = bounds.maxx + 5;
		bounds.maxy = bounds.maxy + 3;
	
		-- bg
		local bgc = ui2FormatColor(UI2_COLTYPE_BACKGROUND, m.hoverAmount, m.hoverAmount, true);
		nvgBeginPath();
		nvgMoveTo(tx+bounds.maxx, ty+bounds.miny);
		nvgLineTo(tx+bounds.maxx, ty+bounds.maxy);
		nvgLineTo(tx+bounds.minx, ty+bounds.maxy);
		nvgLineTo(tx+bounds.minx, ty+bounds.miny + 30);
		nvgLineTo(tx+bounds.minx-8, ty+bounds.miny + 30/2);
		nvgLineTo(tx+bounds.minx, ty+bounds.miny);
		nvgClosePath();
		nvgFillColor(bgc);
		nvgFill();

		-- text
		col = ui2FormatColor(UI2_COLTYPE_TEXT, m.hoverAmount, m.hoverAmount, true);
		nvgFillColor(col);
		nvgTextBox(tx, ty, breakRowWidth, hoverText);

		nvgRestore()
	end
	
	nvgRestore();

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawReplay(intensity)
	local optargs = {
		intensity = intensity;
	};

	-- COL 1
	local x = -130;
	local y = -180;
	local w = 260;

	y = y + 140
	
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = replay.isEditing
	if ui2Button("Watch", x, y, w, 40, optargs) then
		consolePerformCommand("re_edit_toggle")
		hideMenu();
	end
	y = y + 40 + 25;
	
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = not replay.isEditing
	if ui2Button("Edit", x, y, w, 40, optargs) then
		consolePerformCommand("re_edit_toggle")
		hideMenu();
	end
	y = y + 40 + 25;
	
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = true
	if ui2Button("Close", x, y, w, 40, optargs) then
		consolePerformCommand("disconnect")
	end
	y = y + 40 + 25;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawMatch(intensity)
	local optargs = {
		intensity = intensity;
	};

	local localPlayer = getLocalPlayer();
	local gamemode = gamemodes[world.gameModeIndex];
	local localPlayerReady = localPlayer ~= nil and localPlayer.ready or false;
	local localPlayerState = localPlayer ~= nil and localPlayer.state or PLAYER_STATE_INGAME;
	local localPlayerTeam = localPlayer ~= nil and localPlayer.team or 1;

	-- COL 1
	local x = -130;
	local y = -180;
	local w = 260;

	-- -- fake submenu, just the name of the server
	-- local fakeSubKeys = { 
	-- 	[1] = {
	-- 		["name"] = world.hostName;
	-- 		["intensity"] = intensity;
	-- 		["disabled"] = false;
	-- 	}
	-- }
	-- ui2SubMenuBar(fakeSubKeys, intensity, 1);

	-- 
	local isMatchmakingGame = (string.len(world.matchmakingPlaylistKey) > 0)
	local canSpectate = true
	local canJoin = true
	
	-- MM game & playing? => can't spec
	if isMatchmakingGame and localPlayerState == PLAYER_STATE_INGAME then 
		canSpectate = false 
	end

	-- MM lobby? => can't spec
	if world.isMatchmakingLobby then 
		canSpectate = false
	end

	-- MM game & not playing? => can't join
	if isMatchmakingGame and localPlayerState ~= PLAYER_STATE_INGAME then 
		canJoin = false 
	end

	-- inspect players
	local playersAlpha = 0;
	local playersZeta = 0;
	local playersPlaying = 0;
	local playersQueued = 0;
	for k, p in pairs(players) do
		if p.connected then
			if p.state == PLAYER_STATE_INGAME then
				playersPlaying = playersPlaying + 1;
				if p.team == 1 then
					playersAlpha = playersAlpha + 1;
				end
				if p.team == 2 then
					playersZeta = playersZeta + 1;
				end
			elseif p.state == PLAYER_STATE_QUEUED then
				playersQueued = playersQueued + 1;
			end
		end
	end
	
	--
	optargs.hoverText = (canJoin == false) and "You cannot join at this time" or nil;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if gamemode.hasTeams then
	
		local playersAlphaText = playersAlpha == 1 and "Player" or "Players";
		local playersZetaText = playersZeta == 1 and "Player" or "Players";

		local alphaText = string.format("( %d %s )", playersAlpha, playersAlphaText);
		local zetaText = string.format("( %d %s )", playersZeta, playersZetaText);
		
		optargs.enabled = (localPlayerState ~= PLAYER_STATE_INGAME or localPlayerTeam ~= 1) and canJoin;
		optargs.teamIndex = 1;
		if ui2JoinButton("Join Alpha", alphaText, x, y, w, 80, optargs) then
			consolePerformCommand("cl_playerteam 0");
			consolePerformCommand("cl_playerstate " .. PLAYER_STATE_INGAME);
			hideMenu();		
		end
		y = y + 80 + 25;
		
		optargs.enabled = (localPlayerState ~= PLAYER_STATE_INGAME or localPlayerTeam ~= 2) and canJoin;
		optargs.teamIndex = 2;
		if ui2JoinButton("Join Zeta", zetaText, x, y, w, 80, optargs) then
			consolePerformCommand("cl_playerteam 1");
			consolePerformCommand("cl_playerstate " .. PLAYER_STATE_INGAME);
			hideMenu();		
		end
		y = y + 80 + 25;
		
		optargs.enabled = nil;
		optargs.teamIndex = nil;
	else

		local title = "";
		local queue = "";

		local queueText = "";
		if playersQueued > 0 then
			queueText = ", "..playersQueued.." Queued";
		end

		-- (N Players)
		-- (N Players, M Queued)
		playersText = playersPlaying == 1 and "Player" or "Players";
		queue = "( "..playersPlaying.." "..playersText..queueText.." )";
		title = "Join Game";
		
		optargs.enabled = localPlayerState ~= PLAYER_STATE_INGAME and canJoin;
		if ui2JoinButton(title, queue, x, y, w, 80, optargs) then
			consolePerformCommand("cl_playerstate " .. PLAYER_STATE_INGAME);
			hideMenu();			
		end
		optargs.enabled = nil;
		y = y + 80 + 25;
	end
	optargs.hoverText = nil;

	--
	if world.gameState ~= GAME_STATE_WARMUP and 
	   world.gameState ~= GAME_STATE_GAMEOVER and 
	   localPlayer ~= nil and 
	   localPlayer.state == PLAYER_STATE_INGAME and 
	   gamemodes[world.gameModeIndex] ~= nil and 
	   gamemodes[world.gameModeIndex].canForfeit then

		optargs.enabled = true;
		optargs.iconLeft = "internal/ui/icons/forfeit";
		optargs.iconSize = 12;

		if localPlayer.forfeit == true then
			optargs.enabled = false;
			optargs.hoverText = "You have already indicated you want to forfeit";
		end
		if canForfeit == false then
			optargs.enabled = false;
			optargs.hoverText = "You cannot forfeit at this time";
		end

		if ui2Button("Forfeit", x, y, w, 40, optargs) then
			consolePerformCommand("forfeit");
			hideMenu();
		end
		optargs.enabled = nil;
		optargs.iconLeft = nil;
		optargs.iconSize = nil;
		optargs.hoverText = nil;
		y = y + 40 + 25;
	end

	--
	optargs.enabled = canSpectate
	optargs.hoverText = (optargs.enabled == false) and "You cannot spectate at this time" or nil;
	if ui2Button("Spectate", x, y, w, 40, optargs) then
		consolePerformCommand("cl_playerstate " .. PLAYER_STATE_SPECTATOR);
		hideMenu();
	end
	optargs.enabled = nil;
	optargs.hoverText = nil;
	y = y + 40 + 25;

	--
	if world.allowEdit then
		optargs.enabled = world.allowEdit and localPlayerState ~= PLAYER_STATE_EDITOR;
		if ui2Button("Edit", x, y, w, 40, optargs) then
			consolePerformCommand("cl_playerstate " .. PLAYER_STATE_EDITOR);
			hideMenu();
		end
		optargs.enabled = nil;
	y = y + 40 + 25;
	end

	local allowVote = false;
	optargs.enabled = world.allowCallVoteMapMode;
	optargs.hoverText = (optargs.enabled == false) and "The server you are on has not allowed change map / mode" or nil;
	if ui2Button("Change Map / Mode", x, y, w, 40, optargs) then
		local mode = gamemodes[world.gameModeIndex].shortName;
		local mapName = world.mapName;
		local mapId = world.mapWorkshopId;
		showAsPopup("MatchPicker", mapName, mapId, mode, "IsCallVote");
	end
	optargs.enabled = nil;
	optargs.hoverText = nil;
	y = y + 40 + 25;
	
	local allowVote = false;
	optargs.enabled = world.allowCallVoteMutators;
	optargs.hoverText = (optargs.enabled == false) and "The server you are on has not allowed change mutators" or nil;
	if ui2Button("Change Mutators", x, y, w, 40, optargs) then
		showAsPopup("MutatorPicker", world.mutators, "IsCallVote");
	end
	optargs.enabled = nil;
	optargs.hoverText = nil;
	y = y + 40 + 25;
	
	--[[
	ui2Label("Ready", x, y, optargs);
	optargs.enabled = (world.gameState == GAME_STATE_WARMUP) and gamemode.requiresReadyUp;
	local newReady = ui2CheckBox(localPlayerReady, x, y, optargs);
	optargs.enabled = nil;
	if newReady ~= localPlayerReady then
		if newReady then
			consolePerformCommand("ready");
		else
			consolePerformCommand("notready");
		end
	end
	y = y + 60;
	]]--

	--
	local disconnectShouldCancelMatchmaking = false
	if (string.len(world.matchmakingPlaylistKey) > 0) and (localPlayer ~= nil) and (localPlayer.state == PLAYER_STATE_INGAME) and world.gameState ~= GAME_STATE_GAMEOVER then
		optargs.hoverText = "Disconnecting will count as a loss"

		-- if we disconnect from a MM server when actually playing, we do want to cancel the MM too
		disconnectShouldCancelMatchmaking = true
	end
	if ui2Button("Disconnect", x, y, w, 40, optargs) then
		local param1 = nil
		if disconnectShouldCancelMatchmaking then
			param1 = "cancelmm"
		end
		showAsPopup("ConfirmDisconnect", param1);
	end
	optargs.hoverText = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2TileProfile(x, y, w, h, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;
	
	-- look up player
	local name = consoleGetVariable("name");
	local col1 = extendedColors[consoleGetVariable("cl_playercolor1")+1];
	local col2 = extendedColors[consoleGetVariable("cl_playercolor2")+1];
	local experience = 0;
	local timeLastPlayed = 0;
	local bonusExperienceAvailable = false;
	local bonusExperienceMultiplier = 1;
	local bonusExperienceAvailableIn = 0;
	if steamUserStats[steamId] ~= nil and connectedToSteam then
		experience = steamUserStats[steamId].experience;

		local lastBonusXpAwardMultiplier = steamUserStats[steamId].lastBonusXpAwardMultiplier;
		if epochTime > steamUserStats[steamId].bonusExperienceEpochTimeExpires then
			-- expired, return to 1x
			bonusExperienceMultiplier = 1;
			bonusExperienceAvailable = true;
			bonusExperienceAvailableIn = 0;
		elseif epochTime > steamUserStats[steamId].bonusExperienceEpochTimeAvailable then
			-- available now!
			bonusExperienceMultiplier = math.min(lastBonusXpAwardMultiplier + 1, 5);
			bonusExperienceAvailable = true;
			bonusExperienceAvailableIn = 0;
		else
			-- not available yet!
			bonusExperienceMultiplier = math.min(lastBonusXpAwardMultiplier + 1, 5);
			bonusExperienceAvailable = false;
			bonusExperienceAvailableIn = steamUserStats[steamId].bonusExperienceEpochTimeAvailable - epochTime;
		end

	end

	local experienceVars = GetExperienceVars(experience);
	local pad = 20;

	nvgSave();
	nvgIntersectScissor(x, y, w, h);

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
	nvgFill();

	-- bonus xp avatar
	local bonusCol = Color(84, 193, 252);
	local bonusx = x+320;
	local bonusy = y+100;
	local bonusr = 44;
	local bonusExperienceAvatars = {
		[1] = "internal/ui/awards/bonus",
		[2] = "internal/ui/awards/bonusX2",
		[3] = "internal/ui/awards/bonusX3",
		[4] = "internal/ui/awards/bonusX4",
		[5] = "internal/ui/awards/bonusX5"
	};
	if bonusExperienceAvailable then
		Menu.pulseBonusExperienceTimer = (Menu.pulseBonusExperienceTimer + deltaTimeRaw*6) % 30;
		local i = 200 + math.sin(Menu.pulseBonusExperienceTimer) * 50;
		nvgFillColor(Color(bonusCol.r, bonusCol.g, bonusCol.b, i * intensity));
	else
		nvgFillColor(Color(128, 128, 128, 255 * intensity * .5));
	end
	nvgSvg(bonusExperienceAvatars[bonusExperienceMultiplier], bonusx, bonusy, bonusr);
		
	-- avatar
	local ix = x + pad;
	local iy = y + pad;
	local rad = 80;
	nvgBeginPath();
	nvgRect(ix, iy, rad, rad);
	nvgFillColor(Color(0,0,0, 0)); -- draw nothing if icon didn't load for some reason
	nvgFillImagePattern("$avatarLarge_"..steamId, ix, iy, rad, rad, 0, intensity*255);
	nvgFill();

	-- name
	local ix = x + 16 + rad + 20;
	local iy = y + pad + rad/4;
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFillColor(Color(255, 255, 255, 255 * intensity));
	nvgFontSize(48);
	nvgFontFace("Oswald-Medium");
	nvgText(ix, iy, string.upper(name));
	ix = ix + 152;

	-- highest rank
	local ix = x + 16 + rad + 20;
	local iy = y + pad + rad*3/4;
	local mmrBest = 0
	local mmrBestPlaylist = nil
	local mmrBestX = 0
	local mmrBestY = 0
	local mmrBestR = 0
	for k, v in ipairs(matchmaking.playlists) do
		if v.competitive then
			if mmrBest < v.mmr then
				mmrBest = v.mmr 
				mmrBestPlaylist = v
			end
		end
	end
	if mmrBest > 0 then
		local r = getRatingInfo(mmrBest, mmrBest)
		
		ix = ix + 10 * r.iconScale

		nvgFillColor(Color(r.col.r, r.col.g, r.col.b, r.col.a * intensity))
		nvgSvg(r.icon, ix, iy, 10 * r.iconScale);
		mmrBestX = ix
		mmrBestY = iy
		mmrBestR = 10 * r.iconScale
		
		ix = ix + 8 + 9 * r.iconScale
	end

	-- experience
	nvgFillColor(Color(255, 255, 255, 255 * intensity));
	nvgFontSize(32);
	nvgFontFace("oswald-light");
	nvgText(ix, iy, "LEVEL " .. experienceVars.level);
	ix = ix + 152;

	-- level
	local ix = x + pad;
	local iy = y + pad + rad + 28;
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP);
	nvgFillColor(Color(255, 255, 255, 255 * intensity));
	nvgFontSize(24);
	nvgFontFace("Oswald-light");
	local expToGo = experienceVars.experienceEndLevel - experience;
	local text = "EXPERIENCE: " .. expToGo .. "XP TO LEVEL " .. experienceVars.level + 1;
	if experienceVars.maxLevel then
		text = "MAX LEVEL REACHED!";
	end
	if not connectedToSteam then
		text = "";
	end		
	nvgText(ix, iy, text);
	ix = ix + 152;
		
	-- experience bar
	local ix = x + pad;
	local iw = w - pad*2;
	local iy = y + pad + rad + pad + pad+26;
	local ih = 26;
	local m = mouseRegion(ix, iy, iw, ih);
	nvgBeginPath();
	nvgRect(ix, iy, iw, ih);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BUTTON_BLACK2, intensity, 0, enabled));
	nvgFill();
	if connectedToSteam then
		nvgBeginPath();
		nvgRect(ix, iy, iw*experienceVars.percentageCompletedLevel, ih);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_BUTTON, intensity, m.hoverAmount, enabled));
		nvgFill();
	else
		nvgBeginPath();
		nvgRect(ix, iy, iw, ih);
		nvgFillColor(Color(42, 42, 42, 255*intensity));
		nvgFill();
	end

	-- experience text
	local text = string.format("%d / %d", experience - experienceVars.experienceStartLevel, experienceVars.experienceEndLevel - experienceVars.experienceStartLevel);
	if experienceVars.maxLevel then
		text = "LEVEL " .. experienceVars.level;
	end
	if not connectedToSteam then
		text = "NO STEAM CONNECTION FOUND";
	end
	nvgFillColor(Color(200, 200, 200, 255 * intensity));
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFontSize(20);
	nvgFontFace("oswald-Medium");
	nvgText(ix+iw/2, iy+ih/2-1, text);

	-- stripes
	nvgTranslate(x+w, y);
	nvgRotate(3.1415/4);
	nvgBeginPath();
	nvgRect(-50, 15, 100, 10);
	nvgFillColor(Color(col1.r, col1.g, col1.b, 192*intensity));
	nvgFill();
	nvgBeginPath();
	nvgRect(-50, 25, 100, 10);
	nvgFillColor(Color(col2.r, col2.g, col2.b, 192*intensity));
	nvgFill();
	
	nvgRestore();

	-- bonus xp hover
	local m = mouseRegion(bonusx - bonusr, bonusy - bonusr, bonusr*2, bonusr*2);
	if m.hoverAmount > 0.5 then
		local text1A = "";
		local text1B = "";
		local text1C = "";
		local text2A = "";
		local text2B = "";
		local bonusXP = 200 * bonusExperienceMultiplier;
		if not connectedToSteam then
			text1A = "No Steam connection found";
		elseif bonusExperienceAvailable then
			text1A = "Receive ";
			text1B = bonusXP .. "XP";
			text1C = " on your first match today!";
		else
			text1A = "Your next daily bonus of ";
			text1B = bonusXP .. "XP"
			text1C = " is available in:";
			text2A = FormatSecondsToString(bonusExperienceAvailableIn);
			text2B = "";
		end
		
		nvgSave();
		ui2FontSmall();
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgTextLineHeight(.8);

		local w1 = nvgTextWidth(text1A) + nvgTextWidth(text1B) + nvgTextWidth(text1C);
		local w2 = nvgTextWidth(text2A) + nvgTextWidth(text2B);
		local h = (string.len(text2A) > 0) and 66 or 36;
		
		-- bg
		local mx = Menu.mouseX + 5;
		local my = Menu.mouseY + 5;
		local col = Color(55, 55, 55, 255*intensity);
		local w = math.max(w1, w2)+14;
		nvgBeginPath();
		nvgRoundedRect(mx, my, w, h, 3);
		nvgFillColor(col);
		nvgFill();
		
		-- text
		local iy = my + 37;
		local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity * .9, 1, enabled);
		local ix = mx + 7;
		nvgFillColor(col);
		nvgText(ix, iy-20, text1A);
		ix = ix + nvgTextWidth(text1A);
		nvgFillColor(bonusCol);
		nvgText(ix, iy-20, text1B);
		ix = ix + nvgTextWidth(text1B);
		nvgFillColor(col);
		nvgText(ix, iy-20, text1C);
		ix = ix + nvgTextWidth(text1C);
		
		local ix = mx + 7;
		nvgFillColor(col);
		nvgText(ix, iy+7, text2A);
		ix = ix + nvgTextWidth(text2A);
		nvgFillColor(bonusCol);
		nvgText(ix, iy+7, text2B);
		ix = ix + nvgTextWidth(text2B);
		nvgRestore();
	end

	-- mmr hover
	if mmrBest > 0 then
		local m = mouseRegion(mmrBestX - mmrBestR, mmrBestY - mmrBestR, mmrBestR*2, mmrBestR*2);
		if m.hoverAmount > 0.5 then
			local r = getRatingInfo(mmrBest, mmrBest)
			local breakRowWidth = 1400
			local text = "Rank: " .. r.name
			local title = "Favourite Mode: " .. mmrBestPlaylist.name
			local bgCol = Color(55, 55, 55, 255*intensity);
			ui2DrawHoverWindow(Menu.mouseX + 5, Menu.mouseY + 5, breakRowWidth, title, text, r.icon, r.col, 1 * r.iconScale, bgCol);
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2TileWelcome(x, y, w, h, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;

	nvgSave();

	local hoverAmount = 0;
	local enabled = true;

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
	nvgFill();

	-- header
	local ix = x + 74;
	local iy = y + 40;
	--local iy = y + 88;
	--nvgFillColor(Color(255, 255, 255, 255 * intensity));
	--nvgSvg("internal/ui/icons/reflexlogo", ix, iy-20, 26);
	--ix = ix + 32;
	--
	---- header
	--nvgFontSize(72);
	--nvgFontFace("oswald-bold");
	--nvgText(ix, iy, "REFLEX");
	--ix = ix + 152;
	--
	---- header
	--nvgFontFace("Oswald-Stencil");
	--nvgFillColor(Color(192, 32, 31, 255 * intensity));
	--nvgText(ix, iy, "41");
	--iy = iy + 70;

	-- body
	local text = [[
		LOTS of new content now available!
		Weapon skins & crates!

		Weapon skins can now be community created via the Curated Workshop
		Get your skins into the game!
		]];

	nvgFontSize(30);
	nvgFontFace(FONT_TEXT2);
	nvgFillColor(Color(232,232,232,255 * intensity));
	nvgTextBox(x+20, iy, w-40, text);
	--iy = iy + 310;
	iy = iy + 200;

	-- ladder
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK2;
	optargs.color = Color(255,255,255);
	if ui2Button("LADDER", x+20, iy, w-40, 35, optargs) then
		launchUrl("http://reflexmm-149202.appspot.com");
		-- launchUrl("http://mm.reflexarena.com");
	end
	iy = iy + 40;

	-- changelog
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK2;
	optargs.color = Color(255,255,255);
	if ui2Button("CHANGELOG", x+20, iy, w-40, 35, optargs) then
		launchUrl("http://steamcommunity.com/app/328070/announcements");
	end
	iy = iy + 40;

	-- forums
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK2;
	optargs.color = Color(255,255,255);
	if ui2Button("FORUMS", x+20, iy, w-40, 35, optargs) then
		launchUrl("http://forums.reflexarena.com");
	end
	iy = iy + 60;

	-- social.twitter
	ix = x + 20;
	optargs.icon = "internal/ui/icons/socialTwitter";
	optargs.iconSize = 25;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	if ui2Button("", ix, iy, 60, 60, optargs) then
		launchUrl("https://twitter.com/Reflexarena");
	end
	ix = ix + 70;

	-- social.facebook
	optargs.icon = "internal/ui/icons/socialFacebook";
	optargs.iconSize = 25;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	if ui2Button("", ix, iy, 60, 60, optargs) then
		launchUrl("https://www.facebook.com/playreflex");
	end
	ix = ix + 70;

	-- social.reddit
	optargs.icon = "internal/ui/icons/socialReddit";
	optargs.iconSize = 25;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	if ui2Button("", ix, iy, 60, 60, optargs) then
		launchUrl("https://www.reddit.com/r/reflex");
	end
	ix = ix + 70;

	-- social.youtube
	optargs.icon = "internal/ui/icons/socialYoutube";
	optargs.iconSize = 25;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	if ui2Button("", ix, iy, 60, 60, optargs) then
		launchUrl("https://www.youtube.com/user/PlayReflex");
	end
	ix = ix + 70;

	-- social.discord
	optargs.icon = "internal/ui/icons/socialDiscord";
	optargs.iconSize = 25;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	if ui2Button("", ix, iy, 60, 60, optargs) then
		launchUrl("https://discord.gg/reflex");
	end
	ix = ix + 70;
	
	optargs.icon = nil;

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function DrawFriend(x, y, row, friend, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local ix = x + 20;

	-- is this a header?
	if friend.header ~= nil then

		-- bg
		local col = Color(40,40,40,255*intensity);
		nvgBeginPath();
		nvgRect(x+10, y-4, w-20, h+8);
		nvgFillColor(col);
		nvgFill();

		-- header
		--nvgFontSize(34);
		--nvgFontFace(FONT_TEXT2);
		nvgFontSize(26);
		nvgFontFace(FONT_TEXT2_BOLD);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgText(ix, y+h*(1/4)+1, friend.header);
		
		nvgFontFace(FONT_TEXT2);
		nvgText(ix, y+h*(3/4)-1, friend.headerDesc);

		-- all done
		return;
	end

	local joinButton = friend.serverIpPort ~= nil and string.len(friend.serverIpPort) > 0 and friend.serverRespondedToPing;

	-- invite if, in main menu, party isn't full, not in party already
	local inviteButton = friend.state == "In Main Menu" and party.memberCount < 4
	if inviteButton then
		for k, v in ipairs(party.members) do
			if v.steamId == friend.steamId then
				inviteButton = false
			end
		end
	end

	-- internals
	local intersectWidth = w - 8
	if joinButton or inviteButton then
		intersectWidth = intersectWidth - 68
	end
	nvgSave();
	nvgIntersectScissor(x, y-10, intersectWidth, h+20);
	
	-- avatar
	local iy = y;
	local rad = h;
	nvgBeginPath();
	nvgRect(ix, iy, rad, rad);
	nvgFillColor(Color(0,0,0, 0)); -- draw nothing if icon didn't load for some reason
	nvgFillImagePattern(friend.avatar, ix, iy, rad, rad, 0, intensity*255);
	nvgFill();

	-- avatar border
	nvgStrokeColor(ui2FormatColor(friend.coltype, intensity, m.hoverAmount, enabled));
	nvgStrokeWidth(1.5);
	nvgStroke();

	-- name
	nvgFontSize(26);
	nvgFillColor(ui2FormatColor(friend.coltype, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace(FONT_TEXT2_BOLD);
	nvgText(ix + rad+14, y+h*(1/4), friend.name);
	nvgFontSize(24);
	nvgFontFace(FONT_TEXT2);
	nvgText(ix + rad+14, y+h*(3/4), friend.state);
	
	-- want vertical clipping only
	nvgResetScissor();
	nvgIntersectScissor(x, optargs.scrollSelectionMinY, w+400, optargs.scrollSelectionMaxY - optargs.scrollSelectionMinY);
	
	-- join button
	if joinButton or inviteButton then
		local buttonHeight = 32;
		local buttonWidth = 60;
		local ix = x + w - buttonWidth - 10;
		optargs.optionalId = row;
		optargs.bgcoltype = friend.coltype;
		optargs.coltype = UI2_COLTYPE_BACKGROUND;
		optargs.nofont = true
		ui2FontSmall()
		local joinText = "Join"
		if joinButton then
			if friend.serverIsFull then
				optargs.enabled = false;
				optargs.hoverText = "Server full!";	
			end
			if string.sub(friend.state, 0, 10) == "Playing MM" then
				joinText = "Watch"
			end
		elseif inviteButton then
			joinText = "Invite"
		end
		if ui2Button(joinText, ix, y+h/2-buttonHeight/2, buttonWidth, buttonHeight, optargs) then
			if joinButton then
				if friend.serverHasPassword then
					showAsPopup("Connect", friend.serverIpPort, friend.serverIpPort);
				else
					consolePerformCommand("connect ".. friend.serverIpPort);
				end
			else
				partyInvite(friend.steamId)
			end
		end
		optargs.optionalId = nil;
		optargs.bgcoltype = nil;
		optargs.coltype = nil;
		optargs.enabled = nil;
		optargs.hoverText = nil;
		optargs.nofont = nil
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortBySortThenName(a, b)
	if a.sort == b.sort then
		return a.name < b.name;
	end
	return a.sort < b.sort;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2TileFriendsList(x, y, w, h, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;

	nvgSave();

	local hoverAmount = 0;
	local enabled = true;
	local pad = 20;

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w-14, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
	nvgFill();

	-- sort friends list
	local sortedFriends = {};
	local sortedFriendCount = 0;
	local peopleOnline = 0;
	local peopleOffline = 0;
	local peopleIngame = 0;
	for k, v in pairs(steamFriends) do
		
		local f = nil;

		-- -- test
		-- v.gameId = "328070";
		-- v.serverIpPort = "127.0.0.1:25787";
		-- v.serverHasPassword = false;
		-- v.serverIsFull = true;
		-- v.isInGame = true;
		-- v.serverRespondedToPing = true;

		if v.relationship ~= "Friend" then
			-- ignore, we get others as we've played with them recently etc
		elseif v.personaState == "Offline" then
			f = {};
			f.group = "Offline";
			f.coltype = UI2_COLTYPE_DIM;
			f.sort = 3;
			peopleOffline = peopleOffline + 1;
		elseif v.personaState == "Online" then
			f = {};
			f.group = "Online";
			f.coltype = UI2_COLTYPE_SUBSCRIBE;
			f.sort = 2;
			peopleOnline = peopleOnline + 1;
		else
			--consolePrint(v.personaName .. " - " .. v.personaState .. " - " .. v.relationship);
			f = {};
			f.group = "Online";
			f.coltype = UI2_COLTYPE_SUBSCRIBE;
			f.sort = 2.1;
			peopleOnline = peopleOnline + 1;
		end
			
		if f ~= nil then
			f.name = v.personaName;
			f.avatar = v.avatarMedium;

			if v.isInGame then
				if v.gameId == "328070" then
					peopleIngame = peopleIngame + 1;
					f.coltype = UI2_COLTYPE_FRIEND_INGAME;
					f.sort = 1;
					f.serverIpPort = v.serverIpPort;
					f.serverHasPassword = v.serverHasPassword;
					f.serverIsFull = v.serverIsFull;
					f.serverRespondedToPing = v.serverRespondedToPing;
					f.steamId = v.steamId

					-- rich presence
					f.state = "Playing Reflex";
					if v.whatDoing ~= nil and string.len(v.whatDoing) > 0 then
						f.state = v.whatDoing;end
				else
					f.state = "In other game";
					f.sort = 1.5;
				end
			else
				f.state = v.personaState;
			end

			sortedFriendCount = sortedFriendCount + 1;
			sortedFriends[sortedFriendCount] = f;
		end
	end
	if peopleOnline > 0 then
		local f = {};
		f.header = "Online";
		f.headerDesc = string.format("%d in game, %d online", peopleIngame, peopleOnline);
		f.sort = 0.9;
		f.name = "";
		sortedFriendCount = sortedFriendCount + 1;
		sortedFriends[sortedFriendCount] = f;
	end
	if peopleOffline > 0 then
		local f = {};
		f.header = "Offline";
		f.headerDesc = string.format("%d offline", peopleOffline);
		f.sort = 2.9;
		f.name = "";
		sortedFriendCount = sortedFriendCount + 1;
		sortedFriends[sortedFriendCount] = f;
	end
	table.sort(sortedFriends, SortBySortThenName);

	local optargs = {};
	optargs.itemHeight = 40;
	optargs.itemDrawFunction = DrawFriend;
	optargs.itemPad = 14;
	optargs.vertBorderPad = 14;
	optargs.intensity = intensity;
	local selectedFriend = nil;
	selectedFriend = ui2ScrollSelection(sortedFriends, selectedFriend, x, y, w, h, Menu.scrollBarDataFriends, optargs);
	y = y + 535;
	optargs.itemHeight = nil;
	optargs.itemDrawFunction = nil;
	optargs.itemPad = nil;
	optargs.vertBorderPad = nil;
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function DrawWatchServer(x, y, row, server, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local ix = x + 20;

	-- is this a header?
	if server.header ~= nil then

		-- bg
		local col = Color(40,40,40,255*intensity);
		nvgBeginPath();
		nvgRect(x+10, y-4, w-20, h+8);
		nvgFillColor(col);
		nvgFill();

		-- header
		--nvgFontSize(34);
		--nvgFontFace(FONT_TEXT2);
		nvgFontSize(26);
		nvgFontFace(FONT_TEXT2_BOLD);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgText(ix, y+h*(1/4)+1, server.header);
		
		nvgFontFace(FONT_TEXT2);
		nvgText(ix, y+h*(3/4)-1, server.headerDesc);
		
		-- top
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
		optargs.enabled = connectedToSteam;
		optargs.icon = "internal/ui/icons/refresh"
		optargs.iconSize = 11;
		if ui2Button("", ix + w - 70, y+5, 35, 35, optargs) then
			local mmCanWatchOnly = true
			serverListRefresh(mmCanWatchOnly)	-- for watch tile
		end
		optargs.icon = nil
		optargs.iconSize = nil;
		optargs.bgcoltype = nil;

		-- all done
		return;
	end

	local joinButton = true

	-- internals
	local intersectWidth = w - 98-10
	nvgSave();
	nvgIntersectScissor(x, y-10, intersectWidth, h+20);
	
	-- avatar
	r = getRatingInfo(server.highestMmr, server.highestMmr)
	local iy = y;
	local rad = h * r.iconScale;
	nvgBeginPath();
	nvgRect(ix, iy, rad, rad);
	nvgFillColor(Color(r.col.r, r.col.g, r.col.b, r.col.a * intensity))
	nvgSvg(r.icon, ix + h/2, iy + h/2, 10 * r.iconScale);
	--nvgFill();

	-- avatar border
	-- nvgStrokeColor(ui2FormatColor(friend.coltype, intensity, m.hoverAmount, enabled));
	-- nvgStrokeWidth(1.5);
	-- nvgStroke();

	-- text
	nvgFontSize(26);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace(FONT_TEXT2_BOLD);
	nvgText(ix + 54, y+h*(1/4), server.text);
	nvgFontSize(24);
	nvgFontFace(FONT_TEXT2);
	nvgText(ix + 54, y+h*(3/4), server.textDesc);
	
	-- want vertical clipping only
	nvgResetScissor();
	nvgIntersectScissor(x, optargs.scrollSelectionMinY, w+400, optargs.scrollSelectionMaxY - optargs.scrollSelectionMinY);
	
	-- join button
	if joinButton then
		local buttonHeight = 32;
		local buttonWidth = 90;
		local ix = x + w - buttonWidth - 10;
		optargs.optionalId = row;
		optargs.bgcoltype = UI2_COLTYPE_FRIEND_INGAME;
		optargs.coltype = UI2_COLTYPE_BACKGROUND;
		optargs.nofont = true
		if server.playerCount >= server.playerCountMax then
			optargs.enabled = false;
			optargs.hoverText = "Full!";	
		end
		ui2FontSmall()
		local spectators = server.spectatorCount;
		local joinText = spectators == 1 and "1 Viewer" or string.format("%d Viewers", spectators)
		if ui2Button(joinText, ix, y+h/2-buttonHeight/2, buttonWidth, buttonHeight, optargs) then
			if server.serverHasPassword then
				showAsPopup("Connect", server.serverIpPort, server.serverIpPort);
			else
				consolePerformCommand("connect ".. server.serverIpPort);
			end
		end
		optargs.optionalId = nil;
		optargs.bgcoltype = nil;
		optargs.coltype = nil;
		optargs.enabled = nil;
		optargs.hoverText = nil;
		optargs.nofont = nil;
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortBySortThenText(a, b)
	if a.sort == b.sort then
		return a.text < b.text;
	end
	return a.sort > b.sort;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function DecodeServerSteamIdPlayerList(serverSteamIds)
	local playerList = ""
	local steamIdAccum = ""
	local foundUnknownPlayer = false

	local function appendName()
		local friend = steamFriends[steamIdAccum];
		if friend ~= nil then
			playerList = playerList .. friend.personaName
		else
			playerList = playerList .. steamIdAccum
			foundUnknownPlayer = true
		end

		steamIdAccum = ""
	end

	-- format player list by looking up steam friends
	for c in serverSteamIds:gmatch"." do
		if c == "-" then
			appendName()
			playerList = playerList .. " vs "
		elseif c == "," then
			appendName()
			playerList = playerList .. ", "
			steamIdAccum = ""
		else
			steamIdAccum = steamIdAccum .. c
		end
	end
	if string.len(steamIdAccum) then
		appendName()
	end

	if foundUnknownPlayer then
		playerList = "..."
	end

	return playerList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2TileWatchMMList(x, y, w, h, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;

	nvgSave();

	local hoverAmount = 0;
	local enabled = true;
	local pad = 20;

	local playListKeyToPlaylist = {}
	for k, v in ipairs(matchmaking.playlists) do
		playListKeyToPlaylist[v.key] = v
	end

	-- test
	-- servers = {}
	-- servers[1] = {}
	-- servers[1].mm = true
	-- servers[1].playerCount = 2
	-- servers[1].playerCountMax = 11
	-- servers[1].spectatorCount = 8
	-- servers[1].highestMmr = 2120
	-- servers[1].protocolVersion = protocolVersion
	-- servers[1].serverHasPassword = false
	-- servers[1].serverIpPort = "127.0.0.1"
	-- servers[1].playlistKey = "competitive1v1"
	-- servers[1].mode = "1v1"
	-- servers[1].map = "Fusion"
	-- servers[1].steamServerIds = "76561197970656188-76561197999520277"
	-- servers[2] = {}
	-- servers[2].mm = true
	-- servers[2].playerCount = 2
	-- servers[2].playerCountMax = 7
	-- servers[2].spectatorCount = 5
	-- servers[2].highestMmr = 1620
	-- servers[2].protocolVersion = protocolVersion
	-- servers[2].serverHasPassword = false
	-- servers[2].serverIpPort = "127.0.0.1"
	-- servers[2].playlistKey = "1v1"
	-- servers[2].mode = "1v1"
	-- servers[2].map = "The Catalyst"
	-- servers[2].steamServerIds = "76561198278985577-76561197970686271"

	-- find MM servers, add them to list
	local filteredServers = {};
	local filteredServerCount = 0;
	if servers ~= nil then
		for k, server in pairs(servers) do
			if server.protocolVersion == protocolVersion and server.mm and server.playerCount > 0 and server.highestMmr > 0 then

				-- format mode name
				local modeName = server.mode
				local playlist = playListKeyToPlaylist[server.playlistKey]
				if playlist ~= nil then
					modeName = ""
					if playlist.competitive then modeName = modeName .. "Comp " end
					modeName = modeName .. playlist.name
				end

				filteredServerCount = filteredServerCount + 1;
				filteredServers[filteredServerCount] = {}
				filteredServers[filteredServerCount].sort = server.highestMmr
				filteredServers[filteredServerCount].highestMmr = server.highestMmr
				filteredServers[filteredServerCount].playerCount = server.playerCount
				filteredServers[filteredServerCount].playerCountMax = server.playerCountMax
				filteredServers[filteredServerCount].spectatorCount = server.spectatorCount
				filteredServers[filteredServerCount].serverHasPassword = false
				filteredServers[filteredServerCount].serverIpPort = server.address
				filteredServers[filteredServerCount].text = string.format("%s: %s", string.upper(modeName), server.map)
				filteredServers[filteredServerCount].textDesc = DecodeServerSteamIdPlayerList(server.steamServerIds)
			end
		end
	end

	-- add header
	f = {}
	f.header = string.format("Watch Matchmaking Live")
	f.headerDesc = filteredServerCount == 1 and "1 game being played" or string.format("%d games being played", filteredServerCount);
	f.text = ""
	f.sort = 5000;
	filteredServerCount = filteredServerCount + 1;
	filteredServers[filteredServerCount] = f;
	
	-- sort
	table.sort(filteredServers, SortBySortThenText);
	
	-- prepare optargs
	local optargs = {};
	optargs.itemHeight = 40;
	optargs.itemDrawFunction = DrawWatchServer;
	optargs.itemPad = 14;
	optargs.vertBorderPad = 14;
	optargs.intensity = intensity;
	local itemsInListHeight = 14 + 40 * filteredServerCount + 14
	local requireScrollBar = itemsInListHeight > h
	--local requireScrollBar = filteredServerCount > 8

	-- bg
	local bw = requireScrollBar and w-14 or w -- shrink if we require scrollbar
	nvgBeginPath();
	nvgRect(x, y, bw, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
	nvgFill();

	-- draw
	local selectedServer = nil;
	local sw = requireScrollBar and w or w+14 -- grow if no scrollbar
	selectedFriend = ui2ScrollSelection(filteredServers, selectedServer, x, y, sw, h, Menu.scrollBarDataWatchMMList, optargs);
	y = y + 535;
	optargs.itemHeight = nil;
	optargs.itemDrawFunction = nil;
	optargs.itemPad = nil;
	optargs.vertBorderPad = nil;
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2Tile(x, y, w, h, bgimage, title, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;
	
	local hoverAmount = 0;
	local leftUp = false;
	local leftHeld = false;
	local enabled = true;

	if optargs.canClick then
		local optionalId = x+y;
		local m = mouseRegion(x, y, w, h, optionalId);
		hoverAmount = m.hoverAmount;
		leftUp = m.leftUp;
		leftHeld = m.leftHeld;
	end

	nvgSave();

	-- bg	
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, hoverAmount, enabled));
	nvgFillImagePattern(bgimage, x, y, w, 220, 0, intensity*255);--h);
	nvgFill();

	-- title
	nvgFontSize(36);
	nvgFontFace("oswald-light");
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
	nvgTextBox(x+20, y+40, w-40, title);

	--
	if leftHeld then
		-- held
		nvgFillColor(Color(0, 0, 0, 20*intensity));
		nvgFill();
	else
		-- hover
		nvgFillColor(Color(255, 255, 255, hoverAmount*20*intensity));
		nvgFill();
	end

	-- time splat
	if optargs.epochTimeTarget ~= nil then
		local delta = optargs.epochTimeTarget - epochTime;
		local isLive = delta < 0 and optargs.epochTimeLength ~= nil and delta > -optargs.epochTimeLength;		

		local ix = x + w - 50;
		local iy = y + h - 45;
		nvgFillColor(ui2FormatColor(isLive and UI2_COLTYPE_BUTTON or UI2_COLTYPE_BACKGROUND, intensity, hoverAmount, enabled));
		nvgSvg("internal/ui/icons/circleSplat", ix, iy, 70);
		
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE);
		nvgFontFace("oswald-light");
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
	
		if delta > 0 then
			local rem = delta;
			
			local seconds = rem % 60;
			rem = rem - seconds;
			rem = rem / 60;

			local minutes = rem % 60;
			rem = rem - minutes;
			rem = rem / 60;

			local hours = rem % 24;
			rem = rem - hours;
			rem = rem / 24;

			local days = rem;

			-- days
			nvgFontSize(36);
			nvgText(ix-36, iy, string.format("%02d", days));
			nvgFontSize(16);
			nvgText(ix-36, iy+18, "DAYS");

			-- hours
			nvgFontSize(36);
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
			nvgText(ix, iy, string.format("%02d", hours));
			nvgFontSize(16);
			nvgText(ix, iy+18, "HOURS");

			-- minutes
			nvgFontSize(36);
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
			nvgText(ix+36, iy, string.format("%02d", minutes));
			nvgFontSize(16);
			nvgText(ix+36, iy+18, "MINS");

		elseif isLive then
			
			nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
			nvgFontSize(32);
			nvgText(ix, iy-5, "Watch Live");

		else
			
			nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
			nvgFontSize(32);
			nvgText(ix, iy-5, "Watch VODs");
		end
	end

	nvgRestore();

	if leftUp then
		playSound("internal/ui/sounds/buttonClick")
	end

	return leftUp;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawHome(intensity)
	local optargs = {
		intensity = intensity;
	};
	local x = -620;
	local y = -300;
	local w = 600;

	--ui2TileFriendsList(-920, y, 280, 700, optargs);

	-- training tile
	local iy = y;
	optargs.canClick = true; -- enable once ironguard is published (once build is released!)
	if ui2Tile(-190, iy, 710, 220, "internal/ui/tiles/tile_a_c", "", optargs) then
		--launchUrl("http://store.steampowered.com/itemstore/328070");
		--self.modeKey = 5;
		--self.modes[self.modeKey].subKey = 1;
		--self.submode = 3;

		-- map
		self.modeKey = 6;
		self.modes[self.modeKey].subKey = 1;
	end
	optargs.canClick = nil;

	-- forge/map editor to side
	optargs.icon = "internal/ui/icons/forge"
	optargs.iconSize = 24;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK2;
	if ui2Button("", -190 + 710+20, iy, 80, 80, optargs) then
		showAsPopup("ConfirmForge")
	end
	optargs.icon = "internal/ui/icons/mapEditor"
	if ui2Button("", -190 + 710+20, iy+140, 80, 80, optargs) then
		showAsPopup("ConfirmMapEditor")
	end
	optargs.icon = nil
	optargs.iconSize = nil;
	optargs.bgcoltype = nil;
	iy = iy + 240;

	-- welcome tile
	ui2TileWelcome(-190, iy, 380, 460, optargs);
	
	-- optargs.canClick = true;
	-- if ui2Tile(240, iy, 380, 220, "internal/ui/tiles/tile_c_c", "", optargs) then
	-- 	self.modeKey = 4;
	-- 	self.modes[self.modeKey].subKey = 1;
	-- end
	-- optargs.canClick = nil;
	ui2TileWatchMMList(240, iy, 380, 220, optargs);	
	iy = iy + 240;
	
	optargs.canClick = true;
	--optargs.canClick = connectedToSteam; -- no wmap on non-steam, so only make it clickable if we have steam
	--if ui2Tile(240, iy, 380, 220, "internal/ui/tiles/vid_zigzter_c", "", optargs) then
	if ui2Tile(240, iy, 380, 220, "internal/ui/tiles/tile_c_c", "", optargs) then
		-- map: sanctum
		-- self.modeKey = 4;
		-- self.modes[self.modeKey].subKey = 3;
		-- consolePerformCommand("sv_startwmap " .. 803273126);
		-- consolePerformCommand("sv_startmode 1v1");
		-- consolePerformCommand("sv_steam 1");

		-- addons
		-- self.modeKey = 7;
		-- self.modes[self.modeKey].subKey = 7;

		-- -- cosmetics
		-- self.modeKey = 6;
		-- self.modes[self.modeKey].subKey = 1;
		-- 
		-- -- training ots
		-- self.modeKey = 5;
		-- self.modes[self.modeKey].subKey = 2;

		-- launchUrl("http://forums.reflexarena.com/index.php?/topic/4388-proving-grounds/")
		showAsPopup("ConfirmForge")
	end
	optargs.canClick = nil;
	iy = iy + 240;

	-- last so hover goes over other tiles
	ui2TileProfile(-620, y, 380, 220, optargs);
	
	-- friends list
	ui2TileFriendsList(-620, y+240, 380, 700-240, optargs);	
end

--------------------------------------------------------------------------------
-- item for uiScrollSelection()
--------------------------------------------------------------------------------
local function ui2ScrollSelectionTrainingItem(x, y, row, item, isSelected, m, w, h, optargs)
	
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	-- look up leaderboardEntry
	local entry = nil;
	local leaderboard = QuerySelfLeaderboard(item.map,  "training");
	if leaderboard ~= nil then
		entry = leaderboard.friendsEntries[steamId];
	end

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	-- old version warning
	local old = false;
	if entry ~= nil and leaderboard ~= nil and entry.mapHash ~= leaderboard.mapHash and entry.mapHash ~= 0 then
		local ix = x + w - 34;
		local iy = y-3;
		
		nvgSave();
		nvgResetScissor();
		
		local optargsPopup = {};
		optargsPopup.optionalId = iy;
		ui2TooltipBox("This result was obtained on an older version", ix, iy, 250, optargsPopup);
		
		nvgRestore();

		old = true;
	end

	-- text
	local name = item.name;
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled);
	--col.r = itemDef.color.r;
	--col.g = itemDef.color.g;
	--col.b = itemDef.color.b;
	ui2FontNormal();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x+10, y+h/2, name);

	-- time
	local name = "-";
	if entry ~= nil and entry.timeMillis > 0 then
		name = FormatTimeToDecimalTime(entry.timeMillis);
	end
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, false);
	local ix = x + w - 10;
	if old then
		col = ui2FormatColor(UI2_COLTYPE_FAVORITE, intensity, m.hoverAmount, false);
		ix = ix - 20;
	end
	--col.r = itemDef.color.r;
	--col.g = itemDef.color.g;
	--col.b = itemDef.color.b;
	ui2FontSmall();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgText(ix, y+h/2-13, name);

	-- read tokens from leaderboard
	local tokens = {};
	local tokensTotal = 0;
	if entry ~= nil then
		tokens = entry.tokens;
		for k, v in pairs(tokens) do
			tokensTotal = tokensTotal + 1;
		end
	end

	-- tokens
	local ir = 9;
	local istride = 23;
	local ix = x + w + 5 - istride * tokensTotal;
	local iy =  y+h/2+10;
	for i = 1, tokensTotal do
		local achieved = tokens[i].achieved;
		nvgFillColor(achieved and Color(232,232,232,255*intensity) or Color(70,70,70,255*intensity));
		nvgSvg("internal/items/training_token/training_token", ix, iy, ir);
		ix = ix + istride;
	end

	---- icon
	--if itemDef.ownedCount > 0 then
	--	local ix = x + 17;
	--	local iy = y + h/2+1;
	--	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	--	nvgSvg("internal/ui/icons/tick", ix, iy, 8);
	--end
	--
	---- count text
	--if itemDef.ownedCount > 1 then
	--	local text = "x" .. itemDef.ownedCount;
	--	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, enabled);
	--	ui2FontSmall();
	--	nvgFillColor(col);
	--	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BOTTOM);
	--	nvgText(x+w-5, y+h-3, text);
	--end

	return m.leftUp;
end

--------------------------------------------------------------------------------
-- item for uiScrollSelection()
--------------------------------------------------------------------------------
local function ui2ScrollSelectionTrainingBotsItem(x, y, row, item, isSelected, m, w, h, optargs)
	
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	local kills = item.kills
	local won = item.won

	-- -- look up leaderboardEntry
	-- local entry = nil;
	-- local leaderboard = QuerySelfLeaderboard(item.map,  "training");
	-- if leaderboard ~= nil then
	-- 	entry = leaderboard.friendsEntries[steamId];
	-- end

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	-- text
	local name = item.name;
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled);
	--col.r = itemDef.color.r;
	--col.g = itemDef.color.g;
	--col.b = itemDef.color.b;
	ui2FontNormal();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x+10, y+h/2, name);

	-- kills
	local name = "-"
	if kills > 0 then
		name = string.format("%d kill%s", kills, kills ~= 1 and "s" or "")
	end
	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, kills > 0);
	local ix = x + w - 10;
	ui2FontSmall();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgText(ix, y+h/2-13, name);

	-- read tokens from leaderboard
	local tokens = {};
	local tokensTotal = 0;
	if entry ~= nil then
		tokens = entry.tokens;
		for k, v in pairs(tokens) do
			tokensTotal = tokensTotal + 1;
		end
	end

	-- tokens
	local ir = 9;
	local istride = 23;
	local ix = x + w + 5 - istride;
	local iy = y+h/2+10;
	nvgFillColor(won and Color(232,232,232,255*intensity) or Color(70,70,70,255*intensity));
	nvgSvg("internal/ui/icons/tick", ix, iy, ir);

	---- icon
	--if itemDef.ownedCount > 0 then
	--	local ix = x + 17;
	--	local iy = y + h/2+1;
	--	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	--	nvgSvg("internal/ui/icons/tick", ix, iy, 8);
	--end
	--
	---- count text
	--if itemDef.ownedCount > 1 then
	--	local text = "x" .. itemDef.ownedCount;
	--	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, enabled);
	--	ui2FontSmall();
	--	nvgFillColor(col);
	--	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BOTTOM);
	--	nvgText(x+w-5, y+h-3, text);
	--end

	return m.leftUp;
end

--------------------------------------------------------------------------------
-- item for uiScrollSelection()
--------------------------------------------------------------------------------
local function ui2ScrollSelectionLeaderboardItem(x, y, row, item, isSelected, m, w, h, optargs)
	
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	
	local entry = item;
	local rank = 1;
	local iy = y + h/2;

	nvgSave();

	-- bg
	local isMe = entry.steamId == steamId;
	local coltype = isMe and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();
		
	-- rank
	local iw = optargs.rankWidth;
	local ix = x;
	ui2FontSmall();
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.8, m.hoverAmount, enabled, m.leftHeld));
	nvgText(ix+iw/2, iy, entry.rank);
	ix = ix + iw;

	-- avatar
	local ih = 23;
	nvgBeginPath();
	nvgRoundedRect(ix, iy-ih/2, ih, ih, 4);
	nvgFillColor(Color(230,220,240));
	nvgFillImagePattern("$avatarSmall_"..entry.steamId, ix, iy-ih/2, ih, ih, 0, intensity*255);
	nvgFill();
	ix = ix + 30;
		
	-- name
	local friend = steamFriends[entry.steamId];
	local name = friend ~= nil and friend.personaName or entry.steamId;
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.8, m.hoverAmount, enabled, m.leftHeld));
	nvgText(ix, iy, name);
	
	-- speed
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x + 320, iy, entry.topSpeed .. "ups");

	-- time
	local text = FormatTimeToDecimalTime(entry.timeMillis);
	if old then
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_FAVORITE, intensity*.8, m.hoverAmount, enabled, m.leftHeld));
	end
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgText(x + w - 7, iy, text);

	if old then
		if entry.mapHash ~= leaderboard.mapHash then
			local optargs = {};
			optargs.optionalId = i;
			ui2TooltipBox("This result was obtained on an older version", x + 415, iy-16, 250, optargs);
		end
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local _trainingMapSelected = nil;
local _trainingMaps = {
	[1] = { ["name"] = "Stage 1 Movement", ["map"] = "training_move_stage_1", ["desc"] = "Introduces you to the basic movement in Reflex. You will learn jump, duck, duckjump, double jump and rocket jump! Essential for any beginner." },
	[2] = { ["name"] = "Stage 2 Movement", ["map"] = "training_move_stage_2", ["desc"] =  "So, now that you have the basics down, here's some more basics! Time to step things up and get even more mobile. You'll be learning how to circle jump, ramp double jump, distance rocket jump and plasma climb."},
	[3] = { ["name"] = "Stage 1 Items", ["map"] = "training_items_stage_1", ["desc"] =  "Learn about the things you can get that are essential to saving your life. Healths, Armors, Carnage!"},
	[4] = { ["name"] = "Stage 1 Combat", ["map"] = "training_combat_stage_1", ["desc"] =  "Finally time to shoot things! Learn what the pickups look like, get some tips, and get a feel for how they behave. Plus, shooting stuff is fun."},
	[5] = { ["name"] = "Stage 2 Combat", ["map"] = "training_combat_stage_2", ["desc"] =  "Now it's time to put everything you've learned so far to use to complete this course. After completing this your journey has just begun, there's plenty more to explore online to grow your skills to unlimited potential."},
};
function Menu:ui2DrawTraining(intensity)
	local optargs = {
		intensity = intensity;
	};
	nvgSave();
	
	local x = -620;
	local y = -250;
	local colWidth = 550;
	local colIndent = 250;

	optargs.enabled = false;
	ui2Label("Missions", x, y, optargs);
	optargs.enabled = nil;
	y = y + 60;

	-- ensure we have a valid selection
	if _trainingMapSelected == nil then
		_trainingMapSelected = _trainingMaps[1];
	end

	-- map on right first
	if _trainingMapSelected ~= nil then
		local map = _trainingMapSelected;

		local ix = 70;
		local iy = -250;
		local iwidth = 550;
		local iheight = iwidth * 9 / 16;

		
		-- header
		local headery = iy;
		optargs.enabled = false;
		ui2Label(map.name, ix, iy, optargs);
		optargs.enabled = true;
		iy = iy + 60;
		
		if self.selected_training_leaderboard == "Friends Leaderboard" or self.selected_training_leaderboard == "Global Leaderboard" or self.selected_training_leaderboard == "Top Times" then

			local leaderboard, entries, entryCount, useGlobalRank;

			-- query leaderboard & extract results
			if self.selected_training_leaderboard == "Friends Leaderboard" then
				leaderboard = QueryFriendsLeaderboard(_trainingMapSelected.map, "training");
				entries, entryCount = ExtractFriendsLeaderboardEntries(leaderboard);
				useGlobalRank = false;
			elseif self.selected_training_leaderboard == "Top Times" then
				leaderboard = QueryGlobalLeaderboard(_trainingMapSelected.map, "training", "toponly");
				entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
				useGlobalRank = true;
			else
				leaderboard = QueryGlobalLeaderboard(_trainingMapSelected.map, "training");
				entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
				useGlobalRank = true;
			end

			-- find our rank
			local myRank = 1;
			for i = 1, entryCount do
				if entries[i].steamId == steamId then
					myRank = i;
				end
			end

			-- find range
			local startRank = math.max(myRank - 5, 1);
			local endRank = math.min(myRank + 5, entryCount);
			startRank = math.max(endRank - 10, 1);
			endRank = math.min(startRank + 10, entryCount);

			-- create another table of just the appropriate range (just so we can pass to ui2ScrollSelection)
			local entriesToDraw = {};
			local entriesToDrawCount = 0;
			for rank = startRank, endRank do
				entriesToDrawCount = entriesToDrawCount + 1;
				entriesToDraw[entriesToDrawCount] = entries[rank];
				entriesToDraw[entriesToDrawCount].rank = useGlobalRank and entries[rank].globalRank or rank;
			end

			-- determine rank width do we scale well (to big rank numbers :))
			if entriesToDrawCount > 0 then 
				local highestRank = entriesToDraw[entriesToDrawCount].rank;
				optargs.rankWidth = string.len(highestRank) * 16;
				optargs.rankWidth = math.max(optargs.rankWidth, 32);
			end

			-- draw list of leaderboards
			local bogusScrollData = {}; -- never scroll it?
			optargs.itemHeight = 30;
			optargs.itemDrawFunction = ui2ScrollSelectionLeaderboardItem;
			optargs.itemPad = 5;
			local sw = colWidth + UI_SCROLLBAR_WIDTH;	-- grow it a bit to line up nicely, we won't have a scrollbar
			local selectedEntry = ui2ScrollSelection(entriesToDraw, nil, ix, iy, sw, 500, bogusScrollData, optargs);

		else

			-- map image
			local previewImageName = "$mappreview_"..map.map;
			nvgBeginPath();
			nvgRoundedRect(ix, iy, iwidth, iheight, 0);
			nvgFillImagePattern(previewImageName, ix-iwidth*.25, iy-iheight*.25, iwidth*1.5, iheight*1.5, 0, intensity*255); -- (center quarter of image)
			nvgFill();
			iy = iy + iheight;
			iy = iy + 20;
		
			-- map desc
			if map.desc ~= nil then
				local breakRowWidth = iwidth;
				local bounds = nvgTextBoxBounds(breakRowWidth, map.desc);
				local height = bounds.maxy - bounds.miny;
			
				iy = iy + 15;
				local hoverAmount = 0;
				local enabled = true;
				nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, optargs.intensity, hoverAmount, enabled));
				ui2FontNormal();
				nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
				nvgTextBox(ix, iy, breakRowWidth, map.desc);

				iy = iy + height + 90;
			end
		end

		-- combo to select 
		local options = {
			"Description",
			"Friends Leaderboard",
			"Global Leaderboard",
			"Top Times"
		};
		if self.selected_training_leaderboard == nil then
			self.selected_training_leaderboard = "Description";
		end
		self.selected_training_leaderboard = ui2ComboBox(options, self.selected_training_leaderboard, ix + iwidth - 240, headery, 240, self.comboBoxDataTrainingLeaderboard, optargs);
	end

	-- play button
	local iy = y + 480;
	local trainingMultiplayer = widgetGetConsoleVariable("training_multiplayer") ~= 0;
	optargs.enabled = _trainingMapSelected ~= nil;
	if optargs.enabled and party.memberCount > 1 then
		optargs.enabled = false
		optargs.hoverText = "In party, use Quickplay to start match"
	end
	if ui2Button("Play", 620 - 200, iy, 200, 35, optargs) then
		consolePerformCommand("disconnect");
		consolePerformCommand("sv_startmode training");
		consolePerformCommand("sv_startmutators "); -- disable previously set mutators!
		consolePerformCommand("sv_maxclients " .. (trainingMultiplayer and 6 or 1));
		if connectedToSteam then
			-- gives us player cosmetics, so we want this
			consolePerformCommand("sv_steam 1");
		else
			-- need fallback. no steam => cannot start steam server!
			consolePerformCommand("sv_steam 0");
		end
		consolePerformCommand("map " .. _trainingMapSelected.map);
	end
	optargs.hoverText = nil
	optargs.enabled = nil
	iy = iy + 60;

	-- multiplayer?
	ui2Label("Allow multiplayer", 620-220, iy, optargs);
	local trainingMultiplayerNew = ui2CheckBox(trainingMultiplayer, 585, iy, optargs);
	if trainingMultiplayerNew ~= trainingMultiplayer then
		widgetSetConsoleVariable("training_multiplayer", trainingMultiplayerNew and 1 or 0);
	end
	iy = iy + 60;

	-- draw list of maps
	optargs.itemHeight = 50;
	optargs.itemDrawFunction = ui2ScrollSelectionTrainingItem;
	optargs.itemPad = 5;
	_trainingMapSelected = ui2ScrollSelection(
		_trainingMaps, _trainingMapSelected, x, y, colWidth, 300, self.scrollBarDataTrainingMap, optargs);
	y = y + 255 + 70;

	--ui2FontSmall();
	--optargs.nofont = true;
	--optargs.halign = NVG_ALIGN_RIGHT;
	--optargs.enabled = false;
	--ui2Label("To qualify for a time complete all goals & collect all tokens", x+colWidth - 10, y, optargs);
	--y = y + 80;
	--optargs.enabled = nil;
	--optargs.nofont = nil;
	--optargs.halign = nil;

	-- count stats
	local missionCompletedCount = 0;
	local missionTotalCount = 0;
	local tokenGotCount = 0;
	local tokenTotalCount = 0;
	for k, item in ipairs(_trainingMaps) do

		local leaderboard = QuerySelfLeaderboard(item.map, "training");
		if leaderboard ~= nil then
			local entry = leaderboard.friendsEntries[steamId];
			if entry ~= nil then

				-- count tokens
				for k, token in ipairs(entry.tokens) do
					tokenTotalCount = tokenTotalCount + 1;
					if token.achieved then
						tokenGotCount = tokenGotCount + 1;
					end
				end

				-- valid time => we've finished it
				if entry.timeMillis > 0 then
					missionCompletedCount = missionCompletedCount + 1;
				end
			end
		end

		missionTotalCount = missionTotalCount + 1;
	end

	-- stats
	optargs.enabled = false;
	ui2Label("Result", x, y, optargs);
	optargs.enabled = nil;
	y = y + 60;
	
	optargs.enabled = tokenTotalCount > 0;
	ui2Label("Missions Completed:", x, y, optargs);
	ui2Label(string.format("%d / %d", missionCompletedCount, missionTotalCount), x + colIndent, y, optargs);
	y = y + 45;

	ui2Label("Tokens Collected:", x, y, optargs);
	ui2Label(tokenGotCount, x + colIndent, y, optargs);
	y = y + 60;
	optargs.enabled = nil;

	ui2Label("To qualify for a time complete all goals & collect all tokens", x, y, optargs);
	y = y + 60;
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local _trainingBotsMapSelected = nil;
local _trainingBotsMaps = {
	[1] = { ["name"] = "FFA: Fusion",			["map"] = "Fusion",			["botSkill"] = 10,	["botCount"] = 2,	["gameMode"] = "ffa",	["desc"] = "Wreak carnage in a Free-For-All against 2 opponents simultaneously!" },
	[2] = { ["name"] = "Duel: The Catalyst",	["map"] = "TheCatalyst",	["botSkill"] = 20,	["botCount"] = 1,	["gameMode"] = "1v1",	["desc"] =  "Come to grips with one of the more popular competitive modes in a popular duel map."},
	[3] = { ["name"] = "Doubles: Aerowalk",		["map"] = "Aerowalk",		["botSkill"] = 40,	["botCount"] = 3,	["gameMode"] = "2v2",	["desc"] =  "Coordinate with your bot companion to take out the enemy bot team."},
};
function Menu:ui2DrawTrainingBots(intensity)
	local optargs = {
		intensity = intensity;
	};
	nvgSave();
	
	local x = -620;
	local y = -250;
	local colWidth = 550;
	local colIndent = 250;

	optargs.enabled = false;
	ui2Label("Matches", x, y, optargs);
	optargs.enabled = nil;
	y = y + 60;

	-- ensure we have a valid selection
	if _trainingBotsMapSelected == nil then
		_trainingBotsMapSelected = _trainingBotsMaps[1];
	end

	-- map on right first
	if _trainingBotsMapSelected ~= nil then
		local map = _trainingBotsMapSelected;

		local ix = 70;
		local iy = -250;
		local iwidth = 550;
		local iheight = iwidth * 9 / 16;
		
		-- header
		local headery = iy;
		optargs.enabled = false;
		ui2Label(map.name, ix, iy, optargs);
		optargs.enabled = true;
		iy = iy + 60;

		-- map image
		local previewImageName = "$mappreview_"..map.map;
		nvgBeginPath();
		nvgRoundedRect(ix, iy, iwidth, iheight, 0);
		nvgFillImagePattern(previewImageName, ix-iwidth*.25, iy-iheight*.25, iwidth*1.5, iheight*1.5, 0, intensity*255); -- (center quarter of image)
		nvgFill();
		iy = iy + iheight;
		iy = iy + 20;
		
		-- map desc
		if map.desc ~= nil then
			local breakRowWidth = iwidth;
			local bounds = nvgTextBoxBounds(breakRowWidth, map.desc);
			local height = bounds.maxy - bounds.miny;
			
			iy = iy + 15;
			local hoverAmount = 0;
			local enabled = true;
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, optargs.intensity, hoverAmount, enabled));
			ui2FontNormal();
			nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
			nvgTextBox(ix, iy, breakRowWidth, map.desc);

			iy = iy + height + 90;
		end
	end

	-- play button
	local iy = y + 480;
	optargs.enabled = _trainingBotsMapSelected ~= nil;
	if optargs.enabled and party.memberCount > 1 then
		optargs.enabled = false
		optargs.hoverText = "In party, use Quickplay to start match"
	end
	if ui2Button("Play", 620 - 200, iy, 200, 35, optargs) then
		consolePerformCommand("disconnect");
		consolePerformCommand(string.format("sv_startmode %s", _trainingBotsMapSelected.gameMode));
		consolePerformCommand("sv_startruleset "); -- disable previously set ruleset!
		consolePerformCommand("sv_startmutators "); -- disable previously set mutators!
		consolePerformCommand("sv_maxclients " .. _trainingBotsMapSelected.botCount + 1);
		if connectedToSteam then
			-- gives us player cosmetics, so we want this
			consolePerformCommand("sv_steam 1");
		else
			-- need fallback. no steam => cannot start steam server!
			consolePerformCommand("sv_steam 0");
		end
		consolePerformCommand("map " .. _trainingBotsMapSelected.map);
		for i = 1, _trainingBotsMapSelected.botCount do
			local botTeam = (i % 2)
			consolePerformCommand(string.format("sv_addbot %d %d", _trainingBotsMapSelected.botSkill, botTeam))
		end
		consolePerformCommand("cl_playerteam 0");
		consolePerformCommand("cl_playerstate " .. PLAYER_STATE_INGAME);
	end
	optargs.hoverText = nil
	optargs.enabled = nil
	iy = iy + 60;

	-- read results from leaderboard
	for k, item in ipairs(_trainingBotsMaps) do
		local leaderboard = QuerySelfLeaderboard(item.map, item.gameMode);
		local kills = 0;
		local won = false;
		if leaderboard ~= nil then
			local entry = leaderboard.friendsEntries[steamId];
			if entry ~= nil then
				botSkill = entry.topSpeed;				-- (yuuuuk, this just gets things working quickly though :S)
				if botSkill == item.botSkill then
					won = entry.tokens[1] ~= nil and entry.tokens[1].achieved;		-- (yuuuuk, this just gets things working quickly though :S)
					kills = entry.distanceTravelled;								-- (yuuuuk, this just gets things working quickly though :S)
				end
			end
		end
		item.won = won;
		item.kills = kills;
	end

	-- draw list of maps
	optargs.itemHeight = 50;
	optargs.itemDrawFunction = ui2ScrollSelectionTrainingBotsItem;
	optargs.itemPad = 5;
	_trainingBotsMapSelected = ui2ScrollSelection(
		_trainingBotsMaps, _trainingBotsMapSelected, x, y, colWidth, 300, self.scrollBarDataTrainingBotsMap, optargs);
	y = y + 255 + 70;

	-- count stats
	local missionCompletedCount = 0;
	local missionTotalCount = 0;
	local killsGotCount = 0;
	for k, item in ipairs(_trainingBotsMaps) do
		missionTotalCount = missionTotalCount + 1;
		killsGotCount = killsGotCount + item.kills
		if item.won then
			missionCompletedCount = missionCompletedCount + 1
		end
	end

	-- stats
	optargs.enabled = false;
	ui2Label("Result", x, y, optargs);
	optargs.enabled = nil;
	y = y + 60;
	
	ui2Label("Matches Won:", x, y, optargs);
	ui2Label(string.format("%d / %d", missionCompletedCount, missionTotalCount), x + colIndent, y, optargs);
	y = y + 45;

	ui2Label("Total Kills:", x, y, optargs);
	ui2Label(killsGotCount, x + colIndent, y, optargs);
	y = y + 60;

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawLearn(intensity)
	local optargs = {
		intensity = intensity;
	};
	nvgSave();
	
	local x = -620;
	local y = -250;
	local colWidth = 650;
	local colIndent = 250;
	ui2Label("Below you can find some videos from our community members!", x, y, optargs);
	y = y + 35;
	ui2Label("These can help you take your skills further!", x, y, optargs);
	y = y + 90;
	
	ui2Label("Introduction", x, y, optargs);
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2VideoButton("internal/ui/thumbs/intro_kovaak_c", "Tutorial Series", "KovaaK", x + colIndent, y, colWidth - colIndent, 95, optargs) then
		launchUrl("https://www.youtube.com/watch?v=JtxCauiv5B4&list=PLxP7tvMqaXzBGG8VV4LqaUddV1WrErMXS");
	end
	y = y + 130;
	
	ui2Label("Movement", x, y, optargs);
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2VideoButton("internal/ui/thumbs/movement_entik_c", "Movement Overview", "Entik", x + colIndent, y, colWidth - colIndent, 95, optargs) then
		launchUrl("https://www.youtube.com/watch?v=rpy38UiTWrY");
	end
	y = y + 130;
	
	ui2Label("Level Editor", x, y, optargs);
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2VideoButton("internal/ui/thumbs/editor_electro_c", "Level Editor Walk Through", "Electro", x + colIndent, y, colWidth - colIndent, 95, optargs) then
		launchUrl("https://www.youtube.com/watch?v=Brg5eiOzIIU");
	end
	y = y + 130;

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByPing(a, b)
	if a.ping == b.ping then
		return a.address < b.address;
	end
	return a.ping < b.ping;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByPlayers(a, b)
	if a.playerCount == b.playerCount then
		return a.address < b.address;
	end
	return a.playerCount > b.playerCount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByMode(a, b)
	if a.mode == b.mode then
		return a.address < b.address;
	end
	return a.mode < b.mode;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByMap(a, b)
	if a.map == b.map then
		return a.address < b.address;
	end
	return a.map < b.map;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByName(a, b)
	if a.name == b.name then
		return a.address < b.address;
	end
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SortByRuleset(a, b)
	if a.ruleset == b.ruleset then
		return a.address < b.address;
	end
	return a.ruleset < b.ruleset;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local ui2DrawServerHeight = 35;
local ui2DrawServerHeaders = {
	["Flag"] =		{ ["x"] = 40, drawHeader = false },
	["Hostname"] =	{ ["x"] = 60, sort = SortByName },
	["Map"] =		{ ["x"] = 440, sort = SortByMap },
	["Players"] =	{ ["x"] = 590, sort = SortByPlayers },
	["Mode"] =		{ ["x"] = 700, sort = SortByMode },
	["Ruleset"] =	{ ["x"] = 785, sort = SortByRuleset },
	["Address"] =	{ ["x"] = 890 },
	["Ping"] =		{ ["x"] = 1100, sort = SortByPing },
	["Dedicated"] = { ["x"] = 1180, drawHeader = false },
	["Password"] =	{ ["x"] = 1210, drawHeader = false }
}
local function ui2DrawServer(x, y, row, server, isSelected, m, w, h, optargs)
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;

	-- disable server is miss-matching version
	if server.protocolVersion ~= protocolVersion then
		enabled = false;
	end

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();

	col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled);
	local colDisabled = ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, false);
	ui2FontSmall();
	nvgFillColor(col);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	
	nvgFillColor(server.dedicated and col or colDisabled);
	local iconName = "internal/ui/icons/dedicatedServer";
	hx = nvgSvg(iconName, x + ui2DrawServerHeaders["Dedicated"].x, y+h/2, 9);
	
	nvgFillColor(server.password and col or colDisabled);
	local iconName = "internal/ui/icons/passwordedServer";
	hx = nvgSvg(iconName, x + ui2DrawServerHeaders["Password"].x, y+h/2, 9);
	
	nvgFillColor(col);
	local iconName = "internal/ui/icons/flags/"..server.country;
	hx = nvgSvg(iconName, x + ui2DrawServerHeaders["Flag"].x, y+h/2, 12);

	-- hostname (clip)
	nvgSave();
	nvgIntersectScissor(x, y, ui2DrawServerHeaders["Map"].x-10, h);
	nvgText(x + ui2DrawServerHeaders["Hostname"].x, y+h/2, server.name);	
	nvgRestore();

	-- mapname (clip)
	nvgSave();
	nvgIntersectScissor(x, y, ui2DrawServerHeaders["Players"].x-10, h);
	nvgText(x + ui2DrawServerHeaders["Map"].x, y+h/2, server.map);
	nvgRestore();
	
	-- mode
	nvgSave();
	nvgIntersectScissor(x, y, ui2DrawServerHeaders["Ruleset"].x-10, h);
	nvgText(x + ui2DrawServerHeaders["Mode"].x, y+h/2, server.mode);
	-- & mutators
	local ix = x + ui2DrawServerHeaders["Mode"].x + nvgTextWidth(server.mode) + 5;
	local iy = y+h/2;
	local iconRad = 12;
	local upperCaseMutators = string.upper(server.mutators);
	for k, v in pairs(mutatorDefinitions) do
		if string.find(upperCaseMutators, k) ~= nil then
			-- icon
			local iconCol = enabled and v.col or colDisabled;
			nvgFillColor(Color(iconCol.r, iconCol.g, iconCol.b, col.a));
			nvgSvg(v.icon, ix + iconRad, iy, iconRad-2);
			ix = ix + iconRad*2-4;
		end
	end
	nvgRestore();

	-- ruleset
	nvgSave();
	nvgIntersectScissor(x, y, ui2DrawServerHeaders["Address"].x-10, h);
	nvgText(x + ui2DrawServerHeaders["Ruleset"].x, y+h/2, server.ruleset);
	nvgRestore();

	-- address
	nvgSave();
	nvgIntersectScissor(x, y, ui2DrawServerHeaders["Ping"].x-10, h);
	nvgText(x + ui2DrawServerHeaders["Address"].x, y+h/2, server.address);
	nvgRestore();

	local playerstext = server.playerCount .. "/" .. server.playerCountMax;
	local playerscol = Color(255,255,255, col.a);
	if server.playerCount == 0 then
		playerscol.r = col.r * (180/255);
		playerscol.g = col.g * (180/255);
		playerscol.b = col.b * (180/255);
	elseif server.playerCount == server.playerCountMax then
		playerscol.r = col.r * (255/255);
		playerscol.g = col.g * (140/255);
		playerscol.b = col.b * (140/255);
	else
		playerscol.r = col.r * (140/255);
		playerscol.g = col.g * (255/255);
		playerscol.b = col.b * (140/255);
	end
	nvgFillColor(playerscol);
	nvgText(x + ui2DrawServerHeaders["Players"].x, y+h/2, playerstext);
	
	nvgFillColor(GetPingColor(server.ping, col));
	nvgText(x + ui2DrawServerHeaders["Ping"].x, y+h/2, server.ping);

	-- record server we're hovering over so we can later draw player list
	if m.hoverAmount > 0 then
		if Menu.serverMouseOver == nil or m.hoverAmount > Menu.serverMouseOver.m.hoverAmount then
			Menu.serverMouseOver = {};
			Menu.serverMouseOver.m = m;
			Menu.serverMouseOver.address = server.address;
			Menu.serverMouseOver.protocolVersion = server.protocolVersion;
			Menu.serverMouseOverMutators = server.mutators;
		end
	end

	return m.leftUp;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawQuickPlayItem(name, players, selected, mmr, mmrBest, x, y, w, optargs)
	local optargs = optargs or {};
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local ix = x + 10;
	local h = 35;
	local iconSize = 30;
	local iconPad = 4;
	local iconTop = y + h/2-25;

	optargs.optionalId = y;

	nvgSave();

	local m = {};
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
		m.hoverAmount = 0;
	else
		m = mouseRegion(x, y, w, h, y);
	end

	-- bg
	local coltype = isSelected and UI2_COLTYPE_BUTTON_BLACK_SELECTED or UI2_COLTYPE_BUTTON_BLACK;
	local col = ui2FormatColor(coltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x+h+5, y, w-h-5, h);
	nvgFillColor(col);
	nvgFill();
	nvgBeginPath();
	nvgRect(x, y, h, h);
	nvgFillColor(col);
	nvgFill();

	-- icon
	local iconCol = Color(232,232,0)
	local iconRad = 10;
	if selected then
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled, m.leftHeld));
		nvgSvg("internal/ui/icons/checkBoxTick", ix + iconRad-3, y + h/2+1, iconRad-2);
	end
	ix = ix + iconRad*2+10;

	-- name
	ui2FontNormal();
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, selected and intensity or intensity * 0.5, m.hoverAmount, enabled, m.leftHeld));
	nvgText(ix+10, y+h/2, name);

	-- status text
	local status = players;
	local ix = x + w - 10;
	local iy = y + h/2;
	ui2FontSmall();
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREY, intensity, m.hoverAmount, enabled, m.leftHeld));
	nvgText(ix, y+h/2, players);
	
	-- tack on mmr
	if mmr ~= nil then
		local rw = 120;
		local rp = 8;

		local bgcol = col
		local text = nil
		local icon = nil

		if mmr ~= 0 then
			local r = getRatingInfo(mmr, mmrBest)
			r.name = string.upper(r.name)

			mmrcol = {}
			mmrcol.r = r.col.r + m.hoverAmount * 30
			mmrcol.g = r.col.g + m.hoverAmount * 30
			mmrcol.b = r.col.b + m.hoverAmount * 30
			mmrcol.a = col.a
			bgcol = Color(mmrcol.r, mmrcol.g, mmrcol.b, mmrcol.a * .5)

			local toffset = 22 + 20 * r.iconScale
			local ioffset = 25 + 10 * r.iconScale

			ui2FontSmall();
			nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
			local fw = nvgTextWidth(r.name)
			local rw = toffset + fw

			nvgBeginPath();
			nvgRect(x+w, y+5, rp + rw, h-5);
			nvgFillColor(bgcol);
			--nvgFillLinearGradient(x+w, y, x+w+rp, y, col, Color(172, 107, 46,col.a))
			--nvgFillLinearGradient(x+w, y, x+w+rp, y, col, Color(200, 172, 75,col.a))
			--nvgFillLinearGradient(x+w, y, x+w+rp, y, col, Color(col.r+60,col.g+60,col.b+60,col.a))
			nvgFillLinearGradient(x+w, y, x+w+rp, y, col, bgcol)
			nvgFill();

			nvgBeginPath()
			nvgMoveTo(x+w+rp, y+h-2)
			nvgLineTo(x+w+rp+rw*r.percentage, y+h-2)
			nvgStrokeColor(mmrcol)
			nvgStrokeWidth(2)
			nvgStroke()

			--ui2FontSmall();
			--nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
			--nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity * .5, m.hoverAmount, enabled, m.leftHeld));
			--nvgText(x+w+rp + rw/2, y+h/2+2, "MMR " .. rank);
		
			nvgFillColor(mmrcol);
			nvgText(x+w+rp + toffset-9, y+h/2+2, r.name);
		
			--nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled, m.leftHeld));
			nvgSvg(r.icon, ix + ioffset, y + h/2+1, 10 * r.iconScale);
		end
	end

	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick");
		selected = not selected;
	end

	return selected;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2RegionsButton(regions, x, y, w, h, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local col = optargs.color or Color(0,0,0,0);
	local bgcoltype = optargs.bgcoltype == nil and UI2_COLTYPE_BUTTON or optargs.bgcoltype;

	local cornerRadius = 5.0;
	local tw = 0;
	local iw = 0;

	local m = {};
	if enabled == false then 
		m.leftHeld = false;
		m.mouseInside = false;
		m.leftUp = false;
		m.hoverAmount = 0;
		col = Color(
			col.r * 0.5,
			col.g * 0.5,
			col.b * 0.5,
			col.a);
	else
		m = mouseRegion(x, y, w, h, optionalId);
	end

	nvgSave();
	
	-- bg
	local col = ui2FormatColor(bgcoltype, intensity, m.hoverAmount, enabled, m.leftHeld);
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(col);
	nvgFill();
	
	nvgIntersectScissor(x, y, w - 5, h);

	local ix = x+7;
	local iy = y+h/2;
	local iconRad = 12;
	ui2FontNormal();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);

	if regions == "" then
		-- name
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, m.hoverAmount, enabled));
		nvgText(ix, iy, "Auto-Select");
	else
		-- iterate regions
		local upperCaseRegions = string.upper(regions);

        for regionKey in string.gmatch(upperCaseRegions, "[A-Za-z0-9%.%%%+%-]+") do
			local iconName = nil
			local name = nil

			for k, v in ipairs(matchmaking.regions) do
				if string.upper(v.key) == regionKey then
					iconName = "internal/ui/icons/flags/"..v.flag
					name = v.name
					break
				end
			end

			if name ~= nil and iconName ~= nil then
				-- icon
				nvgSvg(iconName, ix + iconRad, iy, iconRad-2);
				ix = ix + iconRad*2+4;
				
				-- name
				nvgText(ix, iy, name);
				ix = ix + nvgTextWidth(name) + 12;
			end
        end
	end
	
	nvgRestore();

	if m.leftUp then
		playSound("internal/ui/sounds/buttonClick");
	end

	return m.leftUp, m.hoverAmount;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local _quickplay_dot_timer = 0
local _lastMMState = nil
function Menu:updateMMStatusText()
	-- only update on MM status change, or when it's active
	if (matchmaking.state ~= MATCHMAKING_DISABLED) or (matchmaking.state ~= _lastMMState) then

		local status = ""
		if matchmaking.state == MATCHMAKING_DISABLED then
			status = matchmaking.findLobbyError;
			if matchmaking.canContinueGame then
				status = "You have a competitive game in progress! Matchmaking will return you to your match"
			end
		elseif matchmaking.state == MATCHMAKING_PINGINGREGIONS then
			status = "Detecting Region(s).";
		elseif matchmaking.state == MATCHMAKING_REQUESTINGLOBBYSERVER then
			status = "Finding Lobby Server.";
		elseif matchmaking.state == MATCHMAKING_ENABLED_BUT_IDLE and gameActive then
			status = "Game Active.";
		elseif matchmaking.state == MATCHMAKING_ENABLED_BUT_IDLE and world.matchmakingPlayerCount == 0 then
			status = "Connecting.";
		elseif matchmaking.state == MATCHMAKING_SEARCHINGFOROPPONENTS then
			status = "Searching For Opponents.";
		elseif matchmaking.state == MATCHMAKING_VOTINGMAP then
			status = "Performing Map Selection.";
		elseif matchmaking.state == MATCHMAKING_VOTEFINISHED then
			status = "Map Selection Complete.";
		elseif matchmaking.state == MATCHMAKING_FINDINGSERVER then
			status = "Preparing Server.";
		elseif matchmaking.state == MATCHMAKING_LOSTCONNECTIONATTEMPTINGRECONNECT then
			status = "Lost Connection, Attemping to reconnect.";
		elseif matchmaking.state == MATCHMAKING_BANNED then
			status = string.format("Waiting ~%d minutes due to abandoning recent matches.", matchmaking.bannedMinutes);
		end

		if matchmaking.state ~= MATCHMAKING_DISABLED and string.len(status) > 0 then
			_quickplay_dot_timer = _quickplay_dot_timer + deltaTimeRaw*3
			if _quickplay_dot_timer > 1 then status = status .. "." end
			if _quickplay_dot_timer > 2 then status = status .. "." end
			if _quickplay_dot_timer > 3 then _quickplay_dot_timer = 0 end
		end

		if not connectedToSteam then
			status = "(No Steam connection found, Matchmaking unavailable)"
		end	

		_lastMMState = matchmaking.state;
		self.mmStatusText = status;
		if status ~= "" then
			self.mmStatusTextNotEmpty = status;
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawQuickPlay(intensity)
	local optargs = {
		intensity = intensity,
		enabled = connectedToSteam
		--enabled = matchmaking.state ~= MATCHMAKING_REQUESTINGLOBBYSERVER and matchmaking.state ~= MATCHMAKING_PINGINGREGIONS and connectedToSteam
	};

	-- is this screen is controlled by party leader
	local controlledByPartyLeader = party.memberCount > 1 and not party.isOwner
	if controlledByPartyLeader then
		optargs.enabled = false
	end
	
	nvgSave();
	
	-- s1 == current settings
	local s1 = {};
	s1.cl_mm_playlists			= consoleGetVariable("cl_mm_playlists");
	s1.cl_mm_regions			= consoleGetVariable("cl_mm_regions");
	s1.cl_mm_turbo				= consoleGetVariable("cl_mm_turbo");
	s1.cl_mm_lobby				= consoleGetVariable("cl_mm_lobby");
	s1.cl_mm_proving_grounds	= consoleGetVariable("cl_mm_proving_grounds");

	-- if we're in a party, above settings come from party leader
	if controlledByPartyLeader then
		s1.cl_mm_playlists	= party.playlists
		s1.cl_mm_regions	= party.regions
		s1.cl_mm_turbo		= party.turboQueue
		s1.cl_mm_lobby		= party.joinLobby
	end
	
	-- s2 = new settings
	local s2 = {};
	s2.cl_mm_playlists = ""

	local lowerCaseSearch = string.lower(s1.cl_mm_playlists)

	local function FormatPlayers(playlist)
		local ret = ""
		if playlist.minPlayers ~= playlist.maxPlayers then
			ret = "up to "
		end

		if playlist.teams then
			return ret .. playlist.maxPlayers/2 .. "v" .. playlist.maxPlayers/2
		else
			return ret .. playlist.maxPlayers
		end
	end

	-- COL 1
	local selectedValidKey = false;
	local colWidth = 650;
	local colIndent = 250;
	local x = -620;
	local y = -250;
	ui2Label("Casual", x, y, optargs);
	for k, v in ipairs(matchmaking.playlists) do
		if not v.competitive then
		
			local tooBig = party.memberCount > v.maxPartySize
			if tooBig then
				optargs.enabled = false
				optargs.hoverText = "Party too big"
			end
			if controlledByPartyLeader then
				optargs.enabled = false
				optargs.hoverText = "Party leader has control"
			end
			if v.provingGrounds ~= true and s1.cl_mm_proving_grounds == 1 then
				optargs.enabled = false
				optargs.hoverText = "Doesn't support Proving Grounds"
			end

			local selected = isWordFoundInString(v.key, lowerCaseSearch) and optargs.enabled
			local players = FormatPlayers(v)
			v.selected = ui2DrawQuickPlayItem(v.name, players, selected, nil, nil, x + colIndent, y, colWidth - colIndent, optargs);
			y = y + 40;	
			if v.selected and not tooBig then	-- if too big, take out of selection
				selectedValidKey = true;
				if string.len(s2.cl_mm_playlists) > 0 then
					s2.cl_mm_playlists = s2.cl_mm_playlists .. " "
				end
				s2.cl_mm_playlists = s2.cl_mm_playlists .. v.key
			end

			optargs.enabled = connectedToSteam
			optargs.hoverText = nil
		end
	end
	y = y + 60;	
	
	-- check we're level 15
	local playerIsLeveledForCompetitive = false
	if steamUserStats[steamId] ~= nil and connectedToSteam then
		experience = steamUserStats[steamId].experience;
		local experienceVars = GetExperienceVars(experience);
		playerIsLeveledForCompetitive = experienceVars.level >= 15
	end

	optargs.enabled = playerIsLeveledForCompetitive
	ui2Label("Competitive", x, y, optargs);
	for k, v in ipairs(matchmaking.playlists) do
		if v.competitive then

			local tooBig = party.memberCount > v.maxPartySize
			if tooBig then
				optargs.enabled = false
				optargs.hoverText = "Party too big"
			end
			if controlledByPartyLeader then
				optargs.enabled = false
				optargs.hoverText = "Party leader has control"
			end
			if v.provingGrounds ~= true and s1.cl_mm_proving_grounds == 1 then
				optargs.enabled = false
				optargs.hoverText = "Doesn't support Proving Grounds"
			end

			local selected = isWordFoundInString(v.key, lowerCaseSearch) and optargs.enabled
			local players = FormatPlayers(v)
			local mmr = v.mmr
			local mmrBest = v.mmrBest
			if not playerIsLeveledForCompetitive then
				mmr = nil
				mmrBest = nil
			end
			v.selected = ui2DrawQuickPlayItem(v.name, players, selected, mmr, mmrBest, x + colIndent, y, colWidth - colIndent, optargs);
			if not playerIsLeveledForCompetitive then
				v.selected = false
			end
			y = y + 40;	
			if v.selected and not tooBig then	-- if too big, take out of selection
				selectedValidKey = true;
				if string.len(s2.cl_mm_playlists) > 0 then
					s2.cl_mm_playlists = s2.cl_mm_playlists .. " "
				end
				s2.cl_mm_playlists = s2.cl_mm_playlists .. v.key
			end

			optargs.enabled = playerIsLeveledForCompetitive
			optargs.hoverText = nil
		end
	end
	optargs.enabled = connectedToSteam
	
	-- no competitive MM list
	if not playerIsLeveledForCompetitive then
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*1, hoverAmount, enabled));
		nvgSvg("internal/ui/awards/lockdown", x + colIndent + (colWidth - colIndent) * .5, y - 60, 70*.75);
		ui2Tooltip("Competitive matchmaking is unlocked at level 15", x + colWidth, y - 80, optargs);
	end

	-- turbo tuesday
	local turboNow = turboTime.known
	if turboNow then
		local timeTillBonusStarts = turboTime.epochTimeStart - epochTime
		local timeTillBonusEnds = turboTime.epochTimeEnd - epochTime
		turboNow = timeTillBonusStarts < 0 and timeTillBonusEnds > 0
	end
	local bonusx = x+180;
	local bonusy = y-65;
	local bonusr = 44;
	if turboNow and true then
		nvgFillColor(Color(84, 193, 252, 255*intensity))
	else
		nvgFillColor(Color(128, 128, 128, 255 * intensity * .5));
	end
	if playerIsLeveledForCompetitive then
		nvgSvg("internal/ui/icons/turboTuesday", bonusx, bonusy, bonusr);
	end

	local competitivePoints = inventoryCompetitivePoints
	if playerIsLeveledForCompetitive then
		ui2FontSmall();
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.6, hoverAmount, enabled));
		nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP);
		local text = string.format("Competitive Points: %d", competitivePoints)
		nvgText(x + colWidth, y, text);
	end
	
	y = y + 60
	local boty = y;
	
	-- COL 2
	local x = 150;
	local y = -250;
	colWidth = 450;
	--colIndent = 150
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK
	optargs.halign = NVG_ALIGN_LEFT
	ui2Label("Regions", x, y, optargs);
	if ui2RegionsButton(s1.cl_mm_regions, x + colIndent, y, colWidth - colIndent, 35, optargs) then
		showAsPopup("RegionPicker");
	end
	optargs.bgcoltype = nil
	optargs.halign = nil
	y = y + 60;	

	s2.cl_mm_lobby = ui2CheckBox(s1.cl_mm_lobby ~= 0, x + colIndent, y, optargs) and 1 or 0;
	ui2Label("Join Lobby", x, y, optargs)
	ui2TooltipBox("Will place you in a lobby server to warmup while your match is found", x + 90, y, 300, optargs);
	y = y + 60

	s2.cl_mm_turbo = ui2CheckBox(s1.cl_mm_turbo ~= 0, x + colIndent, y, optargs) and 1 or 0;
	ui2Label("Turbo Queue", x, y, optargs)
	ui2TooltipBox("Will find you a match quicker by matching you with higher ranked opponents, use with care!", x + 114, y, 340, optargs);
	y = y + 60

	s2.cl_mm_proving_grounds = ui2CheckBox(s1.cl_mm_proving_grounds ~= 0, x + colIndent, y, optargs) and 1 or 0;
	ui2Label("Map Pool", x, y, optargs)
	local provingGrounds =
	{
		[0] = "Standard",
		[1] = "Proving Grounds",
		[2] = "Both"
	};
	local provingGroundsSelection = provingGrounds[s1.cl_mm_proving_grounds]
	local provingGroundsSelectionNew = ui2ComboBox(provingGrounds, provingGroundsSelection, x + colIndent, y, colWidth - colIndent, self.comboBoxDataProvingGrounds, optargs);
	for k, v in pairs(provingGrounds) do
		if v == provingGroundsSelectionNew then
			s2.cl_mm_proving_grounds = k;
		end
	end
	ui2TooltipBox("Toggles Proving Grounds map pool. Features new maps!", x + 84, y, 300, optargs);
	y = y + 60
	
	local gameActive = matchmaking.state == MATCHMAKING_ENABLED_BUT_IDLE and world.matchmakingPlayerCount > 0
	
	if controlledByPartyLeader then
		optargs.hoverText = "Party leader has control"
	end
	if matchmaking.state > MATCHMAKING_DISABLED then
		optargs.enabled = not gameActive and not controlledByPartyLeader;
		if ui2Button("Cancel", -620 + 650 - 360, boty, 360, 35, optargs) then		
			consolePerformCommand("cl_mm_stop");
		end
	else
		optargs.enabled = selectedValidKey and optargs.enabled and not controlledByPartyLeader;
		if isGameBorrowed then
			optargs.enabled = false
			optargs.hoverText = "Matchmaking is not supported in shared copies of Reflex Arena";
		end

		local text = "Start"
		if s2.cl_mm_proving_grounds ~= 0 then
			text = "Start: Proving Grounds"
		end
		if ui2Button(text, -620 + 650 - 360, boty, 360, 35, optargs) then		
			consolePerformCommand("cl_mm_start");
		end
	end
	optargs.enabled = connectedToSteam;
	optargs.hoverText = nil;

	-- status
	ui2FontSmall();
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREY, intensity, 1, true));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(-620 + 650 - 360, boty + 55, self.mmStatusText);
	
	nvgRestore();

	-- apply new settings (if anything has changed)
	if not controlledByPartyLeader then
		applySettingsTable(s2, s1);
	end

	-- bonus xp hover
	local m = mouseRegion(bonusx - bonusr, bonusy - bonusr, bonusr*2, bonusr*2);
	if turboTime.known and m.hoverAmount > 0.5 then

		local bonusStarts = turboTime.epochTimeStart
		local bonusEnds = turboTime.epochTimeEnd

		local delta = bonusStarts - epochTime;
		local turboActive = false
		if delta < 0 then
			turboActive = true
			delta = bonusEnds - epochTime;
		end
		
		local rem = delta;
		local seconds = rem % 60;
		rem = rem - seconds;
		rem = rem / 60;

		local minutes = rem % 60;
		rem = rem - minutes;
		rem = rem / 60;

		local hours = rem % 24;
		rem = rem - hours;
		rem = rem / 24;

		local days = rem;

		local textTime = ""
		if days > 0 then
			textTime = string.format("%d days", days)
		end
		if hours > 0 then
			if string.len(textTime) > 0 then
				textTime = textTime .. ", "
			end
			textTime = textTime .. string.format("%d hours", hours)
		end
		if minutes > 0 then
			if string.len(textTime) > 0 then
				textTime = textTime .. ", "
			end
			textTime = textTime .. string.format("%d minutes", minutes)
		end
		
		local text1 = "Awards 2x Competitive points!";
		local text2 = "Starts in: " .. textTime;
		if turboActive then
			text2 = "Expires in: " .. textTime;
		end
		
		nvgSave();
		ui2FontNormal();
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgTextLineHeight(.8);

		local w1 = nvgTextWidth(text1);
		local w2 = nvgTextWidth(text2);
		local h = (string.len(text2) > 0) and 62 or 36;
		
		-- bg
		local mx = Menu.mouseX + 5;
		local my = Menu.mouseY + 5;
		local col = Color(55, 55, 55, 255*intensity);
		local w = math.max(w1, w2)+14;
		nvgBeginPath();
		nvgRoundedRect(mx, my, w, h, 3);
		nvgFillColor(col);
		nvgFill();
		
		-- text
		local iy = my + 37;
		local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity * .9, 1, enabled);
		local ix = mx + 7;
		nvgFillColor(col);
		nvgText(ix, iy-20, text1);
		ix = ix + nvgTextWidth(text1);
		
		local ix = mx + 7;
		local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity * .5, 1, enabled);
		nvgFillColor(col);
		nvgText(ix, iy+7, text2);
		ix = ix + nvgTextWidth(text2);
		nvgRestore();
	end
end

--------------------------------------------------------------------------------
-- draw little icon next to "Play" on the main menu
--------------------------------------------------------------------------------
function Menu:ui2DrawMenuBarHoveringMatchmakingStatus(menuBarY)
	nvgSave()

	-- fade in/out
	if matchmaking.state ~= MATCHMAKING_DISABLED and matchmaking.state ~= MATCHMAKING_PINGINGREGIONS and matchmaking.state ~= MATCHMAKING_ENABLED_BUT_IDLE then
		self.quickplayMmIntensity = math.min(1, self.quickplayMmIntensity + deltaTimeRaw*4)
	else
		self.quickplayMmIntensity = math.max(0, self.quickplayMmIntensity - deltaTimeRaw*2)
	end

	if self.quickplayMmIntensity > 0 then
		nvgFontSize(32);
		nvgFontFace(FONT_TEXT2);

		-- get width from text without trailing dots so we don't bounce about
		local statusNoDots = string.gsub(self.mmStatusTextNotEmpty, "%.", "")
		local iconWidth = 16
		local width = iconWidth + nvgTextWidth(statusNoDots)

		local ix = -width/2
		local iy = menuBarY + 135;

		local c = ui2FormatColor(UI2_COLTYPE_TEXT_GREY, self.quickplayMmIntensity, 0, true, false)
		
		nvgSave()
		nvgTranslate(ix, iy+1)
		nvgScale(0.5, 0.5)
		uiDrawMatchmakingIcon(0, 0, c)
		nvgRestore()
		
		nvgFillColor(c)
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgText(ix+iconWidth, iy, self.mmStatusTextNotEmpty);
	end

	nvgRestore()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawFindServer(intensity)
	local optargs = {
		intensity = intensity
	};

	nvgSave();

	local x = -620;
	local y = -250;
	
	-- top
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = connectedToSteam;
	if ui2Button("Refresh", x, y, 160, 35, optargs) then
		serverListRefresh();	
	end
	optargs.bgcoltype = nil;

	if not connectedToSteam then
		ui2Label("(No Steam connection found, browser unavailable)", x + 180, y, optargs);
	end

	optargs.enabled = nil;

	local showMM = widgetGetConsoleVariable("show_server_mm") ~= 0;
	local showOld = widgetGetConsoleVariable("show_server_old") ~= 0;
	local showEmpty = widgetGetConsoleVariable("show_server_empty") ~= 0;
	local showLocked = widgetGetConsoleVariable("show_server_locked") ~= 0;

	ui2FontNormal()
	local ix = 620

	local showMMNew = ui2CheckBox(showMM, ix - 35, y, optargs);
	ix = ix - 35 - nvgTextWidth("Show MatchMaking") - 10
	ui2Label("Show MatchMaking", ix, y, optargs);
	ix = ix - 30
	
	local showEmptyNew = ui2CheckBox(showEmpty, ix - 35, y, optargs);
	ix = ix - 35 - nvgTextWidth("Show Empty") - 10
	ui2Label("Show Empty", ix, y, optargs);
	ix = ix - 30
	
	local showLockedNew = ui2CheckBox(showLocked, ix - 35, y, optargs);
	ix = ix - 35 - nvgTextWidth("Show Locked") - 10
	ui2Label("Show Locked", ix, y, optargs);
	ix = ix - 30
	
	local showOldNew = ui2CheckBox(showOld, ix - 35, y, optargs);
	ix = ix - 35 - nvgTextWidth("Show Old") - 10
	ui2Label("Show Old", ix, y, optargs);
	ix = ix - 30
	
	if showMMNew ~= showMM then
		widgetSetConsoleVariable("show_server_mm", showMMNew and 1 or 0);
	end
	if showEmptyNew ~= showEmpty then
		widgetSetConsoleVariable("show_server_empty", showEmptyNew and 1 or 0);
	end
	if showLockedNew ~= showLocked then
		widgetSetConsoleVariable("show_server_locked", showLockedNew and 1 or 0);
	end
	if showOldNew ~= showOld then
		widgetSetConsoleVariable("show_server_old", showOldNew and 1 or 0);
	end
	
	y = y + 60;
	
	-- draw headers
	for k, v in pairs(ui2DrawServerHeaders) do
		local tw = 0;

		if v.drawHeader ~= false then
			tw = ui2Label(k, x + v.x, y, optargs);
		end

		if v.sort ~= nil then
			optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
			optargs.icon = self.selected_server_col == k and "internal/ui/icons/comboBoxArrow" or "internal/ui/icons/buttonRightArrow";
			optargs.iconSize = 6;
			optargs.optionalId = v.x;

			if ui2Button("", x +  v.x + tw, y+5, 25, 25, optargs) then
				self.selected_server_col = k;
			end

			optargs.bgcoltype = nil;
			optargs.icon = nil;
			optargs.iconSize = nil;
			optargs.optionalId = nil;			
		end
	end
	y = y + 40;

	-- filter
	-- todo: should we send these filters to steam query rather than doing it ourself?
	local filteredServers = {};
	local filteredServerCount = 0;
	if servers ~= nil then
		for k, server in pairs(servers) do
			local filter = false;

			if not showEmpty and server.playerCount == 0 then
				filter = true;
			end

			-- if not showFull and server.playerCount == server.playerCountMax then
			-- 	filter = true;
			-- end

			if not showMM and server.mm then
				filter = true;
			end

			if not showLocked and server.password then
				filter = true;
			end

			-- filter all old ones
			if not showOld and server.protocolVersion ~= protocolVersion then
				filter = true;
			end

			if not filter then
				filteredServerCount = filteredServerCount + 1;
				filteredServers[filteredServerCount] = server;
			end
		end
	end

	-- sort
	if self.selected_server_col ~= nil then
		local sortFunc = ui2DrawServerHeaders[self.selected_server_col].sort;
		if sortFunc ~= nil and table.getn(filteredServers) > 1 then
			table.sort(filteredServers, sortFunc);
		end
	end

	-- find server by address (if we do this rather than by table key, we don't lose server selection when server list still loading)
	local selectedServer = nil;
	for k, v in pairs(filteredServers) do
		if v.address == self.selected_server_address then
			selectedServer = v;
		end
	end

	-- 
	local mouseOverOldAddress = nil;
	if self.serverMouseOver ~= nil then
		mouseOverOldAddress = self.serverMouseOver.address;
	end

	-- draw servers
	self.serverMouseOver = nil;
	optargs.itemHeight = ui2DrawServerHeight;
	optargs.itemDrawFunction = ui2DrawServer;
	optargs.itemPad = 5;
	local newSelectedServer = ui2ScrollSelection(
		filteredServers, selectedServer, x, y, 1240, 500, self.scrollBarDataServerBrowser, optargs);
	y = y + 535;

	if newSelectedServer ~= nil then
		self.selected_server_address = newSelectedServer.address;
	end

	-- connect button (under player list)
	optargs.enabled = selectedServer ~= nil and selectedServer.protocolVersion == protocolVersion;
	if optargs.enabled and party.memberCount > 1 then
		optargs.enabled = false
		optargs.hoverText = "In party, use Quickplay to start match"
	end
	if ui2Button("Connect", 620-260, y, 260, 35, optargs) then
		if selectedServer.password then
			showAsPopup("Connect", selectedServer.name, selectedServer.address);
		else
			consolePerformCommand("connect "..self.selected_server_address);
		end
	end
	optargs.enabled = nil;
	optargs.hoverText = nil;

	-- fade up/down player list
	if self.serverMouseOverIntensity == nil then
		self.serverMouseOverIntensity = 0;
	end
	if self.serverMouseOver ~= nil then
		-- new server? start query
		if mouseOverOldAddress ~= self.serverMouseOver.address then
			serverQueryPlayerList(self.serverMouseOver.address);
			serverQueryRuleList(self.serverMouseOver.address);
		end
		
		-- fade up
		self.serverMouseOverIntensity = math.min(1, self.serverMouseOverIntensity + deltaTimeRaw*4);
	else
		-- fade down
		self.serverMouseOverIntensity = math.max(self.serverMouseOverIntensity - deltaTimeRaw*4, 0);		
	end

	-- draw mouse over popup
	if self.serverMouseOverIntensity > 0 then
		local intensity = self.serverMouseOverIntensity;
		
		-- test if old
		local isOld = false;
		if ((self.serverMouseOver == nil) and self.serverMouseOverWasIncompatible) or
			(self.serverMouseOver ~= nil and self.serverMouseOver.protocolVersion ~= protocolVersion) then
			self.serverMouseOverWasIncompatible = true;
			isOld = true;
		else
			self.serverMouseOverWasIncompatible = false;
		end

		-- count players
		local playerStatus = nil;
		local playerCount = 0;
		for k, v in pairs(serverPlayers) do
			playerCount = playerCount + 1;
		end
		if playerCount == 0 then
			local b = serverIsQueryingPlayerList();
			if b then
				playerStatus = "Querying Server..";
				playerCount = 1;
			else
				playerStatus = "(Server Empty)";
				playerCount = 1;
			end
		end

		-- count mutators
		local mutatorCount = 0;
		local upperCaseMutators = ""
		if (self.serverMouseOverMutators ~= nil) then
			upperCaseMutators = string.upper(self.serverMouseOverMutators);
		end
		for k, v in pairs(mutatorDefinitions) do
			if string.find(upperCaseMutators, k) ~= nil then
				mutatorCount = mutatorCount + 1;
			end
		end
		if mutatorCount > 0 then
			mutatorCount = mutatorCount + 1.5;	-- spacer + title
		end

		-- count rules
		local ruleCount = 0;
		for k, v in pairs(serverRules) do
			ruleCount = ruleCount + 1;
		end
		if ruleCount > 0 then
			ruleCount = ruleCount + 1.5;	-- spacer + title
		end

		local lineCount = 1 + playerCount + mutatorCount + ruleCount;
		if isOld then
			lineCount = 1;
		end

		-- bg
		local mx = self.mouseX + 5;
		local my = self.mouseY + 5;
		local col = Color(45, 45, 45, 255*intensity);
		nvgBeginPath();
		nvgRoundedRect(mx, my, 426, 20*lineCount+12, 3);
		nvgFillColor(col);
		nvgFill();
		
		local iy = my + 15;
		local col = ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 1, enabled);
		ui2FontSmall();
		nvgFillColor(col);
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);

		if isOld then
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, 1, enabled));
			nvgText(mx + 10, iy, "Error: Incompatible server version");			
		else
			nvgText(mx + 10, iy, "Players:");
			iy = iy + 20;
		
			-- draw player list
			if playerStatus ~= nil then
				-- draw status
				nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, 0.5*intensity, 1, enabled));
				nvgText(mx + 10, iy, playerStatus);
				iy = iy + 20;
			else
				-- draw players..
				for k, v in pairs(serverPlayers) do

					-- name
					local colName = Color(255,255,255, 255*intensity);
					colName.r = col.r * .6;
					colName.g = col.g * .6;
					colName.b = col.b * 1;
					colName.a = col.a;
					nvgSave();
					nvgIntersectScissor(mx + 10, iy-10, 180, 40);
					nvgFillColor(colName);
					nvgText(mx + 10, iy, v.name);
					nvgRestore();

					-- score
					if v.score ~= nil then
						nvgFillColor(col);
						nvgText(mx + 200, iy, v.score);
					end

					-- time
					if v.timePlayed ~= nil then
						local time = FormatTime(v.timePlayed * 1000);
						local timeText = "";
						if time.minutes == 1 then
							timeText = time.minutes .. "min ";
						elseif time.minutes > 0 then
							timeText = time.minutes .. "mins ";
						end
						if time.seconds == 1 then
							timeText = timeText .. time.seconds .. "sec ";
						elseif time.seconds > 0 then
							timeText = timeText .. time.seconds .. "secs ";
						end
						local colTime = Color(255,255,255);
						colTime.r = col.r * .6;
						colTime.g = col.g * 1;
						colTime.b = col.b * .6;
						colTime.a = col.a;
						nvgFillColor(colTime);
						nvgText(mx + 300, iy, timeText);
					end

					iy = iy + 20;
				end
			end

			if mutatorCount > 0 then
				iy = iy + 20 * .5; -- half line spacer
		
				nvgFillColor(col);
				nvgText(mx + 10, iy, "Mutators:");
				iy = iy + 20;
			
				for k, v in pairs(mutatorDefinitions) do
					if string.find(upperCaseMutators, k) ~= nil then
						local ix = mx + 10;
						local iconRad = 10;

						-- icon
						local iconCol = v.col;
						nvgFillColor(Color(iconCol.r, iconCol.g, iconCol.b, col.a));
						nvgSvg(v.icon, ix + iconRad, iy, iconRad-2);
						ix = ix + iconRad*2+4;
			
						-- name
						local text = FirstToUpper(string.lower(k));
						nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, 1, enabled));
						nvgText(ix, iy, text, NULL);
						iy = iy + 20;
					end
				end
			end

			if ruleCount > 0 then
				iy = iy + 20 * .5; -- half line spacer
		
				nvgFillColor(col);
				nvgText(mx + 10, iy, "Server:");
				iy = iy + 20;
			
				for k, v in pairs(serverRules) do
					nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5, 1, enabled));
					nvgText(mx+10, iy, k, NULL);

					nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, 1, enabled));
					nvgText(mx+200, iy, v, NULL);

					iy = iy + 20;
				end
			end
		end
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:ui2DrawPlayCreateServer(intensity)
	local optargs = {
		intensity = intensity
	};
	
	nvgSave();
	
	-- s1 == current settings
	local s1 = {};
	s1.sv_hostname					= consoleGetVariable("sv_hostname");
	s1.sv_maxclients				= consoleGetVariable("sv_maxclients");
	s1.sv_steam						= consoleGetVariable("sv_steam");
	s1.sv_allowedit					= consoleGetVariable("sv_allowedit");
	s1.sv_password					= consoleGetVariable("sv_password");
	s1.sv_startmode					= consoleGetVariable("sv_startmode");
	s1.sv_startmap					= consoleGetVariable("sv_startmap");
	s1.sv_startwmap					= consoleGetVariable("sv_startwmap");
	s1.sv_startmutators				= consoleGetVariable("sv_startmutators");
	s1.sv_gameport					= consoleGetVariable("sv_gameport");
	s1.ui_menu_startbot1			= consoleGetVariable("ui_menu_startbot1");
	s1.ui_menu_startbot2			= consoleGetVariable("ui_menu_startbot2");
	s1.ui_menu_startbot3			= consoleGetVariable("ui_menu_startbot3");
	s1.ui_menu_startbot4			= consoleGetVariable("ui_menu_startbot4");
	s1.ui_menu_startbot5			= consoleGetVariable("ui_menu_startbot5");
	s1.ui_menu_startbot6			= consoleGetVariable("ui_menu_startbot6");
	s1.ui_menu_startbot7			= consoleGetVariable("ui_menu_startbot7");
	s1.ui_menu_startbot8			= consoleGetVariable("ui_menu_startbot8");
	
	-- s2 = new settings
	local s2 = {};
	
	-- COL 1
	local colWidth = 650;
	local colIndent = 250;
	local x = -620;
	local y = -250;
	ui2Label("Hostname", x, y, optargs);
	s2.sv_hostname = ui2EditBox(s1.sv_hostname, x + colIndent, y, colWidth - colIndent, optargs);
	y = y + 60;	
	
	-- prepare some mode arrays
	local modeNames = {};
	local modeShortNames = {};
	local i = 1;
	for k, v in pairs(gamemodes) do
		modeNames[i] = v.name;
		modeShortNames[i] = v.shortName;
		i = i + 1;
	end

	-- find current gamemode
	local gamemode = nil
	for k, v in pairs(gamemodes) do
		if s1.sv_startmode == v.shortName then
			gamemode = v
			break
		end
	end
	local gamemodeHasTeams = gamemode ~= nil and gamemode.hasTeams or false

	-- find hasNav
	local hasNav = false
	if s1.sv_steam == 0 then
		-- local maps
		local lowerStartMap = string.lower(s1.sv_startmap)
		for k, v in pairs(maps) do
			if string.lower(v.mapName) == lowerStartMap then
				hasNav = v.hasNav;
				break;
			end
		end
	else
		-- workshop maps
		for k, v in pairs(workshopMaps) do
			if s1.sv_startwmap == v.id then
				hasNav = v.hasNav;
				break;
			end
		end
	end
	
	ui2Label("Match Type", x, y, optargs);
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2MatchButton(s1.sv_steam ~= 0, s1.sv_startmap, s1.sv_startwmap, s1.sv_startmode, x + colIndent, y, colWidth - colIndent, 95, optargs) then
		showAsPopup("MatchPicker", s1.sv_startmap, s1.sv_startwmap, s1.sv_startmode);
	end
	optargs.bgcoltype = nil;
	y = y + 120;

	ui2Label("Mutators", x, y, optargs);
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2MutatorButton(s1.sv_startmutators, x + colIndent, y, colWidth - colIndent, 35, optargs) then
		showAsPopup("MutatorPicker", s1.sv_startmutators);
	end
	optargs.bgcoltype = nil;
	y = y + 60;

	ui2Label("Password", x, y, optargs);
	s2.sv_password = ui2EditBox(s1.sv_password, x + colIndent, y, colWidth - colIndent, optargs);
	y = y + 60;
	
	ui2Label("Max Clients", x, y, optargs);
	s2.sv_maxclients = ui2EditBox0Decimals(s1.sv_maxclients, x+colIndent+330, y, colWidth - colIndent-330, optargs);
	s2.sv_maxclients = math.floor(clamp(s2.sv_maxclients, 4, 16));
	local newSliderValue = ui2Slider(x+colIndent, y, 310, 4, 16, s2.sv_maxclients, optargs);
	if not isEqual(newSliderValue, s2.sv_maxclients) then
		newSliderValue = math.floor(tonumber(newSliderValue));
		if newSliderValue ~= nil then
			s2.sv_maxclients = newSliderValue;
		end
	end
	y = y + 60;	
	
	ui2Label("Bot Slots", x, y, optargs);
	if not hasNav then
		ui2TooltipBox("Only maps that have navigation information built support bots.", 
			x+colWidth, y, 260, optargs);
	end
	local maxSlotsToShow = math.min(s2.sv_maxclients-1, 8) -- -1 => leave 1 slot for local player!
	maxSlotsToShow = math.max(maxSlotsToShow, 0)
	if s1.sv_startmode == "1v1" then maxSlotsToShow = math.min(maxSlotsToShow, 2) end
	if s1.sv_startmode == "2v2" then maxSlotsToShow = math.min(maxSlotsToShow, 4) end
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK
	optargs.halign = NVG_ALIGN_LEFT
	optargs.enabled = hasNav;
	local hw = (colWidth - colIndent) / 2
	for s = 1, maxSlotsToShow do
		local isLeft = ((s-1) % 2 == 0)
		local teamIndexAsString = isLeft and "0" or "1"
		
		local botKey = "ui_menu_startbot"..s
		local botString = s1[botKey]
		local botSkill = nil
		local botTeam = nil
		local botName = nil
		local botText = nil
		
		-- read bot, if didn't parse correctly or assigned wrong time, nuke it
		botSkill, botTeam, botName = string.match(botString, "(%d+)%s(%d+)%s(%w+)")
		local wrongTeam = false
		if gamemodeHasTeams then
			wrongTeam = botTeam ~= teamIndexAsString
		end
		if botSkill == nil or botTeam == nil or botName == nil or wrongTeam or not hasNav then
			s2[botKey] = "none"
			botText = "(empty)"
		else
			botText = string.format("%s (%d)", botName, botSkill)
		end
		
		local ix = x + colIndent
		local iy = y;
		if not isLeft then 
			ix = ix + hw + 10 
			y = y + 50;
		end
		if gamemodeHasTeams then
			optargs.bgcoltype = isLeft and UI2_COLTYPE_BGTEAM_A or UI2_COLTYPE_BGTEAM_B
		end
		optargs.optionalId = s
		if ui2Button(botText, ix, iy, hw-10, 35, optargs) then
			showAsPopup("BotPicker", botKey, botString, tonumber(teamIndexAsString));
		end
	end
	if maxSlotsToShow % 2 == 1 then
		y = y + 50;
	end
	for s = maxSlotsToShow+1, 8 do
		s2["ui_menu_startbot"..s] = "none"
	end
	optargs.bgcoltype = nil;
	optargs.enabled = nil;
	optargs.halign = nil
	y = y + 10;	

	local col1endY = y;
	
	-- COL 2
	local x = 150;
	local y = -250;
	colWidth = 350;

	ui2Label("Steam Integration", x, y, optargs);
	if not connectedToSteam then
		optargs.enabled = false;
	end
	s2.sv_steam = ui2CheckBox(s1.sv_steam ~= 0, x+colIndent, y, optargs) and 1 or 0;
	if not connectedToSteam then
		s2.sv_steam = 0;
	end
	optargs.enabled = nil;
	ui2TooltipBox("This will add your server to the public server browser. It will also add Steam Inventory & Steam Workshop capabilites.", x+colIndent+35, y, 260, optargs);
	y = y + 60;

	ui2Label("Allow Edit", x, y, optargs);
	s2.sv_allowedit = ui2CheckBox(s1.sv_allowedit ~= 0, x+colIndent, y, optargs) and 1 or 0;
	y = y + 60;

	ui2Label("Game Port", x, y, optargs);
	s2.sv_gameport = ui2EditBox(s1.sv_gameport, x + colIndent, y, colWidth - colIndent, optargs);
	ui2TooltipBox("Be sure to forward this port in your router's settings.", x + colWidth, y, 200, optargs);
	y = y + 60;

	y = y + 60;

	optargs.enabled = party.memberCount <= 1
	if optargs.enabled == false then
		optargs.hoverText = "In party, use Quickplay to start match"
	else
		optargs.hoverText = nil
	end

	if ui2Button("Start", -620 + 650 - 300, col1endY, 300, 35, optargs) then
		-- disconnect first, so we force a server restart instead of just map change
		consolePerformCommand("disconnect");		
		if s1.sv_steam ~= 0 then
			consolePerformCommand("wmap " .. s1.sv_startwmap);
		else
			consolePerformCommand("map " .. s1.sv_startmap);
		end

		-- add bots
		for s = 1, 8 do
			local key  = "ui_menu_startbot"..s
			local value = s1[key]
			if string.len(value) > 0 and value ~= "none" then
				consolePerformCommand(string.format("sv_addbot %s", value))
			end
		end
		hideMenu();
	end

	nvgRestore();

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function goneToHomeMenu()
	local mmCanWatchOnly = true
	serverListRefresh(mmCanWatchOnly)	-- for watch tile
	matchmakingUpdateMmr()				-- for profile tile
end
local function goneToFindGame()
	matchmakingUpdateTurboTime()
	matchmakingUpdateMmr()
	matchmakingUpdateCanContinueGame()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function getReplayBrowserDataDir(dirs)
	local data = Menu.replayBrowserTable;

	for i,dir in ipairs(dirs) do
		data = data["folders"][dir];
	end

	return data;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function replayBrowserQueryPreviews()
	if connectedToSteam then
		workshopQuerySpecificMaps(getReplayBrowserDataDir(Menu.replayBrowserCursorDirs)["ids"]);
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function replayBrowserIndex()
	Menu.replayBrowserTable = getReplayBrowserTable();

	if (Menu.replayBrowserTable["folders"] == nil) then
		Menu.replayBrowserTable["folders"] = {};
	end

	if (Menu.replayBrowserTable["ids"] == nil) then
		Menu.replayBrowserTable["ids"] = {};
	end

	if (Menu.replayBrowserTable["replays"] == nil) then
		Menu.replayBrowserTable["replays"] = {};
	end

	if (Menu.replayBrowserTable["info"] == nil) then
		Menu.replayBrowserTable["info"] = {};
	end

	-- Query all maps
	replayBrowserQueryPreviews();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ui2DrawPartyMember(x, y, w, h, intensity, steamId)
	local enabled = 1

	local m = mouseRegion(x, y, w, h, x);

	if steamId ~= nil then
		local avatarIntensity = lerp(232, 255, m.hoverAmount) * intensity

		-- avatar
		nvgBeginPath();
		nvgRoundedRect(x, y, w, h, 3);
		nvgFillColor(Color(0,0,0, 0)); -- draw nothing if icon didn't load for some reason
		nvgFillImagePattern("$avatarMedium_"..steamId, x, y, w, h, 0, avatarIntensity);
		nvgFill();
		nvgStrokeWidth(2)
		--nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREY, intensity, m.hoverAmount, enabled, m.leftHeld));
		--nvgStroke();
	else
		nvgBeginPath();
		nvgRoundedRect(x, y, w, h, 3);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, m.hoverAmount, enabled, m.leftHeld));
		nvgFill();
		nvgStrokeColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREY, intensity*.5, m.hoverAmount, enabled, m.leftHeld));
		nvgStroke();
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREY, intensity*m.hoverAmount, m.hoverAmount, enabled, m.leftHeld));
		nvgSvg("internal/ui/icons/plus", x+w/2, y+w/2, 6)

		if m.leftUp then
			partyInvitePopup();
		end
	end
end
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local partyHistory = {}
local partyHistoryCount = 0
local partyHistoryLastReadId = -1
local function ui2DrawPartyChatHistory(x, y, w)
	local logCount = 0;
	for k, v in pairs(log) do
		logCount = logCount + 1;
	end

	-- read log events
	for i = 1, logCount do
		local logEntry = log[i];

		if partyHistoryLastReadId < logEntry.id then
			partyHistoryLastReadId = logEntry.id

			local text = nil;
			local col = nil;
			if logEntry.type == LOG_TYPE_CHATMESSAGE and logEntry.chatType == LOG_CHATTYPE_PARTY then
				text = logEntry.chatPlayer .. ": " .. logEntry.chatMessage;
				col = Color(127, 255, 50, 255);
			end
			if logEntry.type == LOG_TYPE_NOTIFICATION and logEntry.notificationType == LOG_NOTIFICATIONTYPE_PARTY then
				col = Color(200, 200, 200, 255);
				text = logEntry.notification;
			end

			if text ~= nil then
				-- rip out oldest one
				if partyHistoryCount >= 10 then
					for i = 1, partyHistoryCount-1 do
						partyHistory[i] = partyHistory[i+1]
					end
					partyHistoryCount = 9
				end

				-- add new one
				partyHistoryCount = partyHistoryCount + 1
				partyHistory[partyHistoryCount] = {}
				partyHistory[partyHistoryCount].col = col
				partyHistory[partyHistoryCount].text = text
			end
		end
	end

	-- history
	for i = partyHistoryCount, 1, -1 do
		local logEntry = partyHistory[i];

		local text = partyHistory[i].text;
		local col = partyHistory[i].col;

		local lines, lineCount = SplitTextToMultipleLines(text, w);
			
		for line = lineCount, 1, -1 do
			local lineText = lines[line];

			nvgFontBlur(0);
			nvgFillColor(col);
			nvgText(x, y, lineText);
				
			y = y - 25;
		end
	end
end
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local __cursorFlash = 0
local __entryOffsetX = 0
local function ui2DrawPartyChatInput(x, y, w, h, say, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity ~= nil and optargs.intensity or 1
	local enabled = optargs.enabled ~= nil and optargs.enabled or true
	local cursorFlashPeriod = 0.25;

	-- look up steam name, use that for chat (as that's what others see)
	-- local steamMe = steamFriends ~= nil and steamFriends[steamId] or nil
	-- local steamName = steamMe ~= nil and steamMe.personaName or consoleGetVariable("name");
	local steamName = ""
	
	-- if cursor moves, restart flash
	__cursorFlash = __cursorFlash + deltaTimeRaw;
	if say.cursorChanged then
		__cursorFlash = 0;
	end

	local iy = y + h/2

	local m = mouseRegion(x, y, w, h)
	optargs.intensity = intensity*.5
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON
	optargs.nofont = true

	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, m.hoverAmount, enabled))--, m.leftHeld))
	nvgText(x, iy, "To Party: ")
	local ix = x + nvgTextWidth("To Party: ")

	-- when typing draw border
	if say.hoverAmount > 0 then
		local intensity = say.hoverAmount;
		local borderCol = Color(150, 150, 150, 150 * intensity);
		local bgCol = Color(34+10, 36+10, 40+10, 150 * intensity);

		local col = Color(232,232,232)
		local entryCol = Color(col.r, col.g, col.b, 255 * intensity);

		-- prepare actual say text
		local entryText = say.text;
		local entryLen = string.len(entryText);
		local tx = ix + __entryOffsetX;
		local textUntilCursor = string.sub(entryText, 0, say.cursor);
		local textWidthAtCursor = nvgTextWidth(textUntilCursor);
		
		-- handle scrolling back/forward with a large buffer!
		local cursorx = tx + textWidthAtCursor;
		local endx = (x+w);
		local cursorpast = cursorx - endx;
		if cursorpast > 0 then
			__entryOffsetX = __entryOffsetX - cursorpast;
		end
		local startx = ix;
		local cursorearly = startx - cursorx;
		if cursorearly > 0 then
			__entryOffsetX = __entryOffsetX + cursorearly;
		end
		tx = ix + __entryOffsetX; -- update now, so we're not a frame late
		
		-- clip actual text
		nvgSave();
		nvgIntersectScissor(ix, iy-50, w, h+200);
		
		-- draw actual text
		nvgFillColor(entryCol);
		nvgText(tx, iy, entryText);

		-- multiple selection, draw selection field
		if say.cursor ~= say.cursorStart then
			local textUntilCursorStart = string.sub(entryText, 0, say.cursorStart);
			local textWidthAtCursorStart = nvgTextWidth(textUntilCursorStart);
		
			local selx = math.min(textWidthAtCursor, textWidthAtCursorStart);
			local selw = math.abs(textWidthAtCursor - textWidthAtCursorStart);
			nvgBeginPath();
			nvgRect(tx + selx, iy - 10, selw, 22);
			nvgFillColor(Color(255, 192, 192, 128));
			nvgFill();	
		end

		-- remove clip
		nvgRestore();

		-- flashing cursor
		if __cursorFlash < cursorFlashPeriod then
			nvgBeginPath();
			nvgMoveTo(tx + textWidthAtCursor, iy - 10);
			nvgLineTo(tx + textWidthAtCursor, iy + 12);
			nvgStrokeColor(Color(col.r,col.g,col.b,128*intensity));
			nvgStroke();
		else
			if __cursorFlash > cursorFlashPeriod*2 then
				__cursorFlash = 0;
			end
		end
	end

	if say.hoverAmount < 1 then
		local intensityMult = 1 - say.hoverAmount
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity*.5*intensityMult, m.hoverAmount, enabled, m.leftHeld))
		nvgText(ix, iy, "Type here to chat")

		if m.leftUp then
			-- give focus for next frame
			sayPartyRegion(true)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local __partyOffset = RaiseLower_Define(80, 0)
local __chatSize = RaiseLower_Define(45, 200)
function Menu:ui2DrawParty()
	local partyMembers = party.memberCount

	-- show party always if in HOME or PLAY screen in main menu
	local showParty = ((self.modeKey == 1) or (self.modeKey == 4)) and ((world.state == STATE_DISCONNECTED) or (replayName == "menu"))
	-- or if we actually have a party
	if partyMembers > 1 then
		showParty = true
	end
	-- never show when not in menu
	if not isInMenu() then
		showParty = false
	end

	local x = -620
	local y = viewport.height / 2 - 80 + RaiseLower_UpdateSmart(__partyOffset, showParty)
	local w = 1240
	local h = 80

	-- don't draw if off screen
	if y >= viewport.height/2 - .1 then
		return
	end

	-- say is for input text
	local say = sayPartyRegion();

	local intensity = 1
	local hoverAmount = 0;
	local enabled = true;
	local pad = 10
	local ix = x + pad
	local iy = y + pad

	-- grow chat when we have focus
	local chatHeight = RaiseLower_UpdateSmart(__chatSize, say.focus)

	local heightThere = partyHistoryCount * 25 - 3
	chatHeight = math.min(chatHeight, heightThere)

	nvgSave();
	
	-- party avatar bg
	nvgBeginPath();
	nvgRect(x, y, 380, h);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
	nvgFill();

	-- party text
	nvgFontSize(36);
	nvgFontFace(FONT_TEXT2_BOLD);
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, y+h*(1/4)+8, "PARTY");
	
	-- member count text
	nvgFontSize(26);
	nvgFontFace(FONT_TEXT2);
	nvgText(ix, y+h*(3/4)-8, string.format("%d Member%s", partyMembers, partyMembers ~= 1 and "s" or ""))
	
	-- leave party button
	local optargs = {}
	optargs.intensity = intensity;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.coltype = UI2_COLTYPE_BUTTON;
	optargs.enabled = partyMembers > 1;
	optargs.icon = "internal/ui/icons/checkBoxTick"
	optargs.iconSize = 8;
	if ui2Button("", ix+70, y+15, 25, 25, optargs) then
		partyLeave()
	end
	ix = ix + 100

	-- avatars
	for i=1,4 do
		ui2DrawPartyMember(ix, iy, 60, 60, intensity, partyMembers >= i and party.members[i].steamId or nil)
		ix = ix + 66
	end
	ix = ix + 6
	ix = ix + 50

	if partyMembers > 1 then
		local chatw = 810

		-- chat bg	
		nvgBeginPath();
		nvgRect(ix, y+45-chatHeight, chatw, h+chatHeight);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity*.9, hoverAmount, enabled));
		nvgFill();

		-- text input
		nvgFontSize(FONT_SIZE_DEFAULT);
		nvgFontFace(FONT_TEXT);
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, hoverAmount, enabled));
		local iy = y + h-35
		ui2DrawPartyChatInput(ix+5, iy, chatw-10, 35, say)

		-- history chat
		nvgSave()
		nvgIntersectScissor(x, y+45-chatHeight+2, w - 5, h+chatHeight);
		iy = iy - 7
		ui2DrawPartyChatHistory(ix+5, iy, chatw-10)
		nvgRestore()

		ix = ix + 655
		ix = ix + 50
	
		---- play button
		--local optargs = {}
		--optargs.intensity = intensity
		--optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK
		--if ui2Button("PLAY", ix, y, 100, h, optargs) then
		--	self.modeKey = 4;
		--	self.modes[self.modeKey].subKey = 1;
		--end
	else
		-- dump chat history when leaving party
		partyHistoryCount = 0
	end

	nvgRestore()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:show()
	self.modes = {
		[1] = 
		{ 
			name = "", -- HOME
			icon = "internal/ui/icons/home", 
			draw = self.ui2DrawHome,
			onlyWhenDisconnected = true,
			onSelected = goneToHomeMenu
		},
		[2] = 
		{ 
			name = "", -- MATCH
			icon = "internal/ui/icons/home", 
			draw = self.ui2DrawMatch,
			onlyWhenConnected = true
		},
		[3] = 
		{ 
			name = "", -- REPLAY
			icon = "internal/ui/icons/home", 
			draw = self.ui2DrawReplay,
			onlyWhenInReplay = true
		},
		[4] =
		{
			name = "", -- PROFILE
			icon = "internal/ui/icons/profile",
			subs = 
			{
				[1] = { name = "Player", draw = self.ui2DrawProfilePlayer },
				[2] = { name = "Statistics", draw = self.ui2DrawProfileStatistics },
				[3] = { name = "Awards", draw = self.ui2DrawProfileAwards },
				[4] = { name = "Melee", draw = self.ui2DrawProfileMelee, hidden = true, onDeselected = inventoryDeselected },
				[5] = { name = "Head", draw = self.ui2DrawProfileHead, hidden = true, onDeselected = inventoryDeselected },
				[6] = { name = "Arms", draw = self.ui2DrawProfileArms, hidden = true, onDeselected = inventoryDeselected },
				[7] = { name = "Legs", draw = self.ui2DrawProfileLegs, hidden = true, onDeselected = inventoryDeselected },
				[8] = { name = "Torso", draw = self.ui2DrawProfileTorso, hidden = true, onDeselected = inventoryDeselected },
				[9] = { name = "Burstgun", draw = self.ui2DrawProfileBurstgun, hidden = true, onDeselected = inventoryDeselected },
				[10] = { name = "Shotgun", draw = self.ui2DrawProfileShotgun, hidden = true, onDeselected = inventoryDeselected },
				[11] = { name = "GrenadeLauncher", draw = self.ui2DrawProfileGrenadeLauncher, hidden = true, onDeselected = inventoryDeselected },
				[12] = { name = "PlasmaRifle", draw = self.ui2DrawProfilePlasmaRifle, hidden = true, onDeselected = inventoryDeselected },
				[13] = { name = "RocketLauncher", draw = self.ui2DrawProfileRocketLauncher, hidden = true, onDeselected = inventoryDeselected },
				[14] = { name = "IonCannon", draw = self.ui2DrawProfileIonCannon, hidden = true, onDeselected = inventoryDeselected },
				[15] = { name = "BoltRifle", draw = self.ui2DrawProfileBoltRifle, hidden = true, onDeselected = inventoryDeselected },
			},
			subKey = 1,
		},
		[5] = 
		{ 
			name = "PLAY",
			icon = "", 
			subs = 
			{
				[1] = { name = "Quick Play", draw = self.ui2DrawQuickPlay, onSelected = goneToFindGame },
				[2] = { name = "Find Game", draw = self.ui2DrawFindServer, onSelected = serverListRefresh },
				[3] = { name = "Host Game", draw = self.ui2DrawPlayCreateServer },
				[4] = { name = "Training", draw = self.ui2DrawTraining },
				[5] = { name = "Bots", draw = self.ui2DrawTrainingBots },
				[6] = { name = "Community Support", draw = self.ui2DrawLearn },
				[7] = { name = "Replay Browser", draw = self.ui2DrawReplayBrowser, onSelected = replayBrowserIndex}
			},
			subKey = 1,
		},
		[6] =
		{
			name = "", -- CRATES
			icon = "internal/ui/icons/crate", 
			draw = self.ui2DrawCrates,
			onDeselected = inventoryDeselected, 
			onSelected = inventoryRefresh
		},
		[7] =
		{
			name = "", -- OPTIONS
			icon = "internal/ui/icons/settings", 
			subs =
			{
				[1] = { name = "System Settings", draw = self.ui2DrawOptionsSystem },
				[2] = { name = "Graphics Options", draw = self.ui2DrawOptionsGraphics },
				[3] = { name = "Game Options", draw = self.ui2DrawOptionsGame },
				[4] = { name = "Bindings", draw = self.ui2DrawOptionsBinds },
				[5] = { name = "Mouse Settings", draw = self.ui2DrawOptionsMouse },
				[6] = { name = "Widgets", draw = self.ui2DrawOptionsWidgets },
				[7] = { name = "Addons", draw = self.ui2DrawOptionsAddons }
			},
			subKey = 1,
		}
	};
	self.activeBindFor = "Game";

	-- used on asset reload to restore menu context
	if self.startModeKey ~= nil and self.modes[self.startModeKey] ~= nil then
		self.modeKey = self.startModeKey;
		if self.startSubKey ~= nil and self.modes[self.modeKey].subs[self.startSubKey] ~= nil then
			self.modes[self.modeKey].subKey = self.startSubKey;
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:hide()
	self.selected_r_resolution_fullscreen = nil;
	self.selected_r_resolution_windowed = nil;
	self.selected_r_fullscreen = nil;
	self.selected_r_refreshrate = nil;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:setMode(newmode)
	-- yuk :S
	if self.modes == nil then
		Menu.show(Menu);
	end

	for k, v in pairs(self.modes) do
		if v.name == newmode then
			self.modeKey = k;
			self.submode = 0;
		else
			-- make sure whatever menu we were on isn't there anymore
			-- (because we want to fade from nothing to this)
			v.intensity = 0;
			v.fadeDir = 0;
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:setModeHome()
	-- yuk :S
	if self.modes == nil then
		Menu.show(Menu);
	end
	
	local inReplayEditor = replayActive and replayName ~= "menu"
	local consideredDisconnected = (clientGameState == STATE_DISCONNECTED) or (replayName == "menu");
	
	for k, v in pairs(self.modes) do
		local suitable = true;

		if v.onlyWhenDisconnected then
			suitable = consideredDisconnected == true;
		end
		if v.onlyWhenInReplay then
			suitable = inReplayEditor;			
		end
		if v.onlyWhenConnected then
			suitable = consideredDisconnected == false;
		end

		if v.icon == "internal/ui/icons/home" and suitable then
			self.modeKey = k;
			self.submode = 0;
		else
			-- make sure whatever menu we were on isn't there anymore
			-- (because we want to fade from nothing to this)
			v.intensity = 0;
			v.fadeDir = 0;
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Menu:draw()
	local deltaFade = deltaTimeRaw*6;

	local showMenuBar = isInMenu();
	if showMenuBar then
		self.menuBarIntensity = math.min(1, self.menuBarIntensity + deltaFade);
	else
		self.menuBarIntensity = math.max(0, self.menuBarIntensity - deltaFade);
	end

	self:updateMMStatusText()

	-- show/hide player preview
	local mode = self.modeKey ~= nil and self.modes[self.modeKey] or nil;
	local showPlayerPreview = isInMenu() and mode ~= nil and mode.icon == "internal/ui/icons/profile" and mode.intensity ~= nil and mode.intensity > .1 and (mode.subKey < 2 or mode.subKey > 3);
	local showCrates = isInMenu() and mode ~= nil and mode.icon == "internal/ui/icons/crate" and mode.intensity ~= nil and mode.intensity > .1;
	playerPreviewSetEnabled(showPlayerPreview);
	playerPreviewSetRotation(self.profileRotation);
	cratesSetEnabled(showCrates);
	cratesSetRotation(self.profileRotation);
	if not showCrates and not showPlayerPreview then
		self.profileRotation = 0;
	end

	-- put big mouse region to grab mouse click n drag behind everything
	if isInMenu() then
		local m = mouseRegion(-viewport.width / 2, -viewport.height / 2, viewport.width, viewport.height);
		if showPlayerPreview or showCrates then
			if m.leftHeld and self.profileMouseX ~= nil then
				local dragX = (self.profileMouseX - m.mousex) * 20;
				if dragX > 0 then
					self.profileRotationVelocity = math.max(self.profileRotationVelocity, dragX);
				elseif dragX < 0 then
					self.profileRotationVelocity = math.min(self.profileRotationVelocity, dragX);
				end
			end
			self.profileRotationVelocity = (1.0 - deltaTimeRaw * 5) * self.profileRotationVelocity;
			self.profileMouseX = m.mousex;
			self.profileRotation = self.profileRotation + self.profileRotationVelocity * deltaTimeRaw;
		end
		self.mouseX = m.mousex;
		self.mouseY = m.mousey;
	end

	-- determine intensity for submenu
	local subIntensity = 0;
	for k, v in pairs(self.modes) do
		if v.subs ~= nil and v.intensity ~= nil then
			subIntensity = subIntensity + v.intensity;
		end
	end

	local oldModeKey = self.modeKey;
	local oldSubKey = self.modeKey ~= nil and self.modes[self.modeKey].subKey or nil;

	-- menu bar for mode selection
	local menuBarY = nil
	if self.modeKey == nil then self.modeKey = 1; end
	--if self.menuBarIntensity > 0 then
		-- draw menu
		local mode = self.modes[self.modeKey];
		local intensity = EaseInOut(self.menuBarIntensity) -- ease it
		local newModeKey, menuBarY = ui2MenuBar(
			self.modeKey, self.modes,
			intensity, subIntensity);

		-- apply selection
		self.modeKey = newModeKey;
	--end

	-- fade up/down
	for k, v in pairs(self.modes) do
		-- main menu
		local activeMode = k == self.modeKey;
		if v.intensity == nil then v.intensity = 0; end
		if activeMode and showMenuBar then
			v.intensity = math.min(1, v.intensity + deltaFade);
		else
			v.intensity = math.max(0, v.intensity - deltaFade);
		end

		-- sub menu
		if v.subs ~= nil then
			for k1, v1 in pairs(v.subs) do
				if v1.intensity == nil then v1.intensity = 0; end
				if k1 == v.subKey then
					v1.intensity = math.min(1, v1.intensity + deltaFade);
				else
					v1.intensity = math.max(0, v1.intensity - deltaFade);
				end
			end
		end
	end
	
	-- draw (fading OUT behind)
	for k, v in pairs(self.modes) do
		if k ~= self.modeKey and v.intensity > 0 then
			if v.subs then
				-- submenu bar
				ui2SubMenuBar(v.subs, v.intensity, v.subKey);

				-- subdraws (again putting fading OUT behind)
				for k1, v1 in pairs(v.subs) do
					if k1 ~= v.subKey and v1.draw ~= nil and v1.intensity > 0 then
						v1.draw(self, math.min(v.intensity, v1.intensity));
					end
				end
				for k1, v1 in pairs(v.subs) do
					if k1 == v.subKey and v1.draw ~= nil and v1.intensity > 0 then
						v1.draw(self, math.min(v.intensity, v1.intensity));
					end
				end
			end

			-- draw
			if v.draw ~= nil then
				v.draw(self, v.intensity);
			end
		end
	end
	for k, v in pairs(self.modes) do
		if k == self.modeKey and v.intensity > 0 then
			if v.subs ~= nil then
				-- submenu bar
				local newSubKey = ui2SubMenuBar(v.subs, v.intensity, v.subKey);
				if newSubKey ~= v.subKey then
					v.subKey = newSubKey;
				end

				-- subdraws (again putting fading OUT behind)
				for k1, v1 in pairs(v.subs) do
					if k1 ~= v.subKey and v1.draw ~= nil and v1.intensity > 0 then
						v1.draw(self, math.min(v.intensity, v1.intensity));
					end
				end
				for k1, v1 in pairs(v.subs) do
					if k1 == v.subKey and v1.draw ~= nil and v1.intensity > 0 then
						v1.draw(self, math.min(v.intensity, v1.intensity));
					end
				end
			end

			-- draw
			if v.draw ~= nil then
				v.draw(self, v.intensity);
			end
		end
	end

	-- 
	local modeChanged = (self.modeKey ~= oldModeKey)
	local modeOrSubModeChanged = (modeChanged) or (self.modes[self.modeKey].subKey ~= oldSubKey);
	if modeChanged or modeOrSubModeChanged then
		-- handle onDeselected()
		if oldModeKey ~= nil then
			local oldmodetab = self.modes[oldModeKey];
			if oldmodetab ~= nil and oldmodetab.onDeselected ~= nil then
				oldmodetab.onDeselected();
			end
			if oldmodetab ~= nil and oldmodetab.subs ~= nil and oldSubKey ~= nil then
				local oldsubtab = oldmodetab.subs[oldSubKey];
				if oldsubtab ~= nil and oldsubtab.onDeselected ~= nil then
					oldsubtab.onDeselected();
				end
			end
		end

		-- handle onSelected()
		local modetab = self.modes[self.modeKey];
		if modetab ~= nil and modetab.subs ~= nil then
			local subtab = modetab.subs[modetab.subKey];
			if subtab.onSelected ~= nil then
				subtab.onSelected();
			end
		end

		if modeChanged and modetab ~= nil and modetab.onSelected ~= nil then
			modetab.onSelected();
		end
	end

	if menuBarY ~= nil then
		self:ui2DrawMenuBarHoveringMatchmakingStatus(menuBarY)
	end

	-- party
	self:ui2DrawParty()

	--nvgBeginPath();
	--nvgMoveTo(-620, -2000);
	--nvgLineTo(-620, 2000);
	--nvgMoveTo(620, -2000);
	--nvgLineTo(620, 2000);
	--nvgStrokeColor(Color(255,255,0));
	--nvgStroke();
end


function is_empty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function getEntryPath(entry)
	local path = ""
	for i,v in ipairs(Menu.replayBrowserCursorDirs) do
		path = path .. v .. "/"
	end

	path = path .. entry

	return path
end

function Menu:ui2DrawReplayBrowser()
	-- TODO: Add custom itemDrawFunction

	while (Menu.replayBrowserTable["replays"] == nil) do
		replayBrowserIndex();
	end

	local replayBrowserTable = getReplayBrowserDataDir(Menu.replayBrowserCursorDirs);

	local folders = replayBrowserTable["folders"];
	local replays = replayBrowserTable["replays"];

	local entries = {};

	for k,v in pairs(folders) do
		table.insert(entries, "/" .. k);
		table.sort(entries);
	end

	for i,v in ipairs(replays) do
		table.insert(entries, v);
	end

	local optargs = {
		intensity = intensity;
	};

	nvgSave();
	
	local x = -620;
	local y = -250;
	local colWidth = 550;
	local scrollSelHeight = 600;

	optargs.enabled = not is_empty(Menu.replayBrowserCursorDirs);
	optargs.halign = NVG_ALIGN_CENTER;
	optargs.valign = NVG_ALIGN_MIDDLE;
	if(ui2Button("Back", x, y - 30, 60, 40, optargs)) then
		entrySelected = nil;
		Menu.replayBrowserCursorDirs[#Menu.replayBrowserCursorDirs] = nil;
		replayBrowserIndex();
	end
	optargs.enabled = nil;
	optargs.halign = nil;
	optargs.valign = nil;


	optargs.enabled = false;
	optargs.halign = NVG_ALIGN_CENTER;
	ui2Label("Replays", x + 275, y, optargs);
	optargs.halign = nil;
	optargs.enabled = nil;
	y = y + 40;

	-- replay scroll selection
	optargs.itemHeight = 35;
	-- optargs.itemDrawFunction = blah;
	optargs.itemPad = 5;
	entrySelected = ui2ScrollSelection(
		entries, entrySelected, x, y, colWidth, scrollSelHeight, self.scrollBarDataTrainingBotsMap, optargs);

	-- replay data
	if (entrySelected ~= nil) then
		-- if we have selected a folder, go into it
		if string.find(entrySelected, "/") then
			local folderName = string.sub(entrySelected, 2);
			table.insert(Menu.replayBrowserCursorDirs, folderName);
			entrySelected = nil;
			replayBrowserIndex();
			nvgRestore();
			return;
		end

		x = x + 620;

		-- header
		optargs.enabled = false;
		optargs.halign = NVG_ALIGN_CENTER;
		ui2Label("Information", x + 310, y - 40, optargs);
		optargs.halign = nil;
		optargs.enabled = nil;

		-- outline preview box
		nvgBeginPath();
		nvgRect(x, y, 620, 620 * 9 / 16);
		nvgClosePath();

		-- preview base
		nvgFillColor(Color(25,25,25));

		-- map title & preview
		local title = replayBrowserTable["info"][entrySelected]["szMapTitle"];

		if (replayBrowserTable["info"][entrySelected]["workshopId"] == 0 or not connectedToSteam) then
			nvgFillImagePattern("internal/ui/tiles/offline_replay_c", x, y, 620, 620 * 9 / 16);
		else
			-- need to iterate over all workshopMaps to find the correct one
			for k, v in ipairs(workshopMaps) do
				-- typing problems, convert v.id to a number
				if (v.id + 0 == replayBrowserTable["info"][entrySelected]["workshopId"]) then
					title = v.workshopTitle;

					nvgFillImagePattern(v.previewImageName, x, y, 620, 620 * 9 / 16);
					break;
				end
			end
		end

		nvgFill();

		-- move
		y = y + 620 * 9 / 16;

		-- date
		local starttime = replayBrowserTable["info"][entrySelected]["epochStartTime"]

		nvgFillColor(Color(200, 200, 200));
		nvgFontSize(30);
		nvgFontFace(FONT_TEXT);
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgText(x, y + 20, title);
		
		nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
		nvgText(x + 620, y + 20, starttime);

		-- other info?

		-- play button
		local buttonText = "Play"
		optargs.enabled = (entrySelected ~= nil);
		if (ui2Button(buttonText, x, y + 150, 300, 100, optargs)) then
			consolePerformCommand("play " .. getEntryPath(entrySelected));
			hideMenu();
		end

		-- play PB button
		local buttonText2 = "Start replay at PB"
		optargs.enabled = (entrySelected ~= nil and replayBrowserTable["info"][entrySelected]["timecode"] ~= 0);
		if (ui2Button(buttonText2, x + 320, y + 150, 300, 100, optargs)) then
			consolePerformCommand("ui_playseek_to " .. getEntryPath(entrySelected) .. " " .. replayBrowserTable["info"][entrySelected]["timecode"]);
			hideMenu();
		end
	end

	nvgRestore();
end