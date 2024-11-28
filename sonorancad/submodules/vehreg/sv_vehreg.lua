CreateThread(function()
	Config.LoadPlugin('vehreg', function(pluginConfig)
		if pluginConfig.enabled then
			local placeholderReplace = function(message, placeholderTable)
				for k, v in pairs(placeholderTable) do
					message = message:gsub(k, v)
				end
				return message
			end
			RegisterNetEvent(GetCurrentResourceName() .. '::registerVeh', function(primary, plate, class, realName)
				local source = source
				local first = nil;
				local last = nil;
				local dob = nil;
				local sex = nil;
				local mi = nil;
				local age = nil;
				local aka = nil;
				local residence = nil;
				local zip = nil;
				local occupation = nil;
				local height = nil;
				local weight = nil;
				local skin = nil;
				local hair = nil;
				local eyes = nil;
				local emergencyContact = nil;
				local emergencyRelationship = nil;
				local emergencyContactNumber = nil;
				local img = nil;
				exports['sonorancad']:registerApiType('NEW_RECORD', 'general')
				exports['sonorancad']:registerApiType('GET_CHARACTERS', 'civilian')
				exports['sonorancad']:performApiRequest({
					{
						['apiId'] = GetIdentifiers(source)[Config.primaryIdentifier]
					}
				}, 'GET_CHARACTERS', function(res, err)
					if err == 404 then
						TriggerClientEvent('chat:addMessage', source, {
							color = {
								255,
								0,
								0
							},
							multiline = true,
							args = {
								'[CAD - ERROR] ',
								pluginConfig.language.noApiId
							}
						})
						return;
					else
						res = json.decode(res)
						if #res < 1 then
							TriggerClientEvent('chat:addMessage', source, {
								color = {
									255,
									0,
									0
								},
								multiline = true,
								args = {
									'[CAD - ERROR] ',
									pluginConfig.language.noCharFound
								}
							})
							return;
						end
						if #res[1].sections < 1 then
							TriggerClientEvent('chat:addMessage', source, {
								color = {
									255,
									0,
									0
								},
								multiline = true,
								args = {
									'[CAD - ERROR] ',
									pluginConfig.language.noCharFound
								}
							})
							return;
						end
						if #res[1].sections[1].fields < 1 then
							TriggerClientEvent('chat:addMessage', source, {
								color = {
									255,
									0,
									0
								},
								multiline = true,
								args = {
									'[CAD - ERROR] ',
									pluginConfig.language.noCharFound
								}
							})
							return;
						end
						first = res[1].sections[1].fields[1].value or "Unknown"
						last = res[1].sections[1].fields[2].value or "Unknown"
						mi = res[1].sections[1].fields[3].value or "Unknown"
						dob = res[1].sections[1].fields[4].value or "Unknown"
						age = res[1].sections[1].fields[5].value or "Unknown"
						sex = res[1].sections[1].fields[6].value or "Unknown"
						aka = res[1].sections[1].fields[7].value or "Unknown"
						residence = res[1].sections[1].fields[8].value or "Unknown"
						zip = res[1].sections[1].fields[9].value or "Unknown"
						occupation = res[1].sections[1].fields[10].value or "Unknown"
						height = res[1].sections[1].fields[11].value or "Unknown"
						weight = res[1].sections[1].fields[12].value or "Unknown"
						skin = res[1].sections[1].fields[13].value or "Unknown"
						hair = res[1].sections[1].fields[14].value or "Unknown"
						eyes = res[1].sections[1].fields[15].value or "Unknown"
						emergencyContact = res[1].sections[1].fields[16].value or "Unknown"
						emergencyRelationship = res[1].sections[1].fields[17].value or "Unknown"
						emergencyContactNumber = res[1].sections[1].fields[18].value or "Unknown"
						img = res[1].sections[1].fields[19].value or "Unknown"
					end
				end)
				Citizen.Wait(1000)
				if first ~= nil and last ~= nil then
					exports['sonorancad']:performApiRequest({
						{
							['user'] = GetIdentifiers(source)[Config.primaryIdentifier],
							['useDictionary'] = true,
							['recordTypeId'] = 5,
							['replaceValues'] = {
								['first'] = first,
								['last'] = last,
								['mi'] = mi,
								['dob'] = dob,
								['age'] = age,
								['sex'] = sex,
								['aka'] = aka,
								['residence'] = residence,
								['zip'] = zip,
								['occupation'] = occupation,
								['height'] = height,
								['weight'] = weight,
								['skin'] = skin,
								['hair'] = hair,
								['eyes'] = eyes,
								['emergencyContact'] = emergencyContact,
								['emergencyRelationship'] = emergencyRelationship,
								['emergencyContactNumber'] = emergencyContactNumber,
								['color'] = primary,
								['plate'] = plate,
								['type'] = class,
								['model'] = realName,
								['status'] = pluginConfig.defaultRegStatus,
								['_imtoih149'] = pluginConfig.defaultRegExpire,
								['img'] = img
							}
						}
					}, 'NEW_RECORD', function(res)
						res = tostring(res)
						if string.find(res, 'taken') ~= nil then
							TriggerClientEvent('chat:addMessage', source, {
								color = {
									255,
									0,
									0
								},
								multiline = true,
								args = {
									'[CAD - ERROR] ',
									pluginConfig.language.plateAlrRegisted
								}
							})
						else
							local placeHolders = {
								['{{PLATE}}'] = plate,
								['{{FIRST}}'] = first,
								['{{LAST}}'] = last
							}
							TriggerClientEvent('chat:addMessage', source, {
								color = {
									0,
									255,
									0
								},
								multiline = true,
								args = {
									'[CAD - SUCCESS] ',
									placeholderReplace(pluginConfig.language.successReg, placeHolders)
								}
							})
						end
					end)
				end
			end)
		end
	end)
end)
