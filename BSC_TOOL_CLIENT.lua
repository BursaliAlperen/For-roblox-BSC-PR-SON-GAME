--[[
================================================================
  BSC_TOOL_CLIENT.lua | StarterCharacterScripts
================================================================
  - Tüm remote'lar güvenli yükleniyor (nil crash yok)
  - Tool Blocked attribute kontrolü
  - CuffMode UI (Front/Back toggle)
  - Emote: PlayEmote remote'u ile server'a bildir
================================================================
--]]

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")

local LP    = Players.LocalPlayer
local PG    = LP:WaitForChild("PlayerGui")
local mouse = LP:GetMouse()
local Char  = script.Parent

-- ── REMOTE'LARI GÜVENLİ YÜKLE ────────────────────────────────────────
local Remotes = RS:WaitForChild("Remotes", 15)
if not Remotes then
    warn("[TOOL_CLIENT] FATAL: Remotes klasörü yok! AAA_BSC_SETUP çalışıyor mu?")
    return
end

local function getAnyRemote(names)
    for _, name in ipairs(names) do
        local r = Remotes:FindFirstChild(name)
        if r then return r end
    end
    return nil
end

local R_CuffTog = getAnyRemote({"CuffModeToggle"})
local R_Emote   = getAnyRemote({"PlayEmote"})
local R_Apply   = {
    Handcuff = getAnyRemote({"ApplyRestraint", "ArrestPlayer"}),
    Taser    = getAnyRemote({"ApplyRestraint", "TaserPlayer"}),
    Chain    = getAnyRemote({"ApplyRestraint", "ChainPlayer"}),
    Rope     = getAnyRemote({"ApplyRestraint", "HogtiePlayer"}),
}

if not R_Apply.Handcuff then
    warn("[TOOL_CLIENT] FATAL: ApplyRestraint/ArrestPlayer yok, script durdu.")
    return
end

-- ── COOLDOWN ve DURUM ─────────────────────────────────────────────────
local CD = {Handcuff=1.5, Taser=3.5, Chain=1.5, Rope=1.5, Keycard=1.2, Punch=0.8}
local lastUsed  = {}
local connected = {}
local equipped  = nil
local cuffMode  = "Front"

local TOOL_TO_TYPE = {
    Handcuff = "Handcuff",
    Taser    = "Taser",
    Chain    = "Chain",
    Rope     = "Rope",
}

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

-- ── UI YARDIMCILAR ─────────────────────────────────────────────────────
local function cr(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 6);c.Parent=o end
local function tw(o,p,t,s) TweenSvc:Create(o,TweenInfo.new(t or 0.25,s or Enum.EasingStyle.Back,Enum.EasingDirection.Out),p):Play() end

-- ── KELEPÇE MODU UI ───────────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name="CuffUI"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.Parent=PG

local POS_OPEN  = UDim2.new(0.5,-130,1,-165)
local POS_CLOSE = UDim2.new(0.5,-130,1,-40)

local frame = Instance.new("Frame")
frame.Size=UDim2.new(0,260,0,88)
frame.Position=POS_CLOSE
frame.BackgroundColor3=Color3.fromRGB(8,8,20)
frame.BorderSizePixel=0; frame.Visible=false; frame.Parent=SG
cr(frame,10)
do
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(45,95,230)
    s.Thickness=1.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=frame
end
do
    local g=Instance.new("UIGradient"); g.Rotation=90
    g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(14,14,32)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(5,5,14)),
    }); g.Parent=frame
end

-- Üst bar
local topBar=Instance.new("Frame")
topBar.Size=UDim2.new(1,0,0,24); topBar.BackgroundColor3=Color3.fromRGB(10,10,28)
topBar.BorderSizePixel=0; topBar.Parent=frame; cr(topBar,10)
do -- Alt köşeleri kapat
    local c2=Instance.new("Frame"); c2.Size=UDim2.new(1,0,0,10)
    c2.Position=UDim2.new(0,0,1,-10); c2.BackgroundColor3=Color3.fromRGB(10,10,28)
    c2.BorderSizePixel=0; c2.Parent=topBar
end

local function lbl(parent, text, size, col, xAlign, sz, pos)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
    l.Text=text; l.TextSize=size or 10; l.Font=Enum.Font.GothamBold
    l.TextColor3=col or Color3.new(1,1,1)
    l.TextXAlignment=xAlign or Enum.TextXAlignment.Left
    l.Size=sz or UDim2.new(1,0,1,0); l.Position=pos or UDim2.new(0,0,0,0)
    l.Parent=parent; return l
end

