---@diagnostic disable: undefined-global
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local IsEntityAMissionEntity = IsEntityAMissionEntity
local DeleteEntity = DeleteEntity
local PlayerPedId = PlayerPedId
local GetDisplayNameFromVehicleModel = GetDisplayNameFromVehicleModel
local GetEntityCoords = GetEntityCoords
local IsPedInAnyVehicle = IsPedInAnyVehicle
local DrawMarker = DrawMarker
local BeginTextCommandDisplayHelp = BeginTextCommandDisplayHelp
local AddTextComponentSubstringTextLabel = AddTextComponentSubstringTextLabel
local EndTextCommandDisplayHelp = EndTextCommandDisplayHelp
local CastRayPointToPoint = CastRayPointToPoint
local GetRaycastResult = GetRaycastResult
local Wait = Wait
local AddTextEntry = AddTextEntry
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local GetVehiclePedIsIn = GetVehiclePedIsIn
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local GetPlayerPed = GetPlayerPed
local GetDistanceBetweenCoords = GetDistanceBetweenCoords
local CreateObjectNoOffset = CreateObjectNoOffset
local ObjToNet = ObjToNet
local NetToObj = NetToObj
local NetToVeh = NetToVeh
local VehToNet = VehToNet
local SetVehicleExtra = SetVehicleExtra
local GetEntityMatrix = GetEntityMatrix
local DetachEntity = DetachEntity
local AttachEntityToEntity = AttachEntityToEntity
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local Timestep = Timestep
local IsControlJustPressed = IsControlJustPressed

---@diagnostic disable: undefined-global

local DECOR = {
    FLOAT = 1,
    BOOL = 2,
    INT = 3,
    UNK = 4,
    TIME = 5,
}

local DECORATORS = {
    ["flatbed3_bed"] = DECOR.INT, -- The bed entity
    ["flatbed3_car"] = DECOR.INT, -- The car entity
    ["flatbed3_attached"] = DECOR.BOOL, -- Is a car attached?
    ["flatbed3_lowered"] = DECOR.BOOL, -- Is the bed lowered?
    ["flatbed3_state"] = DECOR.INT, -- Multi-state for the bed,
    ["flatbed4_bed"] = DECOR.INT, -- The bed entity
    ["flatbed4_car"] = DECOR.INT, -- The car entity
    ["flatbed4_attached"] = DECOR.BOOL, -- Is a car attached?
    ["flatbed4_lowered"] = DECOR.BOOL, -- Is the bed lowered?
    ["flatbed4_state"] = DECOR.INT, -- Multi-state for the bed
    ["gtow_bed"] = DECOR.INT, -- The bed entity for gtow
    ["gtow_car"] = DECOR.INT, -- The car entity for gtow
    ["gtow_attached"] = DECOR.BOOL, -- Is a car attached? (gtow)
    ["gtow_lowered"] = DECOR.BOOL, -- Is the bed lowered? (gtow)
    ["gtow_state"] = DECOR.INT -- Multi-state for the bed (gtow)
}

for k,v in next, DECORATORS do
    DecorRegister(k, v)
end

-- Add additional vehicle model names here to make them behave like the original flatbed.
-- Example: { "flatbed3", "flatbed2", "flatbed4" }
local FLATBED_MODELS = { "flatbed3", "gtow", "flatbed4" }
local FLATBED_HASHES = {}
for _, name in ipairs(FLATBED_MODELS) do
    FLATBED_HASHES[GetHashKey(name)] = true
end

local function IsFlatbedModelHash(hash)
    return FLATBED_HASHES[hash] == true
end

local function IsFlatbedVehicle(entityOrHash)
    if not entityOrHash then return false end
    -- if passed an entity handle, get its model
    if type(entityOrHash) == "number" then
        if DoesEntityExist(entityOrHash) then
            return IsFlatbedModelHash(GetEntityModel(entityOrHash))
        end
        return false
    end
    -- otherwise assume a model hash was passed
    return IsFlatbedModelHash(entityOrHash)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

-- Value controlling all movement
local LERP_VALUE = 0.0

local lastFlatbed = nil
local lastBed = nil

--local raisedOffset = vector3(0.0, -3.8, 0.25)
local backOffset = {vector3(0.0, -4.0, 0.0), vector3(0.0, 0.0, 0.0)}
local loweredOffset = {vector3(0.0, -0.4, -1.0), vector3(12.0, 0.0, 0.0)}
local raisedOffset = {vector3(0.0, -3.8, 0.45), vector3(0.0, 0.0, 0.0)}

