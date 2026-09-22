--[[
	GAME_UI
	StarterPlayerScripts içine tek LocalScript olarak konulmak üzere tasarlanmıştır.

	Odak:
	- Sadece UI/UX. Oyun mantığı, 3D dünya ve server-side gameplay yoktur.
	- Remote'lar varsa otomatik bağlanır; yoksa UI çalışmaya devam eder.
	- Remote'lar 30 saniye boyunca sessizce beklenir ve bulunamazsa akış bloke edilmez.
	- Tüm görsel asset/renk/config tabloları dosyanın üst tarafındadır.
	- Yorumlar Türkçe ve kod tek dosyadır.
]]

-- ============================================================================
-- 01) ASSETS / GAMES / PALET / SERVİSLER
-- ============================================================================

local ASSETS = {
	StudTexture = "138180362075438",

	GoldTrophy = "94183347759526",
	SilverTrophy = "86596347754683",
	BronzeTrophy = "90960235662302",

	Icon_Play = "79916773437476",
	Icon_Settings = "15859572237",
	Icon_Stats = "93419920420416",
	Icon_Close = "96300749080072",
	Icon_Back = "17368177673",

	Sound_On = "16572029543",
	Sound_Off = "16572023916",

	Icon_Leaderboard = "94183347759526",

	-- Oyun ikonları şimdilik boş. Boş olduğu durumda studdedIcon ★ fallback kullanır.
	Icon_DodgeRun = "",
	Icon_TargetRush = "",
	Icon_StackTower = "",
	Icon_CoinRush = "",
	Icon_JumpChallenge = "",
	Icon_ReactionTest = "",
	Icon_ColorRush = "",
	Icon_MemoryMatch = "",
	Icon_FallingPlatforms = "",
	Icon_FloorIsLava = "",

	Snd_Click = "6895079853",
	Snd_Hover = "6895079921",
	Snd_Back = "6895079760",
	Snd_Open = "6895080105",
	Snd_Tick = "6023426941",
	Snd_Start = "6023426926",
}

local PALET = {
	Orange = Color3.fromRGB(245, 130, 30),
	OrangeDark = Color3.fromRGB(200, 90, 15),
	OrangeLight = Color3.fromRGB(255, 175, 85),

	Cream = Color3.fromRGB(250, 220, 160),
	CreamLight = Color3.fromRGB(255, 240, 210),

	Dark = Color3.fromRGB(38, 38, 44),
	DarkSoft = Color3.fromRGB(60, 60, 68),

	Panel = Color3.fromRGB(255, 252, 248),
	PanelStud = Color3.fromRGB(245, 240, 230),

	TextDark = Color3.fromRGB(45, 45, 52),
	Muted = Color3.fromRGB(150, 140, 130),

	Success = Color3.fromRGB(80, 200, 120),
	Danger = Color3.fromRGB(230, 70, 60),

	Gold = Color3.fromRGB(255, 205, 60),
	Silver = Color3.fromRGB(200, 205, 215),
	Bronze = Color3.fromRGB(205, 130, 80),
}

local GAMES = {
	{Id = "DodgeRun", Name = "DODGE RUN", Description = "Engelleri aş, tempoyu koru.", IconKey = "Icon_DodgeRun"},
	{Id = "TargetRush", Name = "TARGET RUSH", Description = "Hedefleri hızlıca temizle.", IconKey = "Icon_TargetRush"},
	{Id = "StackTower", Name = "STACK TOWER", Description = "Kuleyi kusursuz yükseklikte kur.", IconKey = "Icon_StackTower"},
	{Id = "CoinRush", Name = "COIN RUSH", Description = "En yüksek coin skoruna koş.", IconKey = "Icon_CoinRush"},
	{Id = "JumpChallenge", Name = "JUMP CHALLENGE", Description = "Zıplama ritmini kaybetme.", IconKey = "Icon_JumpChallenge"},
	{Id = "ReactionTest", Name = "REACTION TEST", Description = "Reflekslerini milisaniyede ölç.", IconKey = "Icon_ReactionTest"},
	{Id = "ColorRush", Name = "COLOR RUSH", Description = "Doğru rengi doğru anda bul.", IconKey = "Icon_ColorRush"},
	{Id = "MemoryMatch", Name = "MEMORY MATCH", Description = "Kartları hafızanla eşleştir.", IconKey = "Icon_MemoryMatch"},
	{Id = "FallingPlatforms", Name = "FALLING PLATFORMS", Description = "Düşen platformlardan kaçın.", IconKey = "Icon_FallingPlatforms"},
	{Id = "FloorIsLava", Name = "FLOOR IS LAVA", Description = "Zemin tehlikeli, yukarı çık.", IconKey = "Icon_FloorIsLava"},
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled
local musicOn = true
local sfxOn = true

-- ============================================================================
-- 02) GÜVENLİ PROPERTY YAZMA / REZERVED FİLTRESİ
-- ============================================================================

local RESERVED = {
	Color = true,
	Radius = true,
	Parent = true,
	Glow = true,
	GlowColor = true,
	StrokeColor = true,
	StrokeThickness = true,
	Studded = true,
}

local function safeSet(instance, property, value)
	if not instance or value == nil then
		return false
	end

	return pcall(function()
		instance[property] = value
	end)
end

local function applyProps(instance, props)
	if not instance or type(props) ~= "table" then
		return instance
	end

	for key, value in pairs(props) do
		if not RESERVED[key] then
			pcall(function()
				instance[key] = value
			end)
		end
	end

	return instance
end

local function create(className, parent, props)
	local instance = Instance.new(className)

	if parent then
		safeSet(instance, "Parent", parent)
	end

	applyProps(instance, props)

	return instance
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 18)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or PALET.CreamLight
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, topColor, bottomColor)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	g.Parent = parent
	return g
end

local function addStudOverlay(parent, transparency)
	local overlay = Instance.new("ImageLabel")
	overlay.Name = "StudOverlay"
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.fromScale(0, 0)
	overlay.Image = "rbxassetid://" .. ASSETS.StudTexture
	overlay.ImageTransparency = transparency or 0.84
	overlay.ScaleType = Enum.ScaleType.Tile
	overlay.TileSize = UDim2.fromOffset(28, 28)
	overlay.ZIndex = parent.ZIndex
	overlay.Active = false
	overlay.Selectable = false
	overlay.Parent = parent

	corner(overlay, 18)

	return overlay
end

local function topHighlight(parent)
	local h = Instance.new("Frame")
	h.Name = "TopHighlight"
	h.BorderSizePixel = 0
	h.BackgroundColor3 = PALET.CreamLight
	h.BackgroundTransparency = 0.16
	h.Size = UDim2.new(1, -24, 0, 2)
	h.Position = UDim2.fromOffset(12, 3)
	h.ZIndex = parent.ZIndex + 1
	h.Parent = parent
	corner(h, 2)
	return h
end

-- ============================================================================
-- 03) TWEEN / SAYI / SES HELPERLARI
-- ============================================================================

