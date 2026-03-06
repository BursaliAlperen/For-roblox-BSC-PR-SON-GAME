-- ============================================================
-- BSC PRISON | BSC_JobSystem.lua
-- StarterPlayerScripts > BSC_JobSystem (ModuleScript)
-- Mahkum ve Polis Görev Sistemleri (Dinamik Etkileşim)
-- ============================================================

local BSC_JobSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- GÖREV VERİLERİ
-- ─────────────────────────────────────────────
local JOBS = {
	PRISONER = {
		{id = "kitchen", name = "Mutfak Yardımı", reward = 35, time = 12, pos = Vector3.new(50, 5, -850)},
		{id = "laundry", name = "Çamaşırhane", reward = 25, time = 8, pos = Vector3.new(-50, 5, -850)},
		{id = "workshop", name = "Atölye (Plaka)", reward = 50, time = 15, pos = Vector3.new(0, 5, -1100)},
	},
	COP = {
		{id = "patrol", name = "Hücre Devriyesi", reward = 60, time = 20, pos = Vector3.new(100, 5, -900)},
		{id = "cctv_check", name = "Kamera Kontrolü", reward = 40, time = 10, pos = Vector3.new(0, 50, -800)},
	}
}

-- ─────────────────────────────────────────────
-- GÖREV ETKİLEŞİM NOKTALARI OLUŞTURMA
-- ─────────────────────────────────────────────
function BSC_JobSystem.SetupJobPoints()
	local JobFolder = workspace:FindFirstChild("BSC_JobPoints") or Instance.new("Folder", workspace)
	JobFolder.Name = "BSC_JobPoints"
	
	for team, tasks in pairs(JOBS) do
		for _, taskData in ipairs(tasks) do
			local part = Instance.new("Part", JobFolder)
			part.Name = "Job_" .. taskData.id
			part.Size = Vector3.new(6, 0.2, 6)
			part.Position = taskData.pos
			part.Anchored = true
			part.CanCollide = false
			part.Color = (team == "COP") and Color3.fromRGB(50, 100, 255) or Color3.fromRGB(255, 150, 50)
			part.Material = Enum.Material.Neon
			part.Transparency = 0.5
			
			local prompt = Instance.new("ProximityPrompt", part)
			prompt.ActionText = taskData.name .. " Başlat"
			prompt.ObjectText = "İş / Görev"
			prompt.HoldDuration = 1.5
			prompt.MaxActivationDistance = 8
			
			prompt.Triggered:Connect(function()
				BSC_JobSystem.StartJob(taskData)
			end)
		end
	end
end

-- ─────────────────────────────────────────────
-- GÖREV BAŞLATMA VE İLERLEME (AAA UI)
-- ─────────────────────────────────────────────
function BSC_JobSystem.StartJob(taskData)
	local ScreenGui = Instance.new("ScreenGui", PlayerGui)
	ScreenGui.Name = "BSC_JobProgress"
	
	local BarBG = Instance.new("Frame", ScreenGui)
	BarBG.Size = UDim2.new(0, 400, 0, 10)
	BarBG.Position = UDim2.new(0.5, -200, 0.85, 0)
	BarBG.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	
	local Bar = Instance.new("Frame", BarBG)
	Bar.Size = UDim2.new(0, 0, 1, 0)
	Bar.BackgroundColor3 = Color3.fromRGB(90, 120, 255)
	
	local Lbl = Instance.new("TextLabel", ScreenGui)
	Lbl.Text = string.upper(taskData.name) .. " YAPILIYOR..."
	Lbl.Size = UDim2.new(0, 400, 0, 30)
	Lbl.Position = UDim2.new(0.5, -200, 0.85, -40)
	Lbl.BackgroundTransparency = 1
	Lbl.TextColor3 = Color3.new(1,1,1)
	Lbl.Font = Enum.Font.GothamBlack
	Lbl.TextSize = 14
	
	-- İlerleme Animasyonu
	local t = TweenService:Create(Bar, TweenInfo.new(taskData.time, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
	t:Play()
	
	t.Completed:Connect(function()
		ScreenGui:Destroy()
		local Remotes = ReplicatedStorage:WaitForChild("BSCRemotes")
		Remotes.CompleteTask:FireServer(taskData.name, taskData.reward)
	end)
end

return BSC_JobSystem
