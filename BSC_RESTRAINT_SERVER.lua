--[[
================================================================
  BSC_RESTRAINT_SERVER.lua | ServerScriptService
================================================================
  - ApplyRestraint: kelepçe/ip/zincir uygula
  - RemoveRestraint: serbest bırak
  - Aynı takım kelepçeleyemez
  - Kısıtlanan oyuncu tool kullanamaz + zıplayamaz
  - Görsel: metal kelepçe halkası + RopeConstraint ip/zincir
  - Tüm görseller server'da oluşturuluyor → herkes görür
================================================================
--]]

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Remotes   = RS:WaitForChild("Remotes", 15)
if not Remotes then warn("[RESTRAINT] Remotes yok!"); return end

local R_Apply   = Remotes:WaitForChild("ApplyRestraint",  15)
local R_Remove  = Remotes:WaitForChild("RemoveRestraint", 15)
local R_Escape  = Remotes:WaitForChild("EscapeAttempt",   15)
local R_CuffTog = Remotes:WaitForChild("CuffModeToggle",  15)

if not R_Apply   then warn("[RESTRAINT] ApplyRestraint remote yok!"); return end
if not R_Remove  then warn("[RESTRAINT] RemoveRestraint remote yok!"); return end
if not R_CuffTog then warn("[RESTRAINT] CuffModeToggle remote yok!"); return end

-- Kısıtlanınca bloklanacak tool'lar
local BLOCKED = {Handcuff=true, Taser=true, Chain=true, Rope=true, Keycard=true}

-- Görsel parçalar registry
local vizReg = {}  -- [char] = {instance, ...}

-- ── GÖRSEL YARDIMCILAR ────────────────────────────────────────────────
local function regV(char, ...)
    if not vizReg[char] then vizReg[char] = {} end
    for _, v in ipairs({...}) do
        if v then table.insert(vizReg[char], v) end
    end
end

local function clearV(char)
    if not vizReg[char] then return end
    for _, v in ipairs(vizReg[char]) do
        pcall(function() v:Destroy() end)
    end
    vizReg[char] = nil
end

local function mkPart(char, sz, col, mat, trans)
    local p = Instance.new("Part")
    p.Size = sz; p.BrickColor = BrickColor.new(col or "Medium stone grey")
    p.Material = mat or Enum.Material.Metal
    p.Transparency = trans or 0
    p.CanCollide = false; p.CastShadow = false; p.Anchored = false
    p.Parent = char
    return p
end

local function weld(part, anchor, offset)
    part.CFrame = anchor.CFrame * (offset or CFrame.new())
    local w = Instance.new("Weld")
    w.Part0 = anchor; w.Part1 = part
    w.C0 = offset or CFrame.new(); w.C1 = CFrame.new()
    w.Parent = anchor
    return w
end

local function mkAtt(part, pos)
    local a = Instance.new("Attachment")
    a.Position = pos or Vector3.new(0,0,0)
    a.Parent = part
    return a
end

local function mkRope(parent, a0, a1, col, thick, len)
    local r = Instance.new("RopeConstraint")
    r.Attachment0 = a0; r.Attachment1 = a1
    r.Length = len or math.max((a0.WorldPosition - a1.WorldPosition).Magnitude + 0.02, 0.05)
    r.Visible = true
    r.Color = BrickColor.new(col or "Reddish brown")
    r.Thickness = thick or 0.024
    r.Restitution = 0
    r.Parent = parent
    return r
end

local function mkAnchor(char, offsetCF)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local p = mkPart(char, Vector3.new(0.05,0.05,0.05), "Black", Enum.Material.SmoothPlastic, 1)
    local w = Instance.new("Weld")
    w.Part0 = hrp; w.Part1 = p; w.C0 = offsetCF or CFrame.new(); w.Parent = hrp
    return p, w
end

local function mkCuffRing(char, arm, yOff, isChain)
    local r = mkPart(char, Vector3.new(0.24,0.11,0.24),
        isChain and "Dark grey metallic" or "Fossil",
        Enum.Material.Metal)
    r.Reflectance = 0.45
    local m = Instance.new("SpecialMesh")
    m.MeshType = Enum.MeshType.Cylinder; m.Scale = Vector3.new(0.38,1,1); m.Parent = r
    local w = weld(r, arm, CFrame.new(0, yOff, 0))
    return r, w, m
end

