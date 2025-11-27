local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert') end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		-- read commit (if available) and build URL
		local commit
		pcall(function() commit = readfile('newvape/profiles/commit.txt') end)
		local subpath = select(1, path:gsub('newvape/', ''))
		local url = 'https://raw.githubusercontent.com/rubim1/VapeV4ForRoblox/' .. (commit or 'main') .. '/' .. subpath

		local suc, res = pcall(function() return game:HttpGet(url, true) end)

		-- If initial attempt returned 404 and commit wasn't 'main', try fallback to 'main' branch
		if (not suc or res == '404: Not Found') and commit and commit ~= 'main' then
			local fallbackUrl = 'https://raw.githubusercontent.com/rubim1/VapeV4ForRoblox/main/' .. subpath
			local suc2, res2 = pcall(function() return game:HttpGet(fallbackUrl, true) end)
			if suc2 and res2 and res2 ~= '404: Not Found' then
				suc = suc2
				res = res2
				url = fallbackUrl
			end
		end

		if not suc or res == '404: Not Found' then
			warn('downloadFile failed to fetch: ' .. url .. ' -> ' .. tostring(res))
			error(res)
		end

		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local tweenService = cloneref(game:GetService('TweenService'))
local teamsService = cloneref(game:GetService('Teams'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextService = cloneref(game:GetService('ContextActionService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local game, workspace, task = game, workspace, task
local require, getupvalue, setconstant, hookfunction = require, getupvalue, setconstant, hookfunction

-- Safe fallbacks for exploit-only functions to avoid crashes when unavailable
if not getgc then
	getgc = function() return {} end
end
if not getinfo then
	getinfo = function() return { name = '' } end
end

local vape = shared.vape
local entitylib = vape.Libraries.entity
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local vm = loadstring(downloadFile('newvape/libraries/vm.lua'), 'vm')()
local NITRO_UPDATE_INTERVAL = 0.1

local HookManager = {restoreCallbacks = {}}
local function wrapHook(label, handler, original, ...)
	local ok, result = pcall(handler, original, ...)
	if not ok then
		warn(('[Vape Hook:%s] %s'):format(label or 'unknown', result))
		return original(...)
	end
	return result
end

function HookManager:hookFunction(target, handler, label)
	if typeof(target) ~= 'function' then return end
	local original
	original = hookfunction(target, function(...)
		return wrapHook(label, handler, original, ...)
	end)
	local function restore()
		hookfunction(target, original)
	end
	table.insert(self.restoreCallbacks, restore)
	return original, restore
end

function HookManager:hookMethod(object, method, handler, label)
	if not object or type(object[method]) ~= 'function' then return end
	local original = object[method]
	object[method] = function(...)
		return wrapHook(label, handler, original, ...)
	end
	local function restore()
		object[method] = original
	end
	table.insert(self.restoreCallbacks, restore)
	return original, restore
end

function HookManager:restoreAll()
	for i = #self.restoreCallbacks, 1, -1 do
		pcall(self.restoreCallbacks[i])
	end
	table.clear(self.restoreCallbacks)
end

local function safeCall(label, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		warn(('[Vape:%s] %s'):format(label, result))
		if vape and vape.CreateNotification then
			pcall(vape.CreateNotification, vape, 'Vape', label .. ' failed', 10, 'alert')
		end
		return nil
	end
	return result
end

local client = {}
do
	local ok, mod

	ok, mod = pcall(function() return require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils) end)
	client.vclasses = ok and (mod.Classes or {}) or {}

	ok, mod = pcall(function() return require(game:GetService("ReplicatedStorage").Module.AlexChassis2) end)
	client.alexchassis2 = ok and mod or nil

	ok, mod = pcall(function() return require(game:GetService("ReplicatedStorage").Tank.TankBinder) end)
	client.tankbinder = ok and (mod._constructor or nil) or nil
end

local originalHeliUpdate
local originalVoltUpdate
local originalMotorbikeSpeedConstant
local originalTankEngineConstant
local jb = {}
local InfNitro = {Enabled = false}
local LazerGodmode = {Enabled = false}
local minigamesCategory = (vape.Categories and (vape.Categories.Minigames or vape.Categories.Utility)) or vape.Categories.Utility

local function getVehicle(ent)
	if ent.Player then
		for _, car in collectionService:GetTagged('Vehicle') do
			for _, seat in car:GetChildren() do
				if (seat.Name == 'Seat' or seat.Name == 'Passenger') then
					seat = seat:FindFirstChild('PlayerName')
					if seat and seat.Value == ent.Player.Name then
						return car
					end
				end
			end
		end
	end
end

local function isArrested(name)
	for i, v in jb.CircleAction.Specs do
		if v.Name == 'Arrest' and v.PlayerName == name then
			return not v.ShouldArrest
		end
	end
	return false
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isIllegal(ent)
	if ent.Player and ent.Player.Team == teamsService.Prisoner then
		local items = ent.Player:FindFirstChild('CurrentInventory')
		items = items and items.Value
		if items then
			for i, v in items:GetChildren() do
				if v.Name ~= 'MansionInvite' then
					return true
				end
			end
		end

		return ent.Illegal
	end
	return true
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			},
			{
				Connect = function()
					return hum:GetPropertyChangedSignal('Sit'):Connect(function()
						if getVehicle(ent) then
							ent.Illegal = true
						end
					end)
				end
			}
		}
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then return ent:TeamCheck() end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		if lplr.Team == teamsService.Police then
			return ent.Player.Team ~= teamsService.Police
		else
			return ent.Player.Team == teamsService.Police
		end
		return true
	end
end)
entitylib.start()

run(function()
	local function dumpRemotes(scripts, renamed)
		local returned = {}

		for _, scr in scripts do
			local deserializedcode = vm.luau_deserialize(getscriptbytecode(scr))

			for _, proto in deserializedcode.protoList do
				local stack, top, code = {}, -1, proto.code
				for i, inst in code do
					if inst.opcode == 4 then -- LOADN
						stack[inst.A] = inst.D
					elseif inst.opcode == 5 then -- LOADK
						stack[inst.A] = inst.K
					elseif inst.opcode == 6 then -- MOVE
						stack[inst.A] = stack[inst.B]
					elseif inst.opcode == 12 then -- GETIMPORT
						local count, import = inst.KC, getrenv()[inst.K0]

						if count == 1 then
							stack[inst.A] = import
						elseif count == 2 then
							stack[inst.A] = import[inst.K1]
						elseif count == 3 then
							stack[inst.A] = import[inst.K1][inst.K2]
						end
					elseif inst.opcode == 20 then -- NAMECALL
						local A, B, kv = inst.A, inst.B, inst.K
						stack[A + 1] = stack[B]

						local callInst = code[i + 2]
						local callA, callB, callC = callInst.A, callInst.B, callInst.C
						local params = if callB == 0 then top - callA else callB - 1
						if kv == 'sub' or kv == 'reverse' then
							local arg1, arg2, arg3 = table.unpack(stack, callA + 1, callA + params)
							if kv == 'reverse' and not arg1 then arg1 = 'a' end

							local ret_list = table.pack(string[kv](arg1, arg2, arg3))
							local ret_num = ret_list.n - 1
							if callC == 0 then
								top = callA + ret_num - 1
							else
								ret_num = callC - 1
							end

							table.move(ret_list, 1, ret_num, callA, stack)
						elseif kv == 'FireServer' then
							local name, val = proto.debugname == '(??)' and scr.Name or proto.debugname, stack[callA + 2]
							if name == val then table.insert(returned, val) continue end
							if returned[name] then
								for i = 1, 10 do
									if not returned[name..i] then name ..= i break end
								end
							end

							returned[name] = val
						end
					elseif inst.opcode == 49 then -- CONCAT
						local s = ""
						for i = inst.B, inst.C do
							if type(stack[i]) ~= 'string' then continue end
							s ..= stack[i]
						end
						stack[inst.A] = s
					end
				end
			end
		end

		for i, v in table.clone(returned) do
			if renamed[i] then
				returned[i] = nil
				returned[renamed[i]] = v
			end
		end

		return returned
	end

	local function getCash()
		for i, v in debug.getupvalue(jb.TeamChooseController.Init, 2) do
			if type(v) == 'function' then
				for _, const in debug.getconstants(v) do
					if tostring(const):find('PlusCash') then
						return v, i
					end
				end
			end
		end
	end

	local function toMoney(num)
		local one, two, three = string.match(tostring(num), '^([^%d]*%d)(%d*)(.-)$')
		return one .. (two:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. three)..'$'
	end

	jb = {
		BulletEmitter = require(replicatedStorage.Game.ItemSystem.BulletEmitter),
		CircleAction = require(replicatedStorage.Module.UI).CircleAction,
		CargoController = require(replicatedStorage.Game.Robbery.RobberyPassengerTrain),
		FallingController = require(replicatedStorage.Game.Falling),
		GunController = require(replicatedStorage.Game.Item.Gun),
		HotbarItemSystem = require(replicatedStorage.Hotbar.HotbarItemSystem),
		InventoryItemSystem = require(replicatedStorage.Inventory.InventoryItemSystem),
		ItemSystemController = require(replicatedStorage.Game.ItemSystem.ItemSystem),
		PlayerUtils = require(replicatedStorage.Game.PlayerUtils),
		RagdollController = require(replicatedStorage.Module.AlexRagdoll),
		TaserController = require(replicatedStorage.Game.Item.Taser),
		TeamChooseController = require(replicatedStorage.TeamSelect.TeamChooseUI),
		VehicleController = require(replicatedStorage.Vehicle.VehicleUtils)
	}

	if not jb.VehicleController.toggleLocalLocked or not jb.VehicleController.NitroShopVisible then
		repeat task.wait() until (jb.VehicleController.toggleLocalLocked and jb.VehicleController.NitroShopVisible) or vape.Loaded == nil
		if vape.Loaded == nil then return end
	end
	local remotetable = debug.getupvalue(jb.VehicleController.toggleLocalLocked, 2)
	local fireserver = remotetable.FireServer
	local fireServerOriginal

	remotes = dumpRemotes({
		replicatedStorage.Game.TrainSystem.LocomotiveFront,
		replicatedStorage.Game.ItemSystem.ItemSystem,
		replicatedStorage.Game.CashBuyUI,
		replicatedStorage.Game.Item.Taser,
		replicatedStorage.Game.Item.Gun,
		replicatedStorage.Game.Falling,
		lplr.PlayerScripts.LocalScript
	}, {
		Action = 'Pickup',
		Action3 = 'StartRob',
		Action2 = 'EndRob',
		AttemptArrest = 'Arrest',
		attemptPunch = 'Punch',
		AttemptVehicleEject = 'Eject',
		AttemptVehicleEnter = 'GetIn',
		BroadcastInputBegan = 'InputBegan',
		BroadcastInputEnded = 'InputEnded',
		CalculateDelta = 'UseNitro',
		Draw = 'TaseReplicate',
		Gun = 'PopTires',
		LocalScript2 = 'LookAngle',
		LocalScript = 'SelfDamage',
		onPressed = 'FlipVehicle',
		OnJump = 'GetOut',
		OnJump1 = 'GetOut',
		UpdateMousePosition = 'AimPosition'
	})

	local function fireHook(original, self, id, ...)
		local rem
		for i, v in remotes do
			if v == id then
				rem = i
			end
		end

		if InfNitro.Enabled and rem == 'UseNitro' then return end
		if LazerGodmode.Enabled and rem == 'SelfDamage' then return end
		if rem ~= 'LookAngle' and rem ~= 'AimPosition' then
			local called = getfenv(3)
			called = called and called.script
			if called and (not rem) then print(id, 'called with', called:GetFullName()) end
			print(id, rem or id, ...)
		end

		return original(self, id, ...)
	end

	fireServerOriginal = HookManager:hookFunction(fireserver, function(original, self, id, ...)
		return fireHook(original, self, id, ...)
	end, 'VehicleFireServer')

	function jb:FireServer(id, ...)
		if not remotes[id] then
			notif('Vape', 'Failed to find remote ('..id..')', 10, 'alert')
			return
		end
		return fireServerOriginal(remotetable, remotes[id], ...)
	end

	local arrests = sessioninfo:AddItem('Arrested')
	local moneymade = sessioninfo:AddItem('Money Made', 0, toMoney, true)
	local bounty = sessioninfo:AddItem('Bounty List', '', function()
		local text, tab = '', workspace.MostWanted:FindFirstChild('Board', true)
		tab = tab and tab:GetChildren() or {}

		for i, v in tab do
			if v:IsA('Frame') then
				local plrname = v:FindFirstChild('PlayerName', true)
				local bounty = v:FindFirstChild('Bounty', true)
				if plrname and bounty then
					text = text..'\n'..(plrname.Text..': '..bounty.Text:gsub(' Bounty', ''))
				end
			end
		end

		return text
	end, false)

	local cashfunc, cashRestore
	if cashfunc then
		_, cashRestore = HookManager:hookFunction(cashfunc, function(original, amount, text, ...)
			moneymade:Increment(amount)
			if text == 'Arrest' then
				arrests:Increment()
			end
			return original(amount, text, ...)
		end, 'CashHook')
	end

	vape:Clean(function()
		isNitroLoopRunning = false
		table.clear(remotes)
		table.clear(jb)
		HookManager:restoreAll()
	end)
end)

for _, v in {'Reach', 'TriggerBot', 'Disabler', 'AntiFall', 'HitBoxes', 'Killaura', 'MurderMystery'} do
	vape:Remove(v)
end
run(function()
	local SilentAim
	local Target
	local Mode
	local Range
	local HitChance
	local HeadshotChance
	local CircleColor
	local CircleTransparency
	local CircleFilled
	local CircleObject
	local Instant
	local Hooked
	local ProjectileRaycast = RaycastParams.new()
	ProjectileRaycast.RespectCanCollide = true
	
	SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			if CircleObject then
				CircleObject.Visible = callback and Mode.Value == 'Mouse'
			end
			if callback then
				Hooked = jb.GunController.TransformLocalMousePosition
				jb.GunController.TransformLocalMousePosition = function(self, pos)
					local ent = entitylib['Entity'..Mode.Value]({
						Range = Range.Value,
						Wallcheck = Target.Walls.Enabled and (obj or true) or nil,
						Part = 'RootPart',
						Origin = entitylib.isAlive and entitylib.character.RootPart.Position or nil,
						Players = Target.Players.Enabled,
						NPCs = Target.NPCs.Enabled
					})
	
					if ent then
						local item = jb.ItemSystemController:GetLocalEquipped()
						if item and ((self.Tip.CFrame.Position - ent.RootPart.Position).Magnitude / (item.Config.BulletSpeed or 1000)) < item.BulletEmitter.LifeSpan then
							ProjectileRaycast.FilterDescendantsInstances = {gameCamera, ent.Character}
							ProjectileRaycast.CollisionGroup = ent.RootPart.CollisionGroup
							local calc = prediction.SolveTrajectory(self.Tip.CFrame.Position, item.Config.BulletSpeed or 1000, math.abs(item.BulletEmitter.GravityVector.Y), ent.RootPart.Position, Instant.Enabled and Vector3.zero or ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
							if calc then
								targetinfo.Targets[ent] = tick() + 1
								return calc
							end
						end
					end
	
					return pos
				end
	
				repeat
					if CircleObject then 
						CircleObject.Position = inputService:GetMouseLocation() 
					end
	
					if Instant.Enabled then 
						local item = jb.ItemSystemController:GetLocalEquipped()
						if item and item.BulletEmitter then
							rawset(item.BulletEmitter, 'LastUpdate', tick() - (item.BulletEmitter.LifeSpan - 0.1))
						end
					end
					task.wait()
				until not SilentAim.Enabled
			else
				jb.GunController.TransformLocalMousePosition = Hooked
			end
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Target = SilentAim:CreateTargets({Players = true})
	Mode = SilentAim:CreateDropdown({
		Name = 'Mode',
		List = {'Mouse', 'Position'},
		Function = function(val)
			if CircleObject then
				CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
			end
		end,
		Tooltip = 'Mouse - Checks for entities near the mouses position\nPosition - Checks for entities near the local character'
	})
	Range = SilentAim:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 1000,
		Default = 150,
		Function = function(val)
			if CircleObject then
				CircleObject.Radius = val
			end
		end,
		Suffix = function(val) 
			return val == 1 and 'stud' or 'studs' 
		end
	})
	SilentAim:CreateToggle({
		Name = 'Range Circle',
		Function = function(callback)
			if callback then
				CircleObject = Drawing.new('Circle')
				CircleObject.Filled = CircleFilled.Enabled
				CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
				CircleObject.Position = vape.gui.AbsoluteSize / 2
				CircleObject.Radius = Range.Value
				CircleObject.NumSides = 100
				CircleObject.Transparency = 1 - CircleTransparency.Value
				CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
			else
				pcall(function()
					CircleObject.Visible = false
					CircleObject:Remove()
				end)
			end
			CircleColor.Object.Visible = callback
			CircleTransparency.Object.Visible = callback
			CircleFilled.Object.Visible = callback
		end
	})
	CircleColor = SilentAim:CreateColorSlider({
		Name = 'Circle Color', 
		Function = function(hue, sat, val)
			if CircleObject then
				CircleObject.Color = Color3.fromHSV(hue, sat, val)
			end
		end, 
		Darker = true, 
		Visible = false
	})
	CircleTransparency = SilentAim:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.5,
		Function = function(val)
			if CircleObject then
				CircleObject.Transparency = 1 - val
			end
		end,
		Darker = true,
		Visible = false
	})
	CircleFilled = SilentAim:CreateToggle({
		Name = 'Circle Filled', 
		Function = function(callback)
			if CircleObject then
				CircleObject.Filled = callback
			end
		end, 
		Darker = true, 
		Visible = false
	})
	Instant = SilentAim:CreateToggle({Name = 'Hitscan Bullets'})
