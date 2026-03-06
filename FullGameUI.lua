-- ============================================================
-- BSC PRISON | FullGameUI.lua
-- StarterPlayerScripts > FullGameUI (ModuleScript)
-- Tüm UI ve İstemci Mantığını Tek Bir Dosyada Toplar
-- ============================================================

local FullGameUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- RENK PALETİ (Tüm modüller için ortak)
-- ─────────────────────────────────────────────
local COLORS = {
	bg          = Color3.fromRGB(10, 10, 14),
	panel       = Color3.fromRGB(16, 16, 22),
	panelAlt    = Color3.fromRGB(18, 18, 26),
	border      = Color3.fromRGB(35, 35, 50),
	accent      = Color3.fromRGB(90, 120, 255),
	accentDark  = Color3.fromRGB(50, 70, 180),
	text        = Color3.fromRGB(220, 220, 235),
	textDim     = Color3.fromRGB(120, 120, 145),
	btnNormal   = Color3.fromRGB(22, 22, 32),
	btnHover    = Color3.fromRGB(35, 35, 55),
	danger      = Color3.fromRGB(220, 60, 60),
	success     = Color3.fromRGB(60, 200, 120),
	warning     = Color3.fromRGB(220, 160, 60),
	riot        = Color3.fromRGB(220, 80, 30),
	cop         = Color3.fromRGB(70, 130, 220),
	prisoner    = Color3.fromRGB(220, 180, 60),
	criminal    = Color3.fromRGB(220, 60, 60),
	hostage     = Color3.fromRGB(60, 200, 120),
	male        = Color3.fromRGB(70, 130, 220),
	female      = Color3.fromRGB(220, 90, 150),
}

-- ─────────────────────────────────────────────
-- YARDIMCI FONKSİYONLAR (Tüm modüller için ortak)
-- ─────────────────────────────────────────────
local function makeTween(obj, info, props)
	return TweenService:Create(obj, info, props)
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.border
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function makeLabel(parent, text, size, color, font, xAlign, zIndex)
	local l = Instance.new("TextLabel")
	l.Text = text l.TextSize = size or 13 l.TextColor3 = color or COLORS.text
	l.Font = font or Enum.Font.Gotham l.BackgroundTransparency = 1
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Size = UDim2.new(1,0,1,0) l.ZIndex = zIndex or 5 l.TextWrapped = true
	l.Parent = parent return l
end

local function makeInput(parent, placeholder, zIndex)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 42)
	bg.BackgroundColor3 = COLORS.panelAlt
	bg.BorderSizePixel = 0
	bg.ZIndex = zIndex or 5
	bg.Parent = parent
	addCorner(bg, 8) addStroke(bg, COLORS.border, 1)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 1, 0)
	box.Position = UDim2.new(0, 10, 0, 0)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = COLORS.textDim
	box.TextColor3 = COLORS.text
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.ZIndex = (zIndex or 5) + 1
	box.Parent = bg

	box.Focused:Connect(function()
		makeTween(bg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 35)}):Play()
		addStroke(bg, COLORS.accent, 1)
	end)
	box.FocusLost:Connect(function()
		makeTween(bg, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.panelAlt}):Play()
		addStroke(bg, COLORS.border, 1)
	end)

	return bg, box
end

local function makeButton(parent, text, color, size, pos, zIndex)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(0, 120, 0, 40)
	btn.Position = pos or UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = color or COLORS.panel
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex or 5
	btn.Parent = parent
	addCorner(btn, 10)
	return btn
end

-- ─────────────────────────────────────────────
-- 1. MainMenuUI (Ana Menü)
-- ─────────────────────────────────────────────
FullGameUI.MainMenu = {}

