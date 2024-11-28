--[[
    Sonoran Plugins
    Plugin Configuration
    Put all needed configuration in this file.
]]

local config = {
    enabled = false,
    pluginName = "vehreg", -- name your plugin here
    pluginAuthor = "Jordan.#2139", -- author
	configVersion = "1.0",

    reigsterCommand = "reg", -- Command to register car
    defaultRegExpire = '01/02/2030', -- The default date that all registrations will expire
    defaultRegStatus = 'VALID', -- The default status that all registrations will have | MUST BE IN CAPS

    language = {
        notInVeh = "Player Not In Vehicle... Please Ensure You're In A Vehicle And Try Again!",
        noApiId = "API ID NOT LINKED TO AN ACCOUNT IN THIS COMMUNITY",
        plateAlrRegisted = "This plate has already been registered to another person",
        helpMsg = 'Register your current vehicle in CAD',
        noCharFound = "No character found. Please ensure you are logged in to a character.",
        --[[
            Placeholders:
            {{PLATE}} = The plate of the vehicle
            {{FIRST}} = The first name of the charactes currently active in CAD
            {{LAST}} = The first name of the charactes currently active in CAD
        ]]
        successReg = "Vehicle ({{PLATE}}) successfully registered to ^2{{FIRST}} {{LAST}}"
    }
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end
