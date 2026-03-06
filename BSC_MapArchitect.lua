-- ============================================================
-- BSC PRISON | BSC_MapArchitect.lua
-- StarterPlayerScripts > BSC_MapArchitect (ModuleScript)
-- Devasa Mesh Tabanlı Mimari ve ProximityPrompt Entegrasyonu
-- ============================================================

local BSC_MapArchitect = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ─────────────────────────────────────────────
-- ASSET KÜTÜPHANESİ (MESH ID'LERİ)
-- ─────────────────────────────────────────────
local ASSETS = {
	-- Mimari
	PRISON_BLOCK_A = 149100001, -- Mesh ID (Placeholder)
	PRISON_BLOCK_B = 149100002,
	WATCH_TOWER    = 149100003,
	SECURITY_GATE  = 149100004,
	
	-- Doğa (Mesh)
	MESH_TREE_PINE = 4635565215,
	MESH_TREE_OAK  = 4635565215,
	MESH_ROCK_BIG  = 4635567012,
	
	-- Etkileşimli Objeler
	DOOR_MODEL     = 149100005,
	KEYCARD_READER = 149100006,
	CCTV_CAMERA    = 149100007,
}

-- ─────────────────────────────────────────────
-- YARDIMCI FONKSİYONLAR
-- ─────────────────────────────────────────────
local function createPart(name, size, pos, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color or Color3.new(1,1,1)
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.Parent = parent or workspace
	return p
end

local function insertMesh(meshId, pos, scale, rot, parent)
	local mesh = Instance.new("MeshPart")
	mesh.Name = "Mesh_" .. tostring(meshId)
	mesh.MeshId = "rbxassetid://" .. tostring(meshId)
	mesh.Position = pos
	mesh.Size = scale or Vector3.new(10, 10, 10)
	mesh.Rotation = rot or Vector3.new(0, 0, 0)
	mesh.Anchored = true
	mesh.Parent = parent
	return mesh
end

-- ─────────────────────────────────────────────
-- PROXIMITYPROMPT SİSTEMLİ KAPI OLUŞTURUCU
-- ─────────────────────────────────────────────
function BSC_MapArchitect.CreateInteractiveDoor(pos, rot, reqLevel, parent)
	local doorModel = Instance.new("Model")
	doorModel.Name = "InteractiveDoor"
	
	-- Kapı Kasası
	local frame = createPart("Frame", Vector3.new(14, 18, 3), pos, Color3.fromRGB(30, 30, 35), Enum.Material.Metal, doorModel)
	frame.Rotation = rot
	
	-- Kapı Kanadı (Mesh olması tercih edilir)
	local doorPart = createPart("DoorPart", Vector3.new(12, 17, 1.5), pos, Color3.fromRGB(80, 80, 85), Enum.Material.DiamondPlate, doorModel)
	doorPart.Rotation = rot
	
	-- ProximityPrompt (E Tuşu Etkileşimi)
	local prompt = Instance.new("ProximityPrompt", doorPart)
	prompt.ActionText = "Kapıyı Aç/Kapat"
	prompt.ObjectText = "Güvenlik Kapısı (Lvl " .. reqLevel .. ")"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	
	-- Yetki Bilgisi
	doorModel:SetAttribute("RequiredLevel", reqLevel)
	doorModel:SetAttribute("OriginalCFrame", doorPart.CFrame)
	doorModel:SetAttribute("Open", false)
	
	local config = Instance.new("Configuration", doorModel)
	config.Name = "Config"
	
	-- İstemci Tarafı Etkileşim (Görsel Tepki)
	prompt.Triggered:Connect(function(player)
		local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
		Remotes.RequestDoor:FireServer(doorModel)
	end)
	
	doorModel.Parent = parent
	return doorModel
end

-- ─────────────────────────────────────────────
-- DEVASA HAPİSHANE MİMARİSİ (ARCHITECT)
-- ─────────────────────────────────────────────
function BSC_MapArchitect.BuildPrison()
	local MapFolder = Instance.new("Folder", workspace)
	MapFolder.Name = "BSC_Prison_Complex"
	
	print("[BSC Architect] Devasa Hapishane Kompleksi İnşa Ediliyor...")
	
	-- 1. ZEMİN VE ÇEVRE (4000x4000)
	local base = createPart("MainBaseplate", Vector3.new(4000, 5, 4000), Vector3.new(0, -2.5, 0), Color3.fromRGB(34, 45, 28), Enum.Material.Grass, MapFolder)
	
	-- 2. ANA HAPİSHANE BLOKLARI (MESH TABANLI TASARIM)
	local PrisonPos = Vector3.new(0, 0, -1000)
	
	-- Ana Blok (Center)
	local MainBlock = createPart("MainBlock", Vector3.new(500, 150, 400), PrisonPos + Vector3.new(0, 75, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Concrete, MapFolder)
	
	-- Kat Detayları ve Pencereler (Kodla Oluşturulan Detaylar)
	for floor = 1, 7 do
		local detail = createPart("FloorLine_"..floor, Vector3.new(510, 2, 410), PrisonPos + Vector3.new(0, floor * 20, 0), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, MapFolder)
	end
	
	-- Hücre Kanatları (Wings)
	local WingA = createPart("WingA", Vector3.new(200, 100, 300), PrisonPos + Vector3.new(-350, 50, 50), Color3.fromRGB(45, 45, 50), Enum.Material.Concrete, MapFolder)
	local WingB = createPart("WingB", Vector3.new(200, 100, 300), PrisonPos + Vector3.new(350, 50, 50), Color3.fromRGB(45, 45, 50), Enum.Material.Concrete, MapFolder)
	
	-- 3. ETKİLEŞİMLİ KAPILARIN YERLEŞTİRİLMESİ
	BSC_MapArchitect.CreateInteractiveDoor(PrisonPos + Vector3.new(0, 9, 200), Vector3.new(0, 0, 0), 2, MapFolder) -- Ana Giriş
	BSC_MapArchitect.CreateInteractiveDoor(PrisonPos + Vector3.new(-250, 9, 50), Vector3.new(0, 90, 0), 1, MapFolder) -- Kanat A Girişi
	BSC_MapArchitect.CreateInteractiveDoor(PrisonPos + Vector3.new(250, 9, 50), Vector3.new(0, -90, 0), 1, MapFolder) -- Kanat B Girişi
	
	-- 4. GÜVENLİK KULELERİ VE ÇİTLER
	for i = 1, 8 do
		local angle = (i-1) * (math.pi/4)
		local tx = math.cos(angle) * 600
		local tz = -1000 + math.sin(angle) * 600
		local tower = createPart("SecurityTower_"..i, Vector3.new(40, 200, 40), Vector3.new(tx, 100, tz), Color3.fromRGB(30, 30, 35), Enum.Material.Concrete, MapFolder)
		createPart("TowerTop_"..i, Vector3.new(60, 30, 60), Vector3.new(tx, 215, tz), Color3.fromRGB(15, 15, 20), Enum.Material.Metal, MapFolder)
	end
	
	-- 5. BODRUM (HOSTAGE ZONE) - DERİN VE KARANLIK
	local BasementPos = PrisonPos + Vector3.new(0, -100, 0)
	local BasementFloor = createPart("Basement_Ground", Vector3.new(480, 10, 380), BasementPos, Color3.fromRGB(10, 10, 12), Enum.Material.Concrete, MapFolder)
	
	-- 6. DOĞA VE MESH DETAYLARI
	local NatureFolder = Instance.new("Folder", MapFolder)
	NatureFolder.Name = "Nature_Mesh"
	local rng = Random.new()
	for i = 1, 500 do
		if i % 50 == 0 then task.wait(0.05) end
		local rx = rng:NextInteger(-1800, 1800)
		local rz = rng:NextInteger(-1800, 1800)
		
		-- Hapishane binasının içine ağaç dikme
		if math.abs(rx) > 600 or math.abs(rz + 1000) > 600 then
			local treeType = (i % 2 == 0) and ASSETS.MESH_TREE_PINE or ASSETS.MESH_TREE_OAK
			insertMesh(treeType, Vector3.new(rx, 0, rz), Vector3.new(20, 40, 20), Vector3.new(0, rng:NextInteger(0, 360), 0), NatureFolder)
		end
	end
	
	print("[BSC Architect] İnşaat Tamamlandı! ✅")
end

return BSC_MapArchitect
