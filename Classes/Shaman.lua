-- Shaman class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("SHAMAN", {
    cooldowns = {
        { key = "earthshock",    ids = { 8042, 8044, 8045, 8046, 10412, 10413, 10414 } },  -- Earth Shock
        { key = "flameshock",    ids = { 8050, 8052, 8053, 10447, 10448, 29228 } },  -- Flame Shock
        { key = "frostshock",    ids = { 8056, 8058, 10472, 10473 } },  -- Frost Shock
        { key = "grounding",     ids = { 8177 } },  -- Grounding Totem
        { key = "manatide",      ids = { 16190, 17354, 17359 } },  -- Mana Tide Totem
        { key = "naturesswift",  ids = { 16188 } },  -- Nature's Swiftness
        { key = "stormstrike",   ids = { 17364 } },  -- Stormstrike
        { key = "earthbind",     ids = { 2484 } },  -- Earthbind Totem
        { key = "stoneclaw",     ids = { 5730, 6390, 6391, 6392, 10427, 10428 } },  -- Stoneclaw Totem
        { key = "chainlight",    ids = { 421, 930, 2860, 10605 } },  -- Chain Lightning
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 403 },
    range = {
        { yards = 30, spells = { 403, 421 }, interact = 4 },   -- Lightning Bolt, Chain Lightning
        { yards = 20, spells = { 8042, 8050, 8056 } },         -- shocks
    },
})
