-- ============================================================
-- BSC PRISON | TeamSelectUI.lua
-- StarterPlayerScripts > TeamSelectUI (ModuleScript)
-- Takım Seçimi: Cop / Prisoner / Criminal / Hostage
-- ============================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Module = {}

-- ─────────────────────────────────────────────
-- RENK PALETİ
-- ─────────────────────────────────────────────
local C = {
	bg       = Color3.fromRGB(6, 6, 10),
	panel    = Color3.fromRGB(12, 12, 18),
	border   = Color3.fromRGB(35, 35, 52),
	text     = Color3.fromRGB(220, 220, 235),
	textDim  = Color3.fromRGB(110, 110, 135),
	accent   = Color3.fromRGB(90, 120, 255),
}

local TEAMS = {
	{
		id       = "cop",
		name     = "POLİS",
		sub      = "COP",
		desc     = "Düzeni sağla, mahkumları kontrol et,\nesir al ve hapishaneyi yönet.",
		icon     = "👮",
		color    = Color3.fromRGB(30, 100, 220),
		darkColor= Color3.fromRGB(15, 55, 130),
		badge    = "KANUN",
		badgeCol = Color3.fromRGB(30, 100, 220),
		perks    = {"🔫  Silah taşıma hakkı", "🔑  Kapı erişimi", "🚔  Araç kullanımı", "⛓  Bağlama yetkisi"},
	},
	{
		id       = "prisoner",
		name     = "MAHKUM",
		sub      = "PRISONER",
		desc     = "Hapishanede hayatta kal, görevleri\ntamamla ve özgürlüğünü kazan.",
		icon     = "🧑‍🦲",
		color    = Color3.fromRGB(180, 140, 40),
		darkColor= Color3.fromRGB(100, 75, 15),
		badge    = "TUTSAK",
		badgeCol = Color3.fromRGB(180, 140, 40),
		perks    = {"🏃  Kaçma hakkı", "⚒  İş yapma", "📦  Eşya toplama", "✊  İsyan katılımı"},
	},
	{
		id       = "criminal",
		name     = "KRİMİNAL",
		sub      = "CRIMINAL",
		desc     = "Gizlice hareket et, suç işle ve\nhapishane düzenini boz.",
		icon     = "🦹",
		color    = Color3.fromRGB(200, 50, 50),
		darkColor= Color3.fromRGB(110, 20, 20),
		badge    = "SUÇLU",
		badgeCol = Color3.fromRGB(200, 50, 50),
		perks    = {"🔪  Gizli silah", "🕵️  Gizlenme", "💣  Sabotaj", "🏴  İsyan lideri"},
	},
	{
		id       = "hostage",
		name     = "REHİNE",
		sub      = "HOSTAGE",
		desc     = "Kriminaller tarafından rehin alınmış\nbir sivil. Kurtarılmayı bekle.",
		icon     = "😰",
		color    = Color3.fromRGB(100, 200, 130),
		darkColor= Color3.fromRGB(40, 100, 60),
		badge    = "SİVİL",
		badgeCol = Color3.fromRGB(100, 200, 130),
		perks    = {"🙏  Kurtarılma bonusu", "🏃  Kaçma şansı", "📢  Yardım çağrısı", "🛡  Koruma kalkanı"},
	},
}

-- ─────────────────────────────────────────────
-- YARDIMCI
-- ─────────────────────────────────────────────
local function corner(p, r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p, col, th) local s=Instance.new("UIStroke") s.Color=col or C.border s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function tween(obj, info, props) return TweenService:Create(obj, info, props) end

