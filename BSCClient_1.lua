-- ============================================================
-- BSC PRISON | BSCClient.lua
-- StarterPlayerScripts > BSCClient (LocalScript)
-- Ana İstemci Giriş Noktası - Tüm sistemleri başlatır
-- ============================================================

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- SUNUCU HAZIR OLANA KADAR BEKLE
-- ─────────────────────────────────────────────
local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes", 15)
if not Remotes then
	warn("[BSC Prison] BSCRemotes bulunamadı! Sunucu scripti çalışıyor mu?")
	return
end

print("[BSC Prison] BSCClient başlatıldı.")

-- ─────────────────────────────────────────────
-- TÜM OYUN UI VE MANTIĞINI BAŞLAT
-- ─────────────────────────────────────────────
local FullGameUI = require(script.Parent:WaitForChild("FullGameUI"))

-- BAŞLANGIÇ EKRANI (Kısa splash)
local SplashGui = Instance.new("ScreenGui")
SplashGui.Name = "BSCSplash"
SplashGui.ResetOnSpawn = false
SplashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SplashGui.IgnoreGuiInset = true
SplashGui.ZIndex = 999
SplashGui.Parent = PlayerGui

local splashBG = Instance.new("Frame")
splashBG.Size = UDim2.new(1, 0, 1, 0)
splashBG.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
splashBG.BorderSizePixel = 0
splashBG.ZIndex = 1000
splashBG.Parent = SplashGui

local splashLogo = Instance.new("TextLabel")
splashLogo.Text = "BSC"
splashLogo.Size = UDim2.new(0, 300, 0, 80)
splashLogo.Position = UDim2.new(0.5, -150, 0.5, -60)
splashLogo.BackgroundTransparency = 1
splashLogo.TextColor3 = Color3.fromRGB(90, 120, 255)
splashLogo.Font = Enum.Font.GothamBlack
splashLogo.TextSize = 72
splashLogo.ZIndex = 1001
splashLogo.Parent = splashBG

local splashPrison = Instance.new("TextLabel")
splashPrison.Text = "PRISON"
splashPrison.Size = UDim2.new(0, 300, 0, 40)
splashPrison.Position = UDim2.new(0.5, -150, 0.5, 28)
splashPrison.BackgroundTransparency = 1
splashPrison.TextColor3 = Color3.fromRGB(220, 220, 235)
splashPrison.Font = Enum.Font.GothamBlack
splashPrison.TextSize = 32
splashPrison.ZIndex = 1001
splashPrison.Parent = splashBG

-- Splash animasyonu
task.spawn(function()
	task.wait(0.3)
	TweenService:Create(splashLogo, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
	task.wait(0.3)
	TweenService:Create(splashPrison, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
	task.wait(1.2)
	TweenService:Create(splashBG, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	task.wait(0.5)
	SplashGui:Destroy()

	-- FullGameUI.UIManager'ı Başlat
	FullGameUI.UIManager.Init()
end)

-- ─────────────────────────────────────────────
-- SUNUCU BİLDİRİMLERİNİ DİNLE
-- ─────────────────────────────────────────────
local RE_Notification = Remotes:WaitForChild("Notification")
RE_Notification.OnClientEvent:Connect(function(message, notifType)
	local color = Color3.fromRGB(90, 120, 255)
	if notifType == "success" then color = Color3.fromRGB(60, 200, 120)
	elseif notifType == "danger" then color = Color3.fromRGB(220, 60, 60)
	elseif notifType == "warning" then color = Color3.fromRGB(220, 160, 60)
	end
	FullGameUI.GameHUD.ShowNotification(PlayerGui:FindFirstChild("BSCGameHUD"), message, color)
end)

print("[BSC Prison] BSCClient hazır.")
