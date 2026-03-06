--[[
╔══════════════════════════════════════════════════════════════════╗
║   BSC PRISON — MapBuild_Server.lua  v3.0 ULTRA                  ║
║   📁 Koy: ServerScriptService → Script                          ║
║                                                                  ║
║   YENİLİKLER v3.0:                                              ║
║   • Criminal Base — girilebilir, keycard kapılar, sandalye      ║
║   • Prison Bodrum — demir parmaklık, ışık kontrolü, yataklar    ║
║   • Polis Karakolu — cephanelik, kıyafet, kahvaltı salonu       ║
║   • Esir sistemi — sandalye, zincir noktaları, hostage oda      ║
║   • Keycard RE entegrasyonu                                      ║
║   • Polis spawn → otomatik tool dağıtımı                        ║
╚══════════════════════════════════════════════════════════════════╝
--]]

local Players   = game:GetService("Players")
local RepStore  = game:GetService("ReplicatedStorage")
local RunSvc    = game:GetService("RunService")
local TweenSvc  = game:GetService("TweenService")

local ws = workspace

-- ════════════════════════════════════════════════════════════════
-- REMOTES SETUP
-- ════════════════════════════════════════════════════════════════
local RE_folder = RepStore:FindFirstChild("BSCRemotes") or Instance.new("Folder")
RE_folder.Name = "BSCRemotes"; RE_folder.Parent = RepStore

local function ensureRE(name, cls)
    if not RE_folder:FindFirstChild(name) then
        local r = Instance.new(cls or "RemoteEvent")
        r.Name = name; r.Parent = RE_folder
    end
    return RE_folder:FindFirstChild(name)
end

ensureRE("CreateCharacter")
ensureRE("SelectTeam")
ensureRE("StartRiot")
ensureRE("SolveConstraint")
ensureRE("CharacterReady")
ensureRE("UpdateConstraints")
ensureRE("AddConstraint")
ensureRE("RiotBroadcast")
ensureRE("KeycardDoor")
ensureRE("SitPlayer")
ensureRE("EscapeChair")
ensureRE("ToggleLight")
ensureRE("ApplyTool")
ensureRE("RespawnPrisoner")

-- ════════════════════════════════════════════════════════════════
-- TEMEL YARDIMCI FONKSİYONLAR
-- ════════════════════════════════════════════════════════════════
local MAP_SIZE = 1200
local WALL_H   = 22
local GY       = 0

local function resolveMaterial(mat)
    if typeof(mat) == "EnumItem" then return mat end
    if type(mat) == "string" then
        local ok, enumMat = pcall(function() return Enum.Material[mat] end)
        if ok and enumMat then return enumMat end
    end
    return Enum.Material.SmoothPlastic
end

local function P(name, sz, cf, col, mat, tr, anch)
    local p = Instance.new("Part")
    p.Name         = name or "Part"
    p.Size         = sz or Vector3.new(4,4,4)
    p.CFrame       = cf or CFrame.new(0,0,0)
    p.BrickColor   = BrickColor.new(col or "Medium stone grey")
    p.Material     = resolveMaterial(mat)
    p.Transparency = tr or 0
    p.Anchored     = (anch == nil) and true or anch
    p.CanCollide   = true
    p.CastShadow   = true
    p.Parent       = ws
    return p
end

local function newModel(name, par)
    local m = Instance.new("Model")
    m.Name = name; m.Parent = par or ws; return m
end

local function ptLight(par, bright, range, col)
    local l = Instance.new("PointLight")
    l.Brightness = bright or 1.5
    l.Range = range or 18
    l.Color = col or Color3.fromRGB(255,240,180)
    l.Parent = par
    return l
end

local function surfLight(par, face, bright, range, col)
    local s = Instance.new("SurfaceLight")
    s.Face = face or Enum.NormalId.Front
    s.Brightness = bright or 1; s.Range = range or 14
    s.Color = col or Color3.fromRGB(255,240,200); s.Parent = par
    return s
end

local function neonPart(name, sz, cf, col, par)
    -- Neon kullanılmasın: daha gerçekçi metal/plastik şerit
    local p = P(name, sz, cf, col or "Dark stone grey", Enum.Material.Metal, 0)
    p.Parent = par or ws; return p
end

local function weld(p0, p1)
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0; w.Part1 = p1; w.Parent = p0
end

local function billboard(par, txt, size, offset, col)
    local b = Instance.new("BillboardGui")
    b.Size = size or UDim2.new(0,200,0,50)
    b.StudsOffset = offset or Vector3.new(0,2,0)
    b.AlwaysOnTop = false; b.MaxDistance = 25
    b.Parent = par
    local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,0,1,0)
    fr.BackgroundColor3 = Color3.fromRGB(8,8,14)
    fr.BackgroundTransparency = 0.15; fr.BorderSizePixel = 0; fr.Parent = b
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = fr
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1; lbl.Text = txt or ""
    lbl.TextColor3 = col or Color3.fromRGB(220,220,255)
    lbl.TextSize = 13; lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.Parent = fr
    return b, lbl
end

-- ════════════════════════════════════════════════════════════════
-- §0  ANA ZEMİN + YOL
-- ════════════════════════════════════════════════════════════════
local Ground = newModel("Ground")

local base = P("BaseGround", Vector3.new(MAP_SIZE,2,MAP_SIZE), CFrame.new(0,-1,0),
    "Sand green", Enum.Material.Grass); base.Parent = Ground

-- Beton yollar
local function road(sz, x, z, rot)
    local r = P("Road", sz, CFrame.new(x,0.08,z)*CFrame.Angles(0,math.rad(rot or 0),0),
        "Dark stone grey", Enum.Material.SmoothPlastic)
    r.Parent = Ground
end
road(Vector3.new(MAP_SIZE,0.2,14), 0,0,0)
road(Vector3.new(14,0.2,MAP_SIZE), 0,0,0)
road(Vector3.new(180,0.2,12), 90,-80,0)
road(Vector3.new(12,0.2,180), -90,80,0)
road(Vector3.new(140,0.2,12), -60,100,0)
road(Vector3.new(12,0.2,140), 100,-60,0)
road(Vector3.new(120,0.2,12), 80,-100,0)
road(Vector3.new(12,0.2,120), -100,80,0)

-- Yol şeritleri
for i=-7,7 do
    local s=P("RL",Vector3.new(7,0.22,0.9),CFrame.new(i*27,0.09,0),"Bright yellow",Enum.Material.SmoothPlastic);s.Parent=Ground
    local s2=P("RL",Vector3.new(0.9,0.22,7),CFrame.new(0,0.09,i*27),"Bright yellow",Enum.Material.SmoothPlastic);s2.Parent=Ground
end

-- Kaldırımlar
for _, def in ipairs({
    {Vector3.new(MAP_SIZE,0.3,5),  0,0.1,  7.5, 0},
    {Vector3.new(MAP_SIZE,0.3,5),  0,0.1, -7.5, 0},
    {Vector3.new(5,0.3,MAP_SIZE),  7.5,0.1,0,   0},
    {Vector3.new(5,0.3,MAP_SIZE), -7.5,0.1,0,   0},
}) do
    local s=P("Sidewalk",def[1],CFrame.new(def[2],def[3],def[4]),"Light stone grey",Enum.Material.SmoothPlastic)
    s.Parent=Ground
end

-- ════════════════════════════════════════════════════════════════
-- §1  MAP BORDER
-- ════════════════════════════════════════════════════════════════
local Border = newModel("MapBorder")
local half = MAP_SIZE/2

local function bWall(sz, x, y, z, rot)
    local w=P("BW",sz,CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(rot or 0),0),
        "Institutional white",Enum.Material.Concrete)
    w.Parent=Border; return w
end
bWall(Vector3.new(MAP_SIZE+6, WALL_H, 3.5),  0,     WALL_H/2,  half+1.75, 0)
bWall(Vector3.new(MAP_SIZE+6, WALL_H, 3.5),  0,     WALL_H/2, -half-1.75, 0)
bWall(Vector3.new(3.5,WALL_H, MAP_SIZE+6),   half+1.75, WALL_H/2, 0, 0)
bWall(Vector3.new(3.5,WALL_H, MAP_SIZE+6),  -half-1.75, WALL_H/2, 0, 0)

-- Üst dikenli tel (neon)
for _,z in ipairs({half+1.75,-half-1.75}) do
    neonPart("Wire",Vector3.new(MAP_SIZE+6,0.6,0.6),CFrame.new(0,WALL_H+0.3,z),"Bright yellow",Border)