-- ─────────────────────────────────────────────
-- AÇMA FONKSİYONU
-- ─────────────────────────────────────────────
function Module.Open(playerGui)
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "BSCTeamSelect"
	Gui.ResetOnSpawn = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.IgnoreGuiInset = true
	Gui.Parent = playerGui

	-- Arka plan
	local BG = Instance.new("Frame")
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.BackgroundColor3 = C.bg
	BG.BorderSizePixel = 0
	BG.ZIndex = 1
	BG.Parent = Gui

	-- Üst başlık
	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 80)
	Header.BackgroundTransparency = 1
	Header.ZIndex = 2
	Header.Parent = BG

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = "TAKIM SEÇ"
	titleLbl.Size = UDim2.new(1, 0, 0, 44)
	titleLbl.Position = UDim2.new(0, 0, 0, 16)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = C.text
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 32
	titleLbl.ZIndex = 3
	titleLbl.Parent = Header

	local subLbl = Instance.new("TextLabel")
	subLbl.Text = "Rolünü seç ve BSC Prison'a katıl"
	subLbl.Size = UDim2.new(1, 0, 0, 20)
	subLbl.Position = UDim2.new(0, 0, 0, 56)
	subLbl.BackgroundTransparency = 1
	subLbl.TextColor3 = C.textDim
	subLbl.Font = Enum.Font.Gotham
	subLbl.TextSize = 13
	subLbl.ZIndex = 3
	subLbl.Parent = Header

	-- Takım kartları konteyneri
	local CardsContainer = Instance.new("Frame")
	CardsContainer.Size = UDim2.new(1, -60, 1, -160)
	CardsContainer.Position = UDim2.new(0, 30, 0, 90)
	CardsContainer.BackgroundTransparency = 1
	CardsContainer.ZIndex = 2
	CardsContainer.Parent = BG

	local cardsLayout = Instance.new("UIListLayout")
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Padding = UDim.new(0, 16)
	cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cardsLayout.Parent = CardsContainer

	-- Seçili takım
	local selectedTeam = nil
	local cardFrames = {}

	-- Onay butonu (alt)
	local ConfirmFrame = Instance.new("Frame")
	ConfirmFrame.Size = UDim2.new(0, 300, 0, 60)
	ConfirmFrame.Position = UDim2.new(0.5, -150, 1, -75)
	ConfirmFrame.BackgroundTransparency = 1
	ConfirmFrame.ZIndex = 2
	ConfirmFrame.Parent = BG

	local ConfirmBtn = Instance.new("TextButton")
	ConfirmBtn.Size = UDim2.new(1, 0, 0, 50)
	ConfirmBtn.Position = UDim2.new(0, 0, 0, 5)
	ConfirmBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	ConfirmBtn.TextColor3 = C.textDim
	ConfirmBtn.Font = Enum.Font.GothamBold
	ConfirmBtn.TextSize = 16
	ConfirmBtn.Text = "Takım Seç"
	ConfirmBtn.BorderSizePixel = 0
	ConfirmBtn.Active = false
	ConfirmBtn.ZIndex = 3
	ConfirmBtn.Parent = ConfirmFrame
	corner(ConfirmBtn, 12)
	stroke(ConfirmBtn, C.border, 1)

	-- ─────────────────────────────────────────────
	-- KART OLUŞTURMA
	-- ─────────────────────────────────────────────
	for i, team in ipairs(TEAMS) do
		local card = Instance.new("TextButton")
		card.Name = team.id
		card.Size = UDim2.new(0, 220, 1, 0)
		card.BackgroundColor3 = C.panel
		card.BorderSizePixel = 0
		card.Text = ""
		card.LayoutOrder = i
		card.ZIndex = 3
		card.Parent = CardsContainer
		corner(card, 16)
		stroke(card, C.border, 1)

		-- Üst renk şeridi
		local topBar = Instance.new("Frame")
		topBar.Size = UDim2.new(1, 0, 0, 6)
		topBar.BackgroundColor3 = team.color
		topBar.BorderSizePixel = 0
		topBar.ZIndex = 4
		topBar.Parent = card
		corner(topBar, 16)

		local topBarFix = Instance.new("Frame")
		topBarFix.Size = UDim2.new(1, 0, 0.5, 0)
		topBarFix.Position = UDim2.new(0, 0, 0.5, 0)
		topBarFix.BackgroundColor3 = team.color
		topBarFix.BorderSizePixel = 0
		topBarFix.ZIndex = 4
		topBarFix.Parent = topBar

		-- İkon arka plan
		local iconBg = Instance.new("Frame")
		iconBg.Size = UDim2.new(0, 80, 0, 80)
		iconBg.Position = UDim2.new(0.5, -40, 0, 22)
		iconBg.BackgroundColor3 = team.darkColor
		iconBg.BorderSizePixel = 0
		iconBg.ZIndex = 4
		iconBg.Parent = card
		corner(iconBg, 40)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Text = team.icon
		iconLbl.Size = UDim2.new(1, 0, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.TextSize = 38
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.ZIndex = 5
		iconLbl.Parent = iconBg

		-- Rozet
		local badge = Instance.new("TextLabel")
		badge.Text = team.badge
		badge.Size = UDim2.new(0, 80, 0, 22)
		badge.Position = UDim2.new(0.5, -40, 0, 108)
		badge.BackgroundColor3 = team.badgeCol
		badge.BackgroundTransparency = 0.75
		badge.TextColor3 = team.badgeCol
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 10
		badge.BorderSizePixel = 0
		badge.ZIndex = 4
		badge.Parent = card
		corner(badge, 5)

		-- Takım adı
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = team.name
		nameLbl.Size = UDim2.new(1, -20, 0, 28)
		nameLbl.Position = UDim2.new(0, 10, 0, 138)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = team.color
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextSize = 18
		nameLbl.ZIndex = 4
		nameLbl.Parent = card

		local subLblCard = Instance.new("TextLabel")
		subLblCard.Text = team.sub
		subLblCard.Size = UDim2.new(1, -20, 0, 16)
		subLblCard.Position = UDim2.new(0, 10, 0, 164)
		subLblCard.BackgroundTransparency = 1
		subLblCard.TextColor3 = C.textDim
		subLblCard.Font = Enum.Font.GothamBold
		subLblCard.TextSize = 10
		subLblCard.LetterSpacing = 4
		subLblCard.ZIndex = 4
		subLblCard.Parent = card

		-- Açıklama
		local descLbl = Instance.new("TextLabel")
		descLbl.Text = team.desc
		descLbl.Size = UDim2.new(1, -20, 0, 44)
		descLbl.Position = UDim2.new(0, 10, 0, 186)
		descLbl.BackgroundTransparency = 1
		descLbl.TextColor3 = C.textDim
		descLbl.Font = Enum.Font.Gotham
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextWrapped = true
		descLbl.ZIndex = 4
		descLbl.Parent = card

		-- Ayırıcı
		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(1, -20, 0, 1)
		divider.Position = UDim2.new(0, 10, 0, 236)
		divider.BackgroundColor3 = C.border
		divider.BorderSizePixel = 0
		divider.ZIndex = 4
		divider.Parent = card

		-- Perk listesi
		for j, perk in ipairs(team.perks) do
			local perkLbl = Instance.new("TextLabel")
			perkLbl.Text = perk
			perkLbl.Size = UDim2.new(1, -20, 0, 22)
			perkLbl.Position = UDim2.new(0, 10, 0, 242 + (j-1) * 24)
			perkLbl.BackgroundTransparency = 1
			perkLbl.TextColor3 = C.textDim
			perkLbl.Font = Enum.Font.Gotham
			perkLbl.TextSize = 11
			perkLbl.TextXAlignment = Enum.TextXAlignment.Left
			perkLbl.ZIndex = 4
			perkLbl.Parent = card
		end

		-- Seçim göstergesi (alt)
		local selectIndicator = Instance.new("Frame")
		selectIndicator.Size = UDim2.new(1, 0, 0, 4)
		selectIndicator.Position = UDim2.new(0, 0, 1, -4)
		selectIndicator.BackgroundColor3 = team.color
		selectIndicator.BackgroundTransparency = 1
		selectIndicator.BorderSizePixel = 0
		selectIndicator.ZIndex = 4
		selectIndicator.Parent = card
		corner(selectIndicator, 2)

		cardFrames[team.id] = {
			card = card,
			indicator = selectIndicator,
			team = team,
		}

		-- Hover
		card.MouseEnter:Connect(function()
			if selectedTeam ~= team.id then
				tween(card, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(18, 18, 28)}):Play()
				tween(card, TweenInfo.new(0.18), {Size = UDim2.new(0, 228, 1, 0)}):Play()
			end
		end)
		card.MouseLeave:Connect(function()
			if selectedTeam ~= team.id then
				tween(card, TweenInfo.new(0.18), {BackgroundColor3 = C.panel}):Play()
				tween(card, TweenInfo.new(0.18), {Size = UDim2.new(0, 220, 1, 0)}):Play()
			end
		end)

		-- Seçim
		card.MouseButton1Click:Connect(function()
			selectedTeam = team.id

			-- Tüm kartları sıfırla
			for tid, data in pairs(cardFrames) do
				if tid ~= team.id then
					tween(data.card, TweenInfo.new(0.2), {
						BackgroundColor3 = C.panel,
						Size = UDim2.new(0, 220, 1, 0)
					}):Play()
					stroke(data.card, C.border, 1)
					tween(data.indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				end
			end

			-- Seçilen kartı vurgula
			tween(card, TweenInfo.new(0.2), {
				BackgroundColor3 = team.darkColor,
				Size = UDim2.new(0, 236, 1, 0)
			}):Play()
			stroke(card, team.color, 2)
			tween(selectIndicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()

			-- Onay butonunu aktif et
			ConfirmBtn.Active = true
			tween(ConfirmBtn, TweenInfo.new(0.2), {BackgroundColor3 = team.color}):Play()
			ConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
			ConfirmBtn.Text = team.icon .. "  " .. team.name .. " OLARAK KATIL"
		end)
	end

	-- ─────────────────────────────────────────────
	-- ONAY BUTONU
	-- ─────────────────────────────────────────────
	ConfirmBtn.MouseButton1Click:Connect(function()
		if not selectedTeam then return end

		ConfirmBtn.Active = false
		ConfirmBtn.Text = "Katılıyorsunuz..."

		-- Sunucuya takım seçimi gönder
		local remote = ReplicatedStorage:FindFirstChild("BSCRemotes")
		if remote then
			local joinTeam = remote:FindFirstChild("JoinTeam")
			if joinTeam then
				joinTeam:FireServer(selectedTeam)
			end
		end

		-- Karartma
		local fadeFrame = Instance.new("Frame")
		fadeFrame.Size = UDim2.new(1, 0, 1, 0)
		fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		fadeFrame.BackgroundTransparency = 1
		fadeFrame.BorderSizePixel = 0
		fadeFrame.ZIndex = 100
		fadeFrame.Parent = BG

		tween(fadeFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

		task.delay(0.6, function()
			Gui:Destroy()
			-- HUD'u aç
			local HUDModule = require(script.Parent:WaitForChild("GameHUD"))
			HUDModule.Open(LocalPlayer.PlayerGui, selectedTeam)
		end)
	end)

	-- ─────────────────────────────────────────────
	-- GİRİŞ ANİMASYONU
	-- ─────────────────────────────────────────────
	for i, team in ipairs(TEAMS) do
		local data = cardFrames[team.id]
		if data then
			data.card.BackgroundTransparency = 1
			data.card.Position = UDim2.new(0, 0, 0.1, 0)
			task.delay(i * 0.08, function()
				tween(data.card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0,
					Position = UDim2.new(0, 0, 0, 0)
				}):Play()
			end)
		end
	end

	print("[BSC Prison] TeamSelectUI yüklendi.")
end

return Module
