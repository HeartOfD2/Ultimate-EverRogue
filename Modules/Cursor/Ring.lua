-- ---------------------------------------------------------------------------
-- The cursor ring: one frame that follows the mouse pointer.
--
-- (A sweep for the global cooldown was tried and dropped: the client gives
-- the ring no usable global cooldown data.)
--
-- The OnUpdate that follows the pointer only runs while the ring is shown;
-- the "hide in menus" check is driven by the menus' OnShow/OnHide, not polled.
-- ---------------------------------------------------------------------------
local _, ns = ...
local T = ns.T
local Cursor = ns.Cursor

local MEDIA = "Interface\\AddOns\\" .. ns.ADDON .. "\\Media\\Cursor\\"
local RING, RING_SMALL = MEDIA .. "ring_96_classic", MEDIA .. "ring_small_96_classic"
local FRAME_PER_RING = 2   -- the ring fills about half of its 512 px picture

-- windows that count as "menus" (the ones that don't exist on a client are skipped)
local MENUS = { "GameMenuFrame", "SettingsPanel", "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame",
    "ClassTalentFrame", "ProfessionsFrame", "CollectionsJournal", "WorldMapFrame", "AchievementFrame",
    "PVEFrame", "CommunitiesFrame", "FriendsFrame" }

local ring                       -- the frame, made when the module starts
local inCombat = false
local lastX, lastY, small

-- ---------------------------------------------------------------------------
-- Menus
-- ---------------------------------------------------------------------------
local function MenuOpen()
    for _, name in ipairs(MENUS) do
        local f = rawget(_G, name)
        if f and f.IsShown and f:IsShown() then return true end
    end
    return false
end

-- some of the windows load on demand: hook each one as soon as it exists
local hooked = {}
local function HookMenus()
    for _, name in ipairs(MENUS) do
        local f = not hooked[name] and rawget(_G, name)
        if f and f.HookScript then
            hooked[name] = true
            local function Changed() Cursor:Apply() end
            pcall(f.HookScript, f, "OnShow", Changed)
            pcall(f.HookScript, f, "OnHide", Changed)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Showing and following
-- ---------------------------------------------------------------------------
local function Wanted()
    if not Cursor:IsActive() then return false end
    if Cursor:Get("hideInMenus") and MenuOpen() then return false end
    local show = Cursor:Get("show")
    if show == "off" then return false end
    if show == "combat" and not inCombat then return false end
    return true
end

local function Follow()
    local mouselook = IsMouselooking and IsMouselooking() or false
    if mouselook ~= small then
        small = mouselook
        local picture = mouselook and RING_SMALL or RING
        ring.tex:SetTexture(picture)
    end
    local x, y = GetCursorPosition()
    if x == lastX and y == lastY then return end
    lastX, lastY = x, y
    local scale = UIParent:GetEffectiveScale()
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- (re)read the settings and show or hide the ring
function Cursor:Apply()
    if not ring then return end
    local px = self:Get("size") * FRAME_PER_RING
    ring:SetSize(px, px)
    self:Paint()
    lastX, lastY = nil, nil
    if Wanted() then
        Follow()
        ring:Show()
    else
        ring:Hide()
    end
end

-- the ring's color: the player's choice, else the theme's HUD text color
function Cursor:Paint()
    if not ring then return end
    local c = self:Get("color") or T.hudText
    ring.tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
end

-- ---------------------------------------------------------------------------
-- Module hooks
-- ---------------------------------------------------------------------------
local function Create()
    ring = CreateFrame("Frame", nil, UIParent)
    Cursor.frame = ring   -- (for the test scenarios)
    ring:SetFrameStrata("TOOLTIP")
    ring:SetSize(64, 64)
    ring.tex = ring:CreateTexture(nil, "ARTWORK")
    ring.tex:SetAllPoints()
    ring.tex:SetTexture(RING)
    ring:SetScript("OnUpdate", Follow)   -- hidden frames get no OnUpdate: no cost while the ring is off
    ring:Hide()
    ns.Paint(function() Cursor:Paint() end)
end

function Cursor:OnEnable()
    Create()
    HookMenus()
    inCombat = InCombatLockdown() and true or false
    self:Apply()
end

function Cursor:OnActiveChanged()
    inCombat = InCombatLockdown() and true or false
    self:Apply()
end

Cursor:Event("PLAYER_REGEN_DISABLED", function()
    inCombat = true
    Cursor:Apply()
end)
Cursor:Event("PLAYER_REGEN_ENABLED", function()
    inCombat = false
    Cursor:Apply()
end)
Cursor:Event("ADDON_LOADED", HookMenus)
