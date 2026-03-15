-- ============================================================
--  SNG BATTLEGROUND — CA_ANIM_CLIENT  [v1 — Entegre]
--  Konum: StarterCharacterScripts > LocalScript
--
--  CA v3 Animasyon Motoru + SNG sistemi entegrasyonu
--
--  Ne yapar:
--    1. R6 animasyonları (Idle/Walk/Run/Jump/Swim/Climb) oynatır
--    2. _G.PlayGojoAnim(name, looped) → yetenek animasyonları
--    3. Diğer oyuncuların animasyonlarını da oynatır
--    4. Animate/Animator script'lerini devre dışı bırakır
--    5. MAIN_UI'daki stamina ile çakışmaz (o stamina UI kendi çalışır)
--
--  Bağımlılıklar:
--    ReplicatedStorage.PlayAnimationState (RemoteEvent)
--    ReplicatedStorage.Animations (Folder)
--      └ Idle, Walk, Run, Jump, Swim, Climb (KeyframeSequence)
--      └ [opsiyonel] Blue, Red, Purple, Domain, Infinity
-- ============================================================

local TweenSvc   = game:GetService("TweenService")
local RunSvc     = game:GetService("RunService")
local Players    = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")

-- BSC anim sistemi yüklüyse bu eski script'i pasif bırak.
local remotes = RepStorage:FindFirstChild("Remotes")
if remotes and remotes:FindFirstChild("PlayAnim") then
    warn("[CA_ANIM] BSC PlayAnim bulundu, CA_ANIM pasif bırakıldı.")
    return
end

local Char        = script.Parent
local Hum         = Char:WaitForChild("Humanoid")
local LocalPlayer = Players:GetPlayerFromCharacter(Char)
if not LocalPlayer then return end

-- ─── Animasyon klasörünü bekle ─────────────────────────────────
local AnimationsFolder = RepStorage:WaitForChild("Animations", 20)
if not AnimationsFolder then
    warn("[CA_ANIM] Animations klasörü bulunamadı! RepStorage'a ekle.")
    -- Sadece PlayGojoAnim boş stub ile bırak ki GOJO_CLIENT hata vermesin
    _G.PlayGojoAnim = function() end
    return
end

local PlayAnimationState = RepStorage:WaitForChild("PlayAnimationState", 10)
if not PlayAnimationState then
    warn("[CA_ANIM] PlayAnimationState RemoteEvent bulunamadı!")
    _G.PlayGojoAnim = function() end
    return
end

-- ─── Ayarlar ──────────────────────────────────────────────────
local ENABLE_INTERPOLATION = true
local ENABLE_BLENDING      = true

-- ─── Animasyon Dizileri ────────────────────────────────────────
local AnimSequences = {
    Idle    = AnimationsFolder:FindFirstChild("Idle"),
    Walk    = AnimationsFolder:FindFirstChild("Walk"),
    Run     = AnimationsFolder:FindFirstChild("Run"),
    Jump    = AnimationsFolder:FindFirstChild("Jump"),
    Swim    = AnimationsFolder:FindFirstChild("Swim"),
    Climb   = AnimationsFolder:FindFirstChild("Climb"),
    -- Yetenek animasyonları (opsiyonel)
    Blue    = AnimationsFolder:FindFirstChild("Blue"),
    Red     = AnimationsFolder:FindFirstChild("Red"),
    Purple  = AnimationsFolder:FindFirstChild("Purple"),
    Domain  = AnimationsFolder:FindFirstChild("Domain"),
    Infinity= AnimationsFolder:FindFirstChild("Infinity"),
}

