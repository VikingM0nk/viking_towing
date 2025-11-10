Config = {}
local lib = require 'ox_lib'
RegisterNetEvent('tow:openMenu', function(towTruck)
    lib.registerContext({
        id = 'tow_controls',
        title = 'Tow Controls',
        options = {
            { title = 'Winch Vehicle', event = 'tow:winch', args = towTruck },
            { title = 'Tilt Rollback', event = 'tow:tilt', args = towTruck },
            { title = 'Attach to Rollback', event = 'tow:rollbackAttach', args = towTruck },
            { title = 'Attach to Boom', event = 'tow:boomAttach', args = towTruck },
            { title = 'Raise Boom', event = 'tow:boomRaise', args = towTruck },
            { title = 'Lower Boom', event = 'tow:boomLower', args = towTruck },
            { title = 'Select Tow Target', event = 'tow:selectTarget', args = towTruck },
            { title = 'Detach Vehicle', event = 'tow:detach' }
        }
    })
    lib.showContext('tow_controls')
end)

RegisterNetEvent('tow:winch', function(towTruck)
    local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if playerVeh == 0 then return end
    startWinch(playerVeh, towTruck)
end)

RegisterNetEvent('tow:tilt', function(towTruck)
    animateRollback(towTruck)
end)

RegisterNetEvent('tow:boomRaise', function(towTruck)
    animateBoom(towTruck, 'up')
end)

RegisterNetEvent('tow:boomLower', function(towTruck)
    animateBoom(towTruck, 'down')
end)

RegisterNetEvent('tow:detach', function()
    local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if playerVeh == 0 then return end
    TriggerServerEvent('tow:syncDetach', VehToNet(playerVeh))
end)