local claimPos, closestTerritory, halfwayAlert, captureBlip = nil, nil, false, nil
function ObjectLoop()
    Citizen.CreateThread(function()
        local objLoopSleep = 1
        while (ESX.PlayerLoaded) do
            Citizen.Wait(objLoopSleep * 1000)
            local closestDistance = 2000
            if (claimPos == nil) then
                for k, v in pairs(Config.Territories) do
                    if (v.capture ~= nil) then
                        local distance = #(GetEntityCoords(PlayerPedId()) - v.capture.location)
                        if (distance < closestDistance) then 
                            closestDistance = distance 
                            closestTerritory = k
                        end
                    end
                end
            else
                closestDistance = #(GetEntityCoords(PlayerPedId()) - Config.Territories[closestTerritory].capture.location)
                if (closestDistance > 30) then
                    CaptureFailed()
                else
                    claimPos.duration = claimPos.duration - (objLoopSleep * 1000)
                    CaptureSuccessfulCheck()
                end
            end

            if (closestDistance < 100) then
                CreateObject()
                objLoopSleep = 5
            elseif (closestDistance > 1000) then
                objLoopSleep = 55
            elseif (closestDistance > 500) then
                objLoopSleep = 25
            elseif (closestDistance > 200) then
                objLoopSleep = 10
            end

            if (closestDistance > 150) then DeleteObject() end
        end
    end)
end

local spawnedObj = nil
function CreateObject()
    if (closestTerritory == nil or spawnedObj ~= nil) then return end
    local territoryConfig = Config.Territories[closestTerritory]

    ESX.Game.SpawnLocalObject(Config.TerritoryObject.objModel, territoryConfig.capture.location, function(obj)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetEntityHeading(obj, territoryConfig.capture.objHeading)
        spawnedObj = obj
    end)
    TargetSetup()
end

local targetCreated = false
function TargetSetup()
    if (targetCreated) then return end
    while (not DoesEntityExist(spawnedObj) or DoesEntityExist(spawnedObj) ~= 1) do Citizen.Wait(100) end
    
    local options = {{ event = 'territories:OpenStashCL', icon = 'fas fa-box', label = 'Open Stash', territory = closestTerritory }}
    table.insert(options, { event = 'territories:ForceOpenStashCL', icon = 'fas fa-terminal', label = 'Force Open Stash', territory = closestTerritory, item = Config.HackItem })
    if (Config.CaptureEnabled and Config.Territories[closestTerritory].capture.enabled) then
        table.insert(options, { event = 'territories:CaptureBegin', icon = 'fas fa-map-marker-alt', label = 'Capture', territory = closestTerritory })
    end
    -- table.insert(options, { event = '', icon = 'fas fa-box-circle-check', label = 'Open Stash' })

    exports.qtarget:AddTargetModel({Config.TerritoryObject.targetModel}, {
		options = options,
		distance = 4.0
	})
    targetCreated = true
end

function DeleteObject()
    if (spawnedObj == nil) then return end
    ESX.Game.DeleteObject(spawnedObj)
    spawnedObj = nil
    if (targetCreated) then 
        exports.qtarget:RemoveTargetModel({Config.TerritoryObject.targetModel}, {
            'Open Stash',
            'Capture',
            'Force Open Stash'
        })
        targetCreated = false
    end
end

function itemCount(item, metadata)
    return exports.ox_inventory:Search(2, item, metadata)
end


AddEventHandler('territories:OpenStashCL', function(data)
    TriggerServerEvent('territories:OpenStash', data.territory)
end)

AddEventHandler('territories:ForceOpenStashCL', function(data)
    local itemCount = itemCount(Config.HackItem)
    if (itemCount == 0) then
        lib.notify({
            title = 'Omastamine',
            description = 'You do not have the required item',
                duration = 5000,
            type = 'error'
        })
        
        return
    else
        TabletAnim()

        TriggerEvent('ultra-voltlab', 60, function(result, reason)
            Citizen.Wait(3000)
            if (result == 1) then
                TriggerServerEvent('territories:OpenStashForce', data.territory)
            else
                lib.notify({
                    title = 'Omastamine',
                    description = string.upper(reason),
                    duration = 5000,
                    type = 'error'
                })
            end
            TabletAnim(true)
        end)
    end
end)