-- ── GÖRSELLERİ UYGULA ────────────────────────────────────────────────

-- ÖN KELEPÇE
local function vizHandcuffFront(char)
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    if not lA or not rA then return end

    local rL, wL, mL = mkCuffRing(char, lA, -0.86)
    local rR, wR, mR = mkCuffRing(char, rA, -0.86)
    local aL = mkAtt(lA, Vector3.new(0,-0.89,0))
    local aR = mkAtt(rA, Vector3.new(0,-0.89,0))
    local rope = mkRope(char, aL, aR, "Reddish brown", 0.022, 0.24)
    regV(char, rL,wL,mL, rR,wR,mR, aL,aR, rope)
end

-- ARKA KELEPÇE
local function vizHandcuffBack(char)
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    if not lA or not rA then return end

    local rL, wL, mL = mkCuffRing(char, lA, -0.86)
    local rR, wR, mR = mkCuffRing(char, rA, -0.86)
    local aL = mkAtt(lA, Vector3.new(0,-0.89,0))
    local aR = mkAtt(rA, Vector3.new(0,-0.89,0))

    local mid, mw = mkAnchor(char, CFrame.new(0,-0.2,0.30))
    if not mid then return end
    local am = mkAtt(mid)
    local r1 = mkRope(char, aL, am, "Reddish brown", 0.022, 0.38)
    local r2 = mkRope(char, aR, am, "Reddish brown", 0.022, 0.38)
    regV(char, rL,wL,mL, rR,wR,mR, aL,aR, mid,mw,am,r1,r2)
end

-- İP BAĞLAMA
local function vizRope(char, mode)
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    if not lA or not rA then return end

    local function wrap(arm, yBase)
        local parts = {}
        for i = 1, 3 do
            local p = mkPart(char, Vector3.new(0.27,0.07,0.27), "Reddish brown", Enum.Material.Fabric)
            local m = Instance.new("SpecialMesh")
            m.MeshType = Enum.MeshType.Cylinder; m.Scale = Vector3.new(0.32,1,1); m.Parent = p
            local w = weld(p, arm, CFrame.new(0, yBase-(i-1)*0.09, 0))
            table.insert(parts, p); table.insert(parts, m); table.insert(parts, w)
        end
        return parts
    end

    local pL = wrap(lA, -0.80)
    local pR = wrap(rA, -0.80)
    local aL = mkAtt(lA, Vector3.new(0,-0.90,0))
    local aR = mkAtt(rA, Vector3.new(0,-0.90,0))

    regV(char, aL, aR)
    for _, v in ipairs(pL) do regV(char, v) end
    for _, v in ipairs(pR) do regV(char, v) end

    if mode == "Back" then
        local mid, mw = mkAnchor(char, CFrame.new(0,-0.2,0.28))
        if not mid then return end
        local am = mkAtt(mid)
        regV(char, mid,mw,am,
            mkRope(char, aL, am, "Reddish brown", 0.026, 0.36),
            mkRope(char, aR, am, "Reddish brown", 0.026, 0.36))
    else
        regV(char, mkRope(char, aL, aR, "Reddish brown", 0.026, 0.24))
    end
end

-- HOGTIED
local function vizHogtied(char)
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    local lL = char:FindFirstChild("Left Leg")
    local rL_part = char:FindFirstChild("Right Leg")
    if not lA or not rA or not lL or not rL_part then return end

    local function ring(arm, y)
        local r = mkPart(char, Vector3.new(0.24,0.10,0.24), "Reddish brown", Enum.Material.Fabric)
        local m = Instance.new("SpecialMesh"); m.MeshType=Enum.MeshType.Cylinder; m.Scale=Vector3.new(0.35,1,1); m.Parent=r
        local w = weld(r, arm, CFrame.new(0,y,0))
        return r,m,w
    end

    local rWL,mWL,wWL = ring(lA, -0.85)
    local rWR,mWR,wWR = ring(rA, -0.85)
    local rAL,mAL,wAL = ring(lL, -0.90)
    local rAR,mAR,wAR = ring(rL_part, -0.90)

    local aWL = mkAtt(lA, Vector3.new(0,-0.88,0))
    local aWR = mkAtt(rA, Vector3.new(0,-0.88,0))
    local aAL = mkAtt(lL, Vector3.new(0,-0.92,0))
    local aAR = mkAtt(rL_part, Vector3.new(0,-0.92,0))

    regV(char,
        rWL,mWL,wWL, rWR,mWR,wWR, rAL,mAL,wAL, rAR,mAR,wAR,
        aWL,aWR,aAL,aAR,
        mkRope(char, aWL, aWR, "Reddish brown", 0.024, 0.24),
        mkRope(char, aAL, aAR, "Reddish brown", 0.024, 0.24),
        mkRope(char, aWL, aAL, "Reddish brown", 0.024, 0.50),
        mkRope(char, aWR, aAR, "Reddish brown", 0.024, 0.50))
