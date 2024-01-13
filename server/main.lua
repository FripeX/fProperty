ESX, Property, Sonnerie = nil, {}, {}

TriggerEvent("esx:getSharedObject", function(obj) 
	ESX = obj 
end)

RegisterServerEvent("fProperty:setPlayerToBucket")
AddEventHandler("fProperty:setPlayerToBucket", function(propertyID)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local PlayerBucket = Config.Buckets["player"]+propertyID
	SetPlayerRoutingBucket(_src, PlayerBucket)
	SetRoutingBucketPopulationEnabled(PlayerBucket, false)
end)

RegisterServerEvent("fProperty:setPlayerToNormalBucket")
AddEventHandler("fProperty:setPlayerToNormalBucket", function()
    local _src = source
    SetPlayerRoutingBucket(_src, 0)
end)

RegisterServerEvent("fProperty:ExitInteract")
AddEventHandler("fProperty:ExitInteract", function(propertyID)
    local _src = source
	if Property[propertyID] then 
		if Property[propertyID].players then 
			for i = 1, #Property[propertyID].players do 
				if (#Property[propertyID].players - 1) >= 1 then 
					if Property[propertyID].players[i].id == _src then 
						Property[propertyID].players[i] = {} 
					end
				else
					Property[propertyID].players = nil
					Property[propertyID] = nil
				end
			end
		end
	end
	TriggerClientEvent("fProperty:ExitProperty", _src, propertyID)
end)

RegisterServerEvent("fProperty:EnteringInteract")
AddEventHandler("fProperty:EnteringInteract", function(propertyType, propertyID, isVisit)
    local _src = source
	if Property[propertyID] == nil then 
		Property[propertyID] = {}
		Property[propertyID].players = {}	
	end
	table.insert(Property[propertyID].players, {
		id = _src,
		playerName = GetPlayerName(_src)
	})
	TriggerClientEvent("fProperty:EnteringProperty", _src, propertyType, propertyID, isVisit)
end)

RegisterServerEvent("fProperty:openJobInteractionsMenu")
AddEventHandler("fProperty:openJobInteractionsMenu", function()
    local _src = source 
    local xPlayer = ESX.GetPlayerFromId(_src)
	MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(propertiesJobs)
        for k, v in pairs(propertiesJobs) do
            v.propertyEntering = json.decode(v.propertyEntering)
			v.propertyGarage = json.decode(v.propertyGarage)
			v.propertyRented = json.decode(v.propertyRented)
			v.data = json.decode(v.data)
			v.dataMoney = json.decode(v.dataMoney)
			v.ownerList = json.decode(v.ownerList)
        end
		TriggerClientEvent("fProperty:OpenBuilderMenu", _src, propertiesJobs)
    end)
end)

RegisterServerEvent("fProperty:OpenOwnerList")
AddEventHandler("fProperty:OpenOwnerList", function(propertyID)
    local _src = source 
    local xPlayer = ESX.GetPlayerFromId(_src)
	TriggerClientEvent("fProperty:OpenOwnerMenu", _src, Property[propertyID].players)
end)

RegisterServerEvent("fProperty:AddProperty")
AddEventHandler("fProperty:AddProperty", function(PropertyInfos)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	MySQL.Async.execute('INSERT INTO properties (propertyLabel, propertyInteriors, propertyEntering, propertyGarage, propertyRented, garageInteriors, maxStorage) VALUES (@propertyLabel, @propertyInteriors, @propertyEntering, @propertyGarage, @propertyRented, @garageInteriors, @maxStorage)',{
		['propertyLabel'] = PropertyInfos.NameOfProperty,
		['propertyInteriors'] = PropertyInfos.Interiors,
		['propertyEntering'] = json.encode(PropertyInfos.EnteringPos),
		['propertyGarage'] = json.encode(PropertyInfos.GaragePos),
		['propertyRented'] = json.encode(PropertyInfos.RentedPos),
		['garageInteriors'] = PropertyInfos.garageInteriors,
        ['maxStorage'] = PropertyInfos.AllowedStorage
	})
	TriggerClientEvent('esx:showNotification', _src, "~b~Agence Immobilière~s~\nPropriété : ~o~"..PropertyInfos.NameOfProperty.."~s~ crée !")
	SetTimeout(250, function()
		MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
			for k, v in pairs(allProperties) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
			end
			TriggerClientEvent("fProperty:refreshProperty", -1, nil, allProperties) 
		end)
	end)