local function tween(instance, duration, goal, easingStyle, easingDirection)
	if not instance or not instance.Parent then
		return nil
	end

	local ok, tw = pcall(function()
		return TweenService:Create(
			instance,
			TweenInfo.new(
				duration,
				easingStyle or Enum.EasingStyle.Quad,
				easingDirection or Enum.EasingDirection.Out
			),
			goal
		)
	end)

	if not ok or not tw then
		return nil
	end

	tw:Play()
	return tw
end

local function offsetPosition(basePosition, xOffset, yOffset)
	return UDim2.new(
		basePosition.X.Scale,
		basePosition.X.Offset + (xOffset or 0),
		basePosition.Y.Scale,
		basePosition.Y.Offset + (yOffset or 0)
	)
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	local negative = numberValue < 0
	numberValue = math.floor(math.abs(numberValue))

	local text = tostring(numberValue)
	while #text > 3 do
		local left = string.sub(text, 1, #text - 3)
		local right = string.sub(text, -3)
		text = left .. "," .. right
	end

	if negative then
		text = "-" .. text
	end

	return text
end

local SoundBank = {}

local function makeSound(name, assetId, volume, looped)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. assetId
	s.Volume = volume or 0.5
	s.Looped = looped or false
	s.Parent = SoundService
	SoundBank[name] = s
	return s
end

makeSound("Snd_Click", ASSETS.Snd_Click, 0.5, false)
makeSound("Snd_Hover", ASSETS.Snd_Hover, 0.25, false)
makeSound("Snd_Back", ASSETS.Snd_Back, 0.5, false)
makeSound("Snd_Open", ASSETS.Snd_Open, 0.45, false)
makeSound("Snd_Tick", ASSETS.Snd_Tick, 0.14, true)
makeSound("Snd_Start", ASSETS.Snd_Start, 0.55, false)

local function playSfx(name)
	if not sfxOn then
		return
	end

	local sound = SoundBank[name]
	if not sound then
		return
	end

	pcall(function()
		sound:Stop()
		sound.TimePosition = 0
		sound:Play()
	end)
end

local function playMusic()
	if not musicOn then
		return
	end

	local sound = SoundBank.Snd_Tick
	if sound and not sound.IsPlaying then
		pcall(function()
			sound:Play()
		end)
	end
end

local function stopMusic()
	local sound = SoundBank.Snd_Tick
	if sound then
		pcall(function()
			sound:Stop()
		end)
	end
end

-- ============================================================================
-- 04) STUDDED GÖRSEL HELPERLARI
-- ============================================================================

local function panel(parent, props)
	local frame = create("Frame", parent)
	safeSet(frame, "BackgroundColor3", PALET.Panel)
	safeSet(frame, "BorderSizePixel", 0)
	safeSet(frame, "ZIndex", props and props.ZIndex or 2)

	applyProps(frame, props)

	corner(frame, props and props.Radius or 20)
	stroke(frame, PALET.Cream, props and props.StrokeThickness or 2.5)
	gradient(frame, PALET.Panel, PALET.PanelStud)
	addStudOverlay(frame, 0.86)
	topHighlight(frame)

	return frame
end

local function studdedPanel(parent, props)
	local frame = create("Frame", parent)
	safeSet(frame, "BackgroundColor3", PALET.Orange)
	safeSet(frame, "BorderSizePixel", 0)
	safeSet(frame, "ZIndex", props and props.ZIndex or 2)

	applyProps(frame, props)

	corner(frame, props and props.Radius or 20)
	stroke(frame, PALET.CreamLight, props and props.StrokeThickness or 3)
	gradient(frame, PALET.OrangeLight, PALET.OrangeDark)
	addStudOverlay(frame, 0.82)
	topHighlight(frame)

	return frame
end

