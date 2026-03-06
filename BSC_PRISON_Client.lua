--[[
╔══════════════════════════════════════════════════════════════════╗
║   BSC PRISON — GameClient.lua  v3.0 ULTRA                       ║
║   📁 StarterPlayerScripts → LocalScript                         ║
║                                                                  ║
║   YENİLİKLER v3.0:                                              ║
║   • Kuş bakışı harita viewport (siyah kutu YOK)                ║
║   • Tüm butonlar baştan görünür                                 ║
║   • CFrame animasyonları: idle, run, jump, sit, sleep           ║
║   • Emotes sistemi: kneel, sit, sleep, layside, vb.            ║
║   • KeycardTool (client + server entegre)                       ║
║   • RopeTool — animasyonlu bağlama, gerçekçi ip görünümü       ║
║   • HandcuffsTool, TaserTool, CollarTool                       ║
║   • Hareket animasyonları (idle/run/jump otomatik)              ║
╚══════════════════════════════════════════════════════════════════╝
--]]

local Players   = game:GetService("Players")
local TweenSvc  = game:GetService("TweenService")
local RepStore  = game:GetService("ReplicatedStorage")
local RunSvc    = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local ContextAS = game:GetService("ContextActionService")

local lp  = Players.LocalPlayer
local Gui = lp:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
-- RENK PALETİ
-- ════════════════════════════════════════════════════════════════
local C = {
    bg       = Color3.fromRGB(6,6,9),
    panel    = Color3.fromRGB(11,11,16),
    card     = Color3.fromRGB(16,16,24),
    cardH    = Color3.fromRGB(24,24,34),
    btn      = Color3.fromRGB(22,22,32),
    accent   = Color3.fromRGB(80,110,200),
    accentH  = Color3.fromRGB(140,170,255),
    accentG  = Color3.fromRGB(40,180,100),
    accentR  = Color3.fromRGB(200,50,50),
    text     = Color3.fromRGB(210,215,230),
    dim      = Color3.fromRGB(80,85,110),
    border   = Color3.fromRGB(30,30,44),
    danger   = Color3.fromRGB(120,22,22),
    dangerH  = Color3.fromRGB(195,65,65),
    black    = Color3.new(0,0,0),
    white    = Color3.new(1,1,1),
    cyan     = Color3.fromRGB(0,200,255),
    neonG    = Color3.fromRGB(50,255,120),
}

-- ════════════════════════════════════════════════════════════════
-- YARDIMCI FONKSİYONLAR
-- ════════════════════════════════════════════════════════════════
local function tw(o,p,t,es,ed)
    return TweenSvc:Create(o,TweenInfo.new(t or .3,es or Enum.EasingStyle.Quart,ed or Enum.EasingDirection.Out),p)
end
local function Corn(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p;return c end
local function Strk(p,col,th) local s=Instance.new("UIStroke");s.Color=col or C.border;s.Thickness=th or 1;s.Parent=p;return s end
local function Pad(p,a,l,r,t,b)
    local u=Instance.new("UIPadding");u.Parent=p
    if a then u.PaddingLeft=UDim.new(0,a);u.PaddingRight=UDim.new(0,a);u.PaddingTop=UDim.new(0,a);u.PaddingBottom=UDim.new(0,a)
    else u.PaddingLeft=UDim.new(0,l or 0);u.PaddingRight=UDim.new(0,r or 0);u.PaddingTop=UDim.new(0,t or 0);u.PaddingBottom=UDim.new(0,b or 0) end
end
local function Fr(nm,par,sz,ps,col,tr)
    local f=Instance.new("Frame");f.Name=nm
    f.Size=sz or UDim2.new(1,0,1,0);f.Position=ps or UDim2.new()
    f.BackgroundColor3=col or C.bg;f.BackgroundTransparency=tr or 0
    f.BorderSizePixel=0;f.Parent=par;return f
end
local function Lbl(nm,par,txt,sz,ps,col,fs,fnt,xa)
    local l=Instance.new("TextLabel");l.Name=nm
    l.Size=sz or UDim2.new(1,0,0,20);l.Position=ps or UDim2.new()
    l.BackgroundTransparency=1;l.Text=txt or ""
    l.TextColor3=col or C.text;l.TextSize=fs or 14
    l.Font=fnt or Enum.Font.GothamMedium
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Parent=par;return l
end
local function Inp(nm,par,ph,sz,ps)
    local w=Fr(nm.."W",par,sz,ps,C.card);Corn(w,6);Strk(w,C.border)
    local tb=Instance.new("TextBox");tb.Name=nm
    tb.Size=UDim2.new(1,-18,1,0);tb.Position=UDim2.new(0,9,0,0)
    tb.BackgroundTransparency=1;tb.PlaceholderText=ph or ""
    tb.PlaceholderColor3=C.dim;tb.Text=""
    tb.TextColor3=C.text;tb.TextSize=13;tb.Font=Enum.Font.Gotham
    tb.TextXAlignment=Enum.TextXAlignment.Left;tb.ClearTextOnFocus=false;tb.Parent=w
    tb.Focused:Connect(function() for _,s in ipairs(w:GetChildren())do if s:IsA("UIStroke")then tw(s,{Color=C.accent},.2):Play()end end end)
    tb.FocusLost:Connect(function() for _,s in ipairs(w:GetChildren())do if s:IsA("UIStroke")then tw(s,{Color=C.border},.2):Play()end end end)
    return tb,w
end
local function ScFr(nm,par,sz,ps)
    local sf=Instance.new("ScrollingFrame");sf.Name=nm
    sf.Size=sz or UDim2.new(1,0,1,0);sf.Position=ps or UDim2.new()
    sf.BackgroundTransparency=1;sf.BorderSizePixel=0
    sf.ScrollBarThickness=3;sf.ScrollBarImageColor3=Color3.fromRGB(55,55,80)
    sf.CanvasSize=UDim2.new(0,0,0,0);sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.Parent=par;return sf
end
local function Btn(nm,par,txt,sz,ps,bg,tx,fs)
    bg=bg or C.btn;tx=tx or C.text
    local b=Instance.new("TextButton");b.Name=nm
    b.Size=sz or UDim2.new(0,120,0,36);b.Position=ps or UDim2.new()
    b.BackgroundColor3=bg;b.BorderSizePixel=0
    b.Text=txt or "";b.TextColor3=tx;b.TextSize=fs or 13
    b.Font=Enum.Font.GothamMedium;b.AutoButtonColor=false
    b.Parent=par;Corn(b,6)
    local ob=bg
    b.MouseEnter:Connect(function()
        tw(b,{BackgroundColor3=Color3.new(math.min(ob.R+.1,1),math.min(ob.G+.1,1),math.min(ob.B+.1,1))},.12):Play()
    end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=ob},.15):Play() end)
    b.MouseButton1Down:Connect(function() tw(b,{BackgroundColor3=Color3.new(ob.R*.72,ob.G*.72,ob.B*.72)},.06):Play() end)
    b.MouseButton1Up:Connect(function() tw(b,{BackgroundColor3=ob},.1):Play() end)
    return b
end

local function addPanelGloss(frame)
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(210,220,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160,170,190)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.96),
        NumberSequenceKeypoint.new(0.4, 0.985),
        NumberSequenceKeypoint.new(1, 0.95),
    })
    grad.Parent = frame
end

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local charData = {firstName="",lastName="",age="",gender="Male",hair=1,face=1}
local currentStep = 1
local panelOpen   = false
local isRioting   = false
local constraintItems = {}
local BSC_RE = nil

local HAIR_IDS = {
    Male  = {{id=86487700,name="Classic"},{id=1303085290,name="Stylish"},{id=250394084,name="Short"},{id=139607718,name="Fade"}},
    Female= {{id=107997590,name="Long"},{id=1031217426,name="Ponytail"},{id=16627529,name="Wavy"},{id=185742297,name="Bob"}},
}
local FACE_IDS = {{id=10521894,name="Default"},{id=2365629,name="Smile"},{id=1572314,name="Serious"},{id=4078060,name="Cool"}}

-- Root ScreenGui
if Gui:FindFirstChild("BSCGui") then Gui.BSCGui:Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name="BSCGui";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.DisplayOrder=30;SG.Enabled=true;SG.Parent=Gui

-- ════════════════════════════════════════════════════════════════
-- §1  MAIN MENU — Kuş Bakışı ViewportFrame
-- ════════════════════════════════════════════════════════════════
local MM = Fr("MM",SG,UDim2.new(1,0,1,0),nil,C.bg)
MM.Visible = true

-- ── Kuş Bakışı ViewportFrame (tam ekran, koyu arka plan YOK) ──
local VP = Instance.new("ViewportFrame")
VP.Name = "VP"
VP.Size = UDim2.new(1,0,1,0)
VP.Position = UDim2.new(0,0,0,0)
-- Gerçekçi sahne renkleri (siyah kutu yok)
VP.BackgroundColor3 = Color3.fromRGB(30,55,90)  -- gece gökyüzü tonu
VP.Ambient = Color3.fromRGB(100,110,140)
VP.LightColor = Color3.fromRGB(200,210,240)
VP.LightDirection = Vector3.new(-0.3,-1,-0.4)
VP.ZIndex = 1
VP.Parent = MM

local vpCam = Instance.new("Camera")
vpCam.CameraType = Enum.CameraType.Scriptable
vpCam.Parent = VP
VP.CurrentCamera = vpCam

-- Mini harita modeli (kuş bakışı için optimize)
local previewM = Instance.new("Model")
previewM.Name = "PreviewMap"
previewM.Parent = VP

local function pvp(sz, pos, bc, mat, tr)
    local p = Instance.new("Part")
    p.Size = sz; p.CFrame = CFrame.new(pos)
    p.BrickColor = BrickColor.new(bc or "Medium stone grey")
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Anchored = true; p.CanCollide = false
    p.Transparency = tr or 0; p.CastShadow = false
    p.Parent = previewM; return p
end

