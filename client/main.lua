local QBCore = exports['qb-core']:GetCoreObject()
local currentHouseGarage = nil
local hasGarageKey = nil
local currentGarage = nil
local OutsideVehicles = {}
local PlayerData = {}
local PlayerGang = {}
local PlayerJob = {}

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerGang = PlayerData.gang
    PlayerJob = PlayerData.job
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerGang = gang
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
    currentHouseGarage = house
    hasGarageKey = hasKey
end)

RegisterNetEvent('qb-garages:client:houseGarageConfig', function(garageConfig)
    HouseGarages = garageConfig
end)

RegisterNetEvent('qb-garages:client:addHouseGarage', function(house, garageInfo)
    HouseGarages[house] = garageInfo
end)

-- Functions

local DrawText3Ds = function(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function MenuGarage()
    exports['qb-menu']:openMenu({
        {
            header = "Public Garage",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your stored vehicles!",
            params = {
                event = "qb-garages:client:VehicleList"
            }
        },
        {
            header = "⬅ Leave Garage",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

local function GangMenuGarage()
    exports['qb-menu']:openMenu({
        {
            header = "Gang Garage",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your stored vehicles!",
            params = {
                event = "qb-garages:client:GangVehicleList"
            }
        },
        {
            header = "⬅ Leave Garage",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

local function JobMenuGarage()
    exports['qb-menu']:openMenu({
        {
            header = "Job Garage",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your stored vehicles!",
            params = {
                event = "qb-garages:client:JobVehicleList"
            }
        },
        {
            header = "⬅ Leave Garage",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

local function MenuDepot()
    exports['qb-menu']:openMenu({
        {
            header = "Impound",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your impounded vehicles!",
            params = {
                event = "qb-garages:client:DepotList"
            }
        },
        {
            header = "⬅ Leave Depot",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

local function MenuHouseGarage(house)
    exports['qb-menu']:openMenu({
        {
            header = "House Garage",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your stored vehicles!",
            params = {
                event = "qb-garages:client:HouseGarage",
                args = house
            }
        },
        {
            header = "⬅ Leave Garage",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

local function ClearMenu()
	exports['qb-menu']:closeMenu()
end

local function closeMenuFull()
    currentGarage = nil
    ClearMenu()
end

local function doCarDamage(currentVehicle, veh)
	smash = false
	damageOutside = false
	damageOutside2 = false
	local engine = veh.engine + 0.0
	local body = veh.body + 0.0
	if engine < 200.0 then
		engine = 200.0
    end

    if engine > 1000.0 then
        engine = 1000.0
    end

	if body < 150.0 then
		body = 150.0
	end
	if body < 900.0 then
		smash = true
	end

	if body < 800.0 then
		damageOutside = true
	end

	if body < 500.0 then
		damageOutside2 = true
	end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)
	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end
	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end
	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end
	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end

local function CheckPlayers(vehicle)
    for i = -1, 5,1 do
        seat = GetPedInVehicleSeat(vehicle,i)
        if seat ~= 0 then
            TaskLeaveVehicle(seat,vehicle,0)
            SetVehicleDoorsLocked(vehicle)
            Wait(1500)
            QBCore.Functions.DeleteVehicle(vehicle)
        end
   end
end

local function GetNearestVeh(coords, coords2)
    local offset = 0
    local rayHandle
    local veh

    for i = 0, 100 do
        rayHandle = CastRayPointToPoint(coords.x, coords.y, coords.z, coords2.x, coords2.y, coords2.z + offset, 10, PlayerPedId(), 0)
        a, b, c, d, veh = GetRaycastResult(rayHandle)
        offset = offset - 1
        if veh ~= 0 then
            break
        end
    end
    
    local distance = #(coords - GetEntityCoords(veh))
    if distance > 3 then
        veh = nil
    end
    return veh ~= nil and veh or 0
end

-- Events

--*/Public Stuff
RegisterNetEvent("qb-garages:client:VehicleList", function()
    QBCore.Functions.TriggerCallback("qb-garage:server:GetUserVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in this garage!", "error", 5000)
        else
            local MenuPublicGarageOptions = {
                {
                    header = "Parking: "..Garages[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = Garages[v.garage].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "In"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuPublicGarageOptions[#MenuPublicGarageOptions+1] = {
                    header = "Take Out: "..vname.." | "..v.plate,
                    txt = "State: "..v.state.." <br>Fuel: "..currentFuel.."% | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%",
                    params = {
                        event = "qb-garages:client:takeOutPublicGarage",
                        args = v,
                    }
                }
            end

            MenuPublicGarageOptions[#MenuPublicGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuPublicGarageOptions)
        end
    end, currentGarage)
end)

RegisterNetEvent('Garages:PutInGarage', function()
    for k, v in pairs(Garages) do
        local PutInDist = #(GetEntityCoords(PlayerPedId()) - Garages[k].pz)
        if PutInDist <= 5 then
            local pedCoords = GetEntityCoords(PlayerPedId(), 1)
            local offCooords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 100.0, 0.0)
            local curVeh = GetNearestVeh(pedCoords, offCooords)
            local plate = GetVehicleNumberPlateText(curVeh)
            if (curVeh ~= 0) then
                QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned)
                    if owned then
                        local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
                        local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
                        local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
                        local vehProperties = QBCore.Functions.GetVehicleProperties(curVeh)
                        CheckPlayers(curVeh)
                        TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, k)
                        TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, k)
                        TriggerServerEvent('qb-vehicletuning:server:SaveVehicleProps', vehProperties)
                        if plate then
                            OutsideVehicles[plate] = veh
                            TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                        end
                        Wait(500)
                        DeleteVehicle(curVeh)
                        QBCore.Functions.Notify("Vehicle Parked In: "..Garages[k].label, "primary", 4500)
                    else
                        QBCore.Functions.Notify("This vehicle not belong to you!", "error", 3500)
                    end
                end, plate)
            else
                QBCore.Functions.Notify("You need to look at the vehicle to park!", "error", 4500)
            end
        end
    end
end)

RegisterNetEvent('qb-garages:client:takeOutPublicGarage', function(vehicle)
    if vehicle.state == "In" then
        local TakeOutDist = #(GetEntityCoords(PlayerPedId()) - Garages[currentGarage].pz)
            if TakeOutDist >= 1 and TakeOutDist <= 4 then
                enginePercent = round(vehicle.engine / 10, 1)
                bodyPercent = round(vehicle.body / 10, 1)
                currentFuel = vehicle.fuel
                QBCore.Functions.Notify("Being Checked, Please Wait...", "Primary", 1000)
                Wait(1000)
                QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                    QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                        if vehicle.plate then
                            OutsideVehicles[vehicle.plate] = veh
                            TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                        end
                        QBCore.Functions.SetVehicleProperties(veh, properties)
                        SetVehicleNumberPlateText(veh, vehicle.plate)
                        SetEntityHeading(veh, Garages[currentGarage].spawnPoint.w)
                        exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                        doCarDamage(veh, vehicle)
                        SetEntityAsMissionEntity(veh, true, true)
                        TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                        closeMenuFull()
                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                        SetVehicleEngineOn(veh, false, false)
                    end, vehicle.plate)
                end, Garages[currentGarage].spawnPoint, true)
            elseif TakeOutDist <= 1 then
                QBCore.Functions.Notify("Please give some space to take out your vehicle", "error", 4500)
            end
    elseif vehicle.state == "Out" then
        QBCore.Functions.Notify("This vehicle already out!", "error", 2500)
    elseif vehicle.state == "Impound" then
        QBCore.Functions.Notify("This vehicle was impounded by the police!", "error", 4000)
    end
end)

RegisterNetEvent('Garages:PutOutGarage', function()
    for k, v in pairs(Garages) do
        local PutOutDist = #(GetEntityCoords(PlayerPedId()) - Garages[k].pz)
        if PutOutDist <= 4 then
            if not IsPedInAnyVehicle(PlayerPedId()) then
                MenuGarage()
                currentGarage = k
            end
        end
    end
end)

--*/Job Stuff
RegisterNetEvent("qb-garages:client:JobVehicleList", function()
    QBCore.Functions.TriggerCallback("qb-garage:server:GetUserVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in this garage!", "error", 5000)
        else
            local MenuJobGarageOptions = {
                {
                    header = "Garage: "..JobGarages[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = JobGarages[v.garage].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "Garaged"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuJobGarageOptions[#MenuJobGarageOptions+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = "State: "..v.state.."<br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:takeOutJobGarage",
                        args = v
                    }
                }
            end

            MenuJobGarageOptions[#MenuJobGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuJobGarageOptions)
        end
    end, currentGarage)
end)

RegisterNetEvent('Garage:PutInJob', function()
    if PlayerJob.name then Name = PlayerJob.name end
    for k, v in pairs(JobGarages) do
        if PlayerJob.name == JobGarages[k].job then
            local PutInDist = #(GetEntityCoords(PlayerPedId()) - JobGarages[Name].pz)
            if PutInDist <= 4 then
                local pedCoords = GetEntityCoords(PlayerPedId(), 1)
                local offCooords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 100.0, 0.0)
                local curVeh = GetNearestVeh(pedCoords, offCooords)
                local plate = GetVehicleNumberPlateText(curVeh)
                if (curVeh ~= 0) then
                    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned)
                        if owned then
                            local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
                            local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
                            local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
                            local vehProperties = QBCore.Functions.GetVehicleProperties(curVeh)
                            CheckPlayers(curVeh)
                            Wait(500)
                            TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, Name)
                            TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, Name)
                            TriggerServerEvent('qb-vehicletuning:server:SaveVehicleProps', vehProperties)
                            if plate then
                                OutsideVehicles[plate] = veh
                                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                            end
                            Wait(500)
                            DeleteVehicle(curVeh)
                            QBCore.Functions.Notify("Vehicle Parked", "primary", 4500)
                        else
                            QBCore.Functions.Notify("Vehicle not owned", "error", 3500)
                        end
                    end, plate)
                else
                    QBCore.Functions.Notify('You need to look at the vehicle to store!', 'error', 4500)
                end
            end
        else
            QBCore.Functions.Notify('You\'re not whitelisted to access this garage', 'error', 4500)
        end
    end
end)

RegisterNetEvent('qb-garages:client:takeOutJobGarage', function(vehicle)
    if vehicle.state == "Garaged" then
        local TakeOutDist = #(GetEntityCoords(PlayerPedId()) - JobGarages[currentGarage].pz)
        if TakeOutDist >= 1 and TakeOutDist <= 4 then
            enginePercent = round(vehicle.engine / 10, 1)
            bodyPercent = round(vehicle.body / 10, 1)
            currentFuel = vehicle.fuel
            QBCore.Functions.Notify("Being Checked, Please Wait...", "Primary", 1000)
            Wait(1000)
            QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                    if vehicle.plate then
                        OutsideVehicles[vehicle.plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end
                    QBCore.Functions.SetVehicleProperties(veh, properties)
                    SetVehicleNumberPlateText(veh, vehicle.plate)
                    SetEntityHeading(veh, JobGarages[currentGarage].spawnPoint.w)
                    exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                    doCarDamage(veh, vehicle)
                    SetEntityAsMissionEntity(veh, true, true)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                    closeMenuFull()
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                    SetVehicleEngineOn(veh, false, false)
                end, vehicle.plate)
            end, JobGarages[currentGarage].spawnPoint, true)
        else
            QBCore.Functions.Notify('Please give some space to take out!', 'error')
        end
    elseif vehicle.state == "Out" then
        QBCore.Functions.Notify("Your vehicle may be in the depot!", "error", 2500)
    elseif vehicle.state == "Impound" then
        QBCore.Functions.Notify("This vehicle was impounded by the police!", "error", 4000)
    end
end)

RegisterNetEvent('Garage:PutOutJob', function()
    if PlayerJob.name then Name = PlayerJob.name end
    for k, v in pairs(JobGarages) do
        if PlayerJob.name == JobGarages[k].job then
            local PutOutDist = #(GetEntityCoords(PlayerPedId()) - JobGarages[Name].pz)
            if PutOutDist <= 4 then
                if not IsPedInAnyVehicle(PlayerPedId()) then
                    JobMenuGarage()
                    currentGarage = Name
                end
            end
        else
            QBCore.Functions.Notify('You\'re not whitelisted to access this garage', 'error', 4500)
        end
    end
end)

--*/Gang Stuff
RegisterNetEvent("qb-garages:client:GangVehicleList", function()
    QBCore.Functions.TriggerCallback("qb-garage:server:GetUserVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in this garage!", "error", 5000)
        else
            local MenuGangGarageOptions = {
                {
                    header = "Garage: "..GangGarages[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = GangGarages[v.garage].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "Garaged"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuGangGarageOptions[#MenuGangGarageOptions+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = "State: "..v.state.."<br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:takeOutGangGarage",
                        args = v
                    }
                }
            end

            MenuGangGarageOptions[#MenuGangGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuGangGarageOptions)
        end
    end, currentGarage)
end)

RegisterNetEvent('Garage:PutInGang', function()
    if PlayerGang.name then Name = PlayerGang.name end
    for k, v in pairs(GangGarages) do
        if PlayerGang.name == GangGarages[k].job then
            local PutInDist = #(GetEntityCoords(PlayerPedId()) - GangGarages[Name].pz)
            if PutInDist <= 4 then
                local pedCoords = GetEntityCoords(PlayerPedId(), 1)
                local offCooords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 100.0, 0.0)
                local curVeh = GetNearestVeh(pedCoords, offCooords)
                local plate = GetVehicleNumberPlateText(curVeh)
                if (curVeh ~= 0) then
                    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned)
                        if owned then
                            local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
                            local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
                            local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
                            local vehProperties = QBCore.Functions.GetVehicleProperties(curVeh)
                            CheckPlayers(curVeh)
                            Wait(500)
                            TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, Name)
                            TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, Name)
                            TriggerServerEvent('qb-vehicletuning:server:SaveVehicleProps', vehProperties)
                            if plate then
                                OutsideVehicles[plate] = veh
                                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                            end
                            Wait(500)
                            DeleteVehicle(curVeh)
                            QBCore.Functions.Notify("Vehicle Parked", "primary", 4500)
                        else
                            QBCore.Functions.Notify("Vehicle not owned", "error", 3500)
                        end
                    end, plate)
                else
                    QBCore.Functions.Notify('You need to look at the vehicle to park!', 'error', 4500)
                end
            end
        else
            QBCore.Functions.Notify('Sup! what you want? your car ain\'t here', 'error', 4500)
        end
    end
end)

RegisterNetEvent('qb-garages:client:takeOutGangGarage', function(vehicle)
    if vehicle.state == "Garaged" then
        local TakeOutDist = #(GetEntityCoords(PlayerPedId()) - GangGarages[currentGarage].pz)
        enginePercent = round(vehicle.engine / 10, 1)
        bodyPercent = round(vehicle.body / 10, 1)
        currentFuel = vehicle.fuel
        QBCore.Functions.Notify("Being Checked, Please Wait...", "Primary", 1000)
        Wait(1000)
        if TakeOutDist >= 1 and TakeOutDist <= 4 then
            QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)

                    if vehicle.plate then
                        OutsideVehicles[vehicle.plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end

                    QBCore.Functions.SetVehicleProperties(veh, properties)
                    SetVehicleNumberPlateText(veh, vehicle.plate)
                    SetEntityHeading(veh, GangGarages[currentGarage].spawnPoint.w)
                    exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                    doCarDamage(veh, vehicle)
                    SetEntityAsMissionEntity(veh, true, true)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                    closeMenuFull()
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                    SetVehicleEngineOn(veh, false, false)
                end, vehicle.plate)

            end, GangGarages[currentGarage].spawnPoint, true)
        elseif TakeOutDist <= 1 then
            QBCore.Functions.Notify("Please give some space to take out your vehicle", "error", 4500)
        end
    elseif vehicle.state == "Out" then
        QBCore.Functions.Notify("Your vehicle may be in the depot!", "error", 2500)
    elseif vehicle.state == "Impound" then
        QBCore.Functions.Notify("This vehicle was impounded by the police!", "error", 4000)
    end
end)

RegisterNetEvent('Garage:PutOutGang', function()
    if PlayerGang.name then Name = PlayerGang.name end
    for k, v in pairs(GangGarages) do
        if PlayerGang.name == GangGarages[k].job then
            local PutOutDist = #(GetEntityCoords(PlayerPedId()) - GangGarages[Name].pz)
            if PutOutDist <= 4 then
                if not IsPedInAnyVehicle(PlayerPedId()) then
                    GangMenuGarage()
                    currentGarage = Name
                end
            end
        else
            QBCore.Functions.Notify('Sup! what you want? your car ain\'t here', 'error', 4500)
        end
    end
end)

--*/Depots Stuff
RegisterNetEvent("qb-garages:client:DepotList", function()
    QBCore.Functions.TriggerCallback("qb-garage:server:GetDepotVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any impounded vehicles!", "error", 5000)
        else
            local MenuDepotOptions = {
                {
                    header = "Depot: "..Depots[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Impound"
                end

                MenuDepotOptions[#MenuDepotOptions+1] = {
                    header = "Take Out: "..vname.." | "..v.plate.."<br>Price: $"..v.depotprice,
                    txt = "Fuel: "..currentFuel.."% | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%",
                    params = {
                        event = "qb-garages:client:TakeOutDepotVehicle",
                        args = v
                    }
                }
            end

            MenuDepotOptions[#MenuDepotOptions+1] = {
                header = "⬅ Leave Depot",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuDepotOptions)
        end
    end)
end)

RegisterNetEvent('qb-garages:client:takeOutDepot', function(vehicle)
    if OutsideVehicles and next(OutsideVehicles) then
        if OutsideVehicles[vehicle.plate] then
            local Engine = GetVehicleEngineHealth(OutsideVehicles[vehicle.plate])
            Wait(500)
            QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                    QBCore.Functions.SetVehicleProperties(veh, properties)
                    enginePercent = round(vehicle.engine / 10, 0)
                    bodyPercent = round(vehicle.body / 10, 0)
                    currentFuel = vehicle.fuel

                    if vehicle.plate then
                        DeleteVehicle(OutsideVehicles[vehicle.plate])
                        OutsideVehicles[vehicle.plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end

                    SetVehicleNumberPlateText(veh, vehicle.plate)
                    SetEntityHeading(veh, Depots[currentGarage].takeVehicle.w)
                    --TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                    exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                    SetEntityAsMissionEntity(veh, true, true)
                    doCarDamage(veh, vehicle)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                    closeMenuFull()
                    SetVehicleEngineOn(veh, false, false)
                end, vehicle.plate)
                TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                QBCore.Functions.Notify("You take out your impounded Vehicle!", "primary", 4000)
            end, Depots[currentGarage].takeVehicle, true)
            SetTimeout(250, function()
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
            end)
        else
            Wait(500)
            QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                    QBCore.Functions.SetVehicleProperties(veh, properties)
                    enginePercent = round(vehicle.engine / 10, 0)
                    bodyPercent = round(vehicle.body / 10, 0)
                    currentFuel = vehicle.fuel

                    if vehicle.plate then
                        OutsideVehicles[vehicle.plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end

                    SetVehicleNumberPlateText(veh, vehicle.plate)
                    SetEntityHeading(veh, Depots[currentGarage].takeVehicle.w)
                    --TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                    exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                    SetEntityAsMissionEntity(veh, true, true)
                    doCarDamage(veh, vehicle)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                    closeMenuFull()
                    SetVehicleEngineOn(veh, false, false)
                end, vehicle.plate)
                TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                QBCore.Functions.Notify("You take out your impounded Vehicle!", "primary", 4000)
            end, Depots[currentGarage].takeVehicle, true)
            SetTimeout(250, function()
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
            end)
        end
    else
        Wait(500)
        QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                enginePercent = round(vehicle.engine / 10, 0)
                bodyPercent = round(vehicle.body / 10, 0)
                currentFuel = vehicle.fuel

                if vehicle.plate then
                    OutsideVehicles[vehicle.plate] = veh
                    TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                end

                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetEntityHeading(veh, Depots[currentGarage].takeVehicle.w)
                --TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                SetEntityAsMissionEntity(veh, true, true)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                closeMenuFull()
                SetVehicleEngineOn(veh, false, false)
            end, vehicle.plate)
            TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
            QBCore.Functions.Notify("You take out your impounded Vehicle!", "primary", 4000)
        end, Depots[currentGarage].takeVehicle, true)
        SetTimeout(250, function()
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
        end)
    end
end)