end)
	
run(function()
	local Wallbang = {Enabled = false}
	local wallbangRestore
	
	Wallbang = vape.Categories.Combat:CreateModule({
		Name = 'Wallbang',
		Function = function(callback)
			if callback then
				if not wallbangRestore then
					_, wallbangRestore = HookManager:hookMethod(jb.GunController, 'BulletEmitterOnLocalHitPlayer', function(original, ...)
						local shotData = select(15, ...)
						shotData.isWallbang = nil
						shotData.isHeadshot = true
						return original(...)
					end, 'WallbangHook')
				end
	
				repeat
					local item = jb.ItemSystemController:GetLocalEquipped()
					if item and item.BulletEmitter then
						item.BulletEmitter.IgnoreList = {workspace}
					end
					task.wait(0.1)
				until not Wallbang.Enabled
			else
				if wallbangRestore then
					wallbangRestore()
					wallbangRestore = nil
				end
			end
		end,
		Tooltip = 'Modifies bullets to always do headshot damage & shooting through most walls.'
	})
end)
	
run(function()
	local AutoArrest = {Enabled = false}
	
	AutoArrest = vape.Categories.Blatant:CreateModule({
		Name = 'AutoArrest',
		Function = function(callback)
			if callback then
				repeat
					local item = jb.ItemSystemController:GetLocalEquipped()
					if item and item.__ClassName == 'Handcuffs' then
						local localPosition = entitylib.character.Humanoid.HumanoidUnloadServerPosition.Value
						local plrs = entitylib.AllPosition({
							Players = true,
							Part = 'RootPart',
							Range = 50
						})
	
						for _, ent in plrs do
							if not AutoArrest.Enabled then break end
							if ent.Player and isIllegal(ent) then
								local vehicle = ent.Humanoid.Sit and getVehicle(ent) or nil
								if vehicle then
									jb:FireServer('Eject', vehicle)
								elseif not isArrested(ent.Player.Name) and (localPosition - ent.RootPart.Position).Magnitude < 18.4 then
									jb:FireServer('Arrest', ent.Player.Name)
									task.wait(0.6)
								end
							end
						end
					end
					task.wait(0.016)
				until not AutoArrest.Enabled
			end
		end,
		Tooltip = 'Automatically uses handcuffs on nearby entities'
	})
end)
	