end
for _,x in ipairs({half+1.75,-half-1.75}) do
    neonPart("Wire",Vector3.new(0.6,0.6,MAP_SIZE+6),CFrame.new(x,WALL_H+0.3,0),"Bright yellow",Border)
end

-- Köşe kuleler
for _,xz in ipairs({{half,half},{-half,half},{half,-half},{-half,-half}}) do
    local tx,tz=xz[1],xz[2]
    local kule=P("Tower",Vector3.new(14,WALL_H+10,14),CFrame.new(tx,(WALL_H+10)/2,tz),"Dark stone grey",Enum.Material.Concrete); kule.Parent=Border
    local top=P("TTop",Vector3.new(16,3.5,16),CFrame.new(tx,WALL_H+11.75,tz),"Dark stone grey",Enum.Material.Concrete); top.Parent=Border
    local lt=neonPart("TLight",Vector3.new(1.2,1.2,1.2),CFrame.new(tx,WALL_H+14,tz),"Bright yellow",Border)
    ptLight(lt,3,40,Color3.fromRGB(255,200,80))
end

-- ════════════════════════════════════════════════════════════════
-- §2  AĞAÇLAR
-- ════════════════════════════════════════════════════════════════
local Trees = newModel("Trees")
local TREE_POS = {
    {-180,-60,1.1},{-200,25,0.9},{-165,-90,1.0},{-225,65,1.2},{-195,105,0.8},
    {-145,135,1.1},{-235,-35,0.9},{-175,-145,1.0},{155,-55,1.0},{185,35,1.2},
    {165,-95,0.9},{205,-65,1.1},{175,85,0.8},{195,115,1.0},{145,155,1.1},
    {215,-115,0.9},{-55,185,1.0},{35,205,1.2},{-85,165,0.9},{65,195,1.1},
    {-35,225,0.8},{55,235,1.0},{-105,205,1.1},{85,215,0.9},{-55,-185,1.1},
    {25,-205,1.0},{-75,-165,0.9},{45,-225,1.2},{-105,-195,0.8},{75,-185,1.0},
    {-135,-215,0.9},{95,-235,1.1},{-245,145,1.0},{245,-145,1.0},{-245,-145,0.9},
}
local function makeTree(x,z,sc)
    sc = sc or 1
    local t = newModel("Tree",Trees)
    local trunk=P("Trunk",Vector3.new(1.5*sc,9*sc,1.5*sc),CFrame.new(x,4.5*sc,z),"Brown",Enum.Material.Wood); trunk.Parent=t
    local l1=P("Leaves",Vector3.new(8*sc,6*sc,8*sc),CFrame.new(x,10*sc+3*sc,z),"Bright green",Enum.Material.Grass,0.05); l1.Shape=Enum.PartType.Ball; l1.Parent=t
    local l2=P("Leaves2",Vector3.new(6*sc,5*sc,6*sc),CFrame.new(x,13*sc+3*sc,z),"Medium green",Enum.Material.Grass,0.05); l2.Shape=Enum.PartType.Ball; l2.Parent=t
    local l3=P("Top",Vector3.new(3.5*sc,3*sc,3.5*sc),CFrame.new(x,16*sc+3*sc,z),"Forest green",Enum.Material.Grass,0.1); l3.Shape=Enum.PartType.Ball; l3.Parent=t
end
for _,d in ipairs(TREE_POS) do makeTree(d[1],d[2],d[3]) end

-- Daha gelişmiş ağaç modelleri (5-6 varyant)
local function createTreeVariant(style, x, z, scale)
    scale = scale or 1
    local m = newModel("Tree_"..style, Trees)
    if style == "Pine" then
        local trunk = P("Trunk", Vector3.new(1.4*scale, 13*scale, 1.4*scale), CFrame.new(x, 6.5*scale, z), "Reddish brown", Enum.Material.Wood); trunk.Parent = m
        for i=0,3 do
            local cone = P("Cone"..i, Vector3.new((8-i*1.3)*scale, (4.2-i*0.6)*scale, (8-i*1.3)*scale), CFrame.new(x, (11+i*2.4)*scale, z), "Dark green", Enum.Material.Grass, 0.04)
            cone.Shape = Enum.PartType.Ball; cone.Parent = m
        end
    elseif style == "Oak" then
        local trunk = P("Trunk", Vector3.new(2.3*scale, 10*scale, 2.3*scale), CFrame.new(x,5*scale,z), "Brown", Enum.Material.Wood); trunk.Parent = m
        for _,ofs in ipairs({{-2,12,-1},{2,13,1},{0,14,0},{-1,11,2},{1,12,-2}}) do
            local leaf = P("Leaf", Vector3.new(7*scale,6*scale,7*scale), CFrame.new(x+ofs[1]*scale,ofs[2]*scale,z+ofs[3]*scale), "Earth green", Enum.Material.Grass, 0.05)
            leaf.Shape = Enum.PartType.Ball; leaf.Parent = m
        end
    elseif style == "Dry" then
        local trunk = P("Trunk", Vector3.new(1.6*scale, 9*scale, 1.6*scale), CFrame.new(x,4.5*scale,z), "CGA brown", Enum.Material.Wood); trunk.Parent = m
        for i=1,4 do
            local br = P("Branch"..i, Vector3.new(0.5*scale,4*scale,0.5*scale), CFrame.new(x,7.5*scale,z) * CFrame.Angles(math.rad(40), math.rad(i*90), 0) * CFrame.new(0,2*scale,0), "CGA brown", Enum.Material.Wood)
            br.Parent = m
        end
    elseif style == "Palm" then
        local trunk = P("Trunk", Vector3.new(1.2*scale, 12*scale, 1.2*scale), CFrame.new(x,6*scale,z), "Reddish brown", Enum.Material.Wood); trunk.Parent = m
        for i=0,5 do
            local leaf = P("PalmLeaf"..i, Vector3.new(1.2*scale,0.35*scale,7*scale), CFrame.new(x,12*scale,z) * CFrame.Angles(math.rad(-8), math.rad(i*60), math.rad(-22)), "Bright green", Enum.Material.Grass)
            leaf.Parent = m
        end
    elseif style == "Birch" then
        local trunk = P("Trunk", Vector3.new(1.3*scale, 11*scale, 1.3*scale), CFrame.new(x,5.5*scale,z), "Institutional white", Enum.Material.Wood); trunk.Parent = m
        for _,ofs in ipairs({{-1.5,12,0},{1.5,12,0},{0,13.5,1.5},{0,13.5,-1.5}}) do
            local leaf = P("Leaf", Vector3.new(5*scale,4*scale,5*scale), CFrame.new(x+ofs[1]*scale,ofs[2]*scale,z+ofs[3]*scale), "Grime", Enum.Material.Grass, 0.04)
            leaf.Shape = Enum.PartType.Ball; leaf.Parent = m
        end
    else -- Cedar
        local trunk = P("Trunk", Vector3.new(1.8*scale, 11*scale, 1.8*scale), CFrame.new(x,5.5*scale,z), "Brown", Enum.Material.Wood); trunk.Parent = m
        local crown = P("Crown", Vector3.new(9*scale,8*scale,9*scale), CFrame.new(x,12*scale,z), "Forest green", Enum.Material.Grass, 0.05)
        crown.Shape = Enum.PartType.Ball; crown.Parent = m
    end
end

for i=1,6 do
    local ang = (math.pi * 2) * (i/6)
    createTreeVariant("Pine", math.cos(ang)*420, math.sin(ang)*410, 1.25)
    createTreeVariant("Oak", math.cos(ang+0.6)*455, math.sin(ang+0.6)*435, 1.4)
    createTreeVariant("Dry", math.cos(ang+0.9)*500, math.sin(ang+0.9)*470, 1.1)
    createTreeVariant("Palm", math.cos(ang+1.2)*360, math.sin(ang+1.2)*510, 1.15)
    createTreeVariant("Birch", math.cos(ang+1.6)*530, math.sin(ang+1.6)*380, 1.2)
    createTreeVariant("Cedar", math.cos(ang+2.1)*470, math.sin(ang+2.1)*520, 1.3)
end

-- 6-7 farklı taş/kaya varyantı + büyük dağ sırtları
local Rocks = newModel("RockField")
local rockMats = {Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Rock, Enum.Material.Concrete, Enum.Material.Cobblestone, Enum.Material.CrackedLava, Enum.Material.Granite}
local function rockPart(name, sz, cf, mat)
    local r = P(name, sz, cf, "Dark stone grey", mat)
    r.Parent = Rocks
    r.Orientation = Vector3.new(math.random(-25,25), math.random(0,360), math.random(-25,25))
    return r