function FullGameUI.MainMenu.Open(onPlayCallback)
	print("[BSC UI] Ana Menü açılıyor...")

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BSCPrisonMainMenu"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = PlayerGui

	-- Karartma Overlay
	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.new(1, 0, 1, 0)
	Overlay.BackgroundColor3 = COLORS.bg
	Overlay.BackgroundTransparency = 0.4
	Overlay.BorderSizePixel = 0
	Overlay.Parent = ScreenGui

	-- Sol Panel
	local LeftPanel = Instance.new("Frame")
	LeftPanel.Size = UDim2.new(0, 320, 1, 0)
	LeftPanel.BackgroundColor3 = COLORS.panel
	LeftPanel.BorderSizePixel = 0
	LeftPanel.Parent = ScreenGui
	addStroke(LeftPanel, COLORS.border, 1)

	-- Logo
	local Logo = Instance.new("TextLabel")
	Logo.Text = "BSC PRISON"
	Logo.Size = UDim2.new(1, 0, 0, 100)
	Logo.Position = UDim2.new(0, 0, 0, 40)
	Logo.TextColor3 = COLORS.accent
	Logo.Font = Enum.Font.GothamBlack
	Logo.TextSize = 32
	Logo.BackgroundTransparency = 1
	Logo.Parent = LeftPanel

	-- Buton Konteyneri
	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(1, -40, 0, 300)
	ButtonContainer.Position = UDim2.new(0, 20, 0, 150)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.Parent = LeftPanel

	local UIList = Instance.new("UIListLayout")
	UIList.Padding = UDim.new(0, 10)
	UIList.Parent = ButtonContainer

	local function createMenuButton(text, icon, color)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 50)
		btn.BackgroundColor3 = COLORS.btnNormal
		btn.Text = "  " .. icon .. "  " .. text
		btn.TextColor3 = COLORS.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 16
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = ButtonContainer
		addCorner(btn, 8)
		addStroke(btn, COLORS.border, 1)

		btn.MouseEnter:Connect(function()
			makeTween(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.btnHover}):Play()
		end)
		btn.MouseLeave:Connect(function()
			makeTween(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.btnNormal}):Play()
		end)

		return btn
	end

	local PlayBtn = createMenuButton("PLAY", "▶", COLORS.accent)
	local SettingsBtn = createMenuButton("SETTINGS", "⚙", COLORS.textDim)
	local LogsBtn = createMenuButton("UPDATE LOGS", "📋", COLORS.textDim)
	local RulesBtn = createMenuButton("RULES", "📜", COLORS.textDim)

	-- Play Butonu Aksiyonu
	PlayBtn.MouseButton1Click:Connect(function()
		print("[BSC UI] Play tıklandı.")
		
		-- Ekranı karart
		local fade = Instance.new("Frame")
		fade.Size = UDim2.new(1, 0, 1, 0)
		fade.BackgroundColor3 = Color3.new(0,0,0)
		fade.BackgroundTransparency = 1
		fade.ZIndex = 100
		fade.Parent = ScreenGui
		
		local t = makeTween(fade, TweenInfo.new(0.5), {BackgroundTransparency = 0})
		t:Play()
		t.Completed:Connect(function()
			ScreenGui:Destroy()
			if onPlayCallback then onPlayCallback() end
		end)
	end)

	-- Kamera Döndürme (Arka Planda)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	
	local rotAngle = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not ScreenGui.Parent then 
			connection:Disconnect() 
			camera.CameraType = Enum.CameraType.Custom
			return 
		end
		rotAngle = rotAngle + dt * 0.05
		local center = Vector3.new(0, 100, 0)
		local radius = 300
		local x = math.sin(rotAngle) * radius
		local z = math.cos(rotAngle) * radius
		camera.CFrame = CFrame.new(center + Vector3.new(x, 50, z), center)
	end)

	return ScreenGui
end

-- ─────────────────────────────────────────────
-- 2. CharacterCreatorUI (Karakter Oluşturma)
-- ─────────────────────────────────────────────
FullGameUI.CharacterCreator = {}

