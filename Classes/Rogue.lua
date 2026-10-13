-- Rogue class pack (see Registry.lua).
local _, ns = ...

ns.RegisterClass("ROGUE", {
    comboPoints = true,
    cooldowns = {
        { key = "evasion",       ids = { 5277 }, dur = 15 },  -- Evasion
        { key = "vanish",        ids = { 1856, 1857 } },  -- Vanish
        { key = "kick",          ids = { 1766, 1767, 1768, 1769 } },  -- Kick
        { key = "sprint",        ids = { 2983, 8696, 11305 }, dur = 15 },  -- Sprint
        { key = "bladeflurry",   ids = { 13877 }, dur = 15 },  -- Blade Flurry
        { key = "adrenaline",    ids = { 13750 }, dur = 15 },  -- Adrenaline Rush
        { key = "blind",         ids = { 2094 } },  -- Blind
        { key = "kidney",        ids = { 408, 8643 } },  -- Kidney Shot
        { key = "gouge",         ids = { 1776, 1777, 8629, 11285, 11286 } },  -- Gouge
        { key = "coldblood",     ids = { 14177 } },  -- Cold Blood
        { key = "ghoststrike",   ids = { 14278 } },  -- Ghostly Strike
        { key = "premeditation", ids = { 14183 } },  -- Premeditation
        { key = "preparation",   ids = { 14185 } },  -- Preparation
        { key = "riposte",       ids = { 14251 } },  -- Riposte
        { key = "feint",         ids = { 1966, 6768, 8637, 11303, 25302 } },  -- Feint
        { key = "distract",      ids = { 1725 } },  -- Distract
    },
    -- spells without a cooldown of their own that show the global cooldown (GCD bar)
    gcdRef = { 1752, 1758 },
    range = {
        { yards = 30, spells = { 2764, 2480, 7918, 7919 }, interact = 4 },   -- Throw, Shoot Bow/Gun/Crossbow
        { yards = 10, spells = { 2094, 6770 }, interact = 3 },               -- Blind, Sap
        { yards = 0,  spells = { 1752, 1776, 1766, 53 } },                   -- Sinister Strike, Gouge, Kick, Backstab
    },
})
