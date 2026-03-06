-- ============================================================
-- BSC PRISON | BSC_ClientCore.lua
-- StarterPlayerScripts > BSC_ClientCore (ModuleScript)
-- AAA Kalitesinde İstemci Çekirdeği ve Modüler Yönetim
-- ============================================================

local BSC_ClientCore = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- MODÜL İÇE AKTARMA (MODULAR SYSTEM)
-- ─────────────────────────────────────────────
local Architect = require(script.Parent:WaitForChild("BSC_MapArchitect"))
local Interface = require(script.Parent:WaitForChild("BSC_Interface"))
local Motion = require(script.Parent:WaitForChild("BSC_MotionEngine"))
local JobSystem = require(script.Parent:WaitForChild("BSC_JobSystem"))

-- ─────────────────────────────────────────────
-- GLOBAL AYARLAR VE RENKLER
-- ─────────────────────────────────────────────
BSC_ClientCore.COLORS = {
	PRIMARY     = Color3.fromRGB(12, 12, 18),
	SECONDARY   = Color3.fromRGB(18, 18, 26),
	ACCENT      = Color3.fromRGB(90, 120, 255),
	TEXT        = Color3.fromRGB(225, 225, 240),
	TEXT_DIM    = Color3.fromRGB(140, 140, 160),
	DANGER      = Color3.fromRGB(230, 60, 60),
	SUCCESS     = Color3.fromRGB(60, 220, 120),
	WARNING     = Color3.fromRGB(240, 180, 40),
	GOLD        = Color3.fromRGB(255, 215, 0),
}

-- ─────────────────────────────────────────────
-- ÇEKİRDEK BAŞLATICI (BOOTSTRAP)
-- ─────────────────────────────────────────────
function BSC_ClientCore.Initialize()
	print("[BSC Client] Çekirdek Sistem Başlatılıyor... 🚀")
	
	-- 0. ANIMASYON MOTORUNU BAŞLAT
	Motion.Initialize()
	
	-- 1. HARİTA MİMARİSİNİ OLUŞTUR VE GÖREVLERİ KUR
	task.spawn(function()
		Architect.BuildPrison()
		JobSystem.SetupJobPoints()
	end)
	
	-- 2. ANA MENÜYÜ AÇ (Gecikmeli)
	task.wait(1.5)
	Interface.OpenMainMenu(function()
		-- Play'e basınca karakter oluşturma
		Interface.OpenCharacterCreator(function(charData)
			-- Takım seçimi (Şimdilik direkt mahkum)
			local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
			Remotes.JoinTeam:FireServer("prisoner")
			
			-- HUD'ı başlat
			Interface.InitHUD("prisoner", charData)
		end)
	end)
	
	-- 2. KAPI SİSTEMİ DİNLEYİCİSİ
	local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
	Remotes.RequestDoor.OnClientEvent:Connect(function(doorModel, isOpen)
		local doorPart = doorModel:FindFirstChild("DoorPart")
		if not doorPart then return end
		
		local targetCF = doorModel:GetAttribute("OriginalCFrame")
		if isOpen then
			targetCF = targetCF * CFrame.new(0, 0, 8) -- Sürgülü Kapı
		end
		
		local t = TweenService:Create(doorPart, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = targetCF})
		t:Play()
		
		-- Ses Efekti (İstemci Taraflı)
		local s = Instance.new("Sound", doorPart)
		s.SoundId = "rbxassetid://149100000"
		s.Volume = 0.6
		s:Play()
		task.delay(3, function() s:Destroy() end)
	end)
	
	-- 3. BİLDİRİM SİSTEMİ (MODERN POPUP)
	Remotes.Notification.OnClientEvent:Connect(function(msg, type)
		BSC_ClientCore.ShowNotification(msg, type)
	end)
	
	print("[BSC Client] Çekirdek Sistem Hazır! ✅")
end

-- ─────────────────────────────────────────────
-- MODERN BİLDİRİM SİSTEMİ
-- ─────────────────────────────────────────────
function BSC_ClientCore.ShowNotification(text, type)
	local ScreenGui = PlayerGui:FindFirstChild("BSC_Notifications") or Instance.new("ScreenGui", PlayerGui)
	ScreenGui.Name = "BSC_Notifications"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local color = BSC_ClientCore.COLORS.ACCENT
	if type == "danger" then color = BSC_ClientCore.COLORS.DANGER
	elseif type == "success" then color = BSC_ClientCore.COLORS.SUCCESS
	elseif type == "warning" then color = BSC_ClientCore.COLORS.WARNING end
	
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0, 0, 0, 45)
	notif.Position = UDim2.new(0.5, 0, 0, 100)
	notif.BackgroundColor3 = BSC_ClientCore.COLORS.SECONDARY
	notif.TextColor3 = color
	notif.Text = "  " .. text .. "  "
	notif.Font = Enum.Font.GothamBold
	notif.TextSize = 14
	notif.AutomaticSize = Enum.AutomaticSize.X
	notif.Parent = ScreenGui
	
	local c = Instance.new("UICorner", notif)
	c.CornerRadius = UDim.new(0, 22)
	local s = Instance.new("UIStroke", notif)
	s.Color = color
	s.Thickness = 1.5
	
	-- Animasyon
	notif.Position = UDim2.new(0.5, -notif.AbsoluteSize.X/2, 0, 80)
	notif.TextTransparency = 1
	notif.BackgroundTransparency = 1
	s.Transparency = 1
	
	TweenService:Create(notif, TweenInfo.new(0.4), {
		Position = UDim2.new(0.5, -notif.AbsoluteSize.X/2, 0, 120),
		TextTransparency = 0,
		BackgroundTransparency = 0,
		Transparency = 0
	}):Play()
	
	task.delay(4, function()
		local t = TweenService:Create(notif, TweenInfo.new(0.4), {
			Position = UDim2.new(0.5, -notif.AbsoluteSize.X/2, 0, 80),
			TextTransparency = 1,
			BackgroundTransparency = 1,
			Transparency = 1
		})
		t:Play()
		t.Completed:Connect(function() notif:Destroy() end)
	end)
end

return BSC_ClientCore