run(function()
	local AutoPop
	local Range
	local HandCheck
	local TeamCheck
	
	local function getEntitiesInVehicle(car)
		local entities = {}
	
		for _, seat in car:GetChildren() do
			if (seat.Name == 'Seat' or seat.Name == 'Passenger') then
				seat = seat:FindFirstChild('PlayerName')
				if seat then
					for _, ent in entitylib.List do
						if ent.Player and ent.Player.Name == seat.Value then
							table.insert(entities, ent)
						end
					end
				end
			end
		end
	
		return entities
	end
	
	local function getVehiclesNear()
		local allowed = {}
	
		if entitylib.isAlive then
			local localPosition = entitylib.character.HumanoidRootPart.Position
			for _, car in collectionService:GetTagged('Vehicle') do
				if car.PrimaryPart and (car.PrimaryPart.Position - localPosition).Magnitude <= Range.Value then
					local entities = getEntitiesInVehicle(car)
					local check = #entities > 0
					if TeamCheck.Enabled then
						for _, ent in entities do
							if not ent.Targetable then 
								check = false 
								break 
							end
						end
					end
					
					if check then 
						table.insert(allowed, car) 
					end
				end
			end
		end
	
		return allowed
	end
	
	AutoPop = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPop',
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						local item = jb.ItemSystemController:GetLocalEquipped()
						if (not HandCheck.Enabled) or item and item.BulletEmitter then
							for _, car in getVehiclesNear() do
								if not AutoPop.Enabled then break end
								jb:FireServer('PopTires', car, 'Sniper')
								task.wait(0.1)
							end
						end
						task.wait(0.016)
					until not AutoPop.Enabled
				end)
			end
		end,
		Tooltip = 'Automatically pops vehicles tires around you'
	})
	Range = AutoPop:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 600,
		Default = 600
	})
	HandCheck = AutoPop:CreateToggle({Name = 'Hand Check'})
	TeamCheck = AutoPop:CreateToggle({Name = 'Team Check'})
