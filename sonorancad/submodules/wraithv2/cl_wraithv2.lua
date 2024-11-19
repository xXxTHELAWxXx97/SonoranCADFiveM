
CreateThread(function()
    Config.LoadPlugin("wraithv2", function(pluginConfig)
        if pluginConfig.enabled then
            RegisterNetEvent('SonoranCAD::wraithv2:PlaySound',
                             function(soundType)
                SendNUIMessage({
                    type = 'playSound',
                    transactionFile = '../../submodules/wraithv2/sfx/' .. soundType .. '.mp3',
                    transactionVolume = 1.0
                })
            end)
        end
    end)
end)
