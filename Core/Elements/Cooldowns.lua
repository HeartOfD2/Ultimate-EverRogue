-- ---------------------------------------------------------------------------
-- Cooldown bars: up to five rows of icons (seven per row) for the class
-- package, your own race's racials, module entries (e.g. Slice and Dice) and
-- items or spells you add yourself (potions, bandages, trinkets ...).
-- Swipes start from cast events (their spell IDs are not secret) and take
-- the game's cooldown through the secret-safe Duration path where it exists.
-- Abilities with a buff (Sprint, Evasion ...) first count down the buff with
-- an accent border, then show the real cooldown.
--
-- Split by responsibility, all parts extend the public table ns.Cooldowns:
--   Cooldowns.lua        entries and their icons (this file)
--   CooldownLayout.lua   order, bars, placement on the frame
--   CooldownSwipes.lua   what the game knows about a cooldown; casts, lockouts
--   CooldownSpellbook.lua  abilities found in the spellbook
--   CooldownCustom.lua   items and spells you add yourself
--   CooldownRanks.lua    spell ranks and override spells
--   CooldownEvents.lua   game events
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, T = ns.L, ns.T
local HUD = ns.HUD

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local CD = {
    entries = {},      -- key -> entry
    byCast = {},       -- spellID -> entry
    byName = {},       -- localized spell name -> entry
    specials = {},     -- module entries, in registration order
    BARS = 20,         -- the most bars a character can have (HUD elements cd1 .. cd20)
    IGAP = 4,          -- gap between icons
}
ns.Cooldowns = CD

function CD.Settings() return ns.Char().cooldowns end
local Settings = CD.Settings

-- look of all cooldown bars (shared style "cooldowns")
function CD.IconSize() return HUD:Get("cooldowns", "iconSize") or 28 end

-- icons per bar: as many as fit in one row of the frame
function CD.PerBar()
    return math.max(1, math.floor((HUD.WIDTH + CD.IGAP) / (CD.IconSize() + CD.IGAP)))
end

-- ---------------------------------------------------------------------------
-- Icons. Every entry runs a small state machine:
--   ready      plain icon, usable
--   buff       its buff is running (accent frame, the swipe counts the buff)
--   cooldown   the game's cooldown is running
-- When a cooldown ends, an accent ring fades out around the icon. Optional
-- looks: grey while running, an accent outline while ready (CD:ShowLook).
-- ---------------------------------------------------------------------------
function CD.Paint(e)
    local o, st = e.frame, e.state
    local c = (st == "buff") and T.accent or HUD:EdgeColor("cd" .. CD:Bar(e.key))
    o.border:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    o.halo:SetShown(st == "buff")
    -- optional: ready icons step back, running ones stand out
    if e.kind ~= "special" then
        o:SetAlpha((st == "ready" and HUD:Get("cooldowns", "dimReady")) and 0.4 or 1)
    end
end

-- to change state from outside (modules driving their own entry)
function CD.SetState(e, st)
    e.state = st
    e.frame.running = (st ~= "ready")
    CD.Paint(e)
    CD:ShowLook(e)   -- grey / ready outline (CooldownSwipes.lua)
end

local function Finish(e)
    if e.state == "buff" and not e.itemID then
        -- the buff is over: now the ability's own cooldown
        CD.SetState(e, "cooldown")
        CD.Apply(e, e.castID)   -- CooldownSwipes.lua
        return
    end
    local was = e.state
    e.lockoutMode = nil
    CD.SetState(e, "ready")
    if was == "cooldown" then e.frame.readyRing:Play() end
end