end)
	
run(function()
	local Punch = {Enabled = false}
	
	Punch = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPunch',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive then 
						jb:FireServer('Punch') 
					end
					task.wait(0.3)
				until not Punch.Enabled
			end
		end,
		Tooltip = 'Always punches people infront of you'
	})
end)
	
run(function()
	local AutoTaze = {Enabled = false}
	local AutoTazeHandCheck = {Enabled = false}
	
	AutoTaze = vape.Categories.Blatant:CreateModule({
		Name = 'AutoTaze',
		Function = function(callback)
			if callback then
				repeat
					local item = jb.ItemSystemController:GetLocalEquipped()
					item = item and item.__ClassName == 'Taser' or nil
					if not AutoTazeHandCheck.Enabled or item then
						local ent = entitylib.EntityPosition({
							Players = true,
							Part = 'RootPart',
							Range = 50
						})
	
						if ent and isIllegal(ent) and not isArrested(ent.Player.Name) then
							if item then 
								jb:FireServer('TaseReplicate', ent.Head.Position) 
							end
							jb:FireServer('Tase', ent.Humanoid, ent.Head, ent.Head.Position)
							task.wait(10)
						end
					end
					task.wait(0.016)
				until not AutoTaze.Enabled
			end
		end,
		Tooltip = 'Immobilizes entities around you'
	})
	AutoTazeHandCheck = AutoTaze:CreateToggle({Name = 'Hand Check'})
end)
	
run(function()
	LazerGodmode = vape.Categories.Blatant:CreateModule({Name = 'LazerGodmode'})
end)
	
run(function()
	vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			debug.setconstant(debug.getupvalue(jb.FallingController.Init, 19), 9, callback and 'Archivable' or 'Sit')
		end,
		Tooltip = 'Disables ragdoll handling & fall damage'
	})