-- Ana zemin (yeşilimsi toprak)
pvp(Vector3.new(160,1,130), Vector3.new(0,-0.5,0), "Sand green", Enum.Material.Grass)
-- Yollar
pvp(Vector3.new(160,0.2,6),  Vector3.new(0,0.1,0),  "Dark stone grey")
pvp(Vector3.new(6,0.2,130),  Vector3.new(0,0.1,0),  "Dark stone grey")
-- Yol çizgisi
pvp(Vector3.new(160,0.22,0.6),Vector3.new(0,0.12,0),"Bright yellow",Enum.Material.SmoothPlastic)
pvp(Vector3.new(0.6,0.22,130),Vector3.new(0,0.12,0),"Bright yellow",Enum.Material.SmoothPlastic)

-- Prison (merkez, gri)
pvp(Vector3.new(28,7,22),   Vector3.new(0,3.5,0),   "Smoky grey", Enum.Material.Concrete)
pvp(Vector3.new(28,0.4,15), Vector3.new(0,0.3,20),  "Light stone grey", Enum.Material.Concrete) -- avlu
-- Prison neon çatı (turuncu)
pvp(Vector3.new(26,0.5,20), Vector3.new(0,7.3,0),   "Bright orange", Enum.Material.SmoothPlastic)

-- Police HQ (kuzey, mavi ton)
pvp(Vector3.new(32,9,25),   Vector3.new(40,-15,0),  "Light stone grey", Enum.Material.Concrete)
pvp(Vector3.new(30,0.5,23), Vector3.new(40,-5.5,0), "Cyan", Enum.Material.SmoothPlastic)

-- Criminal Base (güney batı, siyah/kırmızı)
pvp(Vector3.new(26,8,20),   Vector3.new(-45,0,40),  "Really black", Enum.Material.Concrete)
pvp(Vector3.new(24,0.4,18), Vector3.new(-45,8.3,40),"Bright red", Enum.Material.SmoothPlastic)

-- Şehir binaları (kuzey batı)
local cityColors = {"Sand green","Pastel blue","Reddish brown","Institutional white","Sand yellow"}
for i=0,4 do
    pvp(Vector3.new(7,5+i*2,6), Vector3.new(-45+i*10,-15,-35+i*5), cityColors[i+1], Enum.Material.SmoothPlastic)
    pvp(Vector3.new(7,0.3,6),   Vector3.new(-45+i*10,2+i,-35+i*5), "Bright yellow", Enum.Material.SmoothPlastic)
end

-- Endüstriyel (doğu)
pvp(Vector3.new(28,12,24),  Vector3.new(60,0,40),   "Dark stone grey", Enum.Material.Concrete)
pvp(Vector3.new(4,28,4),    Vector3.new(65,6,48),   "Dark stone grey", Enum.Material.Brick) -- baca
pvp(Vector3.new(3,3,3),     Vector3.new(65,22,48),  "Bright orange", Enum.Material.SmoothPlastic)

-- Sınır duvarları (ince beyaz çizgi)
pvp(Vector3.new(160,8,2),   Vector3.new(0,0,65),    "Institutional white", Enum.Material.Concrete)
pvp(Vector3.new(160,8,2),   Vector3.new(0,0,-65),   "Institutional white", Enum.Material.Concrete)
pvp(Vector3.new(2,8,130),   Vector3.new(80,0,0),    "Institutional white", Enum.Material.Concrete)
pvp(Vector3.new(2,8,130),   Vector3.new(-80,0,0),   "Institutional white", Enum.Material.Concrete)

-- Köşe kuleler
for _,xz in ipairs({{80,65},{-80,65},{80,-65},{-80,-65}}) do
    local kule = pvp(Vector3.new(5,14,5),  Vector3.new(xz[1],0,xz[2]),  "Dark stone grey", Enum.Material.Concrete)
    pvp(Vector3.new(1,1,1), Vector3.new(xz[1],7.5,xz[2]), "Bright yellow", Enum.Material.SmoothPlastic)
end

-- Ağaçlar (küçük yeşil toplar)
local treePos = {
    {-65,-40},{-70,-20},{-62,-55},{60,-45},{68,-30},{55,-60},
    {-65,20},{-70,35},{-60,50},{60,20},{68,38},{55,55},
}
for _,tp in ipairs(treePos) do
    pvp(Vector3.new(3,5,3),  Vector3.new(tp[1],0,tp[2]),  "Brown", Enum.Material.Wood)
    pvp(Vector3.new(6,5,6),  Vector3.new(tp[1],5,tp[2]),  "Bright green", Enum.Material.Grass, 0.05)
end

-- ── Kuş Bakışı Kamera (tam yukarıdan, hafif eğimli) ──
local vpTopY = 140    -- yükseklik
local vpAngle = math.random(0,628)/100

RunSvc.RenderStepped:Connect(function(dt)
    if not MM.Visible then return end
    -- Yavaş dönen kuş bakışı
    vpAngle = vpAngle + dt * 0.04
    local radius = 30
    local camX = math.sin(vpAngle) * radius
    local camZ = math.cos(vpAngle) * radius
    -- Kuş bakışı: çok yüksek, hafif eğik
    vpCam.CFrame = CFrame.lookAt(
        Vector3.new(camX, vpTopY, camZ),
        Vector3.new(0, 0, 0)
    )
end)

-- ── Gradient overlay (üstten aşağı solan) ──
local gradientFrame = Fr("GradTop",MM,UDim2.new(1,0,0.5,0),UDim2.new(0,0,0,0),C.bg,1)
gradientFrame.ZIndex = 2
local topGrad = Instance.new("UIGradient")
topGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0),
    NumberSequenceKeypoint.new(0.25,0.6),
    NumberSequenceKeypoint.new(1,1),
})
topGrad.Parent = gradientFrame

local gradientBottom = Fr("GradBot",MM,UDim2.new(1,0,0.55,0),UDim2.new(0,0,0.45,0),C.bg,1)
gradientBottom.ZIndex = 2
local botGrad = Instance.new("UIGradient")
botGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,1),
    NumberSequenceKeypoint.new(0.3,0.2),
    NumberSequenceKeypoint.new(1,0),
})
botGrad.Parent = gradientBottom

-- Hafif vignette
local vigF = Fr("Vig",MM,nil,nil,C.black,1); vigF.ZIndex=3
local vg=Instance.new("UIGradient"); vg.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.25,0.75),NumberSequenceKeypoint.new(1,1),
}); vg.Parent=vigF

-- ── LOGO ──
local bscLbl = Lbl("BSC",MM,"BSC",UDim2.new(0,500,0,75),UDim2.new(0.5,-250,0,35),
    C.text,64,Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
bscLbl.ZIndex=5; bscLbl.LetterSpacing=20
local bscG=Instance.new("UIGradient"); bscG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(140,145,165)),
    ColorSequenceKeypoint.new(0.5,C.white),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(125,130,150)),
}); bscG.Rotation=90; bscG.Parent=bscLbl

local prisonLbl=Lbl("PRISON",MM,"P  R  I  S  O  N",UDim2.new(0,400,0,24),
    UDim2.new(0.5,-200,0,110),C.dim,15,Enum.Font.GothamMedium,Enum.TextXAlignment.Center)
prisonLbl.ZIndex=5

local sepLn=Fr("Sep",MM,UDim2.new(0,44,0,1.5),UDim2.new(0.5,-22,0,142),C.border); sepLn.ZIndex=5
local verLbl=Lbl("Ver",MM,"ULTRA v3.0",UDim2.new(0,200,0,15),UDim2.new(0.5,-100,0,150),
    C.dim,10,Enum.Font.Gotham,Enum.TextXAlignment.Center); verLbl.ZIndex=5

-- ── MENÜ BUTONLARI (baştan TAM görünür) ──
local btnHolder = Instance.new("CanvasGroup")
btnHolder.Name = "BtnHolder"
btnHolder.Size = UDim2.new(0,250,0,0)
btnHolder.Position = UDim2.new(0.5,-125,0.5,-20)
btnHolder.BackgroundColor3 = C.black
btnHolder.BackgroundTransparency = 1
btnHolder.BorderSizePixel = 0
btnHolder.AutomaticSize = Enum.AutomaticSize.Y
btnHolder.ZIndex = 5
btnHolder.Parent = MM
Instance.new("UIListLayout",btnHolder).Padding=UDim.new(0,10)

local MENU_DEFS = {
    {k="Play",     lbl="▶   PLAY",             hi=true},
    {k="Settings", lbl="⚙   SETTINGS"               },
    {k="Logs",     lbl="⚡   PATCH NOTES"       },
    {k="Rules",    lbl="⚑   RULES"              },
    {k="Credits",  lbl="★   CREDITS"             },
}
local mBtns = {}
for _,bd in ipairs(MENU_DEFS) do
    local bg=bd.hi and Color3.fromRGB(18,18,32) or C.btn
    local tx=bd.hi and C.accentH or C.dim
    local b=Btn(bd.k,btnHolder,bd.lbl,UDim2.new(1,0,0,52),nil,bg,tx,13)
    b.TextXAlignment=Enum.TextXAlignment.Left; b.ZIndex=6
    Pad(b,nil,20,0,0,0)
    Strk(b,bd.hi and Color3.fromRGB(45,45,80) or C.border)
    if bd.hi then
        local ac=Fr("Ac",b,UDim2.new(0,3,1,-20),UDim2.new(0,0,0,10),C.accent); Corn(ac,2)
        -- Play butonu parıldaması
        local glow=Instance.new("UIGradient")
        glow.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(18,18,32)),
            ColorSequenceKeypoint.new(0.5,Color3.fromRGB(26,28,52)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(18,18,32)),
        })
        glow.Rotation=90; glow.Parent=b
    end
    mBtns[bd.k]=b
end

-- ── AÇILIŞ ANİMASYONU (logo fade, butonlar zaten görünür) ──
do
    bscLbl.TextTransparency=1; prisonLbl.TextTransparency=1
    sepLn.BackgroundTransparency=1; verLbl.TextTransparency=1
    btnHolder.GroupTransparency=1

    task.delay(0.15, function()
        tw(bscLbl,{TextTransparency=0},1,Enum.EasingStyle.Quad):Play()
        task.delay(0.5,function()
            tw(prisonLbl,{TextTransparency=0},.6):Play()
            tw(sepLn,{BackgroundTransparency=0},.6):Play()
            tw(verLbl,{TextTransparency=0},.6):Play()
            task.delay(0.25,function()
                tw(btnHolder,{GroupTransparency=0},.5,Enum.EasingStyle.Back):Play()
            end)
        end)
    end)
