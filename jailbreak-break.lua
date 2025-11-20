--[[
Core:
	[~] Fixed Not Working
]]

-- i recommend yall to not seeing this shitty source, because most of these stuff is from old jb script which at the time that i'm still learning luau soo everything here is 1000% guranteed full of masterpiece of shitfest code
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles

local MainESP, CullingSystem = loadstring(game:HttpGet('https://raw.githubusercontent.com/Breadido/Main/refs/heads/master/utils/esp/source.lua'))() 
MainESP.Options = {
    Enabled = false,              -- Master toggle for player ESP
    Box = false,                  -- Show bounding boxes
    Health = false,               -- Show health bars
    Tracer = false,               -- Show tracer lines
    TracerOrigin = "Bottom",      -- Tracer origin point
    Name = false,                 -- Show player names
    Distance = false,             -- Show distance
    Direction = false,            -- Show facing direction
    Skeleton = false,             -- Show skeleton
    TextOutline = false,          -- Add text outlines
    Color = Color3.new(1, 1, 1),  -- Default ESP color
    UseTeamColor = true,          -- Use team colors
    Rainbow = false,              -- Rainbow color mode
    Font = 1,                     -- Text font (0-3)
    FontSize = 15,                -- Text size
    TeamCheck = false,            -- Hide teammates
    BoxThickness = 0,             -- Box line thickness
    TracerThickness = 0,          -- Tracer line thickness
    DirectionThickness = 0,       -- Direction arrow thickness
    SkeletonThickness = 0,        -- Skeleton line thickness
}
CullingSystem.maxRenderDistance = 20000
CullingSystem.nearDistance = 10000
CullingSystem.farDistance = 15000

local setclipboard = setclipboard or toclipboard or set_clipboard or nil
local setthreadcontext = setthreadidentity or set_thread_identity or setthreadcontext or set_thread_context or function() Library:Notify("missing setthreadidentity/sethreadcontext") end
local firesignal = firesignal or function() Library:Notify("missing firesignal") end

configs = {
    player = {
		walktog = false;
		walkval = 0;
		infjump = false;
		respawndeathloc = false;
		nofall = false;
		norag = false;
		noislow = false;
		nosky = false;
		nostun = false;
		norwait = false;
		nocslow = false;
		nocircwait = false;
		nopwait = false;
		nocwait = false;
		bypasskd = false;
		doornoreq = false;
		alwayssilentp = false;
		alwaysp = false;
		alwayssp = false;
		juiced = false;
		crawlequip = false;
		backbone = false;
		dogs = {
			dogshephardsp = 50;
			bulldogsp = 40;
			instantleadattack = false;
			alwaysbarking = false;
		};
	};
    vehicle = {
		fspeed = 10;
		ftog = false;
		fx = 0;
		fy = 0;
		fz = 0; 
		engine = false;
		enginesp = 0;
		brake = false;
		brakesp = 0;
		suspension = false;
		suspensionhe = 0;
		turnsp = 0;
		turn = false;
		inftrac= false;
		reducebounce = false;
		tirepop = false;
		alwayshij = false;
		infnitro = false;
		rinfnitro = false;
		autoflip = false;
		helibreak = false;
		helienginesp = 0;
		heliverticalsp = 0;
		heliturnsp = 0;
		heliengine = false;
		helipick = false;
		-- helivertical = false;
		-- heliturn = false;
		heliheight = false;
		instanttow = false;
		driveonwater = false;
		tanksus = false;
		tanksushe = 5.3;
		tankengine = false;
		tankenginesp = 0;
		--voltengine = false;
		voltenginesp = 0;
	};
    combat = {
		hitboxradius = 3;
		noequipt = false;
		nospread = false;
		norecoil = false;
		nobulletg = false;
		alwaysauto = false;
		alwaysheadshot = false;
		pistolswat = false;
		snipernoblur = false;
		snipernogui = false;
		wallbang = false;
		nogrenadesmoke = false;
		nogrenadesmokelimit = false;
		tasermodz = false;
		instantrocketseek = false;
		forcefieldnomiss = false;
		increasetakedowndamage = false;
		increaseforcedamage = false;
		forcefieldreload = false;
		shootthroughforce =false;
		instantc4throw = false;
		antic4limit = false;
		instantbullethit = false;
		getweapon = false;
		silentaim = {
			enabled = false;
			includetaser = false;
			includeplasma = false;
			radius = 50;
			wallcheck = false;
			fovcirc = false;
			fovthick = 5;
			fovtransp = 0;
		};
		arrestaura = {
			enabled = false;
			showtargeted = false;
		};
		batonsword = {
			noreloadtime = false;
			spamlunge = false;
			spamswoosh = false;
		};
	};
    teleportation = {}; -- soon not yet lmfao
    robberies = {
		--guardnodmg = false;
	};
    nametags = {};
	others = {
		disablehometurret = false;
		disablemilitaryturret = false;
		guardnodmg = false;
		opendoor = false;
		prisonelevator = false;
		nooilblow = false;
		disablelaser = false;
		opensewer = false;
	};
}
local client = {
	tankdata = {};
	inprogress = false;
	lastvehiclestats = {
		GarageEngineSpeed = nil;
		Height = nil;
		TurnSpeed = nil;
	};
	lastmotorcyclestats = {
		f = nil;
		Height = nil;
	};
	lastvehiclemodel = nil;
	vehicleEntered = false;
	originalequippeddata = {};
	activeaction = {};
	activel = {};
	simulatedphysicsprojectile = require(game:GetService("ReplicatedStorage").Module.SimulatedPhysicsProjectile);
	guardnpcbinder = require(game:GetService("ReplicatedStorage").GuardNPC.GuardNPCBinder);
	combatconst = require(game:GetService("ReplicatedStorage").Combat.CombatConsts);
	militaryturretconst= require(game:GetService("ReplicatedStorage").Game.MilitaryTurret.MilitaryTurretConsts);
	dogconst = require(game:GetService("ReplicatedStorage").Game.Dog.DogConsts);
	combatutils = require(game:GetService("ReplicatedStorage").Combat.CombatUtils);
	playerutil = require(game:GetService("ReplicatedStorage").Game.PlayerUtils);
	actionbuttonservice = require(game:GetService("ReplicatedStorage").ActionButton.ActionButtonService);
	settingss = require(game:GetService("ReplicatedStorage").Resource.Settings);
	characterutil = require(game:GetService("ReplicatedStorage").Game.CharacterUtil);
	paraglide = require(game:GetService("ReplicatedStorage").Game.Paraglide);
	alexchassis = require(game:GetService("ReplicatedStorage").Module.AlexChassis);
	alexchassis2 = require(game:GetService("ReplicatedStorage").Module.AlexChassis2);
	dog = require(game:GetService("ReplicatedStorage").Game.Dog.Dog);
    dogsystem = require(game:GetService("ReplicatedStorage").Game.Dog.DogSystem);
	itemgun = require(game:GetService("ReplicatedStorage").Game.Item.Gun);
	itemsys = require(game:GetService("ReplicatedStorage").Game.ItemSystem.ItemSystem);
	gunutil = require(game:GetService("ReplicatedStorage").Game.GunShop.GunUtils);
	gamepasssystem = require(game:GetService("ReplicatedStorage").Game.Gamepass.GamepassSystem);
	pistolitem = require(game:GetService("ReplicatedStorage").Game.Item.Pistol);
	smokegrenadeitem = require(game:GetService("ReplicatedStorage").Game.SmokeGrenade.SmokeGrenade);
	movementrollservice = require(game:GetService("ReplicatedStorage").MovementRoll.MovementRollService);
	circleac = require(game:GetService("ReplicatedStorage").Module.UI).CircleAction;
	tase = require(game:GetService("ReplicatedStorage").Game.Item.Taser);
	plasmagun = require(game:GetService("ReplicatedStorage").Game.Item.PlasmaGun);
	geomUtils = require(game:GetService("ReplicatedStorage"):WaitForChild("Std"):WaitForChild("GeomUtils"));
    vehiclelinkbinder = require(game:GetService("ReplicatedStorage").VehicleLink.VehicleLinkBinder);
	duck = require(game:GetService("ReplicatedStorage").Game.Robbery.TombRobbery.TombRobberySystem).duck;
	vehicleutils = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils);
	onvehicleentered = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils).OnVehicleEntered;
	onvehicleexited = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils).OnVehicleExited;
	onlocalitemequipped = require(game:GetService("ReplicatedStorage").Game.ItemSystem.ItemSystem).OnLocalItemEquipped;
	onlocalitemunequipped = require(game:GetService("ReplicatedStorage").Game.ItemSystem.ItemSystem).OnLocalItemUnequipped;
	raycast = require(game:GetService("ReplicatedStorage").Module.RayCast);
	bulletemitter = require(game:GetService("ReplicatedStorage").Game.ItemSystem.BulletEmitter);
	c4 = require(game:GetService("ReplicatedStorage").Game.Item.C4);
	wheel = require(game:GetService("ReplicatedStorage").Module.Wheel.Wheel);
	localization = require(game:GetService("ReplicatedStorage").Module.Localization);
	rocketconsts = require(game:GetService("ReplicatedStorage").RocketLauncher.RocketLauncherConsts);
	dartdispenser = require(game:GetService("ReplicatedStorage").Game.DartDispenser.DartDispenser);
	rocketworld = require(game:GetService("ReplicatedStorage").Game.RocketWorld);
	turret = require(game:GetService("ReplicatedStorage").Turret2.Turret);
	oilrigbinder = require(game:GetService("ReplicatedStorage").OilRig.OilRigBinder)._constructor;
	gunshopui = require(game:GetService("ReplicatedStorage").Game.GunShop.GunShopUI);
	spotlightbinder = require(game:GetService("ReplicatedStorage").TrackingSpotlight.TrackingSpotlightBinder);
	inventoryitemsystem = require(game:GetService("ReplicatedStorage").Inventory.InventoryItemSystem);
	interval = require(game:GetService("ReplicatedStorage").Std.Interval);
	tankbinder = require(game:GetService("ReplicatedStorage").Tank.TankBinder)._constructor;
}

