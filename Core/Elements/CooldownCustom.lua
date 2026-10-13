-- ---------------------------------------------------------------------------
-- Cooldown bars: your own entries, "item:<id>" or "spell:<id>" (potions,
-- bandages, trinkets ...).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, HUD = ns.L, ns.HUD
local CD = ns.Cooldowns
local Settings = CD.Settings

function CD:CreateCustom(key)
    if self.entries[key] then return self.entries[key] end
    local kind, id = key:match("^(%a+):(%d+)$")
    id = tonumber(id)
    if not id then return end
    local e = { key = key, kind = "custom" }
    if kind == "item" then
        e.itemID = id
        local sub = ns.ItemSubclass(id)
        local class = C_Item and C_Item.GetItemInfoInstant and select(6, C_Item.GetItemInfoInstant(id))
        if ns.BANDAGES[id] or (class == 0 and sub == 7) then e.lockout = ns.Lockouts.bandage end
    else
        e.ids = { id }
    end
    CD.Add(e)
    local o = e.frame
    if e.itemID then
        o.countFrame = CreateFrame("Frame", nil, o)   -- the count sits above the swipe
        o.countFrame:SetAllPoints()
        o.countFrame:SetFrameLevel(o.cd:GetFrameLevel() + 2)
        o.count = ns.HudText(o.countFrame, 12, "OUTLINE")
        o.count:SetPoint("BOTTOMRIGHT", -1, 2)
        self:MapItemCast(e)
    end
    self:RefreshIcon(e)
    return e
end

-- the item's use effect is a spell: casting it restarts the swipe
function CD:MapItemCast(e)
    if not (e.itemID and C_Item and C_Item.GetItemSpell) then return end
    local ok, _, spellID = pcall(C_Item.GetItemSpell, e.itemID)
    if ok and spellID then
        self.byCast[spellID] = e
        e.useSpell = spellID
    end
end

function CD:DropCustom(key)
    local e = self.entries[key]
    if not e then return end
    e.frame:Hide()
    self.entries[key] = nil
    for id, x in pairs(self.byCast) do if x == e then self.byCast[id] = nil end end
end

-- text from the add box: link, "item:123", "spell:123", a number or a name
function CD:Parse(text)
    text = ns.Trim(text)
    if text == "" then return nil, L["Drag an item or spell here, shift-click its link, or type its name or ID."] end
    local id = text:match("|Hitem:(%d+)") or text:match("^[Ii]tem:(%d+)$")
    if id then return "item", tonumber(id) end
    id = text:match("|Hspell:(%d+)") or text:match("^[Ss]pell:(%d+)$")
    if id then return "spell", tonumber(id) end
    local name = ns.StripColors(text):gsub("^%[", ""):gsub("%]$", "")
    name = ns.Trim(name)
    local n = tonumber(name)
    if n then
        if C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(n) then return "item", n end
        if ns.SpellName(n) then return "spell", n end
        return nil, L["Nothing found with the ID %d."]:format(n)
    end
    -- by name: bags and gear first (localized names off the items), then spells
    local want, found = ns.Fold(name), nil
    ns.ForEachBagItem(function(itemID, itemName)
        if itemName and ns.Fold(itemName) == want then found = itemID return true end
    end)
    if found then return "item", found end
    for slot = 1, 19 do
        local equipped = ns.EquippedName(slot)
        if equipped and ns.Fold(equipped) == want then return "item", GetInventoryItemID("player", slot) end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(name)
        if info and info.spellID then return "spell", info.spellID end
    end
    return nil, L["\"%s\" was not found. Drag it in or shift-click it instead."]:format(name)
end

function CD:AddCustom(kind, id)
    local key = kind .. ":" .. id
    local list = Settings().custom
    if ns.IndexOf(list, key) then return nil, L["That one is already tracked."] end
    if kind == "spell" and self.byCast[id] then return nil, L["That spell is tracked already."] end
    list[#list + 1] = key
    local e = self:CreateCustom(key)
    self:RefreshItems()
    HUD:ApplyLayout()
    return e
end

function CD:RemoveCustom(key)
    local list = Settings().custom
    local i = ns.IndexOf(list, key)
    if i then table.remove(list, i) end
    self:DropCustom(key)
    Settings().bar[key], Settings().hidden[key] = nil, nil
    HUD:ApplyLayout()
end

function CD:RefreshItems()
    for _, e in pairs(self.entries) do
        if e.itemID then
            CD.ItemSwipe(e)
            local n = ns.ItemCount(e.itemID)
            e.frame.count:SetText(n > 0 and tostring(n) or "")
            e.frame.icon:SetDesaturated(n == 0)
            e.frame.icon:SetAlpha(n == 0 and 0.5 or 1)
        end
    end
end