RegisterNetEvent('Garages:TakeOutDepots', function()
    for k, v in pairs(Depots) do
        local depottakeDist = #(GetEntityCoords(PlayerPedId()) - Depots[k].pz)
        if depottakeDist <= 20 then
            if not IsPedInAnyVehicle(PlayerPedId()) then
                MenuDepot()
                currentGarage = k
            end
        end
    end
end)

RegisterNetEvent('qb-garages:client:TakeOutDepotVehicle', function(vehicle)
    if vehicle.state == "Impound" then
        TriggerServerEvent("qb-garage:server:PayDepotPrice", vehicle)
        Wait(1000)
    end
end)

RegisterNetEvent("qb-garages:client:HouseGarage", function(house)
    QBCore.Functions.TriggerCallback("qb-garage:server:GetHouseVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in your garage!", "error", 5000)
        else
            local MenuHouseGarageOptions = {
                {
                    header = "Garage: "..HouseGarages[house].label,
                    isMenuHeader = true
                },
            }

            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = HouseGarages[house].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "Garaged"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuHouseGarageOptions[#MenuHouseGarageOptions+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = "State: "..v.state.. "<br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:TakeOutHouseGarage",
                        args = v
                    }
                }
            end

            MenuHouseGarageOptions[#MenuHouseGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuHouseGarageOptions)
        end
    end, house)