end

-- Fadeout / fadein
local fadeF=Fr("FadeF",SG,nil,nil,C.black,1); fadeF.ZIndex=100; fadeF.Visible=false
local function fadeOut(cb)
    fadeF.Visible=true; tw(fadeF,{BackgroundTransparency=0},.4):Play()
    task.delay(.45,function() if cb then cb() end end)
end
local function fadeIn()
    task.delay(.05,function() tw(fadeF,{BackgroundTransparency=1},.4):Play()
    task.delay(.5,function() fadeF.Visible=false end) end)
end

-- ════════════════════════════════════════════════════════════════
-- §2  OVERLAY PANELLERİ
-- ════════════════════════════════════════════════════════════════
local function makePanel(title)
    local ov=Fr(title.."Ov",SG,nil,nil,C.black,.78); ov.Visible=false; ov.ZIndex=40
    local pan=Fr("Pan",ov,UDim2.new(0,500,0,450),UDim2.new(0.5,-250,0.5,-225),C.panel)
    pan.ZIndex=41; Corn(pan,12); Strk(pan,C.border)
    local hdr=Fr("Hdr",pan,UDim2.new(1,0,0,50),nil,C.card); hdr.ZIndex=42; Corn(hdr,12)
    Fr("HF",hdr,UDim2.new(1,0,.5,0),UDim2.new(0,0,.5,0),C.card).ZIndex=42
    Lbl("T",hdr,title:upper(),UDim2.new(1,-56,1,0),UDim2.new(0,20,0,0),C.text,15,Enum.Font.GothamBold).ZIndex=43
    local xb=Btn("X",hdr,"✕",UDim2.new(0,32,0,32),UDim2.new(1,-40,.5,-16),C.btn,C.dim,14); xb.ZIndex=43
    local sc=ScFr("Sc",pan,UDim2.new(1,-28,1,-66),UDim2.new(0,14,0,60)); sc.ZIndex=42
    Instance.new("UIListLayout",sc).Padding=UDim.new(0,8)
    local BP=UDim2.new(0.5,-250,0.5,-225)
    local function show()
        pan.Position=UDim2.new(0.5,-250,.42,-225); pan.BackgroundTransparency=1; ov.Visible=true
        tw(ov,{BackgroundTransparency=.78},.25):Play()
        tw(pan,{BackgroundTransparency=0,Position=BP},.45,Enum.EasingStyle.Back):Play()
    end
    local function hide()
        tw(ov,{BackgroundTransparency=1},.2):Play()
        tw(pan,{Position=UDim2.new(0.5,-250,.58,-225)},.3,Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
        task.delay(.35,function() ov.Visible=false end)
    end
    xb.MouseButton1Click:Connect(hide)
    ov.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hide() end end)
    return sc, show, hide
end

local setScr,setShow,setHide = makePanel("Settings")
local logScr,logShow,logHide = makePanel("Patch Notes")
local rulScr,rulShow,rulHide = makePanel("Rules")
local crdScr,crdShow,crdHide= makePanel("Credits")

local function addEntry(scr, title, desc, col)
    local item=Fr("E",scr,UDim2.new(1,0,0,0),nil,C.card); item.AutomaticSize=Enum.AutomaticSize.Y; Corn(item,8); Strk(item,C.border); Pad(item,14); item.ZIndex=43
    Lbl("T",item,title,UDim2.new(1,0,0,18),nil,col or C.accentH,13,Enum.Font.GothamBold).ZIndex=44
    local d=Lbl("D",item,desc,UDim2.new(1,0,0,0),UDim2.new(0,0,0,20),C.dim,12); d.ZIndex=44; d.AutomaticSize=Enum.AutomaticSize.Y; d.TextWrapped=true; d.LineHeight=1.45
end

-- Ayarlar içerik
addEntry(setScr,"🎮 Graphics Quality","Lower graphics are recommended for smoother performance.",C.accentH)
addEntry(setScr,"🔊 Audio","In-game sound effects and music settings.",C.accentG)
addEntry(setScr,"🌐 Language","English / Turkish",C.accentH)
addEntry(setScr,"📷 Camera","Camera sensitivity and FOV settings.",C.accentG)

-- Log içerik
addEntry(logScr,"v3.0 ULTRA","• Bird-eye map preview\n• Advanced animation system\n• Keycard doors\n• Rope/Handcuff/Taser/Collar tools\n• Emote system\n• Enterable criminal base\n• Prison basement dungeon",C.neonG)
addEntry(logScr,"v2.0","• Improved map model\n• Team selection added\n• Loading screen animation",C.accentH)
addEntry(logScr,"v1.0","• Initial release",C.dim)

-- Kurallar
addEntry(rulScr,"⚠ Rule 1","Be respectful to others. Insults are not allowed.",C.accentR)
addEntry(rulScr,"⚠ Rule 2","Using bug exploits is prohibited.",C.accentR)
addEntry(rulScr,"✅ Rule 3","Use proper animations while restraining players.",C.accentG)
addEntry(rulScr,"✅ Rule 4","Criminal team cannot enter police HQ.",C.accentG)
addEntry(rulScr,"ℹ Rule 5","Admin decisions are final.",C.accentH)

-- Credits
addEntry(crdScr,"👑 BSC Studios","Core development team",C.accentH)
addEntry(crdScr,"🎨 Design","UI/UX — premium design system",C.neonG)
addEntry(crdScr,"🗺 Map","Detailed prison environment design",C.cyan)

mBtns.Settings.MouseButton1Click:Connect(setShow)
mBtns.Logs.MouseButton1Click:Connect(logShow)
mBtns.Rules.MouseButton1Click:Connect(rulShow)
mBtns.Credits.MouseButton1Click:Connect(crdShow)

-- ════════════════════════════════════════════════════════════════
-- §3  KARAKTER OLUŞTURMA
-- ════════════════════════════════════════════════════════════════
local CC=Fr("CC",SG,nil,nil,C.bg); CC.Visible=false; CC.ZIndex=20

-- Karakter viewport
local CV=Instance.new("ViewportFrame"); CV.Name="CV"
CV.Size=UDim2.new(0,280,1,0); CV.BackgroundColor3=Color3.fromRGB(10,10,16)
CV.Ambient=Color3.fromRGB(120,125,150); CV.LightColor=Color3.fromRGB(200,205,230)
CV.LightDirection=Vector3.new(-0.5,-1,-0.3); CV.ZIndex=21; CV.Parent=CC
local cvCam=Instance.new("Camera"); cvCam.CameraType=Enum.CameraType.Scriptable; cvCam.Parent=CV; CV.CurrentCamera=cvCam
cvCam.CFrame=CFrame.lookAt(Vector3.new(0,5,10),Vector3.new(0,5,0))

-- Dummy model
local dummyModel=Instance.new("Model"); dummyModel.Name="Dummy"; dummyModel.Parent=CV
local function buildDummy(gender)
    dummyModel:ClearAllChildren()
    local function dp(nm,sz,cf,col) local p=Instance.new("Part");p.Name=nm;p.Size=sz;p.CFrame=CFrame.new(cf);p.BrickColor=BrickColor.new(col or "Bright orange");p.Anchored=true;p.CanCollide=false;p.Parent=dummyModel;return p end
    dp("Head",Vector3.new(2,2,2),Vector3.new(0,8,0),"Peach")
    dp("Torso",Vector3.new(2,2,1),Vector3.new(0,5.5,0),gender=="Male" and "Bright blue" or "Hot pink")
    dp("LArm",Vector3.new(1,2,1),Vector3.new(-1.5,5.5,0),"Bright orange")
    dp("RArm",Vector3.new(1,2,1),Vector3.new(1.5,5.5,0),"Bright orange")
    dp("LLeg",Vector3.new(1,2,1),Vector3.new(-0.5,3,0),"Medium blue")
    dp("RLeg",Vector3.new(1,2,1),Vector3.new(0.5,3,0),"Medium blue")
    dummyModel.PrimaryPart=dummyModel:FindFirstChild("Torso")
end
buildDummy("Male")

-- Sağ panel
local CP=Fr("CP",CC,UDim2.new(1,-290,1,0),UDim2.new(0,280,0,0),C.panel); CP.ZIndex=21; Strk(CP,C.border)
addPanelGloss(CP)
Pad(CP,nil,30,30,30,30)

-- Adım göstergesi
local stepW=Fr("SW",CP,UDim2.new(1,0,0,8),UDim2.new(0,0,0,0),C.black,1); stepW.ZIndex=22
local bHL2=Instance.new("UIListLayout"); bHL2.FillDirection=Enum.FillDirection.Horizontal; bHL2.Padding=UDim.new(0,6); bHL2.Parent=stepW
local DOTS={}
for i=1,3 do
    local d=Fr("D"..i,stepW,UDim2.new(0,8,0,5),nil,i==1 and C.accent or C.border); Corn(d,3); d.ZIndex=23
    DOTS[i]=d
end

local sTitle=Lbl("ST",CP,"",UDim2.new(1,0,0,28),UDim2.new(0,0,0,18),C.text,18,Enum.Font.GothamBlack); sTitle.ZIndex=22
local sSub=Lbl("SS",CP,"",UDim2.new(1,0,0,16),UDim2.new(0,0,0,48),C.dim,12); sSub.ZIndex=22

-- Step container
local stepsW=Fr("StW",CP,UDim2.new(1,0,1,-130),UDim2.new(0,0,0,72),C.black,1); stepsW.ClipsDescendants=true; stepsW.ZIndex=22
local STEPS={}
for i=1,3 do
    local s=Fr("S"..i,stepsW,UDim2.new(1,0,1,0),UDim2.new(i-1,0,0,0),C.black,1); s.ZIndex=22; STEPS[i]=s
end

