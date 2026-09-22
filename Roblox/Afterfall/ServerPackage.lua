-- AFTERFALL: THE LAST SHIFT
-- GitHub-hosted server package. Loaded by ServerBootstrap.server.lua.
-- Server authoritative prototype: stats, inventory, crafting, combat, zombies, loot, persistence.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local GAME_TITLE = "AFTERFALL"
local GAME_SUBTITLE = "THE LAST SHIFT"
local DATASTORE_NAME = "Afterfall_PlayerData_v1"

local ITEMS = {
	Scrap = {name="SCRAP", max=999, icon="▣"},
	Cloth = {name="CLOTH", max=999, icon="▤"},
	Wood = {name="WOOD", max=999, icon="▥"},
	Medkit = {name="MEDKIT", max=20, icon="+"},
	Ammo9 = {name="9MM", max=999, icon="•"},
	Water = {name="WATER", max=20, icon="◇"},
	Food = {name="FOOD", max=20, icon="▦"},
	Battery = {name="BATTERY", max=99, icon="▰"},
	Bolt = {name="BOLT", max=999, icon="⌁"},
	Rag = {name="RAG", max=999, icon="≈"}
}

local RECIPES = {
	Medkit = {name="MEDKIT", out=1, needs={Cloth=3, Rag=2, Battery=1}},
	Ammo9 = {name="9MM AMMO", out=12, needs={Scrap=2, Battery=1}},
	Rag = {name="RAG", out=3, needs={Cloth=2}},
}

local DEFAULT = {
	Health=100,
	Stamina=100,
	Hunger=100,
	Thirst=100,
	XP=0,
	Level=1,
	Inventory={
		Scrap=14, Cloth=9, Wood=22, Medkit=1, Ammo9=36,
		Water=3, Food=5, Battery=3, Bolt=12, Rag=6
	}
}