client.ori = {
	hookNearest = client.vehiclelinkbinder._constructor._hookNearest;
	bulletemitteronlocalhitplayer = client.itemgun.BulletEmitterOnLocalHitPlayer;
	hittargetwithspeed = client.simulatedphysicsprojectile.HitTargetWithSpeed;
	isflying = client.paraglide.IsFlying;
	tase = client.tase.Tase;
	doesplayerowncached = client.gamepasssystem.doesPlayerOwnCached;
	update = client.circleac.Update;
	getequiptime = client.gunutil.getEquipTime;
	rayignorenon = client.raycast.RayIgnoreNonCollide;
	plasmashootother = client.plasmagun.ShootOther;
	pistolsetupmodel = client.pistolitem.SetupModel;
	rayignore = client.raycast.RayIgnoreNonCollideWithIgnoreList;
	shoot = client.itemgun.Shoot;
	circleactionpress =  client.circleac.Press;
	oillaunchblow = client.oilrigbinder._launchBlowUp;
};

client.tagfuninstance = getupvalue(getconnections(game:GetService("CollectionService"):GetInstanceAddedSignal("SewerHatch"))[1].Function, 3)
client.dooraddedsignal = getconnections(game:GetService("CollectionService"):GetInstanceAddedSignal("Door"))[1].Function
-- client.opendoor = getupvalue(getupvalue(client.dooraddedsignal, 2), 4)
client.doors = getupvalue(client.dooraddedsignal, 1)
client.doors.cellz = {}
client.oilexplosion = workspace.OilRig.OpenCloseSignal.Explosion

client.rocketworld.yousuck = (function() end)
 
client.getnumactivec4 = getupvalue(client.c4.ShootBegin, 4)
client.gethrowablesmokegrenade = getupvalue(require(game:GetService("ReplicatedStorage").Game.Item.SmokeGrenade).ShootBegin, 1)
client.getnearestplayer = getupvalue(require(game:GetService("ReplicatedStorage").Home.HomeItem.Fabricate.Turret).setup, 12)
client.motorupdatewheel = getupvalue(client.alexchassis2.UpdateHQ, 16)
client.circleupdateui = getupvalue(client.circleac.Update, 1)

client.rollratelimiter = getupvalue(client.movementrollservice.attemptRoll, 6)
client.vclasses = client.vehicleutils.Classes 
client.ori.heliupdate = client.vclasses.Heli.Update
client.ori.voltupdate = client.vclasses.Volt.Update
client.ori.chassisupdate = client.vclasses.Chassis.UpdateEngine

setreadonly(client.combatconst, isreadonly(client.combatconst) and false)
setreadonly(client.militaryturretconst, isreadonly(client.militaryturretconst) and false)
setreadonly(client.dogconst, isreadonly(client.dogconst) and false)
setreadonly(client.rocketconsts, isreadonly(client.rocketconsts) and false)
setconstant(client.motorupdatewheel, 17, "die")

for i,v in next, client.ori do
	client.ori[i] = clonefunction(v)
end

for i,v in next, getgc() do 
	if type(v) == "function" and islclosure(v) then
		local infoname = tostring(getinfo(v).name) 
		if tostring(getfenv(v).script) == "LocalScript" then
			if table.find(getconstants(v), "StartRagdolling") then
				client.stunnedragdoll = v
			end
			if table.find(getconstants(v), "PlusCash") then
				client.cashthingy = v
			end
			-- if table.find(getconstants(v), "Door was already resolved:") then
			-- 	client.doorAddedFunction = v
			-- end
			-- if getconstants(v)[8] == "Door was already resolved:" then
			-- 	client.doors = getupvalue(v, 1)
			-- end
			-- if infoname == "DoorSequence" then
			-- 	client.opendoor = v
			-- end
			if infoname == "HasPerm" then
				client.hasperm = v
				client.ori.hasperm = v
			end
			if infoname == "AttemptArrest" then 
				client.attemptarrest = v
			end
			if infoname == "UpdatePlayer" then
				client.updateplayer = v
			end
			if infoname == "StartNitro" then
				client.startnitro = v
				client.nitro = getupvalue(v, 8)
			end
			if infoname == "StopNitro" then
				client.stopnitro = v
			end
			if infoname:find("CheatCheck") then -- shit didn't work
				hookfunction(v, function()  end)
			end
		end
		if getfenv(v).script == game:GetService("ReplicatedStorage").Std.Binder and infoname == "" and getupvalues(v)[1] and type(getupvalues(v)[1]) == "table" then
			local upvalue = getupvalue(v, 1) 
			if typeof(upvalue) == "table" and upvalue._tagName == "BarbedWireClient" then
				client.barbedwireclient = upvalue
			end
		end
	end
end

for i,v in next, getconnections(game:GetService("RunService").Heartbeat) do
    if v.Function and islclosure(v.Function) then
        if getconstants(v.Function)[13] == "Time/UI" then
            client.walkspeedfun = getupvalue(v.Function,6)
        end
		if getconstants(v.Function)[4] == "LQVehicle Heartbeat" then
			setconstant(v.Function, 27, "plzdie")
			setconstant(v.Function, 28, "plzdie")
		end
    end
end

for i,v in next, client.actionbuttonservice.active do
	if table.find(v.keyCodes, Enum.KeyCode.V) then
		client.activeaction.flip = v
	end
	if table.find(v.keyCodes, Enum.KeyCode.LeftControl) then
		client.activeaction.roll = v
	end
end

for i,v in next, client.doors do
	if v.Model and v.Model.Parent.Name == "Cell" then
		table.insert(client.doors.cellz, v)
	end
end

local itemConfigClone = game:GetService("ReplicatedStorage").Game.ItemConfig:Clone()
itemConfigClone.Name = "ItemConfigBackup"

local Circle = MainESP.CreateCircle()
Circle.Radius = configs.combat.silentaim.radius
Circle.Color = Color3.fromRGB(255,255,255)
Circle.Position = MainESP.TracerOrigins.Middle
Circle.NumSides = 500

local CircleOutline = MainESP.CreateCircle()
CircleOutline.Radius = configs.combat.silentaim.radius + 2
CircleOutline.Color = Color3.fromRGB(0, 0, 0)
CircleOutline.Filled = false
CircleOutline.Visible = false
CircleOutline.Position = MainESP.TracerOrigins.Middle
CircleOutline.NumSides = 500

local CircleFilled = MainESP.CreateCircle()
CircleFilled.Radius = configs.combat.silentaim.radius - 1
CircleFilled.Color = Color3.fromRGB(0, 0, 0)
CircleFilled.Filled = true
CircleFilled.Visible = false
CircleFilled.Transparency = 0.5
CircleFilled.Position = MainESP.TracerOrigins.Middle
CircleFilled.NumSides = 500

