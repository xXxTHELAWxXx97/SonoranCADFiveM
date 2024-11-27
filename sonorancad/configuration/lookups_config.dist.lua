--[[
    Sonoran Plugins

    Plugin Configuration
]]
local config = {
    enabled = true,
    pluginName = "lookups", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    configVersion = "1.0",
    requiresPlugins = {}, -- required plugins for this plugin to work, separated by commas

    -- put your configuration options below
    maxCacheTime = 120, -- max time to cache a plate hit, in seconds
    stalePurgeTimer = 600, -- delay between garbage collection, default 10 minutes
    autoLookupEnabled = true
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end