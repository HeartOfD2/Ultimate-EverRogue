-- ---------------------------------------------------------------------------
-- Sticky notes: docking. A note hangs at one side of another (its "host"), takes
-- its size and moves along; dragging shows the edges it would snap to.
-- ---------------------------------------------------------------------------
local _, ns = ...
local Notes = ns.Notes
local Stickies = ns.Stickies
local Geo, byNote, BAR_H, MIN_H = Stickies.Geo, Stickies.byNote, Stickies.BAR_H, Stickies.MIN_H

-- ---------------------------------------------------------------------------
-- Docking: a note hangs at one side of another (its "host")
-- ---------------------------------------------------------------------------
local DOCK_GAP, SNAP = 4, 18
local DOCK_POINTS = {   -- side of the host -> our point, host point, x, y
    RIGHT  = { "TOPLEFT", "TOPRIGHT", DOCK_GAP, 0 },
    LEFT   = { "TOPRIGHT", "TOPLEFT", -DOCK_GAP, 0 },
    BOTTOM = { "TOPLEFT", "BOTTOMLEFT", 0, -DOCK_GAP },
    TOP    = { "BOTTOMLEFT", "TOPLEFT", 0, DOCK_GAP },
}

-- a stable number per note (docks survive reloads by it)
local function NoteId(note)
    if not note.id then
        local d = Notes.DB()
        d.nextId = (d.nextId or 0) + 1
        note.id = d.nextId
    end
    return note.id
end

-- the open window a note is docked to, if any
function Stickies.HostOf(f)
    local dock = f.note and f.note.sticky and f.note.sticky.dock
    if not dock then return end
    for note, x in pairs(byNote) do
        if note.id == dock.id and x ~= f then return x end
    end
end

-- open windows docked to f
function Stickies.DockedTo(f)
    local out, id = {}, f.note and f.note.id
    if not id then return out end
    for note, x in pairs(byNote) do
        local dock = note.sticky and note.sticky.dock
        if dock and dock.id == id and x ~= f then out[#out + 1] = x end
    end
    return out
end

-- does a hang (directly or further up) on b?
local function HangsOn(a, b)
    local x, guard = a, 0
    while x and guard < 50 do
        if x == b then return true end
        x, guard = Stickies.HostOf(x), guard + 1
    end
    return false
end

local function FullHeight(f)
    local g = Geo(f.note)
    if g.collapsed then return math.max(MIN_H, g.h or Stickies.Settings().h) end
    return f:GetHeight()
end

-- puts a docked window at its host and gives it the host's size; then its own
-- docked windows follow
function Stickies.Relayout(f, depth)
    if (depth or 0) > 20 then return end   -- broken saved data must not loop
    for _, x in ipairs(Stickies.DockedTo(f)) do
        local g = Geo(x.note)
        local pt = DOCK_POINTS[g.dock.side]
        x:ClearAllPoints()
        x:SetPoint(pt[1], f, pt[2], pt[3], pt[4])
        x:SetWidth(f:GetWidth())
        x:SetHeight(g.collapsed and BAR_H or FullHeight(f))
        Stickies.Relayout(x, (depth or 0) + 1)
    end
end


-- ---------------------------------------------------------------------------
-- Snapping while dragging
-- ---------------------------------------------------------------------------
-- the open window and side f would dock to if dropped now
function Stickies.FindSnap(f)
    local fl, fr, ft, fb = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
    if not (fl and ft) then return end
    local best, bestSide, bestDist
    for note, x in pairs(byNote) do
        if x ~= f and x:IsShown() and not HangsOn(x, f) then
            local xl, xr, xt, xb = x:GetLeft(), x:GetRight(), x:GetTop(), x:GetBottom()
            if xl and xt then
                local taken = {}
                for _, y in ipairs(Stickies.DockedTo(x)) do taken[Geo(y.note).dock.side] = true end
                local vOverlap = ft > xb and fb < xt
                local hOverlap = fr > xl and fl < xr
                local tries = {
                    { "RIGHT", math.abs(fl - (xr + DOCK_GAP)), vOverlap },
                    { "LEFT", math.abs(fr - (xl - DOCK_GAP)), vOverlap },
                    { "BOTTOM", math.abs(ft - (xb - DOCK_GAP)), hOverlap },
                    { "TOP", math.abs(fb - (xt + DOCK_GAP)), hOverlap },
                }
                for _, t in ipairs(tries) do
                    if t[3] and t[2] <= SNAP and not taken[t[1]] and (not bestDist or t[2] < bestDist) then
                        best, bestSide, bestDist = x, t[1], t[2]
                    end
                end
            end
        end
    end
    return best, bestSide
end

local SNAP_W = 3
local OPPOSITE = { LEFT = "RIGHT", RIGHT = "LEFT", TOP = "BOTTOM", BOTTOM = "TOP" }
local snapShown = {}
function Stickies.HideSnap()
    for _, x in ipairs(snapShown) do x.snapLine:Hide() end
    wipe(snapShown)
end

local function EdgeLine(x, side)
    local tex = x.snapLine
    tex:ClearAllPoints()
    if side == "LEFT" or side == "RIGHT" then
        tex:SetPoint("TOP" .. side)
        tex:SetPoint("BOTTOM" .. side)
        tex:SetWidth(SNAP_W)
    else
        tex:SetPoint(side .. "LEFT")
        tex:SetPoint(side .. "RIGHT")
        tex:SetHeight(SNAP_W)
    end
    tex:Show()
    snapShown[#snapShown + 1] = x
end

-- the edge of the other note and the matching edge of the dragged one light up
function Stickies.ShowSnap(f)
    local x, side = Stickies.FindSnap(f)
    Stickies.HideSnap()
    if not x then return end
    EdgeLine(x, side)
    EdgeLine(f, OPPOSITE[side])
end

function Stickies.Dock(f, host, side)
    local g = Geo(f.note)
    g.dock = { id = NoteId(host.note), side = side }
    Stickies.ApplyGeometry(f)
    Stickies.Paint(f)
    Stickies.Render(f)
end

-- free again where it is now, at the size it has now
function Stickies.Undock(f)
    local g = Geo(f.note)
    local l, t = f:GetLeft(), f:GetTop()
    g.dock = nil
    if l and t then
        g.l, g.t = l, t
        g.w = f:GetWidth()
        if not g.collapsed then g.h = f:GetHeight() end
    end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", g.l or 0, g.t or 0)
    Stickies.Paint(f)
end
