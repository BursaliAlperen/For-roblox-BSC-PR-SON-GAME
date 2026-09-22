--[[ 
    ZOMBIE SURVIVAL — AAA TPS HUD
    16:9 / Roblox LocalScript
    Put this LocalScript in StarterPlayer > StarterPlayerScripts.

    Stage 1:
    • Center TPS crosshair
    • Left-bottom HP / Stamina / XP
    • Right M1 / USE / SPRINT / CROUCH
    • Bottom-left ||| inventory button
    • 20-slot inventory panel
    • Smooth tweens + safe-area positioning
    • Designed for 16:9 and scales down on mobile
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
    bg = Color3.fromRGB(8, 12, 14),
    panel = Color3.fromRGB(13, 19, 22),
    panel2 = Color3.fromRGB(19, 27, 31),
    white = Color3.fromRGB(235, 241, 243),
    muted = Color3.fromRGB(135, 148, 154),
    line = Color3.fromRGB(74, 88, 94),
    red = Color3.fromRGB(224, 62, 66),
    amber = Color3.fromRGB(232, 180, 70),
    cyan = Color3.fromRGB(105, 204, 218),
    green = Color3.fromRGB(102, 207, 129),
}

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function label(parent, text, size, pos, font, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = color or C.white
    t.TextSize = size
    t.Font = font or Enum.Font.GothamBold
    t.Position = pos or UDim2.fromOffset(0, 0)
    t.Size = UDim2.fromOffset(100, 25)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end

local function button(parent, text, size, pos)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = text
    b.TextColor3 = C.white
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = C.panel
    b.BackgroundTransparency = 0.12
    b.Parent = parent
    corner(b, 999)
    stroke(b, C.line, 0.18, 1)
    return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZombieAAA_HUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Main safe-area frame. AnchorPoint/Scale keeps the layout stable at 16:9.
local root = Instance.new("Frame")
root.Name = "SafeArea"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

-- Vignette
local vignette = Instance.new("Frame")
vignette.BackgroundColor3 = Color3.new(0,0,0)
vignette.BackgroundTransparency = 0.82
vignette.Size = UDim2.fromScale(1,1)
vignette.ZIndex = 1
vignette.Parent = root

-- Crosshair
local cross = Instance.new("Frame")
cross.Name = "Crosshair"
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.46)
cross.Size = UDim2.fromOffset(44, 44)
cross.BackgroundTransparency = 1
cross.ZIndex = 20
cross.Parent = root

local function crossLine(size, pos)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.white
    f.BackgroundTransparency = 0.12
    f.BorderSizePixel = 0
    f.Size = size
    f.Position = pos
    f.Parent = cross
end
crossLine(UDim2.fromOffset(2, 13), UDim2.fromOffset(21, 0))
crossLine(UDim2.fromOffset(2, 13), UDim2.fromOffset(21, 31))
crossLine(UDim2.fromOffset(13, 2), UDim2.fromOffset(0, 21))
crossLine(UDim2.fromOffset(13, 2), UDim2.fromOffset(31, 21))

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(4,4)
dot.Position = UDim2.fromOffset(20,20)
dot.BackgroundColor3 = C.white
dot.BorderSizePixel = 0
corner(dot, 99)
dot.Parent = cross

local targetText = label(root, "", 11, UDim2.fromScale(0.5, 0.395), Enum.Font.GothamBold, C.white)
targetText.AnchorPoint = Vector2.new(0.5, 0)
targetText.Size = UDim2.fromOffset(330, 24)
targetText.TextXAlignment = Enum.TextXAlignment.Center
targetText.TextTransparency = 1
targetText.ZIndex = 20

local function setTarget(text, visible)
    targetText.Text = text or ""
    TweenService:Create(targetText, TweenInfo.new(0.18), {
        TextTransparency = visible and 0.1 or 1
    }):Play()
end

-- Bottom-left player status
local status = Instance.new("Frame")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0,1)
status.Position = UDim2.new(0.025,0,0.96,0)
status.Size = UDim2.new(0,285,0,115)
status.BackgroundTransparency = 1
status.ZIndex = 10
status.Parent = root

local portrait = Instance.new("Frame")
portrait.Size = UDim2.fromOffset(42,42)
portrait.Position = UDim2.fromOffset(0,0)
portrait.BackgroundColor3 = C.panel2
portrait.Parent = status
stroke(portrait,C.line,0.35,1)
label(portrait,"07",17,UDim2.fromOffset(9,8),Enum.Font.GothamBlack,C.white).Size = UDim2.fromOffset(30,24)