-- EasingStyle dönüşümleri
local EasingStyles = {
    [Enum.PoseEasingStyle.Linear]   = Enum.EasingStyle.Linear,
    [Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
    [Enum.PoseEasingStyle.Elastic]  = Enum.EasingStyle.Elastic,
    [Enum.PoseEasingStyle.Cubic]    = Enum.EasingStyle.Cubic,
    [Enum.PoseEasingStyle.Bounce]   = Enum.EasingStyle.Bounce,
}
local EasingDirections = {
    [Enum.PoseEasingDirection.In]    = Enum.EasingDirection.In,
    [Enum.PoseEasingDirection.Out]   = Enum.EasingDirection.Out,
    [Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}

-- ================================================================
--  R6SequencePlayer — CA v3 Animasyon Motoru
-- ================================================================
local R6SequencePlayer = {}
R6SequencePlayer.__index = R6SequencePlayer

function R6SequencePlayer.new(character, sequence, isLooping)
    return setmetatable({
        Character    = character,
        Sequence     = sequence,
        IsLooping    = isLooping,
        MotorCache   = {},
        TweenTracks  = {},
        ActiveTweens = {},
        keyframePoses= {},
        IsPlaying    = false,
        ExcessTime   = 0,
    }, R6SequencePlayer)
end

function R6SequencePlayer:FindMotor(pose)
    local part1Name = pose.Name
    local part0Name = pose.Parent.Name
    for _, motor in pairs(self.Character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part1 and motor.Part0 then
            if motor.Part1.Name == part1Name and motor.Part0.Name == part0Name then
                return motor
            end
        end
    end
    return nil
end

function R6SequencePlayer:ResetPoses(transitionTime)
    local t = ENABLE_BLENDING and (transitionTime or 0.15) or 0
    for _, motor in pairs(self.MotorCache) do
        if motor and motor.Parent then
            TweenSvc:Create(motor, TweenInfo.new(t, Enum.EasingStyle.Linear), {Transform = CFrame.new()}):Play()
        end
    end
end

function R6SequencePlayer:PlayCycle()
    for _, group in ipairs(self.TweenTracks) do
        if not self.IsPlaying then return end
        self.ActiveTweens = {}
        local longestTween, longestTime = nil, 0
        for _, tween in pairs(group.Tweens) do
            tween:Play()
            table.insert(self.ActiveTweens, tween)
            if tween.TweenInfo.Time > longestTime then
                longestTime = tween.TweenInfo.Time
                longestTween = tween
            end
        end
        if longestTween and longestTime > 0 then
            longestTween.Completed:Wait()
        elseif group.Time > 0 then
            task.wait(group.Time)
        else
            RunSvc.Heartbeat:Wait()
        end
        self.ActiveTweens = {}
    end
end

function R6SequencePlayer:Play()
    if self.IsPlaying then return end
    self.IsPlaying = true
    if #self.keyframePoses > 0 then
        local firstPoses = self.keyframePoses[1].Poses
        for motorName, pose in pairs(firstPoses) do
            local motor = self.MotorCache[motorName]
            if motor and motor.Parent then motor.Transform = pose.CFrame end
        end
    end
    task.spawn(function()
        if self.IsLooping then
            while self.IsPlaying do self:PlayCycle() end
        else
            self:PlayCycle()
            if self.IsPlaying and #self.keyframePoses > 0 then
                local last = self.keyframePoses[#self.keyframePoses].Poses
                for motorName, pose in pairs(last) do
                    local motor = self.MotorCache[motorName]
                    if motor and motor.Parent then motor.Transform = pose.CFrame end
                end
            end
            self.IsPlaying = false
        end
    end)
end

function R6SequencePlayer:Stop()
    if not self.IsPlaying then return end
    self.IsPlaying = false
    for _, tween in ipairs(self.ActiveTweens) do
        if tween and tween.PlaybackState == Enum.PlaybackState.Playing then tween:Cancel() end
    end
    self.ActiveTweens = {}
    self:ResetPoses(0.1)
end

function R6SequencePlayer:Load()
    if not self.Sequence then return end
    local allKF = {}
    for _, kf in pairs(self.Sequence:GetKeyframes()) do table.insert(allKF, kf) end
    table.sort(allKF, function(a, b) return a.Time < b.Time end)

    self.keyframePoses = {}; self.TweenTracks = {}; self.ExcessTime = 0

    if #allKF > 1 then
        local lastKF = allKF[#allKF]; local hasWeightedPose = false
        for _, d in pairs(lastKF:GetDescendants()) do
            if d:IsA("Pose") and d.Weight > 0 then hasWeightedPose = true; break end
        end
        if not hasWeightedPose then
            self.ExcessTime = lastKF.Time - allKF[#allKF - 1].Time
            table.remove(allKF, #allKF)
        end
    end
    if #allKF == 0 then return end

    local motorPoseData = {}
    for i, kf in ipairs(allKF) do
        self.keyframePoses[i] = {Time = kf.Time, Poses = {}}
        for _, pose in pairs(kf:GetDescendants()) do
            if pose:IsA("Pose") and pose.Weight > 0 then
                local key = pose.Name .. "." .. pose.Parent.Name
                if not motorPoseData[key] then
                    local motor = self:FindMotor(pose)
                    if motor then
                        motorPoseData[key] = {Motor = motor, Name = motor.Name}
                        self.MotorCache[motor.Name] = motor
                    end
                end
                if motorPoseData[key] then
                    self.keyframePoses[i].Poses[motorPoseData[key].Name] = pose
                end
            end
        end
    end

    local lastPoseData = {}
    for i = 1, #allKF - 1 do
        local kf1 = self.keyframePoses[i]; local kf2 = self.keyframePoses[i + 1]
        local timeDiff = kf2.Time - kf1.Time
        self.TweenTracks[i] = {Time = timeDiff, Tweens = {}}
        local dur = ENABLE_INTERPOLATION and timeDiff or 0
        for name, pose in pairs(kf1.Poses) do lastPoseData[name] = pose end
        for name, pose2 in pairs(kf2.Poses) do
            local pose1 = lastPoseData[name]
            if pose1 and self.MotorCache[name] then
                local style = EasingStyles[pose1.EasingStyle] or Enum.EasingStyle.Linear
                local dir   = EasingDirections[pose1.EasingDirection] or Enum.EasingDirection.Out
                self.TweenTracks[i].Tweens[name] = TweenSvc:Create(
                    self.MotorCache[name], TweenInfo.new(dur, style, dir), {Transform = pose2.CFrame}
                )
            end
        end
    end

    if self.IsLooping and #allKF > 0 then
        local lastKFData  = self.keyframePoses[#allKF]
        local firstKFData = self.keyframePoses[1]
        local loopTime    = self.ExcessTime > 0 and self.ExcessTime or 0
        local idx = #self.TweenTracks + 1
        self.TweenTracks[idx] = {Time = loopTime, Tweens = {}}
        local dur = ENABLE_INTERPOLATION and loopTime or 0
        for name, pose in pairs(lastKFData.Poses) do lastPoseData[name] = pose end
        for name, pose1 in pairs(firstKFData.Poses) do
            local poseLast = lastPoseData[name]
            if poseLast and self.MotorCache[name] then
                local style = EasingStyles[poseLast.EasingStyle] or Enum.EasingStyle.Linear
                local dir   = EasingDirections[poseLast.EasingDirection] or Enum.EasingDirection.Out
                self.TweenTracks[idx].Tweens[name] = TweenSvc:Create(
                    self.MotorCache[name], TweenInfo.new(dur, style, dir), {Transform = pose1.CFrame}
                )
            end
        end
    end
end

-- ================================================================
--  Karakter Kurulum
-- ================================================================
local CharacterStates = {}

-- Seat'ları kaldır (CA v3 gereksinimi)
for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Seat") then d:Destroy() end
end

local function disableDefaultAnimations(char)
    -- Roblox'un Animator'ını kapat
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then animator:Destroy() end
    end
    -- Varsayılan Animate script'ini kaldır
    local animate = char:FindFirstChild("Animate")
    if animate then animate:Destroy() end
end

local function setupCharacter(targetChar)
    if CharacterStates[targetChar] then return CharacterStates[targetChar] end

    disableDefaultAnimations(targetChar)

    local players = {}
    for stateName, seq in pairs(AnimSequences) do
        if seq then
            local isLoop = (stateName ~= "Jump")  -- Jump looplamaz, diğerleri loop
            local sp = R6SequencePlayer.new(targetChar, seq, isLoop)
            sp:Load()
            players[stateName] = sp
        end
    end

    local stateTable = {
        Players = players,
        Current = {player = nil, state = "None"},
    }
    CharacterStates[targetChar] = stateTable

    targetChar.Destroying:Connect(function()
        local d = CharacterStates[targetChar]
        if d and d.Current.player then d.Current.player:Stop() end
        CharacterStates[targetChar] = nil
    end)

    return stateTable
end

-- ─── Kendi karakterimizi kur ──────────────────────────────────
local myData = setupCharacter(Char)

-- ─── Animasyon oynatma yardımcıları ───────────────────────────
local currentAnimPlayer = nil
local currentState      = "None"

local function stopCurrent()
    if currentAnimPlayer then
        currentAnimPlayer:Stop()
        currentAnimPlayer = nil
    end
end

local function playAnim(state)
    if currentState == state then return end
    stopCurrent()
    local p = myData.Players[state]
    if p then
        p:Play()
        currentAnimPlayer = p
        currentState = state
    end
end

-- ================================================================
--  _G.PlayGojoAnim — GOJO_CLIENT bu fonksiyonu çağırır
--  Yetenek animasyonunu oynatır, bitince Idle'a döner
-- ================================================================
_G.PlayGojoAnim = function(name, looped)
    local p = myData.Players[name]
    if not p then
        -- Animasyon yoksa sadece uyar, Idle devam eder
        warn("[CA_ANIM] Yetenek animasyonu bulunamadı:", name, "— Animations klasörüne ekle")
        return
    end
    stopCurrent()
    p.IsLooping = looped == true
    p:Play()
    currentAnimPlayer = p
    currentState = name
    if not looped then
        -- Animasyon bitince Idle'a dön
        task.spawn(function()
            -- Animasyonun bitmesini bekle (yaklaşık süre)
            local totalTime = 0
            for _, track in ipairs(p.TweenTracks) do totalTime += track.Time end
            task.wait(math.max(totalTime, 0.1))
            if currentState == name then
                playAnim("Idle")
            end
        end)
    end
end

-- ================================================================
--  Humanoid Olayları — Yerelde animasyon tetikle
-- ================================================================
Hum.Running:Connect(function(speed)
    if speed > 0.5 then
        -- Sprint durumuna bak (MAIN_UI'dan veya CA sprint butonundan)
        local isSprinting = _G.IsLocalSprinting == true
        playAnim(isSprinting and "Run" or "Walk")
    else
        playAnim("Idle")
    end
end)

Hum.Jumping:Connect(function(active)
    if active then playAnim("Jump") end
end)

Hum.FreeFalling:Connect(function(active)
    if active then playAnim("Jump") end
end)

Hum.Swimming:Connect(function(active)
    if active then playAnim("Swim") end
end)

Hum.Climbing:Connect(function(active)
    if active then playAnim("Climb") end
end)

-- Başlangıç
playAnim("Idle")

-- ================================================================
--  PlayAnimationState.OnClientEvent — Diğer oyuncuların animasyonları
-- ================================================================
PlayAnimationState.OnClientEvent:Connect(function(targetPlayer, newState)
    -- Kendi durumumuzu sunucu zaten Humanoid events ile yönetiyoruz
    -- SADECE diğer oyuncuları burada işle
    if targetPlayer == LocalPlayer then return end

    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local charData = CharacterStates[targetChar] or setupCharacter(targetChar)

    if charData.Current.player then
        charData.Current.player:Stop()
        charData.Current.player = nil
    end

    local p = charData.Players[newState]
    if p then
        p:Play()
        charData.Current.player = p
        charData.Current.state  = newState
    end
end)

print("[CA_ANIM] v1 yüklendi —", Char.Name)
