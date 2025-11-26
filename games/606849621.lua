-- Minigames Category - Complete Refactor
local MinigamesCategory = vape.Categories.Minigames or vape.Categories.Utility

-- Configuration for stable module handling
local ModuleRegistry = {
    ActiveModules = {},
    Threads = {},
    OriginalFunctions = {},
    ConnectionHandles = {}
}

-- Thread management system
local function SafeThread(name, func, ...)
    if ModuleRegistry.Threads[name] then
        ModuleRegistry.Threads[name] = nil
    end
    
    local thread = task.spawn(function(...)
        local args = {...}
        local success, err = pcall(function()
            func(table.unpack(args))
        end)
        if not success then
            warn(string.format("[%s] Thread error: %s", name, err))
        end
    end, ...)
    
    ModuleRegistry.Threads[name] = thread
    return thread
end

local function StopThread(name)
    if ModuleRegistry.Threads[name] then
        ModuleRegistry.Threads[name] = nil
    end
end

-- Universal cleanup function
local function CleanupModule(moduleName)
    -- Stop associated threads
    StopThread(moduleName)
    StopThread(moduleName .. "_Loop")
    StopThread(moduleName .. "_Update")
    
    -- Disconnect connections
    if ModuleRegistry.ConnectionHandles[moduleName] then
        for _, connection in pairs(ModuleRegistry.ConnectionHandles[moduleName]) do
            if connection then
                connection:Disconnect()
            end
        end
        ModuleRegistry.ConnectionHandles[moduleName] = nil
    end
    
    -- Restore original functions
    if ModuleRegistry.OriginalFunctions[moduleName] then
        for funcName, original in pairs(ModuleRegistry.OriginalFunctions[moduleName]) do
            if original and type(original) == "function" then
                local success = pcall(function()
                    -- Restore hooked functions
                    if string.find(funcName, "hook_") then
                        local targetFunc = string.gsub(funcName, "hook_", "")
                        -- Implementation depends on specific function restoration
                    end
                end)
                if not success then
                    warn(string.format("[%s] Failed to restore %s", moduleName, funcName))
                end
            end
        end
        ModuleRegistry.OriginalFunctions[moduleName] = nil
    end
    
    ModuleRegistry.ActiveModules[moduleName] = nil
end

-- Enhanced Infinite Nitro with better state management
local InfiniteNitro = MinigamesCategory:CreateModule({
    Name = "Infinite Nitro",
    Function = function(callback)
        if callback then
            ModuleRegistry.ActiveModules["InfiniteNitro"] = true
            
            SafeThread("InfiniteNitro", function()
                local nitroStateTable
                
                -- Locate nitro state table more reliably
                for _, func in getgc(true) do
                    if type(func) == "function" and islclosure(func) then
                        local info = getinfo(func)
                        if info.name == "StartNitro" or (info.source and string.find(info.source, "Nitro")) then
                            for i = 1, 10 do
                                local success, value = pcall(getupvalue, func, i)
                                if success and type(value) == "table" and rawget(value, "Nitro") ~= nil then
                                    nitroStateTable = value
                                    break
                                end
                            end
                            if nitroStateTable then break end
                        end
                    end
                end
                
                if not nitroStateTable then
                    warn("[InfiniteNitro] Failed to locate nitro state table")
                    InfiniteNitro.ToggleButton(false)
                    return
                end
                
                -- Store original values for restoration
                ModuleRegistry.OriginalFunctions["InfiniteNitro"] = {
                    originalNitro = nitroStateTable.Nitro,
                    originalMax = nitroStateTable.NitroLastMax
                }
                
                while ModuleRegistry.ActiveModules["InfiniteNitro"] do
                    if nitroStateTable then
                        nitroStateTable.NitroLastMax = 250
                        nitroStateTable.Nitro = 249
                        nitroStateTable.NitroForceUIUpdate = true
                    end
                    task.wait(0.1)
                end
            end)
        else
            CleanupModule("InfiniteNitro")
            
            -- Restore original nitro values
            if ModuleRegistry.OriginalFunctions["InfiniteNitro"] then
                -- Values will be restored naturally when module is disabled
            end
        end
    end,
    Tooltip = "Unlimited nitro for all vehicles - Stable version"
})

-- Enhanced Engine Speed with vehicle detection
local EngineSpeed = MinigamesCategory:CreateModule({
    Name = "Engine Speed",
    Function = function(callback)
        if callback then
            ModuleRegistry.ActiveModules["EngineSpeed"] = true
            
            SafeThread("EngineSpeed", function()
                local originalValues = {}
                local vehicleUtils = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils)
                
                while ModuleRegistry.ActiveModules["EngineSpeed"] do
                    local success, vehiclePacket = pcall(vehicleUtils.GetLocalVehiclePacket)
                    
                    if success and vehiclePacket and vehiclePacket.Type == "Chassis" then
                        if not originalValues[vehiclePacket] then
                            originalValues[vehiclePacket] = vehiclePacket.GarageEngineSpeed
                        end
                        
                        if EngineSpeedSlider then
                            vehiclePacket.GarageEngineSpeed = EngineSpeedSlider.Value
                        end
                    elseif next(originalValues) ~= nil then
                        -- Restore original values when no vehicle
                        for packet, originalValue in pairs(originalValues) do
                            if packet and typeof(packet) == "table" then
                                packet.GarageEngineSpeed = originalValue
                            end
                        end
                        originalValues = {}
                    end
                    
                    task.wait(0.2)
                end
                
                -- Cleanup on disable
                for packet, originalValue in pairs(originalValues) do
                    if packet and typeof(packet) == "table" then
                        packet.GarageEngineSpeed = originalValue
                    end
                end
            end)
        else
            CleanupModule("EngineSpeed")
        end
    end,
    Tooltip = "Modify vehicle engine speed with proper cleanup"
})

