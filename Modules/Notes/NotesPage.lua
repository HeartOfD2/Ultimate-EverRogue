-- ---------------------------------------------------------------------------
-- Notes page: the Notebook and Players views, the sticky note settings tab and
-- the tab switching.
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, T, UI, App, Text = ns.L, ns.T, ns.UI, ns.App, ns.Text
local Skin, SetEdgeColor, Muted = ns.Skin, ns.SetEdgeColor, ns.Muted
local Notes = ns.Notes
local Stamp, Hex, DB, NewNote, RemoveNote = Notes.Stamp, Notes.Hex, Notes.DB, Notes.NewNote, Notes.RemoveNote
local Discard, Latest, DisplayName, DropPlayerIfEmpty, KeyOf = Notes.Discard, Notes.Latest, Notes.DisplayName, Notes.DropPlayerIfEmpty, Notes.KeyOf
local Changed, PALETTE = Notes.Changed, Notes.PALETTE
local page, subpages, views, tabs, MakeView = Notes.page, Notes.subpages, Notes.views, Notes.tabs, Notes.MakeView
local HeadLabel, Plural, TREE_W = Notes.HeadLabel, Notes.Plural, Notes.TREE_W
local function Status(msg, alert) App.Status(msg, alert) end

local ShowSub, LastSub

-- ---------------------------------------------------------------- notebook view
local book
local function GroupLabel(g)
    return "|c" .. Hex(PALETTE[g.color] or PALETTE[3]) .. ((g.name ~= "") and g.name or L["(group)"]) .. "|r"
end

-- the group new notes go into: the selected group, the selected note's, or the first
local function TargetGroup()
    if book.selC then return book.selC end
    for _, g in ipairs(DB().groups) do if g == book.sel then return g end end
    return DB().groups[1]
end

