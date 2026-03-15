--[[
	MAIN_UI.lua  |  StarterPlayer > StarterPlayerScripts
	
	KÖKTEN YENİDEN YAZILDI — Basit helper fonksiyonlar,
	kanıtlanmış UDim2 çağrıları, remote crash koruması.
	
	Remote'lar task.spawn ile arka planda yüklenir →
	script hiç crash yapmaz → UI her zaman görünür.
--]]

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local Run      = game:GetService("RunService")
local RepStore = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PGui   = player:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- REMOTE REFERANSLARI (nil başlar, task.spawn doldurur)
-- Bu sayede WaitForChild hiçbir zaman script'i crashlamaz
------------------------------------------------------------------------
local R = {
	TeamSelect     = nil,
	EscapeAttempt  = nil,
	ActivityUpdate = nil,
	DayNightSync   = nil,
	PlayEmote      = nil,
	ForgePrompt    = nil,
}

------------------------------------------------------------------------
-- RENKLER
------------------------------------------------------------------------
local C = {
	BG     = Color3.fromRGB(8,8,10),
	SURF   = Color3.fromRGB(16,16,20),
	PANEL  = Color3.fromRGB(20,20,26),
	BORDER = Color3.fromRGB(35,35,46),
	TEXT   = Color3.fromRGB(210,210,210),
	DIM    = Color3.fromRGB(90,90,105),
	ACC    = Color3.fromRGB(51,102,255),
	HP_HI  = Color3.fromRGB(48,190,75),
	HP_MID = Color3.fromRGB(235,145,35),
	HP_LOW = Color3.fromRGB(205,45,45),
	STA    = Color3.fromRGB(45,95,240),
	WHITE  = Color3.new(1,1,1),
	RED    = Color3.fromRGB(215,50,50),
	GREEN  = Color3.fromRGB(48,190,75),
	YELLOW = Color3.fromRGB(235,195,45),
	BLACK  = Color3.new(0,0,0),
	STEEL  = Color3.fromRGB(55,58,65),
	RUST   = Color3.fromRGB(110,55,25),
	NOR    = Color3.fromRGB(50,185,70),
	BND    = Color3.fromRGB(210,45,45),
}

------------------------------------------------------------------------
-- BASİT HELPER FONKSİYONLAR
-- Hepsi UDim2 objesi alır — nil hatası yok
------------------------------------------------------------------------
local function F(parent, bg, size, pos)
	local f        = Instance.new("Frame")
	f.BackgroundColor3 = bg or C.PANEL
	f.BorderSizePixel  = 0
	f.Size             = size or UDim2.new(1,0,1,0)
	f.Position         = pos  or UDim2.new(0,0,0,0)
	f.Parent           = parent
	return f
end

local function L(parent, text, textSize, color, size, pos, alignX)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font                   = Enum.Font.GothamBold
	l.Text                   = text or ""
	l.TextSize               = textSize or 12
	l.TextColor3             = color or C.TEXT
	l.Size                   = size or UDim2.new(1,0,0,18)
	l.Position               = pos  or UDim2.new(0,0,0,0)
	l.TextXAlignment         = alignX or Enum.TextXAlignment.Left
	l.TextWrapped            = true
	l.Parent                 = parent
	return l
end

local function B(parent, text, bg, textColor, textSize, size, pos)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = bg or C.ACC
	b.BorderSizePixel  = 0
	b.Font             = Enum.Font.GothamBold
	b.Text             = text or ""
	b.TextColor3       = textColor or C.WHITE
	b.TextSize         = textSize or 12
	b.Size             = size or UDim2.new(1,0,0,30)
	b.Position         = pos  or UDim2.new(0,0,0,0)
	b.AutoButtonColor  = false
	b.Parent           = parent
	return b
end