local store
pcall(function()
	store = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

-- World
local world = workspace:FindFirstChild("AfterfallWorld")
if not world then
	world = Instance.new("Folder")
	world.Name = "AfterfallWorld"
	world.Parent = workspace
end

local floor = world:FindFirstChild("Ground")
if not floor then
	floor = Instance.new("Part")
	floor.Name = "Ground"
	floor.Anchored = true
	floor.Size = Vector3.new(700, 2, 700)
	floor.Position = Vector3.new(0, -1, 0)
	floor.Material = Enum.Material.Asphalt
	floor.Color = Color3.fromRGB(24, 28, 29)
	floor.Parent = world
end

local spawn = workspace:FindFirstChild("AfterfallSpawn")
if not spawn then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "AfterfallSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(90, 74, 45)
	spawn.Material = Enum.Material.Metal
	spawn.Parent = workspace
end

Lighting.ClockTime = 2.5
Lighting.Brightness = 1.1
Lighting.FogColor = Color3.fromRGB(17, 23, 26)
Lighting.FogStart = 80
Lighting.FogEnd = 420
pcall(function()
	Lighting.Ambient = Color3.fromRGB(44, 48, 49)
	Lighting.OutdoorAmbient = Color3.fromRGB(24, 28, 30)
end)

-- Remote surface
local remotes = ReplicatedStorage:FindFirstChild("AfterfallRemotes")
if remotes then remotes:Destroy() end
remotes = Instance.new("Folder")
remotes.Name = "AfterfallRemotes"
remotes.Parent = ReplicatedStorage

local getBoot = Instance.new("RemoteFunction")
getBoot.Name = "GetBoot"
getBoot.Parent = remotes

local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = remotes

local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes

local notice = Instance.new("RemoteEvent")
notice.Name = "Notice"
notice.Parent = remotes

local playerState = {}
local zombies = {}
local rng = Random.new()

local function cloneDefault()
	return {
		Health=DEFAULT.Health, Stamina=DEFAULT.Stamina,
		Hunger=DEFAULT.Hunger, Thirst=DEFAULT.Thirst,
		XP=DEFAULT.XP, Level=DEFAULT.Level,
		Inventory=table.clone(DEFAULT.Inventory)
	}
end

local function notify(player, title, text, kind)
	notice:FireClient(player, {title=title, text=text, kind=kind or "info"})
end

local function sanitize(data)
	if type(data) ~= "table" then return cloneDefault() end
	local out = cloneDefault()
	for _, key in ipairs({"Health","Stamina","Hunger","Thirst","XP","Level"}) do
		if type(data[key]) == "number" then out[key] = data[key] end
	end
	if type(data.Inventory) == "table" then
		for id, amount in pairs(out.Inventory) do
			local n = data.Inventory[id]
			if type(n) == "number" then out.Inventory[id] = math.clamp(math.floor(n), 0, ITEMS[id].max) end
		end
	end
	return out
end

local function loadPlayer(player)
	local data = cloneDefault()
	if store then
		local ok, result = pcall(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
		if ok and result then data = sanitize(result) end
	end
	playerState[player] = data
	player:SetAttribute("AFTERFALL_READY", true)
end

local function savePlayer(player)
	local data = playerState[player]
	if not data or not store then return end
	pcall(function()
		store:UpdateAsync("u_" .. player.UserId, function()
			return data
		end)
	end)
end

local function give(player, itemId, amount)
	local s = playerState[player]
	local def = ITEMS[itemId]
	if not s or not def then return false end
	local current = s.Inventory[itemId] or 0
	local nextAmount = math.clamp(current + amount, 0, def.max)
	s.Inventory[itemId] = nextAmount
	return nextAmount > current
end

local function take(player, itemId, amount)
	local s = playerState[player]
	if not s then return false end
	local current = s.Inventory[itemId] or 0
	if current < amount then return false end
	s.Inventory[itemId] = current - amount
	return true
end

local function distanceTo(player, position)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not root then return math.huge end
	return (root.Position - position).Magnitude
end

local function createLoot(position, itemId, amount)
	local bag = Instance.new("Part")
	bag.Name = "Loot"
	bag.Shape = Enum.PartType.Ball
	bag.Size = Vector3.new(1.2,1.2,1.2)
	bag.Material = Enum.Material.Metal
	bag.Color = Color3.fromRGB(168, 123, 53)
	bag.Anchored = false
	bag.Position = position + Vector3.new(0, 1.2, 0)
	bag:SetAttribute("Interactable", true)
	bag:SetAttribute("LootItem", itemId)
	bag:SetAttribute("LootAmount", amount)
	bag:SetAttribute("UseText", "TAKE " .. ITEMS[itemId].name)
	bag.Parent = world
	task.delay(180, function()
		if bag and bag.Parent then bag:Destroy() end
	end)
end

local function makeZombie(position, level)
	local model = Instance.new("Model")
	model.Name = "Walker"
	model:SetAttribute("AfterfallZombie", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2,2,1)
	root.Transparency = 1
	root.CanCollide = true
	root.Position = position + Vector3.new(0,3,0)
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.2,2.3,1.2)
	torso.Color = Color3.fromRGB(76, 93, 78)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Position = position + Vector3.new(0,3.1,0)
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5,1.5,1.5)
	head.Color = Color3.fromRGB(124, 139, 118)
	head.Material = Enum.Material.SmoothPlastic
	head.Position = position + Vector3.new(0,5,0)
	head.Parent = model

	local armL = Instance.new("Part")
	armL.Name = "LeftArm"
	armL.Size = Vector3.new(0.65,2.6,0.65)
	armL.Color = torso.Color
	armL.Position = position + Vector3.new(-1.45,3.0,0)
	armL.Parent = model

	local armR = armL:Clone()
	armR.Name = "RightArm"
	armR.Position = position + Vector3.new(1.45,3.0,0)
	armR.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "WALKER"
	humanoid.MaxHealth = 90 + level*10
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 11 + math.min(level,8)*0.5
	humanoid.Parent = model

	local function weld(a,b)
		local w = Instance.new("WeldConstraint")
		w.Part0 = a
		w.Part1 = b
		w.Parent = a
	end
	weld(root, torso)
	weld(root, head)
	weld(root, armL)
	weld(root, armR)

	model.PrimaryPart = root
	model.Parent = world
	zombies[model] = {damage=8 + level, target=nil, lastAttack=0}

	humanoid.Died:Connect(function()
		local pos = root.Position
		zombies[model] = nil
		createLoot(pos, rng:NextNumber() < 0.7 and "Scrap" or "Cloth", rng:NextInteger(2,6))
		local xp = 20 + level * 5
		for _, p in ipairs(Players:GetPlayers()) do
			if distanceTo(p, pos) <= 35 and playerState[p] then
				playerState[p].XP += xp
				if playerState[p].XP >= playerState[p].Level * 100 then
					playerState[p].XP -= playerState[p].Level * 100
					playerState[p].Level += 1
					notify(p, "LEVEL UP", "SURVIVOR LEVEL " .. playerState[p].Level, "success")
				end
				notify(p, "WALKER DOWN", "+" .. xp .. " XP", "info")
			end
		end
		task.delay(2, function()
			if model then model:Destroy() end
		end)
	end)

	return model
