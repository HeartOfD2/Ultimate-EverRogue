-- ---------------------------------------------------------------------------
-- Sounds: every entry of the client's SOUNDKIT table, read
-- at run time, and one way to play them. A setting stores the entry's name
-- and a volume (0-100 % of the master volume). Sounds play by kit ID only
-- (PlaySound), never by file path; a name this client doesn't know plays the
-- default sound instead.
--
-- Volume: the game has no volume for a single sound, only for its channels.
-- Below 100 % the master volume is turned down just before the sound and put
-- back RESTORE_AFTER seconds later. Only the newest call puts it
-- back, so fast repeats stay quiet; a 100 % call puts it back at once. The
-- value to put back also sits in the saved variables until then, so a
-- /reload in between can't leave the game quieter.
-- ---------------------------------------------------------------------------
local _, ns = ...

local Sound = {}
ns.Sound = Sound

Sound.DEFAULT = "RAID_WARNING"
local DEFAULT_ID = 8959       -- RAID_WARNING's kit ID, for a client without that entry
local MASTER = "Sound_MasterVolume"
local RESTORE_AFTER = 1.5     -- seconds the master volume stays down
local MAX_GROUPS = 18         -- the biggest name prefixes get a group, the rest is "other"
Sound.OTHER = ""              -- group key of the rest

local function Kit()
    local kit = rawget(_G, "SOUNDKIT")
    return type(kit) == "table" and kit or nil
end

-- the kit ID of a name, nil when this client doesn't have it
function Sound.ID(name)
    local kit = Kit()
    local id = kit and type(name) == "string" and kit[name]
    if type(id) == "number" then return id end
    return nil
end

function Sound.Exists(name) return Sound.ID(name) ~= nil end

-- the name that really plays: the given one, else the default
function Sound.Resolve(name)
    return Sound.Exists(name) and name or Sound.DEFAULT
end

-- The name as shown to the player: "RAID_WARNING" -> "Raid warning". The
-- client has no display names for sounds, so this only tidies the key; the
-- stored key and the search stay as they are.
local ACRONYMS = { UI = true, IG = true, GM = true, PVP = true, PET = true, NPC = true, LFG = true, XP = true, AH = true }

function Sound.Title(name)
    if type(name) ~= "string" then return "" end
    local words = {}
    for w in name:gmatch("[^_]+") do
        words[#words + 1] = ACRONYMS[w:upper()] and w:upper() or w:lower()
    end
    local s = table.concat(words, " ")
    return s:sub(1, 1):upper() .. s:sub(2)
end

-- ---------------------------------------------------------------------------
-- The list: built the first time something asks (a few thousand entries).
-- Entries { name, id, group, key }; key is the folded name with spaces for
-- underscores, for the search. Groups { key, count }, sorted, "other" last.
-- ---------------------------------------------------------------------------
local list, groups

local function Prefix(name) return name:match("^([^_]+)_") or name end
local function SearchKey(s) return ns.Fold((s:gsub("_", " "))) end

function Sound.List()
    if list then return list, groups end
    list, groups = {}, {}
    local kit = Kit()
    if kit then
        for name, id in pairs(kit) do
            if type(name) == "string" and type(id) == "number" then
                list[#list + 1] = { name = name, id = id, key = SearchKey(name) }
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    -- the biggest prefixes become groups (keeps the group menu short)
    local count, prefixes = {}, {}
    for _, e in ipairs(list) do
        local p = Prefix(e.name)
        if not count[p] then prefixes[#prefixes + 1] = p end
        count[p] = (count[p] or 0) + 1
    end
    table.sort(prefixes, function(a, b)
        if count[a] ~= count[b] then return count[a] > count[b] end
        return a < b
    end)
    local own = {}
    for i = 1, math.min(MAX_GROUPS, #prefixes) do
        if count[prefixes[i]] > 1 then own[prefixes[i]] = true end
    end
    local inGroup = {}
    for _, e in ipairs(list) do
        local p = Prefix(e.name)
        e.group = own[p] and p or Sound.OTHER
        inGroup[e.group] = (inGroup[e.group] or 0) + 1
    end
    for key, n in pairs(inGroup) do groups[#groups + 1] = { key = key, count = n } end
    table.sort(groups, function(a, b)
        if (a.key == Sound.OTHER) ~= (b.key == Sound.OTHER) then return b.key == Sound.OTHER end
        return a.key < b.key
    end)
    return list, groups
end

-- the entries that match: every word of the query appears in the name
-- (underscores count as spaces); group nil = all groups
function Sound.Filter(query, group)
    local all = Sound.List()
    local words = {}
    for w in SearchKey(query or ""):gmatch("%S+") do words[#words + 1] = w end
    if #words == 0 and group == nil then return all end
    local out = {}
    for _, e in ipairs(all) do
        if group == nil or e.group == group then
            local hit = true
            for _, w in ipairs(words) do
                if not e.key:find(w, 1, true) then hit = false break end
            end
            if hit then out[#out + 1] = e end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Playing
-- ---------------------------------------------------------------------------
local pending, token = nil, 0   -- the master volume to put back; the newest call

local function ReadMaster()
    local get = rawget(_G, "GetCVar")
    if not get then return nil end
    local ok, v = pcall(get, MASTER)
    return ok and tonumber(v) or nil
end

local function WriteMaster(v)
    local set = rawget(_G, "SetCVar")
    if not set then return false end
    return (pcall(set, MASTER, v))
end

local function Remember(v)
    if ns.dbReady then ns.Acct().soundRestore = v end
end

local function PutBack()
    if pending == nil then return end
    WriteMaster(pending)
    pending = nil
    Remember(nil)
end

local function Fire(id)
    local play = rawget(_G, "PlaySound")
    if not play then return nil end
    local ok, willPlay, handle = pcall(play, id, "Master")
    if ok and willPlay then return handle end
    return nil
end

-- plays a sound at volume % of the master volume (nil = 100, 0 = silent);
-- returns the game's handle for Sound.Stop, when it gives one
function Sound.Play(name, volume)
    volume = tonumber(volume) or 100
    if volume <= 0 then return nil end
    local id = Sound.ID(name) or Sound.ID(Sound.DEFAULT) or DEFAULT_ID
    token = token + 1
    local mine = token
    -- a master volume that is still down counts as "not read yet"
    local base = pending or ReadMaster()
    if volume >= 100 or not base then
        PutBack()
        return Fire(id)
    end
    pending = base
    Remember(base)
    WriteMaster(base * volume / 100)
    local handle = Fire(id)
    C_Timer.After(RESTORE_AFTER, function()
        if mine == token then PutBack() end
    end)
    return handle
end

function Sound.Stop(handle)
    local stop = rawget(_G, "StopSound")
    if handle and stop then pcall(stop, handle) end
end

-- trying sounds out (the picker): the last preview stops before the next one
local previewHandle
function Sound.Preview(name, volume)
    Sound.Stop(previewHandle)
    previewHandle = Sound.Play(name, volume)
end

-- a /reload or logout while the volume was down: put it back now
ns.On("DB_READY", function()
    local v = ns.Acct().soundRestore
    if type(v) == "number" then WriteMaster(v) end
    ns.Acct().soundRestore = nil
end)