local function CR(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = obj
end

local function SK(obj, col, th)
	local s = Instance.new("UIStroke")
	s.Color             = col or C.BORDER
	s.Thickness         = th or 1
	s.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
	s.Parent            = obj
end

local function TW(obj, props, dur, style)
	TweenSvc:Create(obj, TweenInfo.new(
		dur or 0.22,
		style or Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	), props):Play()
end

------------------------------------------------------------------------
-- SCREEN GUI
-- ResetOnSpawn=false → ölünce kaybolmaz
-- IgnoreGuiInset=true → üst boşluk yok
------------------------------------------------------------------------
local SG = Instance.new("ScreenGui")
SG.Name           = "BSC_UI"
SG.ResetOnSpawn   = false
SG.IgnoreGuiInset = true
SG.DisplayOrder   = 100
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = PGui

-- ════════════════════════════════════════════════════════════════════
-- ANA MENÜ
-- ════════════════════════════════════════════════════════════════════
local menuRoot = F(SG, C.BG, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
menuRoot.Name    = "MainMenu"
menuRoot.Visible = true   -- BAŞLANGIÇTA GÖRÜNÜR

-- Logo alanı (üst %28)
local logoArea = F(menuRoot, C.BLACK, UDim2.new(1,0,0.28,0), UDim2.new(0,0,0,0))

-- Rust alt çizgi
F(logoArea, C.RUST, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1))

-- BSC PRISON yazısı
L(logoArea, "BSC PRISON", 44, C.WHITE,
	UDim2.new(1,0,0,54), UDim2.new(0,0,0.14,0), Enum.TextXAlignment.Center)

-- Alt yazı
L(logoArea, "MAXIMUM SECURITY FACILITY", 9, C.STEEL,
	UDim2.new(1,0,0,14), UDim2.new(0,0,0.72,0), Enum.TextXAlignment.Center)

-- Accent mavi çizgi (DOĞRU: sadece 4 argüman)
F(logoArea, C.ACC, UDim2.new(0.14,0,0,2), UDim2.new(0.43,0,0.95,0))

-- Buton sütunu (sol taraf)
local btnArea = F(menuRoot, C.BG, UDim2.new(0,160,0,136), UDim2.new(0,44,0.32,0))
btnArea.BackgroundTransparency = 1

local playBtn = B(btnArea, "PLAY", C.ACC, C.WHITE, 14,
	UDim2.new(1,0,0,40), UDim2.new(0,0,0,0))
CR(playBtn, 4)
playBtn.ZIndex = 5   -- Üstte olsun

local settBtn = B(btnArea, "SETTINGS", C.PANEL, C.TEXT, 11,
	UDim2.new(1,0,0,30), UDim2.new(0,0,0,48))
CR(settBtn, 4); SK(settBtn, C.BORDER, 1); settBtn.ZIndex = 5

local credBtn = B(btnArea, "CREDITS", C.PANEL, C.TEXT, 11,
	UDim2.new(1,0,0,30), UDim2.new(0,0,0,86))
CR(credBtn, 4); SK(credBtn, C.BORDER, 1); credBtn.ZIndex = 5

-- ────────────────────────────────────────────────────────────────────
-- SETTINGS PANELİ (kapalıyken Active=false → tıklamayı bloklamaz)
-- ────────────────────────────────────────────────────────────────────
local settPanel = F(SG, C.PANEL, UDim2.new(0,300,0,270), UDim2.new(0.5,-150,0.5,-135))
settPanel.Visible = false
settPanel.Active  = false
settPanel.ZIndex  = 20
CR(settPanel, 5); SK(settPanel, C.ACC, 1)

L(settPanel, "SETTINGS", 13, C.ACC,
	UDim2.new(1,-16,0,20), UDim2.new(0,10,0,8))

local sClose = B(settPanel, "X", C.SURF, C.TEXT, 10,
	UDim2.new(0,22,0,22), UDim2.new(1,-28,0,7))
CR(sClose, 3)
sClose.MouseButton1Click:Connect(function()
	settPanel.Visible = false
	settPanel.Active  = false
end)
settBtn.MouseButton1Click:Connect(function()
	settPanel.Visible = true
	settPanel.Active  = true
end)

L(settPanel, "VOLUME", 9, C.DIM,
	UDim2.new(1,-20,0,12), UDim2.new(0,10,0,38))
local vBg   = F(settPanel, C.SURF, UDim2.new(1,-58,0,6), UDim2.new(0,10,0,52)); CR(vBg, 3)
local vFill = F(vBg, C.ACC, UDim2.new(0.7,0,1,0), UDim2.new(0,0,0,0)); CR(vFill, 3)
local vNum  = L(settPanel, "70", 9, C.TEXT,
	UDim2.new(0,28,0,14), UDim2.new(1,-42,0,47), Enum.TextXAlignment.Center)
local vDrag = false
vBg.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then vDrag = true end
end)
UIS.InputChanged:Connect(function(i)
	if not vDrag then return end
	if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	local pct = math.clamp((i.Position.X - vBg.AbsolutePosition.X) / math.max(vBg.AbsoluteSize.X,1), 0, 1)
	vFill.Size = UDim2.new(pct, 0, 1, 0)
	vNum.Text  = tostring(math.floor(pct * 100))
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then vDrag = false end
end)

L(settPanel, "GRAPHICS", 9, C.DIM,
	UDim2.new(1,-20,0,12), UDim2.new(0,10,0,68))
local GFX = {"Auto","Low","Medium","High"}; local gi = 1
local gBtn = B(settPanel, "Auto", C.SURF, C.TEXT, 10,
	UDim2.new(0,100,0,24), UDim2.new(0,10,0,82))