function FullGameUI.CharacterCreator.Open(onFinishCallback)
	print("[BSC UI] Karakter Oluşturma açılıyor...")
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BSCCharacterCreator"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = PlayerGui

	-- Siyah Oda Arka Planı
	local BG = Instance.new("Frame")
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = Color3.new(0,0,0)
	BG.BorderSizePixel = 0
	BG.Parent = ScreenGui

	-- Panel (Sağda)
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(0, 400, 0.8, 0)
	Panel.Position = UDim2.new(1, -450, 0.1, 0)
	Panel.BackgroundColor3 = COLORS.panel
	Panel.Parent = ScreenGui
	addCorner(Panel, 12)
	addStroke(Panel, COLORS.border, 1)

	local Title = Instance.new("TextLabel")
	Title.Text = "KARAKTER OLUŞTURMA"
	Title.Size = UDim2.new(1, 0, 0, 60)
	Title.TextColor3 = COLORS.accent
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20
	Title.BackgroundTransparency = 1
	Title.Parent = Panel

	-- Form Alanı
	local Form = Instance.new("Frame")
	Form.Size = UDim2.new(1, -40, 1, -150)
	Form.Position = UDim2.new(0, 20, 0, 80)
	Form.BackgroundTransparency = 1
	Form.Parent = Panel

	local function createInput(placeholder, yPos)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 0, 45)
		bg.Position = UDim2.new(0, 0, 0, yPos)
		bg.BackgroundColor3 = COLORS.bg
		bg.Parent = Form
		addCorner(bg, 8)
		addStroke(bg, COLORS.border, 1)

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -20, 1, 0)
		box.Position = UDim2.new(0, 10, 0, 0)
		box.BackgroundTransparency = 1
		box.PlaceholderText = placeholder
		box.Text = ""
		box.TextColor3 = COLORS.text
		box.Font = Enum.Font.Gotham
		box.TextSize = 14
		box.Parent = bg
		return box
	end

	local firstName = createInput("İSİM", 0)
	local lastName = createInput("SOYAD", 60)
	local ageInput = createInput("YAŞ", 120)

	-- Cinsiyet Seçimi
	local GenderFrame = Instance.new("Frame")
	GenderFrame.Size = UDim2.new(1, 0, 0, 50)
	GenderFrame.Position = UDim2.new(0, 0, 0, 180)
	GenderFrame.BackgroundTransparency = 1
	GenderFrame.Parent = Form

	local selectedGender = "male"

	local function createGenderBtn(text, xPos, genderVal)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.48, 0, 1, 0)
		btn.Position = UDim2.new(xPos, 0, 0, 0)
		btn.BackgroundColor3 = COLORS.bg
		btn.Text = text
		btn.TextColor3 = COLORS.textDim
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = GenderFrame
		addCorner(btn, 8)
		local s = addStroke(btn, COLORS.border, 1)

		btn.MouseButton1Click:Connect(function()
			selectedGender = genderVal
			-- Diğer butonları sıfırla, bunu aktif yap (basit mantık)
			btn.BackgroundColor3 = COLORS.accent
			btn.TextColor3 = Color3.new(1,1,1)
		end)
		return btn
	end

	local maleBtn = createGenderBtn("ERKEK", 0, "male")
	local femaleBtn = createGenderBtn("KADIN", 0.52, "female")
	maleBtn.BackgroundColor3 = COLORS.accent -- Varsayılan

	-- Uyarı Yazısı
	local WarnLbl = Instance.new("TextLabel")
	WarnLbl.Text = "BU BİLGİLER BİR DAHA DEĞİŞTİRİLEMEZ!"
	WarnLbl.Size = UDim2.new(1, 0, 0, 30)
	WarnLbl.Position = UDim2.new(0, 0, 1, -110)
	WarnLbl.TextColor3 = Color3.fromRGB(220, 60, 60)
	WarnLbl.Font = Enum.Font.GothamBold
	WarnLbl.TextSize = 12
	WarnLbl.BackgroundTransparency = 1
	WarnLbl.Parent = Panel

	-- Next Butonu
	local NextBtn = Instance.new("TextButton")
	NextBtn.Text = "ONAYLA VE DEVAM ET"
	NextBtn.Size = UDim2.new(1, -40, 0, 50)
	NextBtn.Position = UDim2.new(0, 20, 1, -70)
	NextBtn.BackgroundColor3 = COLORS.accent
	NextBtn.TextColor3 = Color3.new(1,1,1)
	NextBtn.Font = Enum.Font.GothamBold
	NextBtn.TextSize = 16
	NextBtn.Parent = Panel
	addCorner(NextBtn, 10)

	NextBtn.MouseButton1Click:Connect(function()
		if #firstName.Text < 2 or #lastName.Text < 2 then return end
		
		local charData = {
			firstName = firstName.Text,
			lastName = lastName.Text,
			age = tonumber(ageInput.Text) or 18,
			gender = selectedGender
		}
		
		local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
		Remotes.CreateCharacter:FireServer(charData)
		
		ScreenGui:Destroy()
		if onFinishCallback then onFinishCallback(charData) end
	end)

	return ScreenGui
