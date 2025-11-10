Config = {}
local QBCore = exports['qb-core']:GetCoreObject()
local lib = require 'ox_lib'
local function isTowVehicle(vehicle)
    local model = GetEntityModel(vehicle)
    for _, name in pairs(Config.TowVehicles.rollback) do
        if model == GetHashKey(name) then return 'rollback' end
    end
    for _, name in pairs(Config.TowVehicles.boom) do
        if model == GetHashKey(name) then return 'boom' end
    end
    return nil
end

local function isTowJob()
    local job = QBCore.Functions.GetPlayerData().job
    return job and Config.AllowedJobs[job.name] == true
end

exports.ox_target:addGlobalVehicle({
    {
        name = 'tow_controls',
        icon = 'truck',
        label = 'Tow Controls',
        canInteract = function(entity)
            return isTowVehicle(entity) ~= nil and isTowJob()
        end,
        onSelect = function(data)
            TriggerEvent('tow:openMenu', data.entity)
        end
    },
    {
        name = 'detach_trailer',
        icon = 'unlink',
        label = 'Detach Trailer',
        canInteract = function(entity)
            local model = GetEntityModel(entity)
            for _, trailerModel in pairs(Config.TowVehicles.trailers) do
                if model == GetHashKey(trailerModel) and IsEntityAttached(entity) then
                    return true
                end
            end
            return false
        end,
        onSelect = function(data)
            DetachEntity(data.entity, true, true)
            lib.notify({ title = 'Trailer', description = 'Trailer detached.', type = 'info' })
        end
    },
    {
        name = 'attach_trailer',
        icon = 'link',
        label = 'Attach Trailer',
        canInteract = function(entity)
            local model = GetEntityModel(entity)
            for _, trailerModel in pairs(Config.TowVehicles.trailers) do
                if model == GetHashKey(trailerModel) and not IsEntityAttached(entity) then
                    return true
                end
            end
            return false
        end,
        onSelect = function(data)
            local trailer = data.entity
            local player = PlayerPedId()
            local pos = GetEntityCoords(player)
            local nearby = lib.getNearbyVehicles(pos, 10.0)

            for _, veh in pairs(nearby) do
                if veh ~= trailer then
                    local model = GetEntityModel(veh)
                    for _, towModel in pairs(Config.TowVehicles.rollback) do
                        if model == GetHashKey(towModel) then
                            AttachEntityToEntity(trailer, veh, 0,
                                Config.AttachOffset.trailer.x,
                                Config.AttachOffset.trailer.y,
                                Config.AttachOffset.trailer.z,
                                0.0, 0.0, 0.0, false, false, false, false, 2, true)
                            lib.notify({ title = 'Trailer', description = 'Trailer attached to rollback.', type = 'success' })
                            return
                        end
                    end
                    for _, towModel in pairs(Config.TowVehicles.boom) do
                        if model == GetHashKey(towModel) then
                            AttachEntityToEntity(trailer, veh, 0,
                                Config.AttachOffset.trailer.x,
                                Config.AttachOffset.trailer.y,
                                Config.AttachOffset.trailer.z,
                                0.0, 0.0, 0.0, false, false, false, false, 2, true)
                            lib.notify({ title = 'Trailer', description = 'Trailer attached to wrecker.', type = 'success' })
                            return
                        end
                    end
                end
            end

            lib.notify({ title = 'Trailer', description = 'No valid tow truck nearby.', type = 'error' })
        end
    }
})