end)

RegisterServerEvent("fProperty:OwnedProperties")
AddEventHandler("fProperty:OwnedProperties", function(PropertyID)
    local _src = source 
    local xPlayer = ESX.GetPlayerFromId(_src)
	MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
		['propertyID'] = PropertyID
	}, function(propertyResult)
		if propertyResult[1] then 
			for k, v in pairs(propertyResult) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
				if #v.ownerList > 0 then 
					for t,b in pairs(v.ownerList) do 
						if v.propertyOwner == xPlayer.getIdentifier() or b.identifier == xPlayer.getIdentifier() then 
							TriggerClientEvent("fProperty:OpenPropertyMenu", _src, true, propertyResult)
						else
							TriggerClientEvent("fProperty:OpenPropertyMenu", _src, false, propertyResult)
						end
					end
				else
					if v.propertyOwner == xPlayer.getIdentifier() then 
						TriggerClientEvent("fProperty:OpenPropertyMenu", _src, true, propertyResult)
					else
						TriggerClientEvent("fProperty:OpenPropertyMenu", _src, false, propertyResult)
					end
				end
			end
		end
	end)
end)

RegisterServerEvent("fProperty:OwnedGarages")
AddEventHandler("fProperty:OwnedGarages", function(PropertyID)
    local _src = source 
    local xPlayer = ESX.GetPlayerFromId(_src)
	local propertyOwner = nil
	MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
		['propertyID'] = PropertyID
	}, function(propertyResult)
		if propertyResult[1] then 
			for k, v in pairs(propertyResult) do
				if v.propertyEntering ~= nil then 
					v.propertyEntering = json.decode(v.propertyEntering)
				end
				if v.propertyGarage ~= nil then 
					v.propertyGarage = json.decode(v.propertyGarage)
				end
				if v.propertyRented ~= nil then 
					v.propertyRented = json.decode(v.propertyRented)
				end
				if v.ownerList ~= nil then 
					v.ownerList = json.decode(v.ownerList)
				end
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				propertyOwner = v.propertyOwner
				MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
					['@propertyID'] = PropertyID
				}, function(propertyVehiclesResult)
					if propertyVehiclesResult[1] then 
						for k, v in pairs(propertyVehiclesResult) do
							v.data_vehicle = json.decode(v.data_vehicle)
						end
						if propertyOwner == xPlayer.getIdentifier() then 
							TriggerClientEvent("fProperty:OpenGarageMenu", _src, true, propertyResult, propertyVehiclesResult)
						else
							TriggerClientEvent("fProperty:OpenGarageMenu", _src, true, propertyResult, propertyVehiclesResult)
						end
					else
						if propertyOwner == xPlayer.getIdentifier() then 
							TriggerClientEvent("fProperty:OpenGarageMenu", _src, true, propertyResult, nil)
						else
							TriggerClientEvent("fProperty:OpenGarageMenu", _src, false, propertyResult, nil)
						end
					end
				end)
			end
		end
	end)
end)