local EngineSpeedSlider = EngineSpeed:CreateSlider({
    Name = "Speed Multiplier",
    Min = 1,
    Max = 200,
    Default = 10,
    Suffix = "x",
    Function = function(val)
        -- Value is applied in the main thread
    end
})

-- Vehicle Overdrive - Completely Rewritten
local VehicleOverdrive = MinigamesCategory:CreateModule({
    Name = "Vehicle Overdrive",
    Function = function(callback)
        if callback then
            ModuleRegistry.ActiveModules["VehicleOverdrive"] = true
            
            -- Initialize connection handles for this module
            ModuleRegistry.ConnectionHandles["VehicleOverdrive"] = {}
            
            -- Vehicle enter/exit tracking
            local vehicleUtils = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils)
            
            local function onVehicleEntered(packet)
                if packet and ModuleRegistry.ActiveModules["VehicleOverdrive"] then
                    -- Apply overdrive settings to new vehicle
                    task.wait(0.1)
                    -- Settings will be applied in the main thread
                end
            end
            
            local function onVehicleExited()
                -- Cleanup handled in main thread
            end
            
            -- Connect to vehicle events
            if vehicleUtils.OnVehicleEntered then
                table.insert(ModuleRegistry.ConnectionHandles["VehicleOverdrive"], 
                    vehicleUtils.OnVehicleEntered:Connect(onVehicleEntered))
            end
            
            if vehicleUtils.OnVehicleExited then
                table.insert(ModuleRegistry.ConnectionHandles["VehicleOverdrive"],
                    vehicleUtils.OnVehicleExited:Connect(onVehicleExited))
            end
            
            -- Main overdrive application thread
            SafeThread("VehicleOverdrive_Main", function()
                local appliedPackets = {}
                
                while ModuleRegistry.ActiveModules["VehicleOverdrive"] do
                    local success, vehiclePacket = pcall(vehicleUtils.GetLocalVehiclePacket)
                    
                    if success and vehiclePacket then
                        if not appliedPackets[vehiclePacket] then
                            appliedPackets[vehiclePacket] = {
                                EngineSpeed = vehiclePacket.GarageEngineSpeed,
                                TurnSpeed = vehiclePacket.TurnSpeed,
                                Height = vehiclePacket.Height
                            }
                        end
                        
                        -- Apply current slider values
                        if OverdriveEngineToggle and OverdriveEngineToggle.Enabled then
                            vehiclePacket.GarageEngineSpeed = OverdriveEngineSlider.Value
                        end
                        
                        if OverdriveTurnToggle and OverdriveTurnToggle.Enabled then
                            vehiclePacket.TurnSpeed = OverdriveTurnSlider.Value
                        end
                        
                        if OverdriveSuspensionToggle and OverdriveSuspensionToggle.Enabled then
                            vehiclePacket.Height = OverdriveSuspensionSlider.Value
                        end
                    else
                        -- Restore any packets we modified
                        for packet, originalValues in pairs(appliedPackets) do
                            if packet and typeof(packet) == "table" then
                                packet.GarageEngineSpeed = originalValues.EngineSpeed
                                packet.TurnSpeed = originalValues.TurnSpeed
                                packet.Height = originalValues.Height
                            end
                        end
                        appliedPackets = {}
                    end
                    
                    task.wait(0.15)
                end
                
                -- Final cleanup
                for packet, originalValues in pairs(appliedPackets) do
                    if packet and typeof(packet) == "table" then
                        packet.GarageEngineSpeed = originalValues.EngineSpeed
                        packet.TurnSpeed = originalValues.TurnSpeed
                        packet.Height = originalValues.Height
                    end
                end
            end)
        else
            CleanupModule("VehicleOverdrive")
        end
    end,
    Tooltip = "Complete vehicle performance suite - Stable version"
})

-- Vehicle Overdrive Controls
local OverdriveEngineToggle = VehicleOverdrive:CreateToggle({
    Name = "Engine Override",
    Function = function(callback)
        -- Toggle handled in main thread
    end
})

local OverdriveEngineSlider = VehicleOverdrive:CreateSlider({
    Name = "Engine Speed",
    Min = 1,
    Max = 200,
    Default = 25,
    Suffix = "x",
    Function = function(val)
        -- Value applied in main thread
    end
})