end)


RegisterNetEvent('qb-garages:client:TakeOutHouseGarage', function(vehicle)
    if vehicle.state == "Garaged" then
        QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                enginePercent = round(vehicle.engine / 10, 1)
                bodyPercent = round(vehicle.body / 10, 1)
                currentFuel = vehicle.fuel

                if vehicle.plate then
                    OutsideVehicles[vehicle.plate] = veh
                    TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                end

                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetEntityHeading(veh, HouseGarages[currentHouseGarage].takeVehicle.h)
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                SetEntityAsMissionEntity(veh, true, true)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                closeMenuFull()
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetVehicleEngineOn(veh, true, true)
            end, vehicle.plate)
        end, HouseGarages[currentHouseGarage].takeVehicle, true)
    end
end)

-- Threads

CreateThread(function()
    while true do
        sleep = 1000
        if LocalPlayer.state['isLoggedIn'] then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            inGarageRange = false
            if HouseGarages and currentHouseGarage then
                if hasGarageKey and HouseGarages[currentHouseGarage] and HouseGarages[currentHouseGarage].takeVehicle and HouseGarages[currentHouseGarage].takeVehicle.x then
                    local takehouseDist = #(pos - vector3(HouseGarages[currentHouseGarage].takeVehicle.x, HouseGarages[currentHouseGarage].takeVehicle.y, HouseGarages[currentHouseGarage].takeVehicle.z))
                    if takehouseDist <= 15 then
                        sleep = 5
                        inGarageRange = true
                        DrawMarker(2, HouseGarages[currentHouseGarage].takeVehicle.x, HouseGarages[currentHouseGarage].takeVehicle.y, HouseGarages[currentHouseGarage].takeVehicle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                        if takehouseDist < 2.0 then
                            if not IsPedInAnyVehicle(ped) then
                                DrawText3Ds(HouseGarages[currentHouseGarage].takeVehicle.x, HouseGarages[currentHouseGarage].takeVehicle.y, HouseGarages[currentHouseGarage].takeVehicle.z + 0.5, '~g~E~w~ - Garage')
                                if IsControlJustPressed(0, 38) then
                                    MenuHouseGarage(currentHouseGarage)

                                end
                            elseif IsPedInAnyVehicle(ped) then
                                DrawText3Ds(HouseGarages[currentHouseGarage].takeVehicle.x, HouseGarages[currentHouseGarage].takeVehicle.y, HouseGarages[currentHouseGarage].takeVehicle.z + 0.5, '~g~E~w~ - To Park')
                                if IsControlJustPressed(0, 38) then
                                    local curVeh = GetVehiclePedIsIn(ped)
                                    local plate = GetVehicleNumberPlateText(curVeh)
                                    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleHouseOwner', function(owned)
                                        if owned then
                                            local bodyDamage = round(GetVehicleBodyHealth(curVeh), 1)
                                            local engineDamage = round(GetVehicleEngineHealth(curVeh), 1)
                                            local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
                                            local vehProperties = QBCore.Functions.GetVehicleProperties(curVeh)
                                            CheckPlayers(curVeh)
                                            if DoesEntityExist(curVeh) then
                                                    QBCore.Functions.Notify("The Vehicle wasn't deleted, please check if is someone inside the car.", "error", 4500)
                                            else
                                            TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, currentHouseGarage)
                                            TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, currentHouseGarage)
                                            TriggerServerEvent('qb-vehicletuning:server:SaveVehicleProps', vehProperties)
                                            QBCore.Functions.DeleteVehicle(curVeh)
                                            if plate then
                                                OutsideVehicles[plate] = veh
                                                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                                            end
                                            QBCore.Functions.Notify("Vehicle Parked", "primary", 4500)
                                        end
                                        else
                                            QBCore.Functions.Notify("Vehicle not owned", "error", 3500)
                                        end

                                    end, plate, currentHouseGarage)
                                end
                            end
                        end
                        if takehouseDist > 1.99 then
                            closeMenuFull()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    for k, v in pairs(Garages) do
        if v.showBlip then
            local Garage = AddBlipForCoord(Garages[k].pz)
            SetBlipSprite (Garage, 357)
            SetBlipDisplay(Garage, 4)
            SetBlipScale  (Garage, 0.65)
            SetBlipAsShortRange(Garage, true)
            SetBlipColour(Garage, 3)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Garages[k].label)
            EndTextCommandSetBlipName(Garage)
        end
    end

    for k, v in pairs(Depots) do
        if v.showBlip then
            local Depot = AddBlipForCoord(Depots[k].pz)
            SetBlipSprite (Depot, 68)
            SetBlipDisplay(Depot, 4)
            SetBlipScale  (Depot, 0.7)
            SetBlipAsShortRange(Depot, true)
            SetBlipColour(Depot, 5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Depots[k].label)
            EndTextCommandSetBlipName(Depot)
        end
    end
end)
