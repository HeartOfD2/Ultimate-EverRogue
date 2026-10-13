-- ---------------------------------------------------------------------------
-- Rogue module: default macro templates. {s:ID} = spell name from the client,
-- {p:MH} / {p:OH} = the poison for that hand. They show in the Templates page
-- while the module runs; the player's own edits are kept (Templates.lua seeds
-- each group once).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L = ns.L
local Rogue = ns.Rogue

Rogue:Templates({
    key = "rogue",
    title = L["ROGUE TEMPLATES"],
    groupName = L["Rogue"],
    hint = L["Rogue: {p:MH} {p:OH} poison"],   -- shown under the template editor
    Fill = function(body)
        return (body:gsub("{p:(%u%u)}", function(hand)
            local _, id = Rogue:FindPoison(Rogue:EffectiveKey(hand))
            return id and ("item:" .. id) or Rogue:PoisonName(Rogue:EffectiveKey(hand) or "instant")
        end))
    end,
    list = {
        { name = L["Stealth Opener"], desc = L["Stealth, then Cheap Shot"], body = "#showtooltip\n/cast [nostealth] {s:1784}; {s:1833}" },
        { name = L["Builder"], desc = L["Sinister Strike + auto attack"], body = "#showtooltip\n/startattack\n/cast {s:1752}" },
        { name = L["Gouge"], desc = L["Stops auto attack first"], body = "#showtooltip\n/stopattack\n/cast {s:1776}" },
        { name = L["Kick Mouseover"], desc = L["Mouseover, else target"], body = "#showtooltip {s:1766}\n/cast [@mouseover,harm,nodead][] {s:1766}" },
        { name = L["Blind Mouseover"], desc = L["Mouseover, else target"], body = "#showtooltip {s:2094}\n/cast [@mouseover,harm,nodead][] {s:2094}" },
        { name = L["Sap Mouseover"], desc = L["Mouseover, else target"], body = "#showtooltip {s:6770}\n/cast [@mouseover,harm,nodead][] {s:6770}" },
        { name = L["Distract Cursor"], desc = L["Lands at the mouse cursor"], body = "#showtooltip\n/cast [@cursor] {s:1725}" },
        { name = L["Vanish"], desc = L["Stops auto attack first"], body = "#showtooltip\n/stopattack\n/cast {s:1856}" },
        { name = L["Burst"], desc = L["Both trinkets + Adrenaline Rush"], body = "#showtooltip {s:13750}\n/use 13\n/use 14\n/cast {s:13750}" },
        { name = L["Poison MH"], desc = L["Apply main-hand poison"], body = "#showtooltip\n/use {p:MH}\n/use 16" },
        { name = L["Poison OH"], desc = L["Apply off-hand poison"], body = "#showtooltip\n/use {p:OH}\n/use 17" },
    },
})
