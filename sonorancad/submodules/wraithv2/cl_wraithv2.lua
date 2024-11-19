
CreateThread(function()
    Config.LoadPlugin("wraithv2", function(pluginConfig)
        if pluginConfig.enabled then
            RegisterNetEvent('SonoranCAD::wraithv2:PlaySound',
                             function(soundType)
                SendNUIMessage({
                    type = 'playSound',
                    transactionFile = GetResourcePath(GetCurrentResourceName()) ..
                        '/submodules/wraithv2/sfx/' .. soundType .. '.mp3',
                    transactionVolume = 0.3
                })
            end)
        end
    end)
end)
