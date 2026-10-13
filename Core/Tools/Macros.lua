-- ---------------------------------------------------------------------------
-- Macros: what the rest of the addon uses to work with the player's WoW macros
-- (no interface): limits, name and text helpers, the registries for default
-- templates and header buttons, and creating a macro. The Macro Manager page
-- is MacroManager.lua, its parts are MacroIcons / MacroTransfer / MacroActions.
--   ns.Macros.RegisterTemplates(group)  default templates of a module: { key,
--       title, IsActive(), list = { { name, desc, body } }, Fill(body) }
--   ns.Macros.RegisterAction(action)    header button: { label, width,
--       IsActive(), OnClick(button, mouseButton), Tooltip(button) }
-- The game blocks macro writes in combat, so every write is guarded.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local Macros = { templates = {}, actions = {} }
ns.Macros = Macros

local NAME_MAX, BODY_MAX = 16, 255
local MAX_GENERAL = MAX_ACCOUNT_MACROS or 120
local MAX_CHAR = MAX_CHARACTER_MACROS or 18
local QUESTION_ICON = 134400   -- the question mark: WoW picks the icon from #showtooltip
Macros.NAME_MAX, Macros.BODY_MAX, Macros.QUESTION_ICON = NAME_MAX, BODY_MAX, QUESTION_ICON
Macros.MAX_CHAR = MAX_CHAR
Macros.IN_COMBAT = L["Macros can't be changed in combat."]

-- old icon APIs return bare names; textures need the full path
local function IconPath(v)
    if type(v) == "string" and not v:find("[/\\]") then return "Interface\\Icons\\" .. v end
    return v
end
Macros.IconPath = IconPath

-- character macros come after the general slots; the count differs between
-- client generations, so check it against a real macro when there is one
local function CharBase()
    local _, numChar = GetNumMacros()
    if (numChar or 0) > 0 and not GetMacroInfo(MAX_GENERAL + 1) then
        for _, base in ipairs({ 120, 36, 72, 54 }) do
            if GetMacroInfo(base + 1) then return base end
        end
    end
    return MAX_GENERAL
end
Macros.CharBase = CharBase

-- the client stores macro text with a trailing newline (and keeps stray
-- trailing spaces): compare what matters, not the bytes
function Macros.SameText(a, b)
    local function norm(s) return ((s or ""):gsub("\r\n", "\n"):gsub("[ \t]+\n", "\n"):gsub("%s+$", "")) end
    return norm(a) == norm(b)
end

-- macro names hold 16 letters at most
function Macros.ShortName(s)
    if not s then return nil end
    return ns.Utf8Sub(s, NAME_MAX)
end

-- every macro with this name, general and character: { index, ... }
function Macros.IndicesByName(name)
    local out = {}
    local numGeneral, numChar = GetNumMacros()
    local base = CharBase()
    local function scan(first, count)
        for i = first, first + (count or 0) - 1 do
            if GetMacroInfo(i) == name then out[#out + 1] = i end
        end
    end
    scan(1, numGeneral)
    scan(base + 1, numChar)
    return out
end

function Macros.RegisterTemplates(group) table.insert(Macros.templates, group) end
function Macros.RegisterAction(action) table.insert(Macros.actions, action) end

-- ---------------------------------------------------------------------------
-- Creating a macro from outside (the templates page)
-- ---------------------------------------------------------------------------
-- returns the new macro's index, or nil + reason
function Macros.Create(name, text, perChar)
    if ns.InCombat() then return nil, Macros.IN_COMBAT end
    name = Macros.ShortName(ns.Trim(name))
    if name == "" then return nil, L["Enter a name first."] end
    local numGeneral, numChar = GetNumMacros()
    if (perChar and (numChar or 0) >= MAX_CHAR) or (not perChar and (numGeneral or 0) >= CharBase()) then
        return nil, L["This macro list is full."]
    end
    local ok, idx = pcall(CreateMacro, name, QUESTION_ICON, ns.Utf8Sub(text or "", BODY_MAX), perChar)
    if not (ok and idx) then return nil, L["Couldn't create the macro."] end
    return idx
end

