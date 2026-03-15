--[[
================================================================
  BSC_ANIM_CLIENT.lua | StarterCharacterScripts
================================================================

  NEDEN ESKİSİ ÇALIŞMIYORDU:
  
  1. Motor6D.Transform TweenService ile tweenlenemez.
     Roblox animasyon engine'i Transform'u her frame override eder.
     
  2. KeyframeSequence direkt oynatılamaz.
     Animator:LoadAnimation() bir "Animation" objesi ister.
     KeyframeSequence'ı önce AnimationClipProvider'a kayıt etmek,
     sonra dönen hash ID'yi Animation.AnimationId'e set etmek gerekir.

  DOĞRU AKIŞ:
  1. AnimationClipProvider:RegisterKeyframeSequence(kfs) → "rbxassetid://hash"
  2. Animation objesi yap, AnimationId = hash
  3. Animator:LoadAnimation(animObj) → AnimationTrack
  4. track:Play() → ÇALIŞIR, herkes görür (server broadcast sayesinde)
================================================================
--]]

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local AnimProv = game:GetService("AnimationClipProvider")

local LP        = Players.LocalPlayer
local LocalChar = script.Parent
local LocalHum  = LocalChar:WaitForChild("Humanoid", 10)
if not LocalHum then return end

-- ── Default Animate'i TAMAMEN YOK ET ────────────────────────────────
local defaultAnim = LocalChar:FindFirstChild("Animate")
if defaultAnim then defaultAnim:Destroy() end

-- Animator al/oluştur
local LocalAnimator = LocalHum:FindFirstChildOfClass("Animator")
if not LocalAnimator then
    LocalAnimator = Instance.new("Animator")
    LocalAnimator.Parent = LocalHum
end

-- Çalışan track'leri durdur
for _, t in ipairs(LocalAnimator:GetPlayingAnimationTracks()) do
    t:Stop(0)
end

-- ── RS KLASÖRLERINI BEKLE ────────────────────────────────────────────
local AnimFolder  = RS:WaitForChild("Animations", 15)
local EmoteFolder = RS:FindFirstChild("Emotes")  -- opsiyonel

if not AnimFolder then
    warn("[ANIM_CLIENT] HATA: ReplicatedStorage/Animations bulunamadı!")
    return
end

-- ── KEYFRAMESEQUENCE → ANIMATION ID DÖNÜŞÜMÜ ────────────────────────
-- Her KFS'yi AnimationClipProvider'a kaydet → gerçek oynatılabilir ID al
local registeredIDs = {}  -- [kfsName] = "rbxassetid://..."

local function registerKFS(kfs, name)
    if registeredIDs[name] then return registeredIDs[name] end
    
    local ok, id = pcall(function()
        return AnimProv:RegisterKeyframeSequence(kfs)
    end)
    
    if ok and id then
        registeredIDs[name] = id
        print("[ANIM_CLIENT] Kayıt: " .. name .. " → " .. tostring(id))
        return id
    else
        warn("[ANIM_CLIENT] RegisterKeyframeSequence başarısız:", name, id)
        return nil
    end
end

-- Klasördeki tüm KFS'leri kaydet
local function registerFolder(folder, prefix)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("KeyframeSequence") then
            local key = (prefix or "") .. obj.Name
            task.spawn(registerKFS, obj, key)
        end
    end
end

-- İlk kayıtları yap
registerFolder(AnimFolder, "")
registerFolder(EmoteFolder, "Emote_")

-- Klasör değişirse otomatik kaydet
AnimFolder.ChildAdded:Connect(function(obj)
    if obj:IsA("KeyframeSequence") then
        registerKFS(obj, obj.Name)
    end
end)
if EmoteFolder then
    EmoteFolder.ChildAdded:Connect(function(obj)
        if obj:IsA("KeyframeSequence") then
            registerKFS(obj, "Emote_" .. obj.Name)
        end
    end)
end

-- ── ANİMASYON CONTROLLER ─────────────────────────────────────────────
-- Her karakter için bir controller, her isim için bir AnimationTrack cache

