-- ---------------------------------------------------------------------------
-- Miscellaneous, tab Hide chat: the switch and the anchor area of the chat button.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI, T = ns.L, ns.UI, ns.T
local Misc = ns.Misc
local Chat = Misc.ChatHide

local W = 300

Misc.AddTab("chathide", L["Hide chat"], function(frame)
    local widgets, anchor = {}, {}
    local function Put(w, y, dim)
        w:SetPoint("TOPLEFT", 0, y)
        widgets[#widgets + 1] = w
        if dim then anchor[#anchor + 1] = w end
        return w
    end
    local function Dim()
        for _, w in ipairs(anchor) do
            if w.SetDisabled then w:SetDisabled(not Chat.Get("on")) else w:SetAlpha(Chat.Get("on") and 1 or 0.4) end
        end
    end

    UI.Label(frame, L["HIDE CHAT"], 0, 0)
    Put(UI.CheckRow(frame, L["Hide chat button"],
        function() return Chat.Get("on") end, function(v) Chat.Set("on", v) Dim() end, W), -20)
    local hint = UI.Hint(frame, L["A button hides the chat windows, their tabs, the input box and the chat menu buttons. Enter, Edit Mode or a click bring them back."], 600)
    hint:SetPoint("TOPLEFT", 0, -50)

    UI.Label(frame, L["ANCHOR"], 0, -96)
    local lock
    lock = Put(UI.Button(frame, 140, "", function()
        Chat.Set("locked", not Chat.Get("locked"))
        lock:Refresh()
    end), -118, true)
    function lock:Refresh() self.text:SetText(Chat.Get("locked") and L["Unlock"] or L["Lock"]) end
    UI.Label(frame, L["Quick place"], 0, -154)
    Put(UI.Dropdown(frame, {
        { "BOTTOMLEFT", L["Bottom left"] },
        { "BOTTOMRIGHT", L["Bottom right"] },
    }, function() return Chat.Get("corner") end, function(v) Chat.Set("corner", v) end, W), -174, true)
    local r = Chat.RANGES
    Put(UI.ValueSlider(frame, L["Size"], r.size[1], r.size[2], r.size[3],
        function() return Chat.Get("size") end, function(v) Chat.Set("size", v) end, W, "%d"), -210, true)
    Put(UI.ValueSlider(frame, L["Opacity"], r.alpha[1], r.alpha[2], r.alpha[3],
        function() return Chat.Get("alpha") end, function(v) Chat.Set("alpha", v) end, W, "%.2f"), -250, true)
    UI.Label(frame, L["Button color"], 0, -296)
    local sw = UI.ColorSwatch(frame, L["Button color"], Chat.GetColor,
        function(c) Chat.SetColor(c) end, function() return T.accent end)
    sw:SetPoint("TOPLEFT", 0, -316)
    widgets[#widgets + 1] = sw
    anchor[#anchor + 1] = sw
    Put(UI.Button(frame, 140, L["Reset anchor"], function()
        Chat.ResetAnchor()
        Misc:Apply()
        frame:Refresh()
    end), -352, true)

    function frame:Refresh()
        for _, w in ipairs(widgets) do if w.Refresh then w:Refresh() end end
        Dim()
    end
end, 20)
