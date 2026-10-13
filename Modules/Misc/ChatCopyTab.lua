-- ---------------------------------------------------------------------------
-- Miscellaneous, tab Copy chat: the switch, the icon and the text window.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI = ns.L, ns.UI
local Misc = ns.Misc
local Copy = Misc.ChatCopy

local W = 300

Misc.AddTab("chatcopy", L["Copy chat"], function(frame)
    local widgets, dim = {}, {}
    local function Put(w, y, dimmed, x)
        w:SetPoint("TOPLEFT", x or 0, y)
        widgets[#widgets + 1] = w
        if dimmed then dim[#dim + 1] = w end
        return w
    end
    local function Dim()
        for _, w in ipairs(dim) do
            if w.SetDisabled then w:SetDisabled(not Copy.Get("on")) else w:SetAlpha(Copy.Get("on") and 1 or 0.4) end
        end
    end

    UI.Label(frame, L["COPY CHAT"], 0, 0)
    Put(UI.CheckRow(frame, L["Copy chat icon"],
        function() return Copy.Get("on") end, function(v) Copy.Set("on", v) Dim() end, W), -20)
    local hint = UI.Hint(frame, L["A small icon on every chat window opens its text in a window to select and copy (Ctrl+A, Ctrl+C). Lines the game protects are skipped and counted."], 600)
    hint:SetPoint("TOPLEFT", 0, -50)

    local X = 330   -- second column
    UI.Label(frame, L["ICON"], 0, -96)
    Put(UI.Dropdown(frame, {
        { "TOPLEFT", L["Top left"] },
        { "TOPRIGHT", L["Top right"] },
        { "BOTTOMLEFT", L["Bottom left"] },
        { "BOTTOMRIGHT", L["Bottom right"] },
    }, function() return Copy.Get("corner") end, function(v) Copy.Set("corner", v) end, W), -118, true)
    Put(UI.CheckRow(frame, L["Only on mouse over"],
        function() return Copy.Get("hover") end, function(v) Copy.Set("hover", v) end, W), -118, true, X)
    local r = Copy.RANGES
    Put(UI.ValueSlider(frame, L["Icon size"], r.iconSize[1], r.iconSize[2], r.iconSize[3],
        function() return Copy.Get("iconSize") end, function(v) Copy.Set("iconSize", v) end, W, "%d"), -156, true)

    UI.Label(frame, L["WINDOW"], 0, -210)
    Put(UI.ValueSlider(frame, L["Font size"], r.size[1], r.size[2], r.size[3],
        function() return Copy.Get("size") end, function(v) Copy.Set("size", v) Copy.Refresh() end, W, "%d"), -232, true)
    Put(UI.ValueSlider(frame, L["Line limit"], r.limit[1], r.limit[2], r.limit[3],
        function() return Copy.Get("limit") end, function(v) Copy.Set("limit", v) Copy.Refresh() end, W, "%d"), -232, true, X)
    Put(UI.CheckRow(frame, L["Timestamps"],
        function() return Copy.Get("time") end, function(v) Copy.Set("time", v) Copy.Refresh() end, W), -276, true)
    Put(UI.CheckRow(frame, L["Channel colors"],
        function() return Copy.Get("colors") end, function(v) Copy.Set("colors", v) Copy.Refresh() end, W), -276, true, X)
    local hint2 = UI.Hint(frame, L["Timestamps count from switching on. For clean text when copying, turn the channel colors off."], 600)
    hint2:SetPoint("TOPLEFT", 0, -308)

    function frame:Refresh()
        for _, w in ipairs(widgets) do if w.Refresh then w:Refresh() end end
        Dim()
    end
end, 30)
