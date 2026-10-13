-- Mage class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("MAGE", {
    cooldowns = {
        { key = "blink",         ids = { 1953 } },  -- Blink
        { key = "counterspell",  ids = { 2139 } },  -- Counterspell
        { key = "frostnova",     ids = { 122, 865, 6131, 10230 } },  -- Frost Nova
        { key = "fireblast",     ids = { 2136, 2137, 2138, 8412, 8413, 10197, 10199 } },  -- Fire Blast
        { key = "coneofcold",    ids = { 120, 8492, 10159, 10160, 10161 } },  -- Cone of Cold
        { key = "iceblock",      ids = { 11958 }, dur = 10 },  -- Ice Block
        { key = "coldsnap",      ids = { 12472 } },  -- Cold Snap
        { key = "evocation",     ids = { 12051 } },  -- Evocation
        { key = "arcanepower",   ids = { 12042 }, dur = 15 },  -- Arcane Power
        { key = "presence",      ids = { 12043 } },  -- Presence of Mind
        { key = "combustion",    ids = { 11129 } },  -- Combustion
        { key = "icebarrier",    ids = { 11426, 13031, 13032, 13033 } },  -- Ice Barrier
        { key = "blastwave",     ids = { 11113, 13018, 13019, 13020, 13021 } },  -- Blast Wave
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 133, 116 },
    range = {
        { yards = 30, spells = { 133, 116, 5143 }, interact = 4 },   -- Fireball, Frostbolt, Arcane Missiles
        { yards = 10, spells = { 122 } },                            -- Frost Nova
    },
})
