-- ============================================================
-- BSC PRISON | CharacterCreatorUI.lua
-- StarterPlayerScripts > CharacterCreatorUI (ModuleScript)
-- Karakter Oluşturma: 3 Adım Wizard + Onay + Loading
-- ============================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Module = {}

-- ─────────────────────────────────────────────
-- RENK PALETİ
-- ─────────────────────────────────────────────
local C = {
	bg        = Color3.fromRGB(6, 6, 10),
	panel     = Color3.fromRGB(14, 14, 20),
	panelAlt  = Color3.fromRGB(18, 18, 26),
	border    = Color3.fromRGB(35, 35, 52),
	accent    = Color3.fromRGB(90, 120, 255),
	accentDk  = Color3.fromRGB(50, 70, 180),
	text      = Color3.fromRGB(220, 220, 235),
	textDim   = Color3.fromRGB(110, 110, 135),
	success   = Color3.fromRGB(60, 200, 120),
	danger    = Color3.fromRGB(220, 60, 60),
	warning   = Color3.fromRGB(220, 160, 60),
	male      = Color3.fromRGB(70, 130, 220),
	female    = Color3.fromRGB(220, 90, 150),
}

-- ─────────────────────────────────────────────
-- CATALOG ID'LERİ (İleride güncellenecek)
-- ─────────────────────────────────────────────
local HAIR_OPTIONS = {
	{name = "Varsayılan",   id = 0},
	{name = "Kısa Düz",     id = 86487700},
	{name = "Uzun Dalgalı", id = 1112458724},
	{name = "Afro",         id = 13062491},
	{name = "Punk",         id = 1235487},
	{name = "Saçsız",       id = 0},
}

local FACE_OPTIONS = {
	{name = "Varsayılan",  id = 0},
	{name = "Mutlu",       id = 1},
	{name = "Ciddi",       id = 2},
	{name = "Sinirli",     id = 3},
	{name = "Üzgün",       id = 4},
}

-- ─────────────────────────────────────────────
-- YARDIMCI FONKSİYONLAR
-- ─────────────────────────────────────────────
local function corner(p, r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p, col, th) local s=Instance.new("UIStroke") s.Color=col or C.border s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function pad(p, px) local u=Instance.new("UIPadding") u.PaddingLeft=UDim.new(0,px) u.PaddingRight=UDim.new(0,px) u.PaddingTop=UDim.new(0,px) u.PaddingBottom=UDim.new(0,px) u.Parent=p return u end
local function tween(obj, info, props) return TweenService:Create(obj, info, props) end

local function makeLabel(parent, text, size, color, font, xAlign, zIndex)
	local l = Instance.new("TextLabel")
	l.Text = text l.TextSize = size or 13 l.TextColor3 = color or C.text
	l.Font = font or Enum.Font.Gotham l.BackgroundTransparency = 1
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Size = UDim2.new(1,0,1,0) l.ZIndex = zIndex or 5 l.TextWrapped = true
	l.Parent = parent return l
end

local function makeInput(parent, placeholder, zIndex)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 42)
	bg.BackgroundColor3 = C.panelAlt
	bg.BorderSizePixel = 0
	bg.ZIndex = zIndex or 5
	bg.Parent = parent
	corner(bg, 8) stroke(bg, C.border, 1)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 1, 0)
	box.Position = UDim2.new(0, 10, 0, 0)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = C.textDim
	box.TextColor3 = C.text
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.ZIndex = (zIndex or 5) + 1
	box.Parent = bg

	box.Focused:Connect(function()
		tween(bg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 35)}):Play()
		stroke(bg, C.accent, 1)
	end)
	box.FocusLost:Connect(function()
		tween(bg, TweenInfo.new(0.15), {BackgroundColor3 = C.panelAlt}):Play()
		stroke(bg, C.border, 1)
	end)

	return bg, box
end

local function makeButton(parent, text, color, zIndex)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 46)
	btn.BackgroundColor3 = color or C.accent
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex or 6
	btn.Parent = parent
	corner(btn, 10)

	btn.MouseEnter:Connect(function()
		tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.new(
			math.min(color.R + 0.08, 1),
			math.min(color.G + 0.08, 1),
			math.min(color.B + 0.08, 1)
		)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or C.accent}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, 0, 0, 42)}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, TweenInfo.new(0.12), {Size = UDim2.new(1, 0, 0, 46)}):Play()
	end)

	return btn
end

-- ─────────────────────────────────────────────
-- VERİ DEPOLAMA
-- ─────────────────────────────────────────────
local CharData = {
	firstName = "",
	lastName  = "",
	age       = 18,
	gender    = "male",  -- "male" | "female"
	hairIndex = 1,
	faceIndex = 1,
}