function TabletAnim(endAnim)
    local playerPed = PlayerPedId()
    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local tabletProp = "prop_cs_tablet"
    if (endAnim) then
        StopAnimTask(playerPed, animDict, "base" ,8.0, -8.0, -1, 50, 0, false, false, false)
        DetachEntity(tabletObject, true, false)
        DeleteEntity(tabletObject)
    else
        RequestAnimDict(animDict)
        RequestModel(tabletProp)
        while not HasAnimDictLoaded(animDict) or not HasModelLoaded(tabletProp) do Citizen.Wait(100) end
        tabletObject = CreateObject(GetHashKey(tabletProp), 0.0, 0.0, 0.0, true, true, false)
        print(tabletObject)
        AttachEntityToEntity(tabletObject, playerPed, GetPedBoneIndex(playerPed, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
        SetModelAsNoLongerNeeded(tabletProp)
        TaskPlayAnim(playerPed, animDict, "base" , 3.0, 3.0, -1, 49, 0, 0, 0, 0)
    end
end

-- RegisterNetEvent('territories:CaptureBegin')
AddEventHandler('territories:CaptureBegin', function(data)
    if (not IsPedArmed(PlayerPedId(), 4)) then
        lib.notify({
            title = 'Omastamine',
            description = 'You must have a firearm to begin the capture',
            duration = 5000,
            type = 'error'
        })
        return
    end
    halfwayAlert = false

    -- local mugshot, mugshotStr = ESX.Game.GetPedMugshot(PlayerPedId())
    TriggerServerEvent('territories:CaptureStart', closestTerritory)
end)

RegisterNetEvent('territories:Capture')
AddEventHandler('territories:Capture', function(data)
    local territoryCfg = Config.Territories[closestTerritory]
    local captureDuration = territoryCfg.capture.captureTime * 60000
    claimPos = {
        zone = territoryCfg,
        duration = captureDuration,
        name = closestTerritory
    }

    lib.notify({
        title = 'Omastamine',
        description =  'Capturing: ' .. territoryCfg.label .. ', this will take ' .. math.ceil(captureDuration / 60000) .. ' mins',
        duration = 8000,
        type = 'inform'
    })


    captureBlip = AddBlipForRadius(territoryCfg.capture.location, 30.0)
    SetBlipColour(captureBlip, 1)
    GlobalBlipAlert(territoryCfg)
end)

-- RegisterNetEvent('territories:NotifyCaptureAttempt')
-- AddEventHandler('territories:NotifyCaptureAttempt', function(cancel, mugshot, mugshotStr)
--     if (mugshot == nil or mugshotStr == nil) then return end
--     if (not cancel) then
--         ESX.ShowAdvancedNotification('Territory Capture', '', 'Person Spotted', mugshotStr, 1)
--     end
--     UnregisterPedheadshot(mugshot)
-- end)

function CaptureFailed(force)
    if (claimPos.duration > 0 or force) then

        lib.notify({
            title = 'Omastamine',
            description = 'Capture Failed! You went too far from the zone',
            duration = 10000,
            type = 'error'
        })

        TriggerServerEvent('territories:CaptureFailed', closestTerritory)
        Cleanup()
    else
        CaptureSuccessfulCheck()
    end
end

function CaptureSuccessfulCheck()
    if (claimPos.duration <= 0) then

        lib.notify({
            title = 'Omastamine',
            description = 'You have captured the territory',
            duration = 10000,
            type = 'success'
        })


        TriggerServerEvent('territories:UpdateGang', claimPos.name)
        Cleanup()
    elseif (((claimPos.zone.capture.captureTime * 60000) / 2) > claimPos.duration and not halfwayAlert) then
        TriggerServerEvent('territories:CaptureHalfWay', claimPos.zone.label)
        halfwayAlert = true
    end
end

function GlobalBlipAlert(territoryCfg)
    local blip = AddBlipForRadius(territoryCfg.capture.location, 70.0)

    SetBlipSprite(blip, 9)
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 200)
    SetBlipAsShortRange(blip, true)
    SetBlipFlashes(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(territoryCfg.label .. ' Territory')
    EndTextCommandSetBlipName(blip)

    Citizen.Wait(60000)
    RemoveBlip(blip)
end

function CreateMapBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(Config.Territories) do
            if (v.parent == nil) then
                local blip = AddBlipForCoord(v.capture.location)

                SetBlipSprite(blip, 362)
                SetBlipDisplay(blip, 6)
                if (v.capture.captureEnabled) then
                    SetBlipScale(blip, 0.8)
                else
                    SetBlipScale(blip, 0.6)
                end
                SetBlipColour(blip, 1)
                SetBlipAsShortRange(blip, true)

                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(v.label .. ' Capture Point')
                EndTextCommandSetBlipName(blip)
            end
        end
    end)
end

RegisterCommand('territory', function()
    local zoneName = GetNameOfZone(GetEntityCoords(PlayerPedId()))
    TriggerEvent('chat:addMessage', {
        color = {255, 0, 0},
        multiline = true,
        args = {"TERRITORY ", 'Territory name: ' .. zoneName}
    })
end)

--[[--------------------------------------------------
Setup
--]]--------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if (resourceName == GetCurrentResourceName() and Config.Debug) then
        while (ESX == nil) do Citizen.Wait(100) end
        ESX.PlayerLoaded = true
        Setup()
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler("esx:playerLoaded", function(xPlayer)
    while (ESX == nil) do Citizen.Wait(100) end
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
    Setup()
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
    if (claimPos ~= nil) then CaptureFailed(true) end
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    if (claimPos ~= nil) then CaptureFailed(true) end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
        Cleanup()
	end
end)

-- function Setup()
--     CreateMapBlips()
--     ESX.TriggerServerCallback('bixbi_core:illegalTaskBlacklist', function(result)
--         if (not result) then
--             ObjectLoop()
--         end
--     end)
-- end


function Setup()
    CreateMapBlips()
    ObjectLoop()
end

function Cleanup()
    claimPos = nil
    closestTerritory = nil
    halfwayAlert = false
    if (captureBlip ~= nil) then
        RemoveBlip(captureBlip)
        captureBlip = nil
    end
    DeleteObject()
end