--[[
    Sonaran CAD Plugins

    Plugin Name: forcereg
    Creator: Era#1337
    Description: Requires players to link their API IDs to a valid Sonoran account.

]]

local pluginConfig = Config.GetPluginConfig("forcereg")

if pluginConfig.enabled then

    if pluginConfig.captiveOption == "whitelist" then
        local function checkApiId(apiId, deferral, cb)
            cadApiIdExists(apiId, function(exists)
                debugLog(("checkApiId %s"):format(exists))
                cb(exists, deferral)
            end)
        end

        AddEventHandler("playerConnecting", function(name, setMessage, deferrals)
            local source = source
            deferrals.defer()
            Wait(1)
            deferrals.update("Checking CAD account, please wait...")
            checkApiId(GetIdentifiers(source)[Config.primaryIdentifier], deferrals, function(exists, deferral)
                print("exists: "..tostring(exists))
                if not exists then
                    deferral.done(pluginConfig.captiveMessage)
                else
                    deferral.done()
                end
            end)
        end)
    end



    RegisterNetEvent("SonoranCAD::forcereg:CheckPlayer")
    AddEventHandler("SonoranCAD::forcereg:CheckPlayer", function()
        TriggerEvent("SonoranCAD::apicheck:CheckPlayerLinked", source)
    end)

    AddEventHandler("SonoranCAD::apicheck:CheckPlayerLinkedResponse", function(player, identifier, exists)
        if pluginConfig.whitelist.enabled then
            if pluginConfig.whitelist.mode == "ace" then
                local aceAllowed = false
                for i=1, #pluginConfig.whitelist.aces do
                    if IsPlayerAceAllowed(player, pluginConfig.whitelist.aces[i]) then
                        aceAllowed = true
                        break
                    end
                end
                if aceAllowed then
                    TriggerClientEvent("SonoranCAD::forcereg:PlayerReg", player, identifier, exists)
                end
            elseif pluginConfig.whitelist.mode == "qb-core" then
                local QBCore = exports['qb-core']:GetCoreObject()
                local Player = QBCore.Functions.GetPlayer(player)
                local job = Player.PlayerData.job.name
                if job ~= nil then
                    for i=1, #pluginConfig.whitelist.jobs do
                        if job == pluginConfig.whitelist.jobs[i] then
                            TriggerClientEvent("SonoranCAD::forcereg:PlayerReg", player, identifier, exists)
                            break
                        end
                    end
                end
            elseif pluginConfig.whitelist.mode == "esx" then
                local ESX = exports['es_extended']:getSharedObject()
                local xPlayer = ESX.GetPlayerFromId(player)
                local job = xPlayer.job.name
                if job ~= nil then
                    for i=1, #pluginConfig.whitelist.jobs do
                        if job == pluginConfig.whitelist.jobs[i] then
                            TriggerClientEvent("SonoranCAD::forcereg:PlayerReg", player, identifier, exists)
                            break
                        end
                    end
                end
            end
        else
            TriggerClientEvent("SonoranCAD::forcereg:PlayerReg", player, identifier, exists)
        end
    end)



end