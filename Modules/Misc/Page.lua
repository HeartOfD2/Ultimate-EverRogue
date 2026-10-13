-- ---------------------------------------------------------------------------
-- The "Miscellaneous" page (EXTRAS section): tabs on top, one per function. The tabs come
-- from Misc.AddTab; each body is built when its tab is first shown.
-- ---------------------------------------------------------------------------
local _, ns = ...
local UI = ns.UI
local Misc = ns.Misc

local bodies = {}   -- key -> { frame, tab, built }
local row, current

local function Select(key)
    current = key
    row:Select(key)
    for k, b in pairs(bodies) do b.frame:SetShown(k == key) end
    local b = bodies[key]
    if b and not b.built then
        b.built = true
        b.tab.Build(b.frame, ns.App.CONTENT_W)
    end
    if b and b.frame.Refresh then b.frame:Refresh() end
end

local function Build(frame)
    local list, items = Misc.Tabs(), {}
    for _, t in ipairs(list) do items[#items + 1] = { t.key, t.label } end
    row = UI.Tabs(frame, items, 0, 0, 130, Select)
    for _, t in ipairs(list) do
        local f = CreateFrame("Frame", nil, frame)
        f:SetPoint("TOPLEFT", 0, -36)
        f:SetPoint("BOTTOMRIGHT")
        f:Hide()
        bodies[t.key] = { frame = f, tab = t }
    end
    Select(current and bodies[current] and current or (list[1] and list[1].key))
end

Misc:Page({
    key = "misc", section = "extras", label = ns.L["Miscellaneous"], order = 240,
    Build = function(_, frame) Build(frame) end,
    Refresh = function()
        local b = current and bodies[current]
        if b and b.frame.Refresh then b.frame:Refresh() end
    end,
})
