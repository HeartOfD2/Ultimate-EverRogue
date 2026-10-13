-- Priest class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("PRIEST", {
    cooldowns = {
        { key = "psychicscream", ids = { 8122, 8124, 10888, 10890 } },  -- Psychic Scream
        { key = "fade",          ids = { 586, 9578, 9579, 9592, 10941, 10942 } },  -- Fade
        { key = "innerfocus",    ids = { 14751 } },  -- Inner Focus
        { key = "powerinfusion", ids = { 10060 }, dur = 15 },  -- Power Infusion
        { key = "silence",       ids = { 15487 } },  -- Silence
        { key = "desperate",     ids = { 13908, 19236, 19238, 19240, 19241, 19242, 19243 } },  -- Desperate Prayer
        { key = "mindblast",     ids = { 8092, 8102, 8103, 8104, 8105, 8106, 10945, 10946, 10947 } },  -- Mind Blast
        { key = "fearward",      ids = { 6346 } },  -- Fear Ward
        -- no cooldown of its own: Weakened Soul (15 s) blocks it
        { key = "pwshield",      ids = { 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901 },   -- Power Word: Shield
          lockout = { aura = 6788, dur = 15 } },   -- Weakened Soul
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 585 },
    range = {
        { yards = 30, spells = { 585, 589, 8092 }, interact = 4 },   -- Smite, Shadow Word: Pain, Mind Blast
    },
})
