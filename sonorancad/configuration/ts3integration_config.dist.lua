--[[
    Sonoran Plugins

    Plugin Configuration

    This plugin has no configuration. It only exists to add the plugin to the loaded list.
]]

local config = {
    enabled = false,
    pluginName = "ts3integration", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    requiresPlugins = {}, -- required plugins for this plugin to work, separated by commas
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end