local name = label(status,string.upper(player.DisplayName),12,UDim2.fromOffset(54,2),Enum.Font.GothamBold,C.white)
name.Size = UDim2.fromOffset(220,20)
local level = label(status,"LEVEL 18  •  2,430 XP",10,UDim2.fromOffset(54,21),Enum.Font.GothamMedium,C.muted)
level.Size = UDim2.fromOffset(220,18)

local bars = {}
local function makeBar(y, color, text)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(285,10)
    holder.Position = UDim2.fromOffset(0,y)
    holder.BackgroundColor3 = Color3.fromRGB(5,8,9)
    holder.BorderSizePixel = 0
    holder.Parent = status
    stroke(holder,C.line,0.65,1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0.85,1)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = holder

    local txt = label(holder,text,9,UDim2.fromOffset(8,-4),Enum.Font.GothamBold,C.white)
    txt.Size = UDim2.new(1,-10,1,18)
    txt.TextYAlignment = Enum.TextYAlignment.Center

    table.insert(bars,{fill=fill,label=txt})
end

makeBar(53,C.red,"HP 86 / 100")
makeBar(67,C.amber,"STAMINA 64 / 100")
makeBar(81,C.cyan,"XP 48%")

-- Inventory button
local invButton = button(root,"|||",UDim2.fromOffset(52,52),UDim2.new(0.025,0,0.96,-126))
invButton.ZIndex = 12
invButton.TextSize = 19

-- Right controls
local controls = Instance.new("Frame")
controls.AnchorPoint = Vector2.new(1,1)
controls.Position = UDim2.new(0.975,0,0.96,0)
controls.Size = UDim2.fromOffset(350,105)
controls.BackgroundTransparency = 1
controls.ZIndex = 12
controls.Parent = root

local function control(text, x, w, h)
    local b = button(controls,text,UDim2.fromOffset(w,h),UDim2.new(1,-x-w,1,-h))
    return b
end

local crouch = control("CROUCH",8,58,58)
local sprint = control("SPRINT\nSHIFT",74,68,68)
local use = control("USE\nE",150,76,76)
local attack = control("M1\nATTACK",236,92,92)

-- Mobile tap + keyboard feedback
local function pressFeedback(b)
    local old = b.BackgroundColor3
    b.BackgroundColor3 = Color3.fromRGB(55,67,71)
    task.delay(0.1,function()
        if b and b.Parent then b.BackgroundColor3 = old end
    end)
end

local sprinting = false
local crouching = false

sprint.Activated:Connect(function()
    sprinting = not sprinting
    pressFeedback(sprint)
end)

crouch.Activated:Connect(function()
    crouching = not crouching
    pressFeedback(crouch)
end)

attack.Activated:Connect(function()
    pressFeedback(attack)
    -- Replace this with your weapon RemoteEvent later.
end)

use.Activated:Connect(function()
    pressFeedback(use)
    -- Replace this with your interaction RemoteEvent later.
end)

-- Inventory
local inventory = Instance.new("Frame")
inventory.Name = "Inventory"
inventory.AnchorPoint = Vector2.new(0.5,0.5)
inventory.Position = UDim2.fromScale(0.5,0.5)
inventory.Size = UDim2.new(0.82,0,0.78,0)
inventory.BackgroundColor3 = C.panel
inventory.BackgroundTransparency = 0.04
inventory.Visible = false
inventory.ZIndex = 100
inventory.Parent = root
corner(inventory,10)
stroke(inventory,C.line,0.22,1)

local invTitle = label(inventory,"INVENTORY",28,UDim2.fromOffset(22,18),Enum.Font.GothamBlack,C.white)
invTitle.Size = UDim2.fromOffset(300,36)
local invSub = label(inventory,"PERSISTENT SURVIVOR STORAGE  •  20 SLOTS",10,UDim2.fromOffset(24,52),Enum.Font.GothamMedium,C.muted)
invSub.Size = UDim2.fromOffset(360,20)

local close = button(inventory,"×",UDim2.fromOffset(38,38),UDim2.new(1,-52,0,14))
close.TextSize = 22
close.ZIndex = 102

local grid = Instance.new("Frame")
grid.Position = UDim2.fromOffset(22,86)
grid.Size = UDim2.new(0.67,-30,1,-108)
grid.BackgroundTransparency = 1
grid.ZIndex = 101
grid.Parent = inventory

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.18,0,0.22,0)
layout.CellPadding = UDim2.new(0.025,0,0.035,0)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local items = {
    {"SCRAP","▣",14},
    {"CLOTH","▤",9},
    {"WOOD","▥",22},
    {"MEDKIT","✚",2},
    {"9MM AMMO","•",37},
    {"WATER","◇",3},
    {"FOOD","▦",6},
    {"BATTERY","▰",4},
    {"BOLT","⌁",18},
    {"RAG","≈",11},
}