end

function FullGameUI.CharacterCreator.ShowLoading(callback)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BSCLoading"
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = PlayerGui

	local BG = Instance.new("Frame")
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = Color3.new(0,0,0)
	BG.Parent = ScreenGui

	local LoadingLbl = Instance.new("TextLabel")
	LoadingLbl.Text = "KARAKTER VERİLERİ YÜKLENİYOR..."
	LoadingLbl.Size = UDim2.new(1, 0, 1, 0)
	LoadingLbl.TextColor3 = Color3.new(1,1,1)
	LoadingLbl.Font = Enum.Font.GothamBlack
	LoadingLbl.TextSize = 20
	LoadingLbl.BackgroundTransparency = 1
	LoadingLbl.Parent = BG

	task.wait(2)
	ScreenGui:Destroy()
	if callback then callback() end
end

-- ─────────────────────────────────────────────
-- 3. TeamSelectUI (Takım Seçimi)
-- ─────────────────────────────────────────────
FullGameUI.TeamSelect = {}

local TEAMS = {
	{
		id       = "cop",
		name     = "POLİS",
		sub      = "COP",
		desc     = "Düzeni sağla, mahkumları kontrol et,\nesir al ve hapishaneyi yönet.",
		icon     = "👮",
		color    = COLORS.cop,
		darkColor= Color3.fromRGB(15, 55, 130),
		badge    = "KANUN",
		badgeCol = COLORS.cop,
		perks    = {"🔫  Silah taşıma hakkı", "🔑  Kapı erişimi", "🚔  Araç kullanımı", "⛓  Bağlama yetkisi"},
	},
	{
		id       = "prisoner",
		name     = "MAHKUM",
		sub      = "PRISONER",
		desc     = "Hapishanede hayatta kal, görevleri\ntamamla ve özgürlüğünü kazan.",
		icon     = "🧑‍🦲",
		color    = COLORS.prisoner,
		darkColor= Color3.fromRGB(100, 75, 15),
		badge    = "TUTSAK",
		badgeCol = COLORS.prisoner,
		perks    = {"🏃  Kaçma hakkı", "⚒  İş yapma", "📦  Eşya toplama", "✊  İsyan katılımı"},
	},
	{
		id       = "criminal",
		name     = "KRİMİNAL",
		sub      = "CRIMINAL",
		desc     = "Gizlice hareket et, suç işle ve\nhapishane düzenini boz.",
		icon     = "🦹",
		color    = COLORS.criminal,
		darkColor= Color3.fromRGB(110, 20, 20),
		badge    = "SUÇLU",
		badgeCol = COLORS.criminal,
		perks    = {"🔪  Gizli silah", "🕵️  Gizlenme", "💣  Sabotaj", "🏴  İsyan lideri"},
	},
	{
		id       = "hostage",
		name     = "REHİNE",
		sub      = "HOSTAGE",
		desc     = "Kriminaller tarafından rehin alınmış\nbir sivil. Kurtarılmayı bekle.",
		icon     = "😰",
		color    = COLORS.hostage,
		darkColor= Color3.fromRGB(40, 100, 60),
		badge    = "SİVİL",
		badgeCol = COLORS.hostage,
		perks    = {"🙏  Kurtarılma bonusu", "🏃  Kaçma şansı", "📢  Yardım çağrısı", "🛡  Koruma kalkanı"},
	},
}