local function startShine(buttonObject, shineZIndex)
	local shine = Instance.new("Frame")
	shine.Name = "ShineSweep"
	shine.BackgroundColor3 = PALET.CreamLight
	shine.BackgroundTransparency = 0.70
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromOffset(54, 160)
	shine.Position = UDim2.new(0, -90, 0.5, 0)
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Rotation = 18
	shine.ZIndex = shineZIndex or (buttonObject.ZIndex + 1)
	shine.Parent = buttonObject

	corner(shine, 10)

	task.spawn(function()
		while shine.Parent and buttonObject.Parent do
			task.wait(2.0 + math.random() * 1.5)
			if not shine.Parent then
				break
			end

			shine.Position = UDim2.new(0, -90, 0.5, 0)

			local tw = tween(
				shine,
				1.6,
				{Position = UDim2.new(1, 90, 0.5, 0)},
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

			if tw then
				tw.Completed:Wait()
			end
		end
	end)

	return shine
end

local function makeButtonContent(buttonObject, text, iconAsset, contentZIndex)
	local z = contentZIndex or (buttonObject.ZIndex + 3)

	local holder = Instance.new("Frame")
	holder.Name = "Content"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, 1)
	holder.Position = UDim2.fromScale(0, 0)
	holder.ZIndex = z
	holder.Parent = buttonObject

	local hasIcon = type(iconAsset) == "string" and iconAsset ~= ""
	local iconWidth = hasIcon and 46 or 0

	if hasIcon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromOffset(32, 32)
		icon.Position = UDim2.new(0, 18, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Image = "rbxassetid://" .. iconAsset
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = z + 1
		icon.Parent = holder
	end

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -(36 + iconWidth), 1, 0)
	label.Position = UDim2.new(0, 18 + iconWidth, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = text or ""
	label.TextColor3 = PALET.CreamLight
	label.TextSize = 17
	label.TextXAlignment = hasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = z + 1
	label.Parent = holder

	return holder, label
end

local function button(parent, text, options)
	options = options or {}

	local fillTop = options.FillTop or PALET.OrangeLight
	local fillBottom = options.FillBottom or PALET.OrangeDark
	local textColor = options.TextColor or PALET.CreamLight
	local radius = options.Radius or 18

	local b = create("TextButton", parent)
	safeSet(b, "AutoButtonColor", false)
	safeSet(b, "Text", "")
	safeSet(b, "BackgroundColor3", fillTop)
	safeSet(b, "BorderSizePixel", 0)
	safeSet(b, "ZIndex", options.ZIndex or 3)
	safeSet(b, "Size", options.Size or UDim2.fromOffset(420, 58))

	corner(b, radius)
	stroke(b, options.StrokeColor or PALET.Cream, options.StrokeThickness or 2.2)
	gradient(b, fillTop, fillBottom)
	addStudOverlay(b, 0.82)
	startShine(b, (options.ZIndex or 3) + 1)

	local content = makeButtonContent(
		b,
		text,
		options.Icon,
		(b.ZIndex or 3) + 3
	)

	if content and content:FindFirstChild("Text") then
		content.Text.TextColor3 = textColor
	end

	return b
end

local function outlineButton(parent, text, options)
	options = options or {}

	local b = create("TextButton", parent)
	safeSet(b, "AutoButtonColor", false)
	safeSet(b, "Text", "")
	safeSet(b, "BackgroundColor3", PALET.Panel)
	safeSet(b, "BorderSizePixel", 0)
	safeSet(b, "ZIndex", options.ZIndex or 3)
	safeSet(b, "Size", options.Size or UDim2.fromOffset(240, 52))

	corner(b, options.Radius or 18)
	stroke(b, PALET.Orange, options.StrokeThickness or 1.6)
	gradient(b, PALET.Panel, PALET.PanelStud)
	addStudOverlay(b, 0.88)
	startShine(b, (options.ZIndex or 3) + 1)

	local content = makeButtonContent(
		b,
		text,
		options.Icon,
		(b.ZIndex or 3) + 3
	)

	if content and content:FindFirstChild("Text") then
		content.Text.TextColor3 = PALET.TextDark
	end

	return b
end

local function attachButtonFx(buttonObject)
	local baseSize = buttonObject.Size
	local hovering = false
	local pressed = false

	local function sizeWithDelta(widthDelta, heightDelta)
		return UDim2.new(
			baseSize.X.Scale,
			baseSize.X.Offset + widthDelta,
			baseSize.Y.Scale,
			baseSize.Y.Offset + heightDelta
		)
	end

	buttonObject.MouseEnter:Connect(function()
		hovering = true
		playSfx("Snd_Hover")
		tween(
			buttonObject,
			0.12,
			{Size = sizeWithDelta(6, 0)},
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
	end)

	buttonObject.MouseLeave:Connect(function()
		hovering = false
		if not pressed then
			tween(
				buttonObject,
				0.12,
				{Size = baseSize},
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)
		end
	end)

	buttonObject.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		pressed = true
		playSfx("Snd_Click")

		tween(
			buttonObject,
			0.08,
			{Size = sizeWithDelta(-8, -6)},
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
	end)

	buttonObject.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		pressed = false

		tween(
			buttonObject,
			0.30,
			{Size = hovering and sizeWithDelta(6, 0) or baseSize},
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)
	end)

	-- Activated ile ayrıca bir callback bağlanmaz; helper sadece FX bağlar.
	return buttonObject
end

local function studdedIcon(parent, iconAsset, options)
	options = options or {}

	local frame = create("Frame", parent)
	safeSet(frame, "BackgroundColor3", options.BackgroundColor or PALET.Orange)
	safeSet(frame, "BorderSizePixel", 0)
	safeSet(frame, "ZIndex", options.ZIndex or 4)
	safeSet(frame, "Size", options.Size or UDim2.fromOffset(92, 92))

	corner(frame, options.Radius or 20)
	stroke(frame, PALET.CreamLight, options.StrokeThickness or 2)
	gradient(frame, PALET.OrangeLight, PALET.OrangeDark)
	addStudOverlay(frame, 0.82)

	local hasIcon = type(iconAsset) == "string" and iconAsset ~= ""

	if hasIcon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromScale(0.72, 0.72)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Image = "rbxassetid://" .. iconAsset
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = frame.ZIndex + 2
		icon.Parent = frame
	else
		local fallback = Instance.new("TextLabel")
		fallback.Name = "Fallback"
		fallback.BackgroundTransparency = 1
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.Position = UDim2.fromScale(0, 0)
		fallback.Font = Enum.Font.GothamBlack
		fallback.Text = "★"
		fallback.TextColor3 = PALET.CreamLight
		fallback.TextSize = 46
		fallback.ZIndex = frame.ZIndex + 2
		fallback.Parent = frame
	end

	return frame
end

local function trophyIcon(parent, rank)
	if rank == 1 then
		return studdedIcon(parent, ASSETS.GoldTrophy, {
			Size = UDim2.fromOffset(40, 40),
			Radius = 12,
			StrokeThickness = 1.5,
		})
	elseif rank == 2 then
		return studdedIcon(parent, ASSETS.SilverTrophy, {
			Size = UDim2.fromOffset(40, 40),
			Radius = 12,
			StrokeThickness = 1.5,
		})
	elseif rank == 3 then
		return studdedIcon(parent, ASSETS.BronzeTrophy, {
			Size = UDim2.fromOffset(40, 40),
			Radius = 12,
			StrokeThickness = 1.5,
		})
	end

	local frame = create("Frame", parent, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(40, 40),
	})

	local label = create("TextLabel", frame, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = "#" .. tostring(rank),
		TextColor3 = PALET.Muted,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	return frame, label
end

local function logoText(parent, text, options)
	options = options or {}

	local holder = create("Frame", parent, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = options.Size or UDim2.new(1, 0, 0, 64),
		ZIndex = options.ZIndex or 4,
	})

	local outer = create("TextLabel", holder, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		Font = Enum.Font.GothamBlack,
		Text = text or "",
		TextColor3 = PALET.CreamLight,
		TextSize = options.TextSize or 36,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeTransparency = 1,
		ZIndex = holder.ZIndex + 1,
	})

	local outerStroke = stroke(
		outer,
		options.AccentColor or PALET.Cream,
		5,
		0
	)

	pcall(function()
		outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	end)

	local inner = create("TextLabel", holder, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		Font = Enum.Font.GothamBlack,
		Text = text or "",
		TextColor3 = PALET.CreamLight,
		TextSize = options.TextSize or 36,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeTransparency = 1,
		ZIndex = holder.ZIndex + 2,
	})

	stroke(inner, PALET.Dark, 1, 0.05)

	return holder
end

local function studRow(parent, options)
	options = options or {}

	local row = create("Frame", parent, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = options.Size or UDim2.new(1, -32, 0, 12),
		Position = options.Position or UDim2.fromOffset(16, 10),
		ZIndex = options.ZIndex or 4,
	})

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = row

	for _ = 1, 8 do
		local dot = create("Frame", row, {
			BackgroundColor3 = PALET.Dark,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(8, 8),
		})
		corner(dot, 8)
	end

	return row
end

-- ============================================================================
-- 05) SCREEN GUI / ROOT / BACKDROP
-- ============================================================================

