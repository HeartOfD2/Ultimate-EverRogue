-- ---------------------------------------------------------------------------
-- Cooldown bars: range and usability tint (style "tint"), the cast count on
-- spell icons (style "castCount") and the shared potion cooldown.
-- Events only, no polling. IsSpellUsable and the range event carry plain
-- booleans; a secret answer is
-- ignored and the icon keeps its normal colors.
-- ---------------------------------------------------------------------------
local _, ns = ...
local T = ns.T
local HUD = ns.HUD
local CD = ns.Cooldowns

-- spell entries only: items, module entries and lockouts have no spell to ask
local function Askable(e)
    return e.ids and not e.itemID and e.kind ~= "special" and not e.lockout and CD:IsAvailable(e)
end

local function Plain(v) return not ns.IsSecret(v) end

local rangeOn = {}   -- spellID -> true while the game checks its range

-- the tint of one entry: out of range (red), too little power (blue),
-- otherwise not usable (grey); nothing known = the plain icon
local function Wanted(e)
    if not HUD:Get("cooldowns", "tint") or not Askable(e) then return end
    if e.outOfRange then return T.hudAlert end
    local id = CD:SpellID(e)
    if not (id and C_Spell and C_Spell.IsSpellUsable) then return end
    local ok, usable, noPower = pcall(C_Spell.IsSpellUsable, id)
    if not ok or usable == nil or not Plain(usable) or not Plain(noPower) then return end
    if noPower then return T.hudNoPower end
    if not usable then return T.hudUnusable end
end

function CD:ShowTint(e)
    local c = Wanted(e) or { 1, 1, 1, 1 }
    pcall(e.frame.icon.SetVertexColor, e.frame.icon, c[1], c[2], c[3], 1)
end

-- the cast count (bottom left): a number the game counts, e.g. reagents. A
-- secret count goes unread through TruncateWhenZero (empty when zero).
function CD:ShowCastCount(e)
    local fs = e.frame.castCount
    if not fs then return end
    local text = ""
    if HUD:Get("cooldowns", "castCount") and Askable(e) and C_Spell and C_Spell.GetSpellCastCount then
        local ok, n = pcall(C_Spell.GetSpellCastCount, CD:SpellID(e))
        if ok and n ~= nil then
            if C_StringUtil and C_StringUtil.TruncateWhenZero then
                local ok2, s = pcall(C_StringUtil.TruncateWhenZero, n)
                if ok2 and s then text = s end
            elseif Plain(n) and type(n) == "number" and n > 0 then
                text = tostring(n)
            end
        end
    end
    pcall(fs.SetText, fs, text)
end

-- range checks follow the setting and the spell IDs (ranks change them)
local function SyncRange()
    local wanted = {}
    if HUD:Get("cooldowns", "tint") then
        for _, e in pairs(CD.entries) do
            if Askable(e) then wanted[CD:SpellID(e)] = true end
        end
    end
    if not (C_Spell and C_Spell.EnableSpellRangeCheck) then return end
    for id in pairs(rangeOn) do
        if not wanted[id] then
            pcall(C_Spell.EnableSpellRangeCheck, id, false)
            rangeOn[id] = nil
        end
    end
    for id in pairs(wanted) do
        if not rangeOn[id] then
            if pcall(C_Spell.EnableSpellRangeCheck, id, true) then rangeOn[id] = true end
        end
    end
    for _, e in pairs(CD.entries) do
        if not (Askable(e) and rangeOn[CD:SpellID(e)]) then e.outOfRange = nil end
    end
end

function CD:RefreshUsable()
    SyncRange()
    for _, e in pairs(self.entries) do
        if e.frame then
            self:ShowTint(e)
            self:ShowCastCount(e)
        end
    end
end

ns.RegisterEvent("SPELL_RANGE_CHECK_UPDATE", function(_, spellID, inRange, checks)
    if not ns.ready or not Plain(spellID) or not Plain(inRange) or not Plain(checks) then return end
    for _, e in pairs(CD.entries) do
        if Askable(e) and CD:SpellID(e) == spellID then
            e.outOfRange = (checks and not inRange) and true or nil
            CD:ShowTint(e)
        end
    end
end)

-- usability and counts change with power, reagents and procs; power comes
-- often, so it is bundled into one pass
ns.RegisterEvent("SPELL_UPDATE_USABLE", function() if ns.ready then CD:RefreshUsable() end end)
local pending
ns.RegisterUnitEvent("UNIT_POWER_UPDATE", "player", function()
    if not ns.ready or pending or not HUD:Get("cooldowns", "tint") then return end
    pending = true
    C_Timer.After(0.05, function()
        pending = false
        for _, e in pairs(CD.entries) do
            if e.frame then CD:ShowTint(e) end
        end
    end)
end)

-- ---------------------------------------------------------------------------
-- Potions share one cooldown. Where the game gives an item entry no cooldown
-- of its own, the last spell that started the shared category supplies it:
-- the (maybe secret) ID goes unchanged to the Duration API, never compared.
-- ---------------------------------------------------------------------------
function CD.CategoryObject(e)
    if not (e.itemID and e.useSpell and C_Spell and C_Spell.GetSpellCooldown
        and C_Spell.GetLastCategoryCooldownSource and C_Spell.GetSpellCooldownDuration) then return end
    local ok, info = pcall(C_Spell.GetSpellCooldown, e.useSpell)
    if not ok or type(info) ~= "table" or info.activeCategory == nil then return end
    local ok2, spellID = pcall(C_Spell.GetLastCategoryCooldownSource, info.activeCategory)
    if not ok2 or spellID == nil then return end
    local ok3, d = pcall(C_Spell.GetSpellCooldownDuration, spellID)
    if ok3 and d then return d end
end