client.getremotekeyfromdecompiledsource = (function(decompiledstr, keytabletoremove)
	-- my shitty attempt making my own key remote fetcher via using medal decompiler
	-- will be using ts later on probably next update 
	local strkey = {}
	for i,v in ipairs(string.split(decompiledstr, "\n")) do
		if string.find(v, ":FireServer", 0) then
			local currentstr = string.gsub(string.gsub(tostring(v), ":FireServer", ""), " ", "")
			for i2,v2 in next, keytabletoremove do
				currentstr = string.gsub(currentstr, v2, "")
			end
			strkey[#strkey + 1] = loadstring("return".. currentstr:sub(2, currentstr:len() - 1))()
		end
	end
	return strkey
end)

client.ispc = (function()
	local UserInputService = game:GetService("UserInputService")
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return false
	elseif not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return true
	end
	return false
end)

client.duckLoop = (function()
	repeat 
		client.duck()
		task.wait(2)
	until configs.player.backbone == false
end)
client.flipLoop = (function()
	repeat task.wait(.1)
		pcall(function()
			for i,v in next, client.actionbuttonservice.active do
				if table.find(v.keyCodes, Enum.KeyCode.V) then
					v.onPressed(true)
				end
			end
		end)
	until configs.vehicle.autoflip == false
end)
client.hasKeyHook = (function(boolean)
	if boolean then
		hookfunction(client.playerutil.hasKey, function()
			return true
		end)
	else
		if isfunctionhooked(client.playerutil.hasKey) then restorefunction(client.playerutil.hasKey) end
	end
end)
client.smokeGrenadeHook = (function(boolean)
	if boolean then
		hookfunction(client.smokegrenadeitem._playExplosionFx, function() end)
	else
		if isfunctionhooked(client.smokegrenadeitem._playExplosionFx) then restorefunction(client.smokegrenadeitem._playExplosionFx) end
	end
end)
client.getNearestPlayerHook = (function(boolean)
	if boolean then
		hookfunction(client.getnearestplayer, function() return nil end)
	else
		if isfunctionhooked(client.getnearestplayer) then restorefunction(client.getnearestplayer) end
	end
end)
client.isCrawlingLoop = (function()
	repeat task.wait(.1)
		if client.characterutil.IsCrawling then
			client.characterutil.IsCrawling = false
		end
	until configs.player.crawlequip == false
end)
client.hijackLoop = (function()
	repeat task.wait(.1)
		for i,v in next, client.circleac.Specs do
			if v.Name == client.localization:FormatByKey("Action.Hijack") then
				v:Callback(true)
			end
		end
	until configs.vehicle.alwayshij == false
end)
client.setnpcignorelp = (function(a)
	for i,v in next, getupvalue(client.itemsys.GetEquipped, 1) do
		if v.Character and v.BulletEmitter and v.BulletEmitter.IgnoreGuards then
			v.BulletEmitter.IgnoreLocalPlayer = a
		end
	end
end)
client.npcnodamageloop = (function()
	repeat task.wait(0.1)
		client.setnpcignorelp(false)
	until configs.others.guardnodmg == false
end)
client.nitroLoop = (function()
	repeat task.wait()
		client.nitro.NitroLastMax = 250
		client.nitro.Nitro = configs.vehicle.rinfnitro and math.random(10, 249) or 249
		client.nitro.NitroForceUIUpdate = true
	until configs.vehicle.infnitro == false
end)
client.sprintLoop = (function()
	repeat task.wait()
		setupvalue(client.walkspeedfun, 9, true)
	until not configs.player.alwayssp
end)
client.launchVehicleFlight = (function()
	local BodyGyro = Instance.new("BodyGyro", game:GetService("Players").LocalPlayer.Character.HumanoidRootPart)
	local BodyVelocity = Instance.new("BodyVelocity", game:GetService("Players").LocalPlayer.Character.HumanoidRootPart)
	local Camera = workspace.CurrentCamera
	BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	BodyGyro.D = 50000
	BodyGyro.P = 1500000000
	repeat task.wait()
		BodyGyro.CFrame = Camera.CFrame * CFrame.Angles(math.rad(configs.vehicle.fx), math.rad(configs.vehicle.fy), math.rad(configs.vehicle.fz))
		workspace.CurrentCamera.CameraType = Enum.CameraType.Track
		BodyVelocity.Velocity = Vector3.new()
		local direction = require(game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule")):GetMoveVector()
		if direction.X > 0 then
			BodyVelocity.Velocity = BodyVelocity.Velocity + Camera.CFrame.RightVector * direction.X
		end
		if direction.X < 0 then
			BodyVelocity.Velocity = BodyVelocity.Velocity + Camera.CFrame.RightVector * direction.X
		end
		if direction.Z > 0 then
			BodyVelocity.Velocity = BodyVelocity.Velocity - Camera.CFrame.LookVector * direction.Z
		end
		if direction.Z < 0 then
			BodyVelocity.Velocity = BodyVelocity.Velocity - Camera.CFrame.LookVector * direction.Z
		end
		BodyVelocity.Velocity = BodyVelocity.Velocity * configs.vehicle.fspeed
	until client.vehicleEntered == false or configs.vehicle.ftog == false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	BodyGyro:Destroy()
	BodyVelocity:Destroy()
end)
client.getOldWeaponData = (function(name, dataname)
	return rawget(require(itemConfigClone[name]), dataname)
end)
client.setBatonSwordTime = (function(bool)
	local baton = require(game:GetService("ReplicatedStorage").Game.Item.Baton)
	local sword = require(game:GetService("ReplicatedStorage").Game.Item.Sword)
	getupvalue(baton.new,2).ReloadTime = bool and 0 or 0.5
	getupvalue(sword.new,2).ReloadTime = bool and 0 or 0.5
end)
client.spamBatonSwordSwoosh = (function()
	repeat task.wait()
		local a = client.itemsys.GetLocalEquipped()
		if a and (a.__ClassName == "Sword" or a.__ClassName == "Baton") then
			require(game:GetService("ReplicatedStorage").Game.Item[a.__ClassName]).SwingSwoosh(a)
		end
	until configs.combat.batonsword.spamswoosh == false
end)
client.spamBatonSwordLunge = (function()
	repeat task.wait()
		local a = client.itemsys.GetLocalEquipped()
		if a and (a.__ClassName == "Sword" or a.__ClassName == "Baton") then
			require(game:GetService("ReplicatedStorage").Game.Item[a.__ClassName]).SwingLunge(a)
		end
	until configs.combat.batonsword.spamlunge == false
end)

client.notInWall = (function(pos,ilist,wallCheck)
	if not wallCheck then
        return true
    end
	local workspace = game:GetService("Workspace")
    local camera = workspace.CurrentCamera or nil
    if camera == nil then
        return false
    end
    local direction = (pos - camera.CFrame.Position).Unit * (pos - camera.CFrame.Position).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = ilist or {}
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(camera.CFrame.Position, direction, rayParams)
    return result == nil
end)
client.isEnemies = (function(a,b)
    local a, b = tostring(a), tostring(b)
    if a == "Criminal" and b == "Police" then
        return true
    elseif a == "Criminal" and b == "Prisoner" then
        return false
    elseif a == "Police" and b == "Criminal" then
        return true
    elseif a == "Police" and b == "Prisoner" then
        return false
    elseif a == "Prisoner" and b == "Police" then
        return true
    elseif a == "Prisoner" and b == "Criminal" then
        return false
    end
end)
client.getNearestToCursor = (function()
    local Target = nil
	local notInWall = client.notInWall
	local isEnemies = client.isEnemies
	local middlepos = MainESP.TracerOrigins.Middle
    for i,v in next, game:GetService("Players"):GetPlayers() do
        if isEnemies(game:GetService("Players").LocalPlayer.Team, v.Team) and v ~= game:GetService("Players").LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health ~= 0 then
			local magnitude = (game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).magnitude
			if magnitude < 300 then -- max bullet distance of all gun is probably around 300 studs. correct me if i'm wrong please
				local Point, OnScreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
				if OnScreen and notInWall(v.Character.HumanoidRootPart.Position, {game:GetService("Players").LocalPlayer.Character, v.Character}, configs.combat.silentaim.wallcheck) then
					local Distance =(Vector2.new(Point.X, Point.Y) - Vector2.new(middlepos.X, middlepos.Y)).magnitude
					if Distance < configs.combat.silentaim.radius then
						Target = v
						return Target
					end
				end
			end
        end
    end
    return Target
end)
client.getDog = (function()
    for i,v in next, client.dogsystem.getAll() do
        if tostring(client.dog.GetOwner(v)) == game:GetService("Players").LocalPlayer.Name then
            return v   
        end
    end
    return nil
end)
client.getPlayerVehicle = (function(plrname)
	local uh = nil
	for i,v in next, game:GetService("CollectionService"):GetTagged("Vehicle") do
		for i2,v2 in next, v:GetChildren() do
			if v2.Name == "Seat" or v2.Name == "Passenger" then
				local whateverSeatName = v2:FindFirstChild("PlayerName")
				if whateverSeatName and whateverSeatName.Value == plrname then
					return uh
				end
			end
		end
	end
	return uh
end)

client.getNearestVehicle = (function()
	local char = game:GetService("Players").LocalPlayer.Character
	local target, distance = nil, 100
	for i,v in next, game:GetService("CollectionService"):GetTagged("Vehicle") do
		if v:FindFirstChild("Seat") or v:FindFirstChild("Passenger") then
			local targetDistance = (char:FindFirstChild("HumanoidRootPart").Position-v:GetModelCFrame().Position).magnitude
			if targetDistance < distance then
				distance = targetDistance
				target = v
			end
		end
	end
	return target
end)

client.getNearestPlayerNoCuffed = (function() 
    local maxdistance = 18
    local player = nil;
    for i,v in next, game:GetService("Players"):GetPlayers() do
        if tostring(v.Team) == "Criminal" then
            local character = v.Character or nil
            if character ~= nil and not v.Character:GetAttribute("Handcuffs") then
                local hrp = character:FindFirstChild("Head") or nil
                local hum = character:FindFirstChild("Humanoid") or nil
                if hrp ~= nil and hum ~= nil then
                    local mag = (game:GetService("Players").LocalPlayer.Character:GetModelCFrame().Position - hrp.Position).magnitude
                    if mag < maxdistance then
                        player = v
                        if player ~= nil then
                            return player
                        end
                    end
                end
            end
        end
    end
	return false
end)
client.launchArrestAura = (function()
	local getNearestPlayerNoCuffed = client.getNearestPlayerNoCuffed
	repeat task.wait(0.15)
        pcall(function()
            local plr = getNearestPlayerNoCuffed()
            if plr then
                client.attemptarrest(game:GetService("Players"):FindFirstChild(tostring(plr)))		
                --print(game:GetService("Players"):FindFirstChild(tostring(plr)))	
            end
        end)
	until configs.combat.arrestaura.enabled == false
end)

client.updateToOriginalChassisStats = (function()
	local gvp = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils).GetLocalVehiclePacket() 
	if gvp ~= nil and client.lastvehiclestats ~= nil and client.lastvehiclemodel ~= nil and gvp.Model ~= gvp.lastvehiclemodel then
		local stats = client.lastvehiclestats
		if configs.vehicle.engine == false then
			gvp.GarageEngineSpeed = stats.GarageEngineSpeed
		end
		-- if configs.vehicle.brake == false then
		-- 	gvp.GarageBrakes = stats.GarageBrakes
		-- end
		if configs.vehicle.suspension == false then
			gvp.Height = stats.Height
		end
		if configs.vehicle.turn == false then
			gvp.TurnSpeed = stats.TurnSpeed
		end
	end
end)

client.changeHitboxRadius = (function(radius)
	-- setreadonly(client.combatconst, isreadonly(client.combatconst) and false)
	-- client.combatconst.DEFAULT_ROOT_PART_HIT_RADIUS = radius
end)

client.onHitSurfaceHook = (function()
	local a = client.itemsys.GetLocalEquipped()
	a.FakeName = "Sniper"
	if configs.combat.increasetakedowndamage and a.BulletEmitter ~= nil then
		for i,v in next, getconstants(a.BulletEmitter.OnHitSurface._handlerListHead._fn) do
			if v == "__ClassName" then
				setconstant(a.BulletEmitter.OnHitSurface._handlerListHead._fn, i, "FakeName")
			end
		end			
	elseif configs.combat.increasetakedowndamage == false and a.BulletEmitter ~= nil then
		for i,v in next, getconstants(a.BulletEmitter.OnHitSurface._handlerListHead._fn) do
			if v == "FakeName" then
				setconstant(a.BulletEmitter.OnHitSurface._handlerListHead._fn, i, "__ClassName")
			end
		end			
	end
end)

client.opendoorloop = (function()
	repeat 
		for i,v in next, client.tagfuninstance do
			v["Fun"]()
		end
		task.wait(1.5)
	until configs.others.opendoor == false
end)

client.getprisonelevator = (function()
	for i,v in next, workspace:GetChildren() do
		if v:IsA("Model") and v.Name == "Elevator" and v:FindFirstChild("Car") and v.Car:FindFirstChild("InnerModel") and v.Car.InnerModel:FindFirstChild("Calls") and v.Car.InnerModel.Calls[1]:FindFirstChild("SurfaceGui").TextLabel.Text == "1*" then
			return v
		end
	end
	return nil
end)

client.callprisonelevator = (function(flor)
	pcall(function()
		--fireclickdetector(game:GetService("CollectionService"):GetTagged("Elevator")[1].Floors[flor].Call.ClickDetector)
		if client.getprisonelevator() ~= nil then
			fireclickdetector(client.getprisonelevator().Car.InnerModel.Calls[1].ClickDetector)
		end
	end)
end)

client.prisonelevatorloop = (function()
	repeat task.wait(0.5)
		client.callprisonelevator(1)
	until configs.others.prisonelevator == false
end)

client.showgunstore = (function()
	setthreadcontext(2)
	client.gunshopui.open()
	setthreadcontext(10)
end)

client.getallgun = (function()
	local grabguns = (function()
		for i,v in next, game:GetService("Players").LocalPlayer.PlayerGui.GunShopGui.Container.Container.Main.Container.Slider:GetChildren() do
			if v.ClassName == "ImageLabel" and v.Bottom.Action.Text == "EQUIP" then
				firesignal(v.Bottom.Action.MouseButton1Down)
			end
		end
	end)
	client.showgunstore()
	for i,v in next, game:GetService("Players").LocalPlayer.PlayerGui.GunShopGui.Container.Container.Sidebar:GetChildren() do
		if v.ClassName == "ImageButton" then
			task.wait()
			for i = 1, 3 do
				grabguns()
			end
			firesignal(v.MouseButton1Down)
		end
	end
	client.gunshopui.close()
end)

client.barbedwiremodify = (function(a)
	local hooklaser = (function()
		for i,v in next, getproto(client.barbedwireclient._constructor, 1, true) do
			hookfunction(v, function()
				return
			end)
		end
	end)
	local unhooklaser = (function()
		for i,v in next, getproto(client.barbedwireclient._constructor, 1, true) do
			if isfunctionhooked(v) then
				restorefunction(v)
			end
		end
	end)
	if a then hooklaser() else unhooklaser() end
end)

client.barbedwireloop = (function()
	repeat task.wait(1)
		client.barbedwiremodify(true)
	until configs.others.disablelaser == false
end)

client.opensewerhatch = (function()
	for i,v in next, client.tagfuninstance do
		if v["_DEBUG"] == "SewerHatch" then
			v["Fun"]()
		end
	end
end)

client.oepnsewerloop = (function()
	repeat task.wait(0.05) 
		client.opensewerhatch()
	until configs.others.opensewer == false
end)

client.dropall = (function()
	for i,v in next, client.inventoryitemsystem.getInventoryItemsFor(game:GetService("Players").LocalPlayer) do
		local ignore = {"Bag", "Crate", "Gem", "Taser", "Handcuffs", "RoadSpike", "MansionInvite"}
		if not table.find(ignore, v.obj.Name) then
			v:AttemptSetEquipped(true)
			v:AttemptDrop()
		end
	end
end)

client.deathtp = (function(cframe)
	game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").Health = 0
    repeat
        task.wait()
    until game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid") and game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").Health > 0
    local Timeout = os.time()
    repeat
        game:GetService("Players").LocalPlayer.Character:PivotTo(CFrame.new(cframe.Position))
        task.wait()
    until os.time() - Timeout > 1
	client.inprogress = false
end)

