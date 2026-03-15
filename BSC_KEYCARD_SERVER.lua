--[[
================================================================
  BSC_KEYCARD_SERVER.lua | ServerScriptService
================================================================
  - Keycard tool dokunuşunda kapı açar
  - YardDoor / CafeDoor modelindeki her parçayı yumuşak fade ile şeffaf yapar
  - Animasyonlu açılma: TweenService ile Transparency 1'e gider
================================================================
--]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = RS:WaitForChild("Remotes", 15)
if not Remotes then
    warn("[KEYCARD] Remotes yok!")
    return
end

local R_Keycard = Remotes:WaitForChild("Keycard", 15)
if not R_Keycard then
    warn("[KEYCARD] Keycard remote yok!")
    return
end

local ALLOWED_DOORS = {
    YardDoor = true,
    CafeDoor = true,
}

local function resolveDoorFromTarget(target)
    if not target or not target:IsA("BasePart") then return nil end

    local cur = target
    for _ = 1, 10 do
        if not cur then break end
        if cur:IsA("Model") and ALLOWED_DOORS[cur.Name] then
            return cur
        end
        cur = cur.Parent
    end

    -- Kapının herhangi bir parçasına tıklamayı desteklemek için
    -- workspace içinde isim araması fallback.
    for doorName in pairs(ALLOWED_DOORS) do
        local found = workspace:FindFirstChild(doorName, true)
        if found and target:IsDescendantOf(found) then
            return found
        end
    end

    return nil
end

local function fadeDoor(doorModel)
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    for _, inst in ipairs(doorModel:GetDescendants()) do
        if inst:IsA("BasePart") then
            inst.CanCollide = false
            TweenService:Create(inst, tweenInfo, {Transparency = 1}):Play()
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            TweenService:Create(inst, tweenInfo, {Transparency = 1}):Play()
        end
    end
end

R_Keycard.OnServerEvent:Connect(function(player, targetPart)
    if not player.Character then return end

    local heldTool = player.Character:FindFirstChildOfClass("Tool")
    if not heldTool or heldTool.Name ~= "Keycard" then
        return
    end

    local door = resolveDoorFromTarget(targetPart)
    if not door then
        return
    end

    fadeDoor(door)
end)

print("[KEYCARD_SERVER] ✅ Hazır")
