-- ---------------------------------------------------------------------------
-- Cooldown bars: spell ranks and override spells.
-- An entry lists every rank of its spell (own data: class packages, spellbook
-- scan). The icon, the swipe and the charges follow the highest learned rank;
-- a transformed spell (C_Spell.GetOverrideSpell) shows its override. The
-- entry's key never changes, so order, bar, hiding and switches stay put.
-- ---------------------------------------------------------------------------
local _, ns = ...
local CD = ns.Cooldowns

-- the highest learned rank of the list (rank IDs grow with the rank);
-- nothing learned yet: the first one, as before
local function TopRank(ids)
    local best
    for _, id in ipairs(ids) do
        if ns.IsKnown(id) and (not best or id > best) then best = id end
    end
    return best or ids[1]
end

-- what the spell is right now (transformed or not); never with a secret ID
local function Override(id)
    if not id or ns.IsSecret(id) then return id end
    if not (C_Spell and C_Spell.GetOverrideSpell) then return id end
    local ok, o = pcall(C_Spell.GetOverrideSpell, id)
    if ok and type(o) == "number" and not ns.IsSecret(o) and o > 0 then return o end
    return id
end

-- the spell ID the entry shows right now
function CD:SpellID(e)
    return e.activeID or (e.ids and e.ids[1])
end

-- works out rank and override of every spell entry; returns true when an
-- icon changed. Entries driven by a module (own icon) are left alone.
function CD:ResolveRanks()
    local changed = false
    for _, e in pairs(self.entries) do
        if e.ids and e.ids[1] and not e.itemID and not e.GetIcon then
            local base = TopRank(e.ids)
            local active = Override(base)
            if active ~= e.activeID then
                e.activeID = active
                e.synced = nil   -- the next sync hands over the new spell's cooldown
                changed = true
                if e.frame then self:RefreshIcon(e) end
            end
            if not e.noCasts then
                -- a cast reports the rank or the transformed spell
                self.byCast[base] = e
                self.byCast[active] = e
            end
        end
    end
    return changed
end

-- transformations happen without a spellbook change (forms, procs, talents)
local function Changed()
    if ns.ready and CD:ResolveRanks() then CD:Sync(true) end
end
ns.RegisterEvent("SPELL_UPDATE_ICON", Changed)
ns.RegisterEvent("UPDATE_SHAPESHIFT_FORM", Changed)
