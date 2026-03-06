-- ============================================================
-- BSC PRISON | MainMenuUI.lua
-- StarterPlayerScripts > MainMenuUI (LocalScript)
-- Ana Menü: Başlık, Dönen Kamera, Play/Settings/UpdateLogs/Rules
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- KAMERA DÖNDÜRME AÇILARI (Her oturumda farklı)
-- ─────────────────────────────────────────────
local cameraAngles = {
	{CFrame.new(0, 80, 0) * CFrame.Angles(math.rad(-70), 0, 0)},
	{CFrame.new(60, 50, 60) * CFrame.Angles(math.rad(-35), math.rad(45), 0)},
	{CFrame.new(-80, 60, 20) * CFrame.Angles(math.rad(-40), math.rad(-60), 0)},
	{CFrame.new(0, 40, 100) * CFrame.Angles(math.rad(-20), 0, 0)},
	{CFrame.new(100, 70, -50) * CFrame.Angles(math.rad(-45), math.rad(120), 0)},
}
local selectedAngle = cameraAngles[math.random(1, #cameraAngles)][1]
local cameraRotSpeed = 0.008

-- ─────────────────────────────────────────────
-- RENK PALETİ
-- ─────────────────────────────────────────────
local COLORS = {
	bg          = Color3.fromRGB(10, 10, 14),
	panel       = Color3.fromRGB(16, 16, 22),
	border      = Color3.fromRGB(35, 35, 50),
	accent      = Color3.fromRGB(90, 120, 255),
	accentDark  = Color3.fromRGB(50, 70, 180),
	text        = Color3.fromRGB(220, 220, 235),
	textDim     = Color3.fromRGB(120, 120, 145),
	btnNormal   = Color3.fromRGB(22, 22, 32),
	btnHover    = Color3.fromRGB(35, 35, 55),
	btnBorder   = Color3.fromRGB(55, 55, 80),
	danger      = Color3.fromRGB(220, 60, 60),
	success     = Color3.fromRGB(60, 200, 120),
}

-- ─────────────────────────────────────────────
-- YARDIMCI FONKSİYONLAR
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

local function addPadding(parent, px)
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, px)
	p.PaddingRight  = UDim.new(0, px)
	p.PaddingTop    = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
	return p
end

local function createLabel(parent, text, size, color, font, xAlign)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.TextSize = size or 14
	lbl.TextColor3 = color or COLORS.text
	lbl.Font = font or Enum.Font.GothamBold
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Parent = parent
	return lbl
end

-- ─────────────────────────────────────────────
-- SCREENGUI OLUŞTUR
-- ─────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BSCPrisonMainMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Arka plan (yarı saydam koyu overlay)
local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.Position = UDim2.new(0, 0, 0, 0)
Overlay.BackgroundColor3 = COLORS.bg
Overlay.BackgroundTransparency = 0.35
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 1
Overlay.Parent = ScreenGui

-- Sol panel (logo + butonlar)
local LeftPanel = Instance.new("Frame")
LeftPanel.Name = "LeftPanel"
LeftPanel.Size = UDim2.new(0, 320, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundColor3 = COLORS.panel
LeftPanel.BackgroundTransparency = 0.05
LeftPanel.BorderSizePixel = 0
LeftPanel.ZIndex = 2
LeftPanel.Parent = ScreenGui
addStroke(LeftPanel, COLORS.border, 1)

-- Sol panel sağ kenar ince çizgi
local PanelLine = Instance.new("Frame")
PanelLine.Size = UDim2.new(0, 1, 1, 0)
PanelLine.Position = UDim2.new(1, 0, 0, 0)
PanelLine.BackgroundColor3 = COLORS.accent
PanelLine.BackgroundTransparency = 0.5
PanelLine.BorderSizePixel = 0
PanelLine.ZIndex = 3
PanelLine.Parent = LeftPanel

-- Logo bölgesi
local LogoFrame = Instance.new("Frame")
LogoFrame.Name = "LogoFrame"
LogoFrame.Size = UDim2.new(1, 0, 0, 140)
LogoFrame.Position = UDim2.new(0, 0, 0, 0)
LogoFrame.BackgroundTransparency = 1
LogoFrame.ZIndex = 3
LogoFrame.Parent = LeftPanel

-- BSC küçük üst yazı
local SubTitle = Instance.new("TextLabel")
SubTitle.Text = "B S C"
SubTitle.Size = UDim2.new(1, -40, 0, 22)
SubTitle.Position = UDim2.new(0, 20, 0, 38)
SubTitle.BackgroundTransparency = 1
SubTitle.TextColor3 = COLORS.accent
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 13
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.LetterSpacing = 8
SubTitle.ZIndex = 4
SubTitle.Parent = LogoFrame

-- Ana başlık PRISON
local MainTitle = Instance.new("TextLabel")
MainTitle.Text = "PRISON"
MainTitle.Size = UDim2.new(1, -40, 0, 58)
MainTitle.Position = UDim2.new(0, 18, 0, 56)
MainTitle.BackgroundTransparency = 1
MainTitle.TextColor3 = COLORS.text
MainTitle.Font = Enum.Font.GothamBlack
MainTitle.TextSize = 46
MainTitle.TextXAlignment = Enum.TextXAlignment.Left
MainTitle.ZIndex = 4
MainTitle.Parent = LogoFrame

-- Versiyon etiketi
local VersionLabel = Instance.new("TextLabel")
VersionLabel.Text = "v1.0.0  •  BETA"
VersionLabel.Size = UDim2.new(1, -40, 0, 18)
VersionLabel.Position = UDim2.new(0, 20, 0, 112)
VersionLabel.BackgroundTransparency = 1
VersionLabel.TextColor3 = COLORS.textDim
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = 11
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.ZIndex = 4
VersionLabel.Parent = LogoFrame

-- Ayırıcı çizgi
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 0, 140)
Divider.BackgroundColor3 = COLORS.border
Divider.BorderSizePixel = 0
Divider.ZIndex = 3
Divider.Parent = LeftPanel

-- Buton listesi konteyneri
local ButtonList = Instance.new("Frame")
ButtonList.Name = "ButtonList"
ButtonList.Size = UDim2.new(1, -40, 0, 300)
ButtonList.Position = UDim2.new(0, 20, 0, 158)
ButtonList.BackgroundTransparency = 1
ButtonList.ZIndex = 3
ButtonList.Parent = LeftPanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = ButtonList

-- ─────────────────────────────────────────────
-- BUTON OLUŞTURMA FONKSİYONU
-- ─────────────────────────────────────────────
local function createMenuButton(parent, text, icon, layoutOrder, accentColor)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(1, 0, 0, 52)
	btn.BackgroundColor3 = COLORS.btnNormal
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.LayoutOrder = layoutOrder
	btn.ZIndex = 4
	btn.Parent = parent
	addCorner(btn, 10)
	addStroke(btn, COLORS.btnBorder, 1)

	-- Sol renkli çubuk
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0.6, 0)
	bar.Position = UDim2.new(0, 0, 0.2, 0)
	bar.BackgroundColor3 = accentColor or COLORS.accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = btn
	addCorner(bar, 3)

	-- İkon
	local iconLbl = Instance.new("TextLabel")
	iconLbl.Text = icon or "▶"
	iconLbl.Size = UDim2.new(0, 36, 1, 0)
	iconLbl.Position = UDim2.new(0, 12, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.TextColor3 = accentColor or COLORS.accent
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.TextSize = 16
	iconLbl.ZIndex = 5
	iconLbl.Parent = btn

	-- Metin
	local textLbl = Instance.new("TextLabel")
	textLbl.Text = text
	textLbl.Size = UDim2.new(1, -60, 1, 0)
	textLbl.Position = UDim2.new(0, 50, 0, 0)
	textLbl.BackgroundTransparency = 1
	textLbl.TextColor3 = COLORS.text
	textLbl.Font = Enum.Font.GothamBold
	textLbl.TextSize = 15
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.ZIndex = 5
	textLbl.Parent = btn

	-- Hover animasyonu
	local hoverInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	btn.MouseEnter:Connect(function()
		makeTween(btn, hoverInfo, {BackgroundColor3 = COLORS.btnHover}):Play()
		makeTween(bar, hoverInfo, {Size = UDim2.new(0, 3, 0.8, 0), Position = UDim2.new(0, 0, 0.1, 0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		makeTween(btn, hoverInfo, {BackgroundColor3 = COLORS.btnNormal}):Play()
		makeTween(bar, hoverInfo, {Size = UDim2.new(0, 3, 0.6, 0), Position = UDim2.new(0, 0, 0.2, 0)}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		makeTween(btn, TweenInfo.new(0.08), {BackgroundColor3 = accentColor or COLORS.accentDark}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		makeTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.btnHover}):Play()
	end)

	return btn
end

-- Menü butonları
local PlayBtn       = createMenuButton(ButtonList, "PLAY",        "▶", 1, COLORS.accent)
local SettingsBtn   = createMenuButton(ButtonList, "SETTINGS",    "⚙", 2, Color3.fromRGB(180, 180, 220))
local UpdateLogBtn  = createMenuButton(ButtonList, "UPDATE LOGS", "📋", 3, Color3.fromRGB(100, 200, 150))
local RulesBtn      = createMenuButton(ButtonList, "RULES",       "📜", 4, Color3.fromRGB(220, 160, 60))

-- Alt bilgi
local FooterLabel = Instance.new("TextLabel")
FooterLabel.Text = "BSC PRISON  •  All rights reserved"
FooterLabel.Size = UDim2.new(1, -40, 0, 30)
FooterLabel.Position = UDim2.new(0, 20, 1, -40)
FooterLabel.BackgroundTransparency = 1
FooterLabel.TextColor3 = COLORS.textDim
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextSize = 10
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.ZIndex = 3
FooterLabel.Parent = LeftPanel

-- ─────────────────────────────────────────────
-- SAĞ PANEL (Harita önizleme / Bilgi kutusu)
-- ─────────────────────────────────────────────
local RightInfo = Instance.new("Frame")
RightInfo.Name = "RightInfo"
RightInfo.Size = UDim2.new(0, 260, 0, 120)
RightInfo.Position = UDim2.new(1, -280, 1, -140)
RightInfo.BackgroundColor3 = COLORS.panel
RightInfo.BackgroundTransparency = 0.1
RightInfo.BorderSizePixel = 0
RightInfo.ZIndex = 2
RightInfo.Parent = ScreenGui
addCorner(RightInfo, 12)
addStroke(RightInfo, COLORS.border, 1)
addPadding(RightInfo, 16)

local MapLabel = Instance.new("TextLabel")
MapLabel.Text = "🗺  BSC PRISON MAP"
MapLabel.Size = UDim2.new(1, 0, 0, 22)
MapLabel.Position = UDim2.new(0, 0, 0, 0)
MapLabel.BackgroundTransparency = 1
MapLabel.TextColor3 = COLORS.accent
MapLabel.Font = Enum.Font.GothamBold
MapLabel.TextSize = 12
MapLabel.TextXAlignment = Enum.TextXAlignment.Left
MapLabel.ZIndex = 3
MapLabel.Parent = RightInfo

local MapDesc = Instance.new("TextLabel")
MapDesc.Text = "Harita yükleniyor...\nKuş bakışı görünüm aktif."
MapDesc.Size = UDim2.new(1, 0, 0, 50)
MapDesc.Position = UDim2.new(0, 0, 0, 28)
MapDesc.BackgroundTransparency = 1
MapDesc.TextColor3 = COLORS.textDim
MapDesc.Font = Enum.Font.Gotham
MapDesc.TextSize = 11
MapDesc.TextXAlignment = Enum.TextXAlignment.Left
MapDesc.TextWrapped = true
MapDesc.ZIndex = 3
MapDesc.Parent = RightInfo

-- Oyuncu sayısı
local PlayerCountLabel = Instance.new("TextLabel")
PlayerCountLabel.Text = "👥  " .. #Players:GetPlayers() .. " / 50 Oyuncu"
PlayerCountLabel.Size = UDim2.new(1, 0, 0, 20)
PlayerCountLabel.Position = UDim2.new(0, 0, 0, 82)
PlayerCountLabel.BackgroundTransparency = 1
PlayerCountLabel.TextColor3 = COLORS.success
PlayerCountLabel.Font = Enum.Font.GothamBold
PlayerCountLabel.TextSize = 12
PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerCountLabel.ZIndex = 3
PlayerCountLabel.Parent = RightInfo

-- ─────────────────────────────────────────────
-- KAMERA KURULUMU
-- ─────────────────────────────────────────────
local Camera = workspace.CurrentCamera
Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = selectedAngle

local cameraAngle = 0
RunService.RenderStepped:Connect(function(dt)
	if ScreenGui.Parent and ScreenGui.Enabled then
		cameraAngle = cameraAngle + cameraRotSpeed * dt * 60
		local baseCF = selectedAngle
		local rotated = CFrame.new(baseCF.Position) * CFrame.Angles(0, cameraAngle, 0) * CFrame.new(0, 0, 0)
		-- Yatay döndürme: orijin etrafında
		local origin = Vector3.new(0, baseCF.Position.Y, 0)
		local radius = (Vector3.new(baseCF.Position.X, 0, baseCF.Position.Z)).Magnitude
		local newPos = Vector3.new(
			math.cos(cameraAngle) * radius,
			baseCF.Position.Y,
			math.sin(cameraAngle) * radius
		)
		Camera.CFrame = CFrame.new(newPos, origin) * CFrame.Angles(math.rad(-40), 0, 0)
	end
end)

-- ─────────────────────────────────────────────
-- SETTINGS POPUP
-- ─────────────────────────────────────────────
local function createSettingsPopup()
	local popup = Instance.new("Frame")
	popup.Name = "SettingsPopup"
	popup.Size = UDim2.new(0, 380, 0, 420)
	popup.Position = UDim2.new(0.5, -190, 0.5, -210)
	popup.BackgroundColor3 = COLORS.panel
	popup.BorderSizePixel = 0
	popup.ZIndex = 20
	popup.Visible = false
	popup.Parent = ScreenGui
	addCorner(popup, 14)
	addStroke(popup, COLORS.border, 1)

	-- Başlık
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = COLORS.accentDark
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 21
	titleBar.Parent = popup
	addCorner(titleBar, 14)

	-- Alt köşe düzeltme
	local titleBarFix = Instance.new("Frame")
	titleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
	titleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
	titleBarFix.BackgroundColor3 = COLORS.accentDark
	titleBarFix.BorderSizePixel = 0
	titleBarFix.ZIndex = 21
	titleBarFix.Parent = titleBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = "⚙  SETTINGS"
	titleLbl.Size = UDim2.new(1, -60, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.new(1,1,1)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 16
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 22
	titleLbl.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = "✕"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 7)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 22
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 8)

	-- İçerik
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -32, 1, -66)
	content.Position = UDim2.new(0, 16, 0, 58)
	content.BackgroundTransparency = 1
	content.ZIndex = 21
	content.Parent = popup

	local contentList = Instance.new("UIListLayout")
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Padding = UDim.new(0, 12)
	contentList.Parent = content

	-- Toggle oluşturma fonksiyonu
	local function createToggle(parent, label, defaultOn, layoutOrder, onChange)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = COLORS.btnNormal
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder
		row.ZIndex = 22
		row.Parent = parent
		addCorner(row, 8)
		addStroke(row, COLORS.border, 1)

		local lbl = Instance.new("TextLabel")
		lbl.Text = label
		lbl.Size = UDim2.new(1, -70, 1, 0)
		lbl.Position = UDim2.new(0, 14, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = COLORS.text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 23
		lbl.Parent = row

		local toggleBg = Instance.new("Frame")
		toggleBg.Size = UDim2.new(0, 44, 0, 24)
		toggleBg.Position = UDim2.new(1, -58, 0.5, -12)
		toggleBg.BackgroundColor3 = defaultOn and COLORS.accent or COLORS.border
		toggleBg.BorderSizePixel = 0
		toggleBg.ZIndex = 23
		toggleBg.Parent = row
		addCorner(toggleBg, 12)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 18, 0, 18)
		knob.Position = defaultOn and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		knob.BackgroundColor3 = Color3.new(1,1,1)
		knob.BorderSizePixel = 0
		knob.ZIndex = 24
		knob.Parent = toggleBg
		addCorner(knob, 9)

		local isOn = defaultOn
		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(1, 0, 1, 0)
		toggleBtn.BackgroundTransparency = 1
		toggleBtn.Text = ""
		toggleBtn.ZIndex = 25
		toggleBtn.Parent = row

		toggleBtn.MouseButton1Click:Connect(function()
			isOn = not isOn
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
			makeTween(toggleBg, tweenInfo, {BackgroundColor3 = isOn and COLORS.accent or COLORS.border}):Play()
			makeTween(knob, tweenInfo, {Position = isOn and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
			if onChange then onChange(isOn) end
		end)

		return row
	end

	-- Slider oluşturma fonksiyonu
	local function createSlider(parent, label, min, max, default, layoutOrder, onChange)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = COLORS.btnNormal
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder
		row.ZIndex = 22
		row.Parent = parent
		addCorner(row, 8)
		addStroke(row, COLORS.border, 1)

		local lbl = Instance.new("TextLabel")
		lbl.Text = label
		lbl.Size = UDim2.new(1, -60, 0, 24)
		lbl.Position = UDim2.new(0, 14, 0, 6)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = COLORS.text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 23
		lbl.Parent = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Text = tostring(default)
		valLbl.Size = UDim2.new(0, 50, 0, 24)
		valLbl.Position = UDim2.new(1, -64, 0, 6)
		valLbl.BackgroundTransparency = 1
		valLbl.TextColor3 = COLORS.accent
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextSize = 13
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.ZIndex = 23
		valLbl.Parent = row

		local trackBg = Instance.new("Frame")
		trackBg.Size = UDim2.new(1, -28, 0, 6)
		trackBg.Position = UDim2.new(0, 14, 0, 40)
		trackBg.BackgroundColor3 = COLORS.border
		trackBg.BorderSizePixel = 0
		trackBg.ZIndex = 23
		trackBg.Parent = row
		addCorner(trackBg, 3)

		local fill = Instance.new("Frame")
		local pct = (default - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = COLORS.accent
		fill.BorderSizePixel = 0
		fill.ZIndex = 24
		fill.Parent = trackBg
		addCorner(fill, 3)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
		knob.BackgroundColor3 = Color3.new(1,1,1)
		knob.BorderSizePixel = 0
		knob.ZIndex = 25
		knob.Parent = trackBg
		addCorner(knob, 7)

		-- Sürükleme
		local dragging = false
		local dragBtn = Instance.new("TextButton")
		dragBtn.Size = UDim2.new(1, 0, 0, 30)
		dragBtn.Position = UDim2.new(0, 0, 0, 30)
		dragBtn.BackgroundTransparency = 1
		dragBtn.Text = ""
		dragBtn.ZIndex = 26
		dragBtn.Parent = row

		local function updateSlider(inputX)
			local trackPos = trackBg.AbsolutePosition.X
			local trackSize = trackBg.AbsoluteSize.X
			local relX = math.clamp((inputX - trackPos) / trackSize, 0, 1)
			local value = math.floor(min + relX * (max - min) + 0.5)
			local newPct = (value - min) / (max - min)
			fill.Size = UDim2.new(newPct, 0, 1, 0)
			knob.Position = UDim2.new(newPct, -7, 0.5, -7)
			valLbl.Text = tostring(value)
			if onChange then onChange(value) end
		end

		dragBtn.MouseButton1Down:Connect(function()
			dragging = true
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateSlider(input.Position.X)
			end
		end)
		dragBtn.MouseButton1Click:Connect(function()
			local mouse = LocalPlayer:GetMouse()
			updateSlider(mouse.X)
		end)

		return row
	end

	-- Ayar öğeleri
	createToggle(content, "🌑  Gölgeler (Shadows)", true, 1, function(v)
		-- Gölge ayarı: Lighting.GlobalShadows
		local ok, err = pcall(function()
			game:GetService("Lighting").GlobalShadows = v
		end)
	end)
	createToggle(content, "🌿  Çimen / Detay (Grass Detail)", true, 2, function(v)
		-- İleride workspace ayarı
	end)
	createToggle(content, "💧  Su Efektleri (Water FX)", true, 3, function(v)
		-- İleride
	end)
	createToggle(content, "🎵  Müzik (Music)", true, 4, function(v)
		-- İleride ses ayarı
	end)
	createSlider(content, "🖥  Render Mesafesi", 64, 512, 256, 5, function(v)
		workspace.StreamingMinRadius = v
	end)

	-- Kapatma
	closeBtn.MouseButton1Click:Connect(function()
		makeTween(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 380, 0, 0),
			Position = UDim2.new(0.5, -190, 0.5, 0)
		}):Play()
		task.delay(0.2, function() popup.Visible = false end)
	end)

	return popup
end

-- ─────────────────────────────────────────────
-- UPDATE LOGS POPUP
-- ─────────────────────────────────────────────
local function createUpdateLogsPopup()
	local popup = Instance.new("Frame")
	popup.Name = "UpdateLogsPopup"
	popup.Size = UDim2.new(0, 420, 0, 460)
	popup.Position = UDim2.new(0.5, -210, 0.5, -230)
	popup.BackgroundColor3 = COLORS.panel
	popup.BorderSizePixel = 0
	popup.ZIndex = 20
	popup.Visible = false
	popup.Parent = ScreenGui
	addCorner(popup, 14)
	addStroke(popup, COLORS.border, 1)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 90, 60)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 21
	titleBar.Parent = popup
	addCorner(titleBar, 14)

	local titleBarFix = Instance.new("Frame")
	titleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
	titleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
	titleBarFix.BackgroundColor3 = Color3.fromRGB(30, 90, 60)
	titleBarFix.BorderSizePixel = 0
	titleBarFix.ZIndex = 21
	titleBarFix.Parent = titleBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = "📋  UPDATE LOGS"
	titleLbl.Size = UDim2.new(1, -60, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.new(1,1,1)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 16
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 22
	titleLbl.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = "✕"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 7)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 22
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 8)

	-- Kaydırılabilir içerik
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -32, 1, -66)
	scrollFrame.Position = UDim2.new(0, 16, 0, 58)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = COLORS.accent
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 21
	scrollFrame.Parent = popup

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scrollFrame

	-- Güncelleme kayıtları
	local logs = {
		{version = "v1.0.0", date = "06 Mar 2026", tag = "BETA LAUNCH", color = COLORS.accent, items = {
			"BSC Prison beta sürümü yayınlandı.",
			"Karakter oluşturma sistemi eklendi.",
			"4 takım sistemi: Cop, Prisoner, Criminal, Hostage.",
			"İsyan mekaniği eklendi.",
			"Solve sistemi eklendi.",
			"Ana menü ve ayarlar arayüzü tamamlandı.",
		}},
		{version = "v0.9.0", date = "01 Mar 2026", tag = "PRE-RELEASE", color = Color3.fromRGB(180, 140, 60), items = {
			"Harita taslağı oluşturuldu.",
			"Temel sunucu altyapısı kuruldu.",
			"RemoteEvent sistemi kuruldu.",
		}},
	}

	for i, log in ipairs(logs) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = COLORS.btnNormal
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.ZIndex = 22
		card.Parent = scrollFrame
		addCorner(card, 10)
		addStroke(card, COLORS.border, 1)
		addPadding(card, 14)

		local cardList = Instance.new("UIListLayout")
		cardList.SortOrder = Enum.SortOrder.LayoutOrder
		cardList.Padding = UDim.new(0, 6)
		cardList.Parent = card

		-- Versiyon başlığı
		local header = Instance.new("Frame")
		header.Size = UDim2.new(1, 0, 0, 28)
		header.BackgroundTransparency = 1
		header.LayoutOrder = 0
		header.ZIndex = 23
		header.Parent = card

		local versionLbl = Instance.new("TextLabel")
		versionLbl.Text = log.version
		versionLbl.Size = UDim2.new(0, 60, 1, 0)
		versionLbl.BackgroundTransparency = 1
		versionLbl.TextColor3 = log.color
		versionLbl.Font = Enum.Font.GothamBlack
		versionLbl.TextSize = 15
		versionLbl.TextXAlignment = Enum.TextXAlignment.Left
		versionLbl.ZIndex = 24
		versionLbl.Parent = header

		local tagLbl = Instance.new("TextLabel")
		tagLbl.Text = log.tag
		tagLbl.Size = UDim2.new(0, 100, 0, 20)
		tagLbl.Position = UDim2.new(0, 68, 0.5, -10)
		tagLbl.BackgroundColor3 = log.color
		tagLbl.BackgroundTransparency = 0.7
		tagLbl.TextColor3 = log.color
		tagLbl.Font = Enum.Font.GothamBold
		tagLbl.TextSize = 10
		tagLbl.ZIndex = 24
		tagLbl.Parent = header
		addCorner(tagLbl, 4)

		local dateLbl = Instance.new("TextLabel")
		dateLbl.Text = log.date
		dateLbl.Size = UDim2.new(1, -180, 1, 0)
		dateLbl.Position = UDim2.new(0, 180, 0, 0)
		dateLbl.BackgroundTransparency = 1
		dateLbl.TextColor3 = COLORS.textDim
		dateLbl.Font = Enum.Font.Gotham
		dateLbl.TextSize = 11
		dateLbl.TextXAlignment = Enum.TextXAlignment.Right
		dateLbl.ZIndex = 24
		dateLbl.Parent = header

		-- Öğeler
		for j, item in ipairs(log.items) do
			local itemLbl = Instance.new("TextLabel")
			itemLbl.Text = "  •  " .. item
			itemLbl.Size = UDim2.new(1, 0, 0, 20)
			itemLbl.AutomaticSize = Enum.AutomaticSize.Y
			itemLbl.BackgroundTransparency = 1
			itemLbl.TextColor3 = COLORS.textDim
			itemLbl.Font = Enum.Font.Gotham
			itemLbl.TextSize = 12
			itemLbl.TextXAlignment = Enum.TextXAlignment.Left
			itemLbl.TextWrapped = true
			itemLbl.LayoutOrder = j
			itemLbl.ZIndex = 23
			itemLbl.Parent = card
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		makeTween(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 420, 0, 0),
			Position = UDim2.new(0.5, -210, 0.5, 0)
		}):Play()
		task.delay(0.2, function() popup.Visible = false end)
	end)

	return popup