RegisterServerEvent("fProperty:GivePropertyToPlayer")
AddEventHandler("fProperty:GivePropertyToPlayer", function(propertyID, xTarget)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
    local xOtherPlayer = ESX.GetPlayerFromId(xTarget)
    MySQL.Async.execute("UPDATE properties SET propertyOwner = @propertyOwner, ownerName = @ownerName WHERE propertyID = @propertyID", {
		["@propertyOwner"] = xOtherPlayer.identifier,
		["@ownerName"] = GetPlayerName(xTarget),
		["@propertyID"] = propertyID
	})
	TriggerClientEvent('esx:showNotification', _src, "~b~Agence Immobilière~s~\nVous avez attribué une propriété.")
	TriggerClientEvent('esx:showNotification', xTarget, "~b~Agence Immobilière~s~\nVous avez reçu une propriété.")
	SetTimeout(250, function()
		MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
			for k, v in pairs(allProperties) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
			end
			TriggerClientEvent("fProperty:refreshProperty", -1, nil, allProperties) 
		end)
	end)
end)

RegisterServerEvent("fProperty:GetVehiclesProperties")
AddEventHandler("fProperty:GetVehiclesProperties", function(PropertyID)
    local _src = source 
    local xPlayer = ESX.GetPlayerFromId(_src)
	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @owner AND propertyID = @propertyID", {
		['@owner'] = xPlayer.identifier,
		['@propertyID'] = 0
	}, function(ownedResult)
		for k,v in pairs (ownedResult) do 
            v.vehicle = json.decode(v.vehicle)
		end
		MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
			['propertyID'] = PropertyID
		}, function(propertiesVehiclesResult)
			for k,v in pairs (propertiesVehiclesResult) do 
				v.data_vehicle = json.decode(v.data_vehicle)
			end
			TriggerClientEvent("fProperty:OpenGestionGarageMenu", _src, ownedResult, propertiesVehiclesResult)
		end)
    end)
end)

RegisterServerEvent("fProperty:InteractionsGarage")
AddEventHandler("fProperty:InteractionsGarage", function(propertyID, vehicleInfos, Actions)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	if Actions == 1 then 
		MySQL.Async.execute("UPDATE owned_vehicles SET propertyID = @propertyID WHERE plate = @plate", {
			["@propertyID"] = propertyID, 
			["@plate"] = vehicleInfos.plate
		}, function(result)
			MySQL.Async.execute('INSERT INTO properties_vehicles (propertyID, plate, data_vehicle) VALUES (@propertyID, @plate, @data_vehicle)',{
				['propertyID'] = propertyID,
				['plate'] = vehicleInfos.plate,
				['data_vehicle'] = json.encode(vehicleInfos)
			})
			SetTimeout(120, function()
				MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID,
				}, function(vehicleResult)
					for k,v in pairs(vehicleResult) do 
						v.data_vehicle = json.decode(v.data_vehicle)
					end
					MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @owner AND propertyID = @propertyID", {
						["owner"] = xPlayer.getIdentifier(),
						["propertyID"] = 0
					}, function(ownedResult)
						for k,v in pairs(ownedResult) do 
							v.vehicle = json.decode(v.vehicle)
						end
						TriggerClientEvent("fProperty:reloadVehicles", _src, vehicleResult, ownedResult)
					end)
				end)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nVéhicule ajouté avec succès.")
			end)
		end)
	elseif Actions == 2 then 
		MySQL.Async.execute("UPDATE owned_vehicles SET propertyID = @propertyID WHERE plate = @plate", {
			["@propertyID"] = 0, 
			["@plate"] = vehicleInfos.plate
		}, function(result)
			MySQL.Async.execute('DELETE FROM properties_vehicles WHERE plate = @plate', {
				['@plate'] = vehicleInfos.plate
			})
			SetTimeout(120, function()
				MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID,
				}, function(vehicleResult)
					for k,v in pairs(vehicleResult) do 
						v.data_vehicle = json.decode(v.data_vehicle)
					end
					MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @owner AND propertyID = @propertyID", {
						["owner"] = xPlayer.getIdentifier(),
						["propertyID"] = 0
					}, function(ownedResult)
						for k,v in pairs(ownedResult) do 
							v.vehicle = json.decode(v.vehicle)
						end
						TriggerClientEvent("fProperty:reloadVehicles", _src, vehicleResult, ownedResult)
					end)
				end)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nVéhicule retiré avec succès.")
			end)
		end)
	end
