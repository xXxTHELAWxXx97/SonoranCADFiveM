--[[
    Sonaran CAD Plugins

    Plugin Name: ersintegration
    Creator: Sonoran Software
    Description: Integrates Knight ERS callouts to SonoranCAD
]]
CreateThread(function() Config.LoadPlugin("ersintegration", function(pluginConfig)
    RegisterNetEvent('night_ers:ERS_GetPedDataFromServer_cb', function(_, data)
        TriggerServerEvent('SonoranCAD::ErsIntegration::BuildChars', data)
    end)
    RegisterNetEvent('night_ers:receiveVehicleInformation', function(_, data)
        TriggerServerEvent('SonoranCAD::ErsIntegration::BuildVehs', data)
    end)
    RegisterNetEvent('SonoranCAD::ErsIntegration::RequestCallout', function(calloutID)
        local type = exports['night_ers']:getPlayerActiveServiceType()
        local onShift = exports['night_ers']:getIsPlayerOnShift()
        if onShift and type ~= nil then
            TriggerServerEvent('night_ers:requestCallout', type, calloutID)
        end
    end)
end) end)