client.openclosedcell = (function()
	for i,v in next, client.doors.cellz do
		if v.State.Open == false then
			v.State.Open = true
			v:OpenFun()
		end
	end
end)

client.cellloop = (function()
	repeat task.wait(0.1)
		client.openclosedcell()
	until configs.player.nocwait == false
end)



task.spawn(function()
	-- Hooking
    hookfunction(getcallbackvalue(game:GetService("ReplicatedStorage").HawkeyeRemoteFunction, "OnClientInvoke"), function() end)
	-- local old
	-- old = hookfunction(Instance.new("RemoteEvent").FireServer, function(...)
	-- 	local args = {...}
	-- 	if #args == 4 and debug.traceback():find("LocalScript:1349") then
	-- 		getgenv().acbypassed = true
	-- 		return
	-- 	end
	-- 	return old(...)
	-- end)

	client.ori.hasperm = hookfunction(client.hasperm, function(...)
		if configs.player.doornoreq then
			return true
		end
		if configs.others.opendoor then
			return true
		end
		return client.ori.hasperm(...)
	end)

	client.simulatedphysicsprojectile.HitTargetWithSpeed = (function(...)
		local args = {...}
		if configs.combat.forcefieldnomiss and args[3] == 75 then
			args[3] = 1
		end
		return client.ori.hittargetwithspeed(unpack(args))
	end)	

	client.itemgun.BulletEmitterOnLocalHitPlayer = (function(...)
		local args = {...}
		if configs.combat.alwaysheadshot then
			args[15].isHeadshot = true
			args[15].isWallbang = false
		end
		return client.ori.bulletemitteronlocalhitplayer(unpack(args))
	end)

	client.itemgun.Shoot = (function(self, a)
		if configs.combat.silentaim.enabled then
			local character = client.getNearestToCursor() and client.getNearestToCursor().Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				self.TipDirection = (hrp.Position - self.Tip.Position).Unit
			end
		end
		local oldLastUpdate = self.BulletEmitter.LastUpdate
		local oldignorelist = self.BulletEmitter.IgnoreList
		self.BulletEmitter.LastUpdate = configs.combat.instantbullethit and -9e9 or oldLastUpdate
		self.BulletEmitter.IgnoreList = configs.combat.wallbang and {workspace} or oldignorelist
		client.ori.shoot(self, a)
	end)

	client.plasmagun.ShootOther = (function(self,a)
		if configs.combat.silentaim.enabled and configs.combat.silentaim.includeplasma then
			local character = client.getNearestToCursor() and client.getNearestToCursor().Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				self.TipDirection = (hrp.Position - self.Tip.Position).Unit
			end
		end
		client.ori.plasmashootother(self,a)
	end)

	client.tase.Tase = (function(self,...)
		if configs.combat.tasermodz then 
			self._lastDraw = 0 
		end
		return client.ori.tase(self,...)
	end)

	client.raycast.RayIgnoreNonCollideWithIgnoreList = (function(...)
		-- yes this is actually from min & brizzy silent aim script cuz i'm starting to get lazy soo yea credits to him!
		-- maybe if i'm not lazy then i will start to make my own
		if debug.traceback():find("Taser") and configs.combat.silentaim.enabled and configs.combat.silentaim.includetaser then
			local character = client.getNearestToCursor() and client.getNearestToCursor().Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				return hrp, hrp.Position, hrp.Position, ... -- not doing args table thing cuz that didn't work for some reason (skill issue tbh)
			end
		end
		return client.ori.rayignore(...)
	end)

	client.raycast.RayIgnoreNonCollide = (function(...)
		local args = {...}
		if configs.vehicle.driveonwater and debug.traceback():find("AlexChassis") then
			args[6] = true
		end
		return client.ori.rayignorenon(unpack(args))
	end)

	client.gamepasssystem.doesPlayerOwnCached = (function(...)
		local args = {...}
		if configs.combat.pistolswat and tostring(args[1]) == game:GetService("Players").LocalPlayer.Name and debug.traceback():find("tem.Pistol") then
			return true
		end
		return client.ori.doesplayerowncached(...)
	end)

	client.gunutil.getEquipTime = (function(...)
		return configs.combat.noequipt and 0 or client.ori.getequiptime(...)
	end)

	client.paraglide.IsFlying = (function(...)
		return configs.player.nosky and debug.traceback():find("Falling") and true or client.ori.isflying(...)
	end)

	client.vehiclelinkbinder._constructor._hookNearest = (function(...)
		local args = {...}
		local rope = args[1].obj
		local obj = args[1].nearestObj
		local requestLink = args[1].manifest.reqLinkRemote
		if configs.vehicle.helipick and rope.Name == "RopePull" then
			local cf = obj.PrimaryPart.CFrame:PointToObjectSpace(client.geomUtils.closestPointInPart(obj.PrimaryPart, rope.Position), rope.Position)
			requestLink:FireServer(obj, cf)
			return
		elseif configs.vehicle.instanttow and rope.Name == "MetalHook" then
			local cf = obj.PrimaryPart.CFrame:PointToObjectSpace(client.geomUtils.closestPointInPart(obj.PrimaryPart, rope.Position), rope.Position)
			requestLink:FireServer(obj, cf)
			return
		end
		return client.ori.hookNearest(...)
	end)

	client.vclasses.Heli.Update = (function(self,...)
		--Vector3.new(configs.vehicle.helienginesp, configs.vehicle.heliverticalsp, configs.vehicle.helienginesp)
		client.ori.heliupdate(self,...)
		if configs.vehicle.heliengine then
			self.Velocity.Velocity *= Vector3.new(configs.vehicle.helienginesp,  configs.vehicle.heliverticalsp, configs.vehicle.helienginesp)
			--self.Rotate.AngularVelocity *= Vector3.new(configs.vehicle.heliturnsp, configs.vehicle.heliturnsp, configs.vehicle.heliturnsp)
		end
	end)

	client.vclasses.Volt.Update = (function(volt)
		--Vector3.new(configs.vehicle.helienginesp, configs.vehicle.heliverticalsp, configs.vehicle.helienginesp)
		client.ori.voltupdate(volt)
		--if configs.vehicle.voltengine then
			volt.Force.Force = volt.Force.Force * (1 + configs.vehicle.voltenginesp)
			--self.Rotate.AngularVelocity *= Vector3.new(configs.vehicle.heliturnsp, configs.vehicle.heliturnsp, configs.vehicle.heliturnsp)
		--end
	end)

	local blacklistedaction = {
		"Rob";
		"Hack";
		"Open Crate";
		"Break In";
		"Pull Lever";
		"Place TNT";
	}
	client.circleac.Press = (function()
		local spec = getupvalue(client.ori.circleactionpress, 1).Spec
		if configs.player.nocircwait and spec and not table.find(blacklistedaction, spec.Name) then
			spec:Callback(true)
		end
		return client.ori.circleactionpress()
	end)

	-- client.oilrigbinder._launchBlowUp = (function(a)
	-- 	if configs.others.nooilblow then
	-- 		return
	-- 	end
	-- 	return client.ori.oillaunchblow(a)
	-- end)

	game:GetService("Players").LocalPlayer:GetMouse().Move:Connect(function()
		if client.ispc() then
			local Mouse = game:GetService"UserInputService":GetMouseLocation()
			Circle.Position = Vector2.new(Mouse.X, Mouse.Y)
			CircleFilled.Position = Vector2.new(Mouse.X, Mouse.Y)
			CircleOutline.Position = Vector2.new(Mouse.X, Mouse.Y)
		end
	end)

	if game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstAncestorOfClass("Humanoid") then
		game:GetService("Players").LocalPlayer.Character.Humanoid.Died:Connect(function(a)
			--local celltime = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.CellTime
			if client.inprogress == false and configs.player.respawndeathloc then
				client.inprogress = true
				local cf = game:GetService("Players").LocalPlayer.Character:GetModelCFrame()
				-- if celltime.Visible then
				-- 	print("waiting for your cell to be opened, please wait")
				-- 	repeat task.wait() until celltime.Visible == false
				-- end
				client.deathtp(cf)
			end
		end)
	end

    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(a)
        local hrp = game:GetService("Players").LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        if hrp then
            if configs.player.nofall then 
                hrp:AddTag("NoFallDamage")
			end
            if configs.player.norag then
                hrp:AddTag("NoRagdoll")
            end
        end
		if configs.combat.getweapon then
			task.delay(0.1, function()
				client.getallgun()
			end)
		end
		repeat task.wait() until a:FindFirstChildOfClass("Humanoid")
		task.wait(0.1)
		a.Humanoid.Died:Connect(function(a)
			-- local celltime = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.CellTime
			if client.inprogress == false and configs.player.respawndeathloc then
				client.inprogress = true
				local cf = game:GetService("Players").LocalPlayer.Character:GetModelCFrame()
				-- if celltime.Visible then
				-- 	print("waiting for your cell to be opened, please wait")
				-- 	repeat task.wait() until celltime.Visible == false
				-- end
				client.deathtp(cf)
			end
		end)
		--[[
		task.wait(0.1)
		for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Character.Humanoid.StateChanged) do -- useless
			if v.Function ~= nil and tostring(getfenv(v.Function).script) == "LocalScript" then
				setconstant(v.Function, 2, "EasingStyle") -- i did this cuz it's funni :>
				setconstant(v.Function, 3, "Linear")
			end
		end
		--]]
    end)
	game:GetService("UserInputService").JumpRequest:Connect(function()
		if configs.player.infjump then
			game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
		end
	end)
	game.Lighting.ChildAdded:connect(function(mama)
		if configs.combat.snipernoblur and mama.Name == "Blur" then
			mama:GetPropertyChangedSignal("Size"):connect(function()
				mama.Enabled = false
			end)
		end
	end)
	client.onvehicleentered:Connect(function(arg1)
		client.vehicleEntered = true
		if arg1.Model ~= client.lastvehiclemodel and arg1.Type == "Chassis" then
			client.lastvehiclemodel = arg1.Model
			client.lastvehiclestats.GarageEngineSpeed = arg1.GarageEngineSpeed
			client.lastvehiclestats.TurnSpeed = arg1.TurnSpeed
			client.lastvehiclestats.Height = arg1.Height
		end
		if configs.vehicle.ftog then
			client.launchVehicleFlight()
		end
		if arg1.Type == "Heli" then
			arg1.MaxHeight = configs.vehicle.heliheight and 9e9 or 400
			arg1.FallOutOfSkyDuration = configs.vehicle.helibreak and 0 or 10
			arg1.DisableDuration = configs.vehicle.helibreak and 0 or 10
		elseif arg1.Type == "Chassis" then
			arg1.TirePopDuration = configs.vehicle.nopop and 0 or 7.5
			arg1.DisableDuration = configs.vehicle.nopop and 0 or 7.5
			arg1.TirePopProportion = configs.vehicle.nopop and 0 or 0.5
		end
	end)
	client.onvehicleexited:Connect(function()
		client.vehicleEntered = false
	end)
	client.onlocalitemequipped:Connect(function(equippeddata) 
		--client.originalequippeddata = equippeddata
		local getdata = client.getOldWeaponData
		local a = client.itemsys.GetLocalEquipped()
		a.FakeName = "Sniper"
		task.spawn(function()
			client.onHitSurfaceHook()
		end)
		if getdata(a.__ClassName, "FireAuto") ~= nil then
			a.Config.FireAuto = configs.combat.alwaysauto and true or getdata(a.__ClassName, "FireAuto") 
		end
		if getdata(a.__ClassName, "BulletSpread") ~= nil then
			a.Config.BulletSpread = configs.combat.nospread and 0 or getdata(a.__ClassName, "BulletSpread")
		end
		if getdata(a.__ClassName, "CamShakeMagnitude") ~= nil then
			a.Config.CamShakeMagnitude = configs.combat.norecoil and 0 or getdata(a.__ClassName, "CamShakeMagnitude")
		end
		if a.__ClassName == "Taser" and getdata(a.__ClassName, "ReloadTimeHit") ~= nil and getdata(a.__ClassName, "ReloadTime") ~= nil then
			a.Config.ReloadTimeHit = configs.combat.tasermodz and 0 or getdata(a.__ClassName, "ReloadTimeHit")
			a.Config.ReloadTime = configs.combat.tasermodz and 0 or getdata(a.__ClassName, "ReloadTime")
		end
		if a and a.BulletEmitter and a.BulletEmitter.GravityVector then
			a.BulletEmitter.GravityVector = configs.combat.nobulletg and nil or Vector3.new(0, -workspace.Gravity / 10, 0)
		end
		if a.__ClassName == "ForcefieldLauncher" then
			a.Config.Reload = configs.combat.forcefieldreload and 0 or 4
		end
	end)
	
	task.spawn(function()
		while true do task.wait(.1)
			pcall(function()
				local humanoid = game:GetService("Players").LocalPlayer.Character.Humanoid or nil
				local gvp = require(game:GetService("ReplicatedStorage").Vehicle.VehicleUtils).GetLocalVehiclePacket() or nil
				if humanoid ~= nil and gvp ~= nil and client.vehicleEntered then
					if gvp.Type == "Chassis" then
						if configs.vehicle.engine then
							gvp.GarageEngineSpeed = configs.vehicle.enginesp
						end
						-- if configs.vehicle.brake then
						-- 	gvp.GarageBrakes = configs.vehicle.brakesp
						-- end
						if configs.vehicle.suspension then
							gvp.Height = configs.vehicle.suspensionhe
						end
						if configs.vehicle.turn then
							gvp.TurnSpeed = configs.vehicle.turnsp
						end
					end
				end
				if configs.player.norwait then
					table.clear(client.movementrollservice.mapLastRollTime)
				end
			end)
		end
	end)
