-- ============================================================
-- BSC PRISON | GameHUD.lua
-- StarterPlayerScripts > GameHUD (ModuleScript)
-- Oyun İçi HUD: İsyan, Emotes, Inventory, Solve
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
	bg       = Color3.fromRGB(8, 8, 12),
	panel    = Color3.fromRGB(14, 14, 20),
	panelAlt = Color3.fromRGB(18, 18, 26),
	border   = Color3.fromRGB(35, 35, 52),
	accent   = Color3.fromRGB(90, 120, 255),
	accentDk = Color3.fromRGB(50, 70, 180),
	text     = Color3.fromRGB(220, 220, 235),
	textDim  = Color3.fromRGB(110, 110, 135),
	danger   = Color3.fromRGB(220, 60, 60),
	warning  = Color3.fromRGB(220, 160, 60),
	success  = Color3.fromRGB(60, 200, 120),
	riot     = Color3.fromRGB(220, 80, 30),
	cop      = Color3.fromRGB(30, 100, 220),
	prisoner = Color3.fromRGB(180, 140, 40),
	criminal = Color3.fromRGB(200, 50, 50),
	hostage  = Color3.fromRGB(100, 200, 130),
}

-- ─────────────────────────────────────────────
-- YARDIMCI
-- ─────────────────────────────────────────────
local function corner(p, r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p, col, th) local s=Instance.new("UIStroke") s.Color=col or C.border s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function pad(p, px) local u=Instance.new("UIPadding") u.PaddingLeft=UDim.new(0,px) u.PaddingRight=UDim.new(0,px) u.PaddingTop=UDim.new(0,px) u.PaddingBottom=UDim.new(0,px) u.Parent=p return u end
local function tween(obj, info, props) return TweenService:Create(obj, info, props) end

local function makeBtn(parent, text, color, size, pos, zIndex)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(0, 120, 0, 40)
	btn.Position = pos or UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = color or C.panel
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex or 5
	btn.Parent = parent
	corner(btn, 10)
	return btn
end

-- ─────────────────────────────────────────────
-- BAĞLI NESNELER (Solve sistemi için)
-- Sunucudan gelecek - şimdilik örnek veri
-- ─────────────────────────────────────────────
local SOLVE_ITEMS = {
	{id = "handcuffs",  name = "El Kelepçesi",  icon = "⛓",  solveTime = 5,  desc = "Ellerin bağlı"},
	{id = "rope",       name = "İp",             icon = "🪢",  solveTime = 8,  desc = "Vücudun bağlı"},
	{id = "collar",     name = "Tasma",          icon = "🔗",  solveTime = 6,  desc = "Boyun tasması"},
	{id = "tape",       name = "Bant",           icon = "🩹",  solveTime = 4,  desc = "Ağzın bantlı"},
}

-- ─────────────────────────────────────────────
-- EMOTE LİSTESİ
-- ─────────────────────────────────────────────
local EMOTES = {
	{name = "Dans",       icon = "💃", animId = "507771019"},
	{name = "Selamlama",  icon = "👋", animId = "507770239"},
	{name = "Alkış",      icon = "👏", animId = "507770677"},
	{name = "Ağlama",     icon = "😢", animId = "507770453"},
	{name = "Güleç",      icon = "😂", animId = "507770818"},
	{name = "Öfke",       icon = "😠", animId = "507770453"},
}

