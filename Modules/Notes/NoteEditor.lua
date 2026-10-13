-- ---------------------------------------------------------------------------
-- The note editor, one for every place a note is written: the notebook, the
-- player popup and the sticky notes. The text shows formatted; a click on it
-- (or ne:Edit()) switches to writing, leaving the box shows it formatted again.
--   [ ] task   [x] done      a click on the box ticks it
--   - item     * item        bullet list
--   1. item    1) item       numbered list (numbers run on by themselves)
-- Enter at the end of a list line starts the next one; Enter on an empty one
-- ends the list. The toolbar (or ne:LineButton(kind)) turns the line under
-- the cursor into a checkbox / bullet / numbered line, or back.
--
--   local ne = ns.NoteEditor.Create(parent, { toolbar = true, size = 13, skin = true, hint = "..." })
--   ne:SetValue(text)          show a text (keeps the cursor while you write)
--   ne.onChange = fn(text)     the user changed it (typing, ticking, buttons)
--   ne.onEditing = fn(on)      writing starts / ends
--   ne.canEdit = fn() -> bool  optional: may writing start now?
--   ne:Edit()  ne:StopEditing()  ne:LineButton(kind)  ne:Progress() -> done, total
--   ne.edit                    the EditBox (HasFocus, ClearFocus)
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, T = ns.L, ns.T
local UI = ns.UI
local Text, Muted = ns.Text, ns.Muted

local NoteEditor = {}
ns.NoteEditor = NoteEditor

local PAD, TOOL_H = 6, 22

-- ---------------------------------------------------------------------------
-- Lines
-- ---------------------------------------------------------------------------
-- kind ("check" | "bullet" | "number" | "text"), text, ticked, number
local function ParseLine(line)
    local mark, rest = line:match("^%s*%[([ xX]?)%]%s?(.*)$")
    if mark then return "check", rest, mark == "x" or mark == "X" end
    local item = line:match("^%s*[%-%*]%s+(.*)$")
    if item then return "bullet", item end
    local n, after = line:match("^%s*(%d+)[%.%)]%s+(.*)$")
    if n then return "number", after, nil, tonumber(n) end
    return "text", line
end
NoteEditor.ParseLine = ParseLine