lbl(topBar,"🔒",11,nil,nil,UDim2.new(0,22,1,0),UDim2.new(0,2,0,0))
lbl(topBar,"HANDCUFF MODE",10,Color3.fromRGB(100,150,255),Enum.TextXAlignment.Left,
    UDim2.new(1,-60,1,0),UDim2.new(0,24,0,0))
lbl(topBar,"[F] toggle",8,Color3.fromRGB(50,50,90),Enum.TextXAlignment.Left,
    UDim2.new(0,55,1,0),UDim2.new(0,128,0,0))

local xBtn=Instance.new("TextButton")
xBtn.Size=UDim2.new(0,20,0,18); xBtn.Position=UDim2.new(1,-22,0,3)
xBtn.BackgroundColor3=Color3.fromRGB(140,25,25); xBtn.Text="✕"
xBtn.TextColor3=Color3.new(1,1,1); xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=11
xBtn.AutoButtonColor=false; xBtn.BorderSizePixel=0; xBtn.Parent=topBar; cr(xBtn,4)
xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=Color3.fromRGB(200,35,35)},0.1) end)
xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=Color3.fromRGB(140,25,25)},0.1) end)

local row=Instance.new("Frame"); row.Size=UDim2.new(1,-10,0,54)
row.Position=UDim2.new(0,5,0,27); row.BackgroundTransparency=1; row.Parent=frame

local function modeBtn(parent, icon, label, xPos)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0.5,-3,1,0)
    btn.Position=UDim2.new(xPos, xPos==0 and 0 or 3, 0, 0)
    btn.Text=""; btn.AutoButtonColor=false; btn.BorderSizePixel=0
    btn.BackgroundColor3=Color3.fromRGB(35,35,55); btn.Parent=parent; cr(btn,8)
    local ico=lbl(btn,icon,22,nil,Enum.TextXAlignment.Center,UDim2.new(1,0,0,30),UDim2.new(0,0,0,3))
    local sub=lbl(btn,label,9,Color3.fromRGB(160,160,200),Enum.TextXAlignment.Center,
        UDim2.new(1,0,0,14),UDim2.new(0,0,1,-16))
    return btn, ico, sub
end

local fBtn,fIco,fSub = modeBtn(row,"⛓","FRONT",0)
local bBtn,bIco,bSub = modeBtn(row,"🔗","BACK",0.5)

local C_BLUE=Color3.fromRGB(30,70,210)
local C_RED =Color3.fromRGB(165,45,25)
local C_DIM =Color3.fromRGB(35,35,55)
local C_ON  =Color3.new(1,1,1)
local C_OFF =Color3.fromRGB(80,80,110)

local function refreshUI()
    local front = cuffMode=="Front"
    tw(fBtn,{BackgroundColor3=front and C_BLUE or C_DIM},0.18)
    tw(bBtn,{BackgroundColor3=front and C_DIM  or C_RED},0.18)
    fIco.TextColor3=front and C_ON or C_OFF
    bIco.TextColor3=front and C_OFF or C_ON
    fSub.TextColor3=front and Color3.fromRGB(180,200,255) or C_OFF
    bSub.TextColor3=front and C_OFF or Color3.fromRGB(255,180,180)
end
refreshUI()

local function openUI()
    frame.Position=POS_CLOSE; frame.Visible=true
    tw(frame,{Position=POS_OPEN},0.3,Enum.EasingStyle.Back)
end
local function closeUI()
    tw(frame,{Position=POS_CLOSE},0.22,Enum.EasingStyle.Quad)
    task.delay(0.23,function() frame.Visible=false; frame.Position=POS_OPEN end)
end

xBtn.MouseButton1Click:Connect(closeUI)

local function reqToggle()
    if LP:GetAttribute("Team")~="POLICE" then return end
    if R_CuffTog then R_CuffTog:FireServer() end
end

fBtn.MouseButton1Click:Connect(function() if cuffMode~="Front" then reqToggle() end end)
bBtn.MouseButton1Click:Connect(function() if cuffMode~="Back"  then reqToggle() end end)
fBtn.MouseEnter:Connect(function() if cuffMode=="Back"  then tw(fBtn,{BackgroundColor3=Color3.fromRGB(50,50,80)},0.1) end end)
fBtn.MouseLeave:Connect(function() refreshUI() end)
bBtn.MouseEnter:Connect(function() if cuffMode=="Front" then tw(bBtn,{BackgroundColor3=Color3.fromRGB(50,50,80)},0.1) end end)
bBtn.MouseLeave:Connect(function() refreshUI() end)

