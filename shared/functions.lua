myProperties, myVehicles, myOwnedVehicles, myGarageVehicles, allProperties = {}, {}, {}, {}, {}

LookInfos = function(args)
	if type(args) == "number" then 
		if not args or not type(args) == "number" then return "~r~Aucun" else return "~g~"..math.round(args).."$~s~" end
	else
		if not args or args == "" then return "~r~Non-Défini" else return "~o~"..args.."~s~" end
	end
end

resetVar = function()
	PropertyName, PropertyPrice, ViewCoordsPlayer, AddGarage = nil, nil, nil, false 
    Config.BuilderSettings.CheckForView = false 
    Config.BuilderSettings.InteriorsList.Index = 1 
    Config.BuilderSettings.StorageList.Index = 1 
    Config.BuilderSettings.AddGarageCheckbox = false 
    Config.BuilderSettings.GarageList.Index = 1 
	Config.BuilderSettings.PropertyInfos = {}
end

GetVehicleLabel = function(VehicleModel)
    return GetLabelText(GetDisplayNameFromVehicleModel(VehicleModel))
end

SellProperty = function(propertyID, propertyPlayer)
    TriggerServerEvent("cxProperty:GivePropertyToPlayer", propertyID, GetPlayerServerId(propertyPlayer))
end

GetStreetForCoords = function(posX, posY, posZ)
    return GetStreetNameFromHashKey(GetStreetNameAtCoord(posX, posY, posZ))
end

Input = function(entryTitle, textEntry, inputText, maxLength)
    AddTextEntry(entryTitle, textEntry)
    DisplayOnscreenKeyboard(1, entryTitle, "", inputText, "", "", "", maxLength)
    blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

viewsMarkers = function(bool)
    isBool = bool
	CreateThread(function()
		while isBool do
			Wait(1)
            EntityPos = GetEntityCoords(PlayerPedId())
            if Config.BuilderSettings.PropertyInfos.EnteringPos ~= nil then
                if #(vector3(Config.BuilderSettings.PropertyInfos.EnteringPos.x, Config.BuilderSettings.PropertyInfos.EnteringPos.y, Config.BuilderSettings.PropertyInfos.EnteringPos.z) - EntityPos) < 4.0 then
                    DrawMarker(22, Config.BuilderSettings.PropertyInfos.EnteringPos.x, Config.BuilderSettings.PropertyInfos.EnteringPos.y, Config.BuilderSettings.PropertyInfos.EnteringPos.z, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 10, 255, 200, 255, 1, 0, 0, 2)
                end
            end
            if Config.BuilderSettings.PropertyInfos.RentedPos ~= nil then
                if #(vector3(Config.BuilderSettings.PropertyInfos.RentedPos.x, Config.BuilderSettings.PropertyInfos.RentedPos.y, Config.BuilderSettings.PropertyInfos.RentedPos.z) - EntityPos) < 4.0 then
                    DrawMarker(22, Config.BuilderSettings.PropertyInfos.RentedPos.x, Config.BuilderSettings.PropertyInfos.RentedPos.y, Config.BuilderSettings.PropertyInfos.RentedPos.z, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 255, 0, 0, 255, 1, 0, 0, 2)
                end
            end
            if Config.BuilderSettings.PropertyInfos.GaragePos ~= nil then
                if #(vector3(Config.BuilderSettings.PropertyInfos.GaragePos.x, Config.BuilderSettings.PropertyInfos.GaragePos.y, Config.BuilderSettings.PropertyInfos.GaragePos.z) - EntityPos) < 4.0 then
                    DrawMarker(22, Config.BuilderSettings.PropertyInfos.GaragePos.x, Config.BuilderSettings.PropertyInfos.GaragePos.y, Config.BuilderSettings.PropertyInfos.GaragePos.z, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 10, 255, 200, 255, 1, 0, 0, 2)
                end
            end
		end
	end)
end

SetPlayerIntoBucket = function(Actions)
    if Actions == true then 
        for k,v in pairs(myProperties) do 
            TriggerServerEvent("cxProperty:setPlayerToBucket", v.propertyID)
        end
    else
        TriggerServerEvent("cxProperty:setPlayerToNormalBucket")
    end
end

getData = function(propertyID)
	DataStorage = {}
	for k,v in pairs(myProperties) do
		if v.propertyID == propertyID then 
			if v.data ~= nil then 
				for t,b in pairs(v.data) do 
					DataStorage = v.data					
				end
			end
		end			
	end
end

Announce = function(Index)
    if Index ~= 3 then
        TriggerServerEvent("cxProperty:Announce", Index, nil)
    else
        local Reason = Input("Announce", "Annonce (75 caractères max): ", "", 75)
        TriggerServerEvent("cxProperty:Announce", Index, Reason)
    end