local function Lines(text)
    local out = {}
    for line in ((text or "") .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end
    return out
end
NoteEditor.Lines = Lines

-- ticked and total checkboxes of a text
function NoteEditor.Progress(text)
    local done, total = 0, 0
    for _, line in ipairs(Lines(text)) do
        local kind, _, on = ParseLine(line)
        if kind == "check" then
            total = total + 1
            if on then done = done + 1 end
        end
    end
    return done, total
end

-- the marker a new line of this kind gets; numbers follow the line above
local function Marker(kind, above)
    if kind == "check" then return "[ ] " end
    if kind == "bullet" then return "- " end
    local k, _, _, n = ParseLine(above or "")
    return ((k == "number" and n or 0) + 1) .. ". "
end

-- line start / end (1-based, end inclusive) around a cursor position
local function LineAt(text, cursor)
    local before = text:sub(1, cursor)
    local start = (before:match(".*()\n") or 0) + 1
    local stop = (text:find("\n", start, true) or (#text + 1)) - 1
    return start, stop
end

-- turns the line under the cursor into a checkbox / bullet / numbered line,
-- or back to plain text; returns the new text and cursor
function NoteEditor.ToggleLine(text, cursor, want)
    local start, stop = LineAt(text, cursor)
    local line = text:sub(start, stop)
    local kind, rest = ParseLine(line)
    local above
    if start > 1 then
        local a1, a2 = LineAt(text, start - 2)
        above = text:sub(a1, a2)
    end
    local new = (kind == want) and rest or (Marker(want, above) .. rest)
    return text:sub(1, start - 1) .. new .. text:sub(stop + 1), start - 1 + #new
end

-- the user just typed a line break at the end of a list line: carry the list
-- on (or end it when that line was empty). nil when nothing is to be done.
function NoteEditor.ContinueList(old, new, cursor)
    if #new ~= #old + 1 or new:sub(cursor, cursor) ~= "\n" then return end
    if new:sub(1, cursor - 1) .. new:sub(cursor + 1) ~= old then return end
    local s, e = LineAt(new, cursor - 1)
    local line = new:sub(s, e)
    local kind, rest = ParseLine(line)
    if kind == "text" then return end
    if ns.Trim(rest) == "" then
        -- empty list line + Enter: the list ends, the line becomes empty
        return new:sub(1, s - 1) .. new:sub(cursor + 1), s - 1
    end
    local m = Marker(kind, line)
    return new:sub(1, cursor) .. m .. new:sub(cursor + 1), cursor + #m
end

-- ---------------------------------------------------------------------------
-- The editor
-- ---------------------------------------------------------------------------
local Editor = {}   -- methods, copied onto each editor frame

local function Row(ne, i)
    local r = ne.rows[i]
    if r then return r end
    r = CreateFrame("Frame", nil, ne.content)
    r.check = CreateFrame("Button", nil, r)
    r.check:SetSize(14, 14)
    r.check:SetPoint("TOPLEFT", 1, -1)   -- 1 px in: the scroll frame clips its left edge
    ns.Skin(r.check, T.control, T.muted)   -- a clear outline in both modes
    r.check.mark = r.check:CreateTexture(nil, "ARTWORK")
    r.check.mark:SetPoint("TOPLEFT", 3, -3)
    r.check.mark:SetPoint("BOTTOMRIGHT", -3, 3)
    ns.Color(r.check.mark, T.accent)
    r.check.hl = r.check:CreateTexture(nil, "HIGHLIGHT")
    r.check.hl:SetAllPoints()
    ns.Color(r.check.hl, T.hover)
    r.check:SetScript("OnClick", function() ne:Tick(r.index) end)
    r.dot = Text(r, 12)               -- "•" or "3."
    r.dot:SetPoint("TOPLEFT", 3, 0)
    r.dot:SetJustifyH("LEFT")
    r.text = Text(r, 12)
    r.text:SetJustifyH("LEFT")
    r.text:SetJustifyV("TOP")
    r.text:SetWordWrap(true)
    ne.rows[i] = r
    return r
end

-- the formatted text
function Editor:Render()
    if self.editing then return end
    local text = self.text or ""
    local size = self.size
    local width = math.max(40, (self.view:GetWidth() or 0) - 2 * PAD)
    self.content:SetWidth(width)
    local y, shown, run = 0, 0, nil   -- run: number of the last numbered line
    local blank = ns.IsBlank(text)
    for i, line in ipairs(blank and {} or Lines(text)) do
        local r = Row(self, i)
        r.index = i
        local kind, body, on, n = ParseLine(line)
        if kind == "number" then run = run and (run + 1) or n else run = nil end
        local indent = (kind == "text") and 0 or (kind == "number" and 24 or 20)
        r.check:SetShown(kind == "check")
        if kind == "check" then r.check.mark:SetShown(on) end
        r.dot:SetShown(kind == "bullet" or kind == "number")
        r.dot:SetText(kind == "number" and (run .. ".") or "•")
        ns.ApplyFont(r.dot, size, "")
        ns.ApplyFont(r.text, size, "")
        r.text:ClearAllPoints()
        r.text:SetPoint("TOPLEFT", indent, 0)
        r.text:SetWidth(width - indent)
        r.text:SetText(body ~= "" and body or " ")
        local c = on and T.muted or T.text
        r.text:SetTextColor(c[1], c[2], c[3], 1)
        r.dot:SetTextColor(unpack(kind == "number" and T.muted or T.text))
        local h = (body == "" and kind == "text") and math.floor(size * 0.6)
            or math.max(r.text:GetStringHeight(), kind == "check" and 16 or size) + 3
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, -y)
        r:SetSize(width, h)
        r:Show()
        y = y + h
        shown = i
    end
    for i = shown + 1, #self.rows do self.rows[i]:Hide() end
    self.content:SetHeight(math.max(1, y))
    self.empty:SetShown(blank)
    if blank then
        ns.ApplyFont(self.empty, size, "")
        self.empty:SetText(Muted(self.hint or L["Click to write.  [ ] makes a checkbox, - a list, 1. a numbered list."]))
    end
    self:UpdateProgress()
end

function Editor:UpdateProgress()
    if not self.progress then return end
    local done, total = NoteEditor.Progress(self.text)
    self.progress:SetText(total > 0 and (done .. "/" .. total) or "")
end

function Editor:Progress() return NoteEditor.Progress(self.text) end

-- a text from outside (the note changed elsewhere, another note selected)
function Editor:SetValue(text)
    self.text = text or ""
    if self.editing then
        if not self.edit:HasFocus() then self.area:SetValue(self.text) end
        self.lastText = self.edit:GetText()
    else
        self.scroll:SetVerticalScroll(0)
        self:Render()
    end
    self:UpdateProgress()
end

function Editor:GetValue() return self.text end

function Editor:SetFontSize(size)
    self.size = size
    ns.ApplyFont(self.edit, size, "")
    self:Render()
end

local function Changed(self)
    self:UpdateProgress()
    if self.onChange then self.onChange(self.text) end
end

function Editor:SetEditing(on)
    on = on and true or false
    if on and self.canEdit and not self.canEdit() then return end
    if self.editing == on then
        if on and not self.edit:HasFocus() then self.edit:SetFocus() end
        return
    end
    self.editing = on
    self.view:SetShown(not on)
    self.area:SetShown(on)
    if on then
        ns.ApplyFont(self.edit, self.size, "")
        self.area:SetValue(self.text)
        self.lastText = self.text
        self.edit:SetFocus()
        self.edit:SetCursorPosition(#self.text)
    else
        if self.edit:HasFocus() then self.edit:ClearFocus() end
        self:Render()
    end
    if self.onEditing then self.onEditing(on) end
end

function Editor:Edit() self:SetEditing(true) end
function Editor:StopEditing() self:SetEditing(false) end

-- the checkbox in line i flips
function Editor:Tick(i)
    local lines = Lines(self.text)
    local line = lines[i]
    if not line then return end
    local _, _, on = ParseLine(line)
    lines[i] = line:gsub("%[[ xX]?%]", on and "[ ]" or "[x]", 1)
    self.text = table.concat(lines, "\n")
    self:Render()
    Changed(self)
end

-- toolbar: change the cursor's line while writing, else add a line and write
function Editor:LineButton(kind)
    if self.canEdit and not self.canEdit() then return end
    if self.editing then
        local text, cursor = NoteEditor.ToggleLine(self.edit:GetText(), self.edit:GetCursorPosition(), kind)
        self.edit:SetText(text)
        self.edit:SetCursorPosition(cursor)
        self.text, self.lastText = text, text
        if not self.edit:HasFocus() then self.edit:SetFocus() end
    else
        local text = self.text or ""
        local lines = Lines(text)
        local last = lines[#lines]
        if text ~= "" and not text:find("\n$") then text = text .. "\n" end
        self.text = text .. Marker(kind, last)
        self:SetEditing(true)
    end
    Changed(self)
end

local function ToolButton(ne, parent, kind, tip)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(20, 20)
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    ns.Color(b.hl, T.hover)
    if kind == "check" then
        b.box = CreateFrame("Frame", nil, b)
        b.box:SetSize(11, 11)
        b.box:SetPoint("CENTER")
        ns.Skin(b.box, { 0, 0, 0, 0 }, T.muted)
    else
        b.label = Text(b, kind == "number" and 11 or 13)
        b.label:SetPoint("CENTER", 0, kind == "number" and 0 or 1)
        b.label:SetText(kind == "number" and "1." or "•")
        ns.Color(b.label, T.muted)
    end
    UI.Tooltip(b, tip)
    b:SetScript("OnClick", function() ne:LineButton(kind) end)
    return b
end

-- the three line buttons in a row on any parent (the sticky notes use their footer)
function Editor:ToolButtons(parent)
    local check = ToolButton(self, parent, "check", { L["Checkbox"], L["Turns the line into a checkbox: [ ] text"] })
    local bullet = ToolButton(self, parent, "bullet", { L["List"], L["Turns the line into a list item: - text"] })
    local number = ToolButton(self, parent, "number", { L["Numbered list"], L["Turns the line into a numbered item: 1. text"] })
    bullet:SetPoint("LEFT", check, "RIGHT", 2, 0)
    number:SetPoint("LEFT", bullet, "RIGHT", 2, 0)
    return check, bullet, number
end

function NoteEditor.Create(parent, opts)
    opts = opts or {}
    local ne = CreateFrame("Frame", nil, parent)
    for k, fn in pairs(Editor) do ne[k] = fn end
    ne.rows, ne.size, ne.text, ne.hint = {}, opts.size or 13, "", opts.hint
    if opts.skin then ns.Skin(ne, T.control, T.input) end
    local bottom = opts.toolbar and TOOL_H or 0

    -- formatted text; a click anywhere on it starts writing
    local view = CreateFrame("Button", nil, ne)
    view:SetPoint("TOPLEFT", 0, 0)
    view:SetPoint("BOTTOMRIGHT", 0, bottom)
    view:SetScript("OnClick", function() ne:SetEditing(true) end)
    view:EnableMouseWheel(true)
    ne.view = view
    local sf = CreateFrame("ScrollFrame", nil, view)
    sf:SetPoint("TOPLEFT", PAD, -PAD)
    sf:SetPoint("BOTTOMRIGHT", -PAD, 2)
    ne.content = CreateFrame("Frame", nil, sf)
    ne.content:SetSize(100, 10)
    sf:SetScrollChild(ne.content)
    ne.scroll = sf
    view:SetScript("OnMouseWheel", function(_, delta)
        local max = math.max(0, ne.content:GetHeight() - sf:GetHeight())
        sf:SetVerticalScroll(math.max(0, math.min(max, sf:GetVerticalScroll() - delta * 18)))
    end)
    ne.empty = Text(view, 12)
    ne.empty:SetPoint("TOPLEFT", PAD, -PAD)
    ne.empty:SetPoint("TOPRIGHT", -PAD, -PAD)
    ne.empty:SetJustifyH("LEFT")
    ne.empty:SetWordWrap(true)

    -- writing: the raw text
    local area = UI.TextArea(ne)
    area:SetPoint("TOPLEFT", 0, 0)
    area:SetPoint("BOTTOMRIGHT", 0, bottom)
    ns.SetFill(area, { 0, 0, 0, 0 })
    if opts.skin then for _, e in ipairs(area.edges) do e:Hide() end end
    area:Hide()
    ne.area, ne.edit = area, area.edit
    area.edit:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local text = self:GetText()
        local cont, cursor = NoteEditor.ContinueList(ne.lastText or "", text, self:GetCursorPosition())
        if cont then
            self:SetText(cont)
            self:SetCursorPosition(cursor)
            text = cont
        end
        ne.text, ne.lastText = text, text
        Changed(ne)
    end)
    area.edit:SetScript("OnEditFocusGained", function()
        ns.SetEdgeColor(opts.skin and ne or area, T.accent)
    end)
    area.edit:SetScript("OnEditFocusLost", function()
        ns.SetEdgeColor(opts.skin and ne or area)
        ne:SetEditing(false)
    end)

    if opts.toolbar then
        local bar = CreateFrame("Frame", nil, ne)
        bar:SetPoint("BOTTOMLEFT", 2, 1)
        bar:SetPoint("BOTTOMRIGHT", -2, 1)
        bar:SetHeight(TOOL_H - 2)
        local check = ne:ToolButtons(bar)
        check:SetPoint("LEFT", 0, 0)
        ne.progress = Text(bar, 11)
        ne.progress:SetPoint("RIGHT", -4, 0)
        ns.Color(ne.progress, T.muted)
        ne.toolbar = bar
    end

    ne:SetScript("OnSizeChanged", function() if not ne.editing then ne:Render() end end)
    ns.On("THEME_CHANGED", function() if not ne.editing then ne:Render() end end)
    return ne
end
