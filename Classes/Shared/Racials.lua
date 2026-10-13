local _, ns = ...

-- racial abilities (WoW: Forever IDs where known). Only the ones your own
-- character knows ever show. A racial can report another spell ID when cast
-- than in the spellbook, so the tracker also matches casts by name.
ns.Racials = {
    { key = "willtosurvive", ids = { 1259718 } },             -- Human
    { key = "perception",    ids = { 20600 }, dur = 20 },     -- Human
    { key = "stoneform",     ids = { 20594 }, dur = 8 },      -- Dwarf
    { key = "eluneslight",   ids = { 1259799 }, dur = 15 },   -- Night Elf
    { key = "shadowmeld",    ids = { 20580 } },               -- Night Elf
    { key = "escapeartist",  ids = { 20589 } },               -- Gnome
    { key = "eureka",        ids = { 1259812 } },             -- Gnome
    { key = "bloodfury",     ids = { 20572 }, dur = 15 },     -- Orc
    { key = "shattercurse",  ids = { 1299026 }, dur = 8 },    -- Orc
    { key = "willforsaken",  ids = { 7744 } },                -- Undead
    { key = "cannibalize",   ids = { 20577 } },               -- Undead
    { key = "warstomp",      ids = { 20549 } },               -- Tauren
    { key = "berserking",    ids = { 20554 }, dur = 10 },     -- Troll
    { key = "rapidregen",    ids = { 1260270 } },             -- Troll
}
