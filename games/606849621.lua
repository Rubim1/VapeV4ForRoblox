-- ===================================
-- STABLE MINIGAMES & UTILITY MODULES
-- ===================================

-- We use a central hook for remote events to ensure stability.
-- This is a proven method from the original script.
local remotes = {}
local function fireHook(self, id, ...)
    -- Find the friendly name for the remote event
    local remoteName = "Unknown"
    for name, remoteId in pairs(remotes) do
        if remoteId == id then
            remoteName = name
            break
        end
    end

    -- Intercept specific events
    if remoteName == 'UseNitro' and vape and vape.Categories and vape.Categories.Utility and vape.Categories.Utility:FindModule('InfiniteNitro') and vape.Categories.Utility:FindModule('InfiniteNitro').Enabled then
        return -- Block nitro usage if Infinite Nitro is enabled
    end
    
    if remoteName == 'SelfDamage' and vape and vape.Categories and vape.Categories.Blatant and vape.Categories.Blatant:FindModule('LazerGodmode') and vape.Categories.Blatant:FindModule('LazerGodmode').Enabled then
        return -- Block self-damage for LazerGodmode
    end

    -- Let the original function handle the call
    return originalFireServer(self, id, ...)
end

-- Hook the main FireServer function if it exists
if jb and jb.VehicleController then
    local remotetable = debug.getupvalue(jb.VehicleController.toggleLocalLocked, 2)
    if remotetable then
        local originalFireServer = remotetable.FireServer
        if originalFireServer then
            -- Create the remotes table (this is a simplified version of the original)
            remotes = {
                ['UseNitro'] = 'CalculateDelta',
                ['SelfDamage'] = 'LocalScript',
                ['PopTires'] = 'Gun',
                ['Arrest'] = 'AttemptArrest',
                ['GetIn'] = 'AttemptVehicleEnter',
                ['Eject'] = 'AttemptVehicleEject',
                ['TaseReplicate'] = 'Draw',
                ['Punch'] = 'attemptPunch'
            }
            hookfunction(remotetable.FireServer, fireHook)
        end
    end
end

-- Modul untuk Instant Tow & Heli Pickup
run(function()
    local towingHooked = false
    local originalHookNearest

    local function applyTowHook()
        if towingHooked then return end
        local success, binder = pcall(function() return require(game:GetService('ReplicatedStorage').VehicleLink.VehicleLinkBinder) end)
        if not success or not binder or not binder._constructor or not binder._constructor._hookNearest then
            warn('[Vape] Instant Actions: Failed to find VehicleLinkBinder.')
            return
        end

        originalHookNearest = binder._constructor._hookNearest
        binder._constructor._hookNearest = function(...)
            local args = {...}
            local data = args[1]
            if data and data.obj and data.nearestObj then
                local ropeName = data.obj.Name
                local isTow = ropeName == 'MetalHook'
                local isHeli = ropeName == 'RopePull'
                if isTow or isHeli then
                    local success, geom = pcall(function() return require(game:GetService('ReplicatedStorage'):WaitForChild('Std'):WaitForChild('GeomUtils')) end)
                    if success and geom then
                        local closest = geom.closestPointInPart(data.nearestObj.PrimaryPart, data.obj.Position)
                        local offset = data.nearestObj.PrimaryPart.CFrame:PointToObjectSpace(closest)
                        data.manifest.reqLinkRemote:FireServer(data.nearestObj, offset)
                        return
                    end
                end
            end
            return originalHookNearest(...)
        end
        towingHooked = true
    end

    local function restoreTowHook()
        if not towingHooked or not originalHookNearest then return end
        local success, binder = pcall(function() return require(game:GetService('ReplicatedStorage').VehicleLink.VehicleLinkBinder) end)
        if success and binder and binder._constructor then
            binder._constructor._hookNearest = originalHookNearest
        end
        towingHooked = false
        originalHookNearest = nil
    end
    
    minigamesCategory:CreateModule({
        Name = 'Instant Actions',
        Function = function(callback)
            if callback then
                applyTowHook()
            else
                restoreTowHook()
            end
        end,
        Tooltip = 'Menyediakan fungsi Tow dan Pickup Heli secara instan.'
    })
end)

