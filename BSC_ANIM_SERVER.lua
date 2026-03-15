--[[
================================================================
  BSC_ANIM_SERVER.lua | ServerScriptService
================================================================
  - RestraintState değişince TÜM clientlara PlayAnim yayınla
  - Emote isteğini doğrula ve yayınla
  - Geç gelen oyuncuya mevcut state'leri sync et
  - PlayEmote remote ismini tutarlı tut
================================================================
--]]

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

-- Remotes klasörünü bekle
local Remotes = RS:WaitForChild("Remotes", 15)
if not Remotes then warn("[ANIM_SERVER] Remotes yok!"); return end

local R_Anim  = Remotes:WaitForChild("PlayAnim",  15)
local R_Emote = Remotes:WaitForChild("PlayEmote", 15)

if not R_Anim  then warn("[ANIM_SERVER] PlayAnim remote yok!"); return end
if not R_Emote then warn("[ANIM_SERVER] PlayEmote remote yok!"); return end

-- State → animasyon adı çözümleyici
local function resolveAnim(char, state)
    if state == "Handcuffed" then
        local mode = char:GetAttribute("CuffMode") or "Front"
        return mode == "Back" and "Cuff2" or "Cuff1", true
    elseif state == "RopeTied" then
        return "Rope", true
    elseif state == "Hogtied" then
        return "Hogtied", true
    elseif state == "Chained" then
        return "Chained", true
    elseif state == "Stunned" then
        return "Stunned", false
    else -- Free veya bilinmeyen
        return "Idle", true
    end
end

-- Tüm clientlara yayınla
local function broadcast(targetPlayer, animName, looped)
    for _, p in ipairs(Players:GetPlayers()) do
        R_Anim:FireClient(p, targetPlayer, animName, looped)
    end
end

-- ── Oyuncu karakteri kurulumu ─────────────────────────────────────────
local function setupChar(player, char)
    -- HumanoidRootPart gelene kadar bekle
    char:WaitForChild("HumanoidRootPart", 10)

    -- RestraintState attribute değişince yayınla
    local conn = char:GetAttributeChangedSignal("RestraintState"):Connect(function()
        local state = char:GetAttribute("RestraintState") or "Free"
        local animName, looped = resolveAnim(char, state)
        broadcast(player, animName, looped)
    end)

    -- Ölünce Idle yayınla + conn temizle
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Once(function()
            conn:Disconnect()
            broadcast(player, "Idle", true)
        end)
    end

    -- Spawn olunca kısa gecikmeli Idle (client'ın script'i yüklemesi için)
    task.delay(1.0, function()
        if char and char.Parent then
            broadcast(player, "Idle", true)
        end
    end)
end

-- ── Yeni oyuncu ──────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.spawn(setupChar, player, char)
    end)

    -- Geç gelen oyuncuya mevcut herkesin state'ini gönder
    task.spawn(function()
        task.wait(2.5)  -- client script'inin yüklenmesi için
        if not player or not player.Parent then return end
        for _, existing in ipairs(Players:GetPlayers()) do
            if existing ~= player and existing.Character and existing.Character.Parent then
                local state = existing.Character:GetAttribute("RestraintState") or "Free"
                local animName, looped = resolveAnim(existing.Character, state)
                R_Anim:FireClient(player, existing, animName, looped)
            end
        end
    end)
end)

-- Zaten bağlı olanlar
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        task.spawn(setupChar, p, p.Character)
    end
end

-- ── Emote isteği ─────────────────────────────────────────────────────
local VALID_EMOTES = {
    Wave=true, Sit=true, Dance=true, Clap=true,
    Kneel=true, HandsUp=true, Lay=true,
}

R_Emote.OnServerEvent:Connect(function(sender, emoteName)
    -- Tip kontrolü
    if type(emoteName) ~= "string" then return end

    -- Whitelist kontrolü
    if not VALID_EMOTES[emoteName] then
        warn("[ANIM_SERVER] Geçersiz emote:", tostring(emoteName), sender.Name)
        return
    end

    -- Sadece Free state'deki oyuncular emote yapabilir
    local char = sender.Character
    if not char then return end
    local state = char:GetAttribute("RestraintState") or "Free"
    if state ~= "Free" then return end

    -- Rate limit: 1 saniyede bir
    local now = tick()
    local last = sender:GetAttribute("_lastEmote") or 0
    if now - last < 1.0 then return end
    sender:SetAttribute("_lastEmote", now)

    -- Tüm clientlara yayınla
    broadcast(sender, emoteName, false)
    print("[ANIM_SERVER] Emote:", sender.Name, "→", emoteName)
end)

print("[ANIM_SERVER] ✅ Hazır")
