-- ---------------------------------------------------------------------------
-- Macro Manager: the category filter menu of the icon picker (two levels:
-- groups, then checkable categories; the menu reopens after each click).
-- Keys are the category names of the icon data. Inside a group the
-- ticked categories add up (swords or daggers), across groups they narrow down
-- (abilities and rogue = the rogue abilities).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, UI = ns.L, ns.UI
local IconFilter = ns.IconFilter

local GROUPS = {
    { name = L["General"], entries = {
        { "Ability", L["Abilities"] },
        { "Achievement", L["Achievements"] },
        { "Housing", L["Housing"] },
        { "Item", L["Items"] },
        { "Pet", L["Pets"] },
        { "Mount", L["Mounts"] },
        { "Alliance", L["Alliance"] },
        { "Horde", L["Horde"] },
        { "OtherFactions", L["Other factions"] },
    } },
    { name = L["Classes"], entries = {
        { "Warrior", L["Warrior"] },
        { "Paladin", L["Paladin"] },
        { "Hunter", L["Hunter"] },
        { "Rogue", L["Rogue"] },
        { "Priest", L["Priest"] },
        { "DeathKnight", L["Death Knight"] },
        { "Shaman", L["Shaman"] },
        { "Mage", L["Mage"] },
        { "Warlock", L["Warlock"] },
        { "Monk", L["Monk"] },
        { "Druid", L["Druid"] },
        { "DemonHunter", L["Demon Hunter"] },
        { "Evoker", L["Evoker"] },
    } },
    { name = L["Weapons"], entries = {
        { "Weapon", L["All weapons"] },
        { "WeaponTypeSword", L["Swords"] },
        { "WeaponTypeAxe", L["Axes"] },
        { "WeaponTypeMace", L["Maces"] },
        { "WeaponTypeDagger", L["Daggers"] },
        { "WeaponTypeFists", L["Fist weapons"] },
        { "WeaponTypePolearm", L["Polearms"] },
        { "WeaponTypeStaff", L["Staves"] },
        { "WeaponTypeWarglaive", L["Warglaives"] },
        { "WeaponTypeBow", L["Bows"] },
        { "WeaponTypeCrossbow", L["Crossbows"] },
        { "WeaponTypeGun", L["Guns"] },
        { "WeaponTypeWand", L["Wands"] },
        { "WeaponTypeThrown", L["Thrown"] },
        { "WeaponTypeAmmo", L["Ammunition"] },
    } },
    { name = L["Armor"], entries = {
        { "Armor", L["All armor"] },
        { "ClothArmor", L["Cloth"] },
        { "LeatherArmor", L["Leather"] },
        { "MailArmor", L["Mail"] },
        { "PlateArmor", L["Plate"] },
        { "Jewelry", L["Jewelry"] },
        { "InventorySlotShield", L["Shields"] },
        { "InventorySlotOffHand", L["Off-hands"] },
        { "InventorySlotTrinket", L["Trinkets"] },
        { "InventorySlotRing", L["Rings"] },
        { "InventorySlotNeck", L["Necklaces"] },
    } },
    { name = L["Equipment slots"], entries = {
        { "InventorySlotHead", L["Head"] },
        { "InventorySlotShoulders", L["Shoulders"] },
        { "InventorySlotChest", L["Chest"] },
        { "InventorySlotBack", L["Back"] },
        { "InventorySlotWrists", L["Wrists"] },
        { "InventorySlotHands", L["Hands"] },
        { "InventorySlotWaist", L["Waist"] },
        { "InventorySlotLegs", L["Legs"] },
        { "InventorySlotFeet", L["Feet"] },
        { "InventorySlotShirt", L["Shirts"] },
        { "InventorySlotTabard", L["Tabards"] },
    } },
    { name = L["Magic"], entries = {
        { "ArcaneMagic", L["Arcane"] },
        { "FireMagic", L["Fire"] },
        { "FrostMagic", L["Frost"] },
        { "NatureMagic", L["Nature"] },
        { "HolyMagic", L["Holy"] },
        { "ShadowMagic", L["Shadow"] },
        { "FelMagic", L["Fel"] },
        { "VoidMagic", L["Void"] },
    } },
    { name = L["Professions"], entries = {
        { "Professions", L["All professions"] },
        { "Alchemy", L["Alchemy"] },
        { "Blacksmithing", L["Blacksmithing"] },
        { "Enchanting", L["Enchanting"] },
        { "Engineering", L["Engineering"] },
        { "Herbalism", L["Herbalism"] },
        { "Inscription", L["Inscription"] },
        { "Jewelcrafting", L["Jewelcrafting"] },
        { "Leatherworking", L["Leatherworking"] },
        { "Mining", L["Mining"] },
        { "Skinning", L["Skinning"] },
        { "Tailoring", L["Tailoring"] },
        { "Cooking", L["Cooking"] },
        { "Fishing", L["Fishing"] },
        { "FirstAid", L["First Aid"] },
        { "Archaeology", L["Archaeology"] },
    } },
    { name = L["Consumables"], entries = {
        { "Potion", L["Potions"] },
        { "Food", L["Food"] },
        { "Drink", L["Drinks"] },
        { "TradeGoods", L["Trade goods"] },
    } },
}

-- selected categories: { [key] = true }; shared with the search
IconFilter.selected = {}

-- which group a category belongs to: the groups narrow each other down, inside one they add up
for gi, g in ipairs(GROUPS) do
    for _, e in ipairs(g.entries) do IconFilter.groupOf[e[1]] = gi end
end

local function CountIn(group)
    local n = 0
    for _, e in ipairs(group.entries) do
        if IconFilter.selected[e[1]] then n = n + 1 end
    end
    return n
end

function IconFilter.HasSelection() return next(IconFilter.selected) ~= nil end

-- opts.point/relPoint/x/y as for UI.OpenMenu; onChange runs after every change
local OpenGroup
local function OpenTop(anchor, onChange, opts)
    local items = {}
    for _, g in ipairs(GROUPS) do
        local n = CountIn(g)
        items[#items + 1] = {
            label = g.name, desc = n > 0 and tostring(n) or ">", checked = n > 0,
            fn = function() OpenGroup(anchor, g, onChange, opts) end,
        }
    end
    items[#items + 1] = {
        label = L["Reset filter"], divider = true,
        fn = function()
            IconFilter.selected = {}
            onChange()
        end,
    }
    UI.OpenMenu(anchor, items, opts)
end

OpenGroup = function(anchor, group, onChange, opts)
    local items = { { label = "< " .. L["Back"], fn = function() OpenTop(anchor, onChange, opts) end } }
    for i, e in ipairs(group.entries) do
        items[#items + 1] = {
            label = e[2], checked = IconFilter.selected[e[1]], divider = i == 1,
            fn = function()
                IconFilter.selected[e[1]] = (not IconFilter.selected[e[1]]) or nil
                onChange()
                OpenGroup(anchor, group, onChange, opts)
            end,
        }
    end
    UI.OpenMenu(anchor, items, opts)
end

function IconFilter.OpenMenu(anchor, onChange, opts)
    opts = opts or {}
    OpenTop(anchor, onChange, opts)
end