-- ─────────────────────────────────────────────
-- AÇMA FONKSİYONU
-- ─────────────────────────────────────────────
function Module.Open(playerGui, teamId)
	local teamColor = C[teamId] or C.accent

	local Gui = Instance.new("ScreenGui")
	Gui.Name = "BSCGameHUD"
	Gui.ResetOnSpawn = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.IgnoreGuiInset = true
	Gui.Parent = playerGui

	-- ─────────────────────────────────────────────
	-- ÜST BAR (Takım bilgisi + BSC Prison)
	-- ─────────────────────────────────────────────
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 48)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = C.panel
	TopBar.BackgroundTransparency = 0.2
	TopBar.BorderSizePixel = 0
	TopBar.ZIndex = 5
	TopBar.Parent = Gui

	local topLine = Instance.new("Frame")
	topLine.Size = UDim2.new(1, 0, 0, 2)
	topLine.Position = UDim2.new(0, 0, 1, -2)
	topLine.BackgroundColor3 = teamColor
	topLine.BorderSizePixel = 0
	topLine.ZIndex = 6
	topLine.Parent = TopBar

	local bscLbl = Instance.new("TextLabel")
	bscLbl.Text = "BSC PRISON"
	bscLbl.Size = UDim2.new(0, 150, 1, 0)
	bscLbl.Position = UDim2.new(0, 16, 0, 0)
	bscLbl.BackgroundTransparency = 1
	bscLbl.TextColor3 = C.accent
	bscLbl.Font = Enum.Font.GothamBlack
	bscLbl.TextSize = 16
	bscLbl.TextXAlignment = Enum.TextXAlignment.Left
	bscLbl.ZIndex = 6
	bscLbl.Parent = TopBar

	local teamBadge = Instance.new("TextLabel")
	local teamNames = {cop="POLİS", prisoner="MAHKUM", criminal="KRİMİNAL", hostage="REHİNE"}
	local teamIcons = {cop="👮", prisoner="🧑‍🦲", criminal="🦹", hostage="😰"}
	teamBadge.Text = (teamIcons[teamId] or "?") .. "  " .. (teamNames[teamId] or "BİLİNMEYEN")
	teamBadge.Size = UDim2.new(0, 160, 0, 30)
	teamBadge.Position = UDim2.new(0.5, -80, 0.5, -15)
	teamBadge.BackgroundColor3 = teamColor
	teamBadge.BackgroundTransparency = 0.7
	teamBadge.TextColor3 = teamColor
	teamBadge.Font = Enum.Font.GothamBold
	teamBadge.TextSize = 13
	teamBadge.BorderSizePixel = 0
	teamBadge.ZIndex = 6
	teamBadge.Parent = TopBar
	corner(teamBadge, 8)

	-- ─────────────────────────────────────────────
	-- SOL ALT: İSYAN BUTONU (Sadece prisoner/criminal)
	-- ─────────────────────────────────────────────
	if teamId == "prisoner" or teamId == "criminal" then
		local RiotContainer = Instance.new("Frame")
		RiotContainer.Name = "RiotContainer"
		RiotContainer.Size = UDim2.new(0, 160, 0, 52)
		RiotContainer.Position = UDim2.new(0, 16, 1, -68)
		RiotContainer.BackgroundTransparency = 1
		RiotContainer.ZIndex = 5
		RiotContainer.Parent = Gui

		local RiotBtn = makeBtn(RiotContainer, "✊  İSYAN ET", C.riot, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), 6)
		stroke(RiotBtn, Color3.fromRGB(255, 100, 50), 1)

		-- Nabız animasyonu
		local pulseConn
		local function startPulse()
			pulseConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
				local t = tick()
				local alpha = (math.sin(t * 3) + 1) / 2
				RiotBtn.BackgroundColor3 = Color3.fromRGB(
					math.floor(180 + alpha * 40),
					math.floor(60 + alpha * 20),
					math.floor(20 + alpha * 10)
				)
			end)
		end
		startPulse()

		-- İSYAN POPUP
		RiotBtn.MouseButton1Click:Connect(function()
			-- Popup oluştur
			local popupBG = Instance.new("Frame")
			popupBG.Size = UDim2.new(1, 0, 1, 0)
			popupBG.BackgroundColor3 = Color3.new(0,0,0)
			popupBG.BackgroundTransparency = 0.5
			popupBG.BorderSizePixel = 0
			popupBG.ZIndex = 50
			popupBG.Parent = Gui

			local popup = Instance.new("Frame")
			popup.Size = UDim2.new(0, 400, 0, 0)
			popup.Position = UDim2.new(0.5, -200, 0.5, 0)
			popup.BackgroundColor3 = C.panel
			popup.BorderSizePixel = 0
			popup.ZIndex = 51
			popup.Parent = Gui
			corner(popup, 16)
			stroke(popup, C.riot, 2)

			tween(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 400, 0, 280),
				Position = UDim2.new(0.5, -200, 0.5, -140)
			}):Play()

			-- İkon
			local riotIcon = Instance.new("TextLabel")
			riotIcon.Text = "✊"
			riotIcon.Size = UDim2.new(0, 80, 0, 80)
			riotIcon.Position = UDim2.new(0.5, -40, 0, 16)
			riotIcon.BackgroundTransparency = 1
			riotIcon.TextSize = 52
			riotIcon.Font = Enum.Font.GothamBold
			riotIcon.ZIndex = 52
			riotIcon.Parent = popup

			local riotTitle = Instance.new("TextLabel")
			riotTitle.Text = "⚠  İSYAN UYARISI"
			riotTitle.Size = UDim2.new(1, -40, 0, 28)
			riotTitle.Position = UDim2.new(0, 20, 0, 100)
			riotTitle.BackgroundTransparency = 1
			riotTitle.TextColor3 = C.riot
			riotTitle.Font = Enum.Font.GothamBlack
			riotTitle.TextSize = 18
			riotTitle.ZIndex = 52
			riotTitle.Parent = popup

			local riotDesc = Instance.new("TextLabel")
			riotDesc.Text = "İsyan başlatırsanız artık masum sayılmayacaksınız!\n\nPolisler sizi görür görmez tutuklayabilir.\nTüm hakları kaybedeceksiniz.\n\nEmin misiniz?"
			riotDesc.Size = UDim2.new(1, -40, 0, 80)
			riotDesc.Position = UDim2.new(0, 20, 0, 132)
			riotDesc.BackgroundTransparency = 1
			riotDesc.TextColor3 = C.textDim
			riotDesc.Font = Enum.Font.Gotham
			riotDesc.TextSize = 12
			riotDesc.TextXAlignment = Enum.TextXAlignment.Left
			riotDesc.TextWrapped = true
			riotDesc.ZIndex = 52
			riotDesc.Parent = popup

			-- Butonlar
			local cancelBtn = makeBtn(popup, "İPTAL", Color3.fromRGB(40, 40, 60),
				UDim2.new(0, 170, 0, 42),
				UDim2.new(0, 20, 0, 222), 52)
			stroke(cancelBtn, C.border, 1)

			local confirmRiotBtn = makeBtn(popup, "✊  İSYAN ET!", C.riot,
				UDim2.new(0, 170, 0, 42),
				UDim2.new(0, 210, 0, 222), 52)

			local function closePopup()
				tween(popup, TweenInfo.new(0.2), {
					Size = UDim2.new(0, 400, 0, 0),
					Position = UDim2.new(0.5, -200, 0.5, 0)
				}):Play()
				task.delay(0.2, function()
					popup:Destroy()
					popupBG:Destroy()
				end)
			end

			cancelBtn.MouseButton1Click:Connect(closePopup)
			popupBG.MouseButton1Click:Connect(closePopup)

			confirmRiotBtn.MouseButton1Click:Connect(function()
				closePopup()

				-- İsyan başlat
				local remote = ReplicatedStorage:FindFirstChild("BSCRemotes")
				if remote then
					local riotEvent = remote:FindFirstChild("StartRiot")
					if riotEvent then riotEvent:FireServer() end
				end

				-- İsyan durumu göstergesi
				if pulseConn then pulseConn:Disconnect() end
				RiotBtn.Text = "🔥  İSYAN AKTİF"
				RiotBtn.BackgroundColor3 = C.danger
				RiotBtn.Active = false

				-- Ekranda uyarı banner
				local riotBanner = Instance.new("Frame")
				riotBanner.Size = UDim2.new(1, 0, 0, 36)
				riotBanner.Position = UDim2.new(0, 0, 0, 48)
				riotBanner.BackgroundColor3 = C.riot
				riotBanner.BackgroundTransparency = 0.2
				riotBanner.BorderSizePixel = 0
				riotBanner.ZIndex = 10
				riotBanner.Parent = Gui

				local riotBannerLbl = Instance.new("TextLabel")
				riotBannerLbl.Text = "🔥  İSYAN BAŞLADI — Artık masum değilsiniz! Dikkatli olun!"
				riotBannerLbl.Size = UDim2.new(1, 0, 1, 0)
				riotBannerLbl.BackgroundTransparency = 1
				riotBannerLbl.TextColor3 = Color3.new(1,1,1)
				riotBannerLbl.Font = Enum.Font.GothamBold
				riotBannerLbl.TextSize = 13
				riotBannerLbl.ZIndex = 11
				riotBannerLbl.Parent = riotBanner

				-- 5 saniye sonra banner kaybolsun
				task.delay(5, function()
					tween(riotBanner, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
					tween(riotBannerLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
					task.delay(0.5, function() riotBanner:Destroy() end)
				end)
			end)
		end)
	end

	-- ─────────────────────────────────────────────
	-- SAĞ KENAR: < TOGGLE BUTONU
	-- ─────────────────────────────────────────────
	local rightPanelOpen = false

	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "RightToggle"
	ToggleBtn.Size = UDim2.new(0, 32, 0, 100)
	ToggleBtn.Position = UDim2.new(1, -32, 0.5, -50)
	ToggleBtn.BackgroundColor3 = C.panel
	ToggleBtn.TextColor3 = C.text
	ToggleBtn.Font = Enum.Font.GothamBold
	ToggleBtn.TextSize = 14
	ToggleBtn.Text = "<"
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.ZIndex = 10
	ToggleBtn.Parent = Gui
	corner(ToggleBtn, 8)
	stroke(ToggleBtn, C.border, 1)

	-- Sağ Panel
	local RightPanel = Instance.new("Frame")
	RightPanel.Name = "RightPanel"
	RightPanel.Size = UDim2.new(0, 260, 1, -60)
	RightPanel.Position = UDim2.new(1, 0, 0, 52)
	RightPanel.BackgroundColor3 = C.panel
	RightPanel.BackgroundTransparency = 0.05
	RightPanel.BorderSizePixel = 0
	RightPanel.ZIndex = 8
	RightPanel.Parent = Gui
	stroke(RightPanel, C.border, 1)

	-- Sağ panel sekme butonları
	local TabBar = Instance.new("Frame")
	TabBar.Size = UDim2.new(1, 0, 0, 48)
	TabBar.BackgroundColor3 = C.panelAlt
	TabBar.BorderSizePixel = 0
	TabBar.ZIndex = 9
	TabBar.Parent = RightPanel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = TabBar

	local TABS = {
		{name = "EMOTES",    icon = "💃", id = "emotes"},
		{name = "EŞYA",      icon = "🎒", id = "inventory"},
		{name = "ÇÖZDÜR",    icon = "🔓", id = "solve"},
	}

	local tabBtns = {}
	local tabPages = {}
	local activeTab = "emotes"

	-- Tab içerik alanı
	local TabContent = Instance.new("Frame")
	TabContent.Size = UDim2.new(1, 0, 1, -48)
	TabContent.Position = UDim2.new(0, 0, 0, 48)
	TabContent.BackgroundTransparency = 1
	TabContent.ZIndex = 9
	TabContent.Parent = RightPanel

	-- ─── EMOTES SAYFASI ───
	local emotesPage = Instance.new("ScrollingFrame")
	emotesPage.Name = "EmotesPage"
	emotesPage.Size = UDim2.new(1, 0, 1, 0)
	emotesPage.BackgroundTransparency = 1
	emotesPage.BorderSizePixel = 0
	emotesPage.ScrollBarThickness = 3
	emotesPage.ScrollBarImageColor3 = C.accent
	emotesPage.CanvasSize = UDim2.new(0, 0, 0, 0)
	emotesPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
	emotesPage.ZIndex = 10
	emotesPage.Visible = true
	emotesPage.Parent = TabContent
	pad(emotesPage, 12)

	local emoteGrid = Instance.new("UIGridLayout")
	emoteGrid.CellSize = UDim2.new(0, 100, 0, 90)
	emoteGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	emoteGrid.SortOrder = Enum.SortOrder.LayoutOrder
	emoteGrid.Parent = emotesPage

	for i, emote in ipairs(EMOTES) do
		local eCard = Instance.new("TextButton")
		eCard.Size = UDim2.new(0, 100, 0, 90)
		eCard.BackgroundColor3 = C.panelAlt
		eCard.BorderSizePixel = 0
		eCard.Text = ""
		eCard.LayoutOrder = i
		eCard.ZIndex = 11
		eCard.Parent = emotesPage
		corner(eCard, 10)
		stroke(eCard, C.border, 1)

		local eIcon = Instance.new("TextLabel")
		eIcon.Text = emote.icon
		eIcon.Size = UDim2.new(1, 0, 0, 50)
		eIcon.Position = UDim2.new(0, 0, 0, 6)
		eIcon.BackgroundTransparency = 1
		eIcon.TextSize = 30
		eIcon.Font = Enum.Font.GothamBold
		eIcon.ZIndex = 12
		eIcon.Parent = eCard

		local eName = Instance.new("TextLabel")
		eName.Text = emote.name
		eName.Size = UDim2.new(1, -4, 0, 24)
		eName.Position = UDim2.new(0, 2, 0, 58)
		eName.BackgroundTransparency = 1
		eName.TextColor3 = C.textDim
		eName.Font = Enum.Font.Gotham
		eName.TextSize = 10
		eName.ZIndex = 12
		eName.Parent = eCard

		eCard.MouseEnter:Connect(function()
			tween(eCard, TweenInfo.new(0.12), {BackgroundColor3 = C.accentDk}):Play()
		end)
		eCard.MouseLeave:Connect(function()
			tween(eCard, TweenInfo.new(0.12), {BackgroundColor3 = C.panelAlt}):Play()
		end)

		eCard.MouseButton1Click:Connect(function()
			local remote = ReplicatedStorage:FindFirstChild("BSCRemotes")
			if remote then
				local playEmote = remote:FindFirstChild("PlayEmote")
				if playEmote then playEmote:FireServer(emote.animId) end
			end
		end)
	end
	tabPages["emotes"] = emotesPage

	-- ─── INVENTORY SAYFASI ───
	local inventoryPage = Instance.new("ScrollingFrame")
	inventoryPage.Name = "InventoryPage"
	inventoryPage.Size = UDim2.new(1, 0, 1, 0)
	inventoryPage.BackgroundTransparency = 1
	inventoryPage.BorderSizePixel = 0
	inventoryPage.ScrollBarThickness = 3
	inventoryPage.ScrollBarImageColor3 = C.accent
	inventoryPage.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inventoryPage.ZIndex = 10
	inventoryPage.Visible = false
	inventoryPage.Parent = TabContent
	pad(inventoryPage, 12)

	local invList = Instance.new("UIListLayout")
	invList.SortOrder = Enum.SortOrder.LayoutOrder
	invList.Padding = UDim.new(0, 8)
	invList.Parent = inventoryPage

	-- Boş envanter mesajı
	local emptyInvLbl = Instance.new("TextLabel")
	emptyInvLbl.Text = "🎒  Envanteriniz boş.\nOyun içinde eşya toplayın."
	emptyInvLbl.Size = UDim2.new(1, 0, 0, 80)
	emptyInvLbl.BackgroundTransparency = 1
	emptyInvLbl.TextColor3 = C.textDim
	emptyInvLbl.Font = Enum.Font.Gotham
	emptyInvLbl.TextSize = 12
	emptyInvLbl.TextWrapped = true
	emptyInvLbl.ZIndex = 11
	emptyInvLbl.Parent = inventoryPage
	tabPages["inventory"] = inventoryPage

	-- ─── SOLVE SAYFASI ───
	local solvePage = Instance.new("Frame")
	solvePage.Name = "SolvePage"
	solvePage.Size = UDim2.new(1, 0, 1, 0)
	solvePage.BackgroundTransparency = 1
	solvePage.ZIndex = 10
	solvePage.Visible = false
	solvePage.Parent = TabContent
	pad(solvePage, 12)

	local solveList = Instance.new("UIListLayout")
	solveList.SortOrder = Enum.SortOrder.LayoutOrder
	solveList.Padding = UDim.new(0, 10)
	solveList.Parent = solvePage

	-- Solve başlık
	local solveTitleLbl = Instance.new("TextLabel")
	solveTitleLbl.Text = "🔓  BAĞLARI ÇÖZDÜR"
	solveTitleLbl.Size = UDim2.new(1, 0, 0, 28)
	solveTitleLbl.BackgroundTransparency = 1
	solveTitleLbl.TextColor3 = C.text
	solveTitleLbl.Font = Enum.Font.GothamBold
	solveTitleLbl.TextSize = 14
	solveTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	solveTitleLbl.LayoutOrder = 0
	solveTitleLbl.ZIndex = 11
	solveTitleLbl.Parent = solvePage

	local solveSubLbl = Instance.new("TextLabel")
	solveSubLbl.Text = "Üzerine tıkla ve 'Çözdür' butonuna bas."
	solveSubLbl.Size = UDim2.new(1, 0, 0, 20)
	solveSubLbl.BackgroundTransparency = 1
	solveSubLbl.TextColor3 = C.textDim
	solveSubLbl.Font = Enum.Font.Gotham
	solveSubLbl.TextSize = 11
	solveSubLbl.TextXAlignment = Enum.TextXAlignment.Left
	solveSubLbl.LayoutOrder = 1
	solveSubLbl.ZIndex = 11
	solveSubLbl.Parent = solvePage

	-- Bağlı nesne listesi
	local selectedSolveItem = nil
	local solveItemCards = {}

	-- Örnek bağlı nesneler (sunucudan gelecek)
	local activeBonds = {SOLVE_ITEMS[1], SOLVE_ITEMS[3]}  -- Örnek: el kelepçesi + tasma

	for i, item in ipairs(activeBonds) do
		local itemCard = Instance.new("TextButton")
		itemCard.Size = UDim2.new(1, 0, 0, 60)
		itemCard.BackgroundColor3 = C.panelAlt
		itemCard.BorderSizePixel = 0
		itemCard.Text = ""
		itemCard.LayoutOrder = i + 1
		itemCard.ZIndex = 11
		itemCard.Parent = solvePage
		corner(itemCard, 10)
		stroke(itemCard, C.border, 1)

		local itemIcon = Instance.new("TextLabel")
		itemIcon.Text = item.icon
		itemIcon.Size = UDim2.new(0, 44, 1, 0)
		itemIcon.BackgroundTransparency = 1
		itemIcon.TextSize = 26
		itemIcon.Font = Enum.Font.GothamBold
		itemIcon.ZIndex = 12
		itemIcon.Parent = itemCard

		local itemNameLbl = Instance.new("TextLabel")
		itemNameLbl.Text = item.name
		itemNameLbl.Size = UDim2.new(1, -80, 0, 24)
		itemNameLbl.Position = UDim2.new(0, 44, 0, 8)
		itemNameLbl.BackgroundTransparency = 1
		itemNameLbl.TextColor3 = C.text
		itemNameLbl.Font = Enum.Font.GothamBold
		itemNameLbl.TextSize = 13
		itemNameLbl.TextXAlignment = Enum.TextXAlignment.Left
		itemNameLbl.ZIndex = 12
		itemNameLbl.Parent = itemCard

		local itemDescLbl = Instance.new("TextLabel")
		itemDescLbl.Text = item.desc .. "  •  " .. item.solveTime .. "sn"
		itemDescLbl.Size = UDim2.new(1, -80, 0, 20)
		itemDescLbl.Position = UDim2.new(0, 44, 0, 32)
		itemDescLbl.BackgroundTransparency = 1
		itemDescLbl.TextColor3 = C.textDim
		itemDescLbl.Font = Enum.Font.Gotham
		itemDescLbl.TextSize = 10
		itemDescLbl.TextXAlignment = Enum.TextXAlignment.Left
		itemDescLbl.ZIndex = 12
		itemDescLbl.Parent = itemCard

		solveItemCards[item.id] = itemCard

		itemCard.MouseButton1Click:Connect(function()
			selectedSolveItem = item
			for id2, card2 in pairs(solveItemCards) do
				if id2 == item.id then
					tween(card2, TweenInfo.new(0.15), {BackgroundColor3 = C.accentDk}):Play()
					stroke(card2, C.accent, 2)
				else
					tween(card2, TweenInfo.new(0.15), {BackgroundColor3 = C.panelAlt}):Play()
					stroke(card2, C.border, 1)
				end
			end
		end)
	end

	-- Çözdür butonu
	local solveActionFrame = Instance.new("Frame")
	solveActionFrame.Size = UDim2.new(1, 0, 0, 50)
	solveActionFrame.BackgroundTransparency = 1
	solveActionFrame.LayoutOrder = 20
	solveActionFrame.ZIndex = 11
	solveActionFrame.Parent = solvePage

	local solveActionBtn = makeBtn(solveActionFrame, "🔓  ÇÖZDÜR", C.success,
		UDim2.new(1, 0, 0, 46), UDim2.new(0,0,0,0), 12)

	-- Progress bar (çözme süresi)
	local solveProgressBg = Instance.new("Frame")
	solveProgressBg.Size = UDim2.new(1, 0, 0, 6)
	solveProgressBg.Position = UDim2.new(0, 0, 1, 4)
	solveProgressBg.BackgroundColor3 = C.border
	solveProgressBg.BorderSizePixel = 0
	solveProgressBg.ZIndex = 12
	solveProgressBg.Visible = false
	solveProgressBg.Parent = solveActionFrame
	corner(solveProgressBg, 3)

	local solveProgressFill = Instance.new("Frame")
	solveProgressFill.Size = UDim2.new(0, 0, 1, 0)
	solveProgressFill.BackgroundColor3 = C.success
	solveProgressFill.BorderSizePixel = 0
	solveProgressFill.ZIndex = 13
	solveProgressFill.Parent = solveProgressBg
	corner(solveProgressFill, 3)

	local isSolving = false

	solveActionBtn.MouseButton1Click:Connect(function()
		if not selectedSolveItem or isSolving then return end
		isSolving = true
		solveActionBtn.Active = false
		solveActionBtn.Text = "⏳  Çözülüyor..."
		solveProgressBg.Visible = true

		local duration = selectedSolveItem.solveTime
		local elapsed = 0

		-- Progress animasyonu
		local solveConn
		solveConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
			elapsed = elapsed + dt
			local pct = math.min(elapsed / duration, 1)
			tween(solveProgressFill, TweenInfo.new(0.05), {Size = UDim2.new(pct, 0, 1, 0)}):Play()

			if pct >= 1 then
				solveConn:Disconnect()
				isSolving = false

				-- Sunucuya bildir
				local remote = ReplicatedStorage:FindFirstChild("BSCRemotes")
				if remote then
					local solveEvent = remote:FindFirstChild("SolveBond")
					if solveEvent then solveEvent:FireServer(selectedSolveItem.id) end
				end

				-- Kartı kaldır
				local card = solveItemCards[selectedSolveItem.id]
				if card then
					tween(card, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
					task.delay(0.3, function() card:Destroy() end)
					solveItemCards[selectedSolveItem.id] = nil
				end

				selectedSolveItem = nil
				solveActionBtn.Active = true
				solveActionBtn.Text = "🔓  ÇÖZDÜR"
				solveProgressBg.Visible = false
				solveProgressFill.Size = UDim2.new(0, 0, 1, 0)

				-- Başarı bildirimi
				Module.ShowNotification(Gui, "✅  Bağ çözüldü!", C.success)
			end
		end)
	end)

	tabPages["solve"] = solvePage

	-- ─── TAB BUTONLARI ───
	for i, tab in ipairs(TABS) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1/#TABS, 0, 1, 0)
		tabBtn.BackgroundColor3 = tab.id == "emotes" and C.accentDk or C.panelAlt
		tabBtn.TextColor3 = tab.id == "emotes" and Color3.new(1,1,1) or C.textDim
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 10
		tabBtn.Text = tab.icon .. "\n" .. tab.name
		tabBtn.BorderSizePixel = 0
		tabBtn.LayoutOrder = i
		tabBtn.ZIndex = 10
		tabBtn.Parent = TabBar

		tabBtns[tab.id] = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			if activeTab == tab.id then return end

			-- Önceki tab
			if tabPages[activeTab] then tabPages[activeTab].Visible = false end
			if tabBtns[activeTab] then
				tween(tabBtns[activeTab], TweenInfo.new(0.15), {BackgroundColor3 = C.panelAlt}):Play()
				tabBtns[activeTab].TextColor3 = C.textDim
			end

			-- Yeni tab
			activeTab = tab.id
			if tabPages[activeTab] then tabPages[activeTab].Visible = true end
			tween(tabBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.accentDk}):Play()
			tabBtn.TextColor3 = Color3.new(1,1,1)
		end)
	end

	-- ─── TOGGLE ANIMASYONU ───
	ToggleBtn.MouseButton1Click:Connect(function()
		rightPanelOpen = not rightPanelOpen
		if rightPanelOpen then
			tween(RightPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -260, 0, 52)
			}):Play()
			tween(ToggleBtn, TweenInfo.new(0.3), {
				Position = UDim2.new(1, -292, 0.5, -50)
			}):Play()
			ToggleBtn.Text = ">"
		else
			tween(RightPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, 0, 0, 52)
			}):Play()
			tween(ToggleBtn, TweenInfo.new(0.3), {
				Position = UDim2.new(1, -32, 0.5, -50)
			}):Play()
			ToggleBtn.Text = "<"
		end
	end)

	print("[BSC Prison] GameHUD yüklendi. Takım:", teamId)