end

LoadAllVehicles = function(ID, GarageType)
    if AddSpawnVehicle then 
        for k, v in pairs(AddSpawnVehicle) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end
    SetTimeout(500, function()
        local counter = 0
        for k,v in pairs (myVehicles) do 
            for t,b in pairs (Config.GarageInteriors) do
                if GarageType == b.IdType then 
                    if ID == v.propertyID then 
                        counter = counter + 1
                        if v.stored == 1 then 
                            local CurrentVehicles = v.data_vehicle.model
                            RequestModel(CurrentVehicles)
                            while not HasModelLoaded(CurrentVehicles) do
                                Wait(1)
                            end
                            SpawnVehicle = CreateVehicle(CurrentVehicles, Config.GarageInteriors[t].AllowedPositions[counter].pos, Config.GarageInteriors[t].AllowedPositions[counter].heading, true, false)
                            setVehicleProps(SpawnVehicle, v.data_vehicle)
                            SetVehicleUndriveable(SpawnVehicle, true)
                            AddSpawnVehicle[counter] = SpawnVehicle
                        end                
                    end
                end
            end
        end
    end)
end

EnterProperty = function(propertyType, propertyID, isVisit)
    TriggerServerEvent("cxProperty:EnteringInteract", propertyType, propertyID, isVisit)
end

ExitProperty = function(propertyID)
    TriggerServerEvent("cxProperty:ExitInteract", propertyID)
end

RegisterNetEvent("cxProperty:ExitProperty")
AddEventHandler("cxProperty:ExitProperty", function(propertyID)
    for k,v in pairs (myProperties) do 
        if v.propertyID == propertyID then 
            DoScreenFadeOut(500)
            Wait(500)
            if InProperty then 
                InProperty, myProperties, myVehicles, myOwnedVehicles, myGarageVehicles = false, {}, {}, {}, {}
                SetEntityCoords(PlayerPedId(), vector3(v.propertyEntering.x, v.propertyEntering.y, v.propertyEntering.z))
            end
            if InGarage then 
                InGarage, myProperties, myVehicles, myOwnedVehicles, myGarageVehicles = false, {}, {}, {}, {}
                SetEntityCoords(PlayerPedId(), vector3(v.propertyGarage.x, v.propertyGarage.y, v.propertyGarage.z))
            end
            SetPlayerIntoBucket(false)
            OwnedPropertyGestionMenu.Closed()
            if AddSpawnVehicle then 
                for k, v in pairs(AddSpawnVehicle) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
            end
            Wait(500)
            DoScreenFadeIn(500) 
        end
    end
end)

RegisterNetEvent("cxProperty:EnteringProperty")
AddEventHandler("cxProperty:EnteringProperty", function(propertyType, propertyID, isVisit)
    if not isVisit then InVisit = false else InVisit = true end
    for k,v in pairs (Config.PropertiesInteriors) do 
        if v.IdType == propertyType then 
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(PlayerPedId(), v.IPL)
            InProperty = true
            SetPlayerIntoBucket(true)
            OwnedPropertyInteractionsMenu.Closed()
            Wait(500)
            DoScreenFadeIn(500) 
        end
    end
end)

EnterGarage = function(isVisit)
    if not isVisit then InVisit = false else InVisit = true end
    for k,v in pairs(myProperties) do 
        for t,b in pairs(Config.GarageInteriors) do 
            if b.IdType == v.garageInteriors then 
                DoScreenFadeOut(500)
                Wait(500)
                SetPlayerIntoBucket(true)
                SetEntityCoords(PlayerPedId(), b.IPL)
                InGarage = true
                if not isVisit then 
                    LoadAllVehicles(v.propertyID, v.garageInteriors)
                end
                if MenuIsOpen then 
                    PropertyGarageMenu.Closed()
                end
                Wait(500)
                DoScreenFadeIn(500) 
            end
        end
    end
end

ExitGarageWithVehicle = function(CurrentVehicle)
    DoScreenFadeOut(500)
    Wait(600)
    for _, vehicle in pairs(AddSpawnVehicle) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    local exitVehicle = CurrentVehicle
    SetPlayerIntoBucket(false)
    Wait(600)
    for k,v in pairs(myProperties) do 
        RequestModel(exitVehicle.model)
        while not HasModelLoaded(exitVehicle.model) do
            Wait(1)
        end
        if InGarage == true then 
            ESX.Game.SpawnVehicle(exitVehicle.model, vector3(v.propertyRented.x, v.propertyRented.y, v.propertyRented.z), v.propertyRented.w, function(vehicle) 
                setVehicleProps(vehicle, CurrentVehicle)
                SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true, false)
            end)
            InGarage, myProperties, myVehicles, myOwnedVehicles, myGarageVehicles = false, {}, {}, {}, {}
            TriggerServerEvent("cxProperty:UpdateStored", CurrentVehicle.plate, GetVehicleLabel(exitVehicle.model))
        end
    end
    Wait(1000)
    DoScreenFadeIn(1000) 
