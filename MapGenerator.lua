-- ============================================================
-- BSC PRISON | MapGenerator.lua
-- StarterPlayerScripts > MapGenerator (ModuleScript)
-- Devasa Harita Oluşturucu: Arazi, Yollar, Hapishane, Kasaba, Bodrum
-- ============================================================

local Module = {}

-- ─────────────────────────────────────────────
-- AYARLAR VE ÖLÇEKLER
-- ─────────────────────────────────────────────
local MAP_SIZE = 2000 -- Harita boyutu (studs)
local BORDER_HEIGHT = 150
local GROUND_COLOR = Color3.fromRGB(34, 45, 28) -- Çimen yeşili
local ROAD_COLOR = Color3.fromRGB(60, 50, 40) -- Toprak yol rengi

-- ─────────────────────────────────────────────
-- ASSET ID'LERİ (Ücretsiz ve Kaliteli Roblox Assetleri)
-- ─────────────────────────────────────────────
local ASSETS = {
	PRISON_WALL = 4635560113, -- Hapishane duvarı
	PRISON_GATE = 4635561383, -- Hapishane kapısı
	HOUSE_1     = 4635562818, -- Kasaba evi 1
	HOUSE_2     = 4635563910, -- Kasaba evi 2
	TREE        = 4635565215, -- Çam ağacı
	BUSH        = 4635566110, -- Çalı
	CRATE       = 4635567012, -- Kutu/Obje
	BARREL      = 4635568115, -- Varil
	LIGHT_POLE  = 4635569210, -- Sokak lambası
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

local function insertAsset(assetId, pos, rot, parent)
	-- Not: Gerçek Roblox Studio'da InsertService kullanılır.
	-- Burada placeholder bir model oluşturuyoruz.
	local model = Instance.new("Model")
	model.Name = "Asset_" .. assetId
	
	local p = createPart("Placeholder", Vector3.new(10, 10, 10), pos, Color3.new(0.5, 0.5, 0.5), Enum.Material.Concrete, model)
	model.PrimaryPart = p
	model:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, math.rad(rot or 0), 0))
	
	model.Parent = parent
	return model
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

	print("[BSC Map] Harita oluşturuluyor...")

	-- 1. ZEMİN (Çimenlik Alan)
	local Ground = createPart("Ground", Vector3.new(MAP_SIZE, 2, MAP_SIZE), Vector3.new(0, -1, 0), GROUND_COLOR, Enum.Material.Grass, MapFolder)
	task.wait(0.1)

	-- 2. HARİTA SINIRLARI (Büyük Dağlar/Duvarlar)
	local function createBorder(name, size, pos)
		local b = createPart(name, size, pos, Color3.fromRGB(40, 40, 45), Enum.Material.Slate, MapFolder)
		-- Rastgele yükseklik varyasyonu (Dağ efekti)
		b.Size = b.Size + Vector3.new(0, math.random(0, 50), 0)
		return b
	end
	createBorder("Border_North", Vector3.new(MAP_SIZE + 40, BORDER_HEIGHT, 40), Vector3.new(0, BORDER_HEIGHT/2, -MAP_SIZE/2))
	createBorder("Border_South", Vector3.new(MAP_SIZE + 40, BORDER_HEIGHT, 40), Vector3.new(0, BORDER_HEIGHT/2, MAP_SIZE/2))
	createBorder("Border_East",  Vector3.new(40, BORDER_HEIGHT, MAP_SIZE + 40), Vector3.new(MAP_SIZE/2, BORDER_HEIGHT/2, 0))
	createBorder("Border_West",  Vector3.new(40, BORDER_HEIGHT, MAP_SIZE + 40), Vector3.new(-MAP_SIZE/2, BORDER_HEIGHT/2, 0))
	task.wait(0.1)

	-- 3. TOPRAK YOLLAR
	local RoadFolder = Instance.new("Folder", MapFolder)
	RoadFolder.Name = "Roads"
	
	-- Ana yol (Kasabadan Hapishaneye)
	createPart("MainRoad", Vector3.new(25, 0.5, MAP_SIZE - 100), Vector3.new(0, 0.1, 0), ROAD_COLOR, Enum.Material.Sand, RoadFolder)
	-- Yan yollar
	createPart("SideRoad1", Vector3.new(MAP_SIZE/2, 0.5, 20), Vector3.new(MAP_SIZE/4, 0.1, 200), ROAD_COLOR, Enum.Material.Sand, RoadFolder)

	-- 4. HAPİSHANE BİNASI (Merkez Kuzey)
	local PrisonPos = Vector3.new(0, 0, -400)
	local PrisonFolder = Instance.new("Folder", MapFolder)
	PrisonFolder.Name = "PrisonComplex"
	
	-- Ana Bina (Dış Kabuk)
	local MainBuilding = createPart("MainPrison_Shell", Vector3.new(200, 60, 150), PrisonPos + Vector3.new(0, 30, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Concrete, PrisonFolder)
	MainBuilding.Transparency = 0.8 -- İçini görebilmek için
	
	-- İç Mekan: Hücreler
	for i = 1, 10 do
		local side = (i % 2 == 0) and 40 or -40
		local zPos = PrisonPos.Z - 60 + (math.floor(i/2) * 25)
		local cell = createPart("Cell_"..i, Vector3.new(20, 15, 20), Vector3.new(side, 7.5, zPos), Color3.fromRGB(40, 40, 45), Enum.Material.Concrete, PrisonFolder)
		-- Demir parmaklıklar
		local bars = createPart("Bars_"..i, Vector3.new(2, 15, 20), Vector3.new(side + (side > 0 and -10 or 10), 7.5, zPos), Color3.new(0.2, 0.2, 0.2), Enum.Material.Metal, cell)
		bars.Transparency = 0.6
	end

	-- Güvenlik Odası (Üst Kat)
	local SecurityRoom = createPart("SecurityRoom", Vector3.new(50, 15, 50), PrisonPos + Vector3.new(0, 45, 0), Color3.fromRGB(30, 30, 35), Enum.Material.Glass, PrisonFolder)
	
	-- Bodrum Girişi (Gizli Merdiven)
	local Hatch = createPart("BasementHatch", Vector3.new(10, 1, 10), PrisonPos + Vector3.new(0, 0.5, 60), Color3.fromRGB(20, 20, 20), Enum.Material.Metal, PrisonFolder)
	
	-- Hapishane Avlusu ve Duvarları
	local function createPrisonWall(name, size, pos)
		createPart(name, size, pos, Color3.fromRGB(50, 50, 55), Enum.Material.Concrete, PrisonFolder)
	end
	createPrisonWall("Wall_N", Vector3.new(300, 25, 5), PrisonPos + Vector3.new(0, 12.5, -100))
	createPrisonWall("Wall_S", Vector3.new(300, 25, 5), PrisonPos + Vector3.new(0, 12.5, 100))
	createPrisonWall("Wall_E", Vector3.new(5, 25, 200), PrisonPos + Vector3.new(150, 12.5, 0))
	createPrisonWall("Wall_W", Vector3.new(5, 25, 200), PrisonPos + Vector3.new(-150, 12.5, 0))

	-- 5. BODRUM (Hostage Bölgesi)
	-- Hapishane binasının altına yerleştirilir
	local BasementPos = PrisonPos + Vector3.new(0, -30, 0)
	local BasementFolder = Instance.new("Folder", MapFolder)
	BasementFolder.Name = "Basement_HostageZone"
	
	local BasementFloor = createPart("BasementFloor", Vector3.new(180, 2, 130), BasementPos, Color3.fromRGB(20, 20, 25), Enum.Material.Concrete, BasementFolder)
	local BasementCeiling = createPart("BasementCeiling", Vector3.new(180, 2, 130), BasementPos + Vector3.new(0, 15, 0), Color3.fromRGB(20, 20, 25), Enum.Material.Concrete, BasementFolder)
	
	-- Bodrum Duvarları (Karanlık ve Kasvetli)
	local function createBasementWall(name, size, pos)
		createPart(name, size, pos, Color3.fromRGB(15, 15, 20), Enum.Material.Cobblestone, BasementFolder)
	end
	createBasementWall("BWall_N", Vector3.new(180, 15, 2), BasementPos + Vector3.new(0, 7.5, -65))
	createBasementWall("BWall_S", Vector3.new(180, 15, 2), BasementPos + Vector3.new(0, 7.5, 65))
	createBasementWall("BWall_E", Vector3.new(2, 15, 130), BasementPos + Vector3.new(90, 7.5, 0))
	createBasementWall("BWall_W", Vector3.new(2, 15, 130), BasementPos + Vector3.new(-90, 7.5, 0))

	-- Hostage Hücresi (Bodrumun en dibinde)
	local CellPos = BasementPos + Vector3.new(60, 0, 40)
	local CellWall = createPart("HostageCell", Vector3.new(30, 15, 30), CellPos + Vector3.new(0, 7.5, 0), Color3.fromRGB(30, 30, 35), Enum.Material.CorrodedMetal, BasementFolder)
	CellWall.Transparency = 0.5 -- Demir parmaklık efekti
	
	-- Bodrum Işıklandırması (Kırmızı/Loş)
	local lightPart = createPart("BasementLight", Vector3.new(1,1,1), BasementPos + Vector3.new(0, 14, 0), Color3.new(1,0,0), Enum.Material.Neon, BasementFolder)
	local pl = Instance.new("PointLight", lightPart)
	pl.Color = Color3.new(1, 0.1, 0.1)
	pl.Range = 60
	pl.Brightness = 2

	-- 6. KASABA (Güney Bölgesi)
	local TownFolder = Instance.new("Folder", MapFolder)
	TownFolder.Name = "TownArea"
	
	-- Kasaba Meydanı ve Binalar
	for i = 1, 10 do
		local xPos = (i % 2 == 0) and 85 or -85
		local zPos = 150 + (math.floor(i/2) * 120)
		insertAsset(ASSETS.HOUSE_1, Vector3.new(xPos, 0, zPos), (xPos > 0) and -90 or 90, TownFolder)
		
		-- Sokak Lambaları
		local lamp = createPart("LampPost", Vector3.new(2, 20, 2), Vector3.new(xPos/2, 10, zPos), Color3.new(0.3, 0.3, 0.3), Enum.Material.Metal, TownFolder)
		local bulb = createPart("Bulb", Vector3.new(2,2,2), lamp.Position + Vector3.new(0, 10, 0), Color3.new(1,1,0.8), Enum.Material.Neon, lamp)
		local pl = Instance.new("PointLight", bulb)
		pl.Range = 40
		pl.Brightness = 1.5
	end

	-- Kasaba Karakolu (Şehir Merkezi)
	local PoliceStation = createPart("TownPoliceStation", Vector3.new(80, 30, 60), Vector3.new(0, 15, 600), Color3.fromRGB(40, 60, 100), Enum.Material.Concrete, TownFolder)
	
	-- Market (Placeholder)
	local Market = createPart("TownMarket", Vector3.new(60, 25, 50), Vector3.new(120, 12.5, 300), Color3.fromRGB(180, 140, 60), Enum.Material.Wood, TownFolder)

	-- 7. DOĞA VE DETAYLAR (Rastgele Ağaçlar ve Kayalar)
	local NatureFolder = Instance.new("Folder", MapFolder)
	NatureFolder.Name = "Nature"
	
	local rng = Random.new()
	for i = 1, 150 do
		if i % 20 == 0 then task.wait(0.05) end -- FPS düşüşünü önlemek için
		local rx = rng:NextInteger(-MAP_SIZE/2 + 50, MAP_SIZE/2 - 50)
		local rz = rng:NextInteger(-MAP_SIZE/2 + 50, MAP_SIZE/2 - 50)
		
		-- Yolların ve binaların üzerine gelmesin
		if math.abs(rx) > 40 and math.abs(rz + 400) > 200 then
			insertAsset(ASSETS.TREE, Vector3.new(rx, 0, rz), rng:NextInteger(0, 360), NatureFolder)
		end
	end

	-- 8. GÖKYÜZÜ VE AYDINLATMA
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 110)

	print("[BSC Map] Harita başarıyla oluşturuldu! ✅")
end

return Module