-- Modul untuk Auto Hijack
run(function()
    local hijackThread = nil

    local function runHijackLoop()
        if hijackThread then return end
        hijackThread = task.spawn(function()
            local success, actionService = pcall(function() return require(game:GetService('ReplicatedStorage').ActionButton.ActionButtonService) end)
            if not success then 
                warn('[Vape] Auto Hijack: Failed to load ActionButtonService.')
                return 
            end

            while task.wait(0.1) do
                for _, action in pairs(actionService.active) do
                    if action.Name == 'Hijack' and table.find(action.keyCodes, Enum.KeyCode.V) then
                        pcall(action.onPressed, true)
                    end
                end
            end
        end)
    end

    minigamesCategory:CreateModule({
        Name = 'Auto Hijack',
        Function = function(callback)
            if callback then
                runHijackLoop()
            else
                if hijackThread then
                    task.cancel(hijackThread)
                    hijackThread = nil
                end
            end
        end,
        Tooltip = 'Secara otomatis membajak kendaraan saat tombol V ditekan.'
    })
end)


-- ===================================
-- MODUL PERFORMA KENDARAAN UTAMA (STABIL)
-- ===================================

run(function()
    local VehicleOverdrive = minigamesCategory:CreateModule({
        Name = 'Vehicle Overdrive',
        Function = function(callback)
            if callback then
                -- State untuk menyimpan nilai asli dan hook
                local state = {
                    hooks = {},
                    originals = {},
                    thread = nil
                }

                -- Fungsi untuk memulai loop modifikasi paket kendaraan (Mobil & Heli)
                local function startPacketLoop()
                    if state.thread then return end
                    state.thread = task.spawn(function()
                        local success, vehicleUtils = pcall(function() return require(game:GetService('ReplicatedStorage').Vehicle.VehicleUtils) end)
                        if not success then return end
                        
                        while task.wait(0.1) do
                            if not VehicleOverdrive.Enabled then break end

                            local ok, packet = pcall(vehicleUtils.GetLocalVehiclePacket)
                            if not ok or not packet then continue end

                            -- Modifikasi untuk Chassis (Mobil)
                            if packet.Type == 'Chassis' then
                                if carControls.engine.Enabled then
                                    packet.GarageEngineSpeed = carControls.engineSlider.Value
                                end
                                if carControls.turn.Enabled then
                                    packet.TurnSpeed = carControls.turnSlider.Value
                                end
                                if carControls.suspension.Enabled then
                                    packet.Height = carControls.suspensionSlider.Value
                                end
                            -- Modifikasi untuk Helikopter
                            elseif packet.Type == 'Heli' then
                                if heliControls.height.Enabled then
                                    packet.MaxHeight = 9e9
                                end
                            end
                        end
                        state.thread = nil
                    end)
                end
                
                -- Fungsi untuk mengatur hook untuk kendaraan fisika (Heli, Volt, Motor, Tank)
                local function setupPhysicsHooks()
                    -- Hook untuk Helikopter (Fisika)
                    if client.vclasses and client.vclasses.Heli and not state.hooks.heliPhysics then
                        local success, err = pcall(function()
                            state.originals.heliUpdate = client.vclasses.Heli.Update
                            client.vclasses.Heli.Update = function(self, ...)
                                state.originals.heliUpdate(self, ...)
                                if VehicleOverdrive.Enabled and heliControls.speed.Enabled then
                                    self.Velocity.Velocity = self.Velocity.Velocity * Vector3.new(heliControls.forward.Value / 100, heliControls.vertical.Value / 10, heliControls.forward.Value / 100)
                                    self.Rotate.AngularVelocity = self.Rotate.AngularVelocity * (heliControls.turn.Value / 100)
                                end
                            end
                        end)
                        if not success then warn('[Vape] Vehicle Overdrive: Failed to hook Heli physics - ', err) else state.hooks.heliPhysics = true end
                    end

                    -- Hook untuk Volt (Fisika)
                    if client.vclasses and client.vclasses.Volt and not state.hooks.volt then
                        local success, err = pcall(function()
                            state.originals.voltUpdate = client.vclasses.Volt.Update
                            client.vclasses.Volt.Update = function(self, ...)
                                state.originals.voltUpdate(self, ...)
                                if VehicleOverdrive.Enabled and voltControls.speed.Enabled then
                                    self.Force.Force = self.Force.Force * (1 + voltControls.speedSlider.Value)
                                end
                            end
                        end)
                        if not success then warn('[Vape] Vehicle Overdrive: Failed to hook Volt physics - ', err) else state.hooks.volt = true end
                    end
                end

                -- Fungsi untuk mengatur konstanta untuk kendaraan tertentu (Motor, Tank)
                local function setupConstants()
                    -- Konstanta untuk Motorbike
                    if client.alexchassis2 and client.alexchassis2.UpdateHQ then
                        if bikeControls.speed.Enabled then
                            local success, err = pcall(function()
                                if not state.originals.motorbikeSpeed then
                                    state.originals.motorbikeSpeed = debug.getconstant(client.alexchassis2.UpdateHQ, 76)
                                end
                                debug.setconstant(client.alexchassis2.UpdateHQ, 76, 1.2 + bikeControls.speedSlider.Value)
                            end)
                            if not success then warn('[Vape] Vehicle Overdrive: Failed to set Motorbike constant - ', err) end
                        elseif state.originals.motorbikeSpeed then
                            pcall(debug.setconstant, client.alexchassis2.UpdateHQ, 76, state.originals.motorbikeSpeed)
                            state.originals.motorbikeSpeed = nil
                        end
                    end

                    -- Konstanta untuk Tank
                    if client.tankbinder and client.tankbinder._handleSeatedDriver then
                        local success, proto = pcall(debug.getproto, client.tankbinder._handleSeatedDriver, 4)
                        if success and proto then
                            if tankControls.speed.Enabled then
                                local s, err = pcall(function()
                                    if not state.originals.tankEngineSpeed then
                                        state.originals.tankEngineSpeed = debug.getconstant(proto, 20)
                                    end
                                    debug.setconstant(proto, 20, tankControls.speedSlider.Value)
                                end)
                                if not s then warn('[Vape] Vehicle Overdrive: Failed to set Tank constant - ', err) end
                            elseif state.originals.tankEngineSpeed then
                                pcall(debug.setconstant, proto, 20, state.originals.tankEngineSpeed)
                                state.originals.tankEngineSpeed = nil
                            end
                        end
                    end
                end

                -- Fungsi untuk memulihkan semua perubahan
                local function restore()
                    if state.thread then
                        task.cancel(state.thread)
                        state.thread = nil
                    end
                    if state.hooks.heliPhysics and state.originals.heliUpdate then
                        pcall(function() client.vclasses.Heli.Update = state.originals.heliUpdate end)
                    end
                    if state.hooks.volt and state.originals.voltUpdate then
                        pcall(function() client.vclasses.Volt.Update = state.originals.voltUpdate end)
                    end
                    if state.originals.motorbikeSpeed then
                        pcall(debug.setconstant, client.alexchassis2.UpdateHQ, 76, state.originals.motorbikeSpeed)
                    end
                    if state.originals.tankEngineSpeed then
                        pcall(debug.setconstant, debug.getproto(client.tankbinder._handleSeatedDriver, 4), 20, state.originals.tankEngineSpeed)
                    end
                    -- Reset state
                    for k in pairs(state) do state[k] = nil end
                end

                -- Event listener untuk mendeteksi saat pemain masuk/keluar kendaraan
                local success, vehicleUtils = pcall(function() return require(game:GetService('ReplicatedStorage').Vehicle.VehicleUtils) end)
                if success and vehicleUtils.OnVehicleEntered and vehicleUtils.OnVehicleExited then
                    local connection1 = vehicleUtils.OnVehicleEntered:Connect(function()
                        startPacketLoop()
                        setupPhysicsHooks()
                        setupConstants()
                    end)
                    local connection2 = vehicleUtils.OnVehicleExited:Connect(function()
                        -- Packet loop will stop on its own when no packet is found
                    end)
                    
                    -- Cek jika sudah ada di dalam kendaraan saat modul diaktifkan
                    local ok, packet = pcall(vehicleUtils.GetLocalVehiclePacket)
                    if ok and packet then
                        startPacketLoop()
                        setupPhysicsHooks()
                        setupConstants()
                    end

                    -- Simpan koneksi untuk cleanup
                    state.connections = {connection1, connection2}
                else
                    warn('[Vape] Vehicle Overdrive: Failed to attach vehicle entry/exit listeners.')
                end

                -- Cleanup function for when the module is disabled
                   vape:Clean(function()
                    restore()
                    if state.connections then
                        for _, conn in pairs(state.connections) do
                            if conn then conn:Disconnect() end
                        end
                    end
                end)

            end
        end,
        Tooltip = 'Suite modifikasi performa kendaraan yang komprehensif dan stabil.'
    })

    -- Kontrol untuk Mobil (Chassis)
    local carControls = {}
    carControls.engine = VehicleOverdrive:CreateToggle({ Name = 'Engine Override' })
    carControls.engineSlider = VehicleOverdrive:CreateSlider({
        Name = 'Engine Speed', Min = 10, Max = 250, Default = 50, Suffix = 'x'
    })
    carControls.turn = VehicleOverdrive:CreateToggle({ Name = 'Turn Override' })
    carControls.turnSlider = VehicleOverdrive:CreateSlider({
        Name = 'Turn Speed', Min = 1, Max = 6, Default = 2, Decimal = 1, Suffix = 'x'
    })
    carControls.suspension = VehicleOverdrive:CreateToggle({ Name = 'Suspension Override' })
    carControls.suspensionSlider = VehicleOverdrive:CreateSlider({
        Name = 'Suspension Height', Min = 1, Max = 200, Default = 10
    })

    -- Kontrol untuk Helikopter
    local heliControls = {}
    heliControls.speed = VehicleOverdrive:CreateToggle({ Name = 'Heli Speed Override' })
    heliControls.forward = VehicleOverdrive:CreateSlider({
        Name = 'Forward Speed %', Min = 10, Max = 500, Default = 100
    })
    heliControls.vertical = VehicleOverdrive:CreateSlider({
        Name = 'Vertical Speed %', Min = 10, Max = 300, Default = 100
    })
    heliControls.turn = VehicleOverdrive:CreateSlider({
        Name = 'Turn Speed %', Min = 10, Max = 500, Default = 100
    })
    heliControls.height = VehicleOverdrive:CreateToggle({ Name = 'Infinite Height' })

    -- Kontrol untuk Volt
    local voltControls = {}
    voltControls.speed = VehicleOverdrive:CreateToggle({ Name = 'Volt Speed Override' })
    voltControls.speedSlider = VehicleOverdrive:CreateSlider({
        Name = 'Volt Multiplier', Min = 0, Max = 25, Default = 0, Suffix = 'x'
    })

    -- Kontrol untuk Motorbike
    local bikeControls = {}
    bikeControls.speed = VehicleOverdrive:CreateToggle({ Name = 'Motorbike Speed Override' })
    bikeControls.speedSlider = VehicleOverdrive:CreateSlider({
        Name = 'Motorbike Multiplier', Min = 0, Max = 100, Default = 0, Suffix = 'x'
    })

    -- Kontrol untuk Tank
    local tankControls = {}
    tankControls.speed = VehicleOverdrive:CreateToggle({ Name = 'Tank Engine Override' })
    tankControls.speedSlider = VehicleOverdrive:CreateSlider({
        Name = 'Tank Engine Speed', Min = 1, Max = 500, Default = 10, Suffix = 'x'
    })
end)