end)

AddToggle = (function(groupboxes, txt, clbck, default, tootip) -- just to make thingz easier and cleaner
    default = default or false
	tootip = type(tootip) == "string" and tootip or false
	local tbl = {
        Text = txt;
        Default = default;
        Callback = function(a)
			task.spawn(function()
				clbck(a)
			end)
		end;
		Tooltip = tootip;
    }
	if tootip == false then 
		table.remove(tbl, 4) 
	end
    groupboxes:AddToggle(string.gsub(txt, " ", ""), tbl)
end)

AddSlider = (function(groupboxes, txt, clbck, default, min, max, round, tootip)
    default = default or false
	tootip = tootip or nil
	round = round or 0
	local tbl = {
        Text = txt;
        Default = default;
		Max = max;
		Min = min;
		Rounding  = round;
        Callback = clbck;
		Tooltip = tootip;
    }
	if tootip == nil then 
		table.remove(tbl, 4) 
	end
    groupboxes:AddSlider(string.gsub(txt, " ", ""), tbl)
end)

Library.ShowToggleFrameInKeybinds = true 
Library.ShowCustomCursor = false
Library.NotifySide = "Left"
Library.Font = Enum.Font.Code

local Window = Library:CreateWindow({
	Title = 'Codecoat',
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = false,
	NotifySide = "Left",
	TabPadding = 1,
	MenuFadeTime = 0.2,
    Size = UDim2.fromOffset(500, 385)
})

