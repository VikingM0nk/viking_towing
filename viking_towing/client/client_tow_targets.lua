local lib = require 'ox_lib'
Config = {}
RegisterNetEvent('tow:selectTarget', function(towTruck)
    local nearby = lib.getNearbyVehicles(GetEntityCoords(towTruck), 10.0)
    local options = {}

    for _, veh in pairs(nearby) do
        if veh ~= towTruck then
            local plate = GetVehicleNumberPlateText(veh)
            table.insert(options, {
                title = 'Tow: ' .. plate,
                event = 'tow:attachTarget',
                args = { towTruck = towTruck, target = veh }
            })
        end
    end

    if #options == 0 then
        lib.notify({ title = 'Tow', description = 'No nearby vehicles found.', type = 'error' })
        return
    end

    lib.registerContext({ id = 'tow_targets', title = 'Select Tow Target', options = options })
    lib.showContext('tow_targets')
end)

RegisterNetEvent('tow:attachTarget', function(data)
    local towTruck = data.towTruck
    local target = data.target

    local model = GetEntityModel(target)
    for _, trailerModel in pairs(Config.TowVehicles.trailers) do
        if model == GetHashKey(trailerModel) then
            AttachEntityToEntity(target, towTruck, 0,
                Config.AttachOffset.trailer.x,
                Config.AttachOffset.trailer.y,
                Config.AttachOffset.trailer.z,
                0.0, 0.0, 0.0, false, false, false, false, 2, true)
            break
        end
    end
end)