-- ---------------------------------------------------------------------------
-- Cooldown swipes: what the game knows about a cooldown, without touching
-- secrets; casts, lockout debuffs and the sync at login.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L = ns.L
local HUD = ns.HUD
local CD = ns.Cooldowns

-- ---------------------------------------------------------------------------
-- Swipes: what the game knows about a cooldown, without touching secrets
-- ---------------------------------------------------------------------------
-- the game's cooldown of a spell or item as (kind, a, b):
--   "object", durationObject      secret-safe, straight to the cooldown frame
--   "times", start, duration      plain or secret numbers
local function Source(e, id)
    if e.itemID then
        local getter = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
        if getter then
            local ok, start, dur = pcall(getter, e.itemID)
            -- (a secret start is fine; only a plain nil means "no data")
            if ok and (ns.IsSecret(start) or start ~= nil) then return "times", start, dur end
        end
        -- the game gave this item nothing: the shared potion cooldown (CooldownUsable.lua)
        local d = CD.CategoryObject and CD.CategoryObject(e)
        if d then return "object", d end
        return nil
    end
    id = id or CD:SpellID(e)
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local ok, d = pcall(C_Spell.GetSpellCooldownDuration, id)
        if ok and d then return "object", d end
    end
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(id)
        if info then return "times", info.startTime, info.duration end
    elseif GetSpellCooldown then
        return "times", GetSpellCooldown(id)
    end
end

-- true when the numbers are known to describe nothing (or only the global cooldown)
local function Idle(start, dur)
    if ns.IsSecret(start) or ns.IsSecret(dur) then return false end
    return type(dur) ~= "number" or dur <= 1.5 or (start or 0) <= 0
end

local function Apply(e, id)
    local cd = e.frame.cd
    local kind, a, b = Source(e, id)
    if kind == "object" and cd.SetCooldownFromDurationObject then
        return pcall(cd.SetCooldownFromDurationObject, cd, a)
    end
    if kind == "times" then
        if Idle(a, b) then
            if e.itemID and e.state ~= "ready" then
                if cd.Clear then cd:Clear() end
                CD.SetState(e, "ready")
            end
            return false
        end
        return pcall(cd.SetCooldown, cd, a, b)
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Look: grey while a cooldown runs (style "desaturate"), an accent outline
-- while ready (style "readyGlow"). While the swipe runs, the game's remaining
-- share goes through two curves straight to SetDesaturation and SetAlpha; in
-- combat it is secret, so it is never compared, stored or read back.
-- Without the curve API, and for items and lockouts, our own state decides.
-- ---------------------------------------------------------------------------
local curves   -- nil: not built yet, false: no curve API
local function Curves()
    if curves == nil then
        curves = false
        local CU = C_CurveUtil
        if CU and CU.CreateCurve then
            -- input: remaining share of the cooldown (1 .. 0), ready = 0
            local ok, grey, ready = pcall(function()
                local g, r = CU.CreateCurve(), CU.CreateCurve()
                g:AddPoint(0, 0)
                g:AddPoint(0.001, 1)
                r:AddPoint(0, 1)
                r:AddPoint(0.001, 0)
                return g, r
            end)
            if ok and grey and ready then curves = { grey = grey, ready = ready } end
        end
    end
    return curves or nil
end

-- the curve values of the game's cooldown, or nothing when it cannot tell
local function GameLook(e)
    if e.itemID or e.lockout then return end
    local c = Curves()
    if not c then return end
    local kind, d = Source(e, e.state == "cooldown" and e.castID or nil)
    if kind ~= "object" then return end
    local ok1, grey = pcall(d.EvaluateRemainingPercent, d, c.grey)
    local ok2, ready = pcall(d.EvaluateRemainingPercent, d, c.ready)
    if ok1 and ok2 and grey ~= nil and ready ~= nil then return grey, ready end
end