local tab = Window:AddTab("Player")

local group = tab:AddLeftGroupbox("Utilities")

configs.player.respawndeathloc = false
AddToggle(group, "Anti Ragdoll", function(a)
	configs.player.norag = a
	local hrp = game:GetService("Players").LocalPlayer.Character:WaitForChild("HumanoidRootPart") or nil
	if configs.player.norag == false and hrp ~= nil then
		hrp:RemoveTag("NoRagdoll")
	elseif configs.player.norag == true and hrp ~= nil then
		hrp:AddTag("NoRagdoll")
	end
end)
AddToggle(group, "Anti Fall Injury", function(a)
	configs.player.nofall = a
	local hrp = game:GetService("Players").LocalPlayer.Character:WaitForChild("HumanoidRootPart") or nil
	if configs.player.nofall == false and hrp ~= nil then
		hrp:RemoveTag("NoFallDamage")
	elseif configs.player.nofall == true and hrp ~= nil then
		hrp:AddTag("NoFallDamage")
	end
end)
AddToggle(group, "Anti Skydiving", function(a)
	configs.player.nosky = a
end)
AddToggle(group, "Anti Ragdoll Stun", function(a)
	configs.player.nostun = a
	client.settingss.Time.Stunned = configs.player.nostun and 0 or 5
	setupvalue(client.stunnedragdoll, 1, configs.player.nostun and nil)
end)
AddToggle(group, "Anti Injury Slow", function(a)
	configs.player.noislow = a
	setconstant(client.walkspeedfun, 8, configs.player.noislow and 1 or 0.5)
end)
AddToggle(group, "Anti Crawling Slow", function(a)
	configs.player.nocslow = a
	setconstant(client.walkspeedfun, 16, configs.player.nocslow and 1 or 0.4)
end)
AddToggle(group, "Anti Spotlight Slow", function(a)
	configs.player.nopslow = a
	setconstant(client.walkspeedfun, 31, configs.player.nospslow and "hey_plainrocky123" or "IsLocalInSpotlight")
	setconstant(client.walkspeedfun, 33, configs.player.nospslow and "yourmomma" or "IsInTrackingSpotlight")
	setconstant(client.walkspeedfun, 35, a and 0 or 0.8)
	setconstant(getproto(client.spotlightbinder._constructor.TrackPlayer, 1), 14, a and 0 or 2.5)
end)
AddToggle(group, "Anti Cell Wait", function(a)
	configs.player.nocwait = a
	if a then
		client.cellloop()
	end
end)
AddToggle(group, "No Circle Hold", function(a)
	configs.player.nocircwait = a
	setconstant(client.updateplayer, 38, a and 0 or 0.5)
end)
AddToggle(group, "Circle Anti Clipping", function(a)
	setconstant(client.circleupdateui, 32, a and "Duration" or "NoRay")
end)
AddToggle(group, "No Roll Cooldown", function(a)
	configs.player.norwait = a
	client.activeaction.roll.useEvery = configs.player.norwait and 0 or 5
	client.rollratelimiter._budgetPerWindow = configs.player.norwait and 9e9 or 10
	client.rollratelimiter._budgetWindowDuration = configs.player.norwait and 9e9 or 10
end)
AddToggle(group, "Always Sprinting", function(a)
	configs.player.alwayssp = a
	if a then
		client.sprintLoop()
	end
end)
AddToggle(group, "Infinite Jump", function(a)
	configs.player.infjump = a
end)
AddToggle(group, "Bypass Door Requirements", function(a)
	configs.player.doornoreq = a
	--client.hasKeyHook(configs.player.bypasskd)
end)
AddToggle(group, "Allow Equip When Crawling", function(a)
	configs.player.crawlequip = a
	if configs.player.crawlequip then
		client.isCrawlingLoop()
	end
end)
AddToggle(group, "Break Your Back Bone", function(a)
	configs.player.backbone = a
	if configs.player.backbone then
		client.duckLoop()
	end
end)

