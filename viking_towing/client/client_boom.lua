Config = {}
RegisterNetEvent('tow:boomAttach', function(towTruck)
    local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if playerVeh == 0 then return end
    TriggerServerEvent('tow:syncAttach', VehToNet(playerVeh), VehToNet(towTruck), 'boom')
end)

function animateBoom(towTruck, direction)
    local pos = GetEntityCoords(towTruck)
    local delta = direction == 'up' and 0.5 or -0.5
    SetEntityCoords(towTruck, pos.x, pos.y, pos.z + delta, false, false, false, true)
end