end

-- ZİNCİR (Chained)
local function vizChained(char)
    local head = char:FindFirstChild("Head")
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    if not head then return end

    -- Metal yaka
    local collar = mkPart(char, Vector3.new(0.60,0.14,0.60), "Dark grey metallic", Enum.Material.Metal)
    collar.Reflectance = 0.50
    local colMesh = Instance.new("SpecialMesh")
    colMesh.MeshType = Enum.MeshType.Cylinder; colMesh.Scale = Vector3.new(0.30,1,1); colMesh.Parent = collar
    local colWeld = weld(collar, head, CFrame.new(0,-0.66,0))

    -- D-ring
    local dring = mkPart(char, Vector3.new(0.08,0.12,0.08), "Dark grey metallic", Enum.Material.Metal)
    dring.Reflectance = 0.55
    local drWeld = weld(dring, head, CFrame.new(0,-0.66,-0.28))

    -- Zincir sarkma noktası
    local cEnd, cWeld = mkAnchor(char, CFrame.new(0,-1.35,-0.52))
    if not cEnd then return end

    local aNeck = mkAtt(dring,    Vector3.new(0,0,-0.04))
    local aEnd  = mkAtt(cEnd,    Vector3.new(0,0,0))

    local neckChain = mkRope(char, aNeck, aEnd, "Dark grey metallic", 0.032, 0.78)
    neckChain.Color = BrickColor.new("Dark grey metallic")

    regV(char, collar,colMesh,colWeld, dring,drWeld, cEnd,cWeld, aNeck,aEnd, neckChain)

    -- Bilek halkası + zincir ucu → bilek ipi
    for _, armName in ipairs({"Left Arm","Right Arm"}) do
        local arm = char:FindFirstChild(armName)
        if arm then
            local ring, rw, rm = mkCuffRing(char, arm, -0.85, true)
            local aW = mkAtt(arm, Vector3.new(0,-0.87,0))
            local ropeW = mkRope(char, aEnd, aW, "Reddish brown", 0.022, 0.68)
            regV(char, ring,rw,rm, aW,ropeW)
        end
    end

    -- Bilekler arası kısa ip
    if lA and rA then
        local aL = mkAtt(lA, Vector3.new(0,-0.87,0))
        local aR_att = mkAtt(rA, Vector3.new(0,-0.87,0))
        regV(char, aL, aR_att, mkRope(char, aL, aR_att, "Reddish brown", 0.020, 0.26))
    end
end

-- ── DURUM UYGULA ─────────────────────────────────────────────────────
local function applyState(char, state, mode)
    clearV(char)

    char:SetAttribute("RestraintState", state)
    char:SetAttribute("CuffMode", mode or "Front")

    if state == "Handcuffed" then
        if mode == "Back" then vizHandcuffBack(char)
        else vizHandcuffFront(char) end
    elseif state == "RopeTied" then
        vizRope(char, mode or "Front")
    elseif state == "Hogtied" then
        vizHogtied(char)
    elseif state == "Chained" then
        vizChained(char)
    end
    -- Stunned ve Free için görsel yok
end

-- ── TOOL BLOKLAMA ─────────────────────────────────────────────────────
local function blockTools(player, blocked)
    local char = player.Character
    local bp   = player:FindFirstChild("Backpack")

    local function check(t)
        if not t:IsA("Tool") then return end
        if not BLOCKED[t.Name] then return end
        t:SetAttribute("Blocked", blocked)
        -- Elindeyse bıraktır
        if blocked and char and t.Parent == char then
            t.Parent = bp or char
        end
    end

    if bp then for _, t in ipairs(bp:GetChildren()) do check(t) end end
    if char then for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then check(t) end
    end end
end

