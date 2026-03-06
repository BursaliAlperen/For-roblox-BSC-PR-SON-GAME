-- ============================================================
-- BSC PRISON | BSC_Interface.lua
-- StarterPlayerScripts > BSC_Interface (ModuleScript)
-- AAA Kalitesinde Modern ve Minimal UI Sistemi
-- ============================================================

local BSC_Interface = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- YARDIMCI UI FONKSİYONLARI
-- ─────────────────────────────────────────────
local function addCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 10)
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or Color3.fromRGB(45, 45, 60)
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function makeButton(parent, text, pos, size, color)
	local btn = Instance.new("TextButton", parent)
	btn.Name = text .. "_Btn"
	btn.Text = text
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = color or Color3.fromRGB(20, 20, 28)
	btn.TextColor3 = Color3.fromRGB(220, 220, 235)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = false
	addCorner(btn, 12)
	addStroke(btn)
	
	-- Hover Efekti
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(35, 35, 55)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = color or Color3.fromRGB(20, 20, 28)}):Play()
	end)
	
	return btn
end

-- ─────────────────────────────────────────────
-- ANA MENÜ (BSC PRISON)
-- ─────────────────────────────────────────────
function BSC_Interface.OpenMainMenu(onPlay)
	local ScreenGui = Instance.new("ScreenGui", PlayerGui)
	ScreenGui.Name = "BSC_MainMenu"
	ScreenGui.IgnoreGuiInset = true
	
	local BG = Instance.new("Frame", ScreenGui)
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
	BG.ZIndex = 1
	
	-- Başlık (BSC PRISON)
	local Title = Instance.new("TextLabel", BG)
	Title.Text = "BSC PRISON"
	Title.Size = UDim2.new(0, 400, 0, 100)
	Title.Position = UDim2.new(0.5, -200, 0, 100)
	Title.BackgroundTransparency = 1
	Title.TextColor3 = Color3.fromRGB(90, 120, 255)
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 64
	Title.ZIndex = 5
	
	-- Menü Butonları
	local MenuFrame = Instance.new("Frame", BG)
	MenuFrame.Size = UDim2.new(0, 250, 0, 350)
	MenuFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
	MenuFrame.BackgroundTransparency = 1
	
	local UIList = Instance.new("UIListLayout", MenuFrame)
	UIList.Padding = UDim.new(0, 15)
	UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local PlayBtn = makeButton(MenuFrame, "OYNA", UDim2.new(0,0,0,0), UDim2.new(1, 0, 0, 55), Color3.fromRGB(25, 35, 75))
	local SettingsBtn = makeButton(MenuFrame, "AYARLAR", UDim2.new(0,0,0,0), UDim2.new(1, 0, 0, 50))
	local LogsBtn = makeButton(MenuFrame, "GÜNCELLEMELER", UDim2.new(0,0,0,0), UDim2.new(1, 0, 0, 50))
	local RulesBtn = makeButton(MenuFrame, "KURALLAR", UDim2.new(0,0,0,0), UDim2.new(1, 0, 0, 50))
	
	PlayBtn.MouseButton1Click:Connect(function()
		TweenService:Create(BG, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
		TweenService:Create(MenuFrame, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -125, 1, 100)}):Play()
		task.wait(0.8)
		ScreenGui:Destroy()
		if onPlay then onPlay() end
	end)
end

-- ─────────────────────────────────────────────
-- KARAKTER OLUŞTURMA (WIZARD)
-- ─────────────────────────────────────────────
function BSC_Interface.OpenCharacterCreator(onComplete)
	local ScreenGui = Instance.new("ScreenGui", PlayerGui)
	ScreenGui.Name = "BSC_CharacterCreator"
	
	local Panel = Instance.new("Frame", ScreenGui)
	Panel.Size = UDim2.new(0, 450, 0, 550)
	Panel.Position = UDim2.new(0.5, -225, 0.5, -275)
	Panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	addCorner(Panel, 15)
	addStroke(Panel)
	
	local Title = Instance.new("TextLabel", Panel)
	Title.Text = "KARAKTER OLUŞTURMA"
	Title.Size = UDim2.new(1, 0, 0, 80)
	Title.BackgroundTransparency = 1
	Title.TextColor3 = Color3.fromRGB(90, 120, 255)
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 24
	
	-- Input Alanları
	local Content = Instance.new("Frame", Panel)
	Content.Size = UDim2.new(1, -60, 1, -150)
	Content.Position = UDim2.new(0, 30, 0, 100)
	Content.BackgroundTransparency = 1
	
	local function makeInput(placeholder, pos)
		local box = Instance.new("TextBox", Content)
		box.PlaceholderText = placeholder
		box.Position = pos
		box.Size = UDim2.new(1, 0, 0, 50)
		box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
		box.TextColor3 = Color3.new(1,1,1)
		box.Font = Enum.Font.Gotham
		box.TextSize = 14
		addCorner(box, 10)
		addStroke(box)
		return box
	end
	
	local FirstName = makeInput("İsim", UDim2.new(0, 0, 0, 0))
	local LastName = makeInput("Soyisim", UDim2.new(0, 0, 0, 65))
	local Age = makeInput("Yaş", UDim2.new(0, 0, 0, 130))
	
	-- Cinsiyet Seçimi
	local GenderFrame = Instance.new("Frame", Content)
	GenderFrame.Size = UDim2.new(1, 0, 0, 60)
	GenderFrame.Position = UDim2.new(0, 0, 0, 195)
	GenderFrame.BackgroundTransparency = 1
	
	local MaleBtn = makeButton(GenderFrame, "ERKEK", UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0), Color3.fromRGB(40, 60, 120))
	local FemaleBtn = makeButton(GenderFrame, "KADIN", UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0), Color3.fromRGB(120, 40, 80))
	
	local ConfirmBtn = makeButton(Panel, "ONAYLA VE DEVAM ET", UDim2.new(0, 30, 1, -80), UDim2.new(1, -60, 0, 55), Color3.fromRGB(25, 75, 35))
	
	ConfirmBtn.MouseButton1Click:Connect(function()
		if FirstName.Text ~= "" and LastName.Text ~= "" then
			local data = {
				firstName = FirstName.Text,
				lastName = LastName.Text,
				age = Age.Text,
				gender = "Male" -- Basitçe
			}
			ScreenGui:Destroy()
			if onComplete then onComplete(data) end
		end
	end)
