-- ---------------------------------------------------------------------------
-- The "Cursor" page (HUD section, last entry): when the ring shows (also
-- "Off"), the ring color and the size.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI = ns.L, ns.UI
local Cursor = ns.Cursor

local CONTROL_W = 300
local MODE_W = 560

local widgets = {}

local function Build(frame)
    local function Put(w, y)
        w:SetPoint("TOPLEFT", 0, y)
        widgets[#widgets + 1] = w
        return w
    end
    local function Hint(text, y)
        local h = UI.Hint(frame, text, MODE_W)
        h:SetPoint("TOPLEFT", 22, y)
        return h
    end

    UI.Label(frame, L["SHOW"], 0, 0)
    Put(UI.Segmented(frame, {
        { "off", L["Off"] }, { "always", L["Always"] }, { "combat", L["In combat"] },
    }, function() return Cursor:Get("show") end,
    function(v) Cursor:Set("show", v) end, MODE_W), -20)

    Put(UI.CheckRow(frame, L["Hide in menus"],
        function() return Cursor:Get("hideInMenus") end,
        function(v) Cursor:Set("hideInMenus", v) end, CONTROL_W), -60)
    Hint(L["Game menu, settings, character, spellbook, map and similar windows."], -82)

    UI.Label(frame, L["RING COLOR"], 0, -112)
    local swatch = UI.ColorSwatch(frame, L["Ring color"],
        function() return Cursor:Get("color") end,
        function(c) Cursor:Set("color", c) end,
        function() return Cursor.DEFAULTS.color end)
    swatch:SetPoint("TOPLEFT", 0, -132)
    widgets[#widgets + 1] = swatch
    Put(UI.ValueSlider(frame, L["Size"], Cursor.SIZE_MIN, Cursor.SIZE_MAX, 1,
        function() return Cursor:Get("size") end,
        function(v) Cursor:Set("size", v) end, CONTROL_W, "%d px"), -172)
end

Cursor:Page({
    key = "cursor", section = "hud", label = L["Cursor"], order = 40,
    Build = function(_, frame)
        Build(frame)
        for _, w in ipairs(widgets) do w:Refresh() end
    end,
    Refresh = function()
        for _, w in ipairs(widgets) do w:Refresh() end
    end,
})
