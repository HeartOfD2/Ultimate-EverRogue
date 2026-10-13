-- ---------------------------------------------------------------------------
-- Notes module: where it hooks into the rest of the addon. All of it follows
-- the module switch (Core/Module.lua); only the reset of the saved notes
-- stays available while the module is off. The "in combat" switches sit in the
-- notes page itself (player tab, sticky note tab).
--   Minimap        Shift- / middle-click opens the notes
--   Commands       /ef notes, /ef note
--   Reset          "All notes" (account-wide)
-- ---------------------------------------------------------------------------
local _, ns = ...
local L, App = ns.L, ns.App
local Notes = ns.Notes
local Module = Notes.module

-- ---------------------------------------------------------------- minimap button
Module:MinimapClick({
    OnClick = function() App:Toggle("notes") end,
    tooltip = L["Shift- or middle-click: notes"],
    hint = L["Shift-click: notes"],
})

-- ---------------------------------------------------------------- commands
Module:Command({ "notes" }, function() App:Toggle("notes") end, L["notes"])
Module:Command({ "note" }, function() ns.NoteForTarget() end, L["new note for your target (works as a macro)"])

-- ---------------------------------------------------------------- reset
-- only the notes go: popup position, size, lock, the view switches, the
-- combat switches and the sticky note settings stay
Module:Reset({ key = "notes", group = "extras", order = 90, label = L["All notes"], accountWide = true, danger = true,
    desc = L["Deletes every notebook and player note for good."],
    reset = function()
        local n = ns.Acct().notes
        if type(n) ~= "table" then return end
        ns.Acct().notes = { popup = n.popup, popupOff = n.popupOff, addBarOff = n.addBarOff, page = n.page,
                            sticky = n.sticky, hideInCombat = n.hideInCombat, holdShowsNotes = n.holdShowsNotes }
    end })