end

refreshInventory = function()
	CreateThread(function()
		ESX.PlayerData = ESX.GetPlayerData()
	end)
end

countData = function(propertyID)
	countStorage = {}
	local counterData = 0
	for k,v in pairs(myProperties) do
		if v.propertyID == propertyID then 
			countStorage.max = v.maxStorage
			if v.data ~= nil then 
				for t,b in pairs(v.data) do 
					counterData = counterData + v.data[t].count					
				end
			end
		end
	end
	countStorage.count = counterData
	WaitStorage = true
end

setVehicleProps = function(vehicle, vehicleProps)
	ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
	SetVehicleEngineHealth(vehicle, vehicleProps["engineHealth"] and vehicleProps["engineHealth"] + 0.0 or 1000.0)
    SetVehicleBodyHealth(vehicle, vehicleProps["bodyHealth"] and vehicleProps["bodyHealth"] + 0.0 or 1000.0)
    SetVehicleFuelLevel(vehicle, vehicleProps["fuelLevel"] and vehicleProps["fuelLevel"] + 0.0 or 1000.0)
    if vehicleProps["windows"] then
        for windowId = 1, 13, 1 do
            if vehicleProps["windows"][windowId] == false then
                SmashVehicleWindow(vehicle, windowId)
            end
        end
    end
    if vehicleProps["tyres"] then
        for tyreId = 1, 7, 1 do
            if vehicleProps["tyres"][tyreId] ~= false then
                SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
            end
        end
    end
    if vehicleProps["doors"] then
        for doorId = 0, 5, 1 do
            if vehicleProps["doors"][doorId] ~= false then
                SetVehicleDoorBroken(vehicle, doorId - 1, true)
            end
        end
    end
end

