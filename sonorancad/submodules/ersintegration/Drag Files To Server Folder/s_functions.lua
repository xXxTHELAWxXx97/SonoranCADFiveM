QBCore = nil
ESX = nil

Citizen.CreateThread(function()
    if Config.Enable_QBCore_Permissions.Check_By_Job or Config.Enable_QBCore_Permissions.Check_By_Permissions or (Config.GearData.Enable_Gear_Permissions and Config.GearData.Enable_QBCore_Permissions.Check_By_Job or Config.GearData.Enable_QBCore_Permissions.Check_By_Permissions) then
        QBCore = exports["qb-core"]:GetCoreObject()
    end

    if Config.Enable_ESX_Permissions.Check_By_Job or Config.Enable_ESX_Permissions.Check_By_Permissions or (Config.GearData.Enable_Gear_Permissions and Config.GearData.Enable_ESX_Permissions.Check_By_Job or Config.GearData.Enable_ESX_Permissions.Check_By_Permissions) then
        ESX = exports["es_extended"]:getSharedObject()
    end
end)

-- src: number - The user who toggled shift
-- isOnShift: boolean - Wether the user is now on shift
-- serviceType: string - The service type of the shift [police, fire, ems, tow]
function OnToggleShift(src, isOnShift, serviceType)
    -- Add your code here.
    -- print(src, isOnShift, serviceType)
end

exports('createCallout', function(callout)
    local newCalloutID = callout.id .. '-' .. os.time()
    Config.Callouts[newCalloutID] = Config.Callouts[callout.id]
    Config.Callouts[newCalloutID].id = newCalloutID
    Config.Callouts[newCalloutID].CalloutLocations = callout.data.CalloutLocations
    Config.Callouts[newCalloutID].PedWeaponData = callout.data.PedWeaponData
    Config.Callouts[newCalloutID].PedActionOnNoActionFound = callout.data.PedActionOnNoActionFound
    Config.Callouts[newCalloutID].PedChanceToFleeFromPlayer = callout.data.PedChanceToFleeFromPlayer
    Config.Callouts[newCalloutID].PedChanceToObtainWeapons = callout.data.PedChanceToObtainWeapons
    Config.Callouts[newCalloutID].PedChanceToAttackPlayer = callout.data.PedChanceToAttackPlayer
    Config.Callouts[newCalloutID].PedChanceToSurrender = callout.data.PedChanceToSurrender
    local returnData = {
        calloutId = newCalloutID,
    }
    return returnData
end)

--============ GIVE WEAPONS & AMMO (GEAR) ============--

RegisterServerEvent(Config.EventPrefix..":setWeaponsAmmoComponents")
AddEventHandler(Config.EventPrefix..":setWeaponsAmmoComponents", function(weaponData) 
    local src = source

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then 
            DebugPrint("ERROR: Could not find QBCore Player with ID: "..src)
            return 
        end
        if weaponData then
            for k, v in pairs(weaponData) do
                if exports['qb-inventory']:CanAddItem(src, v.weaponName, 1) then
                    exports['qb-inventory']:AddItem(src, v.weaponName, 1)

                    -- Add ammo for this weapon
                    if v.ammoType and v.ammoCount then
                        if exports['qb-inventory']:CanAddItem(src, v.ammoType, v.ammoCount) then
                            exports['qb-inventory']:AddItem(src, v.ammoType, v.ammoCount)
                        end
                    end

                    -- Add weapon attachments (components)
                    for _, component in pairs(v.componentList) do
                        if exports['qb-inventory']:CanAddItem(src, component, 1) then
                            exports['qb-inventory']:AddItem(src, component, 1)
                        end
                    end
                end
            end
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then 
            DebugPrint("ERROR: Could not find xPlayer with ID: "..src)
            return 
        end
        if weaponData then
            for k, v in pairs(weaponData) do
                if xPlayer.hasWeapon(v.weaponName) then
                    xPlayer.removeWeapon(v.weaponName)
                    xPlayer.addWeapon(v.weaponName, v.ammoCount)
                    xPlayer.addWeaponAmmo(v.weaponName, v.ammoCount)
                else
                    xPlayer.addWeapon(v.weaponName, v.ammoCount)
                end

                -- Add weapon attachments (components)
                for _, component in pairs(v.componentList) do
                    if xPlayer.hasWeaponComponent(v.weaponName, component) then
                        xPlayer.removeWeaponComponent(v.weaponName, component)
                        xPlayer.addWeaponComponent(v.weaponName, component)
                    else
                        xPlayer.addWeaponComponent(v.weaponName, component)
                    end
                end
            end
        end
    else
        -- Default GTA V Weapons
        for k, v in pairs(weaponData) do
            local playerPed = GetPlayerPed(src)
            GiveWeaponToPed(playerPed, GetHashKey(v.weaponName), v.ammoCount, false, true)
            if #v.componentList > 0 then
                for i, component in pairs(v.componentList) do
                    GiveWeaponComponentToPed(playerPed, GetHashKey(v.weaponName), GetHashKey(component)) 
                    DebugPrint("[^4DEBUG ^7] Set component "..component.." to given weapon "..v.weaponName)
                end
            end
        end
    end
    -- Add other or more logic here...
end)

