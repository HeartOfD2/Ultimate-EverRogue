-- Warrior class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("WARRIOR", {
    cooldowns = {
        { key = "charge",        ids = { 100, 6178, 11578 } },  -- Charge
        { key = "intercept",     ids = { 20252, 20616, 20617 } },  -- Intercept
        { key = "bloodrage",     ids = { 2687 } },  -- Bloodrage
        { key = "berserkerrage", ids = { 18499 }, dur = 10 },  -- Berserker Rage
        { key = "pummel",        ids = { 6552, 6554 } },  -- Pummel
        { key = "shieldbash",    ids = { 72, 1671, 1672 } },  -- Shield Bash
        { key = "overpower",     ids = { 7384, 7887, 11584, 11585 } },  -- Overpower
        { key = "shieldwall",    ids = { 871 }, dur = 10 },  -- Shield Wall
        { key = "recklessness",  ids = { 1719 }, dur = 15 },  -- Recklessness
        { key = "retaliation",   ids = { 20230 }, dur = 15 },  -- Retaliation
        { key = "deathwish",     ids = { 12292 }, dur = 30 },  -- Death Wish
        { key = "laststand",     ids = { 12975 } },  -- Last Stand
        { key = "sweeping",      ids = { 12328 } },  -- Sweeping Strikes
        { key = "mortalstrike",  ids = { 12294, 21551, 21552, 21553 } },  -- Mortal Strike
        { key = "bloodthirst",   ids = { 23881, 23892, 23893, 23894 } },  -- Bloodthirst
        { key = "shieldblock",   ids = { 2565 } },  -- Shield Block
        { key = "intimshout",    ids = { 5246 } },  -- Intimidating Shout
        { key = "taunt",         ids = { 355 } },  -- Taunt
        { key = "whirlwind",     ids = { 1680 } },  -- Whirlwind
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 772 },
    range = {
        { yards = 25, spells = { 100, 20252 }, interact = 4 },   -- Charge, Intercept
        { yards = 0,  spells = { 78, 772, 7384 } },              -- Heroic Strike, Rend, Overpower
    },
})
