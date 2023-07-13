if (Config.MenuKeybind ~= nil) then RegisterKeyMapping(Config.MenuCommand, 'Territory Menu', 'keyboard', Config.MenuKeybind) end
RegisterCommand(Config.MenuCommand, function()
    TerritoryInfoMenu()
end, false)

AddEventHandler('territories:TerritoryInfoMenu', function(data)
    TerritoryInfoMenu()
end)
function TerritoryInfoMenu()
    ESX.TriggerServerCallback('territories:locationCheck', function(locationInfo)
        while (locationInfo == nil) do Citizen.Wait(100) end
        if (not locationInfo) then
            lib.notify({
                title = 'Omastamine',
                description = 'Territory information not found',
                duration = 4000,
                type = 'error'
            })

            return
        end

        if (string.lower(Config.MenuType) == 'ox') then
            OxMenu(locationInfo)
        else
            print("Vali õige Config.MenuType")
        end
        
    end, GetNameOfZone(GetEntityCoords(PlayerPedId())))
end


function OxMenu(locationInfo)
    local options = {
        {
            title = 'Territory Name: ' .. locationInfo.label,
            disabled = false
        },
        {
            title = 'Controlling Gang: ' .. locationInfo.gang,
            disabled = false
        }
    }

    if locationInfo.illegalitems ~= nil then
        if ESX.PlayerData.job.grade == 4 and string.lower(locationInfo.gang) == string.lower(ESX.PlayerData.job.name) then
            table.insert(options, {
                title = '> Drug Cut: ' .. locationInfo.itemstake .. '%',
                onSelect = function()
                    UpdateTakePercent('itemstake', locationInfo)
                end
            })
        else
            table.insert(options, {
                title = 'Drug Cut: ' .. locationInfo.itemstake .. '%',
                disabled = false
            })
        end

        local sellableDrugs = ""
        for k, v in pairs(locationInfo.illegalitems) do
            sellableDrugs = sellableDrugs .. "- " .. string.upper(v) .. "\n"
        end

        table.insert(options, {
            title = 'Sellable Drugs:',
            disabled = false,
            description = sellableDrugs
        })
    end

    if locationInfo.washzone ~= nil and locationInfo.washzone then
        if ESX.PlayerData.job.grade == 4 and string.lower(locationInfo.gang) == string.lower(ESX.PlayerData.job.name) then
            table.insert(options, {
                title = '> Wash Cut: ' .. locationInfo.washtake .. '%',
                onSelect = function()
                    UpdateTakePercent('washtake', locationInfo)
                end
            })
        else
            table.insert(options, {
                title = 'Wash Cut: ' .. locationInfo.washtake .. '%',
                disabled = false
            })
        end
    end

    if locationInfo.parent ~= nil then
        table.insert(options, { title = '' })
        table.insert(options, {
            title = 'Parent Territory: ' .. locationInfo.parent,
            disabled = false
        })
    end

    lib.registerContext({
        id = 'territoryinfo',
        title = 'Territory Information',
        options = options
    })

    lib.showContext('territoryinfo')
end




function UpdateTakePercent(type, locationInfo)
    local dialog = lib.inputDialog("Change Percentage", {
        {
            type = "number",
            label = "Percentage: 15 = 15%",
            default = "15",
            min = Config.MinPercentage,
            max = Config.MaxPercentage,
            step = 1
        }
    })

    if dialog ~= nil then
        local percentage = tonumber(dialog[1]) or 5
        TriggerServerEvent('territories:sv_UpdateTake', locationInfo.location, ESX.Math.Round(percentage, 2), type)
    end
end
