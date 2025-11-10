Config = {}
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tow:syncAttach', function(targetVeh, towVeh, type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then return end
    TriggerClientEvent('tow:clientAttach', -1, targetVeh, towVeh, type)
end)

RegisterNetEvent('tow:syncDetach', function(targetVeh)
    TriggerClientEvent('tow:clientDetach', -1, targetVeh)
end)