function FullGameUI.TeamSelect.Open(onSelectCallback)
	print("[BSC UI] Takım Seçimi açılıyor...")
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BSCTeamSelect"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = PlayerGui

	-- Karartma Overlay
	local BG = Instance.new("Frame")
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = Color3.new(0,0,0)
	BG.BackgroundTransparency = 0.5
	BG.BorderSizePixel = 0
	BG.Parent = ScreenGui

	-- Başlık
	local Title = Instance.new("TextLabel")
	Title.Text = "TAKIMINI SEÇ"
	Title.Size = UDim2.new(1, 0, 0, 80)
	Title.Position = UDim2.new(0, 0, 0, 40)
	Title.TextColor3 = Color3.new(1,1,1)
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 36
	Title.BackgroundTransparency = 1
	Title.Parent = ScreenGui

	-- Takım Kartları Konteyneri
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(0, 900, 0, 350)
	Container.Position = UDim2.new(0.5, -450, 0.5, -175)
	Container.BackgroundTransparency = 1
	Container.Parent = ScreenGui

	local UIList = Instance.new("UIListLayout")
	UIList.FillDirection = Enum.FillDirection.Horizontal
	UIList.Padding = UDim.new(0, 20)
	UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIList.Parent = Container

	local function createTeamCard(name, id, color, icon)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 200, 1, 0)
		card.BackgroundColor3 = COLORS.panel
		card.Parent = Container
		addCorner(card, 12)
		addStroke(card, COLORS.border, 1)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Text = icon
		iconLbl.Size = UDim2.new(1, 0, 0.5, 0)
		iconLbl.TextColor3 = color
		iconLbl.Font = Enum.Font.GothamBlack
		iconLbl.TextSize = 48
		iconLbl.BackgroundTransparency = 1
		iconLbl.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = name
		nameLbl.Size = UDim2.new(1, 0, 0, 40)
		nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
		nameLbl.TextColor3 = Color3.new(1,1,1)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 18
		nameLbl.BackgroundTransparency = 1
		nameLbl.Parent = card

		local selectBtn = Instance.new("TextButton")
		selectBtn.Text = "SEÇ"
		selectBtn.Size = UDim2.new(0.8, 0, 0, 40)
		selectBtn.Position = UDim2.new(0.1, 0, 1, -60)
		selectBtn.BackgroundColor3 = color
		selectBtn.TextColor3 = Color3.new(1,1,1)
		selectBtn.Font = Enum.Font.GothamBold
		selectBtn.TextSize = 14
		selectBtn.Parent = card
		addCorner(selectBtn, 8)

		selectBtn.MouseButton1Click:Connect(function()
			print("[BSC UI] Takım seçildi:", id)
			local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
			Remotes.JoinTeam:FireServer(id)
			
			ScreenGui:Destroy()
			if onSelectCallback then onSelectCallback(id) end
		end)

		return card
	end

	createTeamCard("POLİS", "cop", COLORS.cop, "👮")
	createTeamCard("MAHKUM", "prisoner", COLORS.prisoner, "🔗")
	createTeamCard("KRİMİNAL", "criminal", COLORS.criminal, "🔫")
	createTeamCard("REHİNE", "hostage", COLORS.hostage, "📦")

	return ScreenGui
end

-- ─────────────────────────────────────────────
-- 4. GameHUD (Oyun İçi HUD)
-- ─────────────────────────────────────────────
FullGameUI.GameHUD = {}