end

-- ─────────────────────────────────────────────
-- RULES POPUP
-- ─────────────────────────────────────────────
local function createRulesPopup()
	local popup = Instance.new("Frame")
	popup.Name = "RulesPopup"
	popup.Size = UDim2.new(0, 420, 0, 460)
	popup.Position = UDim2.new(0.5, -210, 0.5, -230)
	popup.BackgroundColor3 = COLORS.panel
	popup.BorderSizePixel = 0
	popup.ZIndex = 20
	popup.Visible = false
	popup.Parent = ScreenGui
	addCorner(popup, 14)
	addStroke(popup, COLORS.border, 1)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 21
	titleBar.Parent = popup
	addCorner(titleBar, 14)

	local titleBarFix = Instance.new("Frame")
	titleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
	titleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
	titleBarFix.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
	titleBarFix.BorderSizePixel = 0
	titleBarFix.ZIndex = 21
	titleBarFix.Parent = titleBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = "📜  RULES"
	titleLbl.Size = UDim2.new(1, -60, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.new(1,1,1)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 16
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 22
	titleLbl.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = "✕"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 7)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 22
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 8)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -32, 1, -66)
	scrollFrame.Position = UDim2.new(0, 16, 0, 58)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 160, 60)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 21
	scrollFrame.Parent = popup

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scrollFrame

	local rules = {
		"Kurallara uyulması zorunludur.",
		"Exploit, hile veya bug kullanmak yasaktır.",
		"Diğer oyunculara saygılı olun.",
		"Takım arkadaşlarınıza zarar vermeyin.",
		"Admin kararları kesindir.",
		"Spam ve küfür yasaktır.",
		"Oyun kuralları ihlali = ban.",
		"[Daha fazla kural yakında eklenecek]",
	}

	for i, rule in ipairs(rules) do
		local ruleFrame = Instance.new("Frame")
		ruleFrame.Size = UDim2.new(1, 0, 0, 40)
		ruleFrame.BackgroundColor3 = COLORS.btnNormal
		ruleFrame.BorderSizePixel = 0
		ruleFrame.LayoutOrder = i
		ruleFrame.ZIndex = 22
		ruleFrame.Parent = scrollFrame
		addCorner(ruleFrame, 8)
		addStroke(ruleFrame, COLORS.border, 1)

		local numLbl = Instance.new("TextLabel")
		numLbl.Text = tostring(i)
		numLbl.Size = UDim2.new(0, 30, 1, 0)
		numLbl.Position = UDim2.new(0, 10, 0, 0)
		numLbl.BackgroundTransparency = 1
		numLbl.TextColor3 = Color3.fromRGB(220, 160, 60)
		numLbl.Font = Enum.Font.GothamBlack
		numLbl.TextSize = 14
		numLbl.ZIndex = 23
		numLbl.Parent = ruleFrame

		local ruleLbl = Instance.new("TextLabel")
		ruleLbl.Text = rule
		ruleLbl.Size = UDim2.new(1, -50, 1, 0)
		ruleLbl.Position = UDim2.new(0, 44, 0, 0)
		ruleLbl.BackgroundTransparency = 1
		ruleLbl.TextColor3 = COLORS.text
		ruleLbl.Font = Enum.Font.Gotham
		ruleLbl.TextSize = 12
		ruleLbl.TextXAlignment = Enum.TextXAlignment.Left
		ruleLbl.ZIndex = 23
		ruleLbl.Parent = ruleFrame
	end

	closeBtn.MouseButton1Click:Connect(function()
		makeTween(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 420, 0, 0),
			Position = UDim2.new(0.5, -210, 0.5, 0)
		}):Play()
		task.delay(0.2, function() popup.Visible = false end)
	end)

	return popup