end)
	
run(function()
	local nitrotable = debug.getupvalue(jb.VehicleController.NitroShopVisible, 1)
	local oldnitro
	
	InfNitro = vape.Categories.Utility:CreateModule({
		Name = 'InfiniteNitro',
		Function = function(callback)
			if callback then
				oldnitro = nitrotable.Nitro
				jb.VehicleController.updateSpdBarRatio(1)
				repeat
					nitrotable.Nitro = 250
					task.wait(0.1)
				until not InfNitro.Enabled
			else
				nitrotable.Nitro = oldnitro
				jb.VehicleController.updateSpdBarRatio(oldnitro / 250)
			end
		end,
		Tooltip = 'Infinite boost for the local car'
	})
end)
	
run(function()
	vape.Categories.Utility:CreateModule({
		Name = 'InstantAction',
		Function = function(callback)
			debug.setconstant(jb.CircleAction.Press, 3, callback and 'Timeda' or 'Timed')
		end,
		Tooltip = 'Allows you to instantly complete ProximityPrompt actions'
	})
end)
	
run(function()
	local keySpoofRestore
	vape.Categories.Utility:CreateModule({
		Name = 'KeySpoofer',
		Function = function(callback)
			if callback then
				if not keySpoofRestore then
					_, keySpoofRestore = HookManager:hookMethod(jb.PlayerUtils, 'hasKey', function()
						return true
					end, 'KeySpoofer')
				end
			else
				if keySpoofRestore then
					keySpoofRestore()
					keySpoofRestore = nil
				end
			end
		end,
		Tooltip = 'Enables most doors to be walked through'
	})
end)

-- Variabel untuk mengontrol loop dari luar fungsi toggle
local isNitroLoopRunning = false
local InfiniteNitro

run(function()
	InfiniteNitro = minigamesCategory:CreateModule({
		Name = 'Infinite Nitro',
			Function = function(callback)
				if callback then
				isNitroLoopRunning = true
				local nitroStateTable

				-- Avoid scanning the garbage collector (exploit-only, crash-prone).
				-- Prefer known upvalues from the VehicleController when available.
				pcall(function()
					nitroStateTable = debug.getupvalue(jb.VehicleController and jb.VehicleController.NitroShopVisible or nil, 1)
				end)

				if nitroStateTable then
					task.spawn(function()
						repeat
							nitroStateTable.NitroLastMax = 250
							nitroStateTable.Nitro = 249
							nitroStateTable.NitroForceUIUpdate = true
							task.wait(NITRO_UPDATE_INTERVAL)
						until not isNitroLoopRunning
					end)
				else
					warn('[Vape Infinite Nitro] failed to locate nitro state table')
					isNitroLoopRunning = false
				end
			else
				isNitroLoopRunning = false
				end
			end,
		Tooltip = 'Memberikan nitro tak terbatas pada semua kendaraan.'
		})
end)

-- Vehicle Suite (unified override system)
local VehicleSuite
local suiteState = {
	originals = {},
	inVehicle = false,
	lastPacket = nil,
	currentPacket = nil,
	currentModel = nil,
	monitorThread = nil,
	charConn = nil,
	seatConn = nil,
	vehicleEnteredConn = nil,
	vehicleExitedConn = nil,
	hijackThread = nil,
	autoReseatCooling = false
}
local carControls, heliControls, voltControls = {}, {}, {}
local bikeControls, tankControls, utilityControls = {}, {}, {}
local heliHooked
local voltHooked
local towingHooked
local ActionButtonService = require(replicatedStorage.ActionButton.ActionButtonService)

local function sliderValue(slider, min, max, default)
	local value = slider and slider.Value or default or min or 0
	if min and max then
		return math.clamp(value, min, max)
	end
	return value
end

local function getSeatedModel()
	local character = lplr.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local seat = humanoid and humanoid.SeatPart
	return seat and seat.Parent or nil
end

local CAR_ENGINE_MIN, CAR_ENGINE_MAX, CAR_ENGINE_DEFAULT = 1, 200, 10
local CAR_TURN_MIN, CAR_TURN_MAX, CAR_TURN_DEFAULT = 1, 5, 1
local CAR_SUSPENSION_MIN, CAR_SUSPENSION_MAX, CAR_SUSPENSION_DEFAULT = 1, 200, 10
local HELI_FORWARD_MIN, HELI_FORWARD_MAX, HELI_FORWARD_DEFAULT = 10, 500, 100
local HELI_VERTICAL_MIN, HELI_VERTICAL_MAX, HELI_VERTICAL_DEFAULT = 10, 300, 100
local HELI_TURN_MIN, HELI_TURN_MAX, HELI_TURN_DEFAULT = 10, 500, 100
local VOLT_MIN, VOLT_MAX, VOLT_DEFAULT = 0, 25, 0
local MOTORBIKE_MIN, MOTORBIKE_MAX, MOTORBIKE_DEFAULT = 0, 100, 0
local TANK_MIN, TANK_MAX, TANK_DEFAULT = 1, 500, 10
local HELI_HEIGHT_CAP = 9e9

local function getVehiclePacket()
	return safeCall('VehiclePacket', function()
		return require(game:GetService('ReplicatedStorage').Vehicle.VehicleUtils).GetLocalVehiclePacket()
	end)
end

local function ensureSnapshot(packet, ...)
	if not packet or not packet.Model then return end
	local snapshot = suiteState.originals[packet.Model]
	if not snapshot then
		snapshot = {}
		suiteState.originals[packet.Model] = snapshot
	end
	for _, field in {...} do
		if field and snapshot[field] == nil then
			snapshot[field] = packet[field]
		end
	end
	return snapshot
end

local function restoreSnapshot(packet)
	if not packet or not packet.Model then return end
	local snapshot = suiteState.originals[packet.Model]
	if not snapshot then return end
	for field, value in snapshot do
		if type(field) == 'string' then
			packet[field] = value
		end
	end
	suiteState.originals[packet.Model] = nil
end