local attachmentOffset = {vector3(0.0, 1.5, 0.3), vector3(0.0, 0.0, 0.0)}

local bedController = {vector3(-2.5, -3.8, -1.0), vector3(0.0, 0.0, 0.0)}

local controllerMessageLoweredCar = "OMNI_FB3_INST_LC"
local controllerMessageLoweredNoCar = "OMNI_FB3_INST_LN"
local controllerMessageRaised = "OMNI_FB3_INST_R"
AddTextEntry(controllerMessageLoweredCar, "Press ~INPUT_CONTEXT~ to ~y~raise ~w~the bed.~n~Press ~INPUT_DETONATE~ to ~r~detach ~w~the vehicle.")
AddTextEntry(controllerMessageLoweredNoCar, "Press ~INPUT_CONTEXT~ to ~y~raise ~w~the bed.~n~Press ~INPUT_DETONATE~ to ~g~attach ~w~a vehicle.")
AddTextEntry(controllerMessageRaised, "Press ~INPUT_CONTEXT~ to ~y~lower ~w~the bed.")

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end

		enum.destructor = nil
		enum.handle = nil
	end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

function GetAllVehicles() 
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

function GetAllObjects() 
	local objs = {}

	for obj in EnumerateObjects() do
		table.insert(objs, obj)
	end

	return objs
end

function BigDelete(entity) 
    local playerPed = PlayerPedId()
    carModel = GetEntityModel(entity)
    carName = GetDisplayNameFromVehicleModel(carModel)
    if (NetworkGetNetworkIdFromEntity(entity) ~= nil and NetworkGetNetworkIdFromEntity(entity) > 0) then
        NetworkRequestControlOfEntity(entity)
        
        local timeout = 2000
        while timeout > 0 and not NetworkHasControlOfEntity(entity) do
            Wait(100)
            timeout = timeout - 100
        end

        SetEntityAsMissionEntity(entity, true, true)
        
        local timeout = 2000
        while timeout > 0 and not IsEntityAMissionEntity(entity) do
            Wait(100)
            timeout = timeout - 100
        end

        Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized( entity ) )
        
        if (DoesEntityExist(entity)) then 
            DeleteEntity(entity)
        end 
    end
end

function BedCheck()
    local objects = GetAllObjects()
    for i=1, #objects do 
        local obj = objects[i]
        if (GetHashKey("inm_flatbed_base") == GetEntityModel(obj)) then 
            local tow = false
            local vehicles = GetAllVehicles()
            for i=1, #vehicles do 
                local car = vehicles[i]
                if IsFlatbedVehicle(car) then 
                    local car_coords = GetEntityCoords(car, false)
                    local bed_coords = GetEntityCoords(obj, false)
                    local dist = GetDistanceBetweenCoords(car_coords.x, car_coords.y, car_coords.z, bed_coords.x, bed_coords.y, bed_coords.z, true)
                    if (dist < 10.0) then
                        tow = true
                        break
                    end
                end
            end
            if (not tow) then
                BigDelete(obj)
            end
        end
    end
end

function drawMarker(pos)
    local plyPos = GetEntityCoords(PlayerPedId(), true)
    if IsPedInAnyVehicle(PlayerPedId(), true) then
        return false
    end
    local dist = #(pos - plyPos)
    if dist < 25.0 then
        DrawMarker(1, pos, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0), vector3(1.0, 1.0, 1.0), 255, 255, 255, 150)
        if dist < 1.5 then
            return true
        end
    end
    return false
end

function showHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringTextLabel(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

function getVehicleInDirection(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y,
            coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10,
            GetPlayerPed(-1), 0)
    local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

function log(text)
    print("[omni_flatbed/client] " .. text)
end

-- Start a flatbed handler thread for a specific flatbed model name
local function StartFlatbedThread(modelName)
    Citizen.CreateThread(function()
        log("Flatbed Loading for " .. modelName)
        RequestModel("inm_flatbed_base")
        while not HasModelLoaded("inm_flatbed_base") do
            Wait(0)
        end
        log("Flatbed Loading Complete for " .. modelName)

        local LERP_VALUE = 0.0
        local lastFlatbed = nil
        local lastBed = nil

        while true do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, true)

            -- Only consider this thread's specific model
            if veh and not (IsFlatbedVehicle(veh) and GetEntityModel(veh) == GetHashKey(modelName)) then
                veh = lastFlatbed
            end

            if lastFlatbed then
                if not DoesEntityExist(lastFlatbed) then
                    log("FLATBED DELETED? (" .. modelName .. ")")
                    if lastBed then
                        if DoesEntityExist(lastBed) then
                            log("BED STILL EXISTS! (" .. modelName .. ")")
                            BigDelete(lastBed)
                            lastBed = nil
                        end
                    end
                    lastFlatbed = nil
                end
            end

            if veh and DoesEntityExist(veh) and IsFlatbedVehicle(veh) and GetEntityModel(veh) == GetHashKey(modelName) and NetworkHasControlOfEntity(veh) then
                lastFlatbed = veh

                local function MigrateLegacyToModel(veh, modelPrefix)
                    -- If we're already using the flatbed3 keys for this model, nothing to do
                    if modelPrefix == "flatbed3" then return end

                    -- Only migrate if the legacy keys contain meaningful data and the new keys are empty
                    local legacyBed = 0
                    if DecorExistOn(veh, "flatbed3_bed") then
                        legacyBed = DecorGetInt(veh, "flatbed3_bed")
                    end

                    local newBed = 0
                    if DecorExistOn(veh, modelPrefix .. "_bed") then
                        newBed = DecorGetInt(veh, modelPrefix .. "_bed")
                    end

                    if legacyBed ~= 0 and (newBed == 0 or not DecorExistOn(veh, modelPrefix .. "_bed")) then
                        DecorSetInt(veh, modelPrefix .. "_bed", legacyBed)
                        DecorSetInt(veh, "flatbed3_bed", 0)
                    end

                    -- Migrate car
                    local legacyCar = 0
                    if DecorExistOn(veh, "flatbed3_car") then
                        legacyCar = DecorGetInt(veh, "flatbed3_car")
                    end
                    local newCar = 0
                    if DecorExistOn(veh, modelPrefix .. "_car") then
                        newCar = DecorGetInt(veh, modelPrefix .. "_car")
                    end
                    if legacyCar ~= 0 and (newCar == 0 or not DecorExistOn(veh, modelPrefix .. "_car")) then
                        DecorSetInt(veh, modelPrefix .. "_car", legacyCar)
                        DecorSetInt(veh, "flatbed3_car", 0)
                    end

                    -- Migrate attached
                    if DecorExistOn(veh, "flatbed3_attached") and not DecorExistOn(veh, modelPrefix .. "_attached") then
                        local legacyAttached = DecorGetBool(veh, "flatbed3_attached")
                        DecorSetBool(veh, modelPrefix .. "_attached", legacyAttached)
                        DecorSetBool(veh, "flatbed3_attached", false)
                    end

                    -- Migrate lowered
                    if DecorExistOn(veh, "flatbed3_lowered") and not DecorExistOn(veh, modelPrefix .. "_lowered") then
                        local legacyLowered = DecorGetBool(veh, "flatbed3_lowered")
                        DecorSetBool(veh, modelPrefix .. "_lowered", legacyLowered)
                        DecorSetBool(veh, "flatbed3_lowered", false)
                    end

                    -- Migrate state
                    if DecorExistOn(veh, "flatbed3_state") and not DecorExistOn(veh, modelPrefix .. "_state") then
                        local legacyState = DecorGetInt(veh, "flatbed3_state")
                        DecorSetInt(veh, modelPrefix .. "_state", legacyState)
                        DecorSetInt(veh, "flatbed3_state", 0)
                    end
                end

                -- perform migration from legacy flatbed3_* decorators where needed
                MigrateLegacyToModel(veh, modelName)

                local rightDir, fwdDir, upDir, pos = GetEntityMatrix(veh)

                if not DecorExistOn(veh, modelName .. "_bed") or DecorGetInt(veh, modelName .. "_bed") == 0 then
                    DecorSetInt(veh, modelName .. "_bed", 0)
                    local bed = CreateObjectNoOffset("inm_flatbed_base", pos, true, 0, 1)
                    log("GENERATING BED (" .. modelName .. ")")
                    if DoesEntityExist(bed) then
                        local bedNet = ObjToNet(bed)
                        DecorSetInt(veh, modelName .. "_bed", bedNet)
                        log("DONE GENERATING BED (" .. modelName .. ")")
                    end
                else
                    SetVehicleExtra(veh, 1, not false)
                end

                local bedNet = DecorGetInt(veh, modelName .. "_bed")
                local bed = nil
                if bedNet ~= 0 then
                    bed = NetToObj(bedNet)
                    lastBed = bed

                    if not DecorExistOn(veh, modelName .. "_attached") then
                        DecorSetBool(veh, modelName .. "_attached", false)
                    end
                    local attached = DecorGetBool(veh, modelName .. "_attached")

                    if not DecorExistOn(veh, modelName .. "_lowered") then
                        DecorSetBool(veh, modelName .. "_lowered", true)
                    end
                    local lowered = DecorGetBool(veh, modelName .. "_lowered")

                    if not DecorExistOn(veh, modelName .. "_state") then
                        DecorSetInt(veh, modelName .. "_state", 0)
                    end
                    local state = DecorGetInt(veh, modelName .. "_state")

                    if not DecorExistOn(veh, modelName .. "_car") then
                        DecorSetInt(veh, modelName .. "_car", 0)
                    end
                    local carNet = DecorGetInt(veh, modelName .. "_car")
                    local car = nil
                    if carNet ~= 0 then
                        car = NetToVeh(carNet)
                    end

                    local data = bedController
                    local x = pos.x + (fwdDir.x * data[1].x) + (rightDir.x * data[1].y) + (upDir.x * data[1].z)
                    local y = pos.y + (fwdDir.y * data[1].x) + (rightDir.y * data[1].y) + (upDir.y * data[1].z)
                    local z = pos.z + (fwdDir.z * data[1].x) + (rightDir.z * data[1].y) + (upDir.z * data[1].z)
                    local controllerPos = vector3(x, y, z)

                    if state == 0 then
                        -- Raised
                        if lowered then
                            DetachEntity(bed, 0, 0)
                            AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), raisedOffset[1], raisedOffset[2], 0, 0, 1, 0, 0, 1)

                            DecorSetBool(veh, modelName .. "_lowered", false)
                            lowered = false
                        end

                        if drawMarker(controllerPos) then
                            showHelpText(controllerMessageRaised)
                            if IsControlJustPressed(0, 38) then
                                state = 1
                                DecorSetInt(veh, modelName .. "_state", state)
                            end
                        end
                    elseif state == 1 then
                        -- Moving back
                        local offsetPos = raisedOffset[1]
                        local offsetRot = raisedOffset[2]

                        offsetPos = offsetPos + vector3(lerp(0.0, backOffset[1].x, LERP_VALUE), lerp(0.0, backOffset[1].y, LERP_VALUE), lerp(0.0, backOffset[1].z, LERP_VALUE))
                        offsetRot = offsetRot + vector3(lerp(0.0, backOffset[2].x, LERP_VALUE), lerp(0.0, backOffset[2].y, LERP_VALUE), lerp(0.0, backOffset[2].z, LERP_VALUE))

                        DetachEntity(bed, 0, 0)
                        AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), offsetPos, offsetRot, 0, 0, 1, 0, 0, 1)

                        LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 4.0

                        if LERP_VALUE >= 1.0 then
                            state = state + 1
                            DecorSetInt(veh, modelName .. "_state", state)
                            LERP_VALUE = 0.0
                        end
                    elseif state == 2 then
                        -- Lowering
                        local offsetPos = raisedOffset[1] + backOffset[1]
                        local offsetRot = raisedOffset[2] + backOffset[2]

                        offsetPos = offsetPos + vector3(lerp(0.0, loweredOffset[1].x, LERP_VALUE), lerp(0.0, loweredOffset[1].y, LERP_VALUE), lerp(0.0, loweredOffset[1].z, LERP_VALUE))
                        offsetRot = offsetRot + vector3(lerp(0.0, loweredOffset[2].x, LERP_VALUE), lerp(0.0, loweredOffset[2].y, LERP_VALUE), lerp(0.0, loweredOffset[2].z, LERP_VALUE))

                        DetachEntity(bed, 0, 0)
                        AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), offsetPos, offsetRot, 0, 0, 1, 0, 0, 1)

                        LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 2.0

                        if LERP_VALUE >= 1.0 then
                            state = state + 1
                            DecorSetInt(veh, modelName .. "_state", state)
                            LERP_VALUE = 0.0
                        end
                    elseif state == 3 then
                        -- Lowered
                        if not lowered then
                            local offsetPos = raisedOffset[1] + backOffset[1] + loweredOffset[1]
                            local offsetRot = raisedOffset[2] + backOffset[2] + loweredOffset[2]
                            DetachEntity(bed, 0, 0)
                            AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), offsetPos, offsetRot, 0, 0, 1, 0, 0, 1)
                            DecorSetBool(veh, modelName .. "_lowered", true)
                            lowered = true
                        end

                        if drawMarker(controllerPos) then
                            if attached then
                                showHelpText(controllerMessageLoweredCar)
                            else
                                showHelpText(controllerMessageLoweredNoCar)
                            end
                            if IsControlJustPressed(0, 38) then
                                state = 4
                                DecorSetInt(veh, modelName .. "_state", state)
                            end
                            if IsControlJustPressed(0, 47) then
                                if attached then
                                    DetachEntity(car, 0, 1)
                                    car = nil
                                    DecorSetInt(veh, modelName .. "_car", 0)
                                    attached = false
                                    DecorSetBool(veh, modelName .. "_attached", attached)
                                else
                                    local bedPos = GetEntityCoords(bed, false)
                                    local newCar = getVehicleInDirection(bedPos + vector3(0.0, 0.0, 0.25), bedPos + vector3(0.0, 0.0, 2.25))
                                    if newCar then
                                        local carPos = GetEntityCoords(newCar, false)
                                        NetworkRequestControlOfEntity(newCar)
                                        while not NetworkHasControlOfEntity(newCar) do Wait(0) end
                                        AttachEntityToEntity(newCar, bed, 0, attachmentOffset[1] + vector3(0.0, 0.0, carPos.z - bedPos.z - 0.50), attachmentOffset[2], 0, 0, false, 0, 0, 1)
                                        car = newCar
                                        DecorSetInt(veh, modelName .. "_car", VehToNet(newCar))
                                        attached = true
                                        DecorSetBool(veh, modelName .. "_attached", attached)
                                    end
                                end
                            end
                        end
                    elseif state == 4 then
                        -- Raising
                        local offsetPos = raisedOffset[1] + backOffset[1]
                        local offsetRot = raisedOffset[2] + backOffset[2]

                        offsetPos = offsetPos + vector3(lerp(loweredOffset[1].x, 0.0, LERP_VALUE), lerp(loweredOffset[1].y, 0.0, LERP_VALUE), lerp(loweredOffset[1].z, 0.0, LERP_VALUE))
                        offsetRot = offsetRot + vector3(lerp(loweredOffset[2].x, 0.0, LERP_VALUE), lerp(loweredOffset[2].y, 0.0, LERP_VALUE), lerp(loweredOffset[2].z, 0.0, LERP_VALUE))

                        DetachEntity(bed, 0, 0)
                        AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), offsetPos, offsetRot, 0, 0, 1, 0, 0, 1)

                        LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 2.0

                        if LERP_VALUE >= 1.0 then
                            state = state + 1
                            DecorSetInt(veh, modelName .. "_state", state)
                            LERP_VALUE = 0.0
                        end
                    elseif state == 5 then
                        -- Moving forward
                        local offsetPos = raisedOffset[1]
                        local offsetRot = raisedOffset[2]

                        offsetPos = offsetPos + vector3(lerp(backOffset[1].x, 0.0, LERP_VALUE), lerp(backOffset[1].y, 0.0, LERP_VALUE), lerp(backOffset[1].z, 0.0, LERP_VALUE))
                        offsetRot = offsetRot + vector3(lerp(backOffset[2].x, 0.0, LERP_VALUE), lerp(backOffset[2].y, 0.0, LERP_VALUE), lerp(backOffset[2].z, 0.0, LERP_VALUE))

                        DetachEntity(bed, 0, 0)
                        AttachEntityToEntity(bed, veh, GetEntityBoneIndexByName(veh, "chassis"), offsetPos, offsetRot, 0, 0, 1, 0, 0, 1)

                        LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 4.0

                        if LERP_VALUE >= 1.0 then
                            state = 0
                            DecorSetInt(veh, modelName .. "_state", state)
                            LERP_VALUE = 0.0
                        end
                    else
                        state = 0
                        DecorSetInt(veh, modelName .. "_state", state)
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- Launch a handler thread for each flatbed model we support
for _, name in ipairs(FLATBED_MODELS) do
    StartFlatbedThread(name)
end

-- CLIENT-DEPENDENT FLOATING BED CHECK. 
Citizen.CreateThread(function() 
    while true do 
        Citizen.Wait(5000) 
        BedCheck()
    end
end)
