-- ---------------------------------------------------------------------------
-- Settings page "Position & visibility": frame scale, lock, position and when the
-- frame shows. Modules can add blocks below (App:AddBlock("general", ...)).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI, HUD, App = ns.L, ns.UI, ns.HUD, ns.App

local generalPage   -- set at the end of the file; filled in while building

local function BuildGeneral(p)
    UI.Label(p, L["FRAME"], 0, 0)
    local scaleLbl = ns.Text(p, 12)
    scaleLbl:SetPoint("TOPLEFT", 0, -20)
    scaleLbl:SetText(L["Scale"])
    local scaleVal = ns.Text(p, 12)
    scaleVal:SetPoint("TOPLEFT", 214, -20)
    local slider = UI.Slider(p, 0.5, 2.0, 0.05,
        function() return ns.Char().hud.scale or 1 end,
        function(v)
            HUD:SetScale(v)
            scaleVal:SetText(("%d%%"):format(v * 100 + 0.5))
        end, 250)
    slider:SetPoint("TOPLEFT", 0, -40)

    local lockBtn
    lockBtn = UI.Button(p, 122, "", function()
        HUD:SetLocked(not HUD:IsLocked())
        lockBtn.text:SetText(HUD:IsLocked() and L["Unlock"] or L["Lock"])
    end)
    lockBtn:SetPoint("TOPLEFT", 0, -62)
    local resetPos = UI.Button(p, 122, L["Reset position"], function()
        HUD:ResetPosition()
        App.Status(L["Position reset."])
    end)
    resetPos:SetPoint("LEFT", lockBtn, "RIGHT", 6, 0)
    local center = UI.CheckRow(p, L["Center horizontally (only up/down)"],
        function() return ns.Char().hud.centerX end, function(v) HUD:SetCenterX(v) end)
    center:SetPoint("TOPLEFT", 0, -90)

    UI.Label(p, L["VISIBILITY"], 0, -126)
    local holdLbl, holdBtn, holdHint
    local function RefreshHold()
        holdBtn.text:SetText(L[ns.Char().hud.holdKey or "ALT"])
        local a = (ns.Char().hud.hide or "never") ~= "never" and 1 or 0.4
        holdLbl:SetAlpha(a)
        holdBtn:SetAlpha(a)
        holdHint:SetAlpha(a)
    end
    local hideLbl = ns.Text(p, 12)
    hideLbl:SetPoint("TOPLEFT", 0, -148)
    hideLbl:SetText(L["Hide the frame"])
    local hideBox = UI.Dropdown(p, {
        { "never",   L["Never (always show)"] },
        { "combat",  L["Out of combat"] },
        { "target",  L["Without a target"] },
        { "vehicle", L["In a vehicle"] },
    }, function() return ns.Char().hud.hide or "never" end,
    function(v) ns.Char().hud.hide = v RefreshHold() end, 160)
    hideBox:SetPoint("TOPLEFT", 90, -144)
    holdLbl = ns.Text(p, 12)
    holdLbl:SetPoint("TOPLEFT", 0, -176)
    holdLbl:SetText(L["Hold to show"])
    holdBtn = UI.Button(p, 70, "", function()
        local keys = HUD.HOLD_KEYS
        local i = ns.IndexOf(keys, ns.Char().hud.holdKey) or 0
        ns.Char().hud.holdKey = keys[i % #keys + 1]
        RefreshHold()
    end)
    holdBtn:SetPoint("TOPLEFT", 180, -172)
    holdHint = UI.Hint(p, L["While hidden, holding this key shows the frame. Unlocked, the frame always shows."], 250)
    holdHint:SetPoint("TOPLEFT", 0, -198)

    generalPage.Refresh = function()
        slider:Refresh()
        scaleVal:SetText(("%d%%"):format((ns.Char().hud.scale or 1) * 100 + 0.5))
        lockBtn.text:SetText(HUD:IsLocked() and L["Unlock"] or L["Lock"])
        center:Refresh()
        hideBox:Refresh()
        -- blocks that modules add (App:AddBlock) go below the visibility
        App:PlaceBlocks("general", p, 0, -244, 270)
        RefreshHold()
    end
end


generalPage = App:AddPage({
    key = "general", section = "hud", label = L["Position & visibility"], order = 10,
    Build = function(_, frame) BuildGeneral(frame) end,
})