end

-- ─────────────────────────────────────────────
-- POPUP'LARI OLUŞTUR
-- ─────────────────────────────────────────────
local settingsPopup   = createSettingsPopup()
local updateLogsPopup = createUpdateLogsPopup()
local rulesPopup      = createRulesPopup()

local function openPopup(popup)
	popup.Size = UDim2.new(popup.Size.X.Scale, popup.Size.X.Offset, 0, 0)
	popup.Visible = true
	makeTween(popup, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(popup.Size.X.Scale, popup.Size.X.Offset, 0, 460)
	}):Play()
end

SettingsBtn.MouseButton1Click:Connect(function()
	openPopup(settingsPopup)
end)
UpdateLogBtn.MouseButton1Click:Connect(function()
	openPopup(updateLogsPopup)
end)
RulesBtn.MouseButton1Click:Connect(function()
	openPopup(rulesPopup)
end)

-- ─────────────────────────────────────────────
-- PLAY BUTONU → Karartma + Karakter Oluşturma
-- ─────────────────────────────────────────────
local CharacterCreatorModule = require(script.Parent:WaitForChild("CharacterCreatorUI"))

PlayBtn.MouseButton1Click:Connect(function()
	PlayBtn.Active = false

	-- Ekranı karart
	local fadeFrame = Instance.new("Frame")
	fadeFrame.Size = UDim2.new(1, 0, 1, 0)
	fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	fadeFrame.BackgroundTransparency = 1
	fadeFrame.BorderSizePixel = 0
	fadeFrame.ZIndex = 100
	fadeFrame.Parent = ScreenGui

	makeTween(fadeFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()

	task.delay(0.7, function()
		-- Kamera sıfırla
		RunService:UnbindFromRenderStep("BSCCameraRotate")
		ScreenGui.Enabled = false

		-- Karakter oluşturma ekranını aç
		CharacterCreatorModule.Open(PlayerGui)
	end)
end)

-- ─────────────────────────────────────────────
-- GİRİŞ ANİMASYONU
-- ─────────────────────────────────────────────
LeftPanel.Position = UDim2.new(-0.25, 0, 0, 0)
LeftPanel.BackgroundTransparency = 1

task.wait(0.1)
makeTween(LeftPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 0.05
}):Play()

task.delay(0.3, function()
	RightInfo.BackgroundTransparency = 1
	RightInfo.Position = UDim2.new(1, -260, 1, -120)
	makeTween(RightInfo, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.1,
		Position = UDim2.new(1, -280, 1, -140)
	}):Play()
end)

print("[BSC Prison] MainMenuUI yüklendi.")
