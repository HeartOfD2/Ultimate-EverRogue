-- ---------------------------------------------------------------------------
-- Placeholders: the page Macros > Placeholders and its reset categories.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, T, HEX, UI, App = ns.L, ns.T, ns.HEX, ns.UI, ns.App
local Placeholders = ns.Placeholders

-- ---------------------------------------------------------------------------
-- Page: Macros › Placeholders
-- ---------------------------------------------------------------------------
local CUSTOM_ROWS, ROW = 6, 28

local function BuildPage(p)
    local W = App.CONTENT_W

    UI.Label(p, L["GEAR"], 0, 0)
    local roleRows = {}
    local function RolesChanged()
        for _, r in ipairs(roleRows) do r:Refresh() end
        Placeholders.CharStore().seen = Placeholders.GearKey()
        Placeholders.UpdateGearMacros()
    end
    for i, role in ipairs(Placeholders.ROLES) do
        local r = Placeholders.RoleRow(p, role, Placeholders.Roles, RolesChanged)
        r:SetPoint("TOPLEFT", 0, -18 - (i - 1) * ROW)
        roleRows[i] = r
    end
    -- trinkets: fixed slots
    local trinkets = {}
    for n = 1, 2 do
        local y = -18 - (n + 1) * ROW - 4
        local t = {}
        t.code = ns.Text(p, 13)
        t.code:SetPoint("TOPLEFT", 0, y)
        t.code:SetText(ns.Code("{g:t" .. n .. "}"))
        t.slot = ns.Text(p, 12)
        t.slot:SetPoint("TOPLEFT", 50, y)
        ns.Color(t.slot, T.muted)
        t.slot:SetText(L["Trinket %d (slot %d)"]:format(n, 12 + n))
        t.found = ns.Text(p, 12)
        t.found:SetPoint("TOPLEFT", 196, y)
        t.found:SetPoint("TOPRIGHT", 0, y)
        t.found:SetJustifyH("LEFT")
        t.found:SetWordWrap(false)
        trinkets[n] = t
    end

    local GY = -18 - 4 * ROW - 6
    local refreshAll = UI.Button(p, 130, L["Refresh"], function() Placeholders.UpdateAll() end, 22)
    refreshAll:SetPoint("TOPLEFT", 0, GY)
    refreshAll:SetAccent(true)
    UI.Tooltip(refreshAll, { L["Refresh"], L["Rewrites every macro named exactly like a template (general or character) and the macros of active modules with the current values."] })
    local gearTpl = UI.Button(p, 172, "+  " .. L["Template with gear"], function()
        ns.Templates.New({ group = L["Gear"], body = "#showtooltip\n/equipslot 16 {w:W1}\n/equipslot 17 {w:W2}" })
        App.Status(L["Name it and save: macros with this name follow your gear."])
    end, 22)
    gearTpl:SetPoint("LEFT", refreshAll, "RIGHT", 6, 0)
    UI.Tooltip(gearTpl, { L["Template with gear"], L["A template with {w:W1} and {w:W2}: they become the weapons picked above. Export and import it with the templates."] })

    -- own placeholders
    local CY = GY - 36
    UI.Label(p, L["YOUR PLACEHOLDERS"], 0, CY)
    local list = CreateFrame("Frame", nil, p)
    list:SetPoint("TOPLEFT", 0, CY - 18)
    list:SetSize(W, CUSTOM_ROWS * ROW)
    list:EnableMouseWheel(true)
    local empty = UI.Hint(list, L["None yet. \"+ Placeholder\" adds one: a name and a value, e.g. {c:me} = Ketchup."], W)
    empty:SetPoint("TOPLEFT", 0, -4)
    local scroll = 0
    local cRows = {}
    local Render

    local function Commit(r)
        local c = r.entry
        if not c then return end
        local name = ns.Trim(r.name:GetText())
        local value = r.value:GetText()
        if name ~= c.name then
            if name == "" or name:find("[{}:%s]") then
                App.Status(L["A name without spaces, braces or colons, please."], true)
                r.name:SetText(c.name)
            elseif Placeholders.FindCustom(name) then
                App.Status(L["{c:%s} exists already."]:format(name), true)
                r.name:SetText(c.name)
            else
                c.name = name
            end
        end
        if value ~= c.value then
            c.value = value
            -- macros with this placeholder take the new value
            if ns.Templates then ns.Templates.UpdateMacros(function(t) return t.body:find("{c:" .. c.name .. "}", 1, true) end) end
        end
        r.code:SetText(ns.Code("{c:" .. c.name .. "}"))
    end

    for i = 1, CUSTOM_ROWS do
        local r = CreateFrame("Frame", nil, list)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
        r:SetSize(W, ROW)
        r.name = UI.LineEdit(r, 12, 24)
        r.name:SetPoint("LEFT", 0, 0)
        r.name:SetSize(130, 22)
        r.eq = ns.Text(r, 12)
        r.eq:SetPoint("LEFT", 136, 0)
        r.eq:SetText("=")
        r.value = UI.LineEdit(r, 12, 200)
        r.value:SetPoint("LEFT", 150, 0)
        r.value:SetSize(W - 150 - 30 - 150, 22)
        r.code = ns.Text(r, 11)
        r.code:SetPoint("LEFT", r.value, "RIGHT", 8, 0)
        r.code:SetWidth(140)
        r.code:SetJustifyH("LEFT")
        r.code:SetWordWrap(false)
        r.del = UI.ConfirmButton(r, 24, "×", function()
            local _, idx = Placeholders.FindCustom(r.entry and r.entry.name)
            if idx then table.remove(Placeholders.Custom(), idx) end
            Render()
        end, 22)
        r.del:SetPoint("RIGHT", 0, 0)
        UI.Tooltip(r.del, { L["Delete"], L["Click twice to confirm."] })
        for _, e in ipairs({ r.name, r.value }) do
            e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
            e:HookScript("OnEditFocusLost", function() Commit(r) end)
        end
        cRows[i] = r
    end

    Render = function()
        local all = Placeholders.Custom()
        scroll = math.max(0, math.min(scroll, #all - CUSTOM_ROWS))
        empty:SetShown(#all == 0)
        for i, r in ipairs(cRows) do
            local c = all[scroll + i]
            r.entry = c
            if c then
                if not r.name:HasFocus() then r.name:SetText(c.name) end
                if not r.value:HasFocus() then r.value:SetText(c.value or "") end
                r.code:SetText(ns.Code("{c:" .. c.name .. "}"))
                r:Show()
            else
                r:Hide()
            end
        end
    end
    list:SetScript("OnMouseWheel", function(_, delta) scroll = scroll - delta Render() end)

    local add = UI.Button(p, 130, "+  " .. L["Placeholder"], function()
        local all, n = Placeholders.Custom(), 1
        while Placeholders.FindCustom(L["name"] .. n) do n = n + 1 end
        all[#all + 1] = { name = L["name"] .. n, value = "" }
        scroll = #all
        Render()
        for _, r in ipairs(cRows) do
            if r.entry == all[#all] then r.name:SetFocus() r.name:HighlightText() end
        end
    end, 22)
    add:SetPoint("TOPRIGHT", 0, CY + 4)

    local note = UI.Hint(p, L["Use them in templates. Refresh rewrites every macro named exactly like a template, general or character, with the current values; other macros are never changed."], W)
    note:SetPoint("BOTTOMLEFT", 0, 0)
    note:SetSpacing(2)

    Placeholders.RefreshPage = function()
        if not p:IsVisible() then return end
        for _, r in ipairs(roleRows) do r:Refresh() end
        for n, t in ipairs(trinkets) do
            local name = Placeholders.Trinket(n)
            t.found:SetText(name and ("= " .. ns.Colorize(HEX.good, name)) or ns.Muted(L["(nothing in this slot)"]))
        end
        Render()
    end
end

App:AddPage({
    key = "placeholders", section = "macros", label = L["Placeholders"], order = 130,
    Build = function(_, frame) BuildPage(frame) end,
    Refresh = function() if Placeholders.RefreshPage then Placeholders.RefreshPage() end end,
})

ns.RegisterReset({ key = "gear", group = "macros", order = 76, label = L["Weapon roles"],
    desc = L["W1 / W2 back to dagger / any weapon, picked anew from what you carry."],
    reset = function() ns.Char().placeholders = nil end })
ns.RegisterReset({ key = "customPlaceholders", group = "macros", order = 87, label = L["Own placeholders"], accountWide = true,
    desc = L["Deletes your own placeholders {c:...}."],
    reset = function()
        local a = ns.Acct()
        if a.placeholders then a.placeholders.custom = nil end
    end })
