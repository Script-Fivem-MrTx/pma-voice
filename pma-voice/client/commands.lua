local wasProximityDisabledFromOverride = false
disableProximityCycle = false
RegisterCommand('setvoiceintent', function(source, args)
    if GetConvarInt('voice_allowSetIntent', 1) == 1 then
        local intent = args[1]
        if intent == 'speech' then
            MumbleSetAudioInputIntent(speech)
        elseif intent == 'music' then
            MumbleSetAudioInputIntent(music)
        end
        LocalPlayer.state:set('voiceIntent', intent, true)
    end
end)

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
    if not args[1] then
        return
    end
    setVolume(tonumber(args[1]))
end)

exports('setAllowProximityCycleState', function(state)
    type_check({state, "boolean"})
    disableProximityCycle = state
end)

function drawProximityCircle(proximityRange)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    local duration = 400 -- 1 detik

    Citizen.CreateThread(function()
        local startTime = GetGameTimer()

        while (GetGameTimer() - startTime < duration) do
            DrawMarker(1, -- Type of marker
            coords.x, coords.y, coords.z - 1, -- Position (X, Y, Z-1)
            0.0, 0.0, 0.0, -- Direction (unused for type 1)
            0.0, 0.0, 0.0, -- Rotation (unused for type 1)
            proximityRange * 5, proximityRange * 5, 0.5, -- Scale (X, Y, Z)
            0, 255, 0, -- Color (R, G, B) set to green
            100, -- Alpha (transparency)
            false, -- BobUpAndDown
            true, -- FaceCamera
            2, -- Unknown parameter (usually 0 or 1)
            nil, nil, false -- Additional parameters
            )
            Citizen.Wait(0)
        end

    end)
end

function setProximityState(proximityRange, isCustom)
    local voiceModeData = Cfg.voiceModes[mode]
    MumbleSetTalkerProximity(proximityRange + 0.0)

    drawProximityCircle(proximityRange)

    LocalPlayer.state:set('proximity', {
        index = mode,
        distance = proximityRange,
        mode = isCustom and "Custom" or voiceModeData[2]
    }, true)

    sendUIMessage({
        voiceMode = isCustom and #Cfg.voiceModes or mode - 1
    })
end

RegisterCommand('cycleproximity', function()

    if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then
        return
    end
    local newMode = mode + 1

    if newMode <= #Cfg.voiceModes then
        mode = newMode
    else
        mode = 1
    end

    setProximityState(Cfg.voiceModes[mode][1], false)

    TriggerEvent('pma-voice:setTalkingMode', mode)
end, false)

exports("overrideProximityRange", function(range, disableCycle)
    type_check({range, "number"})
    setProximityState(range, true)
    if disableCycle then
        disableProximityCycle = true
        wasProximityDisabledFromOverride = true
    end
end)

exports("clearProximityOverride", function()
    local voiceModeData = Cfg.voiceModes[mode]
    setProximityState(voiceModeData[1], false)
    if wasProximityDisabledFromOverride then
        disableProximityCycle = false
    end
end)

RegisterCommand('cycleproximity', function()

    if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then
        return
    end
    local newMode = mode + 1

    if newMode <= #Cfg.voiceModes then
        mode = newMode
    else
        mode = 1
    end

    setProximityState(Cfg.voiceModes[mode][1], false)

    TriggerEvent('pma-voice:setTalkingMode', mode)
end, false)
if gameVersion == 'fivem' then
    RegisterKeyMapping('cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))
end
