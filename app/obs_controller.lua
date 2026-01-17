obs = obslua

version = "0.2.0"

---  config ---
dofile(script_path() .. "config.lua")

FADE_DURATION = 0.5


--- state ---

last_keys   = {}
last_vols   = {}
last_focus  = nil
last_scene  = nil
fade_states = {}


--- paths ---

BASE_DIR = script_path()
DATA_DIR = BASE_DIR .. "data/"
HTML_DIR = DATA_DIR .. "html/"

os.execute('mkdir "' .. DATA_DIR .. '" 2>nul')
os.execute('mkdir "' .. HTML_DIR .. '" 2>nul')

PATH_NAMES    = DATA_DIR .. "names.txt"
PATH_NAME_URL = DATA_DIR .. "name_url.txt"


--- utils ---

function log(msg)
    print(os.date("[%H:%M:%S] ") .. msg)
end

function db_to_volume(db)
    if db <= -40 then return 0 end
    return math.pow(10, db / 20)
end

function volume_to_db(vol)
    if vol <= 0 then return -40 end
    return 20 * math.log10(vol)
end


--- youtube ---

function extract_youtube_id(url)
    local patterns = {
        "youtube%.com/watch%?v=([%w_-]+)",
        "youtu%.be/([%w_-]+)",
        "youtube%.com/live/([%w_-]+)",
        "youtube%.com/embed/([%w_-]+)",
        "youtube%.com/shorts/([%w_-]+)"
    }

    for _, p in ipairs(patterns) do
        local id = string.match(url, p)
        if id then return id end
    end
    return nil
end

function parse_link(url)
    if not url or url == "" then return nil, nil end

    local yt = extract_youtube_id(url)
    if yt then return "yt", yt end

    local tw = string.match(url, "twitch%.tv/([%w_-]+)")
    if tw then return "tw", tw end

    return nil, nil
end

function norm_key(url)
    local k, v = parse_link(url)
    if not k then return "" end
    return k .. ":" .. v
end


--- html ---

function generate_html(video_id, index)
    local path = HTML_DIR .. "player_" .. index .. ".html"

    local f = io.open(path, "w")
    f:write([[
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
html,body{margin:0;padding:0;width:100%;height:100%;background:black;overflow:hidden;}
iframe{width:100%;height:100%;border:none;}
</style>
</head>
<body>
<iframe
 src="https://www.youtube-nocookie.com/embed/]] .. video_id .. [[?autoplay=1&mute=0&playsinline=1&controls=0&rel=0&modestbranding=1"
 allow="autoplay; encrypted-media"
 allowfullscreen>
</iframe>
</body>
</html>
]])
    f:close()
    return path
end


--- name url ---

function load_name_url()
    local map = {}
    local f = io.open(PATH_NAME_URL, "r")
    if not f then return map end

    for line in f:lines() do
        local name, link = string.match(line, "(.+)%s:%s(.+)")
        if name and link then
            local key = norm_key(link)
            if key ~= "" then
                map[key] = name
            end
        end
    end

    f:close()
    return map
end


--- browser ---

function clear_browser(src)
    local s = obs.obs_source_get_settings(src)
    obs.obs_data_set_bool(s, "is_local_file", false)
    obs.obs_data_set_string(s, "url", "about:blank")
    obs.obs_source_update(src, s)
    obs.obs_data_release(s)
    obs.obs_source_set_volume(src, 0)
end

function set_browser(src, link, index)
    local kind, val = parse_link(link)
    if not kind then return end

    local s = obs.obs_source_get_settings(src)

    if kind == "yt" then
        obs.obs_data_set_bool(s, "is_local_file", true)
        obs.obs_data_set_string(s, "local_file", generate_html(val, index))
        obs.obs_data_set_string(s, "url", "")
    else
        obs.obs_data_set_bool(s, "is_local_file", false)
        obs.obs_data_set_string(
            s, "url",
            "https://player.twitch.tv/?channel=" .. val .. "&parent=twitch.tv"
        )
    end

    obs.obs_source_update(src, s)
    obs.obs_data_release(s)
