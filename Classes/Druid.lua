-- Druid class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("DRUID", {
    comboPoints = true,
    comboPowerType = "ENERGY",   -- the points only matter in Cat Form: dimmed in other forms
    cooldowns = {
        { key = "barkskin",      ids = { 22812 }, dur = 15 },  -- Barkskin
        { key = "innervate",     ids = { 29166 }, dur = 20 },  -- Innervate
        { key = "rebirth",       ids = { 20484, 20739, 20742, 20747, 20748 } },  -- Rebirth
        { key = "tranquility",   ids = { 740, 8918, 9862, 9863 } },  -- Tranquility
        { key = "naturesswift",  ids = { 17116 } },  -- Nature's Swiftness
        { key = "swiftmend",     ids = { 18562 } },  -- Swiftmend
        { key = "bash",          ids = { 5211, 6798, 8983 } },  -- Bash
        { key = "dash",          ids = { 1850, 9821 }, dur = 15 },  -- Dash
        { key = "tigersfury",    ids = { 5217 }, dur = 6 },  -- Tiger's Fury
        { key = "feralcharge",   ids = { 16979 } },  -- Feral Charge
        { key = "enrage",        ids = { 5229 } },  -- Enrage
        { key = "frenziedregen", ids = { 22842 }, dur = 10 },  -- Frenzied Regeneration
        { key = "challroar",     ids = { 5209 } },  -- Challenging Roar
        { key = "growl",         ids = { 6795 } },  -- Growl
        { key = "hurricane",     ids = { 16914, 17401, 17402 } },  -- Hurricane
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 5176 },
    range = {
        { yards = 30, spells = { 5176, 8921 }, interact = 4 },   -- Wrath, Moonfire
        { yards = 0,  spells = { 1082, 6807, 5221 } },           -- Claw, Maul, Shred
    },
})