end)

RegisterServerEvent("fProperty:AddVehicleIntoGarage")
AddEventHandler("fProperty:AddVehicleIntoGarage", function(propertyID, CurrentVehicle, vehicleLabel)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID AND plate = @plate", {
        ["propertyID"] = propertyID,
		["plate"] = CurrentVehicle.plate,
	}, function(result)
		if result[1] then
			MySQL.Async.execute("UPDATE properties_vehicles SET stored = @stored, data_vehicle = @data_vehicle WHERE plate = @plate", {
				["stored"] = 1, 
				["data_vehicle"] = json.encode(CurrentVehicle), 
				["plate"] = CurrentVehicle.plate
			})
			TriggerClientEvent('esx:showNotification', _src, ("Vous avez rangé un/une ~b~%s~s~"):format(vehicleLabel))
			TriggerClientEvent("fProperty:checkGarage", _src)
		else
			TriggerClientEvent("esx:showNotification", _src, "~r~Ce véhicule n'est pas attribué à ce garage.")
		end
    end)
end)

RegisterServerEvent("fProperty:UpdateStored")
AddEventHandler("fProperty:UpdateStored", function (vehiclePlate, vehicleLabel)
	local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
  	if vehiclePlate ~= nil then
		MySQL.Async.execute("UPDATE properties_vehicles SET stored = @stored WHERE plate = @plate", {
			["@stored"] = 0, 
			["@plate"] = vehiclePlate
		})
		TriggerClientEvent('esx:showNotification', _src, ("Vous avez sortie un/une ~b~%s~s~"):format(vehicleLabel))
	end
end)

RegisterServerEvent("fProperty:DeleteProperty")
AddEventHandler("fProperty:DeleteProperty", function (propertyID)
	local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
  	if propertyID ~= nil then
		SetTimeout(250, function()
			MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
				['@propertyID'] = propertyID
			}, function(propertyVehicle)
				if propertyVehicle[1] then 
					for k,v in pairs(propertyVehicle) do 
						MySQL.Async.execute("UPDATE owned_vehicles SET propertyID = @propertyID WHERE plate = @plate", {
							["@plate"] = v.plate,
							["@propertyID"] = 0
						})
					end
				end
			end)
			Wait(50)
			MySQL.Async.execute('DELETE FROM properties WHERE propertyID = @propertyID', {
				['@propertyID'] = propertyID
			})
			Wait(50)
			MySQL.Async.execute('DELETE FROM properties_vehicles WHERE propertyID = @propertyID', {
				['@propertyID'] = propertyID
			})
		end)
	end
	SetTimeout(450, function()
		MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
			for k, v in pairs(allProperties) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
			end
			TriggerClientEvent("fProperty:refreshProperty", -1, nil, allProperties) 
		end)
	end)
end)