function CD:ShowLook(e)
    local o = e.frame
    if not o.glow then return end
    local grey, ready = 0, 0
    if e.kind == "special" then
        -- module entries tell for themselves (Slice and Dice: combo points)
        if e.IsReady and e:IsReady() then ready = 1 end
    elseif e.state ~= "buff" then
        if not o.running then
            ready = 1
        else
            local g, r = GameLook(e)
            if g ~= nil then grey, ready = g, r else grey = 1 end
        end
    end
    if not HUD:Get("cooldowns", "desaturate") then grey = 0 end
    if not HUD:Get("cooldowns", "readyGlow") then ready = 0 end
    if o.icon.SetDesaturation then pcall(o.icon.SetDesaturation, o.icon, grey) end
    pcall(o.glow.SetAlpha, o.glow, ready)
end

-- lockout debuffs (Recently Bandaged ...): the swipe follows the debuff;
-- where the game hides it, our own timer of its known length
local function ShowLockout(e, fromCast)
    local cd = e.frame.cd
    local kind, a, b = ns.ReadPlayerAura({ e.lockout.aura })
    if kind == "exact" then
        CD.SetState(e, "cooldown")
        cd:SetCooldown(a, b)
        e.lockoutMode = "exact"
    elseif kind == "object" and cd.SetCooldownFromDurationObject and pcall(cd.SetCooldownFromDurationObject, cd, a) then
        CD.SetState(e, "cooldown")
        e.lockoutMode = "object"
    elseif kind == "none" then
        if e.state ~= "ready" and e.lockoutMode ~= "timer" then
            if cd.Clear then cd:Clear() end
            CD.SetState(e, "ready")
        end
    elseif fromCast then
        CD.SetState(e, "cooldown")
        cd:SetCooldown(GetTime(), e.lockout.dur)
        e.lockoutMode = "timer"
    end
end

-- debuffs can also come from elsewhere (someone else bandages you)
function CD:CheckLockouts()
    for _, e in pairs(self.entries) do
        if e.lockout and self:IsAvailable(e) and e.lockoutMode ~= "timer" then ShowLockout(e, false) end
    end
end

-- charges of a charge spell: the count shows on the icon. Assumed plain
-- (Wiki: maxCharges is never secret; currentCharges not confirmed yet). A
-- secret count is still passed on to the text and reported once in the console.
local chargesReported = {}
function CD:ShowCharges(e)
    local o = e.frame
    local id = CD:SpellID(e)
    local info = id and C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(id)
    local max = info and info.maxCharges
    if not info or ns.IsSecret(max) or type(max) ~= "number" or max <= 1 then
        o.charges:SetText("")
        return
    end
    local cur = info.currentCharges
    if ns.IsSecret(cur) and not chargesReported[id] then
        chargesReported[id] = true
        ns.Print(L["Charges of spell %d are secret; please report this on CurseForge."], id)
    end
    pcall(o.charges.SetText, o.charges, cur)
end

-- a cast of this entry's spell
function CD:Start(e, id)
    e.castID = id
    if e.lockout then
        -- a moment later the debuff is on the player
        C_Timer.After(0.1, function() ShowLockout(e, true) end)
        return
    end
    -- a moment later the game has registered the cooldown
    C_Timer.After(0.05, function()
        if e.dur then
            CD.SetState(e, "buff")
            e.frame.cd:SetCooldown(GetTime(), e.dur)   -- the buff time: our own plain numbers
        else
            CD.SetState(e, "cooldown")
            Apply(e, id)
        end
        if not e.itemID then CD:ShowCharges(e) end
        CD:ShowCastCount(e)
    end)
end

-- login and newly learned spells: hand every entry the game's current
-- cooldown; a cooldown frame with nothing to show stays empty
function CD:Sync(onlyNew)
    for _, e in pairs(self.entries) do
        if e.kind ~= "special" and not e.itemID and e.state == "ready" and self:IsAvailable(e) then
            if not onlyNew or not e.synced then
                e.synced = true
                if Apply(e) then e.frame.running = true end
                self:ShowLook(e)
            end
        end
    end
end

function CD.ItemSwipe(e)
    if e.lockout and e.state ~= "ready" then return end   -- the debuff decides
    if Apply(e) then CD.SetState(e, "cooldown") end
end

CD.Apply = Apply   -- also used by the icon state machine in Cooldowns.lua