function FullGameUI.GameHUD.Init(teamId, charData)
	print("[BSC UI] Game HUD başlatılıyor...")
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BSCGameHUD"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = PlayerGui

	-- Üst Bilgi Paneli
	local TopInfo = Instance.new("Frame")
	TopInfo.Size = UDim2.new(0, 250, 0, 60)
	TopInfo.Position = UDim2.new(0, 20, 0, 20)
	TopInfo.BackgroundColor3 = COLORS.panel
	TopInfo.Parent = ScreenGui
	addCorner(TopInfo, 10)
	addStroke(TopInfo, COLORS.border, 1)

	local NameLbl = Instance.new("TextLabel")
	NameLbl.Text = (charData.firstName or "Bilinmeyen") .. " " .. (charData.lastName or "")
	NameLbl.Size = UDim2.new(1, -20, 0, 30)
	NameLbl.Position = UDim2.new(0, 10, 0, 5)
	NameLbl.TextColor3 = Color3.new(1,1,1)
	NameLbl.Font = Enum.Font.GothamBold
	NameLbl.TextSize = 14
	NameLbl.BackgroundTransparency = 1
	NameLbl.Parent = TopInfo

	local TeamLbl = Instance.new("TextLabel")
	TeamLbl.Text = "TAKIM: " .. string.upper(teamId)
	TeamLbl.Size = UDim2.new(1, -20, 0, 20)
	TeamLbl.Position = UDim2.new(0, 10, 0, 30)
	TeamLbl.TextColor3 = COLORS.accent
	TeamLbl.Font = Enum.Font.Gotham
	TeamLbl.TextSize = 12
	TeamLbl.BackgroundTransparency = 1
	TeamLbl.Parent = TopInfo

	-- İsyan Butonu (Mahkum/Kriminal)
	if teamId == "prisoner" or teamId == "criminal" then
		local RiotBtn = Instance.new("TextButton")
		RiotBtn.Text = "✊  İSYAN ET"
		RiotBtn.Size = UDim2.new(0, 140, 0, 45)
		RiotBtn.Position = UDim2.new(0, 20, 1, -65)
		RiotBtn.BackgroundColor3 = COLORS.danger
		RiotBtn.TextColor3 = Color3.new(1,1,1)
		RiotBtn.Font = Enum.Font.GothamBlack
		RiotBtn.TextSize = 14
		RiotBtn.Parent = ScreenGui
		addCorner(RiotBtn, 10)

		RiotBtn.MouseButton1Click:Connect(function()
			local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
			Remotes.StartRiot:FireServer()
			RiotBtn:Destroy()
		end)
	end

	-- Sağ Panel Toggle
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Text = "<"
	ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
	ToggleBtn.Position = UDim2.new(1, -60, 0.5, -20)
	ToggleBtn.BackgroundColor3 = COLORS.panel
	ToggleBtn.TextColor3 = COLORS.text
	ToggleBtn.Font = Enum.Font.GothamBold
	ToggleBtn.TextSize = 18
	ToggleBtn.Parent = ScreenGui
	addCorner(ToggleBtn, 8)
	addStroke(ToggleBtn, COLORS.border, 1)

	-- Yan Panel
	local SidePanel = Instance.new("Frame")
	SidePanel.Size = UDim2.new(0, 280, 0, 450)
	SidePanel.Position = UDim2.new(1, 20, 0.5, -225)
	SidePanel.BackgroundColor3 = COLORS.panel
	SidePanel.Parent = ScreenGui
	addCorner(SidePanel, 15)
	addStroke(SidePanel, COLORS.border, 1)

	local isOpen = false
	ToggleBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		local targetX = isOpen and UDim2.new(1, -300, 0.5, -225) or UDim2.new(1, 20, 0.5, -225)
		makeTween(SidePanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetX}):Play()
		ToggleBtn.Text = isOpen and ">" or "<"
	end)

	-- Panel Başlığı
	local SideTitle = Instance.new("TextLabel")
	SideTitle.Text = "MENÜ"
	SideTitle.Size = UDim2.new(1, 0, 0, 50)
	SideTitle.TextColor3 = COLORS.accent
	SideTitle.Font = Enum.Font.GothamBlack
	SideTitle.TextSize = 18
	SideTitle.BackgroundTransparency = 1
	SideTitle.Parent = SidePanel

	-- Solve Butonu
	local SolveBtn = Instance.new("TextButton")
	SolveBtn.Text = "⛓  BAĞI ÇÖZ (SOLVE)"
	SolveBtn.Size = UDim2.new(0.9, 0, 0, 50)
	SolveBtn.Position = UDim2.new(0.05, 0, 1, -70)
	SolveBtn.BackgroundColor3 = COLORS.accent
	SolveBtn.TextColor3 = Color3.new(1,1,1)
	SolveBtn.Font = Enum.Font.GothamBold
	SolveBtn.TextSize = 14
	SolveBtn.Parent = SidePanel
	addCorner(SolveBtn, 10)

	SolveBtn.MouseButton1Click:Connect(function()
		local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
		Remotes.SolveBond:FireServer("current")
		FullGameUI.GameHUD.ShowNotification(ScreenGui, "Bağ çözülüyor...", COLORS.accent)
	end)

	return ScreenGui
end

function FullGameUI.GameHUD.ShowNotification(gui, message, color)
	local notif = Instance.new("TextLabel")
	notif.Text = "  " .. message .. "  "
	notif.Size = UDim2.new(0, 0, 0, 40)
	notif.Position = UDim2.new(0.5, 0, 0, 100)
	notif.BackgroundColor3 = color or COLORS.accent
	notif.TextColor3 = Color3.new(1,1,1)
	notif.Font = Enum.Font.GothamBold
	notif.TextSize = 14
	notif.Parent = gui
	notif.AutomaticSize = Enum.AutomaticSize.X
	addCorner(notif, 20)

	makeTween(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -notif.AbsoluteSize.X/2, 0, 120)}):Play()
	task.delay(3, function()
		makeTween(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.3)
		notif:Destroy()
	end)