RegisterServerEvent("fProperty:UpdateOwner")
AddEventHandler("fProperty:UpdateOwner", function (propertyID)
	local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
  	if propertyID ~= nil then
		local dataMoney = {black_money = {count = 0}, cash = {count = 0}}
		MySQL.Async.execute("UPDATE properties SET ownerName = @ownerName, propertyOwner = @propertyOwner, data = @data, dataMoney = @dataMoney, dataWeapon = @dataWeapon, ownerList = @ownerList WHERE propertyID = @propertyID", {
			["@propertyID"] = propertyID, 
			["@ownerName"] = "-",
			["@propertyOwner"] = "-",
			["@data"] = "{}",
			["@dataMoney"] = json.encode(dataMoney),
			["@dataWeapon"] = "{}",
			["@ownerList"] = "{}"
		})
		MySQL.Async.fetchAll("SELECT * FROM properties_vehicles WHERE propertyID = @propertyID", {
			['@propertyID'] = propertyID
		}, function(propertyVehicle)
			if propertyVehicle[1] then 
				for k,v in pairs(propertyVehicle) do 
					MySQL.Async.execute("UPDATE owned_vehicles SET propertyID = @propertyID WHERE plate = @plate", {
						["@plate"] = v.plate,
						["@propertyID"] = 0
					})
				end
			end
		end)
		MySQL.Async.execute('DELETE FROM properties_vehicles WHERE propertyID = @propertyID', {
			['@propertyID'] = propertyID
		})
		TriggerClientEvent('esx:showNotification', _src, "~b~Agence Immobilière~s~\nVous avez révoqué la propriété au joueur.")
		SetTimeout(250, function()
			MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
				for k, v in pairs(allProperties) do
					v.propertyEntering = json.decode(v.propertyEntering)
					v.propertyGarage = json.decode(v.propertyGarage)
					v.propertyRented = json.decode(v.propertyRented)
					v.data = json.decode(v.data)
					v.dataMoney = json.decode(v.dataMoney)
					v.ownerList = json.decode(v.ownerList)
				end
				TriggerClientEvent("fProperty:refreshProperty", -1, nil, allProperties) 
			end)
		end)
	end
end)

local storageCooldown = false 

RegisterServerEvent("fProperty:ActionsStorage")
AddEventHandler("fProperty:ActionsStorage", function (propertyID, dataStorage, itemName, currentStorage, count, Type)
	local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
	count = math.floor(count)
	if not storageCooldown then 
		storageCooldown = true 
		if Type == 1 then 
			if currentStorage.count + count <= currentStorage.max then 
				if count <= xPlayer.getInventoryItem(itemName).count then
					if not dataStorage[itemName] then 
						dataStorage[itemName] = {}
						dataStorage[itemName].label = ESX.GetItemLabel(itemName)
						dataStorage[itemName].name = itemName
						dataStorage[itemName].count = count
					else
						dataStorage[itemName].count = dataStorage[itemName].count + count
					end
					MySQL.Async.execute("UPDATE properties SET data = @data WHERE propertyID = @propertyID", {
						["@propertyID"] = propertyID, 
						["@data"] = json.encode(dataStorage)
					})
					xPlayer.removeInventoryItem(itemName, count)
					TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nDépot de : ~g~"..count.."~s~ "..dataStorage[itemName].label)
				else
					TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Vous n'avez pas autant de "..ESX.GetItemLabel(itemName).." sur vous !")
				end
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Stockage rempli !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		elseif Type == 2 then 
			if count <= dataStorage[itemName].count then 
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nRetrait de : ~g~"..count.."~s~ "..dataStorage[itemName].label)
				if dataStorage[itemName].count then 
					if (dataStorage[itemName].count - count) == 0 then 
						dataStorage[itemName] = nil 
					else
						dataStorage[itemName].count = dataStorage[itemName].count - count
					end
				end
				MySQL.Async.execute("UPDATE properties SET data = @data WHERE propertyID = @propertyID", {
					["@propertyID"] = propertyID, 
					["@data"] = json.encode(dataStorage)
				})
				xPlayer.addInventoryItem(itemName, count)
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Vous n'avez pas autant de "..ESX.GetItemLabel(itemName).." !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		end
		SetTimeout(750, function()
			storageCooldown = false 
		end)
	end 
end)

