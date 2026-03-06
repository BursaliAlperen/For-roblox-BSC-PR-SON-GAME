-- ============================================================
-- BSC PRISON | BSCServer.lua
-- ServerScriptService > BSCServer (Script)
-- Ana Sunucu: RemoteEvents, DataStore, Takım, İsyan, Solve
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
local CharacterStore = DataStoreService:GetDataStore("BSCPrison_Characters_v1")
local RiotStore      = DataStoreService:GetDataStore("BSCPrison_Riot_v1")

-- ─────────────────────────────────────────────
-- REMOTE EVENTS KURULUMU
-- ─────────────────────────────────────────────
local Remotes = Instance.new("Folder")
Remotes.Name = "BSCRemotes"
Remotes.Parent = ReplicatedStorage

local function makeRemote(name, isFunction)
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

-- RemoteEvents
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

-- RemoteFunctions
local RF_GetCharData     = makeRemote("GetCharacterData", true)
local RF_GetPlayerBonds  = makeRemote("GetPlayerBonds", true)

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

-- Takımları oluştur
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
local PlayerData = {}  -- [userId] = {charData, team, bonds, isRioting}

local function getPlayerData(player)
	local uid = tostring(player.UserId)
	if not PlayerData[uid] then
		PlayerData[uid] = {
			charData  = nil,
			team      = nil,
			bonds     = {},
			isRioting = false,
		}
	end
	return PlayerData[uid]
end

-- ─────────────────────────────────────────────
-- KARAKTER OLUŞTURMA
-- ─────────────────────────────────────────────
RE_CreateCharacter.OnServerEvent:Connect(function(player, charData)
	if typeof(charData) ~= "table" then return end

	-- Veri doğrulama
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

	age = math.clamp(age, 18, 80)

	local cleanData = {
		firstName = firstName,
		lastName  = lastName,
		age       = age,
		gender    = gender,
		hairIndex = hairIndex,
		faceIndex = faceIndex,
		createdAt = os.time(),
	}

	-- DataStore'a kaydet
	local uid = tostring(player.UserId)
	local success, err = pcall(function()
		CharacterStore:SetAsync(uid, cleanData)
	end)

	if success then
		local pData = getPlayerData(player)
		pData.charData = cleanData
		print("[BSC Prison] Karakter kaydedildi:", player.Name, firstName, lastName)
	else
		warn("[BSC Prison] DataStore hatası:", err)
		RE_Notification:FireClient(player, "⚠  Kayıt hatası! Tekrar deneyin.", "danger")
	end
end)

-- Karakter verisi sorgulama
RF_GetCharData.OnServerInvoke = function(player)
	local uid = tostring(player.UserId)
	local pData = getPlayerData(player)

	if pData.charData then
		return pData.charData
	end

	-- DataStore'dan yükle
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
	if not TEAM_DATA[teamId] then
		RE_Notification:FireClient(player, "⚠  Geçersiz takım!", "danger")
		return
	end

	local pData = getPlayerData(player)
	pData.team = teamId

	-- Takıma ata
	local team = teamObjects[teamId]
	if team then
		player.Team = team
		player.TeamColor = team.TeamColor
	end

	-- Karakteri yeniden spawn et
	if player.Character then
		player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health == 0 or player:LoadCharacter()
	end

	print("[BSC Prison] Takım atandı:", player.Name, "→", teamId)
	RE_Notification:FireClient(player, "✅  " .. TEAM_DATA[teamId].name .. " takımına katıldınız!", "success")
end)

-- ─────────────────────────────────────────────
-- İSYAN SİSTEMİ
-- ─────────────────────────────────────────────
local activeRioters = {}

RE_StartRiot.OnServerEvent:Connect(function(player)
	local pData = getPlayerData(player)

	if pData.team ~= "prisoner" and pData.team ~= "criminal" then
		RE_Notification:FireClient(player, "⚠  Bu takım isyan edemez!", "danger")
		return
	end

	if pData.isRioting then
		RE_Notification:FireClient(player, "⚠  Zaten isyanda!", "warning")
		return
	end

	pData.isRioting = true
	activeRioters[player.UserId] = true

	print("[BSC Prison] İsyan başladı:", player.Name)

	-- Tüm polislere bildir
	for _, p in ipairs(Players:GetPlayers()) do
		local pd = getPlayerData(p)
		if pd.team == "cop" then
			RE_RiotAlert:FireClient(p, player.Name .. " isyan başlattı!", player.Name)
		end
	end

	-- DataStore'a kaydet
	pcall(function()
		RiotStore:SetAsync(tostring(player.UserId), {
			isRioting = true,
			startTime = os.time(),
		})
	end)
end)

-- ─────────────────────────────────────────────
-- BAĞLAMA SİSTEMİ
-- ─────────────────────────────────────────────
local BOND_TYPES = {
	handcuffs = {name = "El Kelepçesi", solveTime = 5,  icon = "⛓"},
	rope      = {name = "İp",           solveTime = 8,  icon = "🪢"},
	collar    = {name = "Tasma",        solveTime = 6,  icon = "🔗"},
	tape      = {name = "Bant",         solveTime = 4,  icon = "🩹"},
}