--============ PERMISSIONS FOR SERVICES ============-- 

function CheckIsPlayerAllowedToPlayServiceByRoleOrGroups(source, rolesOrGroups) -- to toggle shift
    local permission = false

    -- If this is enabled, everyone can play any service at any time.
    if Config.EveryoneHasPermission then
        return true
    end

    -- Discord API Permissions
    if Config.Enable_Night_DiscordApi_Permissions then
        local isPermitted = exports.night_discordapi:IsMemberPartOfAnyOfTheseRoles(source, rolesOrGroups)
        if isPermitted then
            permission = true
        end
    end

    -- Ace Permissions
    if Config.Enable_Ace_Permissions then
        for _, roleOrGroup in pairs(rolesOrGroups) do
            if IsPlayerAceAllowed(source, roleOrGroup) then
                permission = true
                break
            end
        end
    end

    -- ESX Job Permissions
    if Config.Enable_ESX_Permissions.Check_By_Job then
        if ESX == nil then return print("You've enabled ESX job permissions, but the ESX framework has not been found...") end
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, job in pairs(rolesOrGroups) do
                if xPlayer.job.name == job then
                    permission = true
                    break
                end
            end
        end
    end

    -- ESX Permission Based
    if Config.Enable_ESX_Permissions.Check_By_Permissions then
        if ESX == nil then return print("You've enabled ESX group permissions, but the ESX framework has not been found...") end
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, group in pairs(rolesOrGroups) do
                if xPlayer.getGroup() == group then
                    permission = true
                    break
                end
            end
        end
    end

    -- QBCore Job Based
    if Config.Enable_QBCore_Permissions.Check_By_Job then
        if QBCore == nil then return print("You've enabled QBCore job permissions, but the QBCore framework has not been found...") end
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            for _, job in pairs(rolesOrGroups) do
                if Player.PlayerData.job.name == job then
                    permission = true
                    break
                end
            end
        end
    end

    -- QBCore Permission based
    if Config.Enable_QBCore_Permissions.Check_By_Permissions then
        if QBCore == nil then return print("You've enabled QBCore group permissions, but the QBCore framework has not been found...") end
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            for _, perm in pairs(rolesOrGroups) do
                if QBCore.Functions.HasPermission(source, perm) then
                    permission = true
                end
            end
        end
    end
    return permission
end

--============ PERMISSIONS FOR GEAR LOADOUTS ============-- 

function CheckIsPlayerAllowedToSelectGearByRoleOrGroups(source, rolesOrGroups) -- to toggle shift
    local permission = false

    -- If this is enabled, everyone can select any gear loadout/uniform.
    if not Config.GearData.Enable_Gear_Permissions then
        return true
    end

    -- Discord API Permissions
    if Config.GearData.Enable_Night_DiscordApi_Permissions then
        local isPermitted = exports.night_discordapi:IsMemberPartOfAnyOfTheseRoles(source, rolesOrGroups)
        if isPermitted then
            permission = true
        end
    end

    -- Ace Permissions
    if Config.GearData.Enable_Ace_Permissions then
        for _, roleOrGroup in pairs(rolesOrGroups) do
            if IsPlayerAceAllowed(source, roleOrGroup) then
                permission = true
                break
            end
        end
    end

    -- ESX Job Permissions
    if Config.GearData.Enable_ESX_Permissions.Check_By_Job then
        if ESX == nil then return print("You've enabled ESX job permissions, but the ESX framework has not been found...") end
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, job in pairs(rolesOrGroups) do
                if xPlayer.job.name == job then
                    permission = true
                    break
                end
            end
        end
    end

    -- ESX Permission Based
    if Config.GearData.Enable_ESX_Permissions.Check_By_Permissions then
        if ESX == nil then return print("You've enabled ESX group permissions, but the ESX framework has not been found...") end
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, group in pairs(rolesOrGroups) do
                if xPlayer.getGroup() == group then
                    permission = true
                    break
                end
            end
        end
    end

    -- QBCore Job Based
    if Config.GearData.Enable_QBCore_Permissions.Check_By_Job then
        if QBCore == nil then return print("You've enabled QBCore job permissions, but the QBCore framework has not been found...") end
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            for _, job in pairs(rolesOrGroups) do
                if Player.PlayerData.job.name == job then
                    permission = true
                    break
                end
            end
        end
    end

    -- QBCore Permission based
    if Config.GearData.Enable_QBCore_Permissions.Check_By_Permissions then
        if QBCore == nil then return print("You've enabled QBCore group permissions, but the QBCore framework has not been found...") end
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            for _, perm in pairs(rolesOrGroups) do
                if QBCore.Functions.HasPermission(source, perm) then
                    permission = true
                end
            end
        end
    end
    return permission
