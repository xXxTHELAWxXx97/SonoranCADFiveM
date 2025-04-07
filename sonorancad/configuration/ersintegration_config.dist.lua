--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.
]]
local config = {
    enabled = true,
    pluginName = "ersintegration", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    configVersion = "1.0",
    -- put your configuration options below
    create911Call = true, -- Create a 911 call when an ERS callout is created
    createEmergencyCall = true, -- Create an emergency call when an ERS callout is accepted
    callPriority = 2, -- Priority of the call created in CAD (1-3) | Only used if createEmergencyCall is true
    callCodes = {
        ['Stolen_motorbike'] = '10-22'
    }, -- Call codes for each ERS callout type | Only used if createEmergencyCall is true
    autoAddCall = true, -- Automatically add members to the call when an ERS callout is accepted
    customRecords = {
        civilianRecordID = 7, -- Record ID for civilian records
        civilianValues = {
            -- Configurable mapping for SonoranCAD replaceValues.
            -- The key is what SonoranCAD expects and the value is either:
            --    • A string that matches a key in pedData, or
            --    • A function that returns a value based on pedData.
            --    • Left side of mapping is the SonoranCAD field mapping ID from Custom Records, right side is the ERS field.
            ["first"] = "FirstName",
            ["last"] = "LastName",
            ["dob"] = "DOB",
            ["sex"] = "Gender",
            ["residence"] = function(pedData)
                return pedData.Address .. " " .. pedData.City
            end,
            ["zip"] = "Zip",
            ["phone"] = "Phone",
            ["skin"] = "Nationality",
            -- Add more keys as needed:
            -- email = "Email"  -- Example: if pedData.Email exists.
        },
        vehicleRegistrationRecordID = 5, -- Record ID for vehicle registration records
        vehicleRegistrationValues = {
            -- Configurable mapping for SonoranCAD replaceValues.
            -- The key is what SonoranCAD expects and the value is either:
            --    • A string that matches a key in pedData, or
            --    • A function that returns a value based on pedData.
            --    • Left side of mapping is the SonoranCAD field mapping ID from Custom Records, right side is the ERS field.
            -- Registration Information
            ["status"] = function(vehicleData)
                if vehicleData.stolen then
                    return "STOLEN"
                elseif not vehicleData.mot then
                    return "EXPIRED"
                else
                    return "VALID"
                end
            end,
            ["_wsakvwigt"] = function(vehicleData)
                if vehicleData.stolen then
                    return "STOLEN"
                elseif not vehicleData.mot then
                    return "EXPIRED"
                else
                    return "VALID"
                end
            end,
            ["_imtoih149"] = function(vehicleData)
                return os.date("%m/%d/%Y", os.time() + (60 * 60 * 24 * 365)) -- +1 year from now
            end,
            -- Civilian Information
            ["first"] = function(vehicleData)
                return vehicleData.owner_name:match("^(%S+)")
            end,
            ["last"] = function(vehicleData)
                return vehicleData.owner_name:match("%s(.+)$")
            end,
            -- Vehicle Information
            ["plate"] = "license_plate",
            ["model"] = "model",
            ["color"] = function(vehicleData)
                if vehicleData.color_secondary and vehicleData.color_secondary ~= "" then
                    return vehicleData.color .. ", " .. vehicleData.color_secondary
                else
                    return vehicleData.color
                end
            end,
            ["year"] = "build_year",
            ["type"] = function(vehicleData)
                local classMap = {
                    [0] = "SEDAN", [1] = "SEDAN", [2] = "SUV", [3] = "SUV",
                    [4] = "COUPE", [5] = "COUPE", [6] = "OFFROAD", [7] = "TRUCK",
                    [8] = "MOTORCYCLE", [9] = "MARINE", [16] = "AIRCRAFT"
                }
                return classMap[vehicleData.vehicle_class] or "SEDAN"
            end,
        -- Add more keys as needed:
        -- owner = "Owner"  -- Example: if pedData.Owner exists.
        },
        licenseRecordId = 4, -- Record ID for license records
        licenseTypeField = "7eddab31daf4a0182", -- Field ID for license type
        licenseTypeConfigs = {
            DRIVER = {
                type = "DRIVER",
                is_valid = "is_license_car_valid",
                license = "license_car",
            },
            MOTORCYCLE = {
                type = "MOTORCYCLE",
                is_valid = "is_license_bike_valid",
                license = "license_bike",
            },
            BOAT = {
                type = "BOAT",
                is_valid = "is_license_boat_valid",
                license = "license_boat",
            },
            PILOT = {
                type = "PILOT",
                is_valid = "is_license_pilot_valid",
                license = "license_pilot",
            },
            CDL = {
                type = "CDL",
                is_valid = "is_license_truck_valid",
                license = "license_truck",
            },
        },
        licenseRecordValues = {
            -- License Information
            ["252c4250da9421cbd"] = function(pedData, ctx)
                return pedData[ctx.is_valid] and "VALID" or "SUSPENDED"
            end,
            ["878766af4964853a7"] = function(pedData, ctx)
                return pedData[ctx.is_valid] and "VALID" or "EXPIRED"
            end,
            ["_54iz1scv7"] = function(pedData)
                return os.date("%m/%d/%Y", os.time() + (60 * 60 * 24 * 365)) -- +1 year
            end,
            -- Civilian Information
            ["first"] = "first_name",
            ["last"] = "last_name",
            ["mi"] = "", -- No M.I. mapped
            ["dob"] = "dob",
            ["age"] = function(pedData)
                local birth = os.date("*t", os.time({year=tonumber(pedData.dob:sub(7,10)), month=tonumber(pedData.dob:sub(1,2)), day=tonumber(pedData.dob:sub(4,5))}))
                local now = os.date("*t")
                local age = now.year - birth.year
                if now.month < birth.month or (now.month == birth.month and now.day < birth.day) then
                    age = age - 1
                end
                return tostring(age)
            end,
            ["sex"] = "gender",
            ["residence"] = "address",
            ["zip"] = "postalCode",
        }
    }

}

if config.enabled then Config.RegisterPluginConfig(config.pluginName, config) end
