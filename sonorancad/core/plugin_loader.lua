--[[
    SonoranCAD FiveM Integration

    Plugin Loader

    Provides logic for checking loaded plugins after startup
]]

local function LoadVersionFile()
    local f = LoadResourceFile(GetCurrentResourceName(), ("version.json"))
    if f then
    return f
    else
        warnLog(("Failed to load version file from /sonorancad/version.json Check to see if the file exists."))
        return nil
    end
end

function CheckForPluginUpdate(name)
    local plugin = Config.plugins[name]
    plugin.check_url = 'https://raw.githubusercontent.com/Sonoran-Software/SonoranCADFiveM/refs/heads/master/sonorancad/version.json'
    if plugin == nil then
        errorLog(("Submodule %s not found."):format(name))
        return
    elseif plugin.check_url == nil or plugin.check_url == "" then
        debugLog(("Submodule %s does not have check_url set. Is it configured correctly?"):format(name))
        return
    end
    PerformHttpRequestS(plugin.check_url, function(code, data, headers)
        if code == 200 then
            local remote = json.decode(data)
            if remote == nil then
                if plugin.enabled then
                    warnLog(("Failed to get a valid response for %s. Skipping."):format(k))
                    debugLog(("Raw output for %s: %s"):format(k, data))
                end
            elseif remote.submoduleConfigs[name] == nil and plugin.enabled then
                warnLog(("Failed to check submodule updates for %s: submodule was not found in the updater manifest... if this is a custom submodule you can ignore this warning"):format(name))
            elseif (remote.submoduleConfigs[name].version ~= nil and plugin.configVersion ~= nil) then
                local configCompare = compareVersions(remote.submoduleConfigs[name].version, plugin.configVersion)
                if configCompare.result and not Config.debugMode then
                    if plugin.enabled then
                        errorLog(("Submodule Updater: %s has a new configuration version. You should look at the template configuration file (%s_config.dist.lua) and update your configuration before using this submodule. Guide: https://sonoran.link/config-update"):format(name, name))
                        Config.plugins[name].enabled = false
                        Config.plugins[name].disableReason = "outdated config file"
                    end
                else
                    debugLog(("Submodule %s has the same configuration version."):format(name))
                    local distConfig = LoadResourceFile(GetCurrentResourceName(), ("/configuration/%s_config.dist.lua"):format(name))
                    local normalConfig = LoadResourceFile(GetCurrentResourceName(), ("/configuration/%s_config.lua"):format(name))
                    if distConfig and normalConfig then
                        local filePath = ("%s/configuration/config-backup"):format(GetResourcePath(GetCurrentResourceName()))
                        exports['sonorancad']:CreateFolderIfNotExisting(filePath)
                        local backupFile = io.open(("%s/configuration/config-backup/%s_config.lua"):format(GetResourcePath(GetCurrentResourceName()), name), "w")
                        backupFile:write(distConfig)
                        backupFile:close()
                        os.remove(("%s/configuration/%s_config.dist.lua"):format(GetResourcePath(GetCurrentResourceName()), name))
                        debugLog(("Submodule %s configuration file is up to date. Backup saved."):format(name))
                    end
                end
            elseif name == 'locations' then
                if (remote.submoduleConfigs[name].version ~= nil and plugin.pluginVersion ~= nil) then
                    local configCompare = compareVersions(remote.submoduleConfigs[name].version, plugin.pluginVersion)
                    if configCompare.result and not Config.debugMode then
                        if plugin.enabled then
                            errorLog(("Submodule Updater: %s has a new configuration version. You should look at the template configuration file (%s_config.dist.lua) and update your configuration before using this submodule."):format(name, name))
                            Config.plugins[name].enabled = false
                            Config.plugins[name].disableReason = "outdated config file"
                        end
                    else
                        debugLog(("Submodule %s has the same configuration version."):format(name))
                        local distConfig = LoadResourceFile(GetCurrentResourceName(), ("/configuration/%s_config.dist.lua"):format(name))
                        local normalConfig = LoadResourceFile(GetCurrentResourceName(), ("/configuration/%s_config.lua"):format(name))
                        if distConfig and normalConfig then
                            local filePath = ("%s/configuration/config-backup"):format(GetResourcePath(GetCurrentResourceName()))
                            exports['sonorancad']:CreateFolderIfNotExisting(filePath)
                            local backupFile = io.open(("%s/configuration/config-backup/%s_config.lua"):format(GetResourcePath(GetCurrentResourceName()), name), "w")
                            backupFile:write(distConfig)
                            backupFile:close()
                            os.remove(("%s/configuration/%s_config.dist.lua"):format(GetResourcePath(GetCurrentResourceName()), name))
                            debugLog(("Submodule %s configuration file is up to date. Backup saved."):format(name))
                        end
                    end
                end
            end
        elseif plugin.enabled then
            warnLog(("Failed to check submodule config updates for %s: %s %s"):format(name, code, data))
        end
    end, "GET")
end

CreateThread(function()
    Wait(5000)
    while Config.apiVersion == -1 do Wait(10) end
    if Config.critError then logError("ERROR_ABORT") end
    for k, v in pairs(Config.plugins) do
        if Config.critError then
            Config.plugins[k].enabled = false
            Config.plugins[k].disableReason = "Startup aborted"
            goto skip
        end
        local vfile = LoadVersionFile(k)
        if vfile == nil then
            goto skip
        end
        local versionFile = json.decode(vfile)
        if Config.plugins[k].enabled then
            if versionFile.submoduleConfigs[k].requiresPlugins ~= nil then
                for _, plugin in pairs(versionFile.submoduleConfigs[k].requiresPlugins) do
                    local isCritical = plugin.critical
                    if Config.plugins[plugin.name] == nil or not Config.plugins[plugin.name].enabled then
                        if isCritical then
                            logError("PLUGIN_DEPENDENCY_ERROR", getErrorText("PLUGIN_DEPENDENCY_ERROR"):format(k, plugin.name))
                            Config.plugins[k].enabled = false
                            Config.plugins[k].disableReason = ("Missing dependency %s"):format(plugin.name)
                        elseif plugin.name ~= "esxsupport" then
                            warnLog(("[submodule loader] submodule %s requires %s, but it is not installed. Some features may not work properly."):format(k, plugin.name))
                        end
                    end
                end
            end
        end
        CheckForPluginUpdate(k)
    end
    ::skip::
    local pluginList = {}
    local loadedPlugins = {}
    local disabledPlugins = {}
    local disableFormatted = {}
    for name, v in pairs(Config.plugins) do
        table.insert(pluginList, name)
        if v.enabled then
            table.insert(loadedPlugins, name)
        else
            if v.disableReason == nil then
                v.disableReason = "disabled in config"
            end
            disabledPlugins[name] = v.disableReason
        end
    end
    infoLog(("Available Submodules: %s"):format(table.concat(pluginList, ", ")))
    infoLog(("Loaded Submodules: %s"):format(table.concat(loadedPlugins, ", ")))
    for name, reason in pairs(disabledPlugins) do
        table.insert(disableFormatted, ("%s (%s)"):format(name, reason))
    end
    if #disableFormatted > 0 then
        infoLog(("Disabled Submodules: %s"):format(
                    table.concat(disableFormatted, ", ")))
    end
end)
