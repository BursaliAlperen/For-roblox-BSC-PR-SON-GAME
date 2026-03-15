-- ============================================================
-- BSC_TOOL_CLIENT.lua | StarterCharacterScripts
--
-- Fires ApplyRestraint remote to server.
-- Checks "Blocked" attribute → blocked tools can't be activated.
-- FRONT/BACK cuff mode UI with slide animation and X button.
-- ============================================================

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")

local LP    = Players.LocalPlayer
local PG    = LP:WaitForChild("PlayerGui")
local mouse = LP:GetMouse()
local Char  = script.Parent

-- Safe remote loader: retries until found (fixes timing race on spawn)
local function waitRemote(name, timeout)
	local Remotes = RS:WaitForChild("Remotes", timeout or 15)
	if not Remotes then
		warn("[TOOL_CLIENT] Remotes folder not found! Is BSC_SETUP running?")
		return nil
	end
	local r = Remotes:WaitForChild(name, timeout or 15)
	if not r then
		warn("[TOOL_CLIENT] Remote not found:", name)
	end
	return r
end

local Remotes   = RS:WaitForChild("Remotes", 15)
local R_Apply   = waitRemote("ApplyRestraint")
local R_Remove  = waitRemote("RemoveRestraint")
local R_CuffTog = waitRemote("CuffModeToggle")

-- CRITICAL: If remotes failed to load, abort entirely
if not R_Apply or not R_Remove or not R_CuffTog then
	warn("[TOOL_CLIENT] FATAL: Required remotes missing. Make sure 1_BSC_SETUP runs first!")
	return
end

-- Cooldowns per tool name
local CD = {Handcuff=1.5, Taser=3.5, Chain=1.5, Rope=1.5, Keycard=1.2, Punch=0.8}
local lastUsed   = {}
local connected  = {}
local equipped   = nil
local cuffMode   = "Front"

local TOOL_GRIPS = {
	Handcuff = CFrame.new(0, -0.55, -0.15) * CFrame.Angles(math.rad(-90), 0, 0),
	Chain    = CFrame.new(0, -0.50, -0.25) * CFrame.Angles(math.rad(-90), 0, 0),
	Rope     = CFrame.new(0, -0.45, -0.20) * CFrame.Angles(math.rad(-90), 0, 0),
	Taser    = CFrame.new(0, -0.20, -0.35) * CFrame.Angles(0, math.rad(90), 0),
}

local function findTargetCharacterFromPart(part)
	if not part then return nil end
	local cur = part
	for _ = 1, 8 do
		if not cur then break end
		if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then
			return cur
		end
		cur = cur.Parent
	end
	return part:FindFirstAncestorOfClass("Model")
end

local function nearestTargetCharacter(maxDistance)
	local myHRP = Char and Char:FindFirstChild("HumanoidRootPart")
	if not myHRP then return nil end

	local bestChar, bestDist = nil, maxDistance or 9
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local tChar = plr.Character
			local hum = tChar:FindFirstChildOfClass("Humanoid")
			local hrp = tChar:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local dist = (hrp.Position - myHRP.Position).Magnitude
				if dist <= bestDist then
					bestDist = dist
					bestChar = tChar
				end
			end
		end
	end
	return bestChar
end

-- Tool → restraint type mapping
local TOOL_RESTRAINT = {
	Handcuff = "Handcuff",
	Chain    = "Chain",
	Rope     = "Rope",
	Taser    = "Taser",
}

------------------------------------------------------------------------
-- UI HELPERS
------------------------------------------------------------------------
local function cr(obj, r)
	local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=obj
end
local function sk(obj, col, th)
	local s = Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1
	s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=obj
end
local function tw(obj, props, t, sty)
	TweenSvc:Create(obj, TweenInfo.new(t or 0.25, sty or Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), props):Play()
end

------------------------------------------------------------------------
-- CUFF MODE UI
------------------------------------------------------------------------
local SG = Instance.new("ScreenGui")
SG.Name="CuffUI"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.Parent=PG

local POS_OPEN  = UDim2.new(0.5,-130,1,-165)
local POS_CLOSE = UDim2.new(0.5,-130,1,-40)

local frame = Instance.new("Frame")
frame.Name="CuffFrame"; frame.Size=UDim2.new(0,260,0,88)
frame.Position=POS_CLOSE; frame.BackgroundColor3=Color3.fromRGB(8,8,20)
frame.BorderSizePixel=0; frame.Visible=false; frame.Parent=SG
cr(frame,10); sk(frame, Color3.fromRGB(45,95,230), 1.5)

do -- gradient
	local g=Instance.new("UIGradient"); g.Rotation=90
	g.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(14,14,32)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(5,5,14)),
	}); g.Parent=frame
end

-- Top bar
local topBar=Instance.new("Frame")
topBar.Size=UDim2.new(1,0,0,24); topBar.BackgroundColor3=Color3.fromRGB(10,10,28)
topBar.BorderSizePixel=0; topBar.Parent=frame; cr(topBar,10)
local cover=Instance.new("Frame"); cover.Size=UDim2.new(1,0,0,10)
cover.Position=UDim2.new(0,0,1,-10); cover.BackgroundColor3=Color3.fromRGB(10,10,28)
cover.BorderSizePixel=0; cover.Parent=topBar

