-- ---------------------------------------------------------------------------
-- Macro Manager: export / import of the macros of the open tab (ns.Transfer).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, HEX = ns.L, ns.HEX
local Macros = ns.Macros
local mm, IconPath, QUESTION_ICON = Macros.page, Macros.IconPath, Macros.QUESTION_ICON
local IN_COMBAT, Groups = Macros.IN_COMBAT, ns.Transfer.Groups

-- ---------------------------------------------------------------------------
-- Export / import of the macros of the open tab (ns.Transfer)
-- ---------------------------------------------------------------------------
local exportItems = {}
local function TabLabel() return Macros.Tab() == "general" and L["General"] or L["Character"] end
local transfer = ns.Transfer.Build(mm, {
    items = function() return exportItems end,
    label = function(m) return m.name end,
    icon = function(m) return IconPath(m.icon) or QUESTION_ICON end,
    tooltip = function(m) return { m.name, m.body } end,
    preview = function(m) return ns.Colorize(HEX.accent, m.name) .. "\n\n" .. (m.body or "") end,
    encode = ns.EncodeMacros,
    decode = ns.DecodeMacros,
    groupOf = function(m) return m.group end,
    groupNames = function() return Macros.Groups().names end,
    find = function(m)
        for _, x in ipairs(Macros.List()) do if x.name == m.name then return x end end
    end,
    canImport = function()
        if ns.InCombat() then return false, IN_COMBAT end
        return true
    end,
    add = function(m)
        if not Macros.HasRoom() then return false end
        local perChar = Macros.Tab() == "character"
        local ok, idx = pcall(CreateMacro, m.name, m.icon or QUESTION_ICON, m.body or "", perChar)
        if not (ok and idx) then ok, idx = pcall(CreateMacro, m.name, QUESTION_ICON, m.body or "", perChar) end
        if not (ok and idx) then return false end
        Groups.Ensure(Macros.Groups(), m.group)
        Macros.Groups().of[m.name] = m.group
        return true
    end,
    replace = function(have, m)
        -- creating macros re-sorts the list: look the index up now
        local idx = GetMacroIndexByName(have.name)
        if not (idx and idx > 0) or not pcall(EditMacro, idx, nil, m.icon, m.body or "") then return false end
        if m.group then
            Groups.Ensure(Macros.Groups(), m.group)
            Macros.Groups().of[have.name] = m.group
        end
        return true
    end,
    done = function()
        Macros.Reselect()
    end,
    L = {
        exportTitle = L["Export macros"],
        importTitle = L["Import macros"],
        empty = L["No macros here yet"],
        invalid = L["That is no macro code (it starts with EFM1:)."],
        found = L["%d macros in the code. Untick what you don't want."],
        clashTitle = L["Macros exist already"],
        clashText = L["These macros exist already:\n%s\n\nOverwrite them with the imported ones?"],
    },
})

function Macros.ShowExport()
    wipe(exportItems)
    local pre = {}
    local sel, selGroup = Macros.Selection()
    for _, m in ipairs(Macros.List()) do
        local it = { name = m.name, icon = m.icon, body = (m.body or ""):gsub("\n$", ""), group = Macros.GroupOf(m) }
        exportItems[#exportItems + 1] = it
        if (selGroup and Groups.IsIn(it.group, selGroup)) or (not selGroup and m.index == sel) then
            pre[#pre + 1] = it
        end
    end
    transfer.export.title:SetText(L["Export macros"] .. "  " .. ns.Muted("· " .. TabLabel()))
    transfer.ShowExport(pre)
end

function Macros.ShowImport()
    transfer.import.title:SetText(L["Import macros"] .. "  " .. ns.Muted("· " .. L["into: %s"]:format(TabLabel())))
    transfer.ShowImport()
end

Macros.OnHide(function() transfer.Hide() end)

-- export / import sit right in the header, before the module buttons
Macros.RegisterAction({ label = L["Import"], width = 96, OnClick = function() Macros.ShowImport() end })
Macros.RegisterAction({ label = L["Export"], width = 96, OnClick = function() Macros.ShowExport() end })