-- Adım 1 – Kişisel
local iFirst,iFirstW = Inp("FName",STEPS[1],"First Name",UDim2.new(1,0,0,40),UDim2.new(0,0,0,0))
iFirstW.ZIndex=23
local iLast,iLastW = Inp("LName",STEPS[1],"Last Name",UDim2.new(1,0,0,40),UDim2.new(0,0,0,50))
iLastW.ZIndex=23
local iAge,iAgeW = Inp("Age",STEPS[1],"Age",UDim2.new(0.45,0,0,40),UDim2.new(0,0,0,100))
iAgeW.ZIndex=23
-- Cinsiyet
local genderW=Fr("GW",STEPS[1],UDim2.new(1,0,0,40),UDim2.new(0,0,0,152),C.black,1); genderW.ZIndex=22
local gM=Btn("GM",genderW,"♂ Male",UDim2.new(.48,0,1,0),nil,C.accent,C.white,12); gM.ZIndex=23
local gF=Btn("GF",genderW,"♀ Female",UDim2.new(.48,0,1,0),UDim2.new(.52,0,0,0),C.btn,C.dim,12); gF.ZIndex=23
gM.MouseButton1Click:Connect(function() charData.gender="Male"; tw(gM,{BackgroundColor3=C.accent},.2):Play(); tw(gF,{BackgroundColor3=C.btn},.2):Play(); tw(gM,{TextColor3=C.white},.2):Play(); tw(gF,{TextColor3=C.dim},.2):Play(); buildDummy("Male") end)
gF.MouseButton1Click:Connect(function() charData.gender="Female"; tw(gF,{BackgroundColor3=C.accent},.2):Play(); tw(gM,{BackgroundColor3=C.btn},.2):Play(); tw(gF,{TextColor3=C.white},.2):Play(); tw(gM,{TextColor3=C.dim},.2):Play(); buildDummy("Female") end)

-- Adım 2 – Görünüm
Lbl("HL",STEPS[2],"HAIR STYLE",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.dim,10,Enum.Font.GothamBold).ZIndex=23
local hScr=Instance.new("ScrollingFrame"); hScr.Name="HS"; hScr.Size=UDim2.new(1,0,0,82); hScr.Position=UDim2.new(0,0,0,18)
hScr.BackgroundTransparency=1; hScr.BorderSizePixel=0; hScr.ScrollBarThickness=2; hScr.ScrollingDirection=Enum.ScrollingDirection.X
hScr.CanvasSize=UDim2.new(0,0,0,0); hScr.AutomaticCanvasSize=Enum.AutomaticSize.X; hScr.ZIndex=23; hScr.Parent=STEPS[2]
Instance.new("UIListLayout",hScr).FillDirection=Enum.FillDirection.Horizontal
Lbl("FL",STEPS[2],"FACE STYLE",UDim2.new(1,0,0,16),UDim2.new(0,0,0,106),C.dim,10,Enum.Font.GothamBold).ZIndex=23
local fScr=Instance.new("ScrollingFrame"); fScr.Name="FS"; fScr.Size=UDim2.new(1,0,0,82); fScr.Position=UDim2.new(0,0,0,124)
fScr.BackgroundTransparency=1; fScr.BorderSizePixel=0; fScr.ScrollBarThickness=2; fScr.ScrollingDirection=Enum.ScrollingDirection.X
fScr.CanvasSize=UDim2.new(0,0,0,0); fScr.AutomaticCanvasSize=Enum.AutomaticSize.X; fScr.ZIndex=23; fScr.Parent=STEPS[2]
Instance.new("UIListLayout",fScr).FillDirection=Enum.FillDirection.Horizontal

local hairRefs,faceRefs={},{}
local function refreshHair()
    for _,v in ipairs(hScr:GetChildren())do if v:IsA("TextButton")then v:Destroy()end end; hairRefs={}
    for i,opt in ipairs(HAIR_IDS[charData.gender] or HAIR_IDS.Male) do
        local b=Btn("H"..i,hScr,opt.name,UDim2.new(0,74,0,74),nil,i==charData.hair and Color3.fromRGB(22,22,40) or C.card,C.dim,10)
        b.ZIndex=24; b.TextWrapped=true; b.Font=Enum.Font.Gotham
        local s=Strk(b,i==charData.hair and C.accent or C.border); hairRefs[i]={b=b,s=s}
        b.MouseButton1Click:Connect(function() charData.hair=i; for j,d in ipairs(hairRefs)do tw(d.b,{BackgroundColor3=j==i and Color3.fromRGB(22,22,40) or C.card},.2):Play(); tw(d.s,{Color=j==i and C.accent or C.border},.2):Play() end end)
    end
end
local function refreshFace()
    for _,v in ipairs(fScr:GetChildren())do if v:IsA("TextButton")then v:Destroy()end end; faceRefs={}
    for i,opt in ipairs(FACE_IDS) do
        local b=Btn("F"..i,fScr,opt.name,UDim2.new(0,74,0,74),nil,i==charData.face and Color3.fromRGB(22,22,40) or C.card,C.dim,10)
        b.ZIndex=24; b.TextWrapped=true; b.Font=Enum.Font.Gotham
        local s=Strk(b,i==charData.face and C.accent or C.border); faceRefs[i]={b=b,s=s}
        b.MouseButton1Click:Connect(function() charData.face=i; for j,d in ipairs(faceRefs)do tw(d.b,{BackgroundColor3=j==i and Color3.fromRGB(22,22,40) or C.card},.2):Play(); tw(d.s,{Color=j==i and C.accent or C.border},.2):Play() end end)
    end
end
refreshHair(); refreshFace()

-- Adım 3
local confC=Fr("CC3",STEPS[3],UDim2.new(1,0,1,-36),nil,C.card); Corn(confC,8); Strk(confC,C.border); Pad(confC,14); confC.ZIndex=22
local confI=Lbl("CI",confC,"",UDim2.new(1,0,1,0),nil,C.dim,13,Enum.Font.Gotham); confI.ZIndex=23; confI.TextWrapped=true; confI.TextYAlignment=Enum.TextYAlignment.Top; confI.LineHeight=1.65
Lbl("WL",STEPS[3],"⚠  These details cannot be changed after confirmation.",UDim2.new(1,0,0,22),UDim2.new(0,0,1,-30),Color3.fromRGB(185,140,50),11).TextWrapped=true

-- Nav
local navW=Fr("Nav",CP,UDim2.new(1,0,0,46),UDim2.new(0,0,1,-70),C.black,1); navW.ZIndex=22
local backB=Btn("Back",navW,"← BACK",UDim2.new(.46,0,1,0),nil,C.btn,C.dim,12); backB.ZIndex=23
local nextB=Btn("Next",navW,"NEXT →",UDim2.new(.46,0,1,0),UDim2.new(.54,0,0,0),Color3.fromRGB(16,20,40),C.accentH,12); nextB.ZIndex=23

local STITLES={"PERSONAL DETAILS","APPEARANCE","CONFIRM"}
local SSUBS={"These details cannot be edited later.","Choose your hair and face style.","Check your information before continuing."}

local doShowLoading, doShowTeamSel

local function setStep(n)
    currentStep=n; sTitle.Text=STITLES[n]; sSub.Text=SSUBS[n]
    for i,d in ipairs(DOTS)do tw(d,{BackgroundColor3=i<=n and C.accent or C.border,Size=UDim2.new(0,i==n and 18 or 8,0,5)},.25):Play() end
    for i,s in ipairs(STEPS)do tw(s,{Position=UDim2.new(i-n,0,0,0)},.4,Enum.EasingStyle.Quart):Play() end
    backB.Visible=(n>1)
    if n==3 then
        nextB.Text="✓ CONFIRM"; tw(nextB,{BackgroundColor3=Color3.fromRGB(14,40,18)},.3):Play()
        confI.Text=("Name      : %s %s\nAge         : %s\nGender   : %s\nHair        : %s\nFace        : %s"):format(
            charData.firstName,charData.lastName,charData.age,
            charData.gender=="Male" and "Male" or "Female",
            (HAIR_IDS[charData.gender] or HAIR_IDS.Male)[charData.hair].name,
            FACE_IDS[charData.face].name)
    else nextB.Text="NEXT →"; tw(nextB,{BackgroundColor3=Color3.fromRGB(16,20,40)},.3):Play() end
    if n==2 then refreshHair(); refreshFace() end
end

local function shake()
    for i=1,8 do task.delay(i*.045,function() CP.Position=UDim2.new(0,i<7 and(i%2==0 and 7 or -7)*(8-i)/1.4 or 0,0,0) end) end
end

backB.MouseButton1Click:Connect(function() if currentStep>1 then setStep(currentStep-1) end end)
nextB.MouseButton1Click:Connect(function()
    if currentStep==1 then
        if iFirst.Text==""or iLast.Text==""or iAge.Text=="" then shake();return end
        charData.firstName=iFirst.Text;charData.lastName=iLast.Text;charData.age=tonumber(iAge.Text) or 18;setStep(2)
    elseif currentStep==2 then setStep(3)
    else doShowLoading() end
end)

