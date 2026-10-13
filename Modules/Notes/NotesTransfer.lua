-- ---------------------------------------------------------------------------
-- Notes: export and import as a text code (EFN1:).
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, HEX, UI, Muted, IsBlank = ns.L, ns.HEX, ns.UI, ns.Muted, ns.IsBlank
local Notes = ns.Notes
local Now, Hex, DB, EnsurePlayer, Changed = Notes.Now, Notes.Hex, Notes.DB, Notes.EnsurePlayer, Notes.Changed
local PALETTE = Notes.PALETTE
local page, views = Notes.page, Notes.views

-- ---------------------------------------------------------------- export / import
local exportItems = {}
local function Item(note, kind, c, key)
    -- a group without a name still needs one in the code
    local owner = (kind == "g") and (ns.Trim(c.name or "") ~= "" and c.name or L["(group)"]) or key
    return { note = note, kind = kind, owner = owner,
             extra = kind == "g" and tostring(c.color or 3) or c.class,
             title = note.title, text = note.text, created = note.created, updated = note.updated }
end
-- the group or player an entry belongs to (nil: not there yet)
local function OwnerOf(it)
    if it.kind == "p" then return DB().players[it.owner] end
    for _, g in ipairs(DB().groups) do if g.name == it.owner then return g end end
end
local function ItemColor(it)
    if it.kind == "g" then return PALETTE[tonumber(it.extra) or 3] or PALETTE[3] end
    return Notes.Color("p", { class = it.extra })
end
local function ItemOwnerName(it)
    if it.kind == "g" then return it.owner end
    return it.owner:match("^(.-)%-") or it.owner
end
local function ItemLabel(it)
    return "|c" .. Hex(ItemColor(it)) .. ItemOwnerName(it) .. "|r  " .. ((it.title ~= "" and it.title) or L["(untitled)"])
end

local transfer = ns.Transfer.Build(page, {
    items = function() return exportItems end,
    label = ItemLabel,
    color = ItemColor,
    tooltip = function(it)
        local lines = { (it.title ~= "" and it.title) or L["(untitled)"], ItemOwnerName(it) }
        if not IsBlank(it.text) then lines[#lines + 1] = it.text end
        return lines
    end,
    preview = function(it)
        return ns.Colorize(HEX.accent, (it.title ~= "" and it.title) or L["(untitled)"]) .. "\n"
            .. Muted((it.kind == "g" and L["Group: %s"] or L["Player: %s"]):format(it.owner)) .. "\n\n" .. (it.text or "")
    end,
    encode = Notes.Encode,
    decode = Notes.Decode,
    find = function(it)
        local c = OwnerOf(it)
        if not c then return end
        for _, n in ipairs(c.notes) do
            if (n.title or "") == (it.title or "") then return n end
        end
    end,
    add = function(it)
        local c = OwnerOf(it)
        if not c then
            if it.kind == "g" then
                c = { name = it.owner, color = tonumber(it.extra) or 3, seq = 0, notes = {} }
                table.insert(DB().groups, c)
            else
                c = EnsurePlayer(it.owner, { name = it.owner:match("^(.-)%-") or it.owner,
                    realm = it.owner:match("%-(.+)$"), class = it.extra })
            end
        end
        c.seq = (c.seq or #c.notes) + 1
        table.insert(c.notes, { title = it.title, text = it.text or "", titled = true,
            created = it.created or Now(), updated = it.updated or Now() })
    end,
    replace = function(have, it)
        have.text = it.text or ""
        have.updated = it.updated or Now()
    end,
    done = function()
        Changed("import")
        Notes.ShowSub(Notes.LastSub())
    end,
    L = {
        exportTitle = L["Export notes"],
        importTitle = L["Import notes"],
        empty = L["No notes yet."],
        invalid = L["That is no notes code (it starts with EFN1:)."],
        found = L["%d notes in the code. Untick what you don't want."],
        clashTitle = L["Notes exist already"],
        clashText = L["These notes exist already (same group or player, same title):\n%s\n\nOverwrite their text with the imported one?"],
    },
})

local importBtn = UI.Button(page, 100, L["Import"], function() transfer.ShowImport() end, 22)
importBtn:SetPoint("TOPRIGHT", 0, 0)
local exportBtn = UI.Button(page, 100, L["Export"], function()
    wipe(exportItems)
    local pre = {}
    Notes.ForEach(function(note, kind, c, key)
        local it = Item(note, kind, c, key)
        exportItems[#exportItems + 1] = it
        local v = views[DB().page]
        if v and v.sel == note then pre[1] = it end
    end)
    transfer.ShowExport(pre)
end, 22)
exportBtn:SetPoint("RIGHT", importBtn, "LEFT", -6, 0)

page:HookScript("OnHide", function() transfer.Hide() end)