getVehicleProps = function(vehicle)
    if DoesEntityExist(vehicle) then
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps["tyres"] = {}
        vehicleProps["windows"] = {}
        vehicleProps["doors"] = {}
        for id = 1, 7 do
            local tyreId = IsVehicleTyreBurst(vehicle, id, false)
            if tyreId then
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = tyreId
                if tyreId == false then
                    tyreId = IsVehicleTyreBurst(vehicle, id, true)
                    vehicleProps["tyres"][ #vehicleProps["tyres"]] = tyreId
                end
            else
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = false
            end
        end
        for id = 1, 13 do
            local windowId = IsVehicleWindowIntact(vehicle, id)

            if windowId ~= nil then
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = windowId
            else
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = true
            end
        end
        for id = 0, 5 do
            local doorId = IsVehicleDoorDamaged(vehicle, id)
            if doorId then
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = doorId
            else
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = false
            end
        end
        vehicleProps["engineHealth"] = GetVehicleEngineHealth(vehicle)
        vehicleProps["bodyHealth"] = GetVehicleBodyHealth(vehicle)
        vehicleProps["fuelLevel"] = GetVehicleFuelLevel(vehicle)
        return vehicleProps
    end
end

RegisterNetEvent("cxProperty:refreshProperty")
AddEventHandler("cxProperty:refreshProperty", function(userData, propertiesData)
	Properties = propertiesData
    allProperties = propertiesData
    if userData ~= nil then 
        UsersInfos = userData
    end
    loadBlips()
end)

RegisterNetEvent("cxProperty:reloadVehicles")
AddEventHandler("cxProperty:reloadVehicles", function(vehicleData, ownedData)
	SetTimeout(120, function()
        myVehicles = vehicleData
        myGarageVehicles = vehicleData
        myOwnedVehicles = ownedData
        for k,v in pairs(myProperties) do 
            LoadAllVehicles(v.propertyID, v.garageInteriors)
        end
    end)
end)

RegisterNetEvent("cxProperty:reloadInfos")
AddEventHandler("cxProperty:reloadInfos", function(propertyData)
    myProperties = propertyData
    for k,v in pairs(myProperties) do 
        getData(v.propertyID)
        countData(v.propertyID)
    end
end)

RegisterNetEvent("cxProperty:checkGarage")
AddEventHandler("cxProperty:checkGarage", function()
    local pVehicle = GetVehiclePedIsIn(PlayerPedId())
    DeleteEntity(pVehicle)
end)

RegisterNetEvent("cxProperty:DringDringReponse")
AddEventHandler("cxProperty:DringDringReponse", function(Sonnerie)
    GetInvite = Sonnerie
    if not InProperty then 
        for k,v in pairs(GetInvite) do 
            TriggerServerEvent("cxProperty:NotInProperty", v.source)
        end
        GetInvite = {}
        return 
    end
	for k,v in pairs (GetInvite) do 
		ESX.ShowNotification("~g~"..v.playerName.." sonne à votre porte rendez-vous vers votre porte pour lui ouvrir.")
		SetTimeout(30000, function()
			table.remove(GetInvite, k)
		end)
	end
end)

RegisterNetEvent("cxProperty:ViewInteriors")
AddEventHandler("cxProperty:ViewInteriors", function(bool)
    if bool == true then 
        InView = true 
    else
        InView = false 
    end
    CreateThread(function()
        while InView do 
            Wait(1)
        end
    end)
end)

AddEventHandler('onResourceStart', function()
	TriggerServerEvent("cxProperty:getInfos")
end)
  
blipsCooldown = false

loadBlips = function()
    RemoveBlip(GarageBlips)
    RemoveBlip(PropertyBlips)
    RemoveBlip(YourGarageBlips)
    RemoveBlip(YourPropertyBlips)
    if not blipsCooldown then 
        blipsCooldown = true 
        for k,v in pairs (Properties) do 
            for t,b in pairs (UsersInfos) do
                SetTimeout(450, function()
                    if json.encode(v.ownerList) == "[]" then 
                        if v.propertyOwner == b.identifier then 
                            if v.propertyEntering == nil then 
                                YourGarageBlips = AddBlipForCoord(v.propertyGarage.x, v.propertyGarage.y, v.propertyGarage.z)
                                SetBlipSprite(YourGarageBlips, 524)
                                SetBlipDisplay(YourGarageBlips, 4)
                                SetBlipScale(YourGarageBlips, 0.6)
                                SetBlipColour(YourGarageBlips, 17)
                                SetBlipAsShortRange(YourGarageBlips, true)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString("Votre Garage")
                                EndTextCommandSetBlipName(YourGarageBlips) 
                            else
                                YourPropertyBlips = AddBlipForCoord(v.propertyEntering.x, v.propertyEntering.y, v.propertyEntering.z)
                                if v.propertyGarage == nil and v.propertyRented == nil then 
                                    SetBlipSprite(YourPropertyBlips, 40)
                                else
                                    SetBlipSprite(YourPropertyBlips, 492)
                                end
                                SetBlipDisplay(YourPropertyBlips, 4)
                                SetBlipScale(YourPropertyBlips, 0.6)
                                SetBlipColour(YourPropertyBlips, 2)
                                SetBlipAsShortRange(YourPropertyBlips, true)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString("Votre Propriété")
                                EndTextCommandSetBlipName(YourPropertyBlips)  
                            end
                        end
                    else
                        for i = 1, #v.ownerList do 
                            if v.propertyOwner == b.identifier or v.ownerList[i].identifier == b.identifier then 
                                if v.propertyEntering == nil then 
                                    YourGarageBlips = AddBlipForCoord(v.propertyGarage.x, v.propertyGarage.y, v.propertyGarage.z)
                                    SetBlipSprite(YourGarageBlips, 524)
                                    SetBlipDisplay(YourGarageBlips, 4)
                                    SetBlipScale(YourGarageBlips, 0.6)
                                    SetBlipColour(YourGarageBlips, 17)
                                    SetBlipAsShortRange(YourGarageBlips, true)
                                    BeginTextCommandSetBlipName("STRING")
                                    AddTextComponentString("Votre Garage")
                                    EndTextCommandSetBlipName(YourGarageBlips)  
                                else
                                    YourPropertyBlips = AddBlipForCoord(v.propertyEntering.x, v.propertyEntering.y, v.propertyEntering.z)
                                    if v.propertyGarage == nil and v.propertyRented == nil then 
                                        SetBlipSprite(YourPropertyBlips, 40)
                                    else
                                        SetBlipSprite(YourPropertyBlips, 492)
                                    end
                                    SetBlipDisplay(YourPropertyBlips, 4)
                                    SetBlipScale(YourPropertyBlips, 0.6)
                                    SetBlipColour(YourPropertyBlips, 2)
                                    SetBlipAsShortRange(YourPropertyBlips, true)
                                    BeginTextCommandSetBlipName("STRING")
                                    if v.ownerList[i].identifier == b.identifier then 
                                        AddTextComponentString(("Propriété de %s"):format(v.ownerName))
                                    else
                                        AddTextComponentString("Votre Propriété")
                                    end
                                    EndTextCommandSetBlipName(YourPropertyBlips)  
                                end
                            end
                        end
                        
                    end
                end)
            end
        end
        SetTimeout(350, function()
            blipsCooldown = false 
        end)
    end
end