end

--============ OTHER FUNCTIONS ============--

function GetCustomPlayerName(id) -- Used for shift data only to represent the "Officer/Firefighter/Medics name or callsign"
    local src = tonumber(id)
    local srcName = GetPlayerName(src)

    if Config.Enable_Night_Shifts.ManageShiftsByMDT then
        local shiftDataResults = exports['night_shifts']:GetUserShiftData(src) or nil
        -- print(json.encode(shiftDataResults))
        if shiftDataResults and #shiftDataResults > 0 then
            for k, v in pairs(shiftDataResults) do

                srcName = v.last_callsign or v.userCallsign

                -- if type(v) == "table"then
                --     print("Key: "..k.." | Value: "..json.encode(v))
                -- elseif type(v) == "boolean" then
                --     if v then
                --         print("Key: "..k.." | Value: true")
                --     else
                --         print("Key: "..k.." | Value: false")
                --     end
                -- else
                --     print("Key: "..k.." | Value: "..v)
                -- end
            end
        end
    end

    return srcName
    -- Or write your own stuff here.
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function allToUpper(str)
    return (string.upper(str))
end

-- Randomly generated NPC personal data

function GenerateRandomLicenseResult()  
    -- Calculate total weight
    local totalWeight = 0
    for _, result in pairs(Config.RandomLicenseResults) do
        totalWeight = totalWeight + result.Chance
    end
    
    -- Generate random number based on total weight
    local chance = math.random(1, totalWeight)
    local runningTotal = 0
    
    -- Check each result against its proportional range
    for _, result in pairs(Config.RandomLicenseResults) do
        runningTotal = runningTotal + result.Chance
        if chance <= runningTotal then
            return result.Status, result.IsStatusValid, result.Colour, result.Icon
        end
    end

    -- If no license result is found (shouldn't happen), return nil
    return nil, nil, nil, nil
end

function GenerateRandomFlagsOrMarkers()
    local FlagsOrMarkers = {}
    local FLAG_OR_MARKER_CHANCE = Config.ChanceToHaveRecords
    
    -- Initial check if person should have any flags or markers at all
    if math.random(1, 100) > FLAG_OR_MARKER_CHANCE then
        return {
            armed_and_dangerous = false,
            assault = false,
            burglary = false,
            drug_related = false,
            gang_affiliation = false,
            homicide = false,
            kidnapping = false,
            mental_health_issues = false,
            sex_offense = false,
            terrorism = false,
            theft = false,
            traffic_violation = false,
            wanted_person = false,
            other = false,
            active_warrant = false,
        }
    end
    
    -- Helper function to determine if warrant should be active
    local function shouldHaveFlagOrMarker()
        return math.random(1, 100) <= FLAG_OR_MARKER_CHANCE
    end

    -- Generate a suitable flag_description based off the flag or marker which is true
    local function GenerateFlagDescription(flagsOrMarkers)
        local descriptions = {}
        for flag, isTrue in pairs(flagsOrMarkers) do
            if isTrue and Config.RandomFlagsOrMarkersDescriptions[flag] then
                local descriptionsList = Config.RandomFlagsOrMarkersDescriptions[flag]
                local randomIndex = math.random(#descriptionsList)
                table.insert(descriptions, descriptionsList[randomIndex])
            end
        end
        if #descriptions == 0 then
            return "None"
        else
            return table.concat(descriptions, ", ")
        end
    end
    
    FlagsOrMarkers = {
        armed_and_dangerous = shouldHaveFlagOrMarker(),
        assault = shouldHaveFlagOrMarker(),
        burglary = shouldHaveFlagOrMarker(),
        drug_related = shouldHaveFlagOrMarker(),
        gang_affiliation = shouldHaveFlagOrMarker(),
        homicide = shouldHaveFlagOrMarker(),
        kidnapping = shouldHaveFlagOrMarker(),
        mental_health_issues = shouldHaveFlagOrMarker(),
        sex_offense = shouldHaveFlagOrMarker(),
        terrorism = shouldHaveFlagOrMarker(),
        theft = shouldHaveFlagOrMarker(),
        traffic_violation = shouldHaveFlagOrMarker(),
        wanted_person = shouldHaveFlagOrMarker(),
        other = shouldHaveFlagOrMarker(),
        active_warrant = shouldHaveFlagOrMarker(),
    }

    local flag_description = GenerateFlagDescription(FlagsOrMarkers)
    FlagsOrMarkers.flag_description = flag_description

    return FlagsOrMarkers
end

function GenerateRandomHomeAddress()
    local library = Config.RandomHomeAddressList
    local randomIndex = math.random(#library)
    return library[randomIndex]
end

function GenerateRandomDOB()
    -- Define the range of years
    local minYear = 1970
    local maxYear = 2005
    
    -- Generate a random year within the range
    local year = math.random(minYear, maxYear)
    
    -- Generate a random month (1-12)
    local month = math.random(1, 12)
    
    -- Generate a random day within the month
    local maxDay
    if month == 2 then
        -- Check for February
        if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
            -- Leap year
            maxDay = 29
        else
            maxDay = 28
        end
    elseif month == 4 or month == 6 or month == 9 or month == 11 then
        -- Months with 30 days
        maxDay = 30
    else
        -- Months with 31 days
        maxDay = 31
    end
    
    -- Generate a random day
    local day = math.random(1, maxDay)
    
    -- Determine the format and return the generated date of birth
    if Config.DOBFormat == "en" then
        return string.format("%02d-%02d-%04d", day, month, year)
    elseif Config.DOBFormat == "us" then
        return string.format("%02d-%02d-%04d", month, day, year)
    else
        return "Unknown"
    end
end

function GenerateRandomNationality()
    local randomIndex = math.random(1, #Config.RandomNationalities)
    local nationality = Config.RandomNationalities[randomIndex]
    return nationality
end

function GenerateRandomPhoneNumber()
    -- UK format
    local phoneNumber = "07" .. math.random(10000000, 99999999)
    return phoneNumber

    -- -- US format
    -- local phoneNumber = "1" .. math.random(2000000000, 9999999999)
    -- return phoneNumber

    -- -- NL format
    -- local phoneNumber = "06" .. math.random(10000000, 99999999)
    -- return phoneNumber
end

-- function GenerateRandomPostalCode()
--     -- UK / NL format (Example result: "1234 AB")
--     local postalCode = math.random(1000, 9999) .. " " .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90))
--     return postalCode

--     -- -- US format (Example result: "12345")
--     -- local postalCode = math.random(10000, 99999)
--     -- return postalCode
-- end

function GenerateRandomStateCityPostalCodeRangeAndAddress()    
    -- Error handling for empty/nil tables
    if not Config.RandomStates or #Config.RandomStates == 0 then
        DebugPrint("^1ERROR ^7Config.RandomStates is empty or nil")
        return nil, nil, nil, nil, nil, nil
    end

    local country = Config.RandomStates[math.random(#Config.RandomStates)]
    if not country or not country.States or #country.States == 0 then
        DebugPrint("^1ERROR ^7Country or States table is empty or nil")
        return nil, nil, nil, nil, nil, nil
    end

    local randomState = country.States[math.random(#country.States)]    
    if not randomState or not randomState.Cities or #randomState.Cities == 0 then
        DebugPrint("^1ERROR ^7RandomState or Cities table is empty or nil")
        return nil, nil, nil, nil, nil, nil
    end

    local randomCity = randomState.Cities[math.random(#randomState.Cities)] 
    if not randomCity or not randomCity.Addresses or #randomCity.Addresses == 0 then
        DebugPrint("^1ERROR ^7RandomCity or Addresses table is empty or nil")
        return nil, nil, nil, nil, nil, nil
    end

    -- Generate postal code with proper formatting
    local randomPostalCode = math.random(randomCity.PostalCodeRange[1], randomCity.PostalCodeRange[2])
    local randomAddress = randomCity.Addresses[math.random(#randomCity.Addresses)]
    local randomAddressType = GenerateRandomAdressType()
    
    -- Remove debug prints or make them conditional
    if Config.Debug then
        print(country.Country or "not found")
        print(randomState.State or "not found")
        print(randomCity.City or "not found")
        print(randomPostalCode or "not found")
        print(randomAddress.Address or "not found")
        print(randomAddressType or "not found")
    end
    
    -- Make sure we're returning the actual country name and address type in the correct order
    return country.Country or "USA", 
           randomState.State or "San Andreas", 
           randomCity.City or "Los Santos", 
           tostring(randomPostalCode) or "12345", 
           randomAddress.Address or "123 Night St", 
           randomAddressType -- This should be the property type, not the country
end

function GenerateRandomAdressType()
    return Config.RandomPropertyTypes[math.random(#Config.RandomPropertyTypes)]
end

function GenerateRandomEmail(first_name, last_name)
    local randomDomain = Config.FictiveEmailDomains[math.random(#Config.FictiveEmailDomains)]
    return first_name .. "." .. last_name .. randomDomain
end


function GenerateListOfRandomInventoryItems()
    local inventory = {}

    local itemsPool = Config.NPCInventory

    -- Generate a random number of items (between 0 and the total number of items).
    local numItems = math.random(#itemsPool)

    -- Shuffle the items pool.
    for i = #itemsPool, 2, -1 do
        local j = math.random(i)
        itemsPool[i], itemsPool[j] = itemsPool[j], itemsPool[i]
    end

    -- Add random items to the inventory, limited to a maximum of 8 items.
    for i = 1, math.min(#itemsPool, 8) do
        local item = itemsPool[i]
        table.insert(inventory, {name = item.name, illegal = item.illegal})
    end

    return inventory
end

--============ Discord Webhooks ============--

RegisterServerEvent(Config.EventPrefix..':sendDiscordEmbedMessage')
AddEventHandler(Config.EventPrefix..':sendDiscordEmbedMessage', function(data)
    local src = source
    SendDiscordEmbedMessage(src, data)
end)

function SendDiscordEmbedMessage(src, data)
    if Config.Enable_Discord_Webhooks then
        local webhookURL = "https://discord.com/api/webhooks/964210045220958251/2qzKEBdUceFxJ1Wt3OhmL6WbqP9AUJqrJjbtd0U31MFV8l9uOODvn7mfmsm5I3wxzE1d"
        local webhooKType = data.discordwebhookurltype 
        if webhooKType == nil then webhooKType = '' end
        if webhooKType == 'dispatch' then
            webhookURL = "https://discord.com/api/webhooks/964210045220958251/2qzKEBdUceFxJ1Wt3OhmL6WbqP9AUJqrJjbtd0U31MFV8l9uOODvn7mfmsm5I3wxzE1d"
        else
            webhookURL = "https://discord.com/api/webhooks/964210045220958251/2qzKEBdUceFxJ1Wt3OhmL6WbqP9AUJqrJjbtd0U31MFV8l9uOODvn7mfmsm5I3wxzE1d"
        end

        local discordId = getDiscordIdFromSource(src) or 0
        local embed = {
            {
                ["title"] = "**"..(data.title or "DISPATCH MESSAGE SYSTEM").."**" ,
                ["description"] = data.description or "",
                ["color"] = data.color or 11876095,
                ["author"] = {
                    ["name"] = data.authorname or "",
                    -- ["icon_url"] = data.authoravatarurl or ""
                },
                ["fields"] = {
                    {
                        ["name"] = data.sender or "",
                        ["value"] = "<@"..(discordId or "Unknown")..">",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Get the Emergency Response Simulator",
                        ["value"] = "[Nights Software](https://store.nights-software.com)",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Go for the full experience and expand your options",
                        ["value"] = "[London Studios](https://londonstudios.net)",
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = data.footer or "".." "..os.date("%Y").." | "..os.date("%d-%m-%Y at %H:%M:%S"),
                    ["icon_url"] = data.footericon or "https://assets.ea-rp.com/img/ERS_Logo.png"
                },
                ["thumbnail"] = {
                    ["url"] = data.thumbnail or "https://assets.ea-rp.com/img/ERS_Logo_Sq.png",
                },
                ["image"] = {
                    ["url"] = data.image or "" -- No url is no image, which is fine as well
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") -- UTC timestamp
            }
        }
        PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({data.systemname or "NS - ERS System", embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

-- Usage Example Server Side
-- exports['night_ers']:SendDiscordEmbedMessage(source, messageData)

exports('SendDiscordEmbedMessage', SendDiscordEmbedMessage)

--============ Debug ============--

function DebugPrint(msg)
    if Config.Debug then
        if msg ~= nil then
            print("["..GetCurrentResourceName().."] "..msg)
        end
    end
end