-- ---------------------------------------------------------------------------
-- Rogue module: the options block on the Modules page and the reset category.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI = ns.L, ns.UI
local Rogue = ns.Rogue

function Rogue:BuildOptions(box, width)
    local rows = {}
    local function Row(label, field, y, tip)
        local r = UI.CheckRow(box, label,
            function() return Rogue:Settings()[field] ~= false end,
            function(v) Rogue:Settings()[field] = v and true or false end, width)
        r:SetPoint("TOPLEFT", 0, y)
        if tip then UI.Tooltip(r, { label, tip }) end
        rows[#rows + 1] = r
    end
    Row(L["Warn when a poison runs low (5 minutes or 5 charges)"], "poisonWarn", 0)
    function Rogue:RefreshOptions()
        for _, r in ipairs(rows) do
            r:Refresh()
            r:SetDisabled(not Rogue:IsActive())   -- the module is switched off
        end
    end
    return 22
end

Rogue:Reset({ key = "poisons", group = "macros", order = 75, label = L["Poison choices"],
    desc = L["The poison picked for each hand goes back to \"best available\"."],
    reset = function()
        local s = ns.Char().modules.rogue
        if s then s.poison = {} end
    end })