local oldGui = PlayerGui:FindFirstChild("GAME_UI")
if oldGui then
	pcall(function()
		oldGui:Destroy()
	end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GAME_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = false
ScreenGui.Parent = PlayerGui

local Root = Instance.new("Frame")
Root.Name = "Root"
Root.BackgroundTransparency = 1
Root.BorderSizePixel = 0
Root.Size = UDim2.fromScale(1, 1)
Root.Position = UDim2.fromScale(0, 0)
Root.ZIndex = 1
Root.Parent = ScreenGui

local RootScale = Instance.new("UIScale")
RootScale.Scale = 1
RootScale.Parent = Root

local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.BackgroundColor3 = PALET.Dark
Backdrop.BackgroundTransparency = 0.45
Backdrop.BorderSizePixel = 0
Backdrop.Size = UDim2.fromScale(1, 1)
Backdrop.Position = UDim2.fromScale(0, 0)
Backdrop.Visible = false
Backdrop.ZIndex = 1
Backdrop.Parent = ScreenGui

local ScreenLayer = Instance.new("Frame")
ScreenLayer.Name = "ScreenLayer"
ScreenLayer.BackgroundTransparency = 1
ScreenLayer.BorderSizePixel = 0
ScreenLayer.Size = UDim2.fromScale(1, 1)
ScreenLayer.Position = UDim2.fromScale(0, 0)
ScreenLayer.ZIndex = 2
ScreenLayer.Parent = ScreenGui

local ToastLayer = Instance.new("Frame")
ToastLayer.Name = "ToastLayer"
ToastLayer.BackgroundTransparency = 1
ToastLayer.BorderSizePixel = 0
ToastLayer.Size = UDim2.fromScale(1, 1)
ToastLayer.Position = UDim2.fromScale(0, 0)
ToastLayer.ZIndex = 100
ToastLayer.Parent = ScreenGui

local ALL_PANELS = {}

local function registerPanel(name, object)
	ALL_PANELS[name] = object
	return object
end

local function hideAll()
	for _, panelObject in pairs(ALL_PANELS) do
		pcall(function()
			panelObject.Visible = false
		end)
	end
	Backdrop.Visible = false
end

local function showPanel(panelObject, isModal)
	if not panelObject then
		return
	end

	if isModal then
		hideAll()
		Backdrop.Visible = true
	else
		hideAll()
		Backdrop.Visible = false
	end

	local basePos = panelObject:GetAttribute("BasePos")
	if typeof(basePos) ~= "UDim2" then
		basePos = panelObject.Position
		pcall(function()
			panelObject:SetAttribute("BasePos", basePos)
		end)
	end

	panelObject.Visible = true
	panelObject.Position = offsetPosition(basePos, 0, 30)

	tween(
		panelObject,
		0.22,
		{Position = basePos},
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	if panelObject ~= LoadingPanel then
		playSfx("Snd_Open")
	end
end

-- ============================================================================
-- 06) PANEL SİZE / MOBİL SCALE
-- ============================================================================

local PANEL_SPECS = {}

local function configurePanelBounds(panelObject, width, height)
	PANEL_SPECS[panelObject] = {
		width = width,
		height = height,
	}
end

local function updateViewportScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local size = camera.ViewportSize
	local safeWidth = math.max(280, size.X - 40)
	local safeHeight = math.max(220, size.Y - 40)

	-- Mobil portrait/landscape için tek bir ortak UIScale kullanılır.
	-- Alt sınır 0.72 ile Gotham metinleri aşırı küçülmez.
	local scale = math.clamp(
		math.min(safeWidth / 820, safeHeight / 760),
		0.72,
		1
	)

	if IS_MOBILE then
		scale = math.min(scale, 0.92)
	end

	RootScale.Scale = scale

	for panelObject, spec in pairs(PANEL_SPECS) do
		local width = math.min(spec.width, safeWidth / math.max(scale, 0.01))
		local height = math.min(spec.height, safeHeight / math.max(scale, 0.01))

		pcall(function()
			panelObject.Size = UDim2.fromOffset(width, height)
		end)
	end
end

local function bindViewport()
	task.spawn(function()
		local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera", 10)
		if not camera then
			return
		end

		updateViewportScale()

		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			updateViewportScale()
		end)
	end)
end

-- ============================================================================
-- 07) PANEL OLUŞTURMA HELPERLARI
-- ============================================================================

local function createCenteredPanel(name, width, height, isOrange)
	local p

	if isOrange then
		p = studdedPanel(ScreenLayer, {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, height),
			ZIndex = 3,
			Radius = 22,
			StrokeThickness = 3,
		})
	else
		p = panel(ScreenLayer, {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, height),
			ZIndex = 3,
			Radius = 22,
			StrokeThickness = 2.5,
		})
	end

	p:SetAttribute("BasePos", p.Position)
	p.Visible = false
	registerPanel(name, p)
	configurePanelBounds(p, width, height)

	return p
end

local LoadingPanel
local WelcomePanel
local MainMenuPanel
local GameSelectPanel
local LeaderboardPanel
local StatsPanel
local SettingsPanel
local GameOverPanel

-- ============================================================================
-- 08) LOADING
-- ============================================================================

LoadingPanel = createCenteredPanel("Loading", 520, 300, false)

logoText(LoadingPanel, "GAME HUB", {
	Size = UDim2.new(1, -48, 0, 68),
	Position = UDim2.fromOffset(24, 36),
	TextSize = 40,
})

local loadingTrack = panel(LoadingPanel, {
	Name = "ProgressTrack",
	Position = UDim2.fromOffset(50, 142),
	Size = UDim2.new(1, -100, 0, 26),
	Radius = 12,
	StrokeThickness = 1.5,
	ZIndex = 4,
})

local loadingFill = studdedPanel(loadingTrack, {
	Name = "ProgressFill",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(0, 0, 1, 0),
	Radius = 12,
	StrokeThickness = 1,
	ZIndex = 5,
})

local loadingLabel = create("TextLabel", LoadingPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(40, 190),
	Size = UDim2.new(1, -80, 0, 28),
	Font = Enum.Font.GothamMedium,
	Text = "Loading games...",
	TextColor3 = PALET.Muted,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 5,
})

local loadingStatus = create("TextLabel", LoadingPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(40, 222),
	Size = UDim2.new(1, -80, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "PREPARING UI",
	TextColor3 = PALET.Orange,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 5,
})

-- ============================================================================
-- 09) WELCOME
-- ============================================================================

WelcomePanel = createCenteredPanel("Welcome", 660, 560, false)

logoText(WelcomePanel, "WELCOME!", {
	Position = UDim2.fromOffset(24, 30),
	Size = UDim2.new(1, -48, 0, 68),
	TextSize = 42,
})

local welcomeText = create("TextLabel", WelcomePanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(56, 120),
	Size = UDim2.new(1, -112, 0, 250),
	Font = Enum.Font.GothamMedium,
	Text = table.concat({
		"GAME HUB'e hoş geldin!",
		"Burada kısa, hızlı ve rekabetçi mini oyunlara",
		"tek bir premium arayüzden ulaşabilirsin.",
		"",
		"PLAY ile oyun seç, LEADERBOARD ile sıralamanı gör.",
		"STATS ve SETTINGS ile hesabını ve deneyimini yönet.",
	}, "\n"),
	TextColor3 = PALET.TextDark,
	TextSize = 17,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 4,
})

local welcomeDivider = create("Frame", WelcomePanel, {
	BackgroundColor3 = PALET.Cream,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -110, 0, 386),
	Size = UDim2.fromOffset(220, 2),
	ZIndex = 4,
})
corner(welcomeDivider, 2)

local welcomePlay = attachButtonFx(button(WelcomePanel, "LET'S PLAY", {
	Size = UDim2.fromOffset(330, 60),
	Icon = ASSETS.Icon_Play,
	ZIndex = 4,
}))
welcomePlay.Position = UDim2.new(0.5, -165, 1, -94)

-- ============================================================================
-- 10) MAIN MENU
-- ============================================================================

MainMenuPanel = createCenteredPanel("MainMenu", 640, 690, false)

local mainHeader = studdedPanel(MainMenuPanel, {
	Name = "MainHeader",
	Position = UDim2.fromOffset(22, 20),
	Size = UDim2.new(1, -44, 0, 160),
	Radius = 22,
	StrokeThickness = 3,
	ZIndex = 4,
})