end

-- ─────────────────────────────────────────────
-- BİLDİRİM SİSTEMİ
-- ─────────────────────────────────────────────
function Module.ShowNotification(gui, text, color)
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 300, 0, 44)
	notif.Position = UDim2.new(0.5, -150, 0, -50)
	notif.BackgroundColor3 = color or C.accent
	notif.BackgroundTransparency = 0.1
	notif.BorderSizePixel = 0
	notif.ZIndex = 100
	notif.Parent = gui
	corner(notif, 10)

	local notifLbl = Instance.new("TextLabel")
	notifLbl.Text = text
	notifLbl.Size = UDim2.new(1, -20, 1, 0)
	notifLbl.Position = UDim2.new(0, 10, 0, 0)
	notifLbl.BackgroundTransparency = 1
	notifLbl.TextColor3 = Color3.new(1,1,1)
	notifLbl.Font = Enum.Font.GothamBold
	notifLbl.TextSize = 13
	notifLbl.ZIndex = 101
	notifLbl.Parent = notif

	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, 0, 58)
	}):Play()

	task.delay(2.5, function()
		TweenService:Create(notif, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -150, 0, -50),
			BackgroundTransparency = 1
		}):Play()
		TweenService:Create(notifLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		task.delay(0.3, function() notif:Destroy() end)
	end)
end

return Module
