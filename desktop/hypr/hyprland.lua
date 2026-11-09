local function config_dir()
    for entry in package.path:gmatch("[^;]+") do
        local dir = entry:match("^(.*)/%?%.lua$")
        if dir and dir ~= "." then
            return dir
        end
    end
    local base = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
    return base .. "/hypr"
end

local root = config_dir()
package.path = package.path .. ";" .. root .. "/conf.d/?.lua"

local modules = {
    "env",
    "appearance",
    "animations",
    "input",
    "monitors",
    "windowrules",
    "autostart",
    "keybinds",
}

for _, name in ipairs(modules) do
    local ok, err = pcall(require, name)
    if not ok then
        print("[mylinux] failed to load config module '" .. name .. "': " .. tostring(err))
        pcall(function()
            hl.notification.create({ text = "[mylinux] config module '" .. name .. "' failed: " .. tostring(err), timeout = 10000 })
        end)
    end
end