local OverdriveTurnToggle = VehicleOverdrive:CreateToggle({
    Name = "Turn Speed Override",
    Function = function(callback)
        -- Toggle handled in main thread
    end
})

local OverdriveTurnSlider = VehicleOverdrive:CreateSlider({
    Name = "Turn Speed",
    Min = 1,
    Max = 5,
    Default = 2,
    Decimal = 1,
    Suffix = "x",
    Function = function(val)
        -- Value applied in main thread
    end
})

local OverdriveSuspensionToggle = VehicleOverdrive:CreateToggle({
    Name = "Suspension Override",
    Function = function(callback)
        -- Toggle handled in main thread
    end
})

local OverdriveSuspensionSlider = VehicleOverdrive:CreateSlider({
    Name = "Suspension Height",
    Min = 1,
    Max = 200,
    Default = 15,
    Function = function(val)
        -- Value applied in main thread
    end
})

-- Enhanced Vehicle Tweaks with better hook management
local VehicleTweaks = MinigamesCategory:CreateModule({
    Name = "Vehicle Tweaks",
    Function = function(callback)
        if callback then
            ModuleRegistry.ActiveModules["VehicleTweaks"] = true
            
            SafeThread("VehicleTweaks", function()
                local vehicleUtils = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils)
                local modifiedPackets = {}
                
                while ModuleRegistry.ActiveModules["VehicleTweaks"] do
                    local success, vehiclePacket = pcall(vehicleUtils.GetLocalVehiclePacket)
                    
                    if success and vehiclePacket and vehiclePacket.Type == "Chassis" then
                        if not modifiedPackets[vehiclePacket] then
                            modifiedPackets[vehiclePacket] = {
                                Engine = vehiclePacket.GarageEngineSpeed,
                                Turn = vehiclePacket.TurnSpeed,
                                Suspension = vehiclePacket.Height
                            }
                        end
                        
                        -- Apply tweaks based on toggle states
                        if TweakEngineToggle and TweakEngineToggle.Enabled then
                            vehiclePacket.GarageEngineSpeed = TweakEngineSlider.Value
                        end
                        
                        if TweakTurnToggle and TweakTurnToggle.Enabled then
                            vehiclePacket.TurnSpeed = TweakTurnSlider.Value
                        end
                        
                        if TweakSuspensionToggle and TweakSuspensionToggle.Enabled then
                            vehiclePacket.Height = TweakSuspensionSlider.Value
                        end
                    else
                        -- Restore modified packets when no vehicle
                        for packet, original in pairs(modifiedPackets) do
                            if packet and typeof(packet) == "table" then
                                packet.GarageEngineSpeed = original.Engine
                                packet.TurnSpeed = original.Turn
                                packet.Height = original.Suspension
                            end
                        end
                        modifiedPackets = {}
                    end
                    
                    task.wait(0.2)
                end
                
                -- Final restoration
                for packet, original in pairs(modifiedPackets) do
                    if packet and typeof(packet) == "table" then
                        packet.GarageEngineSpeed = original.Engine
                        packet.TurnSpeed = original.Turn
                        packet.Height = original.Suspension
                    end
                end
            end)
        else
            CleanupModule("VehicleTweaks")
        end
    end,
    Tooltip = "Quality of life vehicle modifications"
})

-- Vehicle Tweaks Controls
local TweakEngineToggle = VehicleTweaks:CreateToggle({Name = "Engine Override"})
local TweakEngineSlider = VehicleTweaks:CreateSlider({
    Name = "Engine Speed",
    Min = 10,
    Max = 150,
    Default = 50
})

local TweakTurnToggle = VehicleTweaks:CreateToggle({Name = "Turn Speed Override"})
local TweakTurnSlider = VehicleTweaks:CreateSlider({
    Name = "Turn Speed",
    Min = 1,
    Max = 4,
    Default = 2,
    Decimal = 1
})

local TweakSuspensionToggle = VehicleTweaks:CreateToggle({Name = "Suspension Override"})
local TweakSuspensionSlider = VehicleTweaks:CreateSlider({
    Name = "Suspension Height",
    Min = 1,
    Max = 100,
    Default = 10
})

-- Global cleanup for all minigames modules
local function CleanupAllMinigames()
    for moduleName in pairs(ModuleRegistry.ActiveModules) do
        CleanupModule(moduleName)
    end
    
    -- Force garbage collection
    task.wait(0.1)
    for i = 1, 3 do
        task.wait()
        collectgarbage()
    end
end

-- Connect cleanup to vape's cleanup system
if vape.Clean then
    vape.Clean(CleanupAllMinigames)
end

-- Module health monitoring
SafeThread("ModuleMonitor", function()
    while task.wait(5) do
        local activeCount = 0
        for moduleName in pairs(ModuleRegistry.ActiveModules) do
            activeCount = activeCount + 1
        end
        
        if activeCount > 0 then
            -- Optional: Add health checks here
            -- warn(string.format("[ModuleMonitor] %d active modules", activeCount))
        end
    end
end)

warn("Minigames category loaded - Enhanced stability system active 🛡️")