end


--- fade ---

function start_fade(i, source_name, target_db)
    local src = obs.obs_get_source_by_name(source_name)
    if not src then return end

    fade_states[i] = {
        name = source_name,
        start_db = volume_to_db(obs.obs_source_get_volume(src)),
        target_db = target_db,
        start_time = os.clock()
    }

    obs.obs_source_release(src)
end

function process_fade(i)
    local f = fade_states[i]
    if not f then return end

    local src = obs.obs_get_source_by_name(f.name)
    if not src then
        fade_states[i] = nil
        return
    end

    local t = (os.clock() - f.start_time) / FADE_DURATION
    if t > 1 then t = 1 end

    local db = f.start_db + (f.target_db - f.start_db) * t
    obs.obs_source_set_volume(src, db_to_volume(db))
    obs.obs_source_release(src)

    if t >= 1 then
        fade_states[i] = nil
    end
end


--- main ---

function update()
    local f = io.open(PATH_NAMES, "r")
    if not f then return end

    local lines = {}
    for line in f:lines() do table.insert(lines, line) end
    f:close()

    if #lines < VIEW_COUNT then return end

    local links, vols = {}, {}

    for i = 1, VIEW_COUNT do
        local u, d = string.match(lines[i], "(.+)%s|%s(.+)")
        if u then
            links[i] = u
            vols[i] = tonumber(d)
        else
            links[i] = lines[i]
            vols[i] = 0
        end
    end

    local focus = tonumber(lines[#lines]) or -1

    if focus ~= last_focus then
        last_keys = {}
        last_vols = {}
        fade_states = {}
        last_focus = focus
    end

    local display = links
    local display_vols = vols
    local browser_fmt = NORMAL_BROWSER_FMT
    local scene_name  = NORMAL_SCENE

    if focus ~= -1 then
        display = {}
        display_vols = {}
        for i = 1, VIEW_COUNT do
            display[i] = links[i]
            display_vols[i] = vols[i]
        end

        if focus ~= 0 then
            display[1], display[focus+1] =
                display[focus+1], display[1]

            display_vols[1], display_vols[focus+1] =
                display_vols[focus+1], display_vols[1]
        end

        browser_fmt = FOCUS_BROWSER_FMT
        scene_name  = FOCUS_SCENE
    end

    local name_map = load_name_url()

    for i = 1, VIEW_COUNT do
        local src = obs.obs_get_source_by_name(browser_fmt .. " " .. i)
        if src then
            if display[i] == "" then
                clear_browser(src)
                last_keys[i] = ""
                last_vols[i] = nil
            else
                local key = norm_key(display[i])

                if key ~= last_keys[i] then
                    set_browser(src, display[i], i)
                    last_keys[i] = key
                end

                if display_vols[i] ~= last_vols[i] then
                    start_fade(i, browser_fmt .. " " .. i, display_vols[i])
                    last_vols[i] = display_vols[i]
                end

                process_fade(i)
            end
            obs.obs_source_release(src)
        end
    end

    if AUTONAME then
        local srcs = focus ~= -1 and display or links
        for i = 1, VIEW_COUNT do
            local txt = obs.obs_get_source_by_name(NAME_FMT .. " " .. i)
            if txt then
                local s = obs.obs_source_get_settings(txt)
                obs.obs_data_set_string(s, "text", name_map[norm_key(srcs[i])] or "")
                obs.obs_source_update(txt, s)
                obs.obs_data_release(s)
                obs.obs_source_release(txt)
            end
        end
    end

    if scene_name ~= last_scene then
        local scene = obs.obs_get_scene_by_name(scene_name)
        if scene then
            local scene_src = obs.obs_scene_get_source(scene)
            obs.obs_frontend_set_current_scene(scene_src)
            obs.obs_source_release(scene_src)
        end
        last_scene = scene_name
    end
end


--- obs ---

function script_description()
    return "Easy MultiView OBS Controller v" .. version
end

function script_update(settings)
    obs.timer_remove(update)
    obs.timer_add(update, 100)
end