logoText(mainHeader, "GAME HUB", {
	Position = UDim2.fromOffset(18, 22),
	Size = UDim2.new(1, -36, 0, 64),
	TextSize = 40,
	ZIndex = 6,
})

local tagline = create("TextLabel", mainHeader, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(22, 90),
	Size = UDim2.new(1, -44, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "PLAY • COMPETE • HAVE FUN",
	TextColor3 = PALET.CreamLight,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 6,
})

studRow(mainHeader, {
	Position = UDim2.new(0, 18, 1, -22),
	Size = UDim2.new(1, -36, 0, 12),
	ZIndex = 6,
})

local menuList = create("Frame", MainMenuPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(86, 212),
	Size = UDim2.new(1, -172, 0, 360),
	ZIndex = 4,
})

local menuLayout = Instance.new("UIListLayout")
menuLayout.FillDirection = Enum.FillDirection.Vertical
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
menuLayout.Padding = UDim.new(0, 14)
menuLayout.Parent = menuList

local playButton = attachButtonFx(button(menuList, "PLAY", {
	Size = UDim2.new(1, 0, 0, 60),
	Icon = ASSETS.Icon_Play,
	ZIndex = 5,
}))

local leaderboardButton = attachButtonFx(button(menuList, "LEADERBOARD", {
	Size = UDim2.new(1, 0, 0, 60),
	Icon = ASSETS.Icon_Leaderboard,
	FillTop = PALET.Dark,
	FillBottom = PALET.DarkSoft,
	TextColor = PALET.CreamLight,
	ZIndex = 5,
}))

local statsButton = attachButtonFx(button(menuList, "STATS", {
	Size = UDim2.new(1, 0, 0, 60),
	Icon = ASSETS.Icon_Stats,
	FillTop = PALET.DarkSoft,
	FillBottom = PALET.Dark,
	TextColor = PALET.CreamLight,
	ZIndex = 5,
}))

local settingsButton = attachButtonFx(button(menuList, "SETTINGS", {
	Size = UDim2.new(1, 0, 0, 60),
	Icon = ASSETS.Icon_Settings,
	FillTop = PALET.Panel,
	FillBottom = PALET.PanelStud,
	TextColor = PALET.TextDark,
	StrokeColor = PALET.Cream,
	ZIndex = 5,
}))

-- ============================================================================
-- 11) GAME SELECT
-- ============================================================================

GameSelectPanel = createCenteredPanel("GameSelect", 820, 720, false)

logoText(GameSelectPanel, "CHOOSE A GAME", {
	Position = UDim2.fromOffset(22, 22),
	Size = UDim2.new(1, -44, 0, 64),
	TextSize = 36,
})

local gameScroll = create("ScrollingFrame", GameSelectPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(24, 98),
	Size = UDim2.new(1, -48, 1, -180),
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = PALET.Orange,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 4,
})

local gameGrid = Instance.new("UIGridLayout")
gameGrid.CellSize = UDim2.fromOffset(230, 220)
gameGrid.CellPadding = UDim2.fromOffset(14, 14)
gameGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
gameGrid.SortOrder = Enum.SortOrder.LayoutOrder
gameGrid.Parent = gameScroll

local function updateGameCanvas()
	gameScroll.CanvasSize = UDim2.fromOffset(
		0,
		math.max(0, gameGrid.AbsoluteContentSize.Y + 8)
	)
end

gameGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateGameCanvas)

local gameButtons = {}

for index, gameInfo in ipairs(GAMES) do
	local cell = create("Frame", gameScroll, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(230, 220),
		LayoutOrder = index,
		ZIndex = 4,
	})

	local card = panel(cell, {
		Name = "Card",
		BackgroundColor3 = PALET.Panel,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(230, 220),
		Radius = 20,
		StrokeThickness = 2,
		ZIndex = 5,
	})

	local gameIcon = studdedIcon(card, ASSETS[gameInfo.IconKey], {
		Size = UDim2.fromOffset(82, 82),
		Radius = 18,
		StrokeThickness = 2,
		ZIndex = 6,
	})
	gameIcon.Position = UDim2.new(0.5, -41, 0, 14)

	local gameName = create("TextLabel", card, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 104),
		Size = UDim2.new(1, -20, 0, 28),
		Font = Enum.Font.GothamBlack,
		Text = gameInfo.Name,
		TextColor3 = PALET.TextDark,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
	})

	local gameDescription = create("TextLabel", card, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 132),
		Size = UDim2.new(1, -24, 0, 42),
		Font = Enum.Font.GothamMedium,
		Text = gameInfo.Description,
		TextColor3 = PALET.Muted,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 7,
	})

	local cardPlay = attachButtonFx(button(card, "PLAY", {
		Size = UDim2.new(1, -28, 0, 46),
		Icon = ASSETS.Icon_Play,
		ZIndex = 7,
	}))
	cardPlay.Position = UDim2.fromOffset(14, 163)

	cardPlay.Activated:Connect(function()
		local remote = _G.GAME_UI_REMOTES and _G.GAME_UI_REMOTES.StartGame
		if remote and remote:IsA("RemoteEvent") then
			pcall(function()
				remote:FireServer(gameInfo.Id)
			end)
		else
			-- Server yoksa UI kırılmaz; kullanıcıya sessiz ve görsel bir durum mesajı gösterilir.
			task.spawn(function()
				local toast = studdedPanel(ToastLayer, {
					Name = "ServerToast",
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, -90),
					Size = UDim2.fromOffset(420, 66),
					Radius = 18,
					StrokeThickness = 2.5,
					ZIndex = 110,
				})
				create("TextLabel", toast, {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBold,
					Text = "SERVER BAĞLANTISI BEKLENİYOR",
					TextColor3 = PALET.CreamLight,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 114,
				})
				tween(toast, 0.35, {
					Position = UDim2.new(0.5, 0, 0, 20),
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				task.wait(2.2)
				tween(toast, 0.30, {
					Position = UDim2.new(0.5, 0, 0, -90),
				})
				task.wait(0.35)
				pcall(function()
					toast:Destroy()
				end)
			end)
		end
	end)

	table.insert(gameButtons, {
		Cell = cell,
		Card = card,
		BasePosition = card.Position,
	})
end

for _, item in ipairs(gameButtons) do
	task.spawn(function()
		while item.Card and item.Card.Parent do
			local up = tween(
				item.Card,
				1.0,
				{Position = offsetPosition(item.BasePosition, 0, -3)},
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			)
			if up then
				up.Completed:Wait()
			end

			local down = tween(
				item.Card,
				1.0,
				{Position = item.BasePosition},
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			)
			if down then
				down.Completed:Wait()
			end

			task.wait(0.02)
		end
	end)
end

local gameBack = attachButtonFx(outlineButton(GameSelectPanel, "BACK", {
	Size = UDim2.fromOffset(230, 52),
	Icon = ASSETS.Icon_Back,
	ZIndex = 6,
}))
gameBack.Position = UDim2.new(0.5, -115, 1, -78)

-- ============================================================================
-- 12) LEADERBOARD
-- ============================================================================

