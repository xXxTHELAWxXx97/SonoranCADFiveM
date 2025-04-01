--[[
    Sonaran CAD Plugins

    Plugin Name: ersintegration
    Creator: Sonoran Software
    Description: Integrates Knight ERS callouts to SonoranCAD
]]
local pluginConfig = Config.GetPluginConfig("ersintegration")

if pluginConfig.enabled then
    RegisterNetEvent('SonoranCAD::ErsIntegration::CalloutOffered')
    RegisterNetEvent('SonoranCAD::ErsIntegration::CalloutAccepted')
    RegisterNetEvent('SonoranCAD::ErsIntegration::BuildChars')
    RegisterNetEvent('SonoranCAD::ErsIntegration::BuildVehs')
    registerApiType('SET_AVAILABLE_CALLOUTS', 'emergency')
    local processedCalloutOffered = {}
    local processedCalloutAccepted = {}
    local processedPedData = {}
    local ersCallouts = {}
    --[[
    @function generateUniqueCalloutKey
    @param table callout
    @return string
    Used to generate the unique key for a callout creation for tracking
    ]]
    local function generateUniqueCalloutKey(callout)
        return string.format(
            "%s_%s_%s_%s_%.2f_%.2f_%.2f",
            callout.calloutId,
            callout.FirstName,
            callout.LastName,
            callout.StreetName,
            callout.Coordinates.x,
            callout.Coordinates.y,
            callout.Coordinates.z
        )
    end
    --[[
    @function generateUniquePedDataKey
    @param table pedData
    @return string
    Used to generate the unique key for a ped data record creation for tracking
    ]]
    local function generateUniquePedDataKey(pedData)
        return string.format(
            "%s_%s_%s_%s",
            pedData.uniqueId,
            pedData.FirstName,
            pedData.LastName,
            pedData.Address
        )
    end
    --[[
    @function generateCallNote
    @param table callout
    @return string
    Used to generate the call note for a callout
    ]]
    function generateCallNote(callout)
        -- Start with basic callout information
        local note = ''

        -- Append potential weapons information
        if callout.PedWeaponData and #callout.PedWeaponData > 0 then
            note = note .. "Potential weapons: " .. table.concat(callout.PedWeaponData, ", ") .. ". "
        else
            note = note .. "No weapons reported. "
        end

        -- Determine the required units from the callout
        local requiredUnits = {}
        local units = callout.CalloutUnitsRequired or {}
        if units.policeRequired then table.insert(requiredUnits, "Police") end
        if units.ambulanceRequired then table.insert(requiredUnits, "Ambulance") end
        if units.fireRequired then table.insert(requiredUnits, "Fire") end
        if units.towRequired then table.insert(requiredUnits, "Tow") end

        if #requiredUnits > 0 then
            note = note .. "Required units: " .. table.concat(requiredUnits, ", ") .. "."
        else
            note = note .. "No additional units required."
        end

        return note
    end

    --[[
        @funciton generateReplaceValues
        @param table data
        @param table config
        @return table
        Generates the replacement values for a record creation based on the passed data and configuration
    ]]
    function generateReplaceValues(data, config)
        local replaceValues = {}
        for cadKey, source in pairs(config) do
            if type(source) == "function" then
                replaceValues[cadKey] = source(data)
            elseif type(source) == "string" then
                replaceValues[cadKey] = data[source]
            else
                error("Invalid mapping configuration for key: " .. tostring(cadKey))
            end
        end
        return replaceValues
    end
    --[[
        911 CALL CREATION
    ]]
    if pluginConfig.create911Call then
        AddEventHandler('SonoranCAD::ErsIntegration::CalloutOffered', function(calloutData)
            local uniqueKey = generateUniqueCalloutKey(calloutData)
            if processedCalloutOffered[uniqueKey] then
                debugPrint("Callout " .. calloutData.calloutId .. " already processed. Skipping 911 call.")
                return
            end
            local caller = calloutData.FirstName .. " " .. calloutData.LastName
            local location = calloutData.StreetName
            local description = calloutData.Description
            local postal = calloutData.Postal
            local plate = ""
            if calloutData.VehiclePlate ~= nil then
                plate = calloutData.VehiclePlate
            end
            local data = {
                ['serverId'] = Config.serverId,
                ['isEmergency'] = true,
                ['caller'] = caller,
                ['location'] = location,
                ['description'] = description,
                ['metaData'] = {
                    ['x'] = calloutData.Coordinates.x,
                    ['y'] = calloutData.Coordinates.y,
                    ['plate'] = plate,
                    ['postal'] = postal
                }
            }
            performApiRequest({data}, 'CALL_911', function(response)
            end)
            processedCalloutOffered[uniqueKey] = true
        end)
    end
    --[[
        EMERGENCY CALL CREATION
    ]]
    if pluginConfig.createEmergencyCall then
        AddEventHandler('SonoranCAD::ErsIntegration::CalloutAccepted', function(calloutData)
            local uniqueKey = generateUniqueCalloutKey(calloutData)
            if processedCalloutAccepted[uniqueKey] then
                debugPrint("Callout " .. calloutData.calloutId .. " already processed. Skipping emergency call... adding new units")
                if pluginConfig.autoAddCall then
                    local callId = processedCalloutAccepted[uniqueKey]
                    local unit = exports['sonorancad']:GetUnitByPlayerId(source)
                    local unitId = unit.data.apiIds[0]
                    local data = {
                        ['serverId'] = Config.serverId,
                        ['callId'] = callId,
                        ['units'] = {unitId}
                    }
                    performApiRequest({data}, 'ATTACH_UNIT', function(response)
                        debugPrint("Added unit to call: " .. response)
                    end)
                end
            else
                debugPrint("Processing callout " .. calloutData.calloutId .. " for emergency call.")
                local callCode = pluginConfig.callCodes[calloutData.CalloutName] or ""
                local unit = exports['sonorancad']:GetUnitByPlayerId(source)
                local unitId = unit.data.apiIds[0]
                local data = {
                    ['serverId'] = Config.serverId,
                    ['origin'] = 0,
                    ['status'] = 1,
                    ['priority'] = pluginConfig.callPriority,
                    ['block'] = calloutData.Postal,
                    ['postal'] = calloutData.Postal,
                    ['address'] = calloutData.StreetName,
                    ['title'] = calloutData.CalloutName,
                    ['code'] = callCode,
                    ['description'] = calloutData.Description,
                    ['units'] = {unitId},
                    ['notes'] = generateCallNote(calloutData), -- required
                    ['metaData'] = {
                        ['x'] = calloutData.Coordinates.x,
                        ['y'] = calloutData.Coordinates.y
                    }
                }
                performApiRequest({data}, 'NEW_DISPATCH', function(response)
                    local callId = response:match("ID: {?(%w+)}?")
                    if callId then
                        -- Save the callId in the processedCalloutOffered table using the unique key
                        processedCalloutOffered[uniqueKey] = callId
                        debugPrint("Call ID " .. callId .. " saved for unique key: " .. uniqueKey)
                    else
                        debugPrint("Failed to extract callId from response: " .. response)
                    end
                end)
            end
        end)
    end
    --[[
        CALLOUT, PED AND VEHICLE DATA CREATION
    ]]
    AddEventHandler('SonoranCAD::ErsIntegration::BuildChars', function(pedData)
        local uniqueKey = generateUniquePedDataKey(pedData)
        if processedPedData[uniqueKey] then
            debugPrint("Ped " .. pedData.FirstName .. " " .. pedData.LastName .. " already processed. Skipping 911 call.")
            return
        end
        local data = {
            ['user'] = '00000000-0000-0000-0000-000000000000',
            ['useDictionary'] = true,
            ['recordTypeId'] = pluginConfig.customRecords.civilianRecordID,
        }
        data.replaceValues = generateReplaceValues(pedData, pluginConfig.customRecords.civilianValues)
        performApiRequest({data}, 'NEW_RECORD', function(response)
            local recordId = response:match("ID: {?(%w+)}?")
            if recordId then
                -- Save the recordId in the processedPedData table using the unique key
                processedPedData[uniqueKey] = recordId
                debugPrint("Record ID " .. recordId .. " saved for unique key: " .. uniqueKey)
            else
                debugPrint("Failed to extract recordId from response: " .. response)
            end
        end)
    end)
    AddEventHandler('SonoranCAD::ErsIntegration::BuildVehs', function(vehData)
        local data = {
            ['user'] = '00000000-0000-0000-0000-000000000000',
            ['useDictionary'] = true,
            ['recordTypeId'] = pluginConfig.customRecords.vehicleRegistrationRecordID,
        }
        data.replaceValues = generateReplaceValues(vehData, pluginConfig.customRecords.vehicleRegistrationValues)
        performApiRequest({data}, 'NEW_RECORD', function(response)
            local recordId = response:match("ID: {?(%w+)}?")
            if recordId then
                -- Save the recordId in the processedPedData table using the unique key
                processedPedData[uniqueKey] = recordId
                debugPrint("Record ID " .. recordId .. " saved for unique key: " .. uniqueKey)
            else
                debugPrint("Failed to extract recordId from response: " .. response)
            end
        end)
    end)
    CreateThread(function()
        Wait(5000)
        debugPrint('Loading ERS Callouts...')
        local calloutData = exports.night_ers.getCallouts()
        for uid, callout in pairs(calloutData) do
            -- Retain only the first description if it exists, otherwise set to an empty table
            if callout.CalloutDescriptions and #callout.CalloutDescriptions > 0 then
                callout.CalloutDescriptions = { callout.CalloutDescriptions[1] }
            else
                callout.CalloutDescriptions = {}
            end

            -- Set CalloutLocations to an empty array
            callout.CalloutLocations = {}

            local data = {}
            data.id = uid
            data.data = callout
            table.insert(ersCallouts, data)
        end
        local data = {
            ['serverId'] = Config.serverId,
            ['callouts'] = ersCallouts
        }
        debugPrint('Loaded ' .. #ersCallouts .. ' ERS callouts.')
        performApiRequest(data, 'SET_AVAILABLE_CALLOUTS', function(response)
            debugPrint('ERS callouts sent to CAD.')
        end)
    end)
    --[[
        PUSH EVENT HANDLER
    ]]
    TriggerEvent('SonoranCAD::RegisterPushEvent', 'EVENT_NEW_CALLOUT', function(data)
        local calloutData = data.data
        local locations = vec3(calloutData.callout.data.CalloutLocations[1].X, calloutData.callout.data.CalloutLocations[1].Y, 41.0)
        calloutData.callout.data.CalloutLocations = {[1] = vector3(locations.x, locations.y, locations.z)}
        local calloutID = exports.night_ers:createCallout(calloutData.callout)
        calloutData.callout.newId = calloutID.calloutId
        TriggerClientEvent('SonoranCAD::ErsIntegration::BuildCallout', -1, calloutData.callout)
        if calloutID then
            debugPrint("Callout " .. calloutID.calloutId .. " created.")
            TriggerClientEvent('SonoranCAD::ErsIntegration::RequestCallout', -1, calloutID.calloutId)
        else
            debugPrint("Failed to create callout.")
        end
    end)
end