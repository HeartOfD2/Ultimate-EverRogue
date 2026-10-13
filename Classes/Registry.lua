-- ---------------------------------------------------------------------------
-- Class packs: what the addon knows about each class without any code. One
-- file per class (Classes/<Class>.lua) registers its pack:
--
--   ns.RegisterClass("ROGUE", {
--       comboPoints = true,                 -- shows the combo point part
--       comboPowerType = "ENERGY",           -- optional: dimmed unless the player has this power type (druid forms)
--       cooldowns = { { key, ids = { rank IDs }, dur = buff seconds (optional) } },
--       range = { { yards, spells = { IDs }, interact = CheckInteractDistance index } },
--   })
--
-- Spell IDs are rank 1; a spell only shows once the character knows it, and
-- every name comes from the client, so all of this works in any language.
-- WoW: Forever spell IDs can differ from Classic; extend the lists when a
-- spell turns out to report another ID in game. Code that belongs to a class
-- (trackers, macros, templates) is a module: Modules/<Name>/, docs/MODULE-BAUEN.md.
-- ---------------------------------------------------------------------------
local _, ns = ...

local PACKS = {}
ns.ClassData = PACKS

function ns.RegisterClass(token, pack)
    PACKS[token] = pack
    return pack
end

-- the pack of the player's class (empty lists for a class without one)
function ns.ClassPack()
    return PACKS[ns.playerClass or ""] or { cooldowns = {}, range = {} }
end
