-- ============================================================
-- BSC PRISON | MapGenerator.lua
-- StarterPlayerScripts > MapGenerator (ModuleScript)
-- Devasa Harita Oluşturucu v2: Mesh Ağaçlar, Bitki Örtüsü, Detaylı Binalar
-- ============================================================

local Module = {}

-- ─────────────────────────────────────────────
-- AYARLAR VE ÖLÇEKLER
-- ─────────────────────────────────────────────
local MAP_SIZE = 2500 -- Daha büyük harita
local BORDER_HEIGHT = 200
local GROUND_COLOR = Color3.fromRGB(34, 45, 28)
local ROAD_COLOR = Color3.fromRGB(60, 50, 40)

-- ─────────────────────────────────────────────
-- ASSET ID'LERİ (Gelişmiş Mesh Assetleri)
-- ─────────────────────────────────────────────
local ASSETS = {
	MESH_TREE_1 = 4635565215, -- Pine Tree Mesh
	MESH_TREE_2 = 4635565215, -- Oak Tree Mesh
	MESH_BUSH   = 4635566110, -- Bush Mesh
	MESH_ROCK   = 4635567012, -- Rock Mesh
	PRISON_WALL = 4635560113,
	PRISON_GATE = 4635561383,
	HOUSE_1     = 4635562818,
	HOUSE_2     = 4635563910,
	LIGHT_POLE  = 4635569210,
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

local function insertMeshAsset(meshId, pos, scale, rot, parent)
	local mesh = Instance.new("MeshPart")
	mesh.Name = "MeshAsset_" .. meshId
	mesh.MeshId = "rbxassetid://" .. tostring(meshId)
	mesh.Position = pos
	mesh.Size = scale or Vector3.new(10, 10, 10)
	mesh.Rotation = rot or Vector3.new(0, 0, 0)
	mesh.Anchored = true
	mesh.Parent = parent
	return mesh
end

-- ─────────────────────────────────────────────
-- ANA OLUŞTURMA FONKSİYONU
-- ─────────────────────────────────────────────
function Module.Generate()
	local MapFolder = workspace:FindFirstChild("BSC_Map")
	if MapFolder then MapFolder:Destroy() end
	
	MapFolder = Instance.new("Folder")
	MapFolder.Name = "BSC_Map"
	MapFolder.Parent = workspace

	print("[BSC Map] Gelişmiş Harita oluşturuluyor...")

	-- 1. ZEMİN (Gelişmiş Çimenlik Alan)
	local Ground = createPart("Ground", Vector3.new(MAP_SIZE, 4, MAP_SIZE), Vector3.new(0, -2, 0), GROUND_COLOR, Enum.Material.Grass, MapFolder)
	task.wait(0.1)

	-- 2. HARİTA SINIRLARI (Devasa Dağlar)
	local function createBorder(name, size, pos)
		local b = createPart(name, size, pos, Color3.fromRGB(45, 45, 50), Enum.Material.Slate, MapFolder)
		b.Size = b.Size + Vector3.new(0, math.random(0, 100), 0)
		return b
	end
	createBorder("Border_N", Vector3.new(MAP_SIZE + 100, BORDER_HEIGHT, 100), Vector3.new(0, BORDER_HEIGHT/2, -MAP_SIZE/2))
	createBorder("Border_S", Vector3.new(MAP_SIZE + 100, BORDER_HEIGHT, 100), Vector3.new(0, BORDER_HEIGHT/2, MAP_SIZE/2))
	createBorder("Border_E", Vector3.new(100, BORDER_HEIGHT, MAP_SIZE + 100), Vector3.new(MAP_SIZE/2, BORDER_HEIGHT/2, 0))
	createBorder("Border_W", Vector3.new(100, BORDER_HEIGHT, MAP_SIZE + 100), Vector3.new(-MAP_SIZE/2, BORDER_HEIGHT/2, 0))
	task.wait(0.1)

	-- 3. TOPRAK YOLLAR VE PATİKALAR
	local RoadFolder = Instance.new("Folder", MapFolder)
	RoadFolder.Name = "Roads"
	createPart("MainRoad", Vector3.new(30, 0.5, MAP_SIZE - 200), Vector3.new(0, 0.1, 0), ROAD_COLOR, Enum.Material.Sand, RoadFolder)
	
	-- 4. HAPİSHANE VE BODRUM (Kuzey)
	local PrisonPos = Vector3.new(0, 0, -600)
	local PrisonFolder = Instance.new("Folder", MapFolder)
	PrisonFolder.Name = "PrisonComplex"
	
	-- Hapishane Binası
	local MainBuilding = createPart("MainPrison", Vector3.new(250, 80, 200), PrisonPos + Vector3.new(0, 40, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Concrete, PrisonFolder)
	
	-- Bodrum (Hostage Bölgesi)
	local BasementPos = PrisonPos + Vector3.new(0, -50, 0)
	local BasementFloor = createPart("BasementFloor", Vector3.new(230, 2, 180), BasementPos, Color3.fromRGB(15, 15, 20), Enum.Material.Concrete, PrisonFolder)
	
	-- 5. KASABA (Güney)
	local TownFolder = Instance.new("Folder", MapFolder)
	TownFolder.Name = "TownArea"
	for i = 1, 12 do
		local side = (i % 2 == 0) and 100 or -100
		local z = 200 + (math.floor(i/2) * 150)
		createPart("House_"..i, Vector3.new(60, 30, 60), Vector3.new(side, 15, z), Color3.fromRGB(120, 100, 80), Enum.Material.Wood, TownFolder)
	end

	-- 6. DOĞA (Mesh Ağaçlar ve Çalılar)
	local NatureFolder = Instance.new("Folder", MapFolder)
	NatureFolder.Name = "Nature"
	local rng = Random.new()
	for i = 1, 300 do
		if i % 30 == 0 then task.wait(0.05) end
		local rx = rng:NextInteger(-MAP_SIZE/2 + 100, MAP_SIZE/2 - 100)
		local rz = rng:NextInteger(-MAP_SIZE/2 + 100, MAP_SIZE/2 - 100)
		
		-- Yolların ve binaların üzerine gelmesin
		if math.abs(rx) > 60 and math.abs(rz + 600) > 300 then
			local treeType = (i % 2 == 0) and ASSETS.MESH_TREE_1 or ASSETS.MESH_TREE_2
			insertMeshAsset(treeType, Vector3.new(rx, 0, rz), Vector3.new(15, 30, 15), Vector3.new(0, rng:NextInteger(0, 360), 0), NatureFolder)
		end
	end

	print("[BSC Map] Harita başarıyla oluşturuldu! ✅")
end

return Module
