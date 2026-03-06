-- ============================================================
-- BSC PRISON | BSCClient.lua
-- StarterPlayerScripts > BSCClient (LocalScript)
-- Ana İstemci Giriş Noktası - Tüm modülleri başlatır
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
-- BAŞLANGIÇ EKRANI (Kısa splash)
-- ─────────────────────────────────────────────
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
splashLogo.TextTransparency = 1
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
splashPrison.TextTransparency = 1
splashPrison.ZIndex = 1001
splashPrison.Parent = splashBG

-- Splash animasyonu
task.spawn(function()
	task.wait(0.3)

	-- Logo belir
	TweenService:Create(splashLogo, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
		TextTransparency = 0
	}):Play()
	task.wait(0.3)
	TweenService:Create(splashPrison, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
		TextTransparency = 0
	}):Play()

	task.wait(1.2)

	-- Kaybol
	TweenService:Create(splashBG, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(splashLogo, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(splashPrison, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	task.wait(0.5)
	SplashGui:Destroy()

	-- Ana menüyü başlat
	local MainMenuScript = script.Parent:WaitForChild("MainMenuUI")
	-- MainMenuUI bir LocalScript olduğu için require yerine doğrudan çalışır
	-- Eğer ModuleScript olarak düzenlenmişse:
	-- local MainMenu = require(MainMenuScript)
	-- MainMenu.Open(PlayerGui)
end)

-- ─────────────────────────────────────────────
-- SUNUCU BİLDİRİMLERİNİ DİNLE
-- ─────────────────────────────────────────────
local RE_Notification = Remotes:WaitForChild("Notification")
local RE_RiotAlert    = Remotes:WaitForChild("RiotAlert")
local RE_UpdateBonds  = Remotes:WaitForChild("UpdateBonds")

RE_Notification.OnClientEvent:Connect(function(message, notifType)
	-- HUD varsa bildirim göster
	local hudGui = PlayerGui:FindFirstChild("BSCGameHUD")
	if hudGui then
		local HUDModule = require(script.Parent:WaitForChild("GameHUD"))
		local color = Color3.fromRGB(90, 120, 255)
		if notifType == "success" then color = Color3.fromRGB(60, 200, 120)
		elseif notifType == "danger" then color = Color3.fromRGB(220, 60, 60)
		elseif notifType == "warning" then color = Color3.fromRGB(220, 160, 60)
		end
		HUDModule.ShowNotification(hudGui, message, color)
	end
end)

RE_RiotAlert.OnClientEvent:Connect(function(message, rioterName)
	-- Polis uyarısı
	local hudGui = PlayerGui:FindFirstChild("BSCGameHUD")
	if hudGui then
		-- Kırmızı uyarı banner
		local banner = Instance.new("Frame")
		banner.Size = UDim2.new(0, 400, 0, 50)
		banner.Position = UDim2.new(0.5, -200, 0, -60)
		banner.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
		banner.BackgroundTransparency = 0.1
		banner.BorderSizePixel = 0
		banner.ZIndex = 50
		banner.Parent = hudGui

		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 10)
		uiCorner.Parent = banner

		local bannerLbl = Instance.new("TextLabel")
		bannerLbl.Text = "🚨  " .. message
		bannerLbl.Size = UDim2.new(1, -20, 1, 0)
		bannerLbl.Position = UDim2.new(0, 10, 0, 0)
		bannerLbl.BackgroundTransparency = 1
		bannerLbl.TextColor3 = Color3.new(1,1,1)
		bannerLbl.Font = Enum.Font.GothamBold
		bannerLbl.TextSize = 14
		bannerLbl.ZIndex = 51
		bannerLbl.Parent = banner

		TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -200, 0, 58)
		}):Play()

		task.delay(4, function()
			TweenService:Create(banner, TweenInfo.new(0.3), {
				Position = UDim2.new(0.5, -200, 0, -60),
				BackgroundTransparency = 1
			}):Play()
			task.delay(0.3, function() banner:Destroy() end)
		end)
	end
end)

RE_UpdateBonds.OnClientEvent:Connect(function(bonds)
	-- Bağlar güncellendi - Solve panelini güncelle
	-- Bu event geldiğinde HUD'daki solve listesi yenilenir
	print("[BSC Prison] Bağlar güncellendi:", bonds)
end)

print("[BSC Prison] BSCClient hazır.")
