local _, ns = ...

-- lockouts: debuffs that block an ability or item although it has no cooldown
--   aura = the debuff's spell ID, dur = its length when the game hides it
ns.Lockouts = {
    bandage = { aura = 11196, dur = 60 },   -- Recently Bandaged
}
-- bandages of Classic (item IDs); others are recognized by their item subclass
ns.BANDAGES = {}
for _, id in ipairs({ 1251, 2581, 3530, 3531, 6450, 6451, 8544, 8545, 14529, 14530, 19307,
                      19066, 19067, 19068, 20065, 20066, 20067, 20232, 20234, 20235, 20237, 20243, 20244 }) do
    ns.BANDAGES[id] = true
end