LeaderboardPanel = createCenteredPanel("Leaderboard", 680, 720, false)

logoText(LeaderboardPanel, "GLOBAL LEADERBOARD", {
	Position = UDim2.fromOffset(20, 20),
	Size = UDim2.new(1, -40, 0, 64),
	TextSize = 32,
})

local leaderboardList = create("ScrollingFrame", LeaderboardPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(24, 94),
	Size = UDim2.new(1, -48, 0, 438),
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = PALET.Orange,
	ZIndex = 4,
})

local leaderboardLayout = Instance.new("UIListLayout")
leaderboardLayout.FillDirection = Enum.FillDirection.Vertical
leaderboardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
leaderboardLayout.Padding = UDim.new(0, 6)
leaderboardLayout.Parent = leaderboardList

leaderboardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	leaderboardList.CanvasSize = UDim2.fromOffset(0, leaderboardLayout.AbsoluteContentSize.Y + 6)
end)

local leaderboardBottom = panel(LeaderboardPanel, {
	Name = "YourStats",
	Position = UDim2.fromOffset(24, 548),
	Size = UDim2.new(1, -48, 0, 86),
	Radius = 18,
	StrokeThickness = 2,
	ZIndex = 4,
})

local yourRank = create("TextLabel", leaderboardBottom, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 10),
	Size = UDim2.new(0.5, -24, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Your Rank: #--",
	TextColor3 = PALET.TextDark,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
})

local yourScore = create("TextLabel", leaderboardBottom, {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 6, 0, 10),
	Size = UDim2.new(0.5, -24, 0, 28),
	Font = Enum.Font.GothamBlack,
	Text = "Your Score: 0",
	TextColor3 = PALET.Orange,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 6,
})

local leaderboardClose = attachButtonFx(outlineButton(LeaderboardPanel, "CLOSE", {
	Size = UDim2.fromOffset(210, 52),
	Icon = ASSETS.Icon_Close,
	ZIndex = 6,
}))
leaderboardClose.Position = UDim2.new(0.5, -105, 1, -70)

local function clearChildrenExceptLayout(container)
	for _, child in ipairs(container:GetChildren()) do
		if child ~= leaderboardLayout then
			pcall(function()
				child:Destroy()
			end)
		end
	end
end

local function renderLeaderboard(data)
	local entries = {}
	local payload = data

	if type(payload) == "table" then
		if type(payload.leaderboard) == "table" then
			entries = payload.leaderboard
		elseif type(payload.players) == "table" then
			entries = payload.players
		elseif type(payload.entries) == "table" then
			entries = payload.entries
		elseif #payload > 0 then
			entries = payload
		end
	end

	clearChildrenExceptLayout(leaderboardList)

	for rank = 1, 10 do
		local item = entries[rank] or {}

		local row = panel(leaderboardList, {
			Name = "Row_" .. tostring(rank),
			Size = UDim2.new(1, 0, 0, 50),
			Radius = 16,
			StrokeThickness = 1.8,
			ZIndex = 5,
		})
		row.LayoutOrder = rank

		trophyIcon(row, rank).Position = UDim2.fromOffset(8, 5)

		local nameText = item.name
			or item.username
			or item.displayName
			or item.DisplayName
			or ("PLAYER " .. tostring(rank))

		local score = item.score
			or item.value
			or item.points
			or 0

		create("TextLabel", row, {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(58, 0),
			Size = UDim2.new(0.55, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = tostring(nameText),
			TextColor3 = PALET.TextDark,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 7,
		})

		create("TextLabel", row, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.64, 0, 0, 0),
			Size = UDim2.new(0.34, -10, 1, 0),
			Font = Enum.Font.GothamBlack,
			Text = formatNumber(score),
			TextColor3 = PALET.Orange,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 7,
		})
	end

	local playerRank = payload and (payload.yourRank or payload.rank or payload.playerRank)
	local playerScore = payload and (payload.yourScore or payload.playerScore or payload.score)
	if type(payload) == "table" and type(payload.player) == "table" then
		playerRank = playerRank or payload.player.rank
		playerScore = playerScore or payload.player.score
	end

	yourRank.Text = "Your Rank: #" .. tostring(playerRank or "--")
	yourScore.Text = "Your Score: " .. formatNumber(playerScore or 0)
end

-- ============================================================================
-- 13) STATS
-- ============================================================================

StatsPanel = createCenteredPanel("Stats", 620, 620, false)

logoText(StatsPanel, "STATS", {
	Position = UDim2.fromOffset(20, 20),
	Size = UDim2.new(1, -40, 0, 64),
	TextSize = 36,
})

local statsList = create("Frame", StatsPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(30, 104),
	Size = UDim2.new(1, -60, 0, 390),
	ZIndex = 4,
})

local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Vertical
statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsLayout.Padding = UDim.new(0, 8)
statsLayout.Parent = statsList

local STAT_DEFS = {
	{Key = "TotalScore", Label = "Total Score"},
	{Key = "BestScore", Label = "Best Score"},
	{Key = "GamesPlayed", Label = "Games Played"},
	{Key = "GamesWon", Label = "Games Won"},
	{Key = "CurrentStreak", Label = "Current Streak"},
}

local statsValues = {}

for _, def in ipairs(STAT_DEFS) do
	local row = panel(statsList, {
		Name = def.Key,
		Size = UDim2.new(1, 0, 0, 62),
		Radius = 16,
		StrokeThickness = 1.8,
		ZIndex = 5,
	})

	create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(0.58, -18, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = def.Label,
		TextColor3 = PALET.TextDark,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})

	local valueLabel = create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.58, 0, 0, 0),
		Size = UDim2.new(0.42, -18, 1, 0),
		Font = Enum.Font.GothamBlack,
		Text = "0",
		TextColor3 = PALET.Orange,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 7,
	})

	statsValues[def.Key] = valueLabel
end

local statsClose = attachButtonFx(outlineButton(StatsPanel, "CLOSE", {
	Size = UDim2.fromOffset(210, 52),
	Icon = ASSETS.Icon_Close,
	ZIndex = 6,
}))
statsClose.Position = UDim2.new(0.5, -105, 1, -70)

local function renderStats(data)
	local source = data or {}

	if type(source.stats) == "table" then
		source = source.stats
	end

	for _, def in ipairs(STAT_DEFS) do
		local value = source[def.Key]
			or source[string.lower(def.Key)]
			or 0

		statsValues[def.Key].Text = formatNumber(value)
	end
end

-- ============================================================================
-- 14) SETTINGS
-- ============================================================================

SettingsPanel = createCenteredPanel("Settings", 620, 560, false)

logoText(SettingsPanel, "SETTINGS", {
	Position = UDim2.fromOffset(20, 20),
	Size = UDim2.new(1, -40, 0, 64),
	TextSize = 36,
})

local settingsList = create("Frame", SettingsPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(30, 120),
	Size = UDim2.new(1, -60, 0, 220),
	ZIndex = 4,
})

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.Parent = settingsList