for i = 1,20 do
    local data = items[i]
    local slot = Instance.new("TextButton")
    slot.AutoButtonColor = false
    slot.Text = ""
    slot.BackgroundColor3 = data and C.panel2 or C.bg
    slot.BackgroundTransparency = data and 0 or 0.25
    slot.ZIndex = 102
    slot.LayoutOrder = i
    slot.Parent = grid
    corner(slot,5)
    stroke(slot,C.line,0.5,1)

    if data then
        local ico = label(slot,data[2],24,UDim2.fromOffset(8,8),Enum.Font.GothamBold,C.white)
        ico.Size = UDim2.fromOffset(35,32)

        local qty = label(slot,tostring(data[3]),12,UDim2.new(1,-30,1,-25),Enum.Font.GothamBlack,C.white)
        qty.Size = UDim2.fromOffset(25,20)
        qty.TextXAlignment = Enum.TextXAlignment.Right
        qty.TextYAlignment = Enum.TextYAlignment.Bottom

        local nm = label(slot,data[1],8,UDim2.fromOffset(7,0),Enum.Font.GothamBold,C.muted)
        nm.AnchorPoint = Vector2.new(0,1)
        nm.Position = UDim2.new(0,7,1,-5)
        nm.Size = UDim2.new(1,-14,0,14)
        nm.TextTruncate = Enum.TextTruncate.AtEnd

        slot.Activated:Connect(function()
            stroke(slot,C.cyan,0.15,1)
            setTarget("SELECTED  •  "..data[1],true)
        end)
    end
end

local detail = Instance.new("Frame")
detail.Position = UDim2.new(0.69,0,0,86)
detail.Size = UDim2.new(0.28,-20,1,-108)
detail.BackgroundColor3 = C.bg
detail.BackgroundTransparency = 0.18
detail.ZIndex = 101
detail.Parent = inventory
corner(detail,6)
stroke(detail,C.line,0.45,1)

local dTitle = label(detail,"CRAFTING",16,UDim2.fromOffset(16,18),Enum.Font.GothamBlack,C.white)
dTitle.Size = UDim2.new(1,-32,0,25)
local dText = label(detail,"Minecraft-inspired crafting\nwill be connected here.",11,UDim2.fromOffset(16,53),Enum.Font.GothamMedium,C.muted)
dText.Size = UDim2.new(1,-32,0,70)
dText.TextWrapped = true

local craft = button(detail,"CRAFT MEDKIT",UDim2.new(1,-32,0,42),UDim2.new(0,16,1,-58))
craft.TextSize = 11

local function toggleInventory()
    inventory.Visible = not inventory.Visible
end

invButton.Activated:Connect(toggleInventory)
close.Activated:Connect(toggleInventory)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.Tab then
        toggleInventory()
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = true
        pressFeedback(sprint)
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
        crouching = not crouching
        pressFeedback(crouch)
    elseif input.KeyCode == Enum.KeyCode.E then
        pressFeedback(use)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        pressFeedback(attack)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = false
    end
end)

-- Simple raycast target detection for the USE prompt.
-- Your server interaction system should validate the actual interaction.
local camera = workspace.CurrentCamera
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function()
    if not camera then camera = workspace.CurrentCamera end
    if not camera then return end

    local character = player.Character
    if character then
        rayParams.FilterDescendantsInstances = {character}
    end

    local center = camera.ViewportSize * Vector2.new(0.5,0.46)
    local ray = camera:ViewportPointToRay(center.X,center.Y)
    local hit = workspace:Raycast(ray.Origin,ray.Direction * 10,rayParams)

    if hit and hit.Instance and hit.Instance:GetAttribute("Interactable") == true then
        setTarget("[ E ]  "..(hit.Instance:GetAttribute("UseText") or "USE"),true)
    else
        setTarget("",false)
    end
end)

-- Keep the HUD usable on 16:9 and narrower screens.
local function updateScale()
    local size = camera and camera.ViewportSize or Vector2.new(1920,1080)
    local ratio = size.X / math.max(size.Y,1)
    local scale = math.clamp(ratio / (16/9),0.72,1)
    local existing = root:FindFirstChild("UIScale")

    if not existing then
        existing = Instance.new("UIScale")
        existing.Name = "UIScale"
        existing.Parent = root
    end

    existing.Scale = scale
end

if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()