mBtns.Play.MouseButton1Click:Connect(function()
    fadeOut(function()
        MM.Visible=false; CC.Visible=true; currentStep=1; setStep(1); buildDummy(charData.gender); fadeIn()
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- §4  LOADING SCREEN
-- ════════════════════════════════════════════════════════════════
local LS=Fr("LS",SG,nil,nil,C.bg); LS.Visible=false; LS.ZIndex=60
local lsLogo=Lbl("Logo",LS,"BSC PRISON",UDim2.new(0,550,0,60),UDim2.new(.5,-275,.5,-88),C.text,52,Enum.Font.GothamBlack,Enum.TextXAlignment.Center); lsLogo.ZIndex=61
local lsMsg=Lbl("Msg",LS,"Loading…",UDim2.new(0,440,0,20),UDim2.new(.5,-220,.5,4),C.dim,13,Enum.Font.Gotham,Enum.TextXAlignment.Center); lsMsg.ZIndex=61
local lsBB=Fr("BB",LS,UDim2.new(0,360,0,4),UDim2.new(.5,-180,.5,32),Color3.fromRGB(16,16,26)); lsBB.ZIndex=61; Corn(lsBB,3)
local lsBar=Fr("Bar",lsBB,UDim2.new(0,0,1,0),nil,C.accent); lsBar.ZIndex=62; Corn(lsBar,3)
-- Animasyonlu bar parıltısı
local lsGlow=Fr("BG",lsBar,UDim2.new(0,30,1,0),UDim2.new(1,-10,0,0),C.accentH,0.5); Corn(lsGlow,3)
local lsPct=Lbl("Pct",LS,"0%",UDim2.new(0,90,0,16),UDim2.new(.5,-45,.5,44),C.dim,12,Enum.Font.Gotham,Enum.TextXAlignment.Center); lsPct.ZIndex=61
local LS_MSGS={"Booting security systems…","Preparing cell registry…","Dispatching guards…","Preparing security protocols…","Validating inmate records…","Running final checks…","Locking secure doors…"}

local CLS=Fr("CharacterLoading",SG,nil,nil,C.black,0.22); CLS.Visible=false; CLS.ZIndex=76
local clCard=Fr("Card",CLS,UDim2.new(0,500,0,180),UDim2.new(.5,-250,.5,-90),C.panel,0.03); clCard.ZIndex=77; Corn(clCard,14); Strk(clCard,C.border,1.5)
Lbl("Title",clCard,"PREPARING YOUR CHARACTER",UDim2.new(1,-40,0,32),UDim2.new(0,20,0,16),C.text,18,Enum.Font.GothamBold,Enum.TextXAlignment.Left).ZIndex=78
local clDesc=Lbl("Desc",clCard,"Spawning avatar, syncing animations, and loading role tools…",UDim2.new(1,-40,0,42),UDim2.new(0,20,0,50),C.dim,12,Enum.Font.Gotham,Enum.TextXAlignment.Left)
clDesc.ZIndex=78; clDesc.TextWrapped=true
local clBarBg=Fr("BarBg",clCard,UDim2.new(1,-40,0,8),UDim2.new(0,20,1,-32),Color3.fromRGB(28,28,40)); clBarBg.ZIndex=78; Corn(clBarBg,4)
local clBar=Fr("Bar",clBarBg,UDim2.new(0,0,1,0),nil,C.accent); clBar.ZIndex=79; Corn(clBar,4)

local function showCharacterLoading(onDone)
    CLS.Visible=true
    clBar.Size=UDim2.new(0,0,1,0)
    local progress, started = 0, tick()
    local conn
    conn = RunSvc.RenderStepped:Connect(function(dt)
        progress = math.min(0.94, progress + dt*0.35)
        clBar.Size = UDim2.new(progress,0,1,0)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if (hum and hrp and (tick()-started) > 0.7) or (tick()-started) > 7 then
            conn:Disconnect()
            tw(clBar,{Size=UDim2.new(1,0,1,0)},.2):Play()
            task.delay(.25,function()
                tw(CLS,{BackgroundTransparency=1},.22):Play()
                task.delay(.24,function()
                    CLS.Visible=false
                    CLS.BackgroundTransparency=0.22
                    if onDone then onDone() end
                end)
            end)
        end
    end)
end

doShowLoading=function()
    pcall(function() if BSC_RE then BSC_RE.CreateCharacter:FireServer(charData) end end)
    CC.Visible=false; LS.Visible=true; lsBar.Size=UDim2.new(0,0,1,0)
    local prog=0; local mi=0
    local function tick()
        if prog>=1 then task.delay(.45,function() LS.Visible=false; doShowTeamSel() end); return end
        prog=math.min(1,prog+(math.random(5,14)/100)); mi=math.min(mi+1,#LS_MSGS)
        tw(lsBar,{Size=UDim2.new(prog,0,1,0)},.44):Play()
        lsPct.Text=math.floor(prog*100).."%"; lsMsg.Text=LS_MSGS[mi]
        task.delay(.44+math.random()*.25,tick)
    end
    task.delay(.15,tick)
end

-- ════════════════════════════════════════════════════════════════
-- §5  TAKIM SEÇİMİ
-- ════════════════════════════════════════════════════════════════
local TS=Fr("TS",SG,nil,nil,C.bg); TS.Visible=false; TS.ZIndex=70
Lbl("TT",TS,"CHOOSE YOUR ROLE",UDim2.new(0,660,0,50),UDim2.new(.5,-330,0,30),C.text,32,Enum.Font.GothamBlack,Enum.TextXAlignment.Center).LetterSpacing=10
Lbl("TSb",TS,"Choose carefully — this decision changes your gameplay.",UDim2.new(0,540,0,20),UDim2.new(.5,-270,0,88),C.dim,13,Enum.Font.Gotham,Enum.TextXAlignment.Center)

local TEAMS_CFG = {
    {n="Cop",      icon="🚔",tag="GUARD",    desc="Enforce the law.\nProtect order.\nControl inmates.",          col=Color3.fromRGB(10,24,70), acc=Color3.fromRGB(50,90,215)},
    {n="Prisoner", icon="⛓", tag="PRISONER", desc="Serve your sentence.\nFind allies.\nPlan your escape.",      col=Color3.fromRGB(58,32,6),  acc=Color3.fromRGB(195,122,35)},
    {n="Criminal", icon="💀",tag="CRIMINAL", desc="Break the rules.\nLead the riot.\nCreate chaos.",            col=Color3.fromRGB(44,6,6),   acc=Color3.fromRGB(175,30,30)},
    {n="Hostage",  icon="🙏",tag="HOSTAGE",  desc="Survive at all costs.\nUse innocence smartly.\nStay safe.",  col=Color3.fromRGB(8,36,14),  acc=Color3.fromRGB(38,130,52)},
}
local CW,CG=222,16; local totalW=#TEAMS_CFG*(CW+CG)-CG
local cardW=Fr("CW",TS,UDim2.new(0,totalW,0,280),UDim2.new(.5,-totalW/2,.5,-115),C.black,1); cardW.ZIndex=71
addPanelGloss(cardW)

for i,td in ipairs(TEAMS_CFG) do
    local xP=(i-1)*(CW+CG)
    local c=Fr("C"..td.n,cardW,UDim2.new(0,CW,1,0),UDim2.new(0,xP,0,0),td.col); c.ZIndex=72; Corn(c,12)
    local cs=Strk(c,Color3.fromRGB(30,30,44))
    -- Üst accent çizgi
    local bar=Fr("Bar",c,UDim2.new(1,0,0,5),nil,td.acc); Corn(bar,12)
    Fr("BF",bar,UDim2.new(1,0,.5,0),UDim2.new(0,0,.5,0),td.acc)
    -- İkon
    Lbl("Ico",c,td.icon,UDim2.new(1,0,0,52),UDim2.new(0,0,0,16),C.white,34,Enum.Font.GothamBold,Enum.TextXAlignment.Center).ZIndex=73
    local tl=Lbl("Tag",c,td.tag,UDim2.new(1,-16,0,15),UDim2.new(0,8,0,72),td.acc,10,Enum.Font.GothamBold,Enum.TextXAlignment.Center); tl.ZIndex=73; tl.LetterSpacing=5
    Lbl("Nm",c,td.n:upper(),UDim2.new(1,-16,0,22),UDim2.new(0,8,0,90),C.text,16,Enum.Font.GothamBlack,Enum.TextXAlignment.Center).ZIndex=73
    local dl=Lbl("Ds",c,td.desc,UDim2.new(1,-20,0,65),UDim2.new(0,10,0,116),C.dim,11,Enum.Font.Gotham,Enum.TextXAlignment.Center); dl.ZIndex=73; dl.TextWrapped=true; dl.LineHeight=1.5
    local sb=Btn("Sel",c,"SELECT",UDim2.new(1,-24,0,38),UDim2.new(0,12,1,-50),Color3.new(td.acc.R*.2,td.acc.G*.2,td.acc.B*.2),td.acc,12)
    sb.ZIndex=73; sb.Font=Enum.Font.GothamBold
    c.MouseEnter:Connect(function() tw(c,{Size=UDim2.new(0,CW+10,1,12),Position=UDim2.new(0,xP-5,0,-6)},.22):Play(); tw(cs,{Color=td.acc},.22):Play() end)
    c.MouseLeave:Connect(function() tw(c,{Size=UDim2.new(0,CW,1,0),Position=UDim2.new(0,xP,0,0)},.2):Play(); tw(cs,{Color=Color3.fromRGB(30,30,44)},.2):Play() end)
    sb.MouseButton1Click:Connect(function()
        pcall(function() if BSC_RE then BSC_RE.SelectTeam:FireServer(td.n) end end)
        tw(TS,{BackgroundTransparency=1},.5):Play()
        task.delay(.55,function()
            TS.Visible=false
            showCharacterLoading(function()
                showHUD(td.n)
            end)
        end)
    end)
end

doShowTeamSel=function()
    TS.Visible=true; TS.BackgroundTransparency=1; tw(TS,{BackgroundTransparency=0},.45):Play()
    for i,c in ipairs(cardW:GetChildren())do
        if c:IsA("Frame") then
            local op=c.Position; c.Position=UDim2.new(op.X.Scale,op.X.Offset,op.Y.Scale+.18,op.Y.Offset); c.BackgroundTransparency=1
            task.delay(i*.07,function() tw(c,{Position=op,BackgroundTransparency=0},.45,Enum.EasingStyle.Back):Play() end)
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- §6  HUD
-- ════════════════════════════════════════════════════════════════
local HUD=Fr("HUD",SG,nil,nil,C.black,1); HUD.Visible=false; HUD.ZIndex=5

local riotW=Fr("RW",HUD,UDim2.new(0,175,0,46),UDim2.new(0,14,1,-64),C.black,1); riotW.Visible=false; riotW.ZIndex=6
local riotB=Btn("RB",riotW,"⚡  START RIOT",UDim2.new(1,0,1,0),nil,C.danger,C.dangerH,12); riotB.ZIndex=7; riotB.Font=Enum.Font.GothamBold; Strk(riotB,Color3.fromRGB(105,20,20))

local rPop=Fr("RPop",HUD,UDim2.new(0,380,0,210),UDim2.new(.5,-190,.5,-105),Color3.fromRGB(8,4,4)); rPop.Visible=false; rPop.ZIndex=30; Corn(rPop,12); Strk(rPop,Color3.fromRGB(85,16,16)); Pad(rPop,22)
Lbl("RI",rPop,"⚠",UDim2.new(1,0,0,32),nil,Color3.fromRGB(220,100,38),28,Enum.Font.GothamBold,Enum.TextXAlignment.Center).ZIndex=31
Lbl("RT",rPop,"RIOT WARNING",UDim2.new(1,0,0,22),UDim2.new(0,0,0,38),C.dangerH,15,Enum.Font.GothamBold,Enum.TextXAlignment.Center).ZIndex=31
local rD=Lbl("RD",rPop,"You will no longer be treated as innocent.\nPolice will mark you as an active threat.",UDim2.new(1,0,0,44),UDim2.new(0,0,0,66),Color3.fromRGB(150,80,80),12); rD.ZIndex=31; rD.TextWrapped=true; rD.TextXAlignment=Enum.TextXAlignment.Center
local rConf=Btn("RC",rPop,"JOIN RIOT",UDim2.new(.48,0,0,38),UDim2.new(0,0,1,-42),C.danger,C.dangerH,11); rConf.ZIndex=31; rConf.Font=Enum.Font.GothamBold
local rCanc=Btn("RX",rPop,"CANCEL",UDim2.new(.48,0,0,38),UDim2.new(.52,0,1,-42),C.btn,C.dim,11); rCanc.ZIndex=31

local function openRiot() rPop.Visible=true; rPop.BackgroundTransparency=1; rPop.Position=UDim2.new(.5,-190,.43,-105); tw(rPop,{BackgroundTransparency=0,Position=UDim2.new(.5,-190,.5,-105)},.3,Enum.EasingStyle.Back):Play() end
local function closeRiot() tw(rPop,{BackgroundTransparency=1},.2):Play(); task.delay(.22,function() rPop.Visible=false end) end
riotB.MouseButton1Click:Connect(openRiot); rCanc.MouseButton1Click:Connect(closeRiot)
rConf.MouseButton1Click:Connect(function()
    if isRioting then return end; isRioting=true
    pcall(function() if BSC_RE then BSC_RE.StartRiot:FireServer() end end)
    closeRiot(); tw(riotB,{BackgroundColor3=Color3.fromRGB(95,14,14)},.3):Play()
    riotB.Text="⚡  RIOT ACTIVE"; riotB.Active=false
end)

-- Sağ panel toggle
local spT=Btn("SPT",HUD,"❮",UDim2.new(0,28,0,78),UDim2.new(1,-44,.5,-39),Color3.fromRGB(9,9,14),C.dim,14); spT.ZIndex=6; Strk(spT,C.border)
local SP=Fr("SP",HUD,UDim2.new(0,274,1,-86),UDim2.new(1,0,0,43),Color3.fromRGB(7,7,11)); SP.ZIndex=6; SP.ClipsDescendants=true; Strk(SP,C.border)
addPanelGloss(SP)
local tabBar=Fr("TB",SP,UDim2.new(1,0,0,38),nil,Color3.fromRGB(9,9,14)); tabBar.ZIndex=7
local TABS={"Emotes","Inventory","Solve","Tools"}; local tabBs,tabCs={},{}
for i,tn in ipairs(TABS) do
    local tb=Btn("T"..tn,tabBar,tn,UDim2.new(1/#TABS,0,1,0),UDim2.new((i-1)/#TABS,0,0,0),i==1 and C.card or Color3.fromRGB(9,9,14),i==1 and C.text or C.dim,10); tb.ZIndex=8; tabBs[tn]=tb
    local tc=Fr("TC"..tn,SP,UDim2.new(1,0,1,-38),UDim2.new(0,0,0,38),C.black,1); tc.Visible=(i==1); tc.ZIndex=7; tabCs[tn]=tc
end
local tabInd=Fr("TI",tabBar,UDim2.new(1/#TABS,-4,0,2.5),UDim2.new(0,2,1,-2.5),C.accent); Corn(tabInd,1.5); tabInd.ZIndex=9
for _,tn in ipairs(TABS) do
    tabBs[tn].MouseButton1Click:Connect(function()
        for _,t in ipairs(TABS)do local a=t==tn; tw(tabBs[t],{BackgroundColor3=a and C.card or Color3.fromRGB(9,9,14)},.2):Play(); tw(tabBs[t],{TextColor3=a and C.text or C.dim},.2):Play(); tabCs[t].Visible=a end
        tw(tabInd,{Position=UDim2.new((table.find(TABS,tn)-1)/#TABS,2,1,-2.5)},.2):Play()
    end)
end

-- ════════════════════════════════════════════════════════════════
-- §7  EMOTES SİSTEMİ (CFrame animasyonları)
-- ════════════════════════════════════════════════════════════════
local emoteActive = false
local emoteConn   = nil

-- CFrame tabanlı animasyon uygulaması
local function applyEmote(emoteName)
    local char = lp.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    -- Mevcut emote'u iptal et
    if emoteConn then emoteConn:Disconnect(); emoteConn=nil end
    if emoteActive then
        emoteActive = false
        hum.WalkSpeed = 16; hum.JumpPower = 50
        return
    end

    emoteActive = true
    hum.WalkSpeed = 0; hum.JumpPower = 0

    local t = 0
    local function getMotor(partName)
        return char:FindFirstChild(partName) and char:FindFirstChild(partName):FindFirstChildOfClass("Motor6D")
    end

    -- Motor6D bazlı animasyon hedefleri
    local EMOTE_ANIMS = {
        kneel = {
            -- Diz çökme pozisyonu
            LowerTorso = CFrame.new(0,-1.5,0) * CFrame.Angles(math.rad(-30),0,0),
            LeftUpperLeg = CFrame.Angles(math.rad(-60),0,math.rad(-5)),
            RightUpperLeg = CFrame.Angles(math.rad(-60),0,math.rad(5)),
            LeftLowerLeg = CFrame.Angles(math.rad(80),0,0),
            RightLowerLeg = CFrame.Angles(math.rad(80),0,0),
        },
        sit = {
            LowerTorso = CFrame.new(0,-0.5,0),
            LeftUpperLeg = CFrame.Angles(math.rad(-90),0,math.rad(-10)),
            RightUpperLeg = CFrame.Angles(math.rad(-90),0,math.rad(10)),
            LeftLowerLeg = CFrame.Angles(math.rad(90),0,0),
            RightLowerLeg = CFrame.Angles(math.rad(90),0,0),
        },
        sleep = {
            LowerTorso = CFrame.new(0,-3,0) * CFrame.Angles(math.rad(-90),0,0),
            UpperTorso = CFrame.Angles(math.rad(5),0,0),
        },
        layside = {
            LowerTorso = CFrame.new(1,-2,0) * CFrame.Angles(0,0,math.rad(-90)),
            UpperTorso = CFrame.Angles(0,0,0),
        },
        dance = "loop", -- Özel döngü
        wave  = "loop",
        pray  = {
            LeftUpperArm = CFrame.Angles(math.rad(-60),math.rad(20),0),
            RightUpperArm = CFrame.Angles(math.rad(-60),math.rad(-20),0),
        },
        think = {
            RightUpperArm = CFrame.Angles(math.rad(-40),0,math.rad(-30)),
            Head = CFrame.Angles(math.rad(-10),math.rad(15),0),
        },
    }

    local animDef = EMOTE_ANIMS[emoteName]

    -- CFrame Motor6D animasyonu (R15 uyumlu)
    if type(animDef) == "table" then
        emoteConn = RunSvc.RenderStepped:Connect(function(dt)
            t = t + dt
            for motorName, targetCF in pairs(animDef) do
                local part = char:FindFirstChild(motorName)
                if part then
                    local motor = part:FindFirstChildOfClass("Motor6D")
                    if motor then
                        motor.C0 = motor.C0:Lerp(
                            CFrame.new(motor.C0.Position) * targetCF,
                            math.min(dt * 8, 1)
                        )
                    end
                end
            end
        end)
    elseif emoteName == "dance" then
        -- Dans döngüsü
        emoteConn = RunSvc.RenderStepped:Connect(function(dt)
            t = t + dt * 3
            local char2 = lp.Character; if not char2 then return end
            local parts = {
                {name="UpperTorso",  cf=CFrame.Angles(0, math.sin(t)*0.3, math.sin(t*1.5)*0.2)},
                {name="LeftUpperArm",cf=CFrame.Angles(math.sin(t)*0.6, 0, math.rad(-40)+math.sin(t)*0.4)},
                {name="RightUpperArm",cf=CFrame.Angles(math.sin(t+math.pi)*0.6,0,math.rad(40)+math.sin(t+math.pi)*0.4)},
            }
            for _,pd in ipairs(parts) do
                local part = char2:FindFirstChild(pd.name)
                if part then local m=part:FindFirstChildOfClass("Motor6D"); if m then m.C0=m.C0:Lerp(CFrame.new(m.C0.Position)*pd.cf,dt*5) end end
            end
        end)
    elseif emoteName == "wave" then
        emoteConn = RunSvc.RenderStepped:Connect(function(dt)
            t = t + dt * 4
            local char2 = lp.Character; if not char2 then return end
            local rArm = char2:FindFirstChild("RightUpperArm")
            if rArm then local m=rArm:FindFirstChildOfClass("Motor6D"); if m then m.C0=m.C0:Lerp(CFrame.new(m.C0.Position)*CFrame.Angles(math.rad(-90)+math.sin(t)*0.4,0,math.rad(30)),dt*8) end end
        end)
    end

    -- Zıplamada emote boz
    local jumpConn; jumpConn = UIS.JumpRequest:Connect(function()
        if emoteActive then
            emoteActive=false; hum.WalkSpeed=16; hum.JumpPower=50
            if emoteConn then emoteConn:Disconnect(); emoteConn=nil end
            if jumpConn then jumpConn:Disconnect() end
        end
    end)
end

-- Emotes Tab UI
local emC = tabCs["Emotes"]; Pad(emC,8)
local emScroll = ScFr("EmSc",emC); emScroll.ZIndex=8
local emGrid = Instance.new("UIGridLayout"); emGrid.CellSize=UDim2.new(0,70,0,70); emGrid.CellPadding=UDim2.new(0,7,0,7); emGrid.Parent=emScroll

local EMOTE_LIST = {
    {icon="🙏",name="pray",    lbl="Dua"},
    {icon="💃",name="dance",   lbl="Dans"},
    {icon="👋",name="wave",    lbl="El Sal."},
    {icon="🤔",name="think",   lbl="Think"},
    {icon="😴",name="sleep",   lbl="Uyu"},
    {icon="🧎",name="kneel",   lbl="Kneel"},
    {icon="🪑",name="sit",     lbl="Otur"},
    {icon="↔️", name="layside", lbl="Yan Yat"},
    {icon="😂",name="laugh",   lbl="Laugh"},
    {icon="✌️", name="peace",   lbl="Peace"},
    {icon="👊",name="punch",   lbl="Yumruk"},
    {icon="🤝",name="greet",   lbl="Selamla"},
}
for _,em in ipairs(EMOTE_LIST) do
    local b=Btn("E_"..em.name,emScroll,em.icon.."\n"..em.lbl,nil,nil,C.card,C.dim,10)
    b.TextWrapped=true; b.ZIndex=9; b.Font=Enum.Font.Gotham; b.TextSize=10
    Strk(b,C.border)
    b.MouseButton1Click:Connect(function()
        applyEmote(em.name)
        -- Aktif emote renklendirme
        for _,child in ipairs(emScroll:GetChildren())do
            if child:IsA("TextButton") then
                tw(child,{BackgroundColor3=emoteActive and child==b and C.accent or C.card},.2):Play()
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- §8  TOOLS TAB (Polis araçları UI)
-- ════════════════════════════════════════════════════════════════
local toolC=tabCs["Tools"]; Pad(toolC,10)
local toolScroll=ScFr("ToolSc",toolC); toolScroll.ZIndex=8
Instance.new("UIListLayout",toolScroll).Padding=UDim.new(0,8)

local TOOL_INFO = {
    {name="Keycard",   icon="🪪", desc="Opens keycard doors.", col=C.cyan},
    {name="Handcuffs", icon="⛓",  desc="Handcuffs the target. Get close and press E.", col=C.dim},
    {name="Rope",      icon="🪢",  desc="Tie a target with rope. Animated.", col=Color3.fromRGB(160,120,60)},
    {name="Taser",     icon="⚡",  desc="Temporarily stuns the target.", col=Color3.fromRGB(255,220,0)},
    {name="Collar",    icon="📿",  desc="Attach a collar for hostage control.", col=Color3.fromRGB(180,60,60)},
    {name="Radio",     icon="📻",  desc="Team communication. Use: [G]", col=C.accentH},
}

for _,ti in ipairs(TOOL_INFO) do
    local item=Fr("TI_"..ti.name,toolScroll,UDim2.new(1,0,0,58),nil,C.card); Corn(item,8); Strk(item,C.border); Pad(item,nil,12,12,8,8); item.ZIndex=8
    local ico=Lbl("Ic",item,ti.icon,UDim2.new(0,30,1,0),nil,ti.col,20,Enum.Font.GothamBold,Enum.TextXAlignment.Center); ico.ZIndex=9
    Lbl("TN",item,ti.name,UDim2.new(1,-42,0,18),UDim2.new(0,36,0,2),C.text,13,Enum.Font.GothamBold).ZIndex=9
    Lbl("TD",item,ti.desc,UDim2.new(1,-42,0,14),UDim2.new(0,36,0,22),C.dim,11,Enum.Font.Gotham).ZIndex=9; item:FindFirstChild("TD").TextWrapped=true
end

-- ════════════════════════════════════════════════════════════════
-- §9  SOLVE TAB (kısıtlama çözme)
-- ════════════════════════════════════════════════════════════════
local solveC=tabCs["Solve"]; Pad(solveC,10)
local solveScr=ScFr("SS",solveC); solveScr.ZIndex=8; Instance.new("UIListLayout",solveScr).Padding=UDim.new(0,8)
local solveEmp=Lbl("SE",solveScr,"No active restraints.",UDim2.new(1,0,0,42),nil,C.dim,12,Enum.Font.Gotham,Enum.TextXAlignment.Center); solveEmp.ZIndex=9
local CNAMES={rope="Tied by Rope",handcuffs="Handcuffs",collar="Collar",tape="Tape",chainlink="Chain"}
local CTIMES={rope=3,handcuffs=5,collar=6,tape=2.5,chainlink=7}

local function addConUI(cType)
    if constraintItems[cType] then return end; solveEmp.Visible=false
    local item=Fr("C_"..cType,solveScr,UDim2.new(1,0,0,72),nil,C.card); Corn(item,8); Strk(item,C.border); Pad(item,nil,12,12,10,10); item.ZIndex=8
    Lbl("CN",item,CNAMES[cType] or cType,UDim2.new(1,-80,0,18),nil,C.text,13,Enum.Font.GothamBold).ZIndex=9
    Lbl("CT",item,"Restraint active — wait or resolve",UDim2.new(1,-80,0,15),UDim2.new(0,0,0,22),C.dim,11).ZIndex=9; item:FindFirstChild("CT").TextWrapped=true
    local sb=Btn("SB",item,"RESOLVEE",UDim2.new(0,66,0,32),UDim2.new(1,-66,.5,-16),Color3.fromRGB(14,38,14),C.accentG,11); sb.ZIndex=9; sb.Font=Enum.Font.GothamBold
    local pb=Fr("PB",sb,UDim2.new(0,0,1,0),nil,Color3.fromRGB(22,60,22)); pb.ZIndex=8; Corn(pb,4)
    local solving=false
    sb.MouseButton1Click:Connect(function()
        if solving then return end; solving=true
        pcall(function() if BSC_RE then BSC_RE.SolveConstraint:FireServer(cType) end end)
        sb.Text="…"; local dur=CTIMES[cType] or 3; tw(pb,{Size=UDim2.new(1,0,1,0)},dur):Play()
        task.delay(dur,function()
            sb.Text="✓"; tw(item,{BackgroundTransparency=.65},.4):Play()
            task.delay(.9,function() item:Destroy(); constraintItems[cType]=nil; if not next(constraintItems)then solveEmp.Visible=true end end)
        end)
    end)
    constraintItems[cType]=item
end
local function removeConUI(cType)
    if constraintItems[cType] then constraintItems[cType]:Destroy(); constraintItems[cType]=nil end
    if not next(constraintItems) then solveEmp.Visible=true end
end

-- ════════════════════════════════════════════════════════════════
-- §10  INVENTORY TAB
-- ════════════════════════════════════════════════════════════════
local invC=tabCs["Inventory"]; Pad(invC,10)
local invScr=ScFr("IS",invC); invScr.ZIndex=8; Instance.new("UIListLayout",invScr).Padding=UDim.new(0,7)
local invEmp=Lbl("IE",invScr,"Inventory is empty.",UDim2.new(1,0,0,42),nil,C.dim,12,Enum.Font.Gotham,Enum.TextXAlignment.Center); invEmp.ZIndex=9

-- Backpack değişimi izle
local function refreshInventory()
    for _,c in ipairs(invScr:GetChildren())do if c:IsA("Frame") then c:Destroy() end end
    local bp=lp:FindFirstChild("Backpack"); if not bp then return end
    local hasItems=false
    for _,tool in ipairs(bp:GetChildren())do
        if tool:IsA("Tool") then
            hasItems=true
            local item=Fr("IT_"..tool.Name,invScr,UDim2.new(1,0,0,44),nil,C.card); Corn(item,7); Strk(item,C.border); Pad(item,nil,10,10,8,8); item.ZIndex=8
            Lbl("TN",item,"🎒 "..tool.Name,UDim2.new(1,0,0,28),nil,C.text,13,Enum.Font.GothamBold).ZIndex=9
        end
    end
    invEmp.Visible=not hasItems
end

-- ════════════════════════════════════════════════════════════════
-- §11  PANEL TOGGLE
-- ════════════════════════════════════════════════════════════════
SP.Position=UDim2.new(1,0,0,43)
spT.MouseButton1Click:Connect(function()
    panelOpen=not panelOpen
    tw(SP,{Position=UDim2.new(1,panelOpen and -274 or 0,0,43)},.38,Enum.EasingStyle.Quart):Play()
    spT.Text=panelOpen and "❯" or "❮"
    if panelOpen then refreshInventory() end
end)

-- ════════════════════════════════════════════════════════════════
-- §12  CFrame KARAKTER ANİMASYONLARI (idle/run/jump)
-- ════════════════════════════════════════════════════════════════
local animState = "idle"
local animT = 0

local function getMotorC0(char, partName)
    local p = char:FindFirstChild(partName)
    if p then return p:FindFirstChildOfClass("Motor6D") end
    return nil
end

RunSvc.RenderStepped:Connect(function(dt)
    if emoteActive then return end  -- Emote sırasında ana animasyon çalışmaz
    local char = lp.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    animT = animT + dt

    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X,0,vel.Z).Magnitude
    local isJumping = (vel.Y > 2)
    local isRunning = (speed > 1)

    -- Animasyon durumu seç
    if isJumping then
        animState = "jump"
    elseif isRunning then
        animState = "run"
    else
        animState = "idle"
    end

    -- R15 motor hedefleri
    local targets = {}

    if animState == "idle" then
        -- Idle: hafif nefes hareketi
        local breathe = math.sin(animT * 1.8) * 0.03
        targets = {
            UpperTorso   = CFrame.Angles(breathe, 0, 0),
            Head         = CFrame.Angles(breathe*0.5 + math.sin(animT*0.7)*0.02, 0, 0),
            LeftUpperArm  = CFrame.Angles(0, 0, math.rad(-3) + math.sin(animT*1.8)*0.02),
            RightUpperArm = CFrame.Angles(0, 0, math.rad(3)  - math.sin(animT*1.8)*0.02),
        }
    elseif animState == "run" then
        -- Koşu: bacak/kol sallama
        local cycle = animT * 6
        targets = {
            UpperTorso    = CFrame.Angles(math.rad(5), 0, 0),
            Head          = CFrame.Angles(math.rad(-5), 0, 0),
            LeftUpperLeg  = CFrame.Angles(math.sin(cycle)*0.7, 0, 0),
            RightUpperLeg = CFrame.Angles(-math.sin(cycle)*0.7, 0, 0),
            LeftLowerLeg  = CFrame.Angles(math.max(0, -math.sin(cycle)*0.6), 0, 0),
            RightLowerLeg = CFrame.Angles(math.max(0, math.sin(cycle)*0.6), 0, 0),
            LeftUpperArm  = CFrame.Angles(-math.sin(cycle)*0.55, 0, math.rad(-5)),
            RightUpperArm = CFrame.Angles(math.sin(cycle)*0.55, 0, math.rad(5)),
        }
    elseif animState == "jump" then
        -- Zıplama: vücut açılır
        targets = {
            UpperTorso    = CFrame.Angles(math.rad(-5), 0, 0),
            LeftUpperLeg  = CFrame.Angles(math.rad(-20), 0, math.rad(-5)),
            RightUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(5)),
            LeftLowerLeg  = CFrame.Angles(math.rad(15), 0, 0),
            RightLowerLeg = CFrame.Angles(math.rad(15), 0, 0),
            LeftUpperArm  = CFrame.Angles(0, 0, math.rad(-25)),
            RightUpperArm = CFrame.Angles(0, 0, math.rad(25)),
        }
    end

    -- Motor'lara lerp uygula
    for partName, targetCF in pairs(targets) do
        local part = char:FindFirstChild(partName)
        if part then
            local motor = part:FindFirstChildOfClass("Motor6D")
            if motor then
                motor.C0 = motor.C0:Lerp(
                    CFrame.new(motor.C0.Position) * targetCF,
                    math.min(dt * 12, 1)
                )
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- §13  TOOL İŞLEVSELLİĞİ (Client-side)
-- ════════════════════════════════════════════════════════════════

-- Aktif tool takibi
local currentTool = nil
local ropeVisuals = {}

lp.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            currentTool = child
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child == currentTool then
            currentTool = nil
        end
    end)
end)

-- Rope visual (gerçekçi ip görünümü)
local function createRopeVisual(fromPos, toPos)
    local mid = (fromPos + toPos) / 2
    local dist = (toPos - fromPos).Magnitude
    local part = Instance.new("Part")
    part.Name = "RopeVisual"
    part.Size = Vector3.new(0.12, 0.12, dist)
    part.CFrame = CFrame.lookAt(mid, toPos)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Fabric
    part.BrickColor = BrickColor.new("Medium brown")
    part.CastShadow = false
    part.Parent = workspace
    table.insert(ropeVisuals, part)
    return part
end

local function clearRopeVisuals()
    for _,p in ipairs(ropeVisuals) do pcall(function() p:Destroy() end) end
    ropeVisuals = {}
end

-- Tool E-tuşu etkileşimi
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then
        if not currentTool then return end
        local char = lp.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

        -- Yakındaki oyuncu bul
        local closest, closestDist = nil, 12
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local dist = (tHRP.Position - hrp.Position).Magnitude
                    if dist < closestDist then closest=plr; closestDist=dist end
                end
            end
        end

        if not closest then return end

        local tChar = closest.Character
        local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end

        -- Tool'a göre aksiyon
        local tn = currentTool.Name

        if tn == "Rope" then
            -- İp bağlama animasyonu (client visual)
            clearRopeVisuals()
            local ropeAnims = {}
            for i=1,8 do
                local factor = i/8
                local ropePos = hrp.Position:Lerp(tHRP.Position, factor)
                local rv = createRopeVisual(
                    ropePos - Vector3.new(0,1,0),
                    ropePos + Vector3.new(math.sin(i)*0.3, -0.5, math.cos(i)*0.3)
                )
            end
            -- Server'a bildir
            pcall(function() if BSC_RE then BSC_RE.AddConstraint:FireServer(closest,"rope") end end)
            -- Rope görsel güncelleme döngüsü
            task.spawn(function()
                for i=1,60 do
                    task.wait(0.05)
                    clearRopeVisuals()
                    if tChar and tChar.Parent then
                        local tHRP2=tChar:FindFirstChild("HumanoidRootPart")
                        local hrp2=char:FindFirstChild("HumanoidRootPart")
                        if tHRP2 and hrp2 then
                            for j=1,5 do
                                createRopeVisual(
                                    hrp2.Position:Lerp(tHRP2.Position,j/5) + Vector3.new(0,-1.5,0) + Vector3.new(math.sin(j+i)*0.1,0,0),
                                    hrp2.Position:Lerp(tHRP2.Position,(j+1)/5) + Vector3.new(0,-1.5,0) + Vector3.new(math.sin(j+1+i)*0.1,0,0)
                                )
                            end
                        end
                    end
                end
                clearRopeVisuals()
            end)

        elseif tn == "Handcuffs" then
            pcall(function() if BSC_RE then BSC_RE.AddConstraint:FireServer(closest,"handcuffs") end end)
            -- Handcuffs animasyonu (kol hareketi)
            task.spawn(function()
                local tHum=tChar:FindFirstChildOfClass("Humanoid")
                if tHum then tHum.WalkSpeed=0; tHum.JumpPower=0 end
                task.wait(0.1)
                if tHum then tHum.WalkSpeed=8; tHum.JumpPower=0 end
            end)

        elseif tn == "Taser" then
            pcall(function() if BSC_RE then BSC_RE.AddConstraint:FireServer(closest,"taser") end end)
            -- Taser efekti (neon görsel)
            local tHRP3=tChar:FindFirstChild("HumanoidRootPart")
            if tHRP3 then
                for _,side in ipairs({-0.5,0.5}) do
                    local spark=Instance.new("Part"); spark.Size=Vector3.new(0.2,0.2,(tHRP3.Position-hrp.Position).Magnitude)
                    spark.CFrame=CFrame.lookAt((hrp.Position+tHRP3.Position)/2,tHRP3.Position)
                    spark.Anchored=true; spark.CanCollide=false; spark.Material=Enum.Material.SmoothPlastic
                    spark.BrickColor=BrickColor.new("Bright yellow"); spark.Parent=workspace
                    task.delay(0.2,function() spark:Destroy() end)
                end
            end

        elseif tn == "Collar" then
            pcall(function() if BSC_RE then BSC_RE.AddConstraint:FireServer(closest,"collar") end end)

        elseif tn == "Keycard" then
            -- Keycard: zaten server-side ClickDetector ile çalışıyor
            -- Ek olarak yakındaki okuyucuya otomatik etkileşim
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- §14  showHUD fonksiyonu
-- ════════════════════════════════════════════════════════════════
function showHUD(teamName)
    HUD.Visible = true
    -- Takıma göre özel buton göster
    if teamName == "Prisoner" or teamName == "Criminal" then
        riotW.Visible = true
    end
    -- Panel aç
    task.delay(0.5, function()
        panelOpen = true
        tw(SP, {Position=UDim2.new(1,-274,0,43)},.5,Enum.EasingStyle.Back):Play()
        spT.Text = "❯"
    end)
end

-- ════════════════════════════════════════════════════════════════
-- §15  REMOTES — async bağlan
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
    local folder = RepStore:WaitForChild("BSCRemotes")
    BSC_RE = {
        CreateCharacter   = folder:WaitForChild("CreateCharacter"),
        SelectTeam        = folder:WaitForChild("SelectTeam"),
        StartRiot         = folder:WaitForChild("StartRiot"),
        SolveConstraint   = folder:WaitForChild("SolveConstraint"),
        CharacterReady    = folder:WaitForChild("CharacterReady"),
        UpdateConstraints = folder:WaitForChild("UpdateConstraints"),
        AddConstraint     = folder:WaitForChild("AddConstraint"),
        RiotBroadcast     = folder:WaitForChild("RiotBroadcast"),
        KeycardDoor       = folder:WaitForChild("KeycardDoor"),
        SitPlayer         = folder:WaitForChild("SitPlayer"),
        ToggleLight       = folder:WaitForChild("ToggleLight"),
    }

    BSC_RE.AddConstraint.OnClientEvent:Connect(function(cType)
        addConUI(cType)
    end)
    BSC_RE.UpdateConstraints.OnClientEvent:Connect(function(cType, action)
        if action == "removed" then removeConUI(cType) end
    end)
    BSC_RE.RiotBroadcast.OnClientEvent:Connect(function(who)
        local n=Lbl("Notif",HUD,"⚡  "..who.." STARTED A RIOT!",UDim2.new(0,450,0,38),UDim2.new(.5,-225,0,12),C.dangerH,13,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
        n.BackgroundColor3=C.danger; n.BackgroundTransparency=0; n.ZIndex=50; Corn(n,8)
        n.TextTransparency=1; tw(n,{TextTransparency=0},.3):Play()
        task.delay(4,function() tw(n,{TextTransparency=1,BackgroundTransparency=1},.5):Play(); task.delay(.6,function()n:Destroy()end) end)
    end)
    print("[BSC] ✓ Remotes connected")
end)

-- Backpack değişimi otomatik inventory güncelle
lp.CharacterAdded:Connect(function(char)
    if SG and SG.Parent then SG.Enabled = true end
    local bp = lp:WaitForChild("Backpack")
    bp.ChildAdded:Connect(function() if panelOpen then refreshInventory() end end)
    bp.ChildRemoved:Connect(function() if panelOpen then refreshInventory() end end)
    -- Animasyon reset
    animT = 0
    emoteActive = false
    if emoteConn then emoteConn:Disconnect(); emoteConn=nil end
end)

print("[BSC] ✓ Client v3.0 ULTRA loaded — all systems active")
print("[BSC] ✓ Animation system: idle/run/jump + emotes")
print("[BSC] ✓ Tool system: Keycard/Rope/Handcuffs/Taser/Collar")
print("[BSC] ✓ Bird-eye viewport active")
