-- ---------------------------------------------------------------------------
-- Macro assistant, logic only (no UI): turns a plain state table into macro
-- text. Pure string work; no unit data, no protected actions. The UI (a later
-- step) fills the state, shows Build(state) as a live preview and saves it.
--
--   state = {
--     entries = { { spell = 1752 }, { item = 5512, name = "Healthstone" }, { name = "Sprint" } },
--     target  = "mouseover",              -- key of Builder.TARGETS (nil: current target)
--     conditions = { "shift", "combat" }, -- keys of Builder.CONDITIONS (all must hold)
--     extras  = { "showtooltip", "startattack" },   -- keys of Builder.EXTRAS
--     aura    = { spell = 1784 },         -- for the "cancelaura" extra
--   }
-- A spell entry is written as the placeholder {s:<ID>} (the name in the game
-- language, filled in when the macro is written; see Placeholders.lua); with
-- `resolve(id)` (returns a name) the real name is used and the length is exact.
-- ---------------------------------------------------------------------------
local _, ns = ...
local Builder = {}
ns.MacroBuilder = Builder

Builder.MAX_LENGTH = 255   -- characters of one macro

-- target key -> macro target clauses (one clause per fallback, in order)
Builder.TARGETS = {
    target       = {},                               -- the current target: no @ needed
    mouseover    = { "@mouseover" },
    focus        = { "@focus" },
    cursor       = { "@cursor" },
    player       = { "@player" },
    targettarget = { "@targettarget" },
    party1       = { "@party1" },
    party2       = { "@party2" },
    party3       = { "@party3" },
    party4       = { "@party4" },
    pet          = { "@pet" },
    heal         = { "@mouseover,help,nodead", "help,nodead", "@player" },   -- friendly: mouseover, target, yourself
    harm         = { "@mouseover,harm,nodead", "harm,nodead" },              -- hostile: mouseover, target
    mouseover_target_self = { "@mouseover,exists,nodead", "@target,exists,nodead", "@player" },
}
Builder.TARGET_ORDER = { "target", "mouseover", "focus", "cursor", "player", "targettarget",
    "party1", "party2", "party3", "party4", "pet", "heal", "harm", "mouseover_target_self" }

-- condition key -> macro condition
Builder.CONDITIONS = {
    shift = "mod:shift", ctrl = "mod:ctrl", alt = "mod:alt",
    combat = "combat", nocombat = "nocombat",
    stealth = "stealth", nostealth = "nostealth",
    raid = "group:raid", party = "group:party",
    channeling = "channeling",
}
Builder.CONDITION_ORDER = { "shift", "ctrl", "alt", "combat", "nocombat", "stealth", "nostealth",
    "raid", "party", "channeling" }

-- extras that need no argument; written before / after the cast line
local BEFORE = { stopcasting = "/stopcasting", focus = "/focus" }
local AFTER = { startattack = "/startattack", petattack = "/petattack" }
Builder.EXTRAS = { "showtooltip", "stopcasting", "cancelaura", "focus", "startattack", "petattack" }

local function clean(s)
    return (tostring(s or ""):gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- text of one entry: name, or {s:ID}; nil when it holds nothing usable
local function ref(e, resolve)
    if type(e) ~= "table" then return nil end
    if e.spell then
        local id = tonumber(e.spell)
        if not id then return nil end
        local name = resolve and resolve(id)
        if name and name ~= "" then return clean(name) end
        return ("{s:%d}"):format(id)
    end
    local name = clean(e.name)
    if name == "" then return nil end
    return name
end

local function has(list, key)
    for _, k in ipairs(list or {}) do if k == key then return true end end
    return false
end

-- "[a,b][c]" with the conditions in front of every target clause
local function brackets(state, problems)
    local conds = {}
    for _, key in ipairs(Builder.CONDITION_ORDER) do   -- fixed order, not click order
        if has(state.conditions, key) then conds[#conds + 1] = Builder.CONDITIONS[key] end
    end
    for _, key in ipairs(state.conditions or {}) do
        if not Builder.CONDITIONS[key] then problems[#problems + 1] = "condition:" .. tostring(key) end
    end
    local clauses = Builder.TARGETS[state.target or "target"]
    if not clauses then
        problems[#problems + 1] = "target:" .. tostring(state.target)
        clauses = {}
    end
    if #clauses == 0 then clauses = { "" } end
    local out = {}
    for _, clause in ipairs(clauses) do
        local parts = {}
        for _, c in ipairs(conds) do parts[#parts + 1] = c end
        if clause ~= "" then parts[#parts + 1] = clause end
        if #parts > 0 then out[#out + 1] = "[" .. table.concat(parts, ",") .. "]" end
    end
    if #out == 0 then return "" end
    return table.concat(out)
end

-- Build(state[, resolve]) -> text, info
-- info = { length = n, tooLong = bool, exact = bool (no placeholders left), problems = { ... } }
function Builder.Build(state, resolve)
    local problems = {}
    state = state or {}
    local refs, verb = {}, {}
    for _, e in ipairs(state.entries or {}) do
        local r = ref(e, resolve)
        if r then
            refs[#refs + 1] = r
            verb[#verb + 1] = (type(e) == "table" and e.item) and "/use" or "/cast"
        end
    end

    local lines = {}
    local extras = state.extras or {}
    for _, key in ipairs(extras) do
        local known = key == "showtooltip" or key == "cancelaura" or BEFORE[key] or AFTER[key]
        if not known then problems[#problems + 1] = "extra:" .. tostring(key) end
    end

    if has(extras, "showtooltip") then lines[#lines + 1] = "#showtooltip" end   -- always the first line
    for _, key in ipairs({ "stopcasting", "focus" }) do
        if has(extras, key) then lines[#lines + 1] = BEFORE[key] end
    end
    if has(extras, "cancelaura") then
        local aura = ref(state.aura, resolve)
        if aura then lines[#lines + 1] = "/cancelaura " .. aura else problems[#problems + 1] = "cancelaura:missing" end
    end

    local where = brackets(state, problems)
    local prefix = where ~= "" and (where .. " ") or ""
    -- one line per entry (no /castsequence: it is not offered)
    for i, r in ipairs(refs) do lines[#lines + 1] = verb[i] .. " " .. prefix .. r end

    for _, key in ipairs({ "startattack", "petattack" }) do
        if has(extras, key) then lines[#lines + 1] = AFTER[key] end
    end

    local text = table.concat(lines, "\n")
    return text, {
        length = #text,   -- bytes; the client counts the same for the macro limit
        tooLong = #text > Builder.MAX_LENGTH,
        exact = not text:find("{s:%d+}"),
        problems = problems,
    }
end