UIS.InputBegan:Connect(function(inp,isGui)
    if isGui then return end
    if inp.KeyCode==Enum.KeyCode.F
        and LP:GetAttribute("Team")=="POLICE"
        and equipped and equipped.Name=="Handcuff" then
        reqToggle()
    end
end)

if R_CuffTog then
    R_CuffTog.OnClientEvent:Connect(function(newMode)
        cuffMode=newMode; refreshUI()
    end)
end

-- ── EMOTE FONKSİYONU (MAIN_UI tarafından çağrılır) ───────────────────
-- Global olarak tanımla, MAIN_UI kullanabilsin
_G.BSC_PlayEmote = function(emoteName)
    if not R_Emote then
        warn("[TOOL_CLIENT] PlayEmote remote yok!")
        return
    end
    -- Local animasyon zaten server broadcast ile gelecek
    -- Sadece server'a bildir
    R_Emote:FireServer(emoteName)
end

-- ── TOOL BAĞLANTISI ───────────────────────────────────────────────────
local function connectTool(tool)
    if not tool:IsA("Tool") then return end
    if connected[tool] then return end
    connected[tool] = true

    tool.Equipped:Connect(function()
        equipped = tool
        local gripCF = TOOL_GRIPS[tool.Name]
        if gripCF then
            pcall(function()
                tool.Grip = gripCF
            end)
        end
        if tool.Name=="Handcuff" and LP:GetAttribute("Team")=="POLICE" then
            openUI()
        end
    end)

    tool.Unequipped:Connect(function()
        if equipped==tool then equipped=nil end
        if tool.Name=="Handcuff" then closeUI() end
    end)

    tool.Activated:Connect(function()
        -- Blocked kontrolü
        if tool:GetAttribute("Blocked") then return end

        -- Cooldown
        local now = tick()
        local cd  = CD[tool.Name] or 1.5
        if now-(lastUsed[tool.Name] or 0) < cd then
            if frame.Visible then
                tw(frame,{BackgroundColor3=Color3.fromRGB(30,5,5)},0.05)
                task.delay(0.3,function() tw(frame,{BackgroundColor3=Color3.fromRGB(8,8,20)},0.3) end)
            end
            return
        end
        lastUsed[tool.Name] = now

        local tgt = mouse.Target

        -- Keycard
        if tool.Name=="Keycard" then
            local r = Remotes:FindFirstChild("Keycard") or Remotes:FindFirstChild("KeycardAccess")
            if r and tgt then r:FireServer(tgt) end
            return
        end

        -- Punch
        if tool.Name=="Punch" then
            local tChar = findTargetCharacterFromPart(tgt) or nearestTargetCharacter(8)
            if not tChar then return end
            local vp = Players:GetPlayerFromCharacter(tChar)
            if not vp or vp==LP then return end
            local r = Remotes:FindFirstChild("Punch") or Remotes:FindFirstChild("PunchPlayer")
            if r then r:FireServer(vp) end
            return
        end

        -- RemoveRestraint (serbest bırak tuşu ise — örn. Keycard ile)
        -- (opsiyonel, ihtiyaca göre aktif et)

        -- Restraint tool'lar
        local rType = TOOL_TO_TYPE[tool.Name]
        if rType then
            local tChar = findTargetCharacterFromPart(tgt) or nearestTargetCharacter(8)
            if not tChar or tChar==Char then return end
            if not tChar:FindFirstChildOfClass("Humanoid") then return end
            local remote = R_Apply[tool.Name]
            if not remote then return end

            if remote.Name == "ApplyRestraint" then
                remote:FireServer(tChar, rType)
            else
                remote:FireServer(tChar)
            end
        end
    end)
end

-- ── KURULUM ────────────────────────────────────────────────────────────
local function setup()
    local bp = LP:WaitForChild("Backpack", 6)
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            task.spawn(connectTool, t)
        end
        bp.ChildAdded:Connect(function(t) task.spawn(connectTool, t) end)
    end

    for _, t in ipairs(Char:GetChildren()) do
        if t:IsA("Tool") then task.spawn(connectTool, t) end
    end
    Char.ChildAdded:Connect(function(t)
        if t:IsA("Tool") then task.spawn(connectTool, t) end
    end)
end

-- Backpack gelene kadar bekle sonra kur
task.spawn(function()
    local n = 0
    repeat task.wait(0.2); n = n+1 until LP:FindFirstChild("Backpack") or n > 30
    setup()
end)

-- Yeniden spawn olunca
LP.CharacterAdded:Connect(function(c)
    Char = c
    connected = {}
    equipped  = nil
    task.wait(0.5)
    setup()
end)

print("[TOOL_CLIENT] ✅ Hazır")