--local group = tab:AddRightGroupbox("Dogs") -- soon :>>>>
-- AddSlider(group, "Walk uhh", function(a) 
	
-- end, default, min, max, round)


local tab = Window:AddTab("Vehicle")

local group = tab:AddLeftGroupbox("Utilities")
AddSlider(group, "Flight Speed", function(a) 
	configs.vehicle.fspeed = a
end, 0, 0, 1000, 0)
AddSlider(group, "Flight Rotation X", function(a) 
	configs.vehicle.fx = a
end, 0, 0, 360, 0)
AddSlider(group, "Flight Rotation Y", function(a) 
	configs.vehicle.fy = a
end, 0, 0, 360, 0)
AddSlider(group, "Flight Rotation Z", function(a) 
	configs.vehicle.fz = a
end, 0, 0, 360, 0)
AddToggle(group, "Vehicle Flight", function(a)
	configs.vehicle.ftog = a
	if configs.vehicle.ftog and client.vehicleEntered == true then
		client.launchVehicleFlight()
	end
end)
AddToggle(group, "Infinite Nitro", function(a)
	configs.vehicle.infnitro = a
	if configs.vehicle.infnitro then
		client.nitroLoop()
	end
end)
AddToggle(group, "Anti Vehicle Hijack", function(a)
	configs.vehicle.alwayshij = a
	if configs.vehicle.alwayshij then
		client.hijackLoop()
	end
end)

local group = tab:AddRightGroupbox("Car")
AddSlider(group, "Engine Speed", function(a) 
	configs.vehicle.enginesp = a
end, configs.vehicle.enginesp, 1, 200, 0)
AddToggle(group, "Apply Engine Speed", function(a)
	configs.vehicle.engine = a
	if configs.vehicle.engine == false then
		client.updateToOriginalChassisStats()
	end
end)
AddSlider(group, "Suspension Height", function(a) 
	configs.vehicle.suspensionhe = a
end, configs.vehicle.suspensionhe, 1, 200, 0)
AddToggle(group, "Apply Suspension Height", function(a)
	configs.vehicle.suspension = a
	if configs.vehicle.suspension == false then
		client.updateToOriginalChassisStats()
	end
end)
AddSlider(group, "Turn Speed", function(a) 
	configs.vehicle.turnsp = a
end, configs.vehicle.turnsp, 1, 5, 1)
AddToggle(group, "Apply Turn Speed", function(a)
	configs.vehicle.turn = a
	if configs.vehicle.turn == false then
		client.updateToOriginalChassisStats()
	end
end)
AddToggle(group, "Anti Tire Pop", function(a)
	configs.vehicle.nopop = a
end)
AddToggle(group, "Drive On Water", function(a)
	configs.vehicle.driveonwater = a
end)
AddToggle(group, "Always Flip", function(a)
	configs.vehicle.autoflip = a
	if configs.vehicle.autoflip then
		client.flipLoop()
	end
end)
AddToggle(group, "Instant Tow", function(a)
	configs.vehicle.instanttow = a
end)

local group = tab:AddRightGroupbox("Helicopter")
AddSlider(group, "Engine Forward Speed", function(a) 
	configs.vehicle.helienginesp = a / 10
end, 0, 0, 500, 0)
AddSlider(group, "Engine Vertical Speed", function(a) 
	configs.vehicle.heliverticalsp = a / 10
end, 0, 0, 300, 0)
AddToggle(group, "Apply Modification", function(a)
	configs.vehicle.heliengine = a
end)
AddToggle(group, "Instant Heli Pickup", function(a)
	configs.vehicle.helipick = a
end)
AddToggle(group, "Anti Heli Down", function(a)
	configs.vehicle.helibreak = a
end)
AddToggle(group, "Infinite Heli Height", function(a)
	configs.vehicle.heliheight = a
end)

local group = tab:AddRightGroupbox("Motorbike")
AddSlider(group, "Speed Multiplier", function(a) 
	setconstant(client.alexchassis2.UpdateHQ, 76, 1.2 + a)
end, 0, 0, 100, 0)
AddSlider(group, "Suspension Height Multiplier", function(a) 
	setconstant(client.motorupdatewheel, 16, a)
end, 0, 0, 50, 0)

local group = tab:AddRightGroupbox("Tank")
-- AddSlider(group, "Engine Speed Multiplier", function(a) 
-- 	configs.vehicle.tankenginesp = a
-- end, 0, 0, 500, 0)
-- AddToggle(group, "Apply Engine Speed", function(a)
-- 	print(configs.vehicle.tankenginesp)
-- 	setconstant(getproto(client.tankbinder._handleSeatedDriver, 4), 20, tonumber(configs.vehicle.tankenginesp))
-- 	print(getconstant(getproto(client.tankbinder._handleSeatedDriver, 4), 20))
-- end)
AddSlider(group, "Tracks Height", function(a) 
	setconstant(client.tankbinder._buildWheelWorld, 28, 5.3 + a)
end, 0, 0, 50, 0)

local group = tab:AddRightGroupbox("Volt")
AddSlider(group, "Speed Multiplier", function(a) 
	configs.vehicle.voltenginesp = a
end, 0, 0, 25, 0)
AddSlider(group, "Wheel Height", function(a) 
	setconstant(client.vclasses.Volt.VehicleEnter, 30, 6.5 + a)
end, 0, 0, 19, 0)

local tab = Window:AddTab("Combat")

local group = tab:AddLeftGroupbox("Utilities")
AddToggle(group, "Always Auto", function(a)
	configs.combat.alwaysauto = a
end)
AddToggle(group, "Anti Recoil", function(a)
	configs.combat.norecoil = a
end)
AddToggle(group, "Anti Spread", function(a)
	configs.combat.nospread = a
end)
AddToggle(group, "Anti Equip Time", function(a)
	configs.combat.noequipt = a
end)
AddToggle(group, "Bullet Criticals", function(a)
	configs.combat.alwaysheadshot = a
end)
AddToggle(group, "Instant Bullet Hit", function(a)
	configs.combat.instantbullethit = a
end)
AddToggle(group, "Increase Takedown Damage", function(a)
	configs.combat.increasetakedowndamage = a
end)
AddToggle(group, "Increase Forcefield Damage", function(a)
	configs.combat.increaseforcedamage = a
end)
AddToggle(group, "Shoot Through Wall", function(a)
	configs.combat.wallbang = a
end)
AddToggle(group, "Shoot Through Forcefield", function(a)
	configs.combat.shootthroughforce =a
	setconstant(client.bulletemitter.Update, 26, configs.combat.shootthroughforce and 0 or 1)
end)
AddToggle(group, "Rocket Instant Seek", function(a)
	configs.combat.instantrocketseek = a
	client.rocketconsts.SEEKING_LOCK_MIN_DURATION = configs.combat.instantrocketseek and 0 or 2
end)
AddToggle(group, "Free Pistol Swat", function(a)
	configs.combat.pistolswat = a
end)
AddToggle(group, "Fast Taser", function(a)
	configs.combat.tasermodz = a
end)
AddToggle(group, "Faster Forcefield Reload", function(a)
	configs.combat.forcefieldreload = a
end)
AddToggle(group, "Anti Forcefield Misses", function(a)
	configs.combat.forcefieldnomiss = a
end)
AddToggle(group, "Anti Smoke Grenande Effect", function(a)
	configs.combat.nogrenadesmoke = a
	client.smokeGrenadeHook(a)
end)
AddToggle(group, "Anti Smoke Grenade Limit", function(a)
	configs.combat.nogrenadesmokelimit = a
	setconstant(client.gethrowablesmokegrenade, 6, a and 0 or 1)
end)