RegisterServerEvent("fProperty:ActionsMoney")
AddEventHandler("fProperty:ActionsMoney", function (propertyID, dataMoney, moneyType, count, Type, TypeActions)
	local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
	count = math.floor(count)
	if Type == 1 then 
		if TypeActions == 1 then 
			if count <= xPlayer.getAccount('black_money').money then
				if dataMoney[moneyType].count then 
					dataMoney[moneyType].count = dataMoney[moneyType].count + count
				else
					dataMoney[moneyType] = {}
					dataMoney[moneyType].count = count
				end
				MySQL.Async.execute("UPDATE properties SET dataMoney = @dataMoney WHERE propertyID = @propertyID", {
					["@propertyID"] = propertyID, 
					["@dataMoney"] = json.encode(dataMoney)
				})
				xPlayer.removeAccountMoney('black_money', count)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nDépot de : ~r~"..count.."$ ~s~d'argent sale")
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Vous n'avez pas autant d'argent sale sur vous !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		elseif TypeActions == 2 then 
			if count <= dataMoney[moneyType].count then 
				if dataMoney[moneyType].count then 
					dataMoney[moneyType].count = dataMoney[moneyType].count - count
				end
				MySQL.Async.execute("UPDATE properties SET dataMoney = @dataMoney WHERE propertyID = @propertyID", {
					["@propertyID"] = propertyID, 
					["@dataMoney"] = json.encode(dataMoney)
				})
				xPlayer.addAccountMoney('black_money', count)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nRetrait de : ~r~"..count.."$ ~s~d'argent propre")
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Il n'y a pas autant dans le coffre !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		end
	elseif Type == 2 then 
		if TypeActions == 1 then 
			if count <= xPlayer.getMoney() then
				if dataMoney[moneyType].count then 
					dataMoney[moneyType].count = dataMoney[moneyType].count + count
				else
					dataMoney[moneyType] = {}
					dataMoney[moneyType].count = count
				end
				MySQL.Async.execute("UPDATE properties SET dataMoney = @dataMoney WHERE propertyID = @propertyID", {
					["@propertyID"] = propertyID, 
					["@dataMoney"] = json.encode(dataMoney)
				})
				xPlayer.removeMoney(count)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nDépot de : ~g~"..count.."$ ~s~d'argent propre")
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Vous n'avez pas autant d'argent propre sur vous !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		elseif TypeActions == 2 then 
			if count <= dataMoney[moneyType].count then 
				if dataMoney[moneyType].count then 
					dataMoney[moneyType].count = dataMoney[moneyType].count - count
				end
				MySQL.Async.execute("UPDATE properties SET dataMoney = @dataMoney WHERE propertyID = @propertyID", {
					["@propertyID"] = propertyID, 
					["@dataMoney"] = json.encode(dataMoney)
				})
				xPlayer.addMoney(count)
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nRetrait de : ~g~"..count.."~s~$ d'argent propre")
			else
				TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\n~r~Il n'y a pas autant dans le coffre !")
			end
			SetTimeout(250, function()	
				MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
					["propertyID"] = propertyID
				}, function(propertyResult)
					for k, v in pairs(propertyResult) do
						v.propertyEntering = json.decode(v.propertyEntering)
						v.propertyGarage = json.decode(v.propertyGarage)
						v.propertyRented = json.decode(v.propertyRented)
						v.data = json.decode(v.data)
						v.dataMoney = json.decode(v.dataMoney)
						v.ownerList = json.decode(v.ownerList)
						for t,b in pairs(Property[v.propertyID].players) do 
							if b.id ~= nil then 
								TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
							end
						end
					end
				end)
			end)
		end
	end
end)

RegisterServerEvent("fProperty:NotInProperty")
AddEventHandler("fProperty:NotInProperty", function(playerSource)
	TriggerClientEvent("esx:showNotification", playerSource, "Le propriétaire n'est pas dans sa propriété.")
end)

RegisterServerEvent("fProperty:DringDring")
AddEventHandler("fProperty:DringDring", function(propertyOwner)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local xOwner = ESX.GetPlayerFromIdentifier(propertyOwner)
	if xOwner == nil then 
		return TriggerClientEvent("esx:showNotification", _src, "Le propriétaire n'est pas\nen ville.")
	end
	if Sonnerie[_src] then 
		return TriggerClientEvent("esx:showNotification", _src, "Vous avez déjà sonné, veuillez patienter.")
	end
	Sonnerie[_src] = {}
	TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nVous avez sonné à la porte de ~r~"..GetPlayerName(xOwner.source))
	table.insert(Sonnerie[_src], {
		playerName = GetPlayerName(_src),
		source = _src
	})
	TriggerClientEvent("fProperty:DringDringReponse", xOwner.source, Sonnerie[_src])
	SetTimeout(30000, function()
		Sonnerie[_src] = nil
	end)
end)

