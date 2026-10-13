-- ---------------------------------------------------------------------------
-- Miscellaneous, tab Camera: the switch and the three sliders of the fast zoom.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI = ns.L, ns.UI
local Misc = ns.Misc
local Camera = Misc.Camera

local W = 300

Misc.AddTab("camera", L["Camera"], function(frame)
    local widgets, sliders = {}, {}
    local function Put(w, y)
        w:SetPoint("TOPLEFT", 0, y)
        widgets[#widgets + 1] = w
        return w
    end
    local function Slider(label, key, y, fmt)
        local r = Camera.RANGES[key]
        Put(UI.ValueSlider(frame, label, r[1], r[2], r[3],
            function() return Camera.Get(key) end, function(v) Camera.Set(key, v) end, W, fmt), y)
        sliders[#sliders + 1] = widgets[#widgets]
    end

    local function Dim()
        for _, w in ipairs(sliders) do w:SetDisabled(not Camera.Get("on")) end
    end
    UI.Label(frame, L["FAST ZOOM"], 0, 0)
    Put(UI.CheckRow(frame, L["Fast zoom"],
        function() return Camera.Get("on") end, function(v) Camera.Set("on", v) Dim() end, W), -20)
    local hint = UI.Hint(frame, L["Turn the mouse wheel quickly to cover much more distance; turn it slowly for small steps."], 600)
    hint:SetPoint("TOPLEFT", 0, -50)
    Slider(L["Base step"], "base", -86, "%.2f")
    Slider(L["Acceleration"], "accel", -126, "%.1f")
    Slider(L["Zoom speed (slow to fast)"], "speed", -166, "%.2f")
    UI.Label(frame, L["Zoom curve"], 0, -212)
    Put(UI.Dropdown(frame, {
        { "soft", L["Soft"], L["Even"] },
        { "direct", L["Direct"], L["Fast start"] },
    }, function() return Camera.Get("curve") end, function(v) Camera.Set("curve", v) end, W), -232)
    Put(UI.Button(frame, 140, L["Reset values"], function()
        Camera.ResetValues()
        Misc:Apply()
        frame:Refresh()
    end), -268)
    local off = UI.Hint(frame, L["Switching off puts the game's own zoom back; /reload leaves nothing of the change behind."], 600)
    off:SetPoint("TOPLEFT", 0, -306)

    function frame:Refresh()
        for _, w in ipairs(widgets) do if w.Refresh then w:Refresh() end end
        Dim()
    end
end, 10)