local function createToggleRow(labelText, initialState, stateSetter)
	local row = panel(settingsList, {
		Name = labelText .. "Row",
		Size = UDim2.new(1, 0, 0, 86),
		Radius = 18,
		StrokeThickness = 2,
		ZIndex = 5,
	})

	create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -146, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = labelText,
		TextColor3 = PALET.TextDark,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})

	local hitbox = create("TextButton", row, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -112, 0.5, 0),
		Size = UDim2.fromOffset(100, 56),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	})

	local toggle = create("ImageButton", hitbox, {
		BackgroundColor3 = initialState and PALET.Success or PALET.Muted,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(90, 46),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = initialState and ("rbxassetid://" .. ASSETS.Sound_On) or ("rbxassetid://" .. ASSETS.Sound_Off),
		ImageColor3 = PALET.CreamLight,
		AutoButtonColor = false,
		Active = false,
		Selectable = false,
		ZIndex = 9,
	})

	corner(toggle, 23)
	stroke(toggle, PALET.CreamLight, 2)
	addStudOverlay(toggle, 0.84)

	local onState = initialState

	local function renderToggle()
		safeSet(toggle, "BackgroundColor3", onState and PALET.Success or PALET.Muted)
		safeSet(toggle, "Image", onState and ("rbxassetid://" .. ASSETS.Sound_On) or ("rbxassetid://" .. ASSETS.Sound_Off))
	end

	hitbox.Activated:Connect(function()
		onState = not onState
		renderToggle()
		stateSetter(onState)
		playSfx("Snd_Click")
	end)

	return row, toggle, function()
		return onState
	end
end

createToggleRow("Music", musicOn, function(state)
	musicOn = state
	if musicOn then
		playMusic()
	else
		stopMusic()
	end
end)

createToggleRow("SFX", sfxOn, function(state)
	sfxOn = state
end)

local settingsClose = attachButtonFx(outlineButton(SettingsPanel, "CLOSE", {
	Size = UDim2.fromOffset(210, 52),
	Icon = ASSETS.Icon_Close,
	ZIndex = 6,
}))
settingsClose.Position = UDim2.new(0.5, -105, 1, -70)

-- ============================================================================
-- 15) GAME OVER
-- ============================================================================

GameOverPanel = createCenteredPanel("GameOver", 560, 560, false)

local gameOverTitle = logoText(GameOverPanel, "GAME OVER", {
	Position = UDim2.fromOffset(20, 30),
	Size = UDim2.new(1, -40, 0, 70),
	TextSize = 38,
	AccentColor = PALET.Danger,
})

local gameOverScore = create("TextLabel", GameOverPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(30, 122),
	Size = UDim2.new(1, -60, 0, 78),
	Font = Enum.Font.GothamBlack,
	Text = "0",
	TextColor3 = PALET.TextDark,
	TextSize = 52,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 6,
})

local gameOverAward = create("TextLabel", GameOverPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(30, 212),
	Size = UDim2.new(1, -60, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = "+0 TOTAL SCORE",
	TextColor3 = PALET.Success,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 6,
})

local resultDivider = create("Frame", GameOverPanel, {
	BackgroundColor3 = PALET.Cream,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -100, 0, 266),
	Size = UDim2.fromOffset(200, 2),
	ZIndex = 5,
})
corner(resultDivider, 2)

local playAgain = attachButtonFx(button(GameOverPanel, "PLAY AGAIN", {
	Size = UDim2.fromOffset(300, 58),
	Icon = ASSETS.Icon_Play,
	ZIndex = 6,
}))
playAgain.Position = UDim2.new(0.5, -150, 0, 304)

local backToHub = attachButtonFx(outlineButton(GameOverPanel, "BACK TO HUB", {
	Size = UDim2.fromOffset(300, 56),
	Icon = ASSETS.Icon_Back,
	ZIndex = 6,
}))
backToHub.Position = UDim2.new(0.5, -150, 0, 374)

-- ============================================================================
-- 16) DATA / REMOTE NORMALIZATION
-- ============================================================================

_G.GAME_UI_REMOTES = _G.GAME_UI_REMOTES or {}

local function getFirstJoinFromPayload(payload)
	if type(payload) ~= "table" then
		return nil
	end

	if payload.firstJoin ~= nil then
		return payload.firstJoin
	end

	if payload.FirstJoin ~= nil then
		return payload.FirstJoin
	end

	if payload.isFirstJoin ~= nil then
		return payload.isFirstJoin
	end

	if payload.newPlayer ~= nil then
		return payload.newPlayer
	end

	return nil
end

local function requestPlayerData()
	local remote = _G.GAME_UI_REMOTES.RequestPlayerData

	if not remote or not remote:IsA("RemoteFunction") then
		return nil, true
	end

	local ok, data = pcall(function()
		return remote:InvokeServer()
	end)

	if not ok then
		return nil, true
	end

	renderStats(data)

	local firstJoin = getFirstJoinFromPayload(data)

	if firstJoin == nil then
		firstJoin = true
	end

	return data, firstJoin
end

local function requestLeaderboard()
	local remote = _G.GAME_UI_REMOTES.RequestLeaderboard

	if not remote or not remote:IsA("RemoteFunction") then
		renderLeaderboard({})
		return
	end

	local ok, data = pcall(function()
		return remote:InvokeServer()
	end)

	if ok then
		renderLeaderboard(data)
	else
		renderLeaderboard({})
	end
end

-- ============================================================================
-- 17) GAME OVER PAYLOAD / RENDER
-- ============================================================================

local scoreAnimationToken = 0

local function showGameOver(payload)
	payload = type(payload) == "table" and payload or {}

	local victory = payload.victory
	if victory == nil then
		victory = payload.won
	end
	if victory == nil then
		victory = payload.success
	end
	if victory == nil then
		victory = false
	end

	local scoreTarget = tonumber(
		payload.scoreTarget
		or payload.target
		or payload.goal
		or payload.score
		or 0
	) or 0

	local totalScore = tonumber(
		payload.totalScore
		or payload.addedScore
		or payload.scoreDelta
		or payload.award
		or 0
	) or 0

	scoreAnimationToken += 1
	local localToken = scoreAnimationToken

	if victory then
		gameOverTitle:Destroy()
		gameOverTitle = logoText(GameOverPanel, "VICTORY!", {
			Position = UDim2.fromOffset(20, 30),
			Size = UDim2.new(1, -40, 0, 70),
			TextSize = 38,
			AccentColor = PALET.Success,
		})
	else
		gameOverTitle:Destroy()
		gameOverTitle = logoText(GameOverPanel, "GAME OVER", {
			Position = UDim2.fromOffset(20, 30),
			Size = UDim2.new(1, -40, 0, 70),
			TextSize = 38,
			AccentColor = PALET.Danger,
		})
	end

	gameOverAward.Text = "+" .. formatNumber(totalScore) .. " TOTAL SCORE"

	showPanel(GameOverPanel, true)

	gameOverScore.Text = "0"

	local startTime = os.clock()
	local duration = 0.8

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if localToken ~= scoreAnimationToken then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - startTime
		local t = math.clamp(elapsed / duration, 0, 1)
		local easeOutCubic = 1 - math.pow(1 - t, 3)
		local current = math.floor(scoreTarget * easeOutCubic + 0.5)

		gameOverScore.Text = formatNumber(current)

		if t >= 1 then
			gameOverScore.Text = formatNumber(scoreTarget)
			connection:Disconnect()
		end
	end)