local function setJump(player, canJump)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.JumpPower  = canJump and 50  or 0
        h.JumpHeight = canJump and 7.2 or 0
    end
end

-- ── AYNI TAKIM KONTROLÜ ───────────────────────────────────────────────
local function sameTeam(p1, p2)
    local t1 = p1:GetAttribute("Team") or ""
    local t2 = p2:GetAttribute("Team") or ""
    return t1 ~= "" and t1 == t2
end

-- ── ApplyRestraint ────────────────────────────────────────────────────
-- Client → Server: (targetChar, restraintType)
-- restraintType: "Handcuff" | "Rope" | "Chain" | "Hogtied" | "Taser"
R_Apply.OnServerEvent:Connect(function(officer, targetChar, rType)
    -- Officer sağlıklı mı?
    if not officer.Character then return end
    if (officer.Character:GetAttribute("RestraintState") or "Free") ~= "Free" then return end

    -- Hedef geçerli mi?
    if not targetChar or not targetChar:IsA("Model") then return end
    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if not targetPlayer or targetPlayer == officer then return end

    -- Aynı takım kontrolü
    if sameTeam(officer, targetPlayer) then
        warn("[RESTRAINT] Aynı takım engellendi:", officer.Name, "→", targetPlayer.Name)
        return
    end

    -- Hedef canlı mı?
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Spam koruması
    local now = tick()
    if (officer:GetAttribute("_cuffCD") or 0) + 1.5 > now then return end
    officer:SetAttribute("_cuffCD", now)

    -- Type → State
    local typeMap = {
        Handcuff = "Handcuffed",
        Rope     = "RopeTied",
        Chain    = "Chained",
        Hogtied  = "Hogtied",
        Taser    = "Stunned",
    }
    local newState = typeMap[rType]
    if not newState then
        warn("[RESTRAINT] Bilinmeyen tip:", rType)
        return
    end

    local mode = officer.Character:GetAttribute("CuffMode") or "Front"
    applyState(targetChar, newState, mode)
    blockTools(targetPlayer, true)
    setJump(targetPlayer, false)

    print(string.format("[RESTRAINT] %s → %s : %s (%s)",
        officer.Name, targetPlayer.Name, newState, mode))

    -- Taser: 8 saniye sonra otomatik serbest
    if newState == "Stunned" then
        task.delay(8, function()
            if targetChar and targetChar.Parent then
                if targetChar:GetAttribute("RestraintState") == "Stunned" then
                    applyState(targetChar, "Free")
                    blockTools(targetPlayer, false)
                    setJump(targetPlayer, true)
                end
            end
        end)
    end
end)

-- ── RemoveRestraint ───────────────────────────────────────────────────
R_Remove.OnServerEvent:Connect(function(officer, targetChar)
    if not targetChar then return end
    local tp = Players:GetPlayerFromCharacter(targetChar)
    if not tp then return end
    applyState(targetChar, "Free")
    blockTools(tp, false)
    setJump(tp, true)
    print("[RESTRAINT] Serbest:", tp.Name, "by", officer.Name)
end)

-- ── EscapeAttempt ─────────────────────────────────────────────────────
if R_Escape then
    R_Escape.OnServerEvent:Connect(function(player, success)
        local char = player.Character; if not char then return end
        if (char:GetAttribute("RestraintState") or "Free") == "Free" then return end
        if success then
            applyState(char, "Free")
            blockTools(player, false)
            setJump(player, true)
            print("[RESTRAINT] Escape:", player.Name)
        end
    end)
end

-- ── CuffModeToggle ─────────────────────────────────────────────────────
R_CuffTog.OnServerEvent:Connect(function(officer)
    if not officer.Character then return end
    local cur = officer.Character:GetAttribute("CuffMode") or "Front"
    local new = cur == "Front" and "Back" or "Front"
    officer.Character:SetAttribute("CuffMode", new)
    R_CuffTog:FireClient(officer, new)
end)

-- ── Spawn / Ölüm ──────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        char:SetAttribute("RestraintState", "Free")
        char:SetAttribute("CuffMode", "Front")
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Once(function()
                clearV(char)
                blockTools(player, false)
                char:SetAttribute("RestraintState", "Free")
            end)
        end
    end)
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        p.Character:SetAttribute("RestraintState", "Free")
        p.Character:SetAttribute("CuffMode", "Front")
    end
end

print("[RESTRAINT_SERVER] ✅ Hazır")