local function makeController(char, animator)
    local trackCache = {}  -- [kfsName] = AnimationTrack
    local currentLoco  = nil   -- şu an oynayan locomotion adı
    local isAction     = false -- true = restraint/emote, locomotion'ı blokla
    local activeThread = nil   -- döngü için (sadece looped action'lar için)

    local ctrl = {}

    -- Verilen isim için AnimationTrack al veya yükle
    local function getTrack(name)
        if trackCache[name] then return trackCache[name] end

        -- ID hazır mı? Hazır değilse bekle (max 5 saniye)
        local id = registeredIDs[name]
        if not id then
            local waited = 0
            repeat task.wait(0.1); waited = waited + 0.1
                id = registeredIDs[name]
            until id or waited >= 5
        end

        if not id then
            warn("[ANIM_CLIENT] ID bulunamadı:", name)
            return nil
        end

        local animObj = Instance.new("Animation")
        animObj.AnimationId = id

        local ok, track = pcall(function()
            return animator:LoadAnimation(animObj)
        end)

        if not ok or not track then
            warn("[ANIM_CLIENT] LoadAnimation başarısız:", name, track)
            return nil
        end

        -- KFS'den loop bilgisi al
        local kfsObj = AnimFolder:FindFirstChild(name)
            or (EmoteFolder and EmoteFolder:FindFirstChild(
                name:gsub("^Emote_", "")
            ))
        if kfsObj and kfsObj:IsA("KeyframeSequence") then
            track.Looped = kfsObj.Loop
        else
            track.Looped = false
        end

        trackCache[name] = track
        return track
    end

    -- Tüm lokomosyon track'leri durdur
    local LOCO_NAMES = {"Idle", "Walk", "Run"}
    local function stopLoco(fade)
        for _, n in ipairs(LOCO_NAMES) do
            local t = trackCache[n]
            if t and t.IsPlaying then t:Stop(fade or 0.2) end
        end
    end

    -- Tüm track'leri durdur
    local function stopAll(fade)
        for _, t in pairs(trackCache) do
            if t.IsPlaying then t:Stop(fade or 0.2) end
        end
        if activeThread then
            task.cancel(activeThread)
            activeThread = nil
        end
        currentLoco = nil
        isAction = false
    end

    -- Locomotion oynat (action varsa geç)
    function ctrl.playLoco(name, fade)
        if isAction then return end
        if currentLoco == name then return end

        local track = getTrack(name)
        if not track then return end

        track.Looped = true
        track.Priority = Enum.AnimationPriority.Movement

        stopLoco(fade or 0.2)
        if not track.IsPlaying then
            track:Play(fade or 0.2)
        end
        currentLoco = name
    end

    -- Action oynat (restraint / emote)
    function ctrl.playAction(name, looped, fade)
        local track = getTrack(name)
        if not track then
            warn("[ANIM_CLIENT] playAction: track yok:", name)
            return
        end

        stopAll(fade or 0.15)
        task.wait(0.05)

        track.Looped   = looped == true
        track.Priority = Enum.AnimationPriority.Action

        if not track.IsPlaying then
            track:Play(fade or 0.2)
        end

        isAction = true
        currentLoco = name

        -- Looped değilse bitince Idle'a dön
        if not looped then
            track.Stopped:Once(function()
                isAction = false
                currentLoco = nil
                task.wait(0.05)
                ctrl.playLoco("Idle", 0.3)
            end)
        end
    end

    -- State sıfırla (Free olunca)
    function ctrl.resetToIdle(fade)
        stopAll(fade or 0.3)
        task.wait(0.05)
        isAction = false
        ctrl.playLoco("Idle", 0.3)
    end

    -- Ön yükleme (arka planda)
    function ctrl.preload()
        task.spawn(function()
            local names = {"Idle", "Walk", "Run"}
            -- Animations klasöründeki tüm isimleri de ekle
            for name in pairs(registeredIDs) do
                table.insert(names, name)
            end
            for _, name in ipairs(names) do
                task.wait(0.05)
                getTrack(name)
            end
            print("[ANIM_CLIENT] Preload tamamlandı:", char.Name)
        end)
    end

    ctrl._getTrack    = getTrack
    ctrl._isAction    = function() return isAction end
    ctrl._setAction   = function(v) isAction = v end

    return ctrl
end

-- ── LOCAL KARAKTER ────────────────────────────────────────────────────
local localCtrl = makeController(LocalChar, LocalAnimator)

-- Ön yükleme başlat
localCtrl.preload()

-- Sprint kontrolü (WalkSpeed > 18)
local isSprinting = false
game:GetService("RunService").Heartbeat:Connect(function()
    local h = LocalChar:FindFirstChildOfClass("Humanoid")
    if h then isSprinting = h.WalkSpeed > 18 end
end)

-- Başlangıç Idle (kısa gecikme ile)
task.delay(0.5, function()
    localCtrl.playLoco("Idle", 0)
end)

-- Locomotion bağlantıları
LocalHum.Running:Connect(function(speed)
    if speed > 0.5 then
        localCtrl.playLoco(isSprinting and "Run" or "Walk")
    else
        localCtrl.playLoco("Idle")
    end
end)

LocalHum.Swimming:Connect(function(speed)
    if speed > 0 then localCtrl.playLoco("Idle") end
end)

LocalHum.Climbing:Connect(function(speed)
    if speed ~= 0 then localCtrl.playLoco("Walk") end
end)

LocalHum.StateChanged:Connect(function(_, new)
    if new == Enum.HumanoidStateType.Landed then
        if not localCtrl._isAction() then
            localCtrl.playLoco("Idle")
        end
    end
end)

-- ── DİĞER OYUNCULAR ────────────────────────────────────────────────────
-- Diğer karakterler için Controller: kendi Animator'larını kullanır
local otherCtrls = {}  -- [character] = controller

local function setupOtherChar(player, char)
    if player == LP then return end
    if otherCtrls[char] then return end

    -- Diğer karakterin Humanoid ve Animator'ını bekle
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    -- Default Animate'i durdur (sadece Disable edebiliriz başkasının script'ini destroy edemeyiz local'den)
    local defAnim = char:FindFirstChild("Animate")
    if defAnim then
        defAnim.Enabled = false
        -- Animator track'lerini temizle
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            t:Stop(0)
        end
    end

    local ctrl = makeController(char, animator)
    otherCtrls[char] = ctrl

    -- Locomotion
    hum.Running:Connect(function(speed)
        if not ctrl._isAction() then
            if speed > 0.5 then ctrl.playLoco("Walk")
            else                 ctrl.playLoco("Idle") end
        end
    end)

    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed and not ctrl._isAction() then
            ctrl.playLoco("Idle")
        end
    end)

    task.delay(0.3, function()
        ctrl.playLoco("Idle", 0)
    end)

    char.Destroying:Connect(function()
        otherCtrls[char] = nil
    end)

    print("[ANIM_CLIENT] Diğer karakter kuruldu:", player.Name)