end

-- ─────────────────────────────────────────────
-- 5. ToolManager (Collar ve Kelepçe Tool'ları)
-- ─────────────────────────────────────────────
FullGameUI.ToolManager = {}

function FullGameUI.ToolManager.Init()
	print("[BSC Tools] ToolManager başlatıldı.")
end

function FullGameUI.ToolManager.CreateCollarTool()
	local tool = Instance.new("Tool")
	tool.Name = "Collar (Tasma)"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Color = Color3.fromRGB(50, 50, 50)
	handle.Material = Enum.Material.Metal
	handle.Parent = tool
	
	tool.Activated:Connect(function()
		local mouse = LocalPlayer:GetMouse()
		local target = mouse.Target
		
		if target and target.Parent:FindFirstChild("Humanoid") then
			local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
			if targetPlayer and targetPlayer ~= LocalPlayer then
				local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
				Remotes.CollarAction:FireServer(targetPlayer, "attach")
			end
		end
	end)
	
	tool.Unequipped:Connect(function()
		local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
		-- Remotes.CollarAction:FireServer(nil, "release_all") -- Sunucu tarafında yönetilecek
	end)
	
	return tool
end

function FullGameUI.ToolManager.CreateHandcuffTool()
	local tool = Instance.new("Tool")
	tool.Name = "Handcuffs (Kelepçe)"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Color = Color3.fromRGB(150, 150, 150)
	handle.Material = Enum.Material.Metal
	handle.Parent = tool
	
	tool.Activated:Connect(function()
		local mouse = LocalPlayer:GetMouse()
		local target = mouse.Target
		if target and target.Parent:FindFirstChild("Humanoid") then
			local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
			if targetPlayer then
				local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
				Remotes.CollarAction:FireServer(targetPlayer, "attach") -- Aynı sistemi kullanıyoruz
			end
		end
	end)
	
	return tool
end

-- ─────────────────────────────────────────────
-- 6. MapGenerator (Harita Oluşturucu)
-- ─────────────────────────────────────────────
FullGameUI.MapGenerator = {}

local MAP_SIZE = 2500 -- Daha büyük harita
local BORDER_HEIGHT = 200
local GROUND_COLOR = Color3.fromRGB(34, 45, 28)
local ROAD_COLOR = Color3.fromRGB(60, 50, 40)

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

function FullGameUI.MapGenerator.Generate()
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

-- ─────────────────────────────────────────────
-- UIManager (Ana Yönetici)
-- ─────────────────────────────────────────────
FullGameUI.UIManager = {}

function FullGameUI.UIManager.Init()
	print("[BSC UI] UIManager başlatıldı.")
	
	-- Haritayı oluştur
	task.spawn(function()
		FullGameUI.MapGenerator.Generate()
	end)

	-- Ana Menüyü aç
	FullGameUI.MainMenu.Open(function()
		-- Karakter oluşturma ekranını aç
		FullGameUI.CharacterCreator.Open(function(charData)
			-- Loading ekranını göster
			FullGameUI.CharacterCreator.ShowLoading(function()
				-- Takım seçme ekranını aç
				FullGameUI.TeamSelect.Open(function(teamId)
					-- Oyun HUD'ını başlat
					FullGameUI.GameHUD.Init(teamId, charData)
					
					-- Takıma göre tool ver (Cop/Criminal)
					if teamId == "cop" or teamId == "criminal" then
						local collar = FullGameUI.ToolManager.CreateCollarTool()
						collar.Parent = LocalPlayer.Backpack
						
						local handcuffs = FullGameUI.ToolManager.CreateHandcuffTool()
						handcuffs.Parent = LocalPlayer.Backpack
					end
					
					print("[BSC UI] Oyun HUD ve Tool'lar başlatıldı. Takım:", teamId)
				end)
			end)
		end)
	end)
end

return FullGameUI
