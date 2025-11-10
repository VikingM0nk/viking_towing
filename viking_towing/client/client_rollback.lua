Config = {}
RegisterNetEvent('tow:rollbackAttach', function(towTruck)
    local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if playerVeh == 0 then return end
    TriggerServerEvent('tow:syncAttach', VehToNet(playerVeh), VehToNet(towTruck), 'rollback')
end)

function animateRollback(towTruck)
    for i = 1, 15 do
        SetEntityRotation(towTruck, i, 0.0, 0.0, 2, true)
        Wait(50)
    end
end

function startWinch(targetVeh, towTruck)
    local startPos = GetEntityCoords(targetVeh)
    local endPos = GetEntityCoords(towTruck)
    for i = 1, 20 do
        local x = startPos.x + (endPos.x - startPos.x) * (i / 20)
        local y = startPos.y + (endPos.y - startPos.y) * (i / 20)
        local z = startPos.z + (endPos.z - startPos.z) * (i / 20)
        SetEntityCoords(targetVeh, x, y, z, false, false, false, true)
        Wait(100)
    end
end