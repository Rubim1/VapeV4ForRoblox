-- ===================================
-- MODUL UTILITAS KENDARAAN TERPISAH
-- ===================================

-- Modul untuk Instant Tow & Heli Pickup
run(function()
    local towingHooked = false
    local originalHookNearest

    local function applyTowHook()
        if towingHooked then return end
        local success, binder = pcall(function() return require(game:GetService('ReplicatedStorage').VehicleLink.VehicleLinkBinder) end)
        if not success or not binder or not binder._constructor or not binder._constructor._hookNearest then return end

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
            if not success then return end

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
-- MODUL PERFORMA KENDARAAN UTAMA
-- ===================================

run(function()
    local VehicleOverdrive = minigamesCategory:CreateModule({
        Name = 'Vehicle Overdrive',
        Function = function(callback)
            -- State untuk menyimpan nilai asli dan hook
            local state = {
                hooks = {},
                originals = {},
                thread = nil,
                inVehicle = false
            }

            -- Fungsi untuk memulai loop modifikasi
            local function startLoop()
                if state.thread then return end
                state.thread = task.spawn(function()
                    local vehicleUtils = require(game:GetService('ReplicatedStorage').Vehicle.VehicleUtils)
                    while task.wait(0.1) do
                        if not VehicleOverdrive.Enabled then break end

                        local success, packet = pcall(vehicleUtils.GetLocalVehiclePacket)
                        if not success or not packet then continue end

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
            
            -- Fungsi untuk mengatur hook untuk kendaraan fisika
            local function setupPhysicsHooks()
                -- Hook untuk Helikopter
                if client.vclasses and client.vclasses.Heli and not state.hooks.heli then
                    state.originals.heliUpdate = client.vclasses.Heli.Update
                    client.vclasses.Heli.Update = function(self, ...)
                        state.originals.heliUpdate(self, ...)
                        if VehicleOverdrive.Enabled and heliControls.speed.Enabled then
                            self.Velocity.Velocity = self.Velocity.Velocity * Vector3.new(heliControls.forward.Value / 100, heliControls.vertical.Value / 10, heliControls.forward.Value / 100)
                            self.Rotate.AngularVelocity = self.Rotate.AngularVelocity * (heliControls.turn.Value / 100)
                        end
                    end
                    state.hooks.heli = true
                end

                -- Hook untuk Volt
                if client.vclasses and client.vclasses.Volt and not state.hooks.volt then
                    state.originals.voltUpdate = client.vclasses.Volt.Update
                    client.vclasses.Volt.Update = function(self, ...)
                        state.originals.voltUpdate(self, ...)
                        if VehicleOverdrive.Enabled and voltControls.speed.Enabled then
                            self.Force.Force = self.Force.Force * (1 + voltControls.speedSlider.Value)
                        end
                    end
                    state.hooks.volt = true
                end
            end

            -- Fungsi untuk mengatur konstanta untuk kendaraan tertentu
            local function setupConstants()
                -- Konstanta untuk Motorbike
                if client.alexchassis2 and client.alexchassis2.UpdateHQ then
                    if bikeControls.speed.Enabled then
                        if not state.originals.motorbikeSpeed then
                            state.originals.motorbikeSpeed = debug.getconstant(client.alexchassis2.UpdateHQ, 76)
                        end
                        debug.setconstant(client.alexchassis2.UpdateHQ, 76, 1.2 + bikeControls.speedSlider.Value)
                    elseif state.originals.motorbikeSpeed then
                        debug.setconstant(client.alexchassis2.UpdateHQ, 76, state.originals.motorbikeSpeed)
                        state.originals.motorbikeSpeed = nil
                    end
                end

                -- Konstanta untuk Tank
                if client.tankbinder and client.tankbinder._handleSeatedDriver then
                    local proto = debug.getproto(client.tankbinder._handleSeatedDriver, 4)
                    if proto then
                        if tankControls.speed.Enabled then
                            if not state.originals.tankEngineSpeed then
                                state.originals.tankEngineSpeed = debug.getconstant(proto, 20)
                            end
                            debug.setconstant(proto, 20, tankControls.speedSlider.Value)
                        elseif state.originals.tankEngineSpeed then
                            debug.setconstant(proto, 20, state.originals.tankEngineSpeed)
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
                if state.hooks.heli and state.originals.heliUpdate then
                    client.vclasses.Heli.Update = state.originals.heliUpdate
                end
                if state.hooks.volt and state.originals.voltUpdate then
                    client.vclasses.Volt.Update = state.originals.voltUpdate
                end
                if state.originals.motorbikeSpeed then
                    debug.setconstant(client.alexchassis2.UpdateHQ, 76, state.originals.motorbikeSpeed)
                end
                if state.originals.tankEngineSpeed then
                    debug.setconstant(debug.getproto(client.tankbinder._handleSeatedDriver, 4), 20, state.originals.tankEngineSpeed)
                end
                -- Reset state
                state = { hooks = {}, originals = {}, thread = nil, inVehicle = false }
            end

            if callback then
                -- Event listener untuk mendeteksi saat pemain masuk/keluar kendaraan
                local vehicleUtils = require(game:GetService('ReplicatedStorage').Vehicle.VehicleUtils)
                local connection1, connection2

                local function onVehicleEntered(packet)
                    state.inVehicle = true
                    startLoop()
                    setupPhysicsHooks()
                    setupConstants()
                end

                local function onVehicleExited()
                    state.inVehicle = false
                end
                
                if vehicleUtils.OnVehicleEntered then
                    connection1 = vehicleUtils.OnVehicleEntered:Connect(onVehicleEntered)
                end
                if vehicleUtils.OnVehicleExited then
                    connection2 = vehicleUtils.OnVehicleExited:Connect(onVehicleExited)
                end

                -- Cek jika sudah ada di dalam kendaraan saat modul diaktifkan
                local success, packet = pcall(vehicleUtils.GetLocalVehiclePacket)
                if success and packet then
                    onVehicleEntered(packet)
                end

                -- Simpan koneksi untuk cleanup
                state.connections = {connection1, connection2}
            else
                restore()
                -- Putuskan koneksi event jika ada
                if state.connections then
                    for _, conn in pairs(state.connections) do
                        if conn then conn:Disconnect() end
                    end
                end
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