local group = tab:AddLeftGroupbox("Melee")
AddToggle(group, "Anti Reload Time", function(a)
	configs.combat.batonsword.noreloadtime = a
	if configs.combat.batonsword.noreloadtime then
		client.setBatonSwordTime(configs.combat.batonsword.noreloadtime)
	end
end)
AddToggle(group, "Always Swoosh", function(a)
	configs.combat.batonsword.spamswoosh = a
	if configs.combat.batonsword.spamswoosh then
		client.spamBatonSwordSwoosh()
	end
end)
AddToggle(group, "Always Lunge", function(a)
	configs.combat.batonsword.spamlunge = a
	if configs.combat.batonsword.spamlunge then
		client.spamBatonSwordLunge()
	end
end)

local group = tab:AddRightGroupbox("Silent Aim")
AddToggle(group, "Enabled", function(a)
	configs.combat.silentaim.enabled = a
end)
AddToggle(group, "Wallcheck", function(a)
	configs.combat.silentaim.wallcheck = a
end)
AddToggle(group, "Include Taser", function(a)
	configs.combat.silentaim.includetaser = a
end)
AddToggle(group, "Include Plasma", function(a)
	configs.combat.silentaim.includeplasma = a
end)
AddToggle(group, "FOV Circle", function(a)
	configs.combat.silentaim.fovcirc = a
	Circle.Visible = a
	CircleOutline.Visible = a
end)
AddToggle(group, "FOV Circle Filled", function(a)
	CircleFilled.Visible = a
end)
AddSlider(group, "Radius", function(a) 
	configs.combat.silentaim.radius = a
	Circle.Radius = a
	CircleOutline.Radius = a + 2
	CircleFilled.Radius = a - 1
end, 50, 10, 1000, 0)

local group = tab:AddRightGroupbox("Arrest Aura")
AddToggle(group, "Enabled", function(a)
	configs.combat.arrestaura.enabled = a
	if configs.combat.arrestaura.enabled then
		client.launchArrestAura()
	end	
end)

local group = tab:AddRightGroupbox("Gun Store")
AddToggle(group, "Get All Owned Gun On Respawn", function(a)
	configs.combat.getweapon = a
end)
group:AddButton({
	Text = 'Get All Owned Gun',
	Func = function()
		client.getallgun()
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true
})
group:AddButton({
	Text = 'Open Gunstore UI',
	Func = function()
		client.showgunstore()
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true
})

-- local group = tab:AddRightGroupbox("Hitboxes")
-- AddSlider(group, "Radius", function(a) 
-- 	configs.combat.hitboxradius = a
-- 	client.changeHitboxRadius(configs.combat.hitboxradius)
-- end, 50, 10, 1000, 0)

local tab = Window:AddTab("Visual")
local group = tab:AddLeftGroupbox("ESP Options")
AddToggle(group, "Enabled", function(a)
	MainESP.Options.Enabled = a
end)
AddToggle(group, "Box", function(a)
	MainESP.Options.Box = a
end)
AddToggle(group, "Tracer", function(a)
	MainESP.Options.Tracer = a
end)
AddToggle(group, "Name", function(a)
	MainESP.Options.Name = a
end)
AddToggle(group, "Distance", function(a)
	MainESP.Options.Distance = a
end)
AddToggle(group, "Health", function(a)
	MainESP.Options.Health = a
end)
AddToggle(group, "Skeleton", function(a)
	MainESP.Options.Skeleton = a
end)
local group = tab:AddRightGroupbox("ESP Settings")
AddToggle(group, "Team Check", function(a)
	MainESP.Options.Enabled = a
end)
AddToggle(group, "Use Team Color", function(a)
	MainESP.Options.UseTeamColor = a
end, true)
AddToggle(group, "Rainbow", function(a)
	MainESP.Options.Rainbow = a
end)
AddToggle(group, "Text Outline", function(a)
	MainESP.Options.TextOutline = a
end)
AddSlider(group, "Text Size", function(a) 
	MainESP.Options.FontSize = a
end, 15, 1, 50, 0)
group:AddDropdown('TracerOrigins', {
	Values = {"Top","Middle","Bottom"},
	Default = 1, 
	Multi = false, 
	Text = "Tracer Origins",
	Searchable = false,
	Callback = function(Value)
		MainESP.Options.TracerOrigin = Value
	end,
	Visible = true, -- Will make the dropdown invisible (true / false)
})
local tab = Window:AddTab("Others")
local group = tab:AddLeftGroupbox("Protections")
AddToggle(group, "Disable Lasers", function(a)
	configs.others.disablelaser = a
	if a then
		client.barbedwireloop()
	end
	task.delay(0.1, function()
		client.barbedwiremodify(false)
	end)
end)
AddToggle(group, "Disable Home Turret", function(a)
	configs.others.disablehometurret = a
	client.getNearestPlayerHook(a)
end)
AddToggle(group, "Disable Military Turret", function(a)
	configs.others.disablehometurret = a
	client.militaryturretconst.FIRE_RATE = a and 9e9 or 0.1
end)
AddToggle(group, "Disable Guard Damage", function(a)
	configs.others.guardnodmg = a
	setconstant(client.guardnpcbinder._onItemEquipped, 8, a and "yeafuckyou" or "IgnoreLocalPlayer")
	if a then
		client.npcnodamageloop()
	end
	client.setnpcignorelp(true)
end)
local group = tab:AddLeftGroupbox("Fun")
AddToggle(group, "Open All Doors & Gates", function(a)
	configs.others.opendoor = a
	if a then
		client.opendoorloop()
	end
end)
AddToggle(group, "Open All Sewer Hatch", function(a)
	configs.others.opensewer = a
	if a then
		client.oepnsewerloop()
	end
end)
AddToggle(group, "Break Prison Elevator", function(a)
	configs.others.prisonelevator = a
	if a then
		client.prisonelevatorloop()
	else
		client.callprisonelevator(2)
	end
end)
local group = tab:AddRightGroupbox("Oil Rig")
AddToggle(group, "Disable Turret", function(a)
	setconstant(client.turret.ShootLaser, 31, a and 9e9 or 0.5)
end)
AddToggle(group, "Disable Self Destruct", function(a)
	client.oilexplosion.Name = a and "plainrocky123" or "Explosion"
	print(client.oilexplosion.Name)
end)


local group = tab:AddRightGroupbox("Cargo Ship")
AddToggle(group, "Disable Turret", function(a)
	setconstant(client.turret.ShootRocket, 16, a and "yousuck" or "Launch")
end)


-- config system is kinda buggy on linoria soo some features probably won't automatically set to saved config system
local tab = Window:AddTab("⚙️")
local MenuGroup = tab:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Join Our Discord For Receiving The Latest News About Codecoat!", true)
MenuGroup:AddButton("Copy Discord Invite", function() 
	if setclipboard == nil then
		Library:Notify("Copy Discord Invite Failed!, Missing Function: setclipboard")
		return
	end
	setclipboard("https://discord.gg/R82qYWkAsh")
	Library:Notify("Success!")
end)
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder('Codecoat')
SaveManager:SetFolder('Codecoat/Jailbreak')
SaveManager:BuildConfigSection(tab)
ThemeManager:ApplyToTab(tab)
SaveManager:LoadAutoloadConfig()
-- simple fixes for weapon camera lock not working cuz of linoria library having some guibutton modal turned on for some reason
loadstring(game:HttpGet('https://pastebin.pl/view/raw/8e1e69d5'))() -- don't open the link
--SaveManager:SetSubFolder('specific-place')
--[[
AddToggle(group, "", function(a)
	print(a)
end)
AddSlider(group, "", function(a) 
	
end, default, min, max, round)

]]
