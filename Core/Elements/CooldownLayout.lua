-- ---------------------------------------------------------------------------
-- Cooldown bars: order, which bar, and placing the icons on the frame; the HUD
-- elements "cd1" .. "cd20" (as many are in use as the character has bars).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, HUD = ns.L, ns.HUD
local CD = ns.Cooldowns
local Settings, IGAP = CD.Settings, CD.IGAP

-- ---------------------------------------------------------------------------
-- Order and bars
-- ---------------------------------------------------------------------------
function CD:Order()
    local defaults = {}
    for _, s in ipairs(self.specials) do defaults[#defaults + 1] = s.key end
    for _, s in ipairs(ns.ClassPack().cooldowns or {}) do defaults[#defaults + 1] = s.key end
    for _, s in ipairs(ns.Racials) do
        if ns.KnowsAny(s.ids) then defaults[#defaults + 1] = s.key end
    end
    for _, k in ipairs(self.bookKeys) do defaults[#defaults + 1] = k end
    for _, k in ipairs(Settings().custom) do defaults[#defaults + 1] = k end
    local valid = {}
    for _, k in ipairs(defaults) do valid[k] = self.entries[k] ~= nil end
    local order, seen = {}, {}
    local saved = Settings().order
    if type(saved) == "table" then
        for _, k in ipairs(saved) do
            if valid[k] and not seen[k] then seen[k] = true order[#order + 1] = k end
        end
    end
    for _, k in ipairs(defaults) do
        if valid[k] and not seen[k] then seen[k] = true order[#order + 1] = k end
    end
    Settings().order = order
    return order
end

-- how many bars the character has: 0 to BARS, one by default
function CD.BarTotal()
    local n = Settings().bars
    if type(n) ~= "number" or n ~= n then return 1 end
    return math.max(0, math.min(CD.BARS, math.floor(n)))
end

-- the bar of an entry; a stored number beyond the last bar counts as the last one
function CD:Bar(key)
    local b = Settings().bar[key]
    if type(b) ~= "number" then b = 1 end
    return math.max(1, math.min(b, math.max(1, CD.BarTotal())))
end
-- spellbook finds are off until switched on, everything else on until switched off
local function IsBookKey(key) return key:sub(1, 5) == "book:" end
function CD:IsHidden(key)
    if IsBookKey(key) then return not Settings().shown[key] end
    return Settings().hidden[key] and true or false
end

-- counts toward a bar's limit: available and not switched off
function CD:IsShownEntry(e)
    return not self:IsHidden(e.key) and self:IsAvailable(e)
end

-- at most PerBar() icons per bar: what doesn't fit moves to the first bar with room
function CD:Normalize()
    local count, PER_BAR = {}, CD.PerBar()
    for _, k in ipairs(self:Order()) do
        local e = self.entries[k]
        if e and self:IsShownEntry(e) then
            local bar = self:Bar(k)
            if (count[bar] or 0) >= PER_BAR then
                for b = 1, CD.BarTotal() do
                    if (count[b] or 0) < PER_BAR then bar = b break end
                end
                Settings().bar[k] = (bar ~= 1) and bar or nil
            end
            count[bar] = (count[bar] or 0) + 1
        end
    end
    return count
end

function CD:BarCount(bar) return self:Normalize()[bar] or 0 end

-- sorted for the options list: by bar, then order
function CD:List()
    local count = self:Normalize()
    local list = {}
    for pos, k in ipairs(self:Order()) do
        local e = self.entries[k]
        local learnable = e and (e.kind == "class" or e.kind == "racial" or e.kind == "book")
        if e and (not e.IsRelevant or e:IsRelevant()) and not (learnable and not self:IsAvailable(e)) then
            e.pos, e.bar, e.shownEntry = pos, self:Bar(k), self:IsShownEntry(e)
            list[#list + 1] = e
        end
    end
    table.sort(list, function(a, b)
        if a.bar ~= b.bar then return a.bar < b.bar end
        return a.pos < b.pos
    end)
    return list, count
end

function CD:SetHidden(key, hidden)
    if IsBookKey(key) then
        Settings().shown[key] = (not hidden) or nil
    else
        Settings().hidden[key] = hidden and true or nil
    end
    HUD:ApplyLayout()
end

-- returns false + reason when the target bar is full
function CD:SetBar(key, bar)
    local e = self.entries[key]
    if not e then return false end
    if self:Bar(key) ~= bar and self:IsShownEntry(e) and self:BarCount(bar) >= CD.PerBar() then
        return false, L["Bar %d is full (%d cooldowns at most)."]:format(bar, CD.PerBar())
    end
    Settings().bar[key] = (bar ~= 1) and bar or nil
    HUD:ApplyLayout()
    return true
end

-- move within its own bar: swap with the nearest entry on the same bar
function CD:Move(key, dir)
    local order = self:Order()
    local i = ns.IndexOf(order, key)
    if not i then return end
    local bar, j = self:Bar(key), i + dir
    while order[j] and self:Bar(order[j]) ~= bar do j = j + dir end
    if not order[j] then return end
    order[i], order[j] = order[j], order[i]
    HUD:ApplyLayout()
end

-- ---------------------------------------------------------------------------
-- Adding and removing bars. Bars are numbered; taking one away renumbers the
-- ones behind it and moves its cooldowns to the neighbour bar.
-- ---------------------------------------------------------------------------
function CD:AddBar()
    local n = CD.BarTotal()
    if n >= CD.BARS then return false, L["Up to %d cooldown bars."]:format(CD.BARS) end
    ns.Char().layout.hidden["cd" .. (n + 1)] = nil   -- a new bar is on
    Settings().bars = n + 1
    HUD:ApplyLayout()
    return n + 1
end

function CD:RemoveBar(k)
    local n = CD.BarTotal()
    if k < 1 or k > n then return false end
    local bars = Settings().bar
    if n > 1 then
        local into = (k > 1) and (k - 1) or 2
        local keys = {}
        for key in pairs(self.entries) do keys[key] = true end
        for key in pairs(bars) do keys[key] = true end
        for key in pairs(keys) do
            local b = self:Bar(key)
            if b == k then b = into end
            if b > k then b = b - 1 end
            bars[key] = (b ~= 1) and b or nil
        end
    end
    -- the look and the on/off switch of the bars behind it move up with them
    local parts, hidden = ns.Char().style.parts, ns.Char().layout.hidden
    for i = k, n - 1 do
        parts["cd" .. i], hidden["cd" .. i] = parts["cd" .. (i + 1)], hidden["cd" .. (i + 1)]
    end
    parts["cd" .. n], hidden["cd" .. n] = nil, nil
    Settings().bars = n - 1
    HUD:ApplyLayout()
    return true
end

-- ---------------------------------------------------------------------------
-- HUD elements "cd1" .. "cd20": each places the icons of its own bar, centered
-- ---------------------------------------------------------------------------
local function PlaceBar(bar, y)
    CD:Normalize()
    local visible = {}
    for _, k in ipairs(CD:Order()) do
        local e = CD.entries[k]
        if e and CD:Bar(k) == bar then
            if CD:IsShownEntry(e) then visible[#visible + 1] = e else e.frame:Hide() end
        end
    end
    local ICON = CD.IconSize()
    local perRow = CD.PerBar()
    for i, e in ipairs(visible) do
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        local rowCount = math.min(perRow, #visible - row * perRow)
        local x0 = (HUD.WIDTH - (rowCount * ICON + (rowCount - 1) * IGAP)) / 2
        e.frame:ClearAllPoints()
        e.frame:SetPoint("TOPLEFT", HUD.frame, "TOPLEFT", x0 + col * (ICON + IGAP), y - row * (ICON + IGAP))
        e.frame:Show()
    end
    if #visible == 0 then return 0 end
    local rows = math.ceil(#visible / perRow)
    return rows * ICON + (rows - 1) * IGAP
end

local function HideBar(bar)
    for k, e in pairs(CD.entries) do
        if CD:Bar(k) == bar then e.frame:Hide() end
    end
end

HUD:RegisterSharedStyle("cooldowns", {
    iconSize = 28, numbers = true, dimReady = false, desaturate = true, readyGlow = false,
    tint = false, castCount = true,
}, function()
    local size, numbers = CD.IconSize(), HUD:Get("cooldowns", "numbers") ~= false
    for _, e in pairs(CD.entries) do
        e.frame:SetSize(size, size)
        e.frame.cd:SetHideCountdownNumbers(not numbers)
        CD.Paint(e)
        CD:ShowLook(e)
    end
    CD:RefreshUsable()   -- tint, range checks, cast counts (CooldownUsable.lua)
end)

HUD:OnEdges(function() for _, e in pairs(CD.entries) do CD.Paint(e) end end)

for b = 1, CD.BARS do
    HUD:Register({
        key = "cd" .. b, order = 60 + b,
        label = L["Cooldown bar %d"]:format(b),
        cooldownBar = b,
        IsRelevant = function() return b <= CD.BarTotal() end,
        IsAvailable = function() return b <= CD.BarTotal() end,
        Place = function(_, y) return PlaceBar(b, y) end,
        HideAll = function() HideBar(b) end,
    })
end