-- ─────────────────────────────────────────────
-- ANA AÇMA FONKSİYONU
-- ─────────────────────────────────────────────
function Module.Open(playerGui)
	-- ─── SCREENGUI ───
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "BSCCharacterCreator"
	Gui.ResetOnSpawn = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.IgnoreGuiInset = true
	Gui.Parent = playerGui

	-- Tam siyah arka plan
	local BG = Instance.new("Frame")
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = C.bg
	BG.BorderSizePixel = 0
	BG.ZIndex = 1
	BG.Parent = Gui

	-- Sol: Karakter önizleme alanı (siyah oda)
	local PreviewArea = Instance.new("Frame")
	PreviewArea.Name = "PreviewArea"
	PreviewArea.Size = UDim2.new(0.5, 0, 1, 0)
	PreviewArea.Position = UDim2.new(0, 0, 0, 0)
	PreviewArea.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
	PreviewArea.BorderSizePixel = 0
	PreviewArea.ZIndex = 2
	PreviewArea.Parent = BG

	-- Izgara çizgileri (zemin efekti)
	local GridLine = Instance.new("Frame")
	GridLine.Size = UDim2.new(1, 0, 0, 1)
	GridLine.Position = UDim2.new(0, 0, 0.7, 0)
	GridLine.BackgroundColor3 = C.border
	GridLine.BackgroundTransparency = 0.5
	GridLine.BorderSizePixel = 0
	GridLine.ZIndex = 3
	GridLine.Parent = PreviewArea

	-- Karakter görsel placeholder (ViewportFrame yerine ikon)
	local CharPreview = Instance.new("Frame")
	CharPreview.Name = "CharPreview"
	CharPreview.Size = UDim2.new(0, 180, 0, 280)
	CharPreview.Position = UDim2.new(0.5, -90, 0.5, -160)
	CharPreview.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	CharPreview.BorderSizePixel = 0
	CharPreview.ZIndex = 3
	CharPreview.Parent = PreviewArea
	corner(CharPreview, 16)
	stroke(CharPreview, C.border, 1)

	-- Karakter ikonu
	local CharIcon = Instance.new("TextLabel")
	CharIcon.Text = "🧍"
	CharIcon.Size = UDim2.new(1, 0, 0.7, 0)
	CharIcon.Position = UDim2.new(0, 0, 0.05, 0)
	CharIcon.BackgroundTransparency = 1
	CharIcon.TextSize = 80
	CharIcon.Font = Enum.Font.GothamBold
	CharIcon.ZIndex = 4
	CharIcon.Parent = CharPreview

	local GenderLabel = Instance.new("TextLabel")
	GenderLabel.Name = "GenderLabel"
	GenderLabel.Text = "ERKEK"
	GenderLabel.Size = UDim2.new(1, 0, 0, 30)
	GenderLabel.Position = UDim2.new(0, 0, 0.78, 0)
	GenderLabel.BackgroundTransparency = 1
	GenderLabel.TextColor3 = C.male
	GenderLabel.Font = Enum.Font.GothamBold
	GenderLabel.TextSize = 13
	GenderLabel.ZIndex = 4
	GenderLabel.Parent = CharPreview

	-- Önizleme alt etiketi
	local PreviewHint = Instance.new("TextLabel")
	PreviewHint.Text = "KARAKTERİNİZ"
	PreviewHint.Size = UDim2.new(1, 0, 0, 24)
	PreviewHint.Position = UDim2.new(0, 0, 0.92, 0)
	PreviewHint.BackgroundTransparency = 1
	PreviewHint.TextColor3 = C.textDim
	PreviewHint.Font = Enum.Font.GothamBold
	PreviewHint.TextSize = 10
	PreviewHint.ZIndex = 3
	PreviewHint.Parent = PreviewArea

	-- Sol üst logo
	local LogoSmall = Instance.new("TextLabel")
	LogoSmall.Text = "BSC PRISON"
	LogoSmall.Size = UDim2.new(0, 200, 0, 30)
	LogoSmall.Position = UDim2.new(0, 20, 0, 16)
	LogoSmall.BackgroundTransparency = 1
	LogoSmall.TextColor3 = C.accent
	LogoSmall.Font = Enum.Font.GothamBlack
	LogoSmall.TextSize = 16
	LogoSmall.TextXAlignment = Enum.TextXAlignment.Left
	LogoSmall.ZIndex = 4
	LogoSmall.Parent = PreviewArea

	-- Sağ: Form paneli
	local FormPanel = Instance.new("Frame")
	FormPanel.Name = "FormPanel"
	FormPanel.Size = UDim2.new(0.5, 0, 1, 0)
	FormPanel.Position = UDim2.new(0.5, 0, 0, 0)
	FormPanel.BackgroundColor3 = C.panel
	FormPanel.BorderSizePixel = 0
	FormPanel.ZIndex = 2
	FormPanel.Parent = BG

	-- Form içerik konteyneri
	local FormContent = Instance.new("Frame")
	FormContent.Name = "FormContent"
	FormContent.Size = UDim2.new(1, -60, 1, 0)
	FormContent.Position = UDim2.new(0, 30, 0, 0)
	FormContent.BackgroundTransparency = 1
	FormContent.ZIndex = 3
	FormContent.Parent = FormPanel

	-- ─── ADIM GÖSTERGESİ ───
	local StepBar = Instance.new("Frame")
	StepBar.Size = UDim2.new(1, 0, 0, 60)
	StepBar.Position = UDim2.new(0, 0, 0, 20)
	StepBar.BackgroundTransparency = 1
	StepBar.ZIndex = 4
	StepBar.Parent = FormContent

	local stepTitles = {"KİŞİSEL BİLGİLER", "KARAKTER TASARIMI", "ONAY"}
	local stepDots = {}

	for i = 1, 3 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 28, 0, 28)
		dot.Position = UDim2.new((i-1)/3 + 1/6 - 0.05, 0, 0, 0)
		dot.BackgroundColor3 = i == 1 and C.accent or C.border
		dot.BorderSizePixel = 0
		dot.ZIndex = 5
		dot.Parent = StepBar
		corner(dot, 14)

		local numLbl = Instance.new("TextLabel")
		numLbl.Text = tostring(i)
		numLbl.Size = UDim2.new(1, 0, 1, 0)
		numLbl.BackgroundTransparency = 1
		numLbl.TextColor3 = Color3.new(1,1,1)
		numLbl.Font = Enum.Font.GothamBold
		numLbl.TextSize = 13
		numLbl.ZIndex = 6
		numLbl.Parent = dot

		local stepLbl = Instance.new("TextLabel")
		stepLbl.Text = stepTitles[i]
		stepLbl.Size = UDim2.new(0, 120, 0, 20)
		stepLbl.Position = UDim2.new(0.5, -60, 1, 4)
		stepLbl.BackgroundTransparency = 1
		stepLbl.TextColor3 = i == 1 and C.text or C.textDim
		stepLbl.Font = Enum.Font.GothamBold
		stepLbl.TextSize = 9
		stepLbl.ZIndex = 6
		stepLbl.Parent = dot

		stepDots[i] = {dot = dot, lbl = stepLbl}

		-- Bağlantı çizgisi
		if i < 3 then
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1/3 - 0.1, 0, 0, 2)
			line.Position = UDim2.new((i-1)/3 + 1/6 + 0.02, 14, 0, 13)
			line.BackgroundColor3 = C.border
			line.BorderSizePixel = 0
			line.ZIndex = 4
			line.Parent = StepBar
			stepDots[i].line = line
		end
	end

	-- Adım güncelleme fonksiyonu
	local function updateStepBar(currentStep)
		for i, data in ipairs(stepDots) do
			local active = i <= currentStep
			tween(data.dot, TweenInfo.new(0.2), {BackgroundColor3 = active and C.accent or C.border}):Play()
			data.lbl.TextColor3 = active and C.text or C.textDim
			if data.line then
				tween(data.line, TweenInfo.new(0.2), {BackgroundColor3 = i < currentStep and C.accent or C.border}):Play()
			end
		end
	end

	-- ─── SAYFA KONTEYNERLERİ ───
	local pages = {}
	local currentPage = 1

	local function createPage()
		local page = Instance.new("Frame")
		page.Size = UDim2.new(1, 0, 1, -100)
		page.Position = UDim2.new(0, 0, 0, 90)
		page.BackgroundTransparency = 1
		page.ZIndex = 4
		page.Visible = false
		page.Parent = FormContent
		return page
	end

	local function switchPage(from, to, direction)
		local dir = direction or 1
		pages[from].Visible = false
		pages[to].Position = UDim2.new(dir, 0, 0, 90)
		pages[to].Visible = true
		tween(pages[to], TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 90)
		}):Play()
		updateStepBar(to)
		currentPage = to
	end

	-- ════════════════════════════════════════════
	-- SAYFA 1: KİŞİSEL BİLGİLER
	-- ════════════════════════════════════════════
	local page1 = createPage()
	page1.Visible = true
	pages[1] = page1

	local p1List = Instance.new("UIListLayout")
	p1List.SortOrder = Enum.SortOrder.LayoutOrder
	p1List.Padding = UDim.new(0, 14)
	p1List.Parent = page1

	-- Başlık
	local p1Title = Instance.new("Frame")
	p1Title.Size = UDim2.new(1, 0, 0, 50)
	p1Title.BackgroundTransparency = 1
	p1Title.LayoutOrder = 0
	p1Title.ZIndex = 5
	p1Title.Parent = page1

	local p1TitleLbl = Instance.new("TextLabel")
	p1TitleLbl.Text = "KİŞİSEL BİLGİLER"
	p1TitleLbl.Size = UDim2.new(1, 0, 0, 30)
	p1TitleLbl.BackgroundTransparency = 1
	p1TitleLbl.TextColor3 = C.text
	p1TitleLbl.Font = Enum.Font.GothamBlack
	p1TitleLbl.TextSize = 22
	p1TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	p1TitleLbl.ZIndex = 5
	p1TitleLbl.Parent = p1Title

	local p1SubLbl = Instance.new("TextLabel")
	p1SubLbl.Text = "⚠  Bu bilgiler bir daha değiştirilemez!"
	p1SubLbl.Size = UDim2.new(1, 0, 0, 18)
	p1SubLbl.Position = UDim2.new(0, 0, 0, 32)
	p1SubLbl.BackgroundTransparency = 1
	p1SubLbl.TextColor3 = C.warning
	p1SubLbl.Font = Enum.Font.GothamBold
	p1SubLbl.TextSize = 11
	p1SubLbl.TextXAlignment = Enum.TextXAlignment.Left
	p1SubLbl.ZIndex = 5
	p1SubLbl.Parent = p1Title

	-- İsim alanı
	local firstNameFrame = Instance.new("Frame")
	firstNameFrame.Size = UDim2.new(1, 0, 0, 68)
	firstNameFrame.BackgroundTransparency = 1
	firstNameFrame.LayoutOrder = 1
	firstNameFrame.ZIndex = 5
	firstNameFrame.Parent = page1

	local fnLabel = Instance.new("TextLabel")
	fnLabel.Text = "İSİM"
	fnLabel.Size = UDim2.new(1, 0, 0, 18)
	fnLabel.BackgroundTransparency = 1
	fnLabel.TextColor3 = C.textDim
	fnLabel.Font = Enum.Font.GothamBold
	fnLabel.TextSize = 11
	fnLabel.TextXAlignment = Enum.TextXAlignment.Left
	fnLabel.ZIndex = 5
	fnLabel.Parent = firstNameFrame

	local fnBg, fnBox = makeInput(firstNameFrame, "İsminizi girin...", 5)
	fnBg.Position = UDim2.new(0, 0, 0, 22)

	-- Soyad alanı
	local lastNameFrame = Instance.new("Frame")
	lastNameFrame.Size = UDim2.new(1, 0, 0, 68)
	lastNameFrame.BackgroundTransparency = 1
	lastNameFrame.LayoutOrder = 2
	lastNameFrame.ZIndex = 5
	lastNameFrame.Parent = page1

	local lnLabel = Instance.new("TextLabel")
	lnLabel.Text = "SOYİSİM"
	lnLabel.Size = UDim2.new(1, 0, 0, 18)
	lnLabel.BackgroundTransparency = 1
	lnLabel.TextColor3 = C.textDim
	lnLabel.Font = Enum.Font.GothamBold
	lnLabel.TextSize = 11
	lnLabel.TextXAlignment = Enum.TextXAlignment.Left
	lnLabel.ZIndex = 5
	lnLabel.Parent = lastNameFrame

	local lnBg, lnBox = makeInput(lastNameFrame, "Soyisminizi girin...", 5)
	lnBg.Position = UDim2.new(0, 0, 0, 22)

	-- Yaş alanı
	local ageFrame = Instance.new("Frame")
	ageFrame.Size = UDim2.new(1, 0, 0, 68)
	ageFrame.BackgroundTransparency = 1
	ageFrame.LayoutOrder = 3
	ageFrame.ZIndex = 5
	ageFrame.Parent = page1

	local ageLabel = Instance.new("TextLabel")
	ageLabel.Text = "YAŞ"
	ageLabel.Size = UDim2.new(1, 0, 0, 18)
	ageLabel.BackgroundTransparency = 1
	ageLabel.TextColor3 = C.textDim
	ageLabel.Font = Enum.Font.GothamBold
	ageLabel.TextSize = 11
	ageLabel.TextXAlignment = Enum.TextXAlignment.Left
	ageLabel.ZIndex = 5
	ageLabel.Parent = ageFrame

	local ageBg, ageBox = makeInput(ageFrame, "Yaşınızı girin (18-80)...", 5)
	ageBg.Position = UDim2.new(0, 0, 0, 22)
	ageBox.Text = "18"

	-- Cinsiyet seçimi
	local genderFrame = Instance.new("Frame")
	genderFrame.Size = UDim2.new(1, 0, 0, 80)
	genderFrame.BackgroundTransparency = 1
	genderFrame.LayoutOrder = 4
	genderFrame.ZIndex = 5
	genderFrame.Parent = page1

	local genderLabel = Instance.new("TextLabel")
	genderLabel.Text = "CİNSİYET"
	genderLabel.Size = UDim2.new(1, 0, 0, 18)
	genderLabel.BackgroundTransparency = 1
	genderLabel.TextColor3 = C.textDim
	genderLabel.Font = Enum.Font.GothamBold
	genderLabel.TextSize = 11
	genderLabel.TextXAlignment = Enum.TextXAlignment.Left
	genderLabel.ZIndex = 5
	genderLabel.Parent = genderFrame

	local genderBtns = Instance.new("Frame")
	genderBtns.Size = UDim2.new(1, 0, 0, 52)
	genderBtns.Position = UDim2.new(0, 0, 0, 24)
	genderBtns.BackgroundTransparency = 1
	genderBtns.ZIndex = 5
	genderBtns.Parent = genderFrame

	local maleBtn = Instance.new("TextButton")
	maleBtn.Size = UDim2.new(0.48, 0, 1, 0)
	maleBtn.BackgroundColor3 = C.male
	maleBtn.TextColor3 = Color3.new(1,1,1)
	maleBtn.Font = Enum.Font.GothamBold
	maleBtn.TextSize = 14
	maleBtn.Text = "♂  ERKEK"
	maleBtn.BorderSizePixel = 0
	maleBtn.ZIndex = 6
	maleBtn.Parent = genderBtns
	corner(maleBtn, 10)

	local femaleBtn = Instance.new("TextButton")
	femaleBtn.Size = UDim2.new(0.48, 0, 1, 0)
	femaleBtn.Position = UDim2.new(0.52, 0, 0, 0)
	femaleBtn.BackgroundColor3 = C.panelAlt
	femaleBtn.TextColor3 = C.textDim
	femaleBtn.Font = Enum.Font.GothamBold
	femaleBtn.TextSize = 14
	femaleBtn.Text = "♀  KADIN"
	femaleBtn.BorderSizePixel = 0
	femaleBtn.ZIndex = 6
	femaleBtn.Parent = genderBtns
	corner(femaleBtn, 10)
	stroke(femaleBtn, C.border, 1)

	local function selectGender(g)
		CharData.gender = g
		if g == "male" then
			tween(maleBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.male}):Play()
			maleBtn.TextColor3 = Color3.new(1,1,1)
			tween(femaleBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.panelAlt}):Play()
			femaleBtn.TextColor3 = C.textDim
			CharIcon.Text = "🧍"
			GenderLabel.Text = "ERKEK (Blocky)"
			GenderLabel.TextColor3 = C.male
		else
			tween(femaleBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.female}):Play()
			femaleBtn.TextColor3 = Color3.new(1,1,1)
			tween(maleBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.panelAlt}):Play()
			maleBtn.TextColor3 = C.textDim
			CharIcon.Text = "🧍‍♀️"
			GenderLabel.Text = "KADIN (R6 Girl)"
			GenderLabel.TextColor3 = C.female
		end
	end

	maleBtn.MouseButton1Click:Connect(function() selectGender("male") end)
	femaleBtn.MouseButton1Click:Connect(function() selectGender("female") end)

	-- İleri butonu
	local p1NextFrame = Instance.new("Frame")
	p1NextFrame.Size = UDim2.new(1, 0, 0, 46)
	p1NextFrame.BackgroundTransparency = 1
	p1NextFrame.LayoutOrder = 5
	p1NextFrame.ZIndex = 5
	p1NextFrame.Parent = page1

	local p1Next = makeButton(p1NextFrame, "DEVAM ET  →", C.accent, 6)

	-- Hata etiketi
	local p1Error = Instance.new("TextLabel")
	p1Error.Text = ""
	p1Error.Size = UDim2.new(1, 0, 0, 20)
	p1Error.BackgroundTransparency = 1
	p1Error.TextColor3 = C.danger
	p1Error.Font = Enum.Font.GothamBold
	p1Error.TextSize = 11
	p1Error.TextXAlignment = Enum.TextXAlignment.Left
	p1Error.LayoutOrder = 6
	p1Error.ZIndex = 5
	p1Error.Parent = page1

	p1Next.MouseButton1Click:Connect(function()
		local fn = fnBox.Text:match("^%s*(.-)%s*$")
		local ln = lnBox.Text:match("^%s*(.-)%s*$")
		local ageVal = tonumber(ageBox.Text)

		if #fn < 2 then p1Error.Text = "⚠  İsim en az 2 karakter olmalıdır." return end
		if #ln < 2 then p1Error.Text = "⚠  Soyisim en az 2 karakter olmalıdır." return end
		if not ageVal or ageVal < 18 or ageVal > 80 then p1Error.Text = "⚠  Yaş 18-80 arasında olmalıdır." return end

		CharData.firstName = fn
		CharData.lastName  = ln
		CharData.age       = ageVal
		p1Error.Text = ""
		switchPage(1, 2, 1)
	end)

	-- ════════════════════════════════════════════
	-- SAYFA 2: KARAKTER TASARIMI
	-- ════════════════════════════════════════════
	local page2 = createPage()
	pages[2] = page2

	local p2List = Instance.new("UIListLayout")
	p2List.SortOrder = Enum.SortOrder.LayoutOrder
	p2List.Padding = UDim.new(0, 16)
	p2List.Parent = page2

	local p2Title = Instance.new("Frame")
	p2Title.Size = UDim2.new(1, 0, 0, 40)
	p2Title.BackgroundTransparency = 1
	p2Title.LayoutOrder = 0
	p2Title.ZIndex = 5
	p2Title.Parent = page2

	local p2TitleLbl = Instance.new("TextLabel")
	p2TitleLbl.Text = "KARAKTER TASARIMI"
	p2TitleLbl.Size = UDim2.new(1, 0, 1, 0)
	p2TitleLbl.BackgroundTransparency = 1
	p2TitleLbl.TextColor3 = C.text
	p2TitleLbl.Font = Enum.Font.GothamBlack
	p2TitleLbl.TextSize = 22
	p2TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	p2TitleLbl.ZIndex = 5
	p2TitleLbl.Parent = p2Title

	-- Saç seçimi
	local hairSection = Instance.new("Frame")
	hairSection.Size = UDim2.new(1, 0, 0, 100)
	hairSection.BackgroundTransparency = 1
	hairSection.LayoutOrder = 1
	hairSection.ZIndex = 5
	hairSection.Parent = page2

	local hairSectionLbl = Instance.new("TextLabel")
	hairSectionLbl.Text = "SAÇ STİLİ"
	hairSectionLbl.Size = UDim2.new(1, 0, 0, 18)
	hairSectionLbl.BackgroundTransparency = 1
	hairSectionLbl.TextColor3 = C.textDim
	hairSectionLbl.Font = Enum.Font.GothamBold
	hairSectionLbl.TextSize = 11
	hairSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
	hairSectionLbl.ZIndex = 5
	hairSectionLbl.Parent = hairSection

	local hairScroll = Instance.new("ScrollingFrame")
	hairScroll.Size = UDim2.new(1, 0, 0, 72)
	hairScroll.Position = UDim2.new(0, 0, 0, 24)
	hairScroll.BackgroundTransparency = 1
	hairScroll.BorderSizePixel = 0
	hairScroll.ScrollBarThickness = 3
	hairScroll.ScrollBarImageColor3 = C.accent
	hairScroll.CanvasSize = UDim2.new(0, #HAIR_OPTIONS * 84, 0, 0)
	hairScroll.ScrollingDirection = Enum.ScrollingDirection.X
	hairScroll.ZIndex = 5
	hairScroll.Parent = hairSection

	local hairListLayout = Instance.new("UIListLayout")
	hairListLayout.FillDirection = Enum.FillDirection.Horizontal
	hairListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hairListLayout.Padding = UDim.new(0, 8)
	hairListLayout.Parent = hairScroll

	local hairCards = {}
	for i, hair in ipairs(HAIR_OPTIONS) do
		local card = Instance.new("TextButton")
		card.Size = UDim2.new(0, 76, 0, 64)
		card.BackgroundColor3 = i == 1 and C.accentDk or C.panelAlt
		card.BorderSizePixel = 0
		card.Text = ""
		card.LayoutOrder = i
		card.ZIndex = 6
		card.Parent = hairScroll
		corner(card, 10)
		stroke(card, i == 1 and C.accent or C.border, 1)

		local hairIcon = Instance.new("TextLabel")
		hairIcon.Text = "💇"
		hairIcon.Size = UDim2.new(1, 0, 0, 36)
		hairIcon.Position = UDim2.new(0, 0, 0, 4)
		hairIcon.BackgroundTransparency = 1
		hairIcon.TextSize = 24
		hairIcon.Font = Enum.Font.GothamBold
		hairIcon.ZIndex = 7
		hairIcon.Parent = card

		local hairName = Instance.new("TextLabel")
		hairName.Text = hair.name
		hairName.Size = UDim2.new(1, -4, 0, 20)
		hairName.Position = UDim2.new(0, 2, 0, 40)
		hairName.BackgroundTransparency = 1
		hairName.TextColor3 = C.textDim
		hairName.Font = Enum.Font.Gotham
		hairName.TextSize = 9
		hairName.ZIndex = 7
		hairName.Parent = card

		hairCards[i] = card

		card.MouseButton1Click:Connect(function()
			CharData.hairIndex = i
			for j, c2 in ipairs(hairCards) do
				tween(c2, TweenInfo.new(0.15), {BackgroundColor3 = j == i and C.accentDk or C.panelAlt}):Play()
				stroke(c2, j == i and C.accent or C.border, 1)
			end
		end)
	end

	-- Yüz seçimi
	local faceSection = Instance.new("Frame")
	faceSection.Size = UDim2.new(1, 0, 0, 100)
	faceSection.BackgroundTransparency = 1
	faceSection.LayoutOrder = 2
	faceSection.ZIndex = 5
	faceSection.Parent = page2

	local faceSectionLbl = Instance.new("TextLabel")
	faceSectionLbl.Text = "YÜZ İFADESİ"
	faceSectionLbl.Size = UDim2.new(1, 0, 0, 18)
	faceSectionLbl.BackgroundTransparency = 1
	faceSectionLbl.TextColor3 = C.textDim
	faceSectionLbl.Font = Enum.Font.GothamBold
	faceSectionLbl.TextSize = 11
	faceSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
	faceSectionLbl.ZIndex = 5
	faceSectionLbl.Parent = faceSection

	local faceScroll = Instance.new("ScrollingFrame")
	faceScroll.Size = UDim2.new(1, 0, 0, 72)
	faceScroll.Position = UDim2.new(0, 0, 0, 24)
	faceScroll.BackgroundTransparency = 1
	faceScroll.BorderSizePixel = 0
	faceScroll.ScrollBarThickness = 3
	faceScroll.ScrollBarImageColor3 = C.accent
	faceScroll.CanvasSize = UDim2.new(0, #FACE_OPTIONS * 84, 0, 0)
	faceScroll.ScrollingDirection = Enum.ScrollingDirection.X
	faceScroll.ZIndex = 5
	faceScroll.Parent = faceSection

	local faceListLayout = Instance.new("UIListLayout")
	faceListLayout.FillDirection = Enum.FillDirection.Horizontal
	faceListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	faceListLayout.Padding = UDim.new(0, 8)
	faceListLayout.Parent = faceScroll

	local faceEmojis = {"😐", "😊", "😐", "😠", "😢"}
	local faceCards = {}
	for i, face in ipairs(FACE_OPTIONS) do
		local card = Instance.new("TextButton")
		card.Size = UDim2.new(0, 76, 0, 64)
		card.BackgroundColor3 = i == 1 and C.accentDk or C.panelAlt
		card.BorderSizePixel = 0
		card.Text = ""
		card.LayoutOrder = i
		card.ZIndex = 6
		card.Parent = faceScroll
		corner(card, 10)
		stroke(card, i == 1 and C.accent or C.border, 1)

		local faceIcon = Instance.new("TextLabel")
		faceIcon.Text = faceEmojis[i] or "😐"
		faceIcon.Size = UDim2.new(1, 0, 0, 36)
		faceIcon.Position = UDim2.new(0, 0, 0, 4)
		faceIcon.BackgroundTransparency = 1
		faceIcon.TextSize = 24
		faceIcon.Font = Enum.Font.GothamBold
		faceIcon.ZIndex = 7
		faceIcon.Parent = card

		local faceName = Instance.new("TextLabel")
		faceName.Text = face.name
		faceName.Size = UDim2.new(1, -4, 0, 20)
		faceName.Position = UDim2.new(0, 2, 0, 40)
		faceName.BackgroundTransparency = 1
		faceName.TextColor3 = C.textDim
		faceName.Font = Enum.Font.Gotham
		faceName.TextSize = 9
		faceName.ZIndex = 7
		faceName.Parent = card

		faceCards[i] = card

		card.MouseButton1Click:Connect(function()
			CharData.faceIndex = i
			for j, c2 in ipairs(faceCards) do
				tween(c2, TweenInfo.new(0.15), {BackgroundColor3 = j == i and C.accentDk or C.panelAlt}):Play()
				stroke(c2, j == i and C.accent or C.border, 1)
			end
		end)
	end

	-- Geri / İleri butonları
	local p2BtnRow = Instance.new("Frame")
	p2BtnRow.Size = UDim2.new(1, 0, 0, 46)
	p2BtnRow.BackgroundTransparency = 1
	p2BtnRow.LayoutOrder = 3
	p2BtnRow.ZIndex = 5
	p2BtnRow.Parent = page2

	local p2Back = makeButton(p2BtnRow, "←  GERİ", Color3.fromRGB(40, 40, 60), 6)
	p2Back.Size = UDim2.new(0.45, 0, 1, 0)
	stroke(p2Back, C.border, 1)

	local p2Next = makeButton(p2BtnRow, "DEVAM ET  →", C.accent, 6)
	p2Next.Size = UDim2.new(0.52, 0, 1, 0)
	p2Next.Position = UDim2.new(0.48, 0, 0, 0)

	p2Back.MouseButton1Click:Connect(function() switchPage(2, 1, -1) end)
	p2Next.MouseButton1Click:Connect(function() switchPage(2, 3, 1) end)

	-- ════════════════════════════════════════════
	-- SAYFA 3: ONAY
	-- ════════════════════════════════════════════
	local page3 = createPage()
	pages[3] = page3

	local p3List = Instance.new("UIListLayout")
	p3List.SortOrder = Enum.SortOrder.LayoutOrder
	p3List.Padding = UDim.new(0, 14)
	p3List.Parent = page3

	local p3Title = Instance.new("Frame")
	p3Title.Size = UDim2.new(1, 0, 0, 40)
	p3Title.BackgroundTransparency = 1
	p3Title.LayoutOrder = 0
	p3Title.ZIndex = 5
	p3Title.Parent = page3

	local p3TitleLbl = Instance.new("TextLabel")
	p3TitleLbl.Text = "ONAYLA"
	p3TitleLbl.Size = UDim2.new(1, 0, 1, 0)
	p3TitleLbl.BackgroundTransparency = 1
	p3TitleLbl.TextColor3 = C.text
	p3TitleLbl.Font = Enum.Font.GothamBlack
	p3TitleLbl.TextSize = 22
	p3TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	p3TitleLbl.ZIndex = 5
	p3TitleLbl.Parent = p3Title

	-- Özet kutusu
	local summaryBox = Instance.new("Frame")
	summaryBox.Size = UDim2.new(1, 0, 0, 200)
	summaryBox.BackgroundColor3 = C.panelAlt
	summaryBox.BorderSizePixel = 0
	summaryBox.LayoutOrder = 1
	summaryBox.ZIndex = 5
	summaryBox.Parent = page3
	corner(summaryBox, 12)
	stroke(summaryBox, C.border, 1)
	pad(summaryBox, 16)

	local summaryList = Instance.new("UIListLayout")
	summaryList.SortOrder = Enum.SortOrder.LayoutOrder
	summaryList.Padding = UDim.new(0, 8)
	summaryList.Parent = summaryBox

	local function summaryRow(label, valueName, layoutOrder)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundTransparency = 1
		row.LayoutOrder = layoutOrder
		row.ZIndex = 6
		row.Parent = summaryBox

		local lbl = Instance.new("TextLabel")
		lbl.Text = label
		lbl.Size = UDim2.new(0.4, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = C.textDim
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 7
		lbl.Parent = row

		local val = Instance.new("TextLabel")
		val.Name = valueName
		val.Text = "—"
		val.Size = UDim2.new(0.6, 0, 1, 0)
		val.Position = UDim2.new(0.4, 0, 0, 0)
		val.BackgroundTransparency = 1
		val.TextColor3 = C.text
		val.Font = Enum.Font.GothamBold
		val.TextSize = 13
		val.TextXAlignment = Enum.TextXAlignment.Left
		val.ZIndex = 7
		val.Parent = row

		return val
	end

	local s_name    = summaryRow("İSİM",    "SName",    1)
	local s_surname = summaryRow("SOYİSİM", "SSurname", 2)
	local s_age     = summaryRow("YAŞ",     "SAge",     3)
	local s_gender  = summaryRow("CİNSİYET","SGender",  4)
	local s_hair    = summaryRow("SAÇ",     "SHair",    5)
	local s_face    = summaryRow("YÜZ",     "SFace",    6)

	-- Uyarı kutusu
	local warnBox = Instance.new("Frame")
	warnBox.Size = UDim2.new(1, 0, 0, 50)
	warnBox.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
	warnBox.BorderSizePixel = 0
	warnBox.LayoutOrder = 2
	warnBox.ZIndex = 5
	warnBox.Parent = page3
	corner(warnBox, 10)
	stroke(warnBox, C.warning, 1)

	local warnLbl = Instance.new("TextLabel")
	warnLbl.Text = "⚠  Bu bilgiler kaydedildikten sonra bir daha değiştirilemez!\nEmin misiniz?"
	warnLbl.Size = UDim2.new(1, -20, 1, 0)
	warnLbl.Position = UDim2.new(0, 10, 0, 0)
	warnLbl.BackgroundTransparency = 1
	warnLbl.TextColor3 = C.warning
	warnLbl.Font = Enum.Font.GothamBold
	warnLbl.TextSize = 11
	warnLbl.TextXAlignment = Enum.TextXAlignment.Left
	warnLbl.TextWrapped = true
	warnLbl.ZIndex = 6
	warnLbl.Parent = warnBox

	-- Onay butonları
	local p3BtnRow = Instance.new("Frame")
	p3BtnRow.Size = UDim2.new(1, 0, 0, 46)
	p3BtnRow.BackgroundTransparency = 1
	p3BtnRow.LayoutOrder = 3
	p3BtnRow.ZIndex = 5
	p3BtnRow.Parent = page3

	local p3Back = makeButton(p3BtnRow, "←  GERİ", Color3.fromRGB(40, 40, 60), 6)
	p3Back.Size = UDim2.new(0.45, 0, 1, 0)
	stroke(p3Back, C.border, 1)

	local p3Confirm = makeButton(p3BtnRow, "✓  ONAYLA", C.success, 6)
	p3Confirm.Size = UDim2.new(0.52, 0, 1, 0)
	p3Confirm.Position = UDim2.new(0.48, 0, 0, 0)

	p3Back.MouseButton1Click:Connect(function() switchPage(3, 2, -1) end)

	-- Sayfa 3 açıldığında özeti güncelle
	local origSwitchPage = switchPage
	local function updateSummary()
		s_name.Text    = CharData.firstName
		s_surname.Text = CharData.lastName
		s_age.Text     = tostring(CharData.age)
		s_gender.Text  = CharData.gender == "male" and "Erkek (Blocky)" or "Kadın (R6 Girl)"
		s_hair.Text    = HAIR_OPTIONS[CharData.hairIndex].name
		s_face.Text    = FACE_OPTIONS[CharData.faceIndex].name
	end

	p2Next.MouseButton1Click:Connect(function()
		updateSummary()
	end)

	-- ─────────────────────────────────────────────
	-- ONAY → LOADING EKRANI
	-- ─────────────────────────────────────────────
	p3Confirm.MouseButton1Click:Connect(function()
		p3Confirm.Active = false

		-- RemoteEvent ile sunucuya gönder
		local remote = ReplicatedStorage:FindFirstChild("BSCRemotes")
		if remote then
			local createChar = remote:FindFirstChild("CreateCharacter")
			if createChar then
				createChar:FireServer(CharData)
			end
		end

		-- Loading ekranı
		Module.ShowLoading(Gui, function()
			-- Loading bitti → Takım seçimi
			Gui:Destroy()
			local TeamSelectModule = require(script.Parent:WaitForChild("TeamSelectUI"))
			TeamSelectModule.Open(LocalPlayer.PlayerGui)
		end)
	end)

	print("[BSC Prison] CharacterCreatorUI yüklendi.")
end

-- ─────────────────────────────────────────────
-- LOADING EKRANI
-- ─────────────────────────────────────────────
function Module.ShowLoading(parentGui, onComplete)
	local C2 = {
		bg     = Color3.fromRGB(4, 4, 8),
		accent = Color3.fromRGB(90, 120, 255),
		text   = Color3.fromRGB(220, 220, 235),
		dim    = Color3.fromRGB(80, 80, 100),
	}

	local loadGui = Instance.new("ScreenGui")
	loadGui.Name = "BSCLoading"
	loadGui.ResetOnSpawn = false
	loadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	loadGui.IgnoreGuiInset = true
	loadGui.ZIndex = 200
	loadGui.Parent = parentGui.Parent or LocalPlayer.PlayerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = C2.bg
	bg.BorderSizePixel = 0
	bg.ZIndex = 201
	bg.Parent = loadGui

	-- Logo
	local logoLbl = Instance.new("TextLabel")
	logoLbl.Text = "BSC"
	logoLbl.Size = UDim2.new(0, 200, 0, 60)
	logoLbl.Position = UDim2.new(0.5, -100, 0.35, 0)
	logoLbl.BackgroundTransparency = 1
	logoLbl.TextColor3 = C2.accent
	logoLbl.Font = Enum.Font.GothamBlack
	logoLbl.TextSize = 52
	logoLbl.ZIndex = 202
	logoLbl.Parent = bg

	local prisonLbl = Instance.new("TextLabel")
	prisonLbl.Text = "PRISON"
	prisonLbl.Size = UDim2.new(0, 300, 0, 40)
	prisonLbl.Position = UDim2.new(0.5, -150, 0.35, 58)
	prisonLbl.BackgroundTransparency = 1
	prisonLbl.TextColor3 = C2.text
	prisonLbl.Font = Enum.Font.GothamBlack
	prisonLbl.TextSize = 28
	prisonLbl.ZIndex = 202
	prisonLbl.Parent = bg

	-- Loading bar arka plan
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0, 400, 0, 6)
	barBg.Position = UDim2.new(0.5, -200, 0.62, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 202
	barBg.Parent = bg
	corner(barBg, 3)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = C2.accent
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 203
	barFill.Parent = barBg
	corner(barFill, 3)

	-- Loading yüzdesi
	local pctLbl = Instance.new("TextLabel")
	pctLbl.Text = "0%"
	pctLbl.Size = UDim2.new(0, 400, 0, 24)
	pctLbl.Position = UDim2.new(0.5, -200, 0.62, 14)
	pctLbl.BackgroundTransparency = 1
	pctLbl.TextColor3 = C2.accent
	pctLbl.Font = Enum.Font.GothamBold
	pctLbl.TextSize = 13
	pctLbl.ZIndex = 202
	pctLbl.Parent = bg

	-- Loading mesajları
	local messages = {
		"Harita yükleniyor...",
		"Karakteriniz hazırlanıyor...",
		"Güvenlik sistemleri aktif ediliyor...",
		"Takım atamaları yapılıyor...",
		"BSC Prison'a hoş geldiniz!",
	}

	local msgLbl = Instance.new("TextLabel")
	msgLbl.Text = messages[1]
	msgLbl.Size = UDim2.new(0, 400, 0, 24)
	msgLbl.Position = UDim2.new(0.5, -200, 0.62, 38)
	msgLbl.BackgroundTransparency = 1
	msgLbl.TextColor3 = C2.dim
	msgLbl.Font = Enum.Font.Gotham
	msgLbl.TextSize = 12
	msgLbl.ZIndex = 202
	msgLbl.Parent = bg

	-- Dönen yükleme halkası (simüle)
	local spinnerFrame = Instance.new("Frame")
	spinnerFrame.Size = UDim2.new(0, 40, 0, 40)
	spinnerFrame.Position = UDim2.new(0.5, -20, 0.55, -20)
	spinnerFrame.BackgroundTransparency = 1
	spinnerFrame.ZIndex = 202
	spinnerFrame.Parent = bg

	local spinArc = Instance.new("Frame")
	spinArc.Size = UDim2.new(1, 0, 0.5, 0)
	spinArc.BackgroundColor3 = C2.accent
	spinArc.BorderSizePixel = 0
	spinArc.ZIndex = 203
	spinArc.Parent = spinnerFrame
	corner(spinArc, 20)

	-- Spinner animasyonu
	local spinConn
	local spinAngle = 0
	spinConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		spinAngle = spinAngle + 180 * dt
		spinnerFrame.Rotation = spinAngle
	end)

	-- Progress animasyonu
	local progress = 0
	local msgIndex = 1
	local totalTime = 3.5

	local function animateLoading()
		local steps = 100
		local stepTime = totalTime / steps
		for i = 1, steps do
			task.wait(stepTime)
			progress = i / steps
			tween(barFill, TweenInfo.new(stepTime * 0.9), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
			pctLbl.Text = tostring(math.floor(progress * 100)) .. "%"

			local newMsgIdx = math.ceil(progress * #messages)
			if newMsgIdx ~= msgIndex and newMsgIdx <= #messages then
				msgIndex = newMsgIdx
				tween(msgLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
				task.delay(0.2, function()
					msgLbl.Text = messages[msgIndex]
					tween(msgLbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
				end)
			end
		end

		-- Tamamlandı
		task.wait(0.3)
		spinConn:Disconnect()
		tween(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		tween(logoLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		tween(prisonLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.delay(0.5, function()
			loadGui:Destroy()
			if onComplete then onComplete() end
		end)
	end

	task.spawn(animateLoading)
end

return Module