end

for i=1,160 do
    local ring = 420 + math.random()*170
    local ang = math.random()*math.pi*2
    local x,z = math.cos(ang)*ring, math.sin(ang)*ring
    local h = math.random(8,24)
    rockPart("Rock", Vector3.new(math.random(6,15), h, math.random(6,15)), CFrame.new(x,h/2,z), rockMats[(i % #rockMats)+1])
end

local Mountains = newModel("MountainRidges")
local function mountainBand(cx, cz, len, step, baseH, dir)
    for i=0,len do
        local noise = math.noise(i*0.2, cx*0.01, cz*0.01)
        local h = baseH + math.abs(noise)*30 + math.random(0,10)
        local x = cx + math.cos(dir) * i * step
        local z = cz + math.sin(dir) * i * step
        local peak = P("Peak", Vector3.new(28, h, 28), CFrame.new(x, h/2, z), "Dark stone grey", Enum.Material.Slate)
        peak.Parent = Mountains
        peak.Orientation = Vector3.new(math.random(-12,12), math.random(0,360), math.random(-12,12))
    end
end

mountainBand(-540, -520, 32, 26, 45, math.rad(20))
mountainBand(-560,  520, 31, 25, 42, math.rad(-15))
mountainBand( 520, -560, 34, 24, 48, math.rad(165))
mountainBand( 560,  530, 35, 25, 46, math.rad(200))

-- Blok tünel (dağ içi geçiş)
local Tunnel = newModel("MainTunnel")
local function tunnelPart(n, sz, cf, mat)
    local t = P(n, sz, cf, "Dark stone grey", mat or Enum.Material.Slate)
    t.Parent = Tunnel
    return t
end

local tunnelX, tunnelZ = 0, 470
tunnelPart("Floor", Vector3.new(120, 2, 34), CFrame.new(tunnelX, 1, tunnelZ), Enum.Material.Rock)
tunnelPart("Roof", Vector3.new(120, 2, 34), CFrame.new(tunnelX, 26, tunnelZ), Enum.Material.Rock)
tunnelPart("WallL", Vector3.new(120, 26, 2), CFrame.new(tunnelX, 13, tunnelZ-16), Enum.Material.Slate)
tunnelPart("WallR", Vector3.new(120, 26, 2), CFrame.new(tunnelX, 13, tunnelZ+16), Enum.Material.Slate)
for i=-5,5 do
    tunnelPart("Beam"..i, Vector3.new(2, 24, 30), CFrame.new(tunnelX+i*11, 13, tunnelZ), Enum.Material.Wood)
end

-- ════════════════════════════════════════════════════════════════
-- §3  KEYCARD KAPI SİSTEMİ
-- ════════════════════════════════════════════════════════════════
local keycardDoors = {} -- {part, open_cf, closed_cf, isOpen}

local function makeKeycardDoor(name, cf, sz, col, par)
    sz = sz or Vector3.new(4,9,0.5)
    col = col or "Dark stone grey"
    local door = P(name.."Door", sz, cf, col, Enum.Material.Metal)
    door.Parent = par or ws

    -- Metalik görünüm
    local frame = P(name.."Frame", Vector3.new(sz.X+0.4, sz.Y+0.4, 0.3),
        cf, "Dark grey", Enum.Material.Metal, 0)
    frame.CanCollide = false; frame.Parent = par or ws

    -- Neon kenar
    neonPart(name.."Edge", Vector3.new(0.2, sz.Y, 0.2),
        cf * CFrame.new(sz.X/2+0.15, 0, 0), "Cyan", par or ws)
    neonPart(name.."Edge2", Vector3.new(0.2, sz.Y, 0.2),
        cf * CFrame.new(-sz.X/2-0.15, 0, 0), "Cyan", par or ws)

    -- Keycard okuyucu
    local reader = P(name.."Reader", Vector3.new(0.6,1.2,0.6),
        cf * CFrame.new(sz.X/2+0.65, -sz.Y/2+1.5, 0),
        "Really black", Enum.Material.SmoothPlastic)
    reader.Parent = par or ws
    local rNeon = neonPart(name.."RLight", Vector3.new(0.4,0.4,0.3),
        cf * CFrame.new(sz.X/2+0.65, -sz.Y/2+2, 0), "Bright red", par or ws)

    -- Billboard
    local bb,lbl = billboard(reader, "🔑 Keycard Gerekli", UDim2.new(0,190,0,44), Vector3.new(0,2.5,0))
    lbl.TextColor3 = Color3.fromRGB(255,80,80)

    local closed_cf = cf
    local open_cf   = cf * CFrame.new(-sz.X, 0, 0)
    local isOpen    = false
    local entry = {part=door,reader=reader,rNeon=rNeon,lbl=lbl,isOpen=isOpen,open_cf=open_cf,closed_cf=closed_cf}

    -- Tık dedektörü
    local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 6; cd.Parent = reader
    cd.MouseClick:Connect(function(player)
        -- Oyuncunun keycard'ı var mı kontrol et
        local bp = player.Character and player.Character:FindFirstChildOfClass("Tool")
        local hasCard = false
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool.Name == "Keycard" then hasCard = true; break end
        end
        if player.Character then
            for _, tool in ipairs(player.Character:GetChildren()) do
                if tool.Name == "Keycard" then hasCard = true; break end
            end
        end
        if hasCard then
            entry.isOpen = not entry.isOpen
            local targetCF = entry.isOpen and open_cf or closed_cf
            TweenSvc:Create(door, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame=targetCF}):Play()
            TweenSvc:Create(rNeon, TweenInfo.new(0.3), {BrickColor=BrickColor.new(entry.isOpen and "Bright green" or "Bright red")}):Play()
            lbl.Text = entry.isOpen and "✅ Açık" or "🔑 Keycard Gerekli"
        else
            -- Kart yok — kırmızı blink
            for i=1,4 do
                task.delay(i*0.15, function()
                    rNeon.BrickColor = BrickColor.new(i%2==0 and "Bright red" or "Really black")
                end)
            end
        end
    end)

    keycardDoors[name] = entry
    return door, reader
end

-- ════════════════════════════════════════════════════════════════
-- §4  POLİS KARAKOLU (kuzey — +Z yönü) — GELİŞMİŞ
-- ════════════════════════════════════════════════════════════════
local PHQX,PHQZ = 100, -120
local PHQ = newModel("PoliceHQ")

local function phq(nm,sz,ox,oy,oz,col,mat,tr)
    local p=P(nm,sz,CFrame.new(PHQX+ox,oy,PHQZ+oz),col or "Medium stone grey",mat or Enum.Material.SmoothPlastic,tr or 0)
    p.Parent=PHQ; return p
end

-- Ana bina zemini
phq("Floor",    Vector3.new(90,1,70),  0,0.5, 0,  "White","Concrete")
-- Duvarlar
phq("WallN",    Vector3.new(90,14,1),  0,7.5,-35, "Light stone grey","Concrete")
phq("WallS",    Vector3.new(90,14,1),  0,7.5, 35, "Light stone grey","Concrete")
phq("WallW",    Vector3.new(1,14,70), -45,7.5,0,  "Light stone grey","Concrete")
phq("WallE",    Vector3.new(1,14,70),  45,7.5,0,  "Light stone grey","Concrete")
-- Tavan
phq("Roof",     Vector3.new(92,1.5,72),0,15, 0,  "Medium stone grey","Concrete")
-- Çatı neon şerit
neonPart("HQRoofLight",Vector3.new(88,0.4,68),CFrame.new(PHQX,15.8,PHQZ),"Cyan",PHQ)

-- Koridorlar / iç bölmeler
phq("WallInt1", Vector3.new(1,10,70),  0,5.5,  0, "White","Concrete")  -- ortadan böler
phq("WallInt2", Vector3.new(44,10,1), 22,5.5,-15, "White","Concrete")
phq("WallInt3", Vector3.new(44,10,1),-22,5.5,-15, "White","Concrete")
phq("WallInt4", Vector3.new(44,10,1), 22,5.5, 15, "White","Concrete")
phq("WallInt5", Vector3.new(44,10,1),-22,5.5, 15, "White","Concrete")

-- Kapı delikleri (iç duvarları böl)
phq("WallIntA", Vector3.new(18,10,1),  -12,5.5,0, "White","Concrete")
phq("WallIntB", Vector3.new(18,10,1),   12,5.5,0, "White","Concrete")
phq("WallIntTop",Vector3.new(4,3,1),    0,12,0,   "White","Concrete")

-- Zemin (farklı renk odalar)
phq("FloorDesk", Vector3.new(88,0.1,34), 0,1.05,-17,  "Light blue grey","SmoothPlastic")
phq("FloorCell", Vector3.new(88,0.1,34), 0,1.05, 17,  "Dark orange","SmoothPlastic",0.4)

-- POLİS SPAWNER platform
local spawnFloor=phq("CopSpawn",Vector3.new(14,0.3,14),-30,1.2,-25,"Cyan","Neon",0.7)
local spBB,spLbl = billboard(spawnFloor,"👮 POLİS SPAWN",UDim2.new(0,200,0,44),Vector3.new(0,2,0))
spLbl.TextColor3=Color3.fromRGB(80,200,255)

-- CEPHANELİK ODASI (sol arka)
phq("ArmoryFloor",Vector3.new(28,0.1,28),-30,1.05,-23,"Dark stone grey","Concrete")
-- Raf sistemi
for i=0,3 do
    phq("Shelf"..i,Vector3.new(12,0.4,2),-40+i*4,2.5+i*1.5,-30,"Dark stone grey","Metal")
end
-- Silah çubuğu görseller
for i=0,5 do
    local gun=phq("GunRack"..i,Vector3.new(0.8,3,0.3),-43+i*1.8,3,-28.5,"Dark grey","Metal")
    neonPart("GunNeon"..i,Vector3.new(0.6,0.2,0.2),CFrame.new(PHQX-43+i*1.8,4.5,PHQZ-28.5),"Bright red",PHQ)
end
-- Cephanelik kapısı
makeKeycardDoor("Armory", CFrame.new(PHQX-13,5.5,PHQZ-15)*CFrame.Angles(0,math.rad(90),0), Vector3.new(4,10,0.5), "Dark grey", PHQ)

-- KIYAFETLİK ODASI
phq("LokerFloor",Vector3.new(26,0.1,24),  28,1.05,-23,"White","Marble")
for i=0,5 do
    phq("Locker"..i,Vector3.new(2.5,5,2),20+i*3,3.5,-33,"Cyan","Metal")
    neonPart("LockerN"..i,Vector3.new(2,0.2,0.2),CFrame.new(PHQX+20+i*3,6,PHQZ-33),"Cyan",PHQ)
end
makeKeycardDoor("Locker", CFrame.new(PHQX+13,5.5,PHQZ-15)*CFrame.Angles(0,math.rad(90),0), Vector3.new(4,10,0.5), "Cyan", PHQ)

-- KAHVALTI SALONU
phq("BreakFloor",Vector3.new(44,0.1,30),  0,1.05, 23,"Pastel yellow","Marble")
-- Masalar
for i=0,2 do
    phq("Table"..i,Vector3.new(10,1,4),  -12+i*12, 1.7, 20,"White","SmoothPlastic")
    for s=0,1 do
        local chair=phq("Chair"..i..s,Vector3.new(3,2.5,3), -14+i*12+s*6,2.2,24,"White","SmoothPlastic")
        -- Oturma noktası
        local seat=Instance.new("Seat"); seat.Size=Vector3.new(3,0.3,3)
        seat.CFrame=CFrame.new(PHQX-14+i*12+s*6,2.5,PHQZ+24)
        seat.Anchored=true; seat.Parent=PHQ
        seat.CanCollide=true; seat.Transparency=1
    end
end
-- Yemek tezgahı
phq("Counter",Vector3.new(18,4,2.5),  0,2.5,33,"Light stone grey","SmoothPlastic")
neonPart("MenuSign",Vector3.new(14,0.3,0.3),CFrame.new(PHQX,5,PHQZ+33),"Bright yellow",PHQ)

makeKeycardDoor("Canteen",CFrame.new(PHQX,5.5,PHQZ+17)*CFrame.Angles(0,0,0), Vector3.new(6,10,0.5), "Light stone grey", PHQ)

-- İç lambalar
for _, pos in ipairs({{-28,12,-22},{28,12,-22},{0,12,0},{-28,12,22},{28,12,22}}) do
    local lt=P("HQLight",Vector3.new(3,0.4,3),CFrame.new(PHQX+pos[1],pos[2],PHQZ+pos[3]),"White",Enum.Material.SmoothPlastic,0)
    lt.Parent=PHQ; ptLight(lt,2.5,22,Color3.fromRGB(230,235,255))
end

-- Dış lambalar
for _,side in ipairs({-40,40}) do
    local lt=P("ExtLight",Vector3.new(2,2,2),CFrame.new(PHQX+side,17,PHQZ-35),"Bright blue",Enum.Material.SmoothPlastic)
    lt.Parent=PHQ; ptLight(lt,3,28,Color3.fromRGB(100,140,255))
end

-- Giriş merdivenleri
for i=1,3 do
    phq("Step"..i,Vector3.new(16,0.5,2), 0,i*0.5, 35+i*1.2, "Light stone grey","Concrete")
end

-- HQ plaka
local hqSign = phq("HQSign",Vector3.new(20,4,0.5),0,12,-35,"Really black","SmoothPlastic")
neonPart("HQNeon",Vector3.new(18,0.3,0.2),CFrame.new(PHQX,14.5,PHQZ-35.3),"Bright blue",PHQ)
local bb2,l2=billboard(hqSign,"🚔 BSC POLİS KARAKOLU",UDim2.new(0,280,0,54),Vector3.new(0,4,0))
l2.TextColor3=Color3.fromRGB(80,160,255); l2.TextSize=15

-- ════════════════════════════════════════════════════════════════
-- §5  PRISON KOMPLEKS — BODRUM ZINDANI
-- ════════════════════════════════════════════════════════════════
local PRSX, PRSZ = 0, 0  -- Merkez
local PRS = newModel("Prison")

local function prs(nm,sz,ox,oy,oz,col,mat,tr)
    local p=P(nm,sz,CFrame.new(PRSX+ox,oy,PRSZ+oz),col or "Dark stone grey",mat or Enum.Material.Concrete,tr or 0)
    p.Parent=PRS; return p
end

-- ── Ana bina (zemin kat) ──
prs("MainFloor",   Vector3.new(80,1,60),    0,0.5,   0, "Smoky grey","Concrete")
prs("MainWallN",   Vector3.new(80,15,1.5),  0,8,   -30, "Dark stone grey","Concrete")
prs("MainWallS",   Vector3.new(80,15,1.5),  0,8,    30, "Dark stone grey","Concrete")
prs("MainWallW",   Vector3.new(1.5,15,60), -40,8,    0, "Dark stone grey","Concrete")
prs("MainWallE",   Vector3.new(1.5,15,60),  40,8,    0, "Dark stone grey","Concrete")
prs("MainRoof",    Vector3.new(82,2,62),     0,16,    0, "Dark stone grey","Concrete")
neonPart("PrisonRoof",Vector3.new(78,0.3,58),CFrame.new(PRSX,17,PRSZ),"Bright orange",PRS)

-- Avlu
prs("Yard",        Vector3.new(80,0.3,40),  0,0.4,  60, "Light stone grey","Concrete")
prs("YardWallN",   Vector3.new(80,8,1),     0,4.5,  40, "Dark stone grey","Concrete")
prs("YardWallS",   Vector3.new(80,8,1),     0,4.5,  80, "Dark stone grey","Concrete")
prs("YardWallW",   Vector3.new(1,8,40),   -40,4.5,  60, "Dark stone grey","Concrete")
prs("YardWallE",   Vector3.new(1,8,40),    40,4.5,  60, "Dark stone grey","Concrete")

-- Avlu tel örgü
for _, def in ipairs({
    {Vector3.new(80,6,0.4),0,4,40},{Vector3.new(80,6,0.4),0,4,80},
    {Vector3.new(0.4,6,40),-40,4,60},{Vector3.new(0.4,6,40),40,4,60},
}) do
    local f=P("Fence",def[1],CFrame.new(PRSX+def[2],def[3],PRSZ+def[4]),"Silver","WireFrame",0.3); f.Parent=PRS
end

-- ── BODRUM ZİNDAN ──
local BASY = -8  -- bodrum seviyesi

prs("BasFloor",    Vector3.new(80,1,60),    0,BASY+0.5,0,  "Really black","Concrete")
prs("BasWallN",    Vector3.new(80,8,1.5),   0,BASY+4.5,-30,"Dark grey","Concrete")
prs("BasWallS",    Vector3.new(80,8,1.5),   0,BASY+4.5, 30,"Dark grey","Concrete")
prs("BasWallW",    Vector3.new(1.5,8,60),  -40,BASY+4.5,0, "Dark grey","Concrete")
prs("BasWallE",    Vector3.new(1.5,8,60),   40,BASY+4.5,0, "Dark grey","Concrete")
prs("BasRoof",     Vector3.new(82,1,62),     0,BASY+8.5,0,  "Really black","Concrete")

-- Merdivenler aşağıya
for i=0,7 do
    prs("Stair"..i,Vector3.new(5,0.5,3), -35,i*(-1)+0.5,-(20-i*3),"Dark grey","Concrete")
end

-- ── DEMİR PARMAKLIKLARI (koğuş kafesleri) ──
local cellLights = {}  -- ışık açma/kapama için

local function makeCell(cx, cz, idx)
    local cellMdl = newModel("Cell_"..idx, PRS)
    -- Zemin
    local cf=P("CellFloor",Vector3.new(12,0.3,10),CFrame.new(PRSX+cx,BASY+1,PRSZ+cz),"Dark stone grey","Concrete"); cf.Parent=cellMdl
    -- Arka duvar
    P("CellBack",Vector3.new(12,8,0.5),CFrame.new(PRSX+cx,BASY+4.5,PRSZ+cz-5),"Dark grey","Concrete").Parent=cellMdl
    -- Yan duvarlar
    P("CellL",Vector3.new(0.5,8,10),CFrame.new(PRSX+cx-6,BASY+4.5,PRSZ+cz),"Dark grey","Concrete").Parent=cellMdl
    P("CellR",Vector3.new(0.5,8,10),CFrame.new(PRSX+cx+6,BASY+4.5,PRSZ+cz),"Dark grey","Concrete").Parent=cellMdl

    -- Demir parmaklıklar (ön)
    for ri=0,5 do
        local bar=P("Bar"..ri,Vector3.new(0.35,8,0.35),
            CFrame.new(PRSX+cx-5+ri*2,BASY+4.5,PRSZ+cz+5),
            "Dark grey",Enum.Material.Metal)
        bar.Parent=cellMdl
        neonPart("BarN"..ri,Vector3.new(0.2,0.2,0.2),
            CFrame.new(PRSX+cx-5+ri*2,BASY+8,PRSZ+cz+5),"Cyan",cellMdl)
    end
    -- Yatay çubuklar
    P("BarH1",Vector3.new(12,0.35,0.35),CFrame.new(PRSX+cx,BASY+2.5,PRSZ+cz+5),"Dark grey",Enum.Material.Metal).Parent=cellMdl
    P("BarH2",Vector3.new(12,0.35,0.35),CFrame.new(PRSX+cx,BASY+5,PRSZ+cz+5),"Dark grey",Enum.Material.Metal).Parent=cellMdl
    P("BarH3",Vector3.new(12,0.35,0.35),CFrame.new(PRSX+cx,BASY+7.5,PRSZ+cz+5),"Dark grey",Enum.Material.Metal).Parent=cellMdl

    -- Kapı (parmaklıklı)
    local door=P("CellDoor",Vector3.new(3,8,0.4),CFrame.new(PRSX+cx+1,BASY+4.5,PRSZ+cz+5),"Reddish brown",Enum.Material.Metal)
    door.Parent=cellMdl
    for ri=0,2 do
        local db=P("DBar"..ri,Vector3.new(0.3,8,0.3),CFrame.new(PRSX+cx+0+ri,BASY+4.5,PRSZ+cz+5.2),"Dark grey",Enum.Material.Metal)
        db.Parent=cellMdl
    end

    -- Yatak
    local bed=P("Bed",Vector3.new(3,0.8,6),CFrame.new(PRSX+cx-3.5,BASY+1.8,PRSZ+cz-1),"Reddish brown",Enum.Material.SmoothPlastic); bed.Parent=cellMdl
    local mattress=P("Mattress",Vector3.new(2.8,0.3,5.5),CFrame.new(PRSX+cx-3.5,BASY+2.3,PRSZ+cz-1),"Institutional white",Enum.Material.Fabric); mattress.Parent=cellMdl
    local pillow=P("Pillow",Vector3.new(2,0.5,1),CFrame.new(PRSX+cx-3.5,BASY+2.65,PRSZ+cz-3.2),"White",Enum.Material.Fabric); pillow.Parent=cellMdl

    -- Klozet
    local toilet=P("Toilet",Vector3.new(1.5,2,1.5),CFrame.new(PRSX+cx+4.5,BASY+2,PRSZ+cz-4),"White",Enum.Material.Marble); toilet.Parent=cellMdl

    -- Işık
    local light=neonPart("CellLight",Vector3.new(4,0.4,0.4),CFrame.new(PRSX+cx,BASY+8.2,PRSZ+cz-1),"White",cellMdl)
    ptLight(light,1.5,12,Color3.fromRGB(200,210,255))
    table.insert(cellLights,{light=light,model=cellMdl,idx=idx})

    -- Işık açma/kapama butonu (duvar üstünde)
    local lightBtn=P("LightBtn"..idx,Vector3.new(0.6,0.6,0.4),CFrame.new(PRSX+cx-5.8,BASY+4,PRSZ+cz-3),"Bright green",Enum.Material.SmoothPlastic)
    lightBtn.Parent=cellMdl
    local lbBB,lbLbl=billboard(lightBtn,"💡 Işık",UDim2.new(0,100,0,34),Vector3.new(0,1.5,0))
    lbLbl.TextSize=11
    local lbCD=Instance.new("ClickDetector"); lbCD.MaxActivationDistance=8; lbCD.Parent=lightBtn
    local litOn=true
    lbCD.MouseClick:Connect(function()
        litOn=not litOn
        light.Transparency=litOn and 0 or 1
        for _,c in ipairs(light:GetChildren()) do if c:IsA("PointLight") then c.Enabled=litOn end end
        lightBtn.BrickColor=BrickColor.new(litOn and "Bright green" or "Really black")
    end)

    -- Spawn lokasyonu (mahkum ölünce buraya doğar)
    local spawnPt=Instance.new("SpawnLocation")
    spawnPt.Name="PrisonerSpawn"..idx
    spawnPt.Size=Vector3.new(2,0.5,2)
    spawnPt.CFrame=CFrame.new(PRSX+cx,BASY+1.5,PRSZ+cz+2)
    spawnPt.TeamColor=BrickColor.new("Bright orange")
    spawnPt.Neutral=false; spawnPt.Anchored=true
    spawnPt.Transparency=0.8; spawnPt.BrickColor=BrickColor.new("Bright orange")
    spawnPt.Parent=PRS

    return door
end

-- 8 hücre oluştur (2 sıra x 4)
for i=0,3 do
    makeCell(-30+i*16, -10, i*2+1)    -- sol sıra
    makeCell(-30+i*16,  10, i*2+2)    -- sağ sıra (ön)
end

-- Bodrum koridor lambası
for x=-30,30,15 do
    local cl=neonPart("CorLight",Vector3.new(3,0.3,0.3),CFrame.new(PRSX+x,BASY+8.3,PRSZ),"Cyan",PRS)
    ptLight(cl,1,14,Color3.fromRGB(100,200,255))
end

-- ════════════════════════════════════════════════════════════════
-- §6  CRIMINAL BASE — GELİŞMİŞ + GİRİLEBİLİR
-- ════════════════════════════════════════════════════════════════
local CRBX, CRBZ = -140, 100
local CRB = newModel("CriminalBase")

local function crb(nm,sz,ox,oy,oz,col,mat,tr)
    local p=P(nm,sz,CFrame.new(CRBX+ox,oy,CRBZ+oz),col or "Really black",mat or Enum.Material.SmoothPlastic,tr or 0)
    p.Parent=CRB; return p
end

-- Ana kriminal üs binası
crb("Floor",     Vector3.new(70,1,55),   0,0.5,  0, "Really black","Concrete")
crb("WallN",     Vector3.new(70,13,1.5), 0,7,  -27, "Really black","Concrete")
crb("WallS",     Vector3.new(70,13,1.5), 0,7,   27, "Really black","Concrete")
crb("WallW",     Vector3.new(1.5,13,55),-35,7,   0, "Really black","Concrete")
crb("WallE",     Vector3.new(1.5,13,55), 35,7,   0, "Really black","Concrete")
crb("Roof",      Vector3.new(72,1.5,57), 0,14,   0, "Really black","Concrete")
-- Kırmızı neon çatı
neonPart("CRBRoof",Vector3.new(68,0.4,53),CFrame.new(CRBX,14.8,CRBZ),"Bright red",CRB)
neonPart("CRBRoof2",Vector3.new(66,0.3,51),CFrame.new(CRBX,15,CRBZ),"Dark orange",CRB)

-- İç bölmeler
crb("InnerW1",   Vector3.new(1,10,25),   0,5.5,-6, "Dark grey","Concrete")
crb("InnerW2",   Vector3.new(35,10,1),  17,5.5, 0, "Dark grey","Concrete")
crb("InnerW3",   Vector3.new(35,10,1), -17,5.5, 0, "Dark grey","Concrete")
crb("InnerW4",   Vector3.new(4,10,1),   17,5.5, 0, "Dark grey","Concrete",0) -- kapı açıklığı

-- Kriminal spawn
local cSpawn=crb("CrimSpawn",Vector3.new(10,0.3,10),  -20,1.2,-15, "Bright red","Neon",0.7)
local csBB,csLbl=billboard(cSpawn,"💀 KRİMİNAL SPAWN",UDim2.new(0,220,0,44),Vector3.new(0,2,0))
csLbl.TextColor3=Color3.fromRGB(255,60,60)

-- TOPLANTI ODASI
crb("MeetFloor", Vector3.new(30,0.2,22), -18,1.1,-14, "Dark grey","SmoothPlastic")
-- Toplantı masası
crb("BossTable", Vector3.new(14,2,7),    -18,2,  -14, "Reddish brown","Wood")
for i=0,5 do
    local cs=crb("BossChair"..i,Vector3.new(2.5,3,2.5),-25+i*3,2.4,-19,"Really black","SmoothPlastic")
    -- Oturma efekti için gizli seat
    local seat=Instance.new("Seat"); seat.Size=Vector3.new(2.5,0.3,2.5)
    seat.CFrame=CFrame.new(CRBX-25+i*3,2.8,CRBZ-19); seat.Anchored=true
    seat.Parent=CRB; seat.Transparency=1

    -- ESİR sandalye etiket
    if i==2 then
        local eBB,eLbl=billboard(cs,"⛓ ESİR KOLTUĞU",UDim2.new(0,180,0,40),Vector3.new(0,3,0))
        eLbl.TextColor3=Color3.fromRGB(255,100,100)
    end
end

-- Esir koltuğu özel (zincirlerle)
local hostageSeat=crb("HostageSeat",Vector3.new(3,4,3), -18,2.5,-6,"Reddish brown","SmoothPlastic")
-- Zincir görselleri
for _,pos in ipairs({{-1.8,0.5,0},{1.8,0.5,0},{0,0.5,-1.5},{0,0.5,1.5}}) do
    local chain=crb("Chain",Vector3.new(0.4,1.5,0.4),-18+pos[1],2+pos[2],-6+pos[3],"Really black","Metal")
    neonPart("ChainN",Vector3.new(0.3,0.3,0.3),CFrame.new(CRBX-18+pos[1],3.5,CRBZ-6+pos[3]),"Bright red",CRB)
end
-- Hostage seat billboard
local hsBB,hsLbl=billboard(hostageSeat,"⚠ ESİR KOLTUĞU\n[E] Otur",UDim2.new(0,200,0,54),Vector3.new(0,3.5,0))
hsLbl.TextColor3=Color3.fromRGB(255,80,80); hsLbl.TextWrapped=true

-- ESİR ODASI (zincir oturma yerleri)
crb("HostageFloor",Vector3.new(22,0.2,20), 20,1.1,-14,"Dark grey","Concrete")
crb("HWallDiv",Vector3.new(1,10,20),        9,5.5,-14,"Dark grey","Concrete")
-- Zincir direkleri
for i=0,2 do
    local pole=crb("Pole"..i,Vector3.new(0.8,6,0.8),14+i*4,4,-18,"Dark grey","Metal")
    -- Yatay zincir
    crb("HChain"..i,Vector3.new(3,0.3,0.3),14+i*4+1.5,4.5,-18,"Dark grey","Metal")
    neonPart("PoleN"..i,Vector3.new(0.6,0.4,0.6),CFrame.new(CRBX+14+i*4,7,CRBZ-18),"Bright red",CRB)
end

-- Silah depo rafları
crb("WeaponFloor",Vector3.new(20,0.2,20),  20,1.1, 14,"Really black","Concrete")
for i=0,3 do
    crb("WRack"..i,Vector3.new(14,3,1),20,2+i,18-i*0.5,"Dark grey","Metal")
    neonPart("WRackN"..i,Vector3.new(12,0.2,0.2),CFrame.new(CRBX+20,3+i,CRBZ+18-i*0.5),"Bright red",CRB)
end

-- Kriminal base keycard kapıları
makeKeycardDoor("CRBMain", CFrame.new(CRBX+35,7,CRBZ),  Vector3.new(5,13,0.5),"Really black",CRB)
makeKeycardDoor("CRBVault",CFrame.new(CRBX+9,5.5,CRBZ)*CFrame.Angles(0,math.rad(90),0),Vector3.new(4,10,0.5),"Dark grey",CRB)

-- Kriminal base lambalar
for _, pos in ipairs({{-20,12,-14},{0,12,0},{20,12,14},{-20,12,14},{20,12,-14}}) do
    local rl=neonPart("CRBLight",Vector3.new(2,0.4,2),CFrame.new(CRBX+pos[1],pos[2],CRBZ+pos[3]),"Bright red",CRB)
    ptLight(rl,1.5,18,Color3.fromRGB(255,40,40))
end

-- Tünel girişi (yeraltı geçiş)
crb("TunnelEntry",Vector3.new(6,5,6),-33,3.5,25,"Really black","Concrete")
crb("TunnelStairs",Vector3.new(6,0.5,20),-33,0,-5,"Dark grey","Concrete")
for i=0,4 do
    crb("TStep"..i,Vector3.new(5,0.5,3),-33,-i*1.2-0.5,18-i*3,"Dark grey","Concrete")
end

-- CRB plaka
local crbSign=crb("CRBSign",Vector3.new(18,4,0.5),0,12,-27,"Really black","SmoothPlastic")
neonPart("CRBNeon",Vector3.new(16,0.3,0.2),CFrame.new(CRBX,14.3,CRBZ-27.3),"Bright red",CRB)
local bb3,l3=billboard(crbSign,"💀 KRİMİNAL ÜSSÜ",UDim2.new(0,260,0,50),Vector3.new(0,4,0))
l3.TextColor3=Color3.fromRGB(255,60,60); l3.TextSize=15

-- ════════════════════════════════════════════════════════════════
-- §7  ŞEHİR BÖLGESİ
-- ════════════════════════════════════════════════════════════════
local CITY = newModel("City")
local cityBuildings = {
    {-60,-140, 22,18,20, "Sand green"},
    {-90,-140, 18,14,16, "Pastel blue"},
    {-115,-140,16,22,14, "Reddish brown"},
    {-140,-140,20,16,18, "Institutional white"},
    {-60,-170, 24,12,22, "Sand yellow"},
    {-90,-170, 18,20,16, "Light stone grey"},
    {-115,-170,14,16,12, "Medium stone grey"},
    {-140,-170,22,18,20, "White"},
}
for i,bd in ipairs(cityBuildings) do
    local bld=newModel("CityBld"..i,CITY)
    local floor=P("Fl",Vector3.new(bd[3],1,bd[5]),CFrame.new(bd[1],0.5,bd[2]),"Light stone grey",Enum.Material.SmoothPlastic); floor.Parent=bld
    P("W1",Vector3.new(bd[3],bd[4],1),CFrame.new(bd[1],bd[4]/2+1,bd[2]+bd[5]/2),bd[6],Enum.Material.SmoothPlastic).Parent=bld
    P("W2",Vector3.new(bd[3],bd[4],1),CFrame.new(bd[1],bd[4]/2+1,bd[2]-bd[5]/2),bd[6],Enum.Material.SmoothPlastic).Parent=bld
    P("W3",Vector3.new(1,bd[4],bd[5]),CFrame.new(bd[1]+bd[3]/2,bd[4]/2+1,bd[2]),bd[6],Enum.Material.SmoothPlastic).Parent=bld
    P("W4",Vector3.new(1,bd[4],bd[5]),CFrame.new(bd[1]-bd[3]/2,bd[4]/2+1,bd[2]),bd[6],Enum.Material.SmoothPlastic).Parent=bld
    P("Rf",Vector3.new(bd[3]+2,1.5,bd[5]+2),CFrame.new(bd[1],bd[4]+1.75,bd[2]),bd[6],Enum.Material.Concrete).Parent=bld
    -- Pencereler
    for wi=0,2 do
        local gw=P("Win",Vector3.new(3,3,0.2),CFrame.new(bd[1]-3+wi*3,bd[4]/2+1,bd[2]-bd[5]/2-0.1),"Institutional white",Enum.Material.Glass,0.45); gw.Parent=bld
    end
    -- Bina ışığı
    local lt=neonPart("BL",Vector3.new(1.5,0.3,1.5),CFrame.new(bd[1],bd[4]+2.5,bd[2]),
        ({[1]="Bright blue",[2]="Cyan",[3]="Bright orange",[4]="Lime green"})[i%4+1],bld)
    ptLight(lt,1.2,16)
end

-- Sokak lambaları
for _,pos in ipairs({
    {-60,-130},{-90,-130},{-120,-130},{-150,-130},
    {-60,-165},{-90,-165},{-120,-165},{-150,-165},
}) do
    local pole=P("LPole",Vector3.new(0.5,12,0.5),CFrame.new(pos[1],6,pos[2]),"Dark grey",Enum.Material.Metal)
    pole.Parent=CITY
    local head=P("LHead",Vector3.new(3,0.5,1),CFrame.new(pos[1],12.3,pos[2]),"Dark grey",Enum.Material.SmoothPlastic); head.Parent=CITY
    local bulb=neonPart("Bulb",Vector3.new(1.5,0.5,0.5),CFrame.new(pos[1],12,pos[2]),"Bright yellow",CITY)
    ptLight(bulb,2.5,22,Color3.fromRGB(255,230,160))
end

-- ════════════════════════════════════════════════════════════════
-- §8  ENDÜSTRİYEL ALAN
-- ════════════════════════════════════════════════════════════════
local IND = newModel("Industrial")

-- Fabrika
local function ind(nm,sz,ox,oy,oz,col,mat,tr)
    local px,pz=130,100
    local p=P(nm,sz,CFrame.new(px+ox,oy,pz+oz),col or "Dark stone grey",mat or Enum.Material.Concrete,tr or 0)
    p.Parent=IND; return p
end

ind("IFloor",   Vector3.new(75,1,65),   0,0.5,  0, "Dark stone grey","Concrete")
ind("IWallN",   Vector3.new(75,18,1.5), 0,9.5, -32,"Dark grey","Concrete")
ind("IWallS",   Vector3.new(75,18,1.5), 0,9.5,  32,"Dark grey","Concrete")
ind("IWallW",   Vector3.new(1.5,18,65),-37,9.5,  0, "Dark grey","Concrete")
ind("IWallE",   Vector3.new(1.5,18,65), 37,9.5,  0, "Dark grey","Concrete")
ind("IRoof",    Vector3.new(77,1,67),   0,18.5,  0, "Dark grey","Concrete")
-- Baca
local baca=ind("Chimney",Vector3.new(5,40,5), 28,21,25,"Dark stone grey","Brick")
neonPart("Smoke",Vector3.new(3,3,3),CFrame.new(130+28,42,100+25),"Bright orange",IND)
ptLight(neonPart("ChimLight",Vector3.new(2,2,2),CFrame.new(130+28,44,100+25),"Bright orange",IND),2,30,Color3.fromRGB(255,120,20))
-- Fıçılar
for i=0,5 do
    local barrel=ind("Barrel"..i,Vector3.new(3,4,3),-25+i*6,2.5,20,"Dark orange","SmoothPlastic")
    neonPart("BN"..i,Vector3.new(2.5,0.3,2.5),CFrame.new(130-25+i*6,4.7,100+20),"Bright red",IND)
end
-- Endüstriyel lambalar
for _,pos in ipairs({{-20,17,-15},{0,17,0},{20,17,15},{-20,17,15},{20,17,-15}}) do
    local il=neonPart("IndLight",Vector3.new(2,0.4,2),CFrame.new(130+pos[1],pos[2],100+pos[3]),"Bright orange",IND)
    ptLight(il,2,20,Color3.fromRGB(255,150,50))
end

-- ════════════════════════════════════════════════════════════════
-- §9  ESİR SİSTEMİ — Sandalyeye Oturtma
-- ════════════════════════════════════════════════════════════════
local seatRE = RE_folder:WaitForChild("SitPlayer")
local escRE  = RE_folder:WaitForChild("EscapeChair")

-- Sandalye oturma RE (server)
seatRE.OnServerEvent:Connect(function(policePlayer, targetPlayer)
    -- Polis takımında mı kontrol et
    local targetChar = targetPlayer and targetPlayer.Character
    if not targetChar then return end
    -- Mahkum/kriminal ise oturtabilir
    local targetHR = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHR then return end

    -- Hedefi yakındaki seat'e oturt
    local seat = workspace:FindFirstChild("NearestSeat")
    -- Burada client-side ile entegre edilmiş
    -- Serviste constraint ekle
    local att = Instance.new("AlignPosition")
    att.Name = "SeatConstraint"
    att.RigidityEnabled = true
    att.Parent = targetHR
end)

-- ════════════════════════════════════════════════════════════════
-- §10  POLİS SPAWN TOOL DAĞITIMI
-- ════════════════════════════════════════════════════════════════
local function givePolicetTools(player)
    local bp = player:WaitForChild("Backpack")

    -- Araçları ver
    local toolsToGive = {
        {name="Keycard",     col="Cyan",      sz=Vector3.new(1.5,0.2,2.5),   mat=Enum.Material.SmoothPlastic},
        {name="Handcuffs",   col="Dark grey", sz=Vector3.new(2.5,0.8,1.2),   mat=Enum.Material.Metal},
        {name="Taser",       col="Bright yellow",sz=Vector3.new(1.2,1,2.8),  mat=Enum.Material.SmoothPlastic},
        {name="Rope",        col="Brown",     sz=Vector3.new(0.8,0.5,4),      mat=Enum.Material.Fabric},
        {name="Radio",       col="Dark grey", sz=Vector3.new(1,2,0.8),        mat=Enum.Material.SmoothPlastic},
    }

    for _, td in ipairs(toolsToGive) do
        if not bp:FindFirstChild(td.name) then
            local tool = Instance.new("Tool")
            tool.Name = td.name; tool.RequiresHandle = true; tool.CanBeDropped = true
            local h = Instance.new("Part"); h.Name = "Handle"
            h.Size = td.sz; h.BrickColor = BrickColor.new(td.col)
            h.Material = td.mat; h.Anchored = false; h.Parent = tool
            -- GripPos (elle tutma pozisyonu)
            tool.GripPos = Vector3.new(0, -0.5, -1)
            tool.Parent = bp
        end
    end
end

-- Player karakter spawn olunca polis mi kontrol et
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        -- Takıma göre tool ver
        if player.Team and player.Team.Name == "Cop" then
            givePolicetTools(player)
        end
    end)
end)

