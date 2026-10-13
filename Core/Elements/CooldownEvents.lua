-- ---------------------------------------------------------------------------
-- Cooldown bars: game events.
-- ---------------------------------------------------------------------------
local _, ns = ...
local HUD = ns.HUD
local CD = ns.Cooldowns

local function FindByCast(spellID)
    local e = CD.byCast[spellID]
    if e then return e end
    local n = ns.SpellName(spellID)
    return n and CD.byName[n]
end

local function Rebuild()
    CD:Build()
    CD:ScanSpellbook()
    CD:ResolveRanks()
    HUD:ApplyLayout()
    CD:Sync()
    CD:RefreshItems()
    CD:RefreshUsable()
end

ns.On("LOGIN", Rebuild)
ns.On("SETTINGS_RESET", Rebuild)

ns.RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, _, spellID)
    -- a secret ID could not even serve as a table key: skip it
    if ns.IsSecret(spellID) or not spellID then return end
    local e = FindByCast(spellID)
    if e and not e.noCasts then CD:Start(e, spellID) end
    ns.Fire("PLAYER_CAST", spellID)
end)

ns.RegisterUnitEvent("UNIT_AURA", "player", function() if ns.ready then CD:CheckLockouts() end end)
ns.On("LOGIN", function() CD:CheckLockouts() end)

local function SpellsChanged()
    CD:ScanSpellbook()
    CD:RefreshNames()
    CD:ResolveRanks()
    for _, e in pairs(CD.entries) do CD:RefreshIcon(e) end
    HUD:ApplyLayout()   -- newly learned abilities appear
    CD:Sync(true)
    CD:RefreshUsable()   -- new spell IDs after a rank-up
end
ns.RegisterEvent("SPELLS_CHANGED", function() if ns.ready then SpellsChanged() end end)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function() if ns.ready and CD.scanPending then SpellsChanged() end end)

-- charges change on use and while they recharge (an event this client does not
-- know is skipped quietly, see ns.RegisterEvent)
ns.RegisterEvent("SPELL_UPDATE_CHARGES", function()
    if not ns.ready then return end
    for _, e in pairs(CD.entries) do
        if e.ids and not e.itemID then CD:ShowCharges(e) end
    end
end)

for _, ev in ipairs({ "BAG_UPDATE", "BAG_UPDATE_COOLDOWN" }) do
    ns.RegisterEvent(ev, function() if ns.ready then CD:RefreshItems() end end)
end

ns.RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
    if not ns.ready then return end
    for _, e in pairs(CD.entries) do
        if e.itemID then
            CD:RefreshIcon(e)
            CD:MapItemCast(e)
        end
    end
end)

-- talents can grant abilities (Cold Blood ...)
for _, ev in ipairs({ "TRAIT_CONFIG_UPDATED", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED" }) do
    ns.RegisterEvent(ev, function() if ns.ready then HUD:ApplyLayout() end end)
end
