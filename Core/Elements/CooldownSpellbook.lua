-- ---------------------------------------------------------------------------
-- Cooldown bars: abilities with a cooldown that no package lists (new ones after
-- a patch, talents ...) are read from the spellbook with their base cooldown.
-- They join the list switched off; the class package stays the default set.
-- ---------------------------------------------------------------------------
local _, ns = ...
local CD = ns.Cooldowns

local MIN_BOOK_CD = 2000   -- ms; shorter is only the global cooldown

-- calls fn(spellID, name, isPassive) for every learned spellbook entry;
-- returns which API it used (nil: none)
function ns.ForEachSpellbookSpell(fn)
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell or 1
        local ok, lines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
        for line = 1, (ok and lines or 0) do
            local okL, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if okL and info and info.itemIndexOffset and info.numSpellBookItems then
                for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local okI, item = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
                    if okI and item and item.spellID and item.itemType == spellType then
                        fn(item.spellID, item.name, item.isPassive)
                    end
                end
            end
        end
        return "C_SpellBook"
    end
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
        for tab = 1, GetNumSpellTabs() do   -- lint:ignore (guarded fallback)
            local _, _, offset, count = GetSpellTabInfo(tab)   -- lint:ignore (guarded fallback)
            for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local kind, id = GetSpellBookItemInfo(i, "spell")
                if kind == "SPELL" and id then
                    local passive = IsPassiveSpell and IsPassiveSpell(i, "spell")
                    fn(id, ns.SpellName(id), passive)
                end
            end
        end
        return "GetSpellBookItemInfo"
    end
    return nil
end

CD.bookKeys = {}
-- in combat the base cooldowns can be secret: scan after the fight instead;
-- a secret answer outside combat keeps what was found before
function CD:ScanSpellbook()
    if not GetSpellBaseCooldown then return end
    if UnitAffectingCombat("player") then
        self.scanPending = true
        return
    end
    self.scanPending = nil
    -- names the packages already cover (any rank)
    local covered = {}
    for _, e in pairs(self.entries) do
        if e.kind ~= "book" and e.ids and not e.itemID then
            for _, id in ipairs(e.ids) do
                local n = ns.SpellName(id)
                if n then covered[n] = true end
            end
        end
    end
    local found, names, sawSecret = {}, {}, false
    self.bookMode = ns.ForEachSpellbookSpell(function(id, name, passive)
        if passive or not name or covered[name] then return end
        local ok, ms = pcall(GetSpellBaseCooldown, id)
        if ok and ns.IsSecret(ms) then sawSecret = true return end
        if not ok or type(ms) ~= "number" or ms < MIN_BOOK_CD then return end
        if not found[name] then
            found[name] = {}
            names[#names + 1] = name
        end
        table.insert(found[name], id)
    end)
    local before = sawSecret and { unpack(self.bookKeys) } or nil
    wipe(self.bookKeys)
    for _, name in ipairs(names) do
        local ids = found[name]
        table.sort(ids)
        local key = "book:" .. ids[1]
        local e = self.entries[key]
        if e then
            for _, id in ipairs(ids) do
                if not ns.IndexOf(e.ids, id) then table.insert(e.ids, id) end
            end
            table.sort(e.ids)
            CD.Add(e)
        else
            e = CD.Add({ key = key, ids = ids, kind = "book" })
            self:RefreshIcon(e)
            self.byName[name] = e
        end
        self.bookKeys[#self.bookKeys + 1] = key
    end
    for _, key in ipairs(before or {}) do
        if not ns.IndexOf(self.bookKeys, key) then self.bookKeys[#self.bookKeys + 1] = key end
    end
end
