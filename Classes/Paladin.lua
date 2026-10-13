-- Paladin class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("PALADIN", {
    cooldowns = {
        { key = "divineshield",  ids = { 642, 1020 }, dur = 10 },  -- Divine Shield
        { key = "divineprot",    ids = { 498, 5573 }, dur = 6 },  -- Divine Protection
        { key = "blessingprot",  ids = { 1022, 5599, 10278 } },  -- Blessing of Protection
        { key = "layonhands",    ids = { 633, 2800, 10310 } },  -- Lay on Hands
        { key = "hammerjustice", ids = { 853, 5588, 5589, 10308 } },  -- Hammer of Justice
        { key = "hammerwrath",   ids = { 24275, 24274, 24239 } },  -- Hammer of Wrath
        { key = "consecration",  ids = { 26573, 20116, 20922, 20923, 20924 } },  -- Consecration
        { key = "exorcism",      ids = { 879, 5614, 5615, 10312, 10313, 10314 } },  -- Exorcism
        { key = "holyshock",     ids = { 20473, 20929, 20930 } },  -- Holy Shock
        { key = "repentance",    ids = { 20066 } },  -- Repentance
        { key = "divinefavor",   ids = { 20216 } },  -- Divine Favor
        { key = "freedom",       ids = { 1044 } },  -- Blessing of Freedom
        { key = "holyshield",    ids = { 20925, 20927, 20928 } },  -- Holy Shield
        { key = "judgement",     ids = { 20271 } },  -- Judgement
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 21084 },
    range = {
        { yards = 30, spells = { 879, 24275 }, interact = 4 },   -- Exorcism, Hammer of Wrath
        { yards = 10, spells = { 853, 20271 } },                 -- Hammer of Justice, Judgement
    },
})
