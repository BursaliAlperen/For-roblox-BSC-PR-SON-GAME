-- ============================================================
--  SNG BATTLEGROUND — ANIMATIONS_SERVER  [v1]
--  Konum: ServerScriptService > Script (Normal Script)
--
--  GÖREV: Oyuncu animasyon state'ini yönet ve yayınla.
--  MAIN_SERVER'dan tamamen bağımsız çalışır.
--
--  Ne yapar:
--    1. Her oyuncunun Idle/Walk/Run/Jump/Swim/Climb state'ini takip eder
--    2. PlayAnimationState RemoteEvent ile client'lara state gönderir
--    3. Sprint toggle'ı client'tan alır (ToggleSprint action)
--    4. Jump/Swim/Climb gibi özel state'leri HumanoidState'ten okur
--
--  Bağımlılıklar:
--    ReplicatedStorage.PlayAnimationState  (RemoteEvent)
--    Bu script kendi RE'sini oluşturur, MAIN_SERVER da oluşturuyorsa
--    hangisi önce çalışırsa o oluşturur — sorun çıkmaz.
-- ============================================================

local RunSvc     = game:GetService("RunService")
local Players    = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")

-- BSC anim sistemi aktifse bu legacy script çakışma yaratmasın.
local remotes = RepStorage:FindFirstChild("Remotes")
if remotes and remotes:FindFirstChild("PlayAnim") then
    warn("[ANIMATIONS_SERVER] BSC PlayAnim bulundu, legacy ANIMATIONS_SERVER pasif bırakıldı.")
    return
end

-- ─── RemoteEvent ──────────────────────────────────────────────
local PlayAnimationState = RepStorage:FindFirstChild("PlayAnimationState")
if not PlayAnimationState then
    PlayAnimationState             = Instance.new("RemoteEvent")
    PlayAnimationState.Name        = "PlayAnimationState"
    PlayAnimationState.Parent      = RepStorage
end

-- ─── Sabitler ─────────────────────────────────────────────────
local MOVEMENT_THRESHOLD = 0.01

-- ─── Veri Tablosu ─────────────────────────────────────────────
-- Her player için:
--   Character, Humanoid, RootPart
--   CurrentState  → son broadcast edilen state
--   IsSprinting   → client'tan gelen sprint flag
--   SpecialLock   → Jump/Swim/Climb oynarken Walk/Idle geçişini engelle
local CharacterData = {}

-- ─── Yardımcılar ──────────────────────────────────────────────
local function getSpecialState(humState)
    if humState == Enum.HumanoidStateType.Jumping  then return "Jump"  end
    if humState == Enum.HumanoidStateType.Freefall then return "Jump"  end
    if humState == Enum.HumanoidStateType.Swimming then return "Swim"  end
    if humState == Enum.HumanoidStateType.Climbing then return "Climb" end
    return nil
end

local function isStateValid(data, newState)
    if not data.Humanoid or not data.RootPart then return false end
    local onGround = data.Humanoid.FloorMaterial ~= Enum.Material.Air
    local moving   = data.Humanoid.MoveDirection.Magnitude > MOVEMENT_THRESHOLD
    if newState == "Walk" or newState == "Run" then
        return moving and onGround
    elseif newState == "Idle" then
        return (not moving) and onGround
    end
    return true  -- Jump, Swim, Climb her zaman geçerli
end

-- Hem sahibine hem diğer client'lara gönder
local function broadcastState(player, data, newState)
    if not isStateValid(data, newState) then return end
    if data.CurrentState == newState then return end
    data.CurrentState = newState

    -- Sahibine (status label ve kendi CA_ANIM için)
    PlayAnimationState:FireClient(player, player, newState)

    -- Diğer oyunculara (onların CA_ANIM_CLIENT diğer karakterleri için)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            PlayAnimationState:FireClient(p, player, newState)
        end
    end
end

-- ─── Karakter Yüklenme ────────────────────────────────────────
local function handleCharAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local data = {
        Character    = character,
        Humanoid     = humanoid,
        RootPart     = rootPart,
        CurrentState = "Idle",
        IsSprinting  = false,
        SpecialLock  = false,
    }
    CharacterData[player] = data

    -- CA_ANIM_CLIENT'ın yüklenmesi için kısa gecikme sonra Idle gönder
    task.delay(0.6, function()
        if not CharacterData[player] then return end
        -- Sadece sahibine başlangıç state'i gönder
        PlayAnimationState:FireClient(player, player, "Idle")
    end)

    -- HumanoidState değişimlerini dinle (Jump, Swim, Climb)
    humanoid.StateChanged:Connect(function(_, newHumState)
        local sp = getSpecialState(newHumState)
        if sp then
            data.SpecialLock = true
            broadcastState(player, data, sp)
        else
            data.SpecialLock = false
        end
    end)

    -- Karakter silinince temizle
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            CharacterData[player] = nil
        end
    end)
end

-- ─── Player Olayları ──────────────────────────────────────────
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(handleCharAdded)
    player.CharacterRemoving:Connect(function()
        CharacterData[player] = nil
    end)
    if player.Character then
        handleCharAdded(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    CharacterData[player] = nil
end)

for _, p in pairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- ─── Heartbeat — Idle / Walk / Run kararı ─────────────────────
RunSvc.Heartbeat:Connect(function()
    for player, data in pairs(CharacterData) do
        -- Karakter veya humanoid geçersizse atla
        if not data.Humanoid or not data.RootPart then continue end
        if data.Humanoid.Health <= 0 then continue end
        if data.SpecialLock then continue end   -- Jump/Swim/Climb oynuyorken müdahale etme

        local moving = data.Humanoid.MoveDirection.Magnitude > MOVEMENT_THRESHOLD
        local onGround = data.Humanoid.FloorMaterial ~= Enum.Material.Air

        local nextState = "Idle"
        if moving and onGround then
            nextState = data.IsSprinting and "Run" or "Walk"
        end

        if data.CurrentState ~= nextState then
            broadcastState(player, data, nextState)
        end
    end
end)

-- ─── Sprint Toggle ─────────────────────────────────────────────
-- Client (MAIN_UI) Shift'e basınca PlayAnimationState:FireServer("ToggleSprint") gönderir
PlayAnimationState.OnServerEvent:Connect(function(player, action)
    if action ~= "ToggleSprint" then return end
    local data = CharacterData[player]
    if not data then return end

    data.IsSprinting = not data.IsSprinting

    -- Eğer şu an hareket ediyorsa hemen state güncelle
    if not data.SpecialLock then
        local moving   = data.Humanoid.MoveDirection.Magnitude > MOVEMENT_THRESHOLD
        local onGround = data.Humanoid.FloorMaterial ~= Enum.Material.Air
        if moving and onGround then
            broadcastState(player, data, data.IsSprinting and "Run" or "Walk")
        end
    end
end)

print("[ANIMATIONS_SERVER] v1 yüklendi")
