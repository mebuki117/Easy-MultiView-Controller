local CONFIG_PATH = script_path() .. "config.ini"


--- ini loader ---

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function load_ini(path)
    local cfg = {}
    local section = nil

    local f = io.open(path, "r")
    if not f then
        print("[config.lua] config.ini not found")
        return cfg
    end

    for line in f:lines() do
        line = trim(line)

        -- skip
        if line == "" or line:sub(1,1) == ";" or line:sub(1,1) == "#" then
            goto continue
        end

        -- section
        local s = line:match("^%[(.+)%]$")
        if s then
            section = s
            cfg[section] = {}
            goto continue
        end

        -- key = value
        local k, v = line:match("^([^=]+)=(.+)$")
        if k and section then
            k = trim(k)
            v = trim(v)
            cfg[section][k] = v
        end

        ::continue::
    end

    f:close()
    return cfg
end


--- load ---

local cfg = load_ini(CONFIG_PATH)


--- GENERAL ---

VIEW_COUNT =
    tonumber(cfg.GENERAL and cfg.GENERAL.VIEW_COUNT) or 2


--- OBS ---

NORMAL_BROWSER_FMT =
    cfg.OBS and cfg.OBS.NORMAL_BROWSER_FMT or "Normal_Player"

FOCUS_BROWSER_FMT =
    cfg.OBS and cfg.OBS.FOCUS_BROWSER_FMT or "Focus_Player"

NAME_FMT =
    cfg.OBS and cfg.OBS.NAME_FMT or "Name"

NORMAL_SCENE =
    cfg.OBS and cfg.OBS.NORMAL_SCENE or "Normal"

FOCUS_SCENE =
    cfg.OBS and cfg.OBS.FOCUS_SCENE or "Focus"

AUTONAME =
    cfg.OBS and cfg.OBS.AUTONAME == "true" or false
