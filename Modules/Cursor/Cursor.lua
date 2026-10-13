-- ---------------------------------------------------------------------------
-- Cursor module: a ring around the mouse pointer. For every class, on by default.
-- The two ring pictures are used under the MIT license (text in Media/Cursor/LICENSE.txt).
-- This file defines the module, its settings and the reset category; the ring
-- is drawn in Ring.lua and the settings page lives in Page.lua.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local Cursor = ns.NewModule("cursor", {
    title = L["Cursor"],
    desc = L["A ring around the mouse pointer."],
})
ns.Cursor = Cursor

Cursor.SIZE_MIN, Cursor.SIZE_MAX = 16, 48
Cursor.SHOWS = { "off", "always", "combat" }

Cursor.DEFAULTS = {
    show = "off",          -- off / always / combat
    hideInMenus = true,
    color = { 0, 0x6D / 255, 0x77 / 255 },   -- { r, g, b } of the ring: petrol (#006D77)
    size = 32,             -- diameter of the ring in pixels
}

local function OneOf(list, v)
    for _, x in ipairs(list) do if x == v then return true end end
end

-- a stored value, or the default when nothing (valid) is stored
function Cursor:Get(key)
    local v = self:Settings()[key]
    local d = self.DEFAULTS[key]
    if key == "show" then
        if not OneOf(self.SHOWS, v) then return d end
    elseif key == "color" then
        if type(v) ~= "table" or type(v[1]) ~= "number" or type(v[2]) ~= "number" or type(v[3]) ~= "number" then
            return d
        end
    elseif key == "size" then
        if type(v) ~= "number" or v ~= v then return d end
        return math.max(self.SIZE_MIN, math.min(self.SIZE_MAX, v))
    elseif type(v) ~= "boolean" then
        return d
    end
    return v
end

function Cursor:Set(key, value)
    self:Settings()[key] = value
    self:Apply()
end

-- (Apply, the ring and its events live in Ring.lua)

Cursor:Reset({ key = "cursor", group = "hud", order = 77, label = L["Cursor ring"],
    desc = L["Display, color and size of the cursor ring go back to the defaults."],
    reset = function()
        local s = ns.Char().modules.cursor
        if s then
            local on = s.enabled   -- the module switch is not a ring setting
            wipe(s)
            s.enabled = on
        end
    end })

ns.On("SETTINGS_RESET", function() Cursor:Apply() end)

Cursor:Status(function()
    local mode = { off = L["Off"], always = L["Always"], combat = L["In combat"] }
    return L["Cursor ring: %s, %d px"]:format(mode[Cursor:Get("show")], Cursor:Get("size"))
end)