RegisterServerEvent("fProperty:AcceptDringDring")
AddEventHandler("fProperty:AcceptDringDring", function(xOtherPlayer, propertyID)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	if Sonnerie[xOtherPlayer] then 
		Sonnerie[xOtherPlayer] = nil
	end
	TriggerClientEvent('esx:showNotification', _src, "~b~Propriété~s~\nVous avez accepté ~r~"..GetPlayerName(xOtherPlayer))
    SetPlayerRoutingBucket(xOtherPlayer, Config.Buckets["player"]+propertyID)
	SetEntityCoords(GetPlayerPed(xOtherPlayer), GetEntityCoords(GetPlayerPed(_src)))
	if Property[propertyID].players then 
		table.insert(Property[propertyID].players, {
			id = xOtherPlayer,
			playerName = GetPlayerName(xOtherPlayer)
		})
	else
		Property[propertyID].players = {}
		table.insert(Property[propertyID].players, {
			id = xOtherPlayer,
			playerName = GetPlayerName(xOtherPlayer)
		})
	end
	TriggerClientEvent("fProperty:ReponsePerms", xOtherPlayer)
end)

RegisterServerEvent('fProperty:Announce')
AddEventHandler('fProperty:Announce', function(type, reason)
	local xPlayer = ESX.GetPlayerFromId(source)
	if type == 1 then
		TriggerClientEvent('esx:showAdvancedNotification', -1, "Agence Immobilière", "Ouverture", "L'~c~Agence imobilière~s~ est ~g~ouverte~s~ et prêt à vendre des propriétés.", "CHAR_MARTIN", 0)
	elseif type == 2 then
		TriggerClientEvent('esx:showAdvancedNotification', -1, "Agence Immobilière", "Fermeture", "L'~c~Agence imobilière~s~ est ~r~fermé~s~ à très bientôt.", "CHAR_MARTIN", 0)
	elseif type == 3 then
		TriggerClientEvent('esx:showAdvancedNotification', -1, 'Agence Immobilière', 'Divers', reason, 'CHAR_MARTIN', 0)
	end
end)

RegisterServerEvent("fProperty:getInfos")
AddEventHandler("fProperty:getInfos", function()
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local UserData, PropertiesData = {}, {}
	MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
        for k, v in pairs(allProperties) do
            v.propertyEntering = json.decode(v.propertyEntering)
			v.propertyGarage = json.decode(v.propertyGarage)
			v.propertyRented = json.decode(v.propertyRented)
			v.data = json.decode(v.data)
			v.dataMoney = json.decode(v.dataMoney)
			v.ownerList = json.decode(v.ownerList)
        end
		PropertiesData = allProperties
    end)
	MySQL.Async.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
		["@identifier"] = xPlayer.getIdentifier()
	}, function(userData)
		UserData = userData
    end)
	SetTimeout(250, function()
		TriggerClientEvent("fProperty:refreshProperty", _src, UserData, PropertiesData)
	end)
end)