RE_BindPlayer.OnServerEvent:Connect(function(binder, targetPlayer, bondType)
	if not BOND_TYPES[bondType] then return end

	local binderData = getPlayerData(binder)
	local targetData = getPlayerData(targetPlayer)

	-- Yetki kontrolü (cop, criminal bağlayabilir)
	if binderData.team ~= "cop" and binderData.team ~= "criminal" then
		RE_Notification:FireClient(binder, "⚠  Bu takım bağlayamaz!", "danger")
		return
	end

	-- Bağ ekle
	if not targetData.bonds[bondType] then
		targetData.bonds[bondType] = {
			bondType  = bondType,
			boundBy   = binder.Name,
			boundAt   = os.time(),
		}

		-- Hedef oyuncuya bildir
		RE_Notification:FireClient(targetPlayer, "⛓  " .. binder.Name .. " sizi " .. BOND_TYPES[bondType].name .. " ile bağladı!", "warning")
		RE_UpdateBonds:FireClient(targetPlayer, targetData.bonds)

		-- Bağlayan oyuncuya bildir
		RE_Notification:FireClient(binder, "✅  " .. targetPlayer.Name .. " bağlandı!", "success")

		print("[BSC Prison] Bağlandı:", targetPlayer.Name, "←", binder.Name, "(", bondType, ")")
	end
end)

-- ─────────────────────────────────────────────
-- SOLVE (BAĞ ÇÖZME)
-- ─────────────────────────────────────────────
RE_SolveBond.OnServerEvent:Connect(function(player, bondId)
	local pData = getPlayerData(player)

	if not pData.bonds[bondId] then
		RE_Notification:FireClient(player, "⚠  Bu bağ bulunamadı!", "danger")
		return
	end

	-- Bağı kaldır
	pData.bonds[bondId] = nil
	RE_UpdateBonds:FireClient(player, pData.bonds)
	RE_Notification:FireClient(player, "✅  " .. (BOND_TYPES[bondId] and BOND_TYPES[bondId].name or bondId) .. " çözüldü!", "success")

	print("[BSC Prison] Bağ çözüldü:", player.Name, "(", bondId, ")")
end)

-- Bağ sorgulama
RF_GetPlayerBonds.OnServerInvoke = function(player)
	local pData = getPlayerData(player)
	return pData.bonds or {}
end

-- ─────────────────────────────────────────────
-- EMOTE SİSTEMİ
-- ─────────────────────────────────────────────
RE_PlayEmote.OnServerEvent:Connect(function(player, animId)
	-- Animasyon ID doğrulama (sayısal olmalı)
	local id = tonumber(animId)
	if not id then return end

	-- Karaktere animasyon oynat
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)

	local track = animator:LoadAnimation(anim)
	track:Play()

	-- Diğer oyunculara da yayınla (isteğe bağlı)
	-- RE_PlayEmote:FireAllClients(player, animId)
end)

-- ─────────────────────────────────────────────
-- OYUNCU GİRİŞ / ÇIKIŞ
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	print("[BSC Prison] Oyuncu katıldı:", player.Name)

	-- Karakter yüklendiğinde
	player.CharacterAdded:Connect(function(character)
		local pData = getPlayerData(player)

		-- Karakter görünümünü ayarla (cinsiyet bazlı)
		task.wait(1)
		if pData.charData then
			local gender = pData.charData.gender
			-- R6 / R15 rig ayarı sunucu tarafında yapılabilir
			-- Şimdilik temel ayar
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if gender == "female" then
					humanoid.RigType = Enum.HumanoidRigType.R6
				else
					humanoid.RigType = Enum.HumanoidRigType.R6
				end
			end
		end
	end)

	-- Karakter verisi var mı kontrol et
	task.spawn(function()
		task.wait(2)
		local uid = tostring(player.UserId)
		local success, data = pcall(function()
			return CharacterStore:GetAsync(uid)
		end)

		if success and data then
			local pData = getPlayerData(player)
			pData.charData = data
			print("[BSC Prison] Mevcut karakter yüklendi:", player.Name)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = tostring(player.UserId)
	PlayerData[uid] = nil
	activeRioters[player.UserId] = nil
	print("[BSC Prison] Oyuncu ayrıldı:", player.Name)
end)

-- ─────────────────────────────────────────────
-- SUNUCU DÖNGÜSÜ (İsyan takibi vb.)
-- ─────────────────────────────────────────────
local riotCheckInterval = 30
local lastRiotCheck = 0

RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastRiotCheck >= riotCheckInterval then
		lastRiotCheck = now

		-- İsyan eden oyuncuları kontrol et
		local rioterCount = 0
		for _ in pairs(activeRioters) do rioterCount = rioterCount + 1 end

		if rioterCount > 0 then
			-- Tüm polislere periyodik uyarı
			for _, p in ipairs(Players:GetPlayers()) do
				local pd = getPlayerData(p)
				if pd.team == "cop" then
					RE_RiotAlert:FireClient(p, rioterCount .. " isyancı aktif!", nil)
				end
			end
		end
	end
end)

print("[BSC Prison] BSCServer başlatıldı! ✅")
print("[BSC Prison] Sunucu hazır.")