local function MakeIcon(entry)
    local o = CreateFrame("Frame", nil, HUD.frame)
    o:SetSize(CD.IconSize(), CD.IconSize())
    o.halo = o:CreateTexture(nil, "BACKGROUND", nil, -8)
    o.halo:SetPoint("TOPLEFT", -3, 3)
    o.halo:SetPoint("BOTTOMRIGHT", 3, -3)
    ns.Color(o.halo, T.accent, 0.25)
    o.border = o:CreateTexture(nil, "BACKGROUND", nil, -7)
    o.border:SetPoint("TOPLEFT", -1, 1)
    o.border:SetPoint("BOTTOMRIGHT", 1, -1)
    o.icon = o:CreateTexture(nil, "ARTWORK")
    o.icon:SetAllPoints()
    o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    o.sheen = o:CreateTexture(nil, "ARTWORK", nil, 1)
    o.sheen:SetPoint("TOPLEFT")
    o.sheen:SetPoint("TOPRIGHT")
    o.sheen:SetHeight(1)
    o.sheen:SetColorTexture(1, 1, 1, 0.12)
    o.cd = CreateFrame("Cooldown", nil, o, "CooldownFrameTemplate")
    o.cd:SetAllPoints()
    o.cd:SetHideCountdownNumbers(false)
    o.cd:SetDrawEdge(true)
    if o.cd.SetSwipeColor then o.cd:SetSwipeColor(0, 0, 0, 0.75) end
    if ns.FONT and o.cd.GetCountdownFontString then
        local ok, fs = pcall(o.cd.GetCountdownFontString, o.cd)
        if ok and fs then ns.ApplyFont(fs, 13, "OUTLINE") end
    end
    -- charges of a charge spell (CooldownSwipes.lua), bottom right
    o.charges = ns.Text(o, 12, "OUTLINE")
    o.charges:SetPoint("BOTTOMRIGHT", -2, 2)
    -- cast count (CooldownUsable.lua), bottom left
    o.castCount = ns.Text(o, 12, "OUTLINE")
    o.castCount:SetPoint("BOTTOMLEFT", 2, 2)
    -- short countdowns ("2m", then seconds) fit a small icon better than "1:47"
    if o.cd.SetCountdownAbbrevThreshold then pcall(o.cd.SetCountdownAbbrevThreshold, o.cd, 60) end
    -- ready ring: an accent outline just outside the icon that fades away
    local ring = CreateFrame("Frame", nil, o)
    ring:SetPoint("TOPLEFT", -3, 3)
    ring:SetPoint("BOTTOMRIGHT", 3, -3)
    ring:SetFrameLevel(o.cd:GetFrameLevel() + 3)
    ns.Skin(ring, { 0, 0, 0, 0 }, T.accent)
    ring:SetAlpha(0)
    local fade = ring:CreateAnimationGroup()
    local a = fade:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0)
    a:SetDuration(0.9)
    a:SetSmoothing("OUT")
    o.readyRing = fade
    -- ready outline (style "readyGlow"): stays while the ability is ready.
    -- Its alpha may be a secret curve value, so it is never read back.
    local glow = CreateFrame("Frame", nil, o)
    glow:SetPoint("TOPLEFT", -2, 2)
    glow:SetPoint("BOTTOMRIGHT", 2, -2)
    glow:SetFrameLevel(o.cd:GetFrameLevel() + 2)
    ns.Skin(glow, { 0, 0, 0, 0 }, T.accent)
    glow:SetAlpha(0)
    o.glow = glow
    o.cd:SetScript("OnCooldownDone", function()
        if entry.OnCooldownDone then return entry:OnCooldownDone(o) end
        Finish(entry)
    end)
    o:Hide()
    o.entry = entry
    entry.frame = o
    entry.state = "ready"
    CD.Paint(entry)
    CD:ShowLook(entry)
    return o
end

-- the module side (Slice and Dice) uses this for its active look
function CD.SetActive(o, on)
    if o.entry then
        o.entry.state = on and "buff" or "ready"
        CD.Paint(o.entry)
    end
end

-- ---------------------------------------------------------------------------
-- Entries
-- ---------------------------------------------------------------------------
function CD.Add(e)
    CD.entries[e.key] = e
    if not e.frame then MakeIcon(e) end
    if e.ids and not e.noCasts then
        for _, id in ipairs(e.ids) do CD.byCast[id] = e end
    end
    return e
end

function CD:RefreshIcon(e)
    local tex
    if e.itemID then tex = ns.ItemIcon(e.itemID)
    elseif e.GetIcon then tex = e:GetIcon()
    elseif e.ids and e.ids[1] then tex = ns.SpellIcon(CD:SpellID(e)) end
    e.frame.icon:SetTexture(tex or FALLBACK_ICON)
end

-- module entries (e.g. Slice and Dice): def.key, def.ids, def.IsAvailable,
-- def.GetName, def.noCasts (the module drives the icon itself)
function CD:RegisterSpecial(def)
    def.kind = "special"
    table.insert(self.specials, def)
    CD.Add(def)
    self:RefreshIcon(def)
    return def
end

function CD:EntryName(e)
    if e.GetName then return e:GetName() end
    if e.itemID then return ns.ItemName(e.itemID) or (L["Item"] .. " " .. e.itemID) end
    return ns.SpellName(e.ids and e.ids[1]) or (L["Spell"] .. " " .. tostring(e.ids and e.ids[1]))
end

-- can it show at all: items always, specials ask, spells once learned
function CD:IsAvailable(e)
    if e.itemID then return true end
    if e.IsAvailable then return e:IsAvailable() and true or false end
    return ns.KnowsAny(e.ids)
end

-- builds the class, racial and custom entries (class/race are known from login)
local built = false
function CD:Build()
    if not built then
        built = true
        for _, s in ipairs(ns.ClassPack().cooldowns or {}) do
            CD.Add({ key = s.key, ids = s.ids, dur = s.dur, lockout = s.lockout, kind = "class" })
        end
        for _, s in ipairs(ns.Racials) do
            CD.Add({ key = s.key, ids = s.ids, dur = s.dur, kind = "racial" })
        end
    end
    for _, key in ipairs(Settings().custom) do self:CreateCustom(key) end
    -- custom entries no longer in the list (after a reset) go away
    for key, e in pairs(self.entries) do
        if e.kind == "custom" and not ns.IndexOf(Settings().custom, key) then self:DropCustom(key) end
    end
    self:RefreshNames()
    for _, e in pairs(self.entries) do self:RefreshIcon(e) end
end

-- localized names of all spell entries, so a cast reporting another ID than
-- the spellbook (racials on this client) still finds its icon
function CD:RefreshNames()
    wipe(self.byName)
    for _, e in pairs(self.entries) do
        if e.ids and not e.noCasts and not e.itemID then
            local n = ns.SpellName(e.ids[1])
            if n then self.byName[n] = e end
        end
    end
end