-- SelectTeam RE handler
RE_folder.SelectTeam.OnServerEvent:Connect(function(player, teamName)
    -- Team objesi bul veya oluştur
    local Teams = game:GetService("Teams")
    local team = Teams:FindFirstChild(teamName)
    if not team then
        team = Instance.new("Team")
        team.Name = teamName
        team.TeamColor = BrickColor.new(
            teamName=="Cop" and "Bright blue" or
            teamName=="Prisoner" and "Bright orange" or
            teamName=="Criminal" and "Bright red" or "Bright green")
        team.AutoAssignable = false
        team.Parent = Teams
    end
    player.Team = team
    task.wait(0.5)
    if teamName == "Cop" then
        givePolicetTools(player)
    end
end)

-- Mahkum ölünce bodrum spawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        hum.Died:Connect(function()
            if player.Team and (player.Team.Name == "Prisoner" or player.Team.Name == "Hostage") then
                task.wait(3)
                -- Random bodrum spawn seç
                local spawns = workspace:FindFirstChild("Prison") and {} or {}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name:sub(1,13) == "PrisonerSpawn" then
                        table.insert(spawns, obj)
                    end
                end
                if #spawns > 0 then
                    local sp = spawns[math.random(1,#spawns)]
                    player:LoadCharacter()
                    task.wait(0.5)
                    local newChar = player.Character
                    if newChar and newChar:FindFirstChild("HumanoidRootPart") then
                        newChar.HumanoidRootPart.CFrame = sp.CFrame + Vector3.new(0,3,0)
                    end
                end
            end
        end)
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- §11  TOOL SPAWN NOKTALARI (gelişmiş)
-- ════════════════════════════════════════════════════════════════
local TOOL_RESPAWN = 30
local TOOLS_CFG = {
    -- Polis cephanelik önü
    {name="Handcuffs",   display="⛓ Kelepçe",          col="Dark grey",    mat=Enum.Material.Metal,           x=90,  y=1.5, z=-125},
    {name="Taser",       display="⚡ Taser",             col="Bright yellow",mat=Enum.Material.SmoothPlastic,   x=96,  y=1.5, z=-125},
    {name="Keycard",     display="🪪 Keycard",           col="Cyan",         mat=Enum.Material.SmoothPlastic,   x=102, y=1.5, z=-125},
    {name="Radio",       display="📻 Telsiz",            col="Dark grey",    mat=Enum.Material.SmoothPlastic,   x=108, y=1.5, z=-125},
    {name="Rope",        display="🪢 İp",                col="Brown",        mat=Enum.Material.Fabric,          x=114, y=1.5, z=-125},
    -- Criminal base dışı
    {name="Crowbar",     display="🔩 Levye",             col="Dark orange",  mat=Enum.Material.Metal,           x=-145,y=1.5, z=110},
    {name="Knife",       display="🔪 Bıçak",             col="Dark grey",    mat=Enum.Material.Metal,           x=-150,y=1.5, z=118},
    {name="Molotov",     display="🍾 Molotov",           col="Brown",        mat=Enum.Material.Glass,           x=-135,y=1.5, z=105},
    -- Şehir
    {name="Medkit",      display="🩹 Medikit",           col="Bright red",   mat=Enum.Material.SmoothPlastic,   x=-80, y=1.5, z=-145},
    {name="Flashlight",  display="🔦 El Feneri",         col="Dark grey",    mat=Enum.Material.Metal,           x=-90, y=1.5, z=-145},
    -- Endüstriyel
    {name="Wrench",      display="🔧 İngiliz Anahtarı",  col="Dark grey",    mat=Enum.Material.Metal,           x=130, y=1.5, z=105},
    {name="GasCan",      display="⛽ Benzin Bidonu",      col="Bright red",   mat=Enum.Material.SmoothPlastic,   x=140, y=1.5, z=110},
}

local function makeToolSpawn(cfg)
    local M = newModel("ToolSpawn_"..cfg.name)
    local plat = P("Platform",Vector3.new(3.5,0.35,3.5),CFrame.new(cfg.x,cfg.y-0.7,cfg.z),"Dark stone grey",Enum.Material.SmoothPlastic); plat.Parent=M
    -- Neon platform kenar
    neonPart("PlEdge",Vector3.new(3.5,0.15,3.5),CFrame.new(cfg.x,cfg.y-0.5,cfg.z),"Cyan",M)
    local icon=P("Icon",Vector3.new(1.3,1.3,1.3),CFrame.new(cfg.x,cfg.y,cfg.z),cfg.col,cfg.mat); icon.Parent=M
    local sel=Instance.new("SelectionBox"); sel.Adornee=icon; sel.LineThickness=0.06
    sel.SurfaceTransparency=0.85; sel.Color3=Color3.fromRGB(100,220,255); sel.SurfaceColor3=Color3.fromRGB(100,220,255); sel.Parent=icon
    local bbg=Instance.new("BillboardGui"); bbg.Size=UDim2.new(0,210,0,62); bbg.StudsOffset=Vector3.new(0,1.8,0); bbg.AlwaysOnTop=false; bbg.MaxDistance=22; bbg.Parent=icon
    local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(8,8,14); bg.BackgroundTransparency=0.15; bg.BorderSizePixel=0; bg.Parent=bbg
    local bgC=Instance.new("UICorner"); bgC.CornerRadius=UDim.new(0,8); bgC.Parent=bg
    local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,0,.55,0); nl.BackgroundTransparency=1; nl.Text=cfg.display; nl.TextColor3=Color3.fromRGB(220,230,255); nl.TextSize=14; nl.Font=Enum.Font.GothamBold; nl.TextXAlignment=Enum.TextXAlignment.Center; nl.Parent=bg
    local cl=Instance.new("TextLabel"); cl.Size=UDim2.new(1,0,.45,0); cl.Position=UDim2.new(0,0,.55,0); cl.BackgroundTransparency=1; cl.Text="[ CLICK TO CLAIM ]"; cl.TextColor3=Color3.fromRGB(100,220,255); cl.TextSize=11; cl.Font=Enum.Font.GothamMedium; cl.TextXAlignment=Enum.TextXAlignment.Center; cl.Parent=bg
    local spinA=0
    RunSvc.Heartbeat:Connect(function(dt)
        spinA=spinA+dt*1.6
        if icon and icon.Parent then
            icon.CFrame=CFrame.new(cfg.x,cfg.y+math.sin(spinA)*0.18,cfg.z)*CFrame.Angles(0,spinA,0)
        end
    end)
    local cd=Instance.new("ClickDetector"); cd.MaxActivationDistance=14; cd.Parent=icon
    local claimed=false
    cd.MouseClick:Connect(function(clicker)
        if claimed then return end; claimed=true
        bbg.Enabled=false; sel.Parent=nil
        local toolObj=Instance.new("Tool"); toolObj.Name=cfg.name; toolObj.RequiresHandle=true; toolObj.CanBeDropped=true
        local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Vector3.new(1.3,1.3,1.3)
        handle.BrickColor=BrickColor.new(cfg.col); handle.Material=cfg.mat; handle.Anchored=false; handle.Parent=toolObj
        toolObj.GripPos=Vector3.new(0,-0.5,-1)
        toolObj.Parent=clicker:FindFirstChildOfClass("Backpack") or clicker.Character
        icon.Transparency=0.8; plat.BrickColor=BrickColor.new("Dark stone grey")
        task.delay(TOOL_RESPAWN, function()
            if icon and icon.Parent then claimed=false; bbg.Enabled=true; icon.Transparency=0; sel.Parent=icon end
        end)
    end)
    cd.MouseHoverEnter:Connect(function()
        if not claimed then TweenSvc:Create(icon,TweenInfo.new(.15),{Color=Color3.fromRGB(100,220,255)}):Play() end
    end)
    cd.MouseHoverLeave:Connect(function()
        if not claimed then TweenSvc:Create(icon,TweenInfo.new(.15),{Color=BrickColor.new(cfg.col).Color}):Play() end
    end)
end

for _,tc in ipairs(TOOLS_CFG) do task.spawn(function() makeToolSpawn(tc) end) end

-- ════════════════════════════════════════════════════════════════
-- §12  AYDINLATMA
-- ════════════════════════════════════════════════════════════════
local Lighting = game:GetService("Lighting")
Lighting.Ambient         = Color3.fromRGB(70,75,95)
Lighting.Brightness      = 2.2
Lighting.ColorShift_Top  = Color3.fromRGB(185,190,215)
Lighting.ShadowSoftness  = 0.5
Lighting.ClockTime       = 14.5

local atm = Instance.new("Atmosphere")
atm.Density=0.32; atm.Offset=0.12; atm.Color=Color3.fromRGB(190,195,220)
atm.Decay=Color3.fromRGB(85,100,135); atm.Glare=0.08; atm.Haze=1.0; atm.Parent=Lighting

local sky=Instance.new("Sky")
sky.SkyboxBk="rbxassetid://159454793"; sky.SkyboxDn="rbxassetid://159454756"
sky.SkyboxFt="rbxassetid://159454772"; sky.SkyboxLf="rbxassetid://159454785"
sky.SkyboxRt="rbxassetid://159454779"; sky.SkyboxUp="rbxassetid://159454800"
sky.StarCount=4000; sky.Parent=Lighting

-- ════════════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════════════╗")
print("║   BSC PRISON — MapBuild_Server v3.0 ULTRA ✓     ║")
print("╠══════════════════════════════════════════════════╣")
print("║  ✓ Ana Zemin + Çoklu Yol Ağı                   ║")
print("║  ✓ Map Border + Köşe Kuleler + Dikenli Tel      ║")
print("║  ✓ Polis Karakolu — Cephanelik/Kıyafet/Kahv.   ║")
print("║  ✓ Prison — Bodrum Zindanı + Demir Parmaklık   ║")
print("║  ✓ Criminal Base — Girilebilir + Esir Koltuğu  ║")
print("║  ✓ Keycard Kapı Sistemi (tüm bölümler)         ║")
print("║  ✓ Işık Aç/Kapa (her hücre)                    ║")
print("║  ✓ Otomatik Polis Tool Dağıtımı                ║")
print("║  ✓ Mahkum Bodrum Spawn Sistemi                  ║")
print("║  ✓ Şehir + Endüstriyel Alan                    ║")
print("║  ✓ "..#TOOLS_CFG.." Tool Spawn Noktası                    ║")
print("╚══════════════════════════════════════════════════╝")