local function clearSnapshots()
	local packet = suiteState.currentPacket or suiteState.lastPacket
	if packet then
		restoreSnapshot(packet)
	end
	suiteState.lastPacket = nil
	suiteState.currentPacket = nil
	suiteState.currentModel = nil
	table.clear(suiteState.originals)
end

local function applyCarOverrides(packet)
	local snapshot = ensureSnapshot(packet, 'GarageEngineSpeed', 'TurnSpeed', 'Height')
	if not snapshot then return end

	if carControls.engine.Enabled then
		packet.GarageEngineSpeed = sliderValue(carControls.engineSlider, CAR_ENGINE_MIN, CAR_ENGINE_MAX, CAR_ENGINE_DEFAULT)
	else
		packet.GarageEngineSpeed = snapshot.GarageEngineSpeed
	end

	if carControls.turn.Enabled then
		packet.TurnSpeed = sliderValue(carControls.turnSlider, CAR_TURN_MIN, CAR_TURN_MAX, CAR_TURN_DEFAULT)
	else
		packet.TurnSpeed = snapshot.TurnSpeed
	end

	if carControls.suspension.Enabled then
		packet.Height = sliderValue(carControls.suspensionSlider, CAR_SUSPENSION_MIN, CAR_SUSPENSION_MAX, CAR_SUSPENSION_DEFAULT)
	else
		packet.Height = snapshot.Height
	end
end

local function applyHeliOverrides(packet)
	local snapshot = ensureSnapshot(packet, 'MaxHeight')
	if not snapshot then return end
	if heliControls.height.Enabled then
		packet.MaxHeight = HELI_HEIGHT_CAP
	else
		packet.MaxHeight = snapshot.MaxHeight
	end
end

local function refreshVehiclePacket(forceRestore)
	if not VehicleSuite or not VehicleSuite.Enabled then return end
	local packet = getVehiclePacket()
	local seatedModel = getSeatedModel()
	if not packet or not packet.Model then
		if forceRestore then
			clearSnapshots()
		else
			suiteState.inVehicle = false
			suiteState.currentPacket = nil
		end
		return
	end

	local targetModel = seatedModel or suiteState.currentModel
	if targetModel and packet.Model ~= targetModel then
		return
	end

	suiteState.inVehicle = true
	suiteState.lastPacket = packet
	suiteState.currentPacket = packet
	suiteState.currentModel = packet.Model

	if packet.Type == 'Chassis' then
		applyCarOverrides(packet)
	elseif packet.Type == 'Heli' then
		applyHeliOverrides(packet)
	else
		restoreSnapshot(packet)
	end
end

local function ensureMonitorThread()
	if suiteState.monitorThread then return end
	suiteState.monitorThread = task.spawn(function()
		while VehicleSuite and VehicleSuite.Enabled do
			refreshVehiclePacket()
			task.wait(0.05)
		end
		suiteState.monitorThread = nil
	end)
end

local function bindSeatListener(character)
	if suiteState.seatConn then
		suiteState.seatConn:Disconnect()
		suiteState.seatConn = nil
	end
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid', 5)
	if not humanoid then return end
	suiteState.seatConn = humanoid.Seated:Connect(function(isSeated, seat)
		if isSeated then
			suiteState.inVehicle = true
			suiteState.currentModel = seat and seat.Parent or getSeatedModel()
			refreshVehiclePacket(true)
		else
			suiteState.inVehicle = false
			clearSnapshots()
		end
	end)
end

local function ensureCharacterHooks()
	if suiteState.charConn then return end
	if lplr.Character then
		bindSeatListener(lplr.Character)
	end
	suiteState.charConn = lplr.CharacterAdded:Connect(bindSeatListener)
end

local function disconnectCharacterHooks()
	if suiteState.charConn then
		suiteState.charConn:Disconnect()
		suiteState.charConn = nil
	end
	if suiteState.seatConn then
		suiteState.seatConn:Disconnect()
		suiteState.seatConn = nil
	end
end

local function ensureVehicleSignals()
	local vehicleUtils = jb.VehicleController
	if not vehicleUtils then return end

	if not suiteState.vehicleEnteredConn and vehicleUtils.OnVehicleEntered then
		suiteState.vehicleEnteredConn = vehicleUtils.OnVehicleEntered:Connect(function(packet)
			suiteState.inVehicle = true
			suiteState.lastPacket = packet
			suiteState.currentPacket = packet
			suiteState.currentModel = packet and packet.Model or getSeatedModel()
			refreshVehiclePacket(true)
		end)
	end

	if not suiteState.vehicleExitedConn and vehicleUtils.OnVehicleExited then
		suiteState.vehicleExitedConn = vehicleUtils.OnVehicleExited:Connect(function()
			suiteState.inVehicle = false
			clearSnapshots()
		end)
	end
end

local function disconnectVehicleSignals()
	if suiteState.vehicleEnteredConn then
		suiteState.vehicleEnteredConn:Disconnect()
		suiteState.vehicleEnteredConn = nil
	end
	if suiteState.vehicleExitedConn then
		suiteState.vehicleExitedConn:Disconnect()
		suiteState.vehicleExitedConn = nil
	end
end

local function triggerAutoReseat()
	if suiteState.autoReseatCooling or not suiteState.inVehicle then return end
	local character = lplr.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local seat = humanoid and humanoid.SeatPart
	if not humanoid or not seat then return end

	suiteState.autoReseatCooling = true
	humanoid.Sit = false

	task.delay(0.05, function()
		if humanoid.Parent and seat.Parent then
			pcall(function()
				seat:Sit(humanoid)
			end)
		end
	end)

	task.delay(0.5, function()
		suiteState.autoReseatCooling = false
	end)
end