end

local function nearestPlayer(pos)
	local best, bestDist
	for _, p in ipairs(Players:GetPlayers()) do
		local d = distanceTo(p, pos)
		if d < (bestDist or 100000) then
			best, bestDist = p, d
		end
	end
	return best, bestDist
end

local function spawnWave(count)
	local players = Players:GetPlayers()
	if #players == 0 then return end
	for i=1,count do
		local p = players[((i-1) % #players) + 1]
		local c = p.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root then
			local angle = (i / count) * math.pi * 2
			local radius = rng:NextInteger(55,85)
			makeZombie(root.Position + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius), playerState[p] and playerState[p].Level or 1)
		end
	end
end

getBoot.OnServerInvoke = function(player)
	return {
		game = {title=GAME_TITLE, subtitle=GAME_SUBTITLE, version="0.9.0-alpha"},
		colors = {
			bg=Color3.fromRGB(7,10,12), panel=Color3.fromRGB(13,18,21),
			panel2=Color3.fromRGB(19,27,31), text=Color3.fromRGB(237,242,244),
			muted=Color3.fromRGB(131,145,152), line=Color3.fromRGB(52,66,73),
			accent=Color3.fromRGB(230,180,74), danger=Color3.fromRGB(223,74,79),
			info=Color3.fromRGB(125,211,222), success=Color3.fromRGB(116,211,154)
		},
		items=ITEMS,
		recipes=RECIPES
	}
end

getState.OnServerInvoke = function(player)
	local s = playerState[player]
	if not s then return cloneDefault() end
	return {
		Health=s.Health, Stamina=s.Stamina, Hunger=s.Hunger,
		Thirst=s.Thirst, XP=s.XP, Level=s.Level, Inventory=s.Inventory
	}
end

local function handleAttack(player, payload)
	if type(payload) ~= "table" or typeof(payload.direction) ~= "Vector3" then return end
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local head = c and c:FindFirstChild("Head")
	if not root or not head then return end
	local dir = payload.direction
	if dir.Magnitude < 0.5 then return end
	dir = dir.Unit

	local rayOrigin = head.Position
	local rayDir = dir * 95
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {c}

	local hit = workspace:Raycast(rayOrigin, rayDir, params)
	if not hit then return end

	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	local targetHum = model and model:FindFirstChildOfClass("Humanoid")
	if targetHum and model:GetAttribute("AfterfallZombie") == true and targetHum.Health > 0 then
		local targetRoot = model:FindFirstChild("HumanoidRootPart")
		if targetRoot and (targetRoot.Position - root.Position).Magnitude <= 100 then
			targetHum:TakeDamage(25)
		end
	end
end

local function handleUse(player, payload)
	if type(payload) ~= "table" or typeof(payload.target) ~= "Instance" then return end
	local target = payload.target
	if not target:IsDescendantOf(workspace) then return end
	if target:GetAttribute("Interactable") ~= true then return end
	if distanceTo(player, target.Position) > 12 then return end
	local itemId = target:GetAttribute("LootItem")
	local amount = target:GetAttribute("LootAmount")
	if itemId and amount then
		if give(player, itemId, amount) then
			notify(player, "PICKUP", "+" .. amount .. " " .. ITEMS[itemId].name, "success")
			target:Destroy()
		end
	end
end

local function handleCraft(player, recipeId)
	local recipe = RECIPES[recipeId]
	if not recipe then return end
	for itemId, amount in pairs(recipe.needs) do
		if (playerState[player].Inventory[itemId] or 0) < amount then
			notify(player, "CRAFTING", "MISSING " .. ITEMS[itemId].name, "danger")
			return
		end
	end
	for itemId, amount in pairs(recipe.needs) do take(player, itemId, amount) end
	give(player, recipeId, recipe.out)
	notify(player, "CRAFTED", recipe.name .. " x" .. recipe.out, "success")
end

action.OnServerEvent:Connect(function(player, kind, payload)
	local s = playerState[player]
	if not s then return end

	if kind == "ATTACK" then
		handleAttack(player, payload)
	elseif kind == "USE" then
		handleUse(player, payload)
	elseif kind == "CRAFT" then
		if type(payload) == "string" then handleCraft(player, payload) end
	elseif kind == "SPRINT" then
		local enabled = payload == true
		player:SetAttribute("AfterfallSprinting", enabled)
	elseif kind == "CROUCH" then
		player:SetAttribute("AfterfallCrouching", payload == true)
	elseif kind == "CONSUME" then
		local itemId = type(payload) == "string" and payload or ""
		if itemId == "Water" and take(player, "Water", 1) then
			s.Thirst = math.min(100, s.Thirst + 30)
			notify(player, "CONSUMED", "WATER", "info")
		elseif itemId == "Food" and take(player, "Food", 1) then
			s.Hunger = math.min(100, s.Hunger + 28)
			notify(player, "CONSUMED", "FOOD", "info")
		elseif itemId == "Medkit" and take(player, "Medkit", 1) then
			s.Health = math.min(100, s.Health + 40)
			local c = player.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if h then h.Health = math.min(h.MaxHealth, h.Health + 40) end
			notify(player, "MEDICAL", "+40 HEALTH", "success")
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	loadPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid")
		hum.WalkSpeed = 14
		hum.HealthChanged:Connect(function(value)
			if playerState[player] then playerState[player].Health = value end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	playerState[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		for player, s in pairs(playerState) do
			if player.Parent then
				local sprinting = player:GetAttribute("AfterfallSprinting") == true
				local crouching = player:GetAttribute("AfterfallCrouching") == true
				if sprinting and s.Stamina > 0 then
					s.Stamina = math.max(0, s.Stamina - 1.25)
				else
					s.Stamina = math.min(100, s.Stamina + 0.75)
				end
				s.Hunger = math.max(0, s.Hunger - 0.012)
				s.Thirst = math.max(0, s.Thirst - 0.02)
				local c = player.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if hum then
					if sprinting and s.Stamina > 0 and not crouching then
						hum.WalkSpeed = 22
					elseif crouching then
						hum.WalkSpeed = 8
					else
						hum.WalkSpeed = 14
					end
					if s.Hunger <= 0 or s.Thirst <= 0 then
						hum:TakeDamage(0.5)
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(8)
		local count = 0
		for zombie in pairs(zombies) do if zombie and zombie.Parent then count += 1 end end
		if count < math.max(5, #Players:GetPlayers()*3) then
			spawnWave(math.max(2, #Players:GetPlayers()))
		end
	end
end)

RunService.Heartbeat:Connect(function()
	for zombie, meta in pairs(zombies) do
		if zombie and zombie.Parent then
			local root = zombie:FindFirstChild("HumanoidRootPart")
			local hum = zombie:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local target, dist = nearestPlayer(root.Position)
				if target and dist < 100 then
					meta.target = target
					local tc = target.Character
					local tr = tc and tc:FindFirstChild("HumanoidRootPart")
					local th = tc and tc:FindFirstChildOfClass("Humanoid")
					if tr and th and th.Health > 0 then
						hum:MoveTo(tr.Position)
						if dist <= 3.8 and os.clock() - meta.lastAttack > 1.15 then
							meta.lastAttack = os.clock()
							th:TakeDamage(meta.damage)
						end
					end
				end
			end
		end
	end
end)

print("[AFTERFALL] Server package active.")
