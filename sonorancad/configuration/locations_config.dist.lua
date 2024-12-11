--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.
]]
local config = {
    enabled = true,
    pluginName = "locations", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    configVersion = "1.1", -- version of your plugin
    requiresPlugins = {},
    -- put your configuration options below
    checkTime = 5000, -- how frequently to send locations to the server
    prefixPostal = true -- prefix postal code on locations sent, requires postal plugin
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end