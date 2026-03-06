-- ============================================================
-- BSC PRISON | BSC_MotionEngine.lua
-- StarterPlayerScripts > BSC_MotionEngine (ModuleScript)
-- CFrame Tabanlı AAA Animasyon Motoru
-- ============================================================

local BSC_MotionEngine = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- ─────────────────────────────────────────────
-- ANIMASYON AYARLARI
-- ─────────────────────────────────────────────
local activeToolAnim = nil
local activeEmote = nil
local originalC0s = {}

-- ─────────────────────────────────────────────
-- CFRAME INTERPOLATION (LERP) MOTORU
-- ─────────────────────────────────────────────
function BSC_MotionEngine.Initialize()
	Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	
	-- Orijinal C0 değerlerini sakla (Reset için)
	for _, v in ipairs(Character:GetDescendants()) do
		if v:IsA("Motor6D") then
			originalC0s[v.Name] = v.C0
		end
	end
end

-- ─────────────────────────────────────────────
-- TOOL ANİMASYONLARI (CFRAME)
-- ─────────────────────────────────────────────
function BSC_MotionEngine.StartToolMotion(tool)
	if activeToolAnim then activeToolAnim:Disconnect() end
	
	local rightArm = Character:FindFirstChild("Right Upper Arm") or Character:FindFirstChild("Right Arm")
	local shoulder = rightArm and (rightArm:FindFirstChild("RightShoulder") or rightArm:FindFirstChild("Right Shoulder"))
	
	if not shoulder then return end
	local baseC0 = originalC0s[shoulder.Name] or shoulder.C0
	
	activeToolAnim = RunService.RenderStepped:Connect(function()
		if not tool.Parent or tool.Parent.ClassName ~= "Model" then
			shoulder.C0 = shoulder.C0:Lerp(baseC0, 0.1)
			activeToolAnim:Disconnect()
			return
		end
		
		local t = tick()
		local speed = Humanoid.MoveDirection.Magnitude
		local targetC0 = baseC0
		
		-- Dinamik Sallanma (Idle & Walk)
		if speed < 0.1 then
			-- Idle: Nefes alma ve hafif titreme
			targetC0 = baseC0 * CFrame.new(0, math.sin(t * 2) * 0.05, 0) * CFrame.Angles(math.rad(10 + math.sin(t * 1.5) * 2), 0, 0)
		else
			-- Walk/Run: Adım ritmiyle sallanma
			local cycle = math.sin(t * 12)
			targetC0 = baseC0 * CFrame.new(0.1 * cycle, 0.1 * math.abs(cycle), 0) * CFrame.Angles(math.rad(25 + cycle * 5), math.rad(cycle * 2), 0)
		end
		
		shoulder.C0 = shoulder.C0:Lerp(targetC0, 0.2)
	end)
end

-- ─────────────────────────────────────────────
-- GELİŞMİŞ EMOTE SİSTEMİ (PROXIMITY UYUMLU)
-- ─────────────────────────────────────────────
local EMOTES = {
	["Sleep"]    = {C0 = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(-90), 0, 0), Speed = 0},
	["Kneel"]    = {C0 = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-30), 0, 0), Speed = 0},
	["HandsUp"]  = {C0 = CFrame.new(0, 0, 0), ArmC0 = CFrame.Angles(math.rad(150), 0, 0), Speed = 16},
	["Sit"]      = {C0 = CFrame.new(0, -1.8, 0), Speed = 0},
	["Cower"]    = {C0 = CFrame.new(0, -2.2, 0) * CFrame.Angles(math.rad(20), 0, 0), Speed = 0},
}

function BSC_MotionEngine.PlayEmote(name)
	local emote = EMOTES[name]
	if not emote then return end
	
	local rootJoint = Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") or Character.HumanoidRootPart:FindFirstChild("RootJoint")
	if not rootJoint then return end
	
	local baseC0 = originalC0s[rootJoint.Name] or rootJoint.C0
	
	activeEmote = name
	Humanoid.WalkSpeed = emote.Speed
	
	TweenService:Create(rootJoint, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {
		C0 = baseC0 * emote.C0
	}):Play()
	
	-- Hareket edince emote bozulsun
	local conn
	conn = Humanoid.Running:Connect(function(speed)
		if speed > 0.5 and activeEmote == name then
			BSC_MotionEngine.StopEmote()
			conn:Disconnect()
		end
	end)
end

function BSC_MotionEngine.StopEmote()
	if not activeEmote then return end
	
	local rootJoint = Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") or Character.HumanoidRootPart:FindFirstChild("RootJoint")
	if rootJoint then
		local baseC0 = originalC0s[rootJoint.Name] or CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
		TweenService:Create(rootJoint, TweenInfo.new(0.4), {C0 = baseC0}):Play()
	end
	
	activeEmote = nil
	Humanoid.WalkSpeed = 16
end

return BSC_MotionEngine