local function NewGroup()
    local groups = DB().groups
    local g = { name = L["Group %d"]:format(#groups + 1), color = (#groups % #PALETTE) + 1, seq = 0, notes = {} }
    groups[#groups + 1] = g
    book:Select(g, nil)
    book.head.name:SetFocus()
    book.head.name:HighlightText()
    Changed("book")
end

local function NewBookNote()
    local g = TargetGroup()
    if not g then
        NewGroup()
        g = DB().groups[#DB().groups]
    end
    g.collapsed = nil
    local n = NewNote(g)
    book:Select(n, g)
    book.ed.body:Edit()
    Changed("book")
end

book = MakeView("book", {
    emptyText = L["No groups yet. Use \"+ Group\"."],
    headers = function()
        local out = {}
        for _, g in ipairs(DB().groups) do
            out[#out + 1] = { ref = g, label = GroupLabel(g), color = PALETTE[g.color] or PALETTE[3] }
        end
        return out
    end,
    noteMenuLabel = function(v) return GroupLabel(v.selC) .. "  " .. Muted("›") end,
    noteMenu = function(v, anchor)
        local items = { { label = L["Move to group"], isTitle = true } }
        for _, g in ipairs(DB().groups) do
            items[#items + 1] = { label = GroupLabel(g), checked = g == v.selC, fn = function()
                if g == v.selC then return end
                RemoveNote(v.selC, v.sel)
                table.insert(g.notes, v.sel)
                g.collapsed = nil
                v:Select(v.sel, g)
                Changed("book")
            end }
        end
        UI.OpenMenu(anchor, items)
    end,
    headerPanel = function(v)
        local h = v.head
        HeadLabel(h, L["GROUP NAME"], 0)
        h.name = UI.LineEdit(h, 14)
        h.name:SetPoint("TOPLEFT", 0, -16)
        h.name:SetPoint("TOPRIGHT", 0, -16)
        h.name:SetHeight(24)
        h.name:SetScript("OnTextChanged", function(self, userInput)
            if userInput and h.group then
                h.group.name = self:GetText()
                v:Render()
                Changed("book")
            end
        end)
        HeadLabel(h, L["COLOR"], -52)
        h.swatches = {}
        for i, c in ipairs(PALETTE) do
            local s = CreateFrame("Button", nil, h)
            s:SetSize(20, 20)
            s:SetPoint("TOPLEFT", 1 + (i - 1) * 26, -68)
            Skin(s, c)
            s.hl = s:CreateTexture(nil, "HIGHLIGHT")
            s.hl:SetAllPoints()
            s.hl:SetColorTexture(1, 1, 1, 0.25)
            s:SetScript("OnClick", function()
                if not h.group then return end
                h.group.color = i
                h:Fill(h.group)
                v:Render()
                Changed("book")
            end)
            h.swatches[i] = s
        end
        h.info = Text(h, 11)
        h.info:SetPoint("TOPLEFT", 2, -102)
        h.info:SetJustifyH("LEFT")
        h.add = UI.Button(h, 130, "+ " .. L["Note in group"], NewBookNote)
        h.add:SetPoint("TOPLEFT", 0, -126)
        h.del = UI.ConfirmButton(h, 120, L["Delete group"], function()
            local g = h.group
            local i = g and ns.IndexOf(DB().groups, g)
            if not i then return end
            table.remove(DB().groups, i)
            Status(L["Deleted group \"%s\" with %s."]:format(g.name, Plural(#g.notes, L["%d note"], L["%d notes"])))
            local nextG = DB().groups[math.min(i, #DB().groups)]
            v:Select(nextG, nil)
            Changed("book")
        end)
        h.del:SetPoint("LEFT", h.add, "RIGHT", 6, 0)
        function h:Fill(g)
            self.group = g
            if not self.name:HasFocus() then self.name:SetText(g.name or "") end
            for i, s in ipairs(self.swatches) do SetEdgeColor(s, i == g.color and T.text or nil) end
            local last = Latest(g)
            self.info:SetText(Muted(Plural(#g.notes, L["%d note"], L["%d notes"])
                .. (last and ("   ·   " .. L["last update %s"]:format(Stamp(last.updated))) or "")))
        end
    end,
})

local bookAddGroup = UI.Button(book.page, 106, "+ " .. L["Group"], NewGroup)
bookAddGroup:SetPoint("BOTTOMLEFT", 0, 0)
local bookAddNote = UI.Button(book.page, 106, "+ " .. L["Note"], NewBookNote)
bookAddNote:SetPoint("LEFT", bookAddGroup, "RIGHT", 8, 0)

-- ---------------------------------------------------------------- players view
local players

players = MakeView("players", {
    barH = 56,   -- two rows below the tree: the switches of the popup, and "in combat"
    emptyText = L["No player notes yet. Target a player and press \"+ Note for target\"."],
    headers = function()
        local out = {}
        for key, p in pairs(DB().players) do
            local c = p.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[p.class]
            out[#out + 1] = { ref = p, label = DisplayName(p), sort = ns.Fold(p.name or key),
                color = c and { c.r, c.g, c.b } or { 0.62, 0.65, 0.70 } }
        end
        table.sort(out, function(a, b) return a.sort < b.sort end)
        return out
    end,
    afterRemove = function(_, p)
        local key = KeyOf(p)
        if key then DropPlayerIfEmpty(key) end
    end,
    afterRender = function()
        local n = 0
        for _ in pairs(DB().players) do n = n + 1 end
        tabs.buttons.players.text:SetText(L["Players"] .. "  " .. Muted(tostring(n)))
    end,
    headerPanel = function(v)
        local h = v.head
        h.name = Text(h, 16)
        h.name:SetPoint("TOPLEFT", 2, -2)
        h.info = Text(h, 11)
        h.info:SetPoint("TOPLEFT", 2, -26)
        h.info:SetJustifyH("LEFT")
        h.add = UI.Button(h, 110, "+ " .. L["Note"], function()
            local p = h.player
            if not p then return end
            p.collapsed = nil
            local note = NewNote(p)
            v:Select(note, p)
            v.ed.body:Edit()
            Changed("players")
        end)
        h.add:SetPoint("TOPLEFT", 0, -50)
        h.del = UI.ConfirmButton(h, 110, L["Delete all"], function()
            local key = KeyOf(h.player)
            if not key then return end
            DB().players[key] = nil
            Status(L["Deleted all notes for %s."]:format(h.player.name or key))
            v:Refresh()
            Changed("players")
        end)
        h.del:SetPoint("LEFT", h.add, "RIGHT", 6, 0)
        function h:Fill(p)
            self.player = p
            self.name:SetText(DisplayName(p))
            local last = Latest(p)
            self.info:SetText(Muted(("%s   ·   %s%s"):format(p.realm or "", Plural(#p.notes, L["%d note"], L["%d notes"]),
                last and ("   ·   " .. L["last update %s"]:format(Stamp(last.updated))) or "")))
        end
    end,
})

local addForTarget = UI.Button(players.page, TREE_W, "+ " .. L["Note for target"], function() ns.NoteForTarget() end)
addForTarget:SetPoint("BOTTOMLEFT", 0, 0)

local function Toggle(label, get, set)
    local row = UI.CheckRow(players.page, label, get, function(v)
        set(v)
        Notes.RefreshPopup()
    end, 150)
    return row
end
local showTog = Toggle(L["Show on target"],
    function() return not DB().popupOff end, function(v) DB().popupOff = not v or nil end)
showTog:SetPoint("LEFT", addForTarget, "RIGHT", 16, 0)
local barTog = Toggle(L["\"+ Note\" bar"],
    function() return not DB().addBarOff end, function(v) DB().addBarOff = not v or nil end)
barTog:SetPoint("LEFT", showTog, "RIGHT", 8, 0)
UI.Tooltip(barTog, { L["\"+ Note\" bar"], L["Players without notes get a slim bar to add one."] })

-- second row: the popup in combat (the same two switches sit on the sticky notes tab)
local combatTog = UI.CheckRow(players.page, L["Hide in combat"],
    function() return Notes.HideInCombat("popup") end,
    function(v) Notes.SetHideInCombat("popup", v) Notes.RefreshPopup() end, 170)
combatTog:SetPoint("BOTTOMLEFT", 0, 30)
local holdTog = Notes.HoldShowsRow(players.page, 330)
holdTog:SetPoint("LEFT", combatTog, "RIGHT", 16, 0)

-- sticky note settings (built by ns.Stickies when first shown)
subpages.stickies = CreateFrame("Frame", nil, page)
subpages.stickies:SetPoint("TOPLEFT", 0, -32)
subpages.stickies:SetPoint("BOTTOMRIGHT", 0, 0)
subpages.stickies:Hide()

function LastSub()
    local k = DB().page
    return (k == "players" or k == "stickies") and k or "book"
end

-- this note in its tab, selected (from a sticky note's menu)
function Notes.Reveal(note)
    local kind, c = Notes.Owner(note)
    if not kind then return end
    App:Open("notes")
    local key = kind == "g" and "book" or "players"
    ShowSub(key)
    c.collapsed = nil
    views[key]:Select(note, c)
end

ShowSub = function(key)
    DB().page = key
    for k, p in pairs(subpages) do p:SetShown(k == key) end
    tabs:Select(key)
    local v = views[key]
    if not v then
        if key == "stickies" then ns.Stickies.ShowSettings(subpages.stickies) end
        return
    end
    v:Refresh()
    if not v.sel then
        local first = v.items[1]
        if first then v:Select(first.h.ref, nil) end
    end
    if key == "players" then
        showTog:Refresh()
        barTog:Refresh()
        combatTog:Refresh()
        holdTog:Refresh()
    end
end

page:SetScript("OnShow", function()
    ShowSub(LastSub())
end)
page:SetScript("OnHide", function()
    for _, v in pairs(views) do
        v.ed.title:ClearFocus()
        v.ed.body.edit:ClearFocus()
        if v.selC and Discard(v.selC, v.sel) then
            if v.cfg.afterRemove then v.cfg.afterRemove(v, v.selC) end
            v.sel, v.selC = v.selC, nil
            Changed("hide")
        end
    end
end)

-- keep the views in sync with each other
Notes.OnChange(function(source)
    if page:IsVisible() then
        for key, v in pairs(views) do
            if key ~= source and v.page:IsShown() then v:Refresh() end
        end
    end
end)

Notes.module:Page({
    key = "notes", section = "extras", label = L["Notes"], order = 210,
    Build = function(_, frame)
        page:SetParent(frame)
        page:ClearAllPoints()
        page:SetAllPoints(frame)
        page:Show()
    end,
})

function ns.ToggleNotes() App:Toggle("notes") end

ns.On("SETTINGS_RESET", function(keys)
    if (keys.notes or keys.windows) and page:IsVisible() then
        for _, v in pairs(views) do v.sel, v.selC = nil, nil end
        ShowSub(LastSub())
    end
end)
ns.On("THEME_CHANGED", function()
    if page:IsVisible() then ShowSub(LastSub()) end
end)
Notes.ShowSub, Notes.LastSub = ShowSub, LastSub

-- select a note (or group / player) in a tab of the page and show the tab
function Notes.Select(key, ref, container)
    ShowSub(key)
    views[key]:Select(ref, container)
end
-- put the cursor into the note body of a tab
function Notes.EditSelected(key) views[key].ed.body:Edit() end