end

-- Mevcut oyuncular
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then
            task.spawn(setupOtherChar, p, p.Character)
        end
        p.CharacterAdded:Connect(function(c)
            task.wait(0.3)
            task.spawn(setupOtherChar, p, c)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        task.spawn(setupOtherChar, p, c)
    end)
end)

-- ── SERVER'DAN GELEN PlayAnim ─────────────────────────────────────────
local Remotes = RS:WaitForChild("Remotes", 15)
if not Remotes then
    warn("[ANIM_CLIENT] Remotes bulunamadı!")
    return
end

local R_Anim = Remotes:WaitForChild("PlayAnim", 15)
if not R_Anim then
    warn("[ANIM_CLIENT] PlayAnim remote bulunamadı!")
    return
end

-- Hangi animasyonlar action (restraint veya emote)?
local ACTION_MAP = {
    -- Restraint
    Cuff1   = {looped=true},
    Cuff2   = {looped=true},
    Rope    = {looped=true},
    Hogtied = {looped=true},
    Chained = {looped=true},
    Stunned = {looped=false},
    -- Emotes (Emote_ prefix ile depolanmış)
    Wave    = {looped=false, emote=true},
    Sit     = {looped=false, emote=true},
    Dance   = {looped=true,  emote=true},
    Clap    = {looped=false, emote=true},
    Kneel   = {looped=false, emote=true},
    HandsUp = {looped=false, emote=true},
    Lay     = {looped=false, emote=true},
}

R_Anim.OnClientEvent:Connect(function(targetPlayer, animName, looped)
    if not targetPlayer or not animName then return end

    -- Controller'ı seç
    local ctrl
    if targetPlayer == LP then
        ctrl = localCtrl
    else
        local tChar = targetPlayer.Character
        if not tChar then return end
        ctrl = otherCtrls[tChar]
        if not ctrl then
            -- Henüz kurulmamışsa kur
            task.spawn(function()
                setupOtherChar(targetPlayer, tChar)
                task.wait(0.5)
                ctrl = otherCtrls[tChar]
                if ctrl then
                    -- Tekrar dene
                    R_Anim:FireServer()  -- bu olmaz, sadece retry için
                end
            end)
            return
        end
    end

    if not ctrl then return end

    -- "Idle" / "Free" → locomotion'a dön
    if animName == "Idle" or animName == "Free" then
        ctrl.resetToIdle(0.3)
        return
    end

    local info = ACTION_MAP[animName]

    if info then
        -- Emote ise "Emote_" prefix ekle
        local seqName = info.emote and ("Emote_" .. animName) or animName
        local shouldLoop = (looped ~= nil) and looped or info.looped
        ctrl.playAction(seqName, shouldLoop, 0.2)
    else
        -- Locomotion (Walk, Run)
        ctrl.playLoco(animName, 0.2)
    end
end)

print("[ANIM_CLIENT] ✅ Hazır |", LP.Name,
    "| Kayıtlı sequence:", (function()
        local n = 0
        for _ in pairs(registeredIDs) do n = n + 1 end
        return n
    end)()
)