end

-- ============================================================================
-- 18) BUTTON EVENTLERİ
-- ============================================================================

local function showMainMenu()
	showPanel(MainMenuPanel, false)
end

welcomePlay.Activated:Connect(function()
	showMainMenu()
end)

playButton.Activated:Connect(function()
	showPanel(GameSelectPanel, true)
end)

leaderboardButton.Activated:Connect(function()
	showPanel(LeaderboardPanel, true)
	task.spawn(requestLeaderboard)
end)

statsButton.Activated:Connect(function()
	showPanel(StatsPanel, true)
	task.spawn(requestPlayerData)
end)

settingsButton.Activated:Connect(function()
	showPanel(SettingsPanel, true)
end)

gameBack.Activated:Connect(function()
	playSfx("Snd_Back")
	showMainMenu()
end)

leaderboardClose.Activated:Connect(function()
	playSfx("Snd_Back")
	showMainMenu()
end)

statsClose.Activated:Connect(function()
	playSfx("Snd_Back")
	showMainMenu()
end)

settingsClose.Activated:Connect(function()
	playSfx("Snd_Back")
	showMainMenu()
end)

playAgain.Activated:Connect(function()
	showPanel(GameSelectPanel, true)
end)

backToHub.Activated:Connect(function()
	playSfx("Snd_Back")

	local remote = _G.GAME_UI_REMOTES.ReturnToHub
	if remote and remote:IsA("RemoteEvent") then
		pcall(function()
			remote:FireServer()
		end)
	end

	showMainMenu()
end)

-- ============================================================================
-- 19) ACHIEVEMENT TOAST
-- ============================================================================

local toastQueue = {}
local toastRunning = false

local function queueAchievement(achievement)
	local textValue

	if type(achievement) == "table" then
		textValue = achievement.title
			or achievement.name
			or achievement.Name
			or achievement.id
			or achievement.Id
			or "Achievement Unlocked"
	else
		textValue = tostring(achievement or "Achievement Unlocked")
	end

	table.insert(toastQueue, textValue)

	if toastRunning then
		return
	end

	toastRunning = true

	task.spawn(function()
		while #toastQueue > 0 do
			local message = table.remove(toastQueue, 1)

			local toast = studdedPanel(ToastLayer, {
				Name = "AchievementToast",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, -90),
				Size = UDim2.fromOffset(460, 78),
				Radius = 20,
				StrokeThickness = 3,
				ZIndex = 120,
			})

			create("TextLabel", toast, {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 10),
				Size = UDim2.new(1, -36, 0, 22),
				Font = Enum.Font.GothamBlack,
				Text = "ACHIEVEMENT UNLOCKED",
				TextColor3 = PALET.CreamLight,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 125,
			})

			create("TextLabel", toast, {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 35),
				Size = UDim2.new(1, -36, 0, 24),
				Font = Enum.Font.GothamBold,
				Text = tostring(message),
				TextColor3 = PALET.CreamLight,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 125,
			})

			tween(
				toast,
				0.35,
				{Position = UDim2.new(0.5, 0, 0, 20)},
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			)

			task.wait(3)

			tween(
				toast,
				0.30,
				{Position = UDim2.new(0.5, 0, 0, -90)},
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)

			task.wait(0.35)

			pcall(function()
				toast:Destroy()
			end)
		end

		toastRunning = false
	end)
end

-- ============================================================================
-- 20) SERVER REMOTE DİNLEYİCİLERİ
-- ============================================================================

local function waitRemote(name, className)
	local ok, remote = pcall(function()
		return ReplicatedStorage:WaitForChild(name, 30)
	end)

	if not ok or not remote then
		return nil
	end

	local valid = false
	pcall(function()
		valid = remote:IsA(className)
	end)

	if not valid then
		return nil
	end

	return remote
end

task.spawn(function()
	local remote = waitRemote("GameStateChanged", "RemoteEvent")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.GameStateChanged = remote

	remote.OnClientEvent:Connect(function(state, payload)
		if state == "starting" then
			hideAll()
		elseif state == "finished" then
			showGameOver(payload)
			playSfx("Snd_Start")
		elseif state == "hub" then
			showMainMenu()
		end
	end)
end)

task.spawn(function()
	local remote = waitRemote("AchievementUnlocked", "RemoteEvent")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.AchievementUnlocked = remote

	remote.OnClientEvent:Connect(function(achievement)
		queueAchievement(achievement)
	end)
end)

task.spawn(function()
	local remote = waitRemote("StartGame", "RemoteEvent")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.StartGame = remote
end)

task.spawn(function()
	local remote = waitRemote("ReturnToHub", "RemoteEvent")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.ReturnToHub = remote
end)

task.spawn(function()
	local remote = waitRemote("RequestLeaderboard", "RemoteFunction")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.RequestLeaderboard = remote
end)

task.spawn(function()
	local remote = waitRemote("RequestPlayerData", "RemoteFunction")

	if not remote then
		return
	end

	_G.GAME_UI_REMOTES.RequestPlayerData = remote
end)

-- ============================================================================
-- 21) LOADING AKIŞI
-- ============================================================================

local function resetLoading()
	loadingFill.Size = UDim2.new(0, 0, 1, 0)
	loadingStatus.Text = "PREPARING UI"
end

local function runLoading()
	resetLoading()
	showPanel(LoadingPanel, false)

	local progressTween = tween(
		loadingFill,
		1.8,
		{Size = UDim2.new(1, 0, 1, 0)},
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	if progressTween then
		task.spawn(function()
			local statusList = {
				"PREPARING UI",
				"LOADING ASSETS",
				"BUILDING PANELS",
				"READY",
			}

			for _, status in ipairs(statusList) do
				loadingStatus.Text = status
				task.wait(0.42)
			end
		end)
	end

	task.wait(2.2)

	tween(LoadingPanel, 0.22, {
		Position = offsetPosition(LoadingPanel:GetAttribute("BasePos"), 0, -16),
		BackgroundTransparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	task.wait(0.25)
	hideAll()

	-- Paneli sonraki açılışa hazırla.
	local basePos = LoadingPanel:GetAttribute("BasePos")
	safeSet(LoadingPanel, "Position", basePos)
	safeSet(LoadingPanel, "BackgroundTransparency", 0)
end

-- ============================================================================
-- 22) BOOT / FIRST JOIN
-- ============================================================================

bindViewport()
updateViewportScale()

task.spawn(function()
	runLoading()

	local _, firstJoin = requestPlayerData()

	playMusic()

	if firstJoin then
		showPanel(WelcomePanel, true)
	else
		showMainMenu()
	end
end)