local function mkLbl(parent,text,size,col,xalign,sz,pos)
	local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
	l.Text=text; l.TextSize=size or 10; l.Font=Enum.Font.GothamBold
	l.TextColor3=col or Color3.new(1,1,1)
	l.TextXAlignment=xalign or Enum.TextXAlignment.Left
	l.Size=sz or UDim2.new(1,0,1,0)
	l.Position=pos or UDim2.new(0,0,0,0)
	l.Parent=parent; return l
end

mkLbl(topBar,"🔒",11,nil,nil,UDim2.new(0,22,1,0),UDim2.new(0,2,0,0))
mkLbl(topBar,"HANDCUFF MODE",10,Color3.fromRGB(100,150,255),Enum.TextXAlignment.Left,
	UDim2.new(1,-60,1,0),UDim2.new(0,24,0,0))
mkLbl(topBar,"[F] toggle",8,Color3.fromRGB(50,50,90),Enum.TextXAlignment.Left,
	UDim2.new(0,55,1,0),UDim2.new(0,128,0,0))

-- X button
local xBtn=Instance.new("TextButton")
xBtn.Size=UDim2.new(0,20,0,18); xBtn.Position=UDim2.new(1,-22,0,3)
xBtn.BackgroundColor3=Color3.fromRGB(140,25,25); xBtn.Text="✕"
xBtn.TextColor3=Color3.new(1,1,1); xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=11
xBtn.AutoButtonColor=false; xBtn.BorderSizePixel=0; xBtn.Parent=topBar; cr(xBtn,4)
xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=Color3.fromRGB(200,35,35)},0.1) end)
xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=Color3.fromRGB(140,25,25)},0.1) end)

-- Button row
local row=Instance.new("Frame"); row.Size=UDim2.new(1,-10,0,54)
row.Position=UDim2.new(0,5,0,27); row.BackgroundTransparency=1; row.Parent=frame

-- Mode button factory
local function mkModeBtn(parent, icon, label, xPos)
	local btn=Instance.new("TextButton")
	btn.Size=UDim2.new(0.5,-3,1,0); btn.Position=UDim2.new(xPos,xPos==0 and 0 or 3,0,0)
	btn.Text=""; btn.AutoButtonColor=false; btn.BorderSizePixel=0
	btn.BackgroundColor3=Color3.fromRGB(35,35,55); btn.Parent=parent; cr(btn,8)

	local ico=Instance.new("TextLabel"); ico.BackgroundTransparency=1
	ico.Text=icon; ico.TextSize=22; ico.Font=Enum.Font.Gotham
	ico.Size=UDim2.new(1,0,0,30); ico.Position=UDim2.new(0,0,0,3)
	ico.TextXAlignment=Enum.TextXAlignment.Center; ico.Parent=btn

	local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1
	sub.Text=label; sub.TextSize=9; sub.Font=Enum.Font.Gotham
	sub.TextColor3=Color3.fromRGB(160,160,200)
	sub.Size=UDim2.new(1,0,0,14); sub.Position=UDim2.new(0,0,1,-16)
	sub.TextXAlignment=Enum.TextXAlignment.Center; sub.Parent=btn

	return btn, ico, sub
end

local fBtn, fIco, fSub = mkModeBtn(row, "⛓", "FRONT", 0)
local bBtn, bIco, bSub = mkModeBtn(row, "🔗", "BACK",  0.5)

local CLR_BLUE = Color3.fromRGB(30,70,210)
local CLR_RED  = Color3.fromRGB(165,45,25)
local CLR_DIM  = Color3.fromRGB(35,35,55)
local CLR_ICON_ON  = Color3.new(1,1,1)
local CLR_ICON_OFF = Color3.fromRGB(80,80,110)

local function refreshUI()
	local isFront = cuffMode=="Front"
	tw(fBtn,{BackgroundColor3=isFront and CLR_BLUE or CLR_DIM},0.18)
	tw(bBtn,{BackgroundColor3=isFront and CLR_DIM  or CLR_RED}, 0.18)
	fIco.TextColor3 = isFront and CLR_ICON_ON or CLR_ICON_OFF
	bIco.TextColor3 = isFront and CLR_ICON_OFF or CLR_ICON_ON
	fSub.TextColor3 = isFront and Color3.fromRGB(180,200,255) or CLR_ICON_OFF
	bSub.TextColor3 = isFront and CLR_ICON_OFF or Color3.fromRGB(255,180,180)
end
refreshUI()

local function openUI()
	frame.Position=POS_CLOSE; frame.Visible=true
	tw(frame,{Position=POS_OPEN},0.3,Enum.EasingStyle.Back)
end
local function closeUI()
	tw(frame,{Position=POS_CLOSE},0.22,Enum.EasingStyle.Quad)
	task.delay(0.23, function() frame.Visible=false; frame.Position=POS_OPEN end)
end

xBtn.MouseButton1Click:Connect(closeUI)

local function reqToggle()
	if LP:GetAttribute("Team")~="POLICE" then return end
	R_CuffTog:FireServer()
end
fBtn.MouseButton1Click:Connect(function() if cuffMode~="Front" then reqToggle() end end)
bBtn.MouseButton1Click:Connect(function() if cuffMode~="Back"  then reqToggle() end end)
fBtn.MouseEnter:Connect(function() if cuffMode=="Back"  then tw(fBtn,{BackgroundColor3=Color3.fromRGB(50,50,80)},0.1) end end)
fBtn.MouseLeave:Connect(function() refreshUI() end)
bBtn.MouseEnter:Connect(function() if cuffMode=="Front" then tw(bBtn,{BackgroundColor3=Color3.fromRGB(50,50,80)},0.1) end end)
bBtn.MouseLeave:Connect(function() refreshUI() end)

UIS.InputBegan:Connect(function(inp,gui)
	if gui then return end
	if inp.KeyCode==Enum.KeyCode.F
		and LP:GetAttribute("Team")=="POLICE"
		and equipped and equipped.Name=="Handcuff" then
		reqToggle()
	end
end)

R_CuffTog.OnClientEvent:Connect(function(newMode)
	cuffMode=newMode; refreshUI()
end)

------------------------------------------------------------------------
-- TOOL CONNECTION
------------------------------------------------------------------------
local function connectTool(tool)
	if not tool:IsA("Tool") or connected[tool] then return end
	connected[tool]=true

	tool.Equipped:Connect(function()
		equipped=tool
		local gripCF = TOOL_GRIPS[tool.Name]
		if gripCF then
			pcall(function()
				tool.Grip = gripCF
			end)
		end
		if tool.Name=="Handcuff" and LP:GetAttribute("Team")=="POLICE" then openUI() end
	end)
	tool.Unequipped:Connect(function()
		if equipped==tool then equipped=nil end
		if tool.Name=="Handcuff" then closeUI() end
	end)

	tool.Activated:Connect(function()
		-- Check if this tool is blocked (player is restrained)
		if tool:GetAttribute("Blocked") then return end

		-- Cooldown
		local now=tick()
		local cd=CD[tool.Name] or 1.5
		if now-(lastUsed[tool.Name] or 0) < cd then
			-- Flash red to indicate cooldown
			tw(frame,{BackgroundColor3=Color3.fromRGB(30,5,5)},0.05)
			task.delay(0.3, function() tw(frame,{BackgroundColor3=Color3.fromRGB(8,8,20)},0.3) end)
			return
		end
		lastUsed[tool.Name]=now

		local tgt=mouse.Target

		-- Keycard: send raw part
		if tool.Name=="Keycard" then
			if Remotes then
				local remote=Remotes:FindFirstChild("Keycard")
				if remote and tgt then remote:FireServer(tgt) end
			end
			return
		end

		-- Punch
		if tool.Name=="Punch" then
			local tChar=findTargetCharacterFromPart(tgt) or nearestTargetCharacter(8); if not tChar then return end
			local vp=Players:GetPlayerFromCharacter(tChar); if not vp then return end
			if vp==LP then return end
			if Remotes then
				local remote=Remotes:FindFirstChild("Punch")
				if remote then remote:FireServer(vp) end
			end
			return
		end

		-- Restraint tools (Handcuff, Chain, Rope, Taser)
		local restraintType=TOOL_RESTRAINT[tool.Name]
		if restraintType then
			local tChar=findTargetCharacterFromPart(tgt) or nearestTargetCharacter(8); if not tChar then return end
			if tChar==Char then return end
			if not tChar:FindFirstChildOfClass("Humanoid") then return end
			if not R_Apply then
				warn("[TOOL_CLIENT] R_Apply is nil! Remote missing.")
				return
			end
			R_Apply:FireServer(tChar, restraintType)
		end
	end)
end

------------------------------------------------------------------------
-- SETUP: scan backpack and character
------------------------------------------------------------------------
local function setup()
	local bp=LP:WaitForChild("Backpack",6)
	if bp then
		for _,t in ipairs(bp:GetChildren()) do task.spawn(connectTool,t) end
		bp.ChildAdded:Connect(function(t) task.spawn(connectTool,t) end)
	end
	for _,t in ipairs(Char:GetChildren()) do
		if t:IsA("Tool") then task.spawn(connectTool,t) end
	end
	Char.ChildAdded:Connect(function(t)
		if t:IsA("Tool") then task.spawn(connectTool,t) end
	end)
end

task.spawn(function()
	local tries=0
	repeat task.wait(0.2); tries=tries+1 until LP:FindFirstChild("Backpack") or tries>25
	setup()
end)

LP.CharacterAdded:Connect(function(c)
	Char=c; connected={}; task.wait(0.5); setup()
end)

print("[TOOL_CLIENT] Ready")