end

-- ─────────────────────────────────────────────
-- OYUN İÇİ HUD (AAA DÜZENİ)
-- ─────────────────────────────────────────────
function BSC_Interface.InitHUD(teamId, charData)
	local ScreenGui = Instance.new("ScreenGui", PlayerGui)
	ScreenGui.Name = "BSC_HUD"
	
	-- Üst Bilgi Paneli (Modern Minimal)
	local TopInfo = Instance.new("Frame", ScreenGui)
	TopInfo.Size = UDim2.new(0, 300, 0, 80)
	TopInfo.Position = UDim2.new(0, 20, 0, 20)
	TopInfo.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	TopInfo.BackgroundTransparency = 0.3
	addCorner(TopInfo, 12)
	addStroke(TopInfo)
	
	local NameLbl = Instance.new("TextLabel", TopInfo)
	NameLbl.Text = (charData.firstName or "Mahkum") .. " " .. (charData.lastName or "")
	NameLbl.Size = UDim2.new(1, -20, 0, 30)
	NameLbl.Position = UDim2.new(0, 15, 0, 10)
	NameLbl.TextColor3 = Color3.new(1,1,1)
	NameLbl.Font = Enum.Font.GothamBlack
	NameLbl.TextSize = 16
	NameLbl.BackgroundTransparency = 1
	NameLbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local MoneyLbl = Instance.new("TextLabel", TopInfo)
	MoneyLbl.Text = "BAKİYE: $500"
	MoneyLbl.Size = UDim2.new(1, -20, 0, 20)
	MoneyLbl.Position = UDim2.new(0, 15, 0, 40)
	MoneyLbl.TextColor3 = Color3.fromRGB(60, 220, 120)
	MoneyLbl.Font = Enum.Font.GothamBold
	MoneyLbl.TextSize = 14
	MoneyLbl.BackgroundTransparency = 1
	MoneyLbl.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Sağ Panel (Etkileşimler)
	local SideToggle = makeButton(ScreenGui, "<", UDim2.new(1, -60, 0.5, -25), UDim2.new(0, 45, 0, 50))
	
	local SidePanel = Instance.new("Frame", ScreenGui)
	SidePanel.Size = UDim2.new(0, 280, 0, 500)
	SidePanel.Position = UDim2.new(1, 20, 0.5, -250)
	SidePanel.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	addCorner(SidePanel, 15)
	addStroke(SidePanel)
	
	local isOpen = false
	SideToggle.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		local targetPos = isOpen and UDim2.new(1, -300, 0.5, -250) or UDim2.new(1, 20, 0.5, -250)
		local toggleText = isOpen and ">" or "<"
		SideToggle.Text = toggleText
		TweenService:Create(SidePanel, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = targetPos}):Play()
	end)
	
	-- Emotes Menüsü (Side Panel İçinde)
	local EmoteScroll = Instance.new("ScrollingFrame", SidePanel)
	EmoteScroll.Size = UDim2.new(1, -20, 1, -80)
	EmoteScroll.Position = UDim2.new(0, 10, 0, 60)
	EmoteScroll.BackgroundTransparency = 1
	EmoteScroll.ScrollBarThickness = 2
	
	local UIList = Instance.new("UIListLayout", EmoteScroll)
	UIList.Padding = UDim.new(0, 8)
	
	local Motion = require(script.Parent:WaitForChild("BSC_MotionEngine"))
	local emotes = {"Sleep", "Kneel", "HandsUp", "Sit", "Cower"}
	
	for _, name in ipairs(emotes) do
		local btn = makeButton(EmoteScroll, name, UDim2.new(0,0,0,0), UDim2.new(1, -5, 0, 45))
		btn.MouseButton1Click:Connect(function()
			Motion.PlayEmote(name)
		end)
	end
end

return BSC_Interface