local function ensureHeliHook()
	if heliHooked or not client.vclasses or not client.vclasses.Heli then return end
	originalHeliUpdate = originalHeliUpdate or client.vclasses.Heli.Update
	client.vclasses.Heli.Update = function(self, ...)
		originalHeliUpdate(self, ...)
		if not (VehicleSuite and VehicleSuite.Enabled and heliControls.speed.Enabled) then return end
		local forwardMul = sliderValue(heliControls.forward, HELI_FORWARD_MIN, HELI_FORWARD_MAX, HELI_FORWARD_DEFAULT) / 100
		local verticalMul = sliderValue(heliControls.vertical, HELI_VERTICAL_MIN, HELI_VERTICAL_MAX, HELI_VERTICAL_DEFAULT) / 10
		local turnMul = sliderValue(heliControls.turn, HELI_TURN_MIN, HELI_TURN_MAX, HELI_TURN_DEFAULT) / 100
		-- Harden modifications with pcall to avoid nil/index errors if structure changes
		pcall(function()
			if self and self.Velocity and self.Velocity.Velocity then
				self.Velocity.Velocity = self.Velocity.Velocity * Vector3.new(forwardMul, verticalMul, forwardMul)
			end
			if self and self.Rotate and self.Rotate.AngularVelocity then
				self.Rotate.AngularVelocity = self.Rotate.AngularVelocity * turnMul
			end
		end)
	end
	heliHooked = true
end

local function releaseHeliHook()
	if not heliHooked or not originalHeliUpdate or not client.vclasses or not client.vclasses.Heli then return end
	client.vclasses.Heli.Update = originalHeliUpdate
	heliHooked = false
end

local function ensureVoltHook()
	if voltHooked or not client.vclasses or not client.vclasses.Volt then return end
	originalVoltUpdate = originalVoltUpdate or client.vclasses.Volt.Update
	client.vclasses.Volt.Update = function(self, ...)
		originalVoltUpdate(self, ...)
		if not (VehicleSuite and VehicleSuite.Enabled and voltControls.speed.Enabled) then return end
		local multiplier = sliderValue(voltControls.speedSlider, VOLT_MIN, VOLT_MAX, VOLT_DEFAULT)
		self.Force.Force = self.Force.Force * (1 + multiplier)
	end
	voltHooked = true
end

local function releaseVoltHook()
	if not voltHooked or not originalVoltUpdate or not client.vclasses or not client.vclasses.Volt then return end
	client.vclasses.Volt.Update = originalVoltUpdate
	voltHooked = false
end

local function updateMotorbikeConstant(forceRestore)
	if not client.alexchassis2 or not client.alexchassis2.UpdateHQ then return end
		if not forceRestore and VehicleSuite and VehicleSuite.Enabled and bikeControls.speed.Enabled then
			if not originalMotorbikeSpeedConstant then
				originalMotorbikeSpeedConstant = getconstant(client.alexchassis2.UpdateHQ, 76)
			end
			local value = sliderValue(bikeControls.speedSlider, MOTORBIKE_MIN, MOTORBIKE_MAX, MOTORBIKE_DEFAULT)
			-- Disabled direct constant patching to avoid client instability/crashes
			-- setconstant(client.alexchassis2.UpdateHQ, 76, 1.2 + value)
		elseif originalMotorbikeSpeedConstant then
			-- setconstant(client.alexchassis2.UpdateHQ, 76, originalMotorbikeSpeedConstant)
			originalMotorbikeSpeedConstant = nil
		end
	end
end

local function updateTankConstant(forceRestore)
	if not client.tankbinder or not client.tankbinder._handleSeatedDriver then return end
	local proto = getproto(client.tankbinder._handleSeatedDriver, 4)
	if not forceRestore and VehicleSuite and VehicleSuite.Enabled and tankControls.speed.Enabled then
		if not originalTankEngineConstant then
			originalTankEngineConstant = getconstant(proto, 20)
		end
		local value = sliderValue(tankControls.speedSlider, TANK_MIN, TANK_MAX, TANK_DEFAULT)
		-- Disabled direct constant patching to avoid client instability/crashes
		-- setconstant(proto, 20, value)
	elseif originalTankEngineConstant then
		-- setconstant(proto, 20, originalTankEngineConstant)
		originalTankEngineConstant = nil
	end
end

local function applyTowHook()
	if towingHooked then return end
	local binder = require(game:GetService('ReplicatedStorage').VehicleLink.VehicleLinkBinder)
	local constructor = binder._constructor
	if not constructor or not constructor._hookNearest then return end

	local original = constructor._hookNearest
	towingHooked = original

	constructor._hookNearest = function(...)
		local args = {...}
		local data = args[1]
		if data and data.obj and data.nearestObj then
			local ropeName = data.obj.Name
			local isTow = utilityControls.tow.Enabled and ropeName == 'MetalHook'
			local isHeli = utilityControls.heliPickup.Enabled and ropeName == 'RopePull'
			if isTow or isHeli then
				local geom = require(game:GetService('ReplicatedStorage'):WaitForChild('Std'):WaitForChild('GeomUtils'))
				local closest = geom.closestPointInPart(data.nearestObj.PrimaryPart, data.obj.Position)
				local offset = data.nearestObj.PrimaryPart.CFrame:PointToObjectSpace(closest)
				data.manifest.reqLinkRemote:FireServer(data.nearestObj, offset)
				return
			end
		end
		return original(...)
	end
end

local function restoreTowHook(force)
	if not towingHooked then return end
	if not force then
		if utilityControls.tow.Enabled then return end
		if utilityControls.heliPickup.Enabled then return end
	end
	local binder = require(game:GetService('ReplicatedStorage').VehicleLink.VehicleLinkBinder)
	local constructor = binder._constructor
	constructor._hookNearest = towingHooked
	towingHooked = nil
end

local function syncTowHook(forceRestore)
	if VehicleSuite and VehicleSuite.Enabled and (utilityControls.tow.Enabled or utilityControls.heliPickup.Enabled) then
		applyTowHook()
	else
		restoreTowHook(forceRestore)
	end
end

local function runHijackLoop()
	if suiteState.hijackThread or not (VehicleSuite and VehicleSuite.Enabled and utilityControls.hijack.Enabled) then return end
	suiteState.hijackThread = task.spawn(function()
		while VehicleSuite and VehicleSuite.Enabled and utilityControls.hijack.Enabled do
			task.wait(0.1)
			for _, action in ActionButtonService.active do
				if action.Name == 'Hijack' and table.find(action.keyCodes, Enum.KeyCode.V) then
					action.onPressed(true)
				end
			end
		end
		suiteState.hijackThread = nil
	end)
