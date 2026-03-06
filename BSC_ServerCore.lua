-- ============================================================
-- BSC PRISON | BSC_ServerCore.lua
-- ServerScriptService > BSC_ServerCore (Script)
-- AAA Kalitesinde Sunucu Çekirdeği ve Veri Yönetimi
-- ============================================================

local BSC_ServerCore = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- ─────────────────────────────────────────────
-- DATA STORE YAPILANDIRMASI
-- ─────────────────────────────────────────────
local CORE_DATA_VERSION = "v4_AAA"
local MainStore = DataStoreService:GetDataStore("BSC_MainData_" .. CORE_DATA_VERSION)
local EconomyStore = DataStoreService:GetDataStore("BSC_Economy_" .. CORE_DATA_VERSION)

-- ─────────────────────────────────────────────
-- REMOTE EVENT & FUNCTION OTOMASYONU
-- ─────────────────────────────────────────────
local RemotesFolder = ReplicatedStorage:FindFirstChild("BSCRemotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "BSCRemotes"

local function makeRemote(name, isFunction)
	local r = isFunction and RemotesFolder:FindFirstChild(name) or RemotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
		r.Name = name
		r.Parent = RemotesFolder
	end
	return r
end

-- Tüm Remote'ları tanımla
local RE_Notification = makeRemote("Notification")
local RE_UpdateStats = makeRemote("UpdateStats")
local RE_JoinTeam = makeRemote("JoinTeam")
local RE_StartRiot = makeRemote("StartRiot")
local RE_CollarAction = makeRemote("CollarAction")
local RE_RequestDoor = makeRemote("RequestDoor")
local RE_CompleteTask = makeRemote("CompleteTask")
local RE_RequestCCTV = makeRemote("RequestCCTV")
local RE_UpdateBonds = makeRemote("UpdateBonds")
local RE_CharacterCreated = makeRemote("CharacterCreated")

local RF_GetPlayerData = makeRemote("GetPlayerData", true)
local RF_GetCharacterData = makeRemote("GetCharacterData", true)

-- ─────────────────────────────────────────────
-- OYUNCU VERİ YÖNETİMİ
-- ─────────────────────────────────────────────
local SessionData = {}

local function getInitialData(player)
	return {
		character = nil,
		team = "none",
		money = 500,
		xp = 0,
		rank = "Acemi",
		accessLevel = 0,
		isRioting = false,
		bonds = {},
		tasksCompleted = 0,
		lastSaved = os.time(),
	}
end

local function loadPlayerData(player)
	local uid = tostring(player.UserId)
	local success, data = pcall(function()
		return MainStore:GetAsync(uid)
	end)
	
	if success and data then
		SessionData[uid] = data
	else
		SessionData[uid] = getInitialData(player)
	end
	
	-- Ekonomi verilerini yükle
	local eSuccess, eData = pcall(function()
		return EconomyStore:GetAsync(uid)
	end)
	
	if eSuccess and eData then
		SessionData[uid].money = eData.money or 500
		SessionData[uid].xp = eData.xp or 0
		SessionData[uid].rank = eData.rank or "Acemi"
	end
	
	print("[BSC Server] Veriler yüklendi:", player.Name)
end

local function savePlayerData(player)
	local uid = tostring(player.UserId)
	local data = SessionData[uid]
	if not data then return end
	
	pcall(function()
		MainStore:SetAsync(uid, data)
		EconomyStore:SetAsync(uid, {
			money = data.money,
			xp = data.xp,
			rank = data.rank
		})
	end)
	print("[BSC Server] Veriler kaydedildi:", player.Name)
end

-- ─────────────────────────────────────────────
-- TAKIM VE YETKİ SİSTEMİ
-- ─────────────────────────────────────────────
local TEAM_LEVELS = {
	["cop"] = 2,
	["prisoner"] = 0,
	["criminal"] = 0,
	["hostage"] = 0,
	["admin"] = 5
}

RE_JoinTeam.OnServerEvent:Connect(function(player, teamId)
	local uid = tostring(player.UserId)
	local pData = SessionData[uid]
	if not pData then return end
	
	pData.team = teamId
	pData.accessLevel = TEAM_LEVELS[teamId] or 0
	
	-- Takım objesini bul veya oluştur (Roblox Teams Service kullanılabilir)
	local Teams = game:GetService("Teams")
	local teamObj = Teams:FindFirstChild(teamId:gsub("^%l", string.upper))
	if teamObj then
		player.Team = teamObj
	end
	
	player:LoadCharacter()
	RE_Notification:FireClient(player, "✅  Takıma katıldınız: " .. teamId, "success")
	RE_UpdateStats:FireClient(player, pData.money, pData.rank)
end)

-- ─────────────────────────────────────────────
-- KAPI VE ETKİLEŞİM (PROXIMITYPROMPT)
-- ─────────────────────────────────────────────
RE_RequestDoor.OnServerEvent:Connect(function(player, doorModel)
	if not doorModel then return end
	local pData = SessionData[tostring(player.UserId)]
	if not pData then return end
	
	local reqLevel = doorModel:GetAttribute("RequiredLevel") or 0
	local hasKeycard = player.Character:FindFirstChild("Keycard") or player.Backpack:FindFirstChild("Keycard")
	
	if pData.accessLevel >= reqLevel or (reqLevel > 0 and hasKeycard) then
		local isOpen = doorModel:GetAttribute("Open") or false
		doorModel:SetAttribute("Open", not isOpen)
		RE_RequestDoor:FireAllClients(doorModel, not isOpen)
	else
		RE_Notification:FireClient(player, "⚠  Yetki yetersiz!", "danger")
	end
end)

-- ─────────────────────────────────────────────
-- GÖREV SİSTEMİ
-- ─────────────────────────────────────────────
RE_CompleteTask.OnServerEvent:Connect(function(player, taskName, reward)
	local uid = tostring(player.UserId)
	local pData = SessionData[uid]
	if not pData then return end
	
	pData.money = pData.money + (reward or 50)
	pData.xp = pData.xp + 10
	pData.tasksCompleted = pData.tasksCompleted + 1
	
	-- Rütbe atlama kontrolü (Basit örnek)
	if pData.xp > 100 and pData.rank == "Acemi" then
		pData.rank = "Kıdemli"
		RE_Notification:FireClient(player, "🎊  Rütbe Atladınız: KIDEMLİ!", "success")
	end
	
	RE_UpdateStats:FireClient(player, pData.money, pData.rank)
	RE_Notification:FireClient(player, "💰  Görev Tamamlandı: " .. taskName .. " +$" .. (reward or 50), "success")
end)

-- ─────────────────────────────────────────────
-- OYUNCU GİRİŞ/ÇIKIŞ
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	SessionData[tostring(player.UserId)] = nil
end)

-- RemoteFunction Invoke Handler
RF_GetPlayerData.OnServerInvoke = function(player)
	return SessionData[tostring(player.UserId)]
end

print("[BSC Server] Sunucu Çekirdeği v4_AAA Başlatıldı! ✅")

return BSC_ServerCore