RegisterServerEvent("fProperty:addOwner")
AddEventHandler("fProperty:addOwner", function(propertyID, ownerId, ownerData)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	if ownerId == nil then return end 
	local xTarget = ESX.GetPlayerFromId(ownerId)
	MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
		["@propertyID"] = propertyID
	}, function(propertyData)
		if not propertyData[1] then 
			return TriggerClientEvent("esx:showNotification", _src, "~r~Une erreur est survenu..")
		end
		if not ownerData then ownerData = {} end
		for i = 1, #ownerData do 
			if xTarget.getIdentifier() == ownerData[i].identifier then 
				return TriggerClientEvent("esx:showNotification", _src, "~r~Le joueur est déjà locataire.")
			end
		end 
		table.insert(ownerData, {identifier = xTarget.getIdentifier(), name = GetPlayerName(ownerId)})
		MySQL.Async.execute("UPDATE properties SET ownerList = @ownerList WHERE propertyID = @propertyID", {
			["@propertyID"] = propertyID,
			["@ownerList"] = json.encode(ownerData)
		})
		TriggerClientEvent("esx:showNotification", _src, ("~b~Propriété~s~\nVous avez ajouté %s à vos co-propriétaires."):format(GetPlayerName(ownerId)))
		TriggerClientEvent("esx:showNotification", ownerId, "~b~Propriété~s~\nVous êtes co-propriétaire de cette propriété.")
    end)
	SetTimeout(250, function()	
		MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
			["propertyID"] = propertyID
		}, function(propertyResult)
			for k, v in pairs(propertyResult) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
				for t,b in pairs(Property[v.propertyID].players) do 
					if b.id ~= nil then 
						TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
					end
				end
			end
		end)
		MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
			for k, v in pairs(allProperties) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
			end
			TriggerClientEvent("fProperty:refreshProperty", ownerId, nil, allProperties) 
		end)
	end)
end) 

RegisterServerEvent("fProperty:deleteOwner")
AddEventHandler("fProperty:deleteOwner", function(propertyID, propertyIdentifier, ownerData)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local xIdentifier = ESX.GetPlayerFromIdentifier(propertyIdentifier)
	MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
		["@propertyID"] = propertyID
	}, function(propertyData)
		if not propertyData[1] then 
			return TriggerClientEvent("esx:showNotification", _src, "~r~Une erreur est survenu..")
		end
		if not ownerData then 
			return TriggerClientEvent("esx:showNotification", _src, "~r~Une erreur est survenu..") 
		end
		for i = 1, #ownerData do 
			if propertyIdentifier == ownerData[i].identifier then 
				ownerData[i] = nil
			end
		end 
		MySQL.Async.execute("UPDATE properties SET ownerList = @ownerList WHERE propertyID = @propertyID", {
			["@propertyID"] = propertyID,
			["@ownerList"] = json.encode(ownerData)
		})
    end)
	SetTimeout(250, function()	
		MySQL.Async.fetchAll("SELECT * FROM properties WHERE propertyID = @propertyID", {
			["propertyID"] = propertyID
		}, function(propertyResult)
			for k, v in pairs(propertyResult) do
				v.propertyEntering = json.decode(v.propertyEntering)
				v.propertyGarage = json.decode(v.propertyGarage)
				v.propertyRented = json.decode(v.propertyRented)
				v.data = json.decode(v.data)
				v.dataMoney = json.decode(v.dataMoney)
				v.ownerList = json.decode(v.ownerList)
				for t,b in pairs(Property[v.propertyID].players) do 
					if b.id ~= nil then 
						TriggerClientEvent('fProperty:reloadInfos', b.id, propertyResult)
					end
				end
			end
		end)
	end)
	Wait(1000)
	MySQL.Async.fetchAll("SELECT * FROM properties", {}, function(allProperties)
		for k, v in pairs(allProperties) do
			v.propertyEntering = json.decode(v.propertyEntering)
			v.propertyGarage = json.decode(v.propertyGarage)
			v.propertyRented = json.decode(v.propertyRented)
			v.data = json.decode(v.data)
			v.dataMoney = json.decode(v.dataMoney)
			v.ownerList = json.decode(v.ownerList)
		end
		TriggerClientEvent("esx:showNotification", _src, ("~b~Propriété~s~\nVous avez enlevé %s de vos co-propriétaires."):format(GetPlayerName(xIdentifier.source)))
		TriggerClientEvent("esx:showNotification", xIdentifier.source, "~b~Propriété~s~\nVous n'êtes plus co-propriétaire de cette propriété.")
		TriggerClientEvent("fProperty:refreshProperty", xIdentifier.source, nil, allProperties) 
	end)
end) 