CR(gBtn, 3); SK(gBtn, C.BORDER, 1)
gBtn.MouseButton1Click:Connect(function() gi = gi % #GFX + 1; gBtn.Text = GFX[gi] end)

L(settPanel, "UPDATE LOG", 9, C.DIM,
	UDim2.new(1,-20,0,12), UDim2.new(0,10,0,118))
local logSF = Instance.new("ScrollingFrame")
logSF.Size = UDim2.new(1,-20,0,100); logSF.Position = UDim2.new(0,10,0,132)
logSF.BackgroundColor3 = C.SURF; logSF.BorderSizePixel = 0
logSF.ScrollBarThickness = 3; logSF.ScrollBarImageColor3 = C.ACC
logSF.Parent = settPanel
local logTxt = L(logSF, "v1.0.0 — Tüm sistemler aktif", 9, C.TEXT,
	UDim2.new(1,-6,0,80), UDim2.new(0,3,0,3))
logTxt.TextYAlignment = Enum.TextYAlignment.Top
logSF.CanvasSize = UDim2.new(0,0,0,90)

-- ────────────────────────────────────────────────────────────────────
-- CREDITS PANELİ
-- ────────────────────────────────────────────────────────────────────
local credPanel = F(SG, C.PANEL, UDim2.new(0,260,0,160), UDim2.new(0.5,-130,0.5,-80))
credPanel.Visible = false
credPanel.Active  = false
credPanel.ZIndex  = 20
CR(credPanel, 5); SK(credPanel, C.BORDER, 1)

L(credPanel, "CREDITS", 13, C.ACC,
	UDim2.new(1,-16,0,20), UDim2.new(0,10,0,8))
local cClose = B(credPanel, "X", C.SURF, C.TEXT, 10,
	UDim2.new(0,22,0,22), UDim2.new(1,-28,0,7))
CR(cClose, 3)
cClose.MouseButton1Click:Connect(function()
	credPanel.Visible = false
	credPanel.Active  = false
end)
credBtn.MouseButton1Click:Connect(function()
	credPanel.Visible = true
	credPanel.Active  = true
end)
L(credPanel, "BSC PRISON  v1.0.0",      11, C.TEXT,  UDim2.new(1,-20,0,16), UDim2.new(0,10,0,38))
L(credPanel, "Developed by BSC Studios",  9, C.DIM,   UDim2.new(1,-20,0,14), UDim2.new(0,10,0,58))
L(credPanel, "Thank you for playing!",   10, C.ACC,   UDim2.new(1,-20,0,16), UDim2.new(0,10,0,100))

-- ════════════════════════════════════════════════════════════════════
-- TAKIM SEÇİM EKRANI
-- ════════════════════════════════════════════════════════════════════
local teamRoot = F(SG, C.BG, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
teamRoot.Name    = "TeamSelect"
teamRoot.Visible = false

F(teamRoot, C.BLACK, UDim2.new(1,0,0.22,0), UDim2.new(0,0,0,0))  -- üst şerit
L(teamRoot, "SELECT YOUR TEAM", 18, C.WHITE,
	UDim2.new(1,0,0,28), UDim2.new(0,0,0,16), Enum.TextXAlignment.Center)
L(teamRoot, "Choose your role carefully.", 9, C.DIM,
	UDim2.new(0.8,0,0,14), UDim2.new(0.1,0,0,48), Enum.TextXAlignment.Center)
F(teamRoot, C.ACC, UDim2.new(0.08,0,0,2), UDim2.new(0.46,0,0.22,0))

-- Geri butonu
local backBtn = B(teamRoot, "< BACK", C.SURF, C.DIM, 9,
	UDim2.new(0,60,0,22), UDim2.new(0,10,0,12))
CR(backBtn, 3); SK(backBtn, C.BORDER, 1)
backBtn.MouseButton1Click:Connect(function()
	teamRoot.Visible = false
	menuRoot.Visible = true
end)

-- Yükleniyor etiketi
local loadLbl = L(teamRoot, "", 11, C.DIM,
	UDim2.new(1,0,0,20), UDim2.new(0,0,1,-30), Enum.TextXAlignment.Center)

-- Kart grid alanı
local cardArea = F(teamRoot, C.BG, UDim2.new(1,-28,0,185), UDim2.new(0,14,0,78))
cardArea.BackgroundTransparency = 1
local cardGrid = Instance.new("UIGridLayout")
cardGrid.CellSize    = UDim2.new(0.24,-5,0,178)
cardGrid.CellPadding = UDim2.new(0,7,0,0)
cardGrid.Parent      = cardArea

local TEAM_DEFS = {
	{id="POLICE",   label="POLICE",   color=Color3.fromRGB(51,102,255),  desc="Maintain order.\nArrest criminals.",  ab={"Handcuff","Taser","Chain","Rope","Keycard"}},
	{id="CRIMINAL", label="CRIMINAL", color=Color3.fromRGB(195,45,45),   desc="Evade capture.\nRob the vault.",      ab={"Lockpick","Sprint Boost","Disguise"}},
	{id="PRISONER", label="PRISONER", color=Color3.fromRGB(105,105,115), desc="Survive inside.\nFind a way out.",    ab={"Forge","Tunnel","Bribe"}},
	{id="HOSTAGE",  label="HOSTAGE",  color=Color3.fromRGB(210,170,35),  desc="Stay safe.\nWait for rescue.",        ab={"Hide","Signal","Cooperate"}},
}

for _, d in ipairs(TEAM_DEFS) do
	local card = F(cardArea, C.PANEL, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
	CR(card, 4); SK(card, d.color, 1)
	F(card, d.color, UDim2.new(1,0,0,3), UDim2.new(0,0,0,0))  -- renk şeridi
	L(card, d.label,               12, d.color, UDim2.new(1,-10,0,16), UDim2.new(0,6,0,7))
	L(card, d.desc,                 9, C.DIM,   UDim2.new(1,-10,0,30), UDim2.new(0,6,0,26))
	L(card, "ABILITIES",            8, C.ACC,   UDim2.new(1,-10,0,11), UDim2.new(0,6,0,62))
	L(card, table.concat(d.ab,"\n"),8, C.TEXT,  UDim2.new(1,-10,0,65), UDim2.new(0,6,0,75))
	local sel = B(card, "SELECT", d.color, C.WHITE, 10,
		UDim2.new(1,-12,0,24), UDim2.new(0,6,0,148))
	CR(sel, 3)
	local cap = d
	sel.MouseButton1Click:Connect(function()
		-- Tüm kart butonlarını geçici kapat
		for _, ch in ipairs(cardArea:GetChildren()) do
			if ch:IsA("Frame") then
				local bb = ch:FindFirstChildOfClass("TextButton")
				if bb then bb.Active = false end
			end
		end
		loadLbl.Text = "Loading " .. cap.label .. "..."
		if R.TeamSelect then
			R.TeamSelect:FireServer(cap.id)
		end
	end)
end

-- Play → Takım seçim
playBtn.MouseButton1Click:Connect(function()
	menuRoot.Visible = false
	teamRoot.Visible = true
end)

-- ════════════════════════════════════════════════════════════════════
-- HUD
-- ════════════════════════════════════════════════════════════════════
local hudRoot = F(SG, C.BG, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
hudRoot.Name                  = "HUD"
hudRoot.BackgroundTransparency = 1
hudRoot.Visible               = false

-- SAĞ ÜST: Saat + Aktivite
local clkPanel = F(hudRoot, Color3.fromRGB(10,10,14),
	UDim2.new(0,124,0,44), UDim2.new(1,-132,0,7))
CR(clkPanel, 3); SK(clkPanel, C.BORDER, 1)
local clockLbl = L(clkPanel, "06:00 AM", 16, C.WHITE,
	UDim2.new(1,0,0,22), UDim2.new(0,0,0,3), Enum.TextXAlignment.Center)
local actLbl = L(clkPanel, "WAKE UP", 8, C.DIM,
	UDim2.new(1,0,0,13), UDim2.new(0,0,0,26), Enum.TextXAlignment.Center)

-- SOL ALT: Avatar kart
local leftHud = F(hudRoot, C.BG, UDim2.new(0,172,0,108), UDim2.new(0,6,1,-116))
leftHud.BackgroundTransparency = 1

local avPanel = F(leftHud, Color3.fromRGB(11,11,17),
	UDim2.new(1,0,0,44), UDim2.new(0,0,0,0))
CR(avPanel, 3); SK(avPanel, C.BORDER, 1)

local avImg = Instance.new("ImageLabel")
avImg.Size             = UDim2.new(0,32,0,32)
avImg.Position         = UDim2.new(0,5,0.5,-16)
avImg.BackgroundColor3 = C.STEEL
avImg.Image            = ""
avImg.Parent           = avPanel
CR(avImg, 16)

local nameLabel = L(avPanel, player.Name, 10, C.WHITE,
	UDim2.new(0,118,0,17), UDim2.new(0,42,0,5))
local statLabel = L(avPanel, "FREE", 8, C.GREEN,
	UDim2.new(0,118,0,14), UDim2.new(0,42,0,26))

-- Thumbnail
task.spawn(function()
	local ok, url = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
	end)
	if ok and url then avImg.Image = url end
end)

-- HP Bar
local hpBg = F(leftHud, Color3.fromRGB(15,15,22),
	UDim2.new(1,0,0,13), UDim2.new(0,0,0,48))
CR(hpBg, 3)
F(hpBg, Color3.fromRGB(0,0,0), UDim2.new(0,22,1,0), UDim2.new(0,0,0,0))
L(hpBg, "HP", 8, C.DIM, UDim2.new(0,22,1,0), UDim2.new(0,0,0,0), Enum.TextXAlignment.Center)
local hpFill = F(hpBg, C.HP_HI, UDim2.new(1,-22,1,0), UDim2.new(0,22,0,0)); CR(hpFill, 3)

-- Stamina Bar
local stBg = F(leftHud, Color3.fromRGB(15,15,22),
	UDim2.new(1,0,0,13), UDim2.new(0,0,0,65))
CR(stBg, 3)
F(stBg, Color3.fromRGB(0,0,0), UDim2.new(0,22,1,0), UDim2.new(0,0,0,0))
L(stBg, "ST", 8, C.DIM, UDim2.new(0,22,1,0), UDim2.new(0,0,0,0), Enum.TextXAlignment.Center)
local stFill = F(stBg, C.STA, UDim2.new(1,-22,1,0), UDim2.new(0,22,0,0)); CR(stFill, 3)

-- FORGE aç butonu
local forgeBtn = B(leftHud, "FORGE", Color3.fromRGB(14,14,20), C.ACC, 9,
	UDim2.new(0,52,0,17), UDim2.new(0,0,0,84))
CR(forgeBtn, 2); SK(forgeBtn, C.ACC, 1)

-- SAĞ ORTA: > slide panel
local PW = 96  -- panel genişliği
local togBtn = B(hudRoot, ">", Color3.fromRGB(13,13,19), C.ACC, 11,
	UDim2.new(0,16,0,36), UDim2.new(1,-16,0.5,-18))
CR(togBtn, 2); SK(togBtn, C.BORDER, 1)

local slideP = F(hudRoot, Color3.fromRGB(11,11,17),
	UDim2.new(0,PW,0,76), UDim2.new(1,0,0.5,-38))
CR(slideP, 2); SK(slideP, C.BORDER, 1)
L(slideP, "ACTIONS", 8, C.DIM,
	UDim2.new(1,0,0,11), UDim2.new(0,0,0,5), Enum.TextXAlignment.Center)

local sprintBtn = B(slideP, "SPRINT [SHIFT]", C.SURF, C.TEXT, 9,
	UDim2.new(1,-10,0,24), UDim2.new(0,5,0,19))
CR(sprintBtn, 3); SK(sprintBtn, C.BORDER, 1)

local emoteBtn = B(slideP, "EMOTES [E]", C.SURF, C.TEXT, 9,
	UDim2.new(1,-10,0,24), UDim2.new(0,5,0,47))
CR(emoteBtn, 3); SK(emoteBtn, C.BORDER, 1)

local slideOpen = false
slideP.Position = UDim2.new(1,0,0.5,-38)

local function setSlide(open)
	slideOpen = open
	if open then
		TW(slideP, {Position=UDim2.new(1,-PW,0.5,-38)},   0.22, Enum.EasingStyle.Back)
		TW(togBtn, {Position=UDim2.new(1,-PW-16,0.5,-18)}, 0.22, Enum.EasingStyle.Back)
		togBtn.Text = "<"
	else
		TW(slideP, {Position=UDim2.new(1,0,0.5,-38)},   0.2)
		TW(togBtn, {Position=UDim2.new(1,-16,0.5,-18)}, 0.2)
		togBtn.Text = ">"
	end
end
togBtn.MouseButton1Click:Connect(function() setSlide(not slideOpen) end)

-- Sprint sistemi
local stamina   = 100
local sprinting = false

local function getCharState(char)
	if not char then return "Free" end
	return char:GetAttribute("RestraintState") or char:GetAttribute("State") or "Free"
end

local function setSprint(a)
	if sprinting == a then return end
	sprinting = a
	_G.IsLocalSprinting = a
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h and getCharState(c) == "Free" then
		h.WalkSpeed = a and 22 or 16
	end
	sprintBtn.BackgroundColor3 = a and C.ACC  or C.SURF
	sprintBtn.TextColor3       = a and C.WHITE or C.TEXT
end

sprintBtn.MouseButton1Down:Connect(function() setSprint(true)  end)
sprintBtn.MouseButton1Up:Connect(function()   setSprint(false) end)

UIS.InputBegan:Connect(function(inp, gui)
	if gui then return end
	if inp.KeyCode == Enum.KeyCode.LeftShift or inp.KeyCode == Enum.KeyCode.RightShift then
		local c = player.Character
		if c and getCharState(c) == "Free" and stamina > 5 then
			setSprint(true)
		end
	end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.LeftShift or inp.KeyCode == Enum.KeyCode.RightShift then
		setSprint(false)
	end
end)

-- HP + Stamina canlı güncelleme
Run.Heartbeat:Connect(function(dt)
	if sprinting then
		stamina = math.max(0, stamina - dt*18)
		if stamina <= 0 then setSprint(false) end
	else
		stamina = math.min(100, stamina + dt*9)
	end
	stFill.Size = UDim2.new(stamina/100, 0, 1, 0)

	local c = player.Character; if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
	local pct = math.clamp(h.Health / math.max(h.MaxHealth,1), 0, 1)
	hpFill.Size = UDim2.new(pct, 0, 1, 0)
	hpFill.BackgroundColor3 = pct > 0.6 and C.HP_HI or (pct > 0.3 and C.HP_MID or C.HP_LOW)
end)

-- ════════════════════════════════════════════════════════════════════
-- FORGE POPUP
-- ════════════════════════════════════════════════════════════════════
local forgeOvr = F(SG, C.BLACK, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
forgeOvr.BackgroundTransparency = 0.65
forgeOvr.Visible = false
forgeOvr.ZIndex  = 50

local forgeFrame = F(SG, Color3.fromRGB(10,10,16),
	UDim2.new(0,480,0,310), UDim2.new(0.5,-240,0.5,-155))
forgeFrame.Visible = false
forgeFrame.ZIndex  = 51
CR(forgeFrame, 5); SK(forgeFrame, C.ACC, 1)

local fgBar = F(forgeFrame, Color3.fromRGB(6,6,12),
	UDim2.new(1,0,0,34), UDim2.new(0,0,0,0))
SK(fgBar, C.BORDER, 1)
L(fgBar, "FORGE", 12, C.ACC,
	UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Enum.TextXAlignment.Center)
local fgX = B(fgBar, "X", Color3.fromRGB(18,6,6), C.RED, 9,
	UDim2.new(0,22,0,22), UDim2.new(1,-26,0,4))
CR(fgX, 3)

local function closeForge()
	TW(forgeFrame, {Position=UDim2.new(0.5,-240,0.5,100), BackgroundTransparency=1}, 0.2)
	task.wait(0.22)
	forgeFrame.Visible = false
	forgeFrame.BackgroundTransparency = 0
	forgeOvr.Visible = false
end
fgX.MouseButton1Click:Connect(closeForge)
forgeOvr.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then closeForge() end
end)

-- Yakındaki oyuncular paneli (sol)
local nearP = F(forgeFrame, Color3.fromRGB(7,7,13),
	UDim2.new(0,120,0,260), UDim2.new(0,8,0,36))
CR(nearP, 3)
L(nearP, "NEARBY", 8, C.ACC,
	UDim2.new(1,0,0,11), UDim2.new(0,0,0,3), Enum.TextXAlignment.Center)

local nearSel = nil  -- seçili Player

local function buildNearList(data)
	for _, b in ipairs(nearP:GetChildren()) do
		if b:IsA("TextButton") then b:Destroy() end
	end
	if not data or #data == 0 then
		local nl = L(nearP, "(none)", 8, C.DIM,
			UDim2.new(1,-6,0,12), UDim2.new(0,3,0,18))
		nl.TextXAlignment = Enum.TextXAlignment.Center
		return
	end
	for i, d in ipairs(data) do
		local nb = B(nearP, d.name, Color3.fromRGB(14,14,20), C.TEXT, 8,
			UDim2.new(1,-6,0,18), UDim2.new(0,3,0,14+(i-1)*22))
		CR(nb, 2)
		local dot = F(nb, d.state=="Free" and C.GREEN or C.RED,
			UDim2.new(0,5,0,5), UDim2.new(1,-8,0.5,-2))
		CR(dot, 3)
		local cap = d
		nb.MouseButton1Click:Connect(function()
			nearSel = Players:FindFirstChild(cap.name)
			for _, ch in ipairs(nearP:GetChildren()) do
				if ch:IsA("TextButton") then
					ch.BackgroundColor3 = Color3.fromRGB(14,14,20)
				end
			end
			nb.BackgroundColor3 = C.ACC
			if nearSel and nearSel.Character then
				refreshStickman(getCharState(nearSel.Character))
			end
		end)
	end
end

-- STİCKMAN (orta)
local stickC = F(forgeFrame, Color3.fromRGB(7,7,13),
	UDim2.new(0,110,0,260), UDim2.new(0,132,0,36))
CR(stickC, 3)

local function NP(x,y,w,h2,col,r)
	local pp = F(stickC, col, UDim2.new(0,w,0,h2), UDim2.new(0,x,0,y))
	if r then CR(pp, r) end
	return pp
end
local nH  = NP(37, 5, 36, 36, C.NOR, 11)
local nNk = NP(47,42,16,10, C.NOR,  2)
local nBd = NP(37,53,36,40, C.NOR,  2)
local nLA = NP(20,55,14,34, C.NOR,  2)
local nRA = NP(76,55,14,34, C.NOR,  2)
local nLL = NP(37,94,15,38, C.NOR,  2)
local nRL = NP(58,94,15,38, C.NOR,  2)

-- Bilgi paneli (sağ)
local infoP = F(forgeFrame, Color3.fromRGB(13,13,20),
	UDim2.new(0,210,0,260), UDim2.new(0,258,0,36))
CR(infoP, 3); SK(infoP, C.BORDER, 1)

local stTitle = L(infoP, "FREE", 14, C.GREEN,
	UDim2.new(1,0,0,20), UDim2.new(0,0,0,6), Enum.TextXAlignment.Center)
local stDesc  = L(infoP, "No restraints.", 9, C.DIM,
	UDim2.new(1,-10,0,40), UDim2.new(0,5,0,36))

local pBg   = F(infoP, Color3.fromRGB(18,18,28), UDim2.new(1,-10,0,10), UDim2.new(0,5,0,120)); CR(pBg,4)
local pFill = F(pBg, C.ACC, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0)); CR(pFill,4)

local ePBg  = F(infoP, Color3.fromRGB(18,18,28), UDim2.new(1,-10,0,10), UDim2.new(0,5,0,136)); CR(ePBg,4)
ePBg.Visible = false
local ePFill = F(ePBg, C.ACC, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0)); CR(ePFill,4)

local ePLbl = L(infoP, "E x12", 9, C.ACC,
	UDim2.new(1,0,0,14), UDim2.new(0,0,0,154), Enum.TextXAlignment.Center)
ePLbl.Visible = false

local resLbl = L(infoP, "", 9, C.GREEN,
	UDim2.new(1,0,0,14), UDim2.new(0,0,0,174), Enum.TextXAlignment.Center)

local attBtn = B(infoP, "HOLD TO ATTEMPT", C.ACC, C.WHITE, 9,
	UDim2.new(1,-10,0,32), UDim2.new(0,5,0,210))
CR(attBtn, 3)

local curSt = "Free"

function refreshStickman(state)
	for _, pp in ipairs({nH,nNk,nBd,nLA,nRA,nLL,nRL}) do
		pp.BackgroundColor3 = C.NOR
	end
	attBtn.Visible = true; pBg.Visible = true
	ePBg.Visible   = false; ePLbl.Visible = false

	if state == "Handcuffed" then
		nLA.BackgroundColor3 = C.BND; nRA.BackgroundColor3 = C.BND
		stTitle.Text = "HANDCUFFED"; stTitle.TextColor3 = C.RED
		stDesc.Text  = "Wrists bound.\nHold to break free."
		attBtn.Text  = "HOLD TO ATTEMPT"; attBtn.BackgroundColor3 = C.ACC
	elseif state == "Hogtied" then
		nLA.BackgroundColor3 = C.BND; nRA.BackgroundColor3 = C.BND
		nLL.BackgroundColor3 = C.BND; nRL.BackgroundColor3 = C.BND
		stTitle.Text = "HOGTIED"; stTitle.TextColor3 = C.RED
		stDesc.Text  = "Fully bound.\nHold to break free."
		attBtn.Text  = "HOLD TO ATTEMPT"; attBtn.BackgroundColor3 = C.ACC
	elseif state == "Chained" then
		nNk.BackgroundColor3 = C.BND
		stTitle.Text = "CHAINED"; stTitle.TextColor3 = C.YELLOW
		stDesc.Text  = "Collar & chain.\nPress E 12 times."
		attBtn.Visible = false; pBg.Visible = false
		ePBg.Visible   = true;  ePLbl.Visible = true
	else
		stTitle.Text = "FREE"; stTitle.TextColor3 = C.GREEN
		stDesc.Text  = "No restraints."
		attBtn.Text  = "(Not bound)"; attBtn.BackgroundColor3 = C.SURF
	end
	pFill.Size = UDim2.new(0,0,1,0); ePFill.Size = UDim2.new(0,0,1,0); resLbl.Text = ""
end

local function openForge()
	forgeOvr.Visible  = true
	forgeFrame.Visible = true
	forgeFrame.BackgroundTransparency = 1
	forgeFrame.Position = UDim2.new(0.5,-240,0.5,80)
	TW(forgeFrame, {Position=UDim2.new(0.5,-240,0.5,-155), BackgroundTransparency=0},
		0.26, Enum.EasingStyle.Back)
	nearSel = nil
	buildNearList({})
	refreshStickman(curSt)
	setSlide(false)
end
forgeBtn.MouseButton1Click:Connect(openForge)

-- Hold to attempt
local holding = false; local holdConn = nil; local HOLD_DUR = 2; local ePresses = 0

attBtn.MouseButton1Down:Connect(function()
	local targetState = curSt
	if nearSel and nearSel.Character then
		targetState = getCharState(nearSel.Character)
	end
	if targetState == "Free" or targetState == "Chained" or targetState == "Stunned" then return end
	if holding then return end
	holding = true
	attBtn.BackgroundColor3 = Color3.fromRGB(22,60,185)
	local t = 0
	holdConn = Run.Heartbeat:Connect(function(dt)
		t = t + dt
		pFill.Size = UDim2.new(math.clamp(t/HOLD_DUR,0,1), 0, 1, 0)
		if t >= HOLD_DUR then
			holdConn:Disconnect(); holdConn = nil; holding = false
			pFill.Size = UDim2.new(0,0,1,0); attBtn.BackgroundColor3 = C.ACC
			local ok = math.random() < 0.6
			local tc = nearSel and nearSel.Character or nil
			if R.EscapeAttempt then R.EscapeAttempt:FireServer(ok, tc) end
			resLbl.TextColor3 = ok and C.GREEN or C.RED
			resLbl.Text       = ok and "ESCAPED!" or "Failed."
			if ok then
				task.delay(1.1, function()
					TW(forgeFrame, {BackgroundTransparency=1}, 0.18)
					task.wait(0.2)
					forgeFrame.Visible = false
					forgeFrame.BackgroundTransparency = 0
					forgeOvr.Visible = false
				end)
			end
		end
	end)
end)

attBtn.MouseButton1Up:Connect(function()
	if holdConn then holdConn:Disconnect(); holdConn = nil end
	holding = false; attBtn.BackgroundColor3 = C.ACC
	TW(pFill, {Size=UDim2.new(0,0,1,0)}, 0.2)
end)

-- E x12 (Chained)
UIS.InputBegan:Connect(function(inp, gui)
	if gui then return end
	if inp.KeyCode ~= Enum.KeyCode.E then return end
	if not forgeFrame.Visible then openForge(); return end
	local targetState = curSt
	if nearSel and nearSel.Character then
		targetState = getCharState(nearSel.Character)
	end
	if targetState ~= "Chained" then return end
	ePresses = math.min(ePresses+1, 12)
	ePFill.Size = UDim2.new(ePresses/12, 0, 1, 0)
	ePLbl.Text  = "E x" .. tostring(12 - ePresses)
	if ePresses >= 12 then
		ePresses = 0; ePFill.Size = UDim2.new(0,0,1,0); ePLbl.Text = "E x12"
		local ok = math.random() < 0.55
		local tc = nearSel and nearSel.Character or nil
		if R.EscapeAttempt then R.EscapeAttempt:FireServer(ok, tc) end
		resLbl.TextColor3 = ok and C.GREEN or C.RED
		resLbl.Text = ok and "CHAIN BROKEN!" or "Chain held."
		if ok then
			task.delay(1.1, function() forgeFrame.Visible = false; forgeOvr.Visible = false end)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════
-- EMOTE POPUP
-- ════════════════════════════════════════════════════════════════════
local emoteOvr = F(SG, C.BLACK, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
emoteOvr.BackgroundTransparency = 0.6
emoteOvr.Visible = false
emoteOvr.ZIndex  = 60

local emoteFrame = F(SG, Color3.fromRGB(11,11,17),
	UDim2.new(0,290,0,252), UDim2.new(0.5,-145,0.5,-126))
emoteFrame.Visible = false
emoteFrame.ZIndex  = 61
CR(emoteFrame, 5); SK(emoteFrame, C.ACC, 1)

local eTBar = F(emoteFrame, Color3.fromRGB(6,6,12),
	UDim2.new(1,0,0,34), UDim2.new(0,0,0,0))
SK(eTBar, C.BORDER, 1)
L(eTBar, "EMOTES", 12, C.ACC,
	UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Enum.TextXAlignment.Center)
local eX = B(eTBar, "X", Color3.fromRGB(18,6,6), C.RED, 9,
	UDim2.new(0,22,0,22), UDim2.new(1,-26,0,4))
CR(eX, 3)

local function closeEmote()
	TW(emoteFrame, {Position=UDim2.new(0.5,-145,0.5,80), BackgroundTransparency=1}, 0.2)
	task.wait(0.22)
	emoteFrame.Visible = false
	emoteFrame.BackgroundTransparency = 0
	emoteOvr.Visible = false
end
eX.MouseButton1Click:Connect(closeEmote)
emoteOvr.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then closeEmote() end
end)

local eContent = F(emoteFrame, Color3.fromRGB(0,0,0),
	UDim2.new(1,-14,1,-38), UDim2.new(0,7,0,32))
eContent.BackgroundTransparency = 1
local eGrid = Instance.new("UIGridLayout")
eGrid.CellSize    = UDim2.new(0.5,-4,0,42)
eGrid.CellPadding = UDim2.new(0,4,0,4)
eGrid.Parent      = eContent

local EMOTES = {"Wave","Sit","Dance","Clap","Kneel","HandsUp","Lay"}
for i, en in ipairs(EMOTES) do
	local eb = B(eContent, en .. " [" .. i .. "]", Color3.fromRGB(18,18,26), C.TEXT, 11)
	CR(eb, 3); SK(eb, C.BORDER, 1)
	local cap = en
	eb.MouseButton1Click:Connect(function()
		local c = player.Character
		if c and getCharState(c) == "Free" and R.PlayEmote then
			R.PlayEmote:FireServer(cap)
		end
		closeEmote(); setSlide(false)
	end)
end

local function openEmote()
	local c = player.Character
	if c and getCharState(c) ~= "Free" then
		return
	end
	emoteOvr.Visible   = true
	emoteFrame.Visible = true
	emoteFrame.BackgroundTransparency = 1
	emoteFrame.Position = UDim2.new(0.5,-145,0.5,60)
	TW(emoteFrame, {Position=UDim2.new(0.5,-145,0.5,-126), BackgroundTransparency=0},
		0.26, Enum.EasingStyle.Back)
end
emoteBtn.MouseButton1Click:Connect(function() openEmote(); setSlide(false) end)

-- Global toggle (1-7 kısayollar)
_G.ToggleEmoteMenu = function()
	if emoteFrame.Visible then closeEmote() else openEmote() end
end

-- 1-7 emote kısayolları
local EMOTE_KEYS = {
	[Enum.KeyCode.One]  ="Wave",  [Enum.KeyCode.Two]  ="Sit",
	[Enum.KeyCode.Three]="Dance", [Enum.KeyCode.Four] ="Clap",
	[Enum.KeyCode.Five] ="Kneel", [Enum.KeyCode.Six]  ="HandsUp",
	[Enum.KeyCode.Seven]="Lay",
}
UIS.InputBegan:Connect(function(inp, gui)
	if gui then return end
	local em = EMOTE_KEYS[inp.KeyCode]
	if em then
		local c = player.Character
		if c and getCharState(c) == "Free" and R.PlayEmote then
			R.PlayEmote:FireServer(em)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════
-- STATE ETİKETİ
-- ════════════════════════════════════════════════════════════════════
local function onState(state)
	curSt = state or "Free"
	statLabel.Text = curSt
	if curSt == "Free" then
		statLabel.TextColor3 = C.GREEN
	elseif curSt == "Stunned" then
		statLabel.TextColor3 = C.YELLOW
	else
		statLabel.TextColor3 = C.RED
	end
	if forgeFrame.Visible then refreshStickman(curSt) end
	if curSt == "Free" then
		forgeFrame.Visible = false
		forgeOvr.Visible   = false
	end
end

-- ════════════════════════════════════════════════════════════════════
-- KARAKTER SPAWN HANDLER
-- ════════════════════════════════════════════════════════════════════
local function setupChar(char)
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.1)
	hudRoot.Visible  = true
	menuRoot.Visible = false
	teamRoot.Visible = false

	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum.Died:Connect(function()
			hudRoot.Visible = false
			forgeFrame.Visible = false; forgeOvr.Visible = false
			emoteFrame.Visible = false; emoteOvr.Visible = false
			teamRoot.Visible = true   -- ölünce takım seçimine dön
			-- Kart butonlarını sıfırla
			for _, ch in ipairs(cardArea:GetChildren()) do
				if ch:IsA("Frame") then
					local bb = ch:FindFirstChildOfClass("TextButton")
					if bb then bb.Active = true end
				end
			end
			loadLbl.Text = ""
			stamina = 100; setSprint(false); curSt = "Free"
			statLabel.Text = "FREE"; statLabel.TextColor3 = C.GREEN
		end)
	end

	local function bindStateSignal(attrName)
		local ok, signal = pcall(function()
			return char:GetAttributeChangedSignal(attrName)
		end)
		if ok and signal then
			signal:Connect(function()
				onState(getCharState(char))
			end)
		end
	end

	bindStateSignal("RestraintState")
	bindStateSignal("State")
	onState(getCharState(char))
end

player.CharacterAdded:Connect(setupChar)
if player.Character then task.spawn(setupChar, player.Character) end

-- ════════════════════════════════════════════════════════════════════
-- REMOTE BAĞLANTILARI (EN SONDA — UI zaten kurulu, crash yok)
-- ════════════════════════════════════════════════════════════════════
task.spawn(function()
	local ok, Remotes = pcall(function()
		return RepStore:WaitForChild("Remotes", 60)
	end)
	if not ok or not Remotes then
		warn("[MAIN_UI] Remotes yüklenemedi — sunucu başlamadı mı?")
		return
	end

	-- Remote referanslarını doldur
	R.TeamSelect    = Remotes:WaitForChild("TeamSelect",     30)
	R.EscapeAttempt = Remotes:WaitForChild("EscapeAttempt",  30)
	R.PlayEmote     = Remotes:WaitForChild("PlayEmote",      30)

	local rActivity = Remotes:WaitForChild("ActivityUpdate", 30)
	local rDay      = Remotes:WaitForChild("DayNightSync",   30)
	local rForge    = Remotes:WaitForChild("ForgePrompt",    30)

	-- Aktivite güncelle
	if rActivity then
		rActivity.OnClientEvent:Connect(function(a)
			actLbl.Text = tostring(a)
		end)
	end

	-- Saat sync (2 saniyede bir server gönderir)
	if rDay then
		rDay.OnClientEvent:Connect(function(gh)
			local h   = math.floor(gh) % 24
			local m   = math.floor((gh - math.floor(gh)) * 60)
			local ap  = h >= 12 and "PM" or "AM"
			local h12 = h % 12; if h12 == 0 then h12 = 12 end
			clockLbl.Text       = string.format("%02d:%02d %s", h12, m, ap)
			Lighting.ClockTime  = gh
		end)
	end

	-- Forge yakın liste
	if rForge then
		rForge.OnClientEvent:Connect(function(data)
			if forgeFrame.Visible then buildNearList(data) end
		end)
	end

	print("[MAIN_UI] ✅ Tüm remote'lar bağlandı")
end)

print("[MAIN_UI] ✅ UI oluşturuldu — Remotes arka planda yükleniyor")
