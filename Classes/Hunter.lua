-- Hunter class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("HUNTER", {
    cooldowns = {
        { key = "rapidfire",     ids = { 3045 }, dur = 15 },  -- Rapid Fire
        { key = "feigndeath",    ids = { 5384 } },  -- Feign Death
        { key = "disengage",     ids = { 781, 14272, 14273 } },  -- Disengage
        { key = "aimedshot",     ids = { 19434, 20900, 20901, 20902, 20903, 20904 } },  -- Aimed Shot
        { key = "arcaneshot",    ids = { 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287 } },  -- Arcane Shot
        { key = "multishot",     ids = { 2643 } },  -- Multi-Shot
        { key = "concussive",    ids = { 5116 } },  -- Concussive Shot
        { key = "scattershot",   ids = { 19503 } },  -- Scatter Shot
        { key = "intimidation",  ids = { 19577 } },  -- Intimidation
        { key = "bestialwrath",  ids = { 19574 }, dur = 18 },  -- Bestial Wrath
        { key = "deterrence",    ids = { 19263 }, dur = 10 },  -- Deterrence
        { key = "counterattack", ids = { 19306, 20909, 20910 } },  -- Counterattack
        { key = "freezingtrap",  ids = { 1499, 14310, 14311 } },  -- Freezing Trap
        { key = "frosttrap",     ids = { 13809 } },  -- Frost Trap
        { key = "explosivetrap", ids = { 13813, 14316, 14317 } },  -- Explosive Trap
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 1978 },
    range = {
        { yards = 35, spells = { 75, 3044, 1978 }, interact = 4 },   -- Auto Shot, Arcane Shot, Serpent Sting
        { yards = 0,  spells = { 2973, 1495 } },                     -- Raptor Strike, Mongoose Bite
    },
})
