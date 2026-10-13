-- ---------------------------------------------------------------------------
-- Sticky notes: the settings tab in the notes page.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI, App = ns.L, ns.UI, ns.App
local Stickies = ns.Stickies
local byNote, MIN_H, MIN_W = Stickies.byNote, Stickies.MIN_H, Stickies.MIN_W

-- ---------------------------------------------------------------------------
-- Settings tab in the notes page
-- ---------------------------------------------------------------------------
local settings
function Stickies.ShowSettings(p)
    if not settings then
        settings = {}
        local W = 300
        UI.Label(p, L["NEW STICKY NOTES"], 0, -4)
        local function Slider(label, field, minV, maxV, step, fmt, y, apply)
            local s = UI.ValueSlider(p, label, minV, maxV, step,
                function() return Stickies.Settings()[field] end,
                function(v)
                    Stickies.Settings()[field] = v
                    if apply then apply() end
                end, W, fmt)
            s:SetPoint("TOPLEFT", 0, y)
            settings[#settings + 1] = s
        end
        Slider(L["Width"], "w", MIN_W, 500, 10, "%d px", -24)
        Slider(L["Height"], "h", MIN_H, 500, 10, "%d px", -64)
        UI.Label(p, L["ALL STICKY NOTES"], 0, -112)
        Slider(L["Text size"], "size", 10, 18, 1, "%d pt", -132, function()
            for note, f in pairs(byNote) do if not f.editing then Stickies.Render(f) end end
        end)
        settings.count = ns.Text(p, 12)
        settings.count:SetPoint("TOPLEFT", 0, -182)
        local closeAll = UI.Button(p, 140, L["Close all"], function()
            Stickies.CloseAll()
            Stickies.ShowSettings(p)
        end, 22)
        closeAll:SetPoint("TOPLEFT", 0, -202)

        UI.Label(p, L["IN COMBAT"], 0, -244)
        local hide = UI.CheckRow(p, L["Hide in combat"],
            function() return ns.Notes.HideInCombat("stickies") end,
            function(v) ns.Notes.SetHideInCombat("stickies", v) end, W)
        hide:SetPoint("TOPLEFT", 0, -262)
        local hold = ns.Notes.HoldShowsRow(p, W)
        hold:SetPoint("TOPLEFT", 0, -284)
        settings[#settings + 1] = hide
        settings[#settings + 1] = hold

        local X = W + 40
        UI.Label(p, L["HOW IT WORKS"], X, -4)
        local help = UI.Hint(p, "", App.CONTENT_W - X)
        help:SetPoint("TOPLEFT", X, -24)
        help:SetSpacing(4)
        ns.Paint(function()
            help:SetText(table.concat({
                L["\"Sticky\" above a note puts it on the screen."],
                L["Drag the colored bar to move it, the corner to resize it. The lock keeps both."],
                L["Drop it at the edge of another sticky note to dock it there: same size, moves along. Pull it away to undock."],
                L["Click the text to write; Esc or \"Done\" shows it formatted again."],
                "",
                ns.Code("[ ]") .. "  " .. L["checkbox (click it to tick)"],
                ns.Code("[x]") .. "  " .. L["ticked"],
                ns.Code("- ") .. "  " .. L["list item"],
            }, "\n"))
        end)
    end
    for _, s in ipairs(settings) do s:Refresh() end
    settings.count:SetText(L["Open right now: %d"]:format(Stickies.Count()))
end