end

local function reapplyCarStats(withReseat)
	if not (VehicleSuite and VehicleSuite.Enabled) then return end
	refreshVehiclePacket(true)
	if withReseat then
		triggerAutoReseat()
	end
end

VehicleSuite = minigamesCategory:CreateModule({
	Name = 'VehicleSuite',
	Function = function(state)
		if state then
			ensureCharacterHooks()
			ensureVehicleSignals()
			ensureMonitorThread()
			ensureHeliHook()
			ensureVoltHook()
			updateMotorbikeConstant()
			updateTankConstant()
			syncTowHook()
			if utilityControls.hijack.Enabled then
				runHijackLoop()
			end
		refreshVehiclePacket(true)
		else
			disconnectCharacterHooks()
			disconnectVehicleSignals()
			releaseHeliHook()
			releaseVoltHook()
			updateMotorbikeConstant(true)
			updateTankConstant(true)
			restoreTowHook(true)
			clearSnapshots()
		end
	end,
	Tooltip = 'Single module for all vehicle overrides & QoL tweaks.'
})

carControls.engine = VehicleSuite:CreateToggle({
	Name = 'Car Engine Override',
	Function = function()
		reapplyCarStats(true)
	end
})
carControls.engineSlider = VehicleSuite:CreateSlider({
	Name = 'Car Engine Speed',
	Min = CAR_ENGINE_MIN,
	Max = CAR_ENGINE_MAX,
	Default = CAR_ENGINE_DEFAULT,
	Suffix = 'x',
	Function = function()
		if carControls.engine.Enabled then
			reapplyCarStats(true)
		end
	end
})

carControls.turn = VehicleSuite:CreateToggle({
	Name = 'Car Turn Override',
	Function = function()
		reapplyCarStats(true)
	end
})
carControls.turnSlider = VehicleSuite:CreateSlider({
	Name = 'Car Turn Speed',
	Min = CAR_TURN_MIN,
	Max = CAR_TURN_MAX,
	Default = CAR_TURN_DEFAULT,
	Decimal = 1,
	Suffix = 'x',
	Function = function()
		if carControls.turn.Enabled then
			reapplyCarStats(true)
		end
	end
})

carControls.suspension = VehicleSuite:CreateToggle({
	Name = 'Suspension Override',
	Function = function()
		reapplyCarStats(true)
	end
})
carControls.suspensionSlider = VehicleSuite:CreateSlider({
	Name = 'Suspension Height',
	Min = CAR_SUSPENSION_MIN,
	Max = CAR_SUSPENSION_MAX,
	Default = CAR_SUSPENSION_DEFAULT,
	Function = function()
		if carControls.suspension.Enabled then
			reapplyCarStats(true)
		end
	end
})

heliControls.speed = VehicleSuite:CreateToggle({
	Name = 'Heli Speed Override',
	Function = function(state)
		if state then
			ensureHeliHook()
		end
	end
})
heliControls.forward = VehicleSuite:CreateSlider({
	Name = 'Heli Forward Speed %',
	Min = HELI_FORWARD_MIN,
	Max = HELI_FORWARD_MAX,
	Default = HELI_FORWARD_DEFAULT,
	Function = function() end
})
heliControls.vertical = VehicleSuite:CreateSlider({
	Name = 'Heli Vertical Speed %',
	Min = HELI_VERTICAL_MIN,
	Max = HELI_VERTICAL_MAX,
	Default = HELI_VERTICAL_DEFAULT,
	Function = function() end
})
heliControls.turn = VehicleSuite:CreateSlider({
	Name = 'Heli Turn Speed %',
	Min = HELI_TURN_MIN,
	Max = HELI_TURN_MAX,
	Default = HELI_TURN_DEFAULT,
	Function = function() end
})
heliControls.height = VehicleSuite:CreateToggle({
	Name = 'Heli Infinite Height',
	Function = function()
		reapplyCarStats(false)
	end
})

voltControls.speed = VehicleSuite:CreateToggle({
	Name = 'Volt Speed Override',
	Function = function(state)
		if state then
			ensureVoltHook()
		end
	end
})
voltControls.speedSlider = VehicleSuite:CreateSlider({
	Name = 'Volt Multiplier',
	Min = VOLT_MIN,
	Max = VOLT_MAX,
	Default = VOLT_DEFAULT,
	Suffix = 'x',
	Function = function() end
})

bikeControls.speed = VehicleSuite:CreateToggle({
	Name = 'Motorbike Speed Override',
	Function = function()
		updateMotorbikeConstant()
	end
})
bikeControls.speedSlider = VehicleSuite:CreateSlider({
	Name = 'Motorbike Multiplier',
	Min = MOTORBIKE_MIN,
	Max = MOTORBIKE_MAX,
	Default = MOTORBIKE_DEFAULT,
	Suffix = 'x',
	Function = function()
		updateMotorbikeConstant()
	end
})

tankControls.speed = VehicleSuite:CreateToggle({
	Name = 'Tank Engine Override',
	Function = function()
		updateTankConstant()
	end
})
tankControls.speedSlider = VehicleSuite:CreateSlider({
	Name = 'Tank Engine Speed',
	Min = TANK_MIN,
	Max = TANK_MAX,
	Default = TANK_DEFAULT,
	Suffix = 'x',
	Function = function()
		updateTankConstant()
	end
})

utilityControls.tow = VehicleSuite:CreateToggle({
	Name = 'Instant Tow',
	Function = function()
		syncTowHook()
	end
})

utilityControls.heliPickup = VehicleSuite:CreateToggle({
	Name = 'Instant Heli Pickup',
	Function = function()
		syncTowHook()
	end
})

utilityControls.hijack = VehicleSuite:CreateToggle({
	Name = 'Auto Hijack',
	Function = function(state)
		if state then
			runHijackLoop()
		end
	end
})
