-- ---------------------------------------------------------------------------
-- Macro Manager: the buttons in the page header (Macros.RegisterAction), such as
-- Import / Export and those that modules add (e.g. the rogue's weapon macros).
-- ---------------------------------------------------------------------------
local _, ns = ...
local UI = ns.UI
local Macros = ns.Macros
local mm = Macros.page

local actionButtons = {}
local function LayoutActions()
    local x = 0
    for i, a in ipairs(Macros.actions) do
        local b = actionButtons[i]
        if not b then
            b = UI.Button(mm, a.width or 120, a.label, nil, 22)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(self, button) a.OnClick(self, button) end)
            if a.Tooltip then UI.Tooltip(b, function(self) return a.Tooltip(self) end, "ANCHOR_BOTTOM") end
            b:SetAccent(a.accent)
            actionButtons[i] = b
        end
        local active = not a.IsActive or a.IsActive()
        b:SetShown(active)
        if active then
            b:ClearAllPoints()
            b:SetPoint("TOPRIGHT", x, 0)
            x = x - (a.width or 120) - 6
        end
    end
end

Macros.OnShow(LayoutActions)
ns.On("MODULES_CHANGED", function() if mm:IsShown() then LayoutActions() end end)
