-- Warlock class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("WARLOCK", {
    cooldowns = {
        { key = "deathcoil",     ids = { 6789, 17925, 17926 } },  -- Death Coil
        { key = "howlofterror",  ids = { 5484, 17928 } },  -- Howl of Terror
        { key = "shadowburn",    ids = { 17877, 18867, 18868, 18869, 18870, 18871 } },  -- Shadowburn
        { key = "conflagrate",   ids = { 17962, 18930, 18931, 18932 } },  -- Conflagrate
        { key = "amplifycurse",  ids = { 18288 } },  -- Amplify Curse
        { key = "feldomination", ids = { 18708 } },  -- Fel Domination
        { key = "shadowward",    ids = { 6229, 11739, 11740, 28610 } },  -- Shadow Ward
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 686 },
    range = {
        { yards = 30, spells = { 686, 172, 348 }, interact = 4 },   -- Shadow Bolt, Corruption, Immolate
        { yards = 20, spells = { 6789, 5782 } },                    -- Death Coil, Fear
    },
})
