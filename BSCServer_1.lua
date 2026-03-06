-- ============================================================
-- BSC PRISON | BSCServer.lua
-- ServerScriptService > BSCServer (Script)
-- Ana Sunucu: RemoteEvents, DataStore, Takım, İsyan, Solve, Collar/Handcuff
-- ============================================================

local Players          = game:GetService("Players")
local Teams            = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

-- ─────────────────────────────────────────────
-- DATA STORE
-- ─────────────────────────────────────────────
local CharacterStore = DataStoreService:GetDataStore("BSCPrison_Characters_v2")
local RiotStore      = DataStoreService:GetDataStore("BSCPrison_Riot_v2")

-- ─────────────────────────────────────────────
-- REMOTE EVENTS KURULUMU
-- ─────────────────────────────────────────────
local Remotes = ReplicatedStorage:FindFirstChild("BSCRemotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "BSCRemotes"
	Remotes.Parent = ReplicatedStorage
end

local function makeRemote(name, isFunction)
	local existing = Remotes:FindFirstChild(name)
	if existing then return existing end
	
	if isFunction then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = Remotes
		return rf
	else
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = Remotes
		return re
	end
end

-- ─────────────────────────────────────────────
-- REMOTE'LARI OTOMATİK OLUŞTUR (GÜNCEL)
-- ─────────────────────────────────────────────
local RE_CreateCharacter = makeRemote("CreateCharacter")
local RE_JoinTeam        = makeRemote("JoinTeam")
local RE_StartRiot       = makeRemote("StartRiot")
local RE_SolveBond       = makeRemote("SolveBond")
local RE_PlayEmote       = makeRemote("PlayEmote")
local RE_BindPlayer      = makeRemote("BindPlayer")
local RE_UnbindPlayer    = makeRemote("UnbindPlayer")
local RE_UpdateBonds     = makeRemote("UpdateBonds")
local RE_RiotAlert       = makeRemote("RiotAlert")
local RE_Notification    = makeRemote("Notification")
local RE_CollarAction    = makeRemote("CollarAction")

-- RemoteFunctions
local RF_GetCharData     = makeRemote("GetCharacterData", true)
local RF_GetPlayerBonds  = makeRemote("GetPlayerBonds", true)

-- Eksik olabilecek Remote'ları ekle (Garanti olsun)
makeRemote("UpdateBonds")
makeRemote("RiotAlert")
makeRemote("Notification")
makeRemote("CollarAction")

print("[BSC Prison] RemoteEvents kuruldu.")

-- ─────────────────────────────────────────────
-- TAKIM KURULUMU
-- ─────────────────────────────────────────────
local TEAM_DATA = {
	cop      = {name = "Cop",      color = BrickColor.new("Bright blue"),   spawnTag = "CopSpawn"},
	prisoner = {name = "Prisoner", color = BrickColor.new("Bright yellow"), spawnTag = "PrisonerSpawn"},
	criminal = {name = "Criminal", color = BrickColor.new("Bright red"),    spawnTag = "CriminalSpawn"},
	hostage  = {name = "Hostage",  color = BrickColor.new("Bright green"),  spawnTag = "HostageSpawn"},
}

local teamObjects = {}
for id, data in pairs(TEAM_DATA) do
	local existingTeam = Teams:FindFirstChild(data.name)
	if existingTeam then
		teamObjects[id] = existingTeam
	else
		local team = Instance.new("Team")
		team.Name = data.name
		team.TeamColor = data.color
		team.AutoAssignable = false
		team.Parent = Teams
		teamObjects[id] = team
	end
end

print("[BSC Prison] Takımlar kuruldu.")

-- ─────────────────────────────────────────────
-- OYUNCU VERİ DEPOSU
-- ─────────────────────────────────────────────
local PlayerData = {}

local function getPlayerData(player)
	local uid = tostring(player.UserId)
	if not PlayerData[uid] then
		PlayerData[uid] = {
			charData  = nil,
			team      = nil,
			bonds     = {},
			isRioting = false,
			isDragging = false, -- Tasma ile çekiyor mu?
			draggedBy = nil,    -- Kim tarafından çekiliyor?
		}
	end
	return PlayerData[uid]
end

-- ─────────────────────────────────────────────
-- KARAKTER OLUŞTURMA
-- ─────────────────────────────────────────────
RE_CreateCharacter.OnServerEvent:Connect(function(player, charData)
	if typeof(charData) ~= "table" then return end

	local firstName = tostring(charData.firstName or ""):match("^%s*(.-)%s*$")
	local lastName  = tostring(charData.lastName  or ""):match("^%s*(.-)%s*$")
	local age       = tonumber(charData.age) or 18
	local gender    = charData.gender == "female" and "female" or "male"
	local hairIndex = tonumber(charData.hairIndex) or 1
	local faceIndex = tonumber(charData.faceIndex) or 1

	if #firstName < 2 or #lastName < 2 then
		RE_Notification:FireClient(player, "⚠  Geçersiz karakter verisi!", "danger")
		return
	end

	local cleanData = {
		firstName = firstName,
		lastName  = lastName,
		age       = math.clamp(age, 18, 80),
		gender    = gender,
		hairIndex = hairIndex,
		faceIndex = faceIndex,
		createdAt = os.time(),
	}

	local uid = tostring(player.UserId)
	pcall(function()
		CharacterStore:SetAsync(uid, cleanData)
	end)

	local pData = getPlayerData(player)
	pData.charData = cleanData
	RE_Notification:FireClient(player, "✅  Karakter oluşturuldu!", "success")
end)

RF_GetCharData.OnServerInvoke = function(player)
	local uid = tostring(player.UserId)
	local pData = getPlayerData(player)
	if pData.charData then return pData.charData end

	local success, data = pcall(function()
		return CharacterStore:GetAsync(uid)
	end)
	if success and data then
		pData.charData = data
		return data
	end
	return nil
end

-- ─────────────────────────────────────────────
-- TAKIM ATAMA
-- ─────────────────────────────────────────────
RE_JoinTeam.OnServerEvent:Connect(function(player, teamId)
	if not TEAM_DATA[teamId] then return end

	local pData = getPlayerData(player)
	pData.team = teamId

	local team = teamObjects[teamId]
	if team then
		player.Team = team
		player.TeamColor = team.TeamColor
	end

	player:LoadCharacter()
	RE_Notification:FireClient(player, "✅  " .. TEAM_DATA[teamId].name .. " takımına katıldınız!", "success")
end)

-- ─────────────────────────────────────────────
-- COLLAR & HANDCUFF (İPLİ SİSTEM)
-- ─────────────────────────────────────────────
local function createRope(p1, p2)
	local rope = Instance.new("RopeConstraint")
	rope.Name = "BSC_BondRope"
	rope.Visible = true
	rope.Thickness = 0.1
	rope.Color = BrickColor.new("Black")
	rope.Length = 5
	rope.Restitution = 0.5
	
	local a1 = Instance.new("Attachment", p1)
	local a2 = Instance.new("Attachment", p2)
	
	rope.Attachment0 = a1
	rope.Attachment1 = a2
	rope.Parent = p1
	return rope, a1, a2
end

RE_CollarAction.OnServerEvent:Connect(function(player, targetPlayer, actionType)
	local pData = getPlayerData(player)
	local tData = getPlayerData(targetPlayer)
	
	if not targetPlayer or not targetPlayer.Character then return end
	local char = player.Character
	local tChar = targetPlayer.Character
	
	if actionType == "attach" then
		-- Sadece Cop ve Criminal bağlayabilir
		if pData.team ~= "cop" and pData.team ~= "criminal" then return end
		
		-- Mesafe kontrolü
		if (char.PrimaryPart.Position - tChar.PrimaryPart.Position).Magnitude > 15 then
			RE_Notification:FireClient(player, "⚠  Hedef çok uzakta!", "warning")
			return
		end
		
		-- Zaten bağlı mı?
		if tData.draggedBy then return end
		
		-- İp oluştur
		local rope, a1, a2 = createRope(char.PrimaryPart, tChar:WaitForChild("UpperTorso", 5) or tChar.PrimaryPart)
		tData.draggedBy = player
		pData.isDragging = true
		
		-- Kelepçe modeli (Placeholder)
		local collarModel = Instance.new("Part")
		collarModel.Name = "CollarVisual"
		collarModel.Size = Vector3.new(1.2, 0.4, 1.2)
		collarModel.Color = Color3.fromRGB(50, 50, 50)
		collarModel.Material = Enum.Material.Metal
		collarModel.CanCollide = false
		collarModel.Parent = tChar
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = collarModel
		weld.Part1 = tChar:WaitForChild("UpperTorso", 5) or tChar.PrimaryPart
		weld.Parent = collarModel
		collarModel.CFrame = weld.Part1.CFrame
		
		RE_Notification:FireClient(targetPlayer, "⛓  " .. player.Name .. " size tasma taktı!", "danger")
		RE_Notification:FireClient(player, "✅  " .. targetPlayer.Name .. " bağlandı!", "success")
		
	elseif actionType == "release" then
		if tData.draggedBy == player then
			local rope = char.PrimaryPart:FindFirstChild("BSC_BondRope")
			if rope then rope:Destroy() end
			
			local visual = tChar:FindFirstChild("CollarVisual")
			if visual then visual:Destroy() end
			
			tData.draggedBy = nil
			pData.isDragging = false
			RE_Notification:FireClient(targetPlayer, "✅  Serbest bırakıldınız.", "success")
		end
	end
end)

-- ─────────────────────────────────────────────
-- İSYAN SİSTEMİ
-- ─────────────────────────────────────────────
local activeRioters = {}
RE_StartRiot.OnServerEvent:Connect(function(player)
	local pData = getPlayerData(player)
	if pData.team ~= "prisoner" and pData.team ~= "criminal" then return end
	if pData.isRioting then return end

	pData.isRioting = true
	activeRioters[player.UserId] = true

	for _, p in ipairs(Players:GetPlayers()) do
		local pd = getPlayerData(p)
		if pd.team == "cop" then
			RE_RiotAlert:FireClient(p, player.Name .. " isyan başlattı!", player.Name)
		end
	end
end)

-- ─────────────────────────────────────────────
-- SOLVE (BAĞ ÇÖZME)
-- ─────────────────────────────────────────────
RE_SolveBond.OnServerEvent:Connect(function(player, bondId)
	local pData = getPlayerData(player)
	if pData.draggedBy then
		-- Eğer biri tarafından çekiliyorsa bağı kopar
		local binder = pData.draggedBy
		if binder and binder.Character then
			local rope = binder.Character.PrimaryPart:FindFirstChild("BSC_BondRope")
			if rope then rope:Destroy() end
		end
		
		local visual = player.Character:FindFirstChild("CollarVisual")
		if visual then visual:Destroy() end
		
		pData.draggedBy = nil
		RE_Notification:FireClient(player, "✅  Bağı kopardınız!", "success")
	end
end)

-- ─────────────────────────────────────────────
-- OYUNCU GİRİŞ / ÇIKIŞ
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local pData = getPlayerData(player)
		task.wait(1)
		-- Karakter ayarları buraya gelebilir
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = tostring(player.UserId)
	PlayerData[uid] = nil
	activeRioters[player.UserId] = nil
end)

print("[BSC Prison] BSCServer başlatıldı! ✅")
