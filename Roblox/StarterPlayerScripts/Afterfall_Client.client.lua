-- AFTERFALL: THE LAST SHIFT | CLIENT HUD
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Rep=game:GetService("ReplicatedStorage")
local p=Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local R=Rep:WaitForChild("AfterfallRemotes")
local boot=R.GetBoot:InvokeServer()
local Action=R.Action
local Notice=R.Notice
local GetState=R.GetState
local C=boot.colors

local gui=Instance.new("ScreenGui")
gui.Name="AfterfallHUD"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=100; gui.Parent=pg
local root=Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=gui
local scale=Instance.new("UIScale"); scale.Parent=root
local function resize() local v=workspace.CurrentCamera.ViewportSize; scale.Scale=math.clamp(v.X/1920,.72,1.08) end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()

local function F(par,size,pos,col,tr)
	local x=Instance.new("Frame"); x.Size=size; x.Position=pos; x.BackgroundColor3=col or C.panel; x.BackgroundTransparency=tr or 0; x.BorderSizePixel=0; x.Parent=par; return x
end
local function T(par,s,z,pos,font,col)
	local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Text=s; x.TextSize=z; x.Font=font or Enum.Font.GothamBold; x.TextColor3=col or C.text; x.Position=pos; x.Size=UDim2.fromOffset(240,22); x.TextXAlignment=Enum.TextXAlignment.Left; x.Parent=par; return x
end
local function Rnd(x,n) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,n or 7); c.Parent=x end
local function Stroke(x,col,tr,w) local s=Instance.new("UIStroke"); s.Color=col or C.line; s.Transparency=tr or 0; s.Thickness=w or 1; s.Parent=x end
local function Btn(par,s,size,pos)
	local x=Instance.new("TextButton"); x.AutoButtonColor=false; x.Text=s; x.TextSize=12; x.Font=Enum.Font.GothamBold; x.TextColor3=C.text; x.Size=size; x.Position=pos; x.BackgroundColor3=C.panel; x.BackgroundTransparency=.04; x.Parent=par; Rnd(x,8); Stroke(x,C.line,.12,1)
	x.MouseEnter:Connect(function() TweenService:Create(x,TweenInfo.new(.08),{BackgroundColor3=C.panel2}):Play() end)
	x.MouseLeave:Connect(function() TweenService:Create(x,TweenInfo.new(.08),{BackgroundColor3=C.panel}):Play() end)
	return x
end

local top=F(root,UDim2.fromOffset(390,62),UDim2.fromOffset(30,26),C.panel,.08); Rnd(top,8); Stroke(top,C.line,.22,1)
local mark=F(top,UDim2.fromOffset(4,42),UDim2.fromOffset(0,10),C.accent,0); Rnd(mark,3)
local title=T(top,boot.game.title,24,UDim2.fromOffset(18,7),Enum.Font.GothamBlack,C.text); title.Size=UDim2.fromOffset(180,30)
local sub=T(top,boot.game.subtitle,9,UDim2.fromOffset(20,38),Enum.Font.GothamBold,C.muted); sub.Size=UDim2.fromOffset(220,14)
local sector=T(top,"SECTOR 07  //  02:43 AM",9,UDim2.new(1,-210,0,18),Enum.Font.GothamBold,C.info); sector.Size=UDim2.fromOffset(190,16); sector.TextXAlignment=Enum.TextXAlignment.Right

local obj=F(root,UDim2.fromOffset(430,45),UDim2.new(.5,-215,0,25),C.panel,.15); Rnd(obj,7); Stroke(obj,C.line,.38,1)
T(obj,"CURRENT OBJECTIVE",8,UDim2.fromOffset(14,6),Enum.Font.GothamBold,C.muted)
local objective=T(obj,"SURVIVE THE NIGHT  •  0 XP",11,UDim2.fromOffset(14,20),Enum.Font.GothamBlack,C.text); objective.Size=UDim2.fromOffset(395,18)

local ping=F(root,UDim2.fromOffset(210,54),UDim2.new(1,-240,0,26),C.panel,.08); Rnd(ping,8); Stroke(ping,C.line,.22,1)
local lvl=T(ping,"SURVIVOR  •  LVL 1",10,UDim2.fromOffset(12,7),Enum.Font.GothamBlack,C.text); lvl.Size=UDim2.fromOffset(190,16)
T(ping,"● ONLINE    42ms",9,UDim2.fromOffset(12,29),Enum.Font.GothamBold,C.success)

local cross=F(root,UDim2.fromOffset(44,44),UDim2.new(.5,-22,.47,-22),C.text,1); cross.ZIndex=40
local function crossLine(sz,pos) local x=F(cross,sz,pos,C.text,.05); x.ZIndex=41 end
crossLine(UDim2.fromOffset(2,11),UDim2.fromOffset(21,0)); crossLine(UDim2.fromOffset(2,11),UDim2.fromOffset(21,33))
crossLine(UDim2.fromOffset(11,2),UDim2.fromOffset(0,21)); crossLine(UDim2.fromOffset(11,2),UDim2.fromOffset(33,21))
local dot=F(cross,UDim2.fromOffset(4,4),UDim2.fromOffset(20,20),C.accent,0); dot.ZIndex=42; Rnd(dot,8)
local prompt=T(root,"",11,UDim2.new(.5,-180,.47,29),Enum.Font.GothamBlack,C.text); prompt.Size=UDim2.fromOffset(360,20); prompt.TextXAlignment=Enum.TextXAlignment.Center; prompt.TextTransparency=1

local vit=F(root,UDim2.fromOffset(350,164),UDim2.new(0,30,1,-196),C.panel,.06); Rnd(vit,9); Stroke(vit,C.line,.2,1)
T(vit,string.upper(p.DisplayName),13,UDim2.fromOffset(18,11),Enum.Font.GothamBlack,C.text)
T(vit,"SCAVENGER  /  ACTIVE",9,UDim2.fromOffset(18,31),Enum.Font.GothamBold,C.muted)
local rows={}
local map={HEALTH="Health",STAMINA="Stamina",HUNGER="Hunger",THIRST="Thirst"}
local function row(name,y,col)
	T(vit,name,8,UDim2.fromOffset(18,y),Enum.Font.GothamBold,C.muted)
	local bg=F(vit,UDim2.fromOffset(220,8),UDim2.fromOffset(105,y+2),Color3.fromRGB(4,7,8),0)
	local fill=F(bg,UDim2.fromScale(.8,1),UDim2.fromOffset(0,0),col,0)
	local val=T(vit,"--",9,UDim2.fromOffset(226,y-2),Enum.Font.GothamBlack,C.text); val.Size=UDim2.fromOffset(100,14); val.TextXAlignment=Enum.TextXAlignment.Right
	rows[name]={fill=fill,val=val}
end
row("HEALTH",55,C.danger); row("STAMINA",79,C.accent); row("HUNGER",103,C.info); row("THIRST",127,C.info)

local hot=F(root,UDim2.fromOffset(440,72),UDim2.new(.5,-220,1,-98),C.panel,.06); Rnd(hot,10); Stroke(hot,C.line,.16,1)
local hotSlots={}
for i,id in ipairs({"Medkit","Ammo9","Water","Food","Battery","Scrap"}) do
	local s=F(hot,UDim2.fromOffset(62,58),UDim2.fromOffset(7+(i-1)*71,7),C.panel2,.02); Rnd(s,6); Stroke(s,i==1 and C.accent or C.line,i==1 and 0 or .45,1)
	T(s,tostring(i),8,UDim2.fromOffset(7,5),Enum.Font.GothamBlack,C.muted)
	local icon=T(s,boot.items[id].icon,22,UDim2.fromOffset(7,18),Enum.Font.GothamBlack,C.text); icon.Size=UDim2.fromOffset(46,26); icon.TextXAlignment=Enum.TextXAlignment.Center
	local qty=T(s,"",9,UDim2.new(1,-26,1,-19),Enum.Font.GothamBlack,C.text); qty.Size=UDim2.fromOffset(18,14); qty.TextXAlignment=Enum.TextXAlignment.Right
	hotSlots[i]={id=id,qty=qty}
end

local acts=F(root,UDim2.fromOffset(310,142),UDim2.new(1,-340,1,-190),C.panel,.06); Rnd(acts,10); Stroke(acts,C.line,.2,1)
local atk=Btn(acts,"M1\nATTACK",UDim2.fromOffset(92,92),UDim2.new(1,-104,0,11)); atk.TextSize=13
local use=Btn(acts,"E\nUSE",UDim2.fromOffset(68,68),UDim2.new(1,-180,0,37))
local sprint=Btn(acts,"SHIFT\nSPRINT",UDim2.fromOffset(68,68),UDim2.fromOffset(12,37))
local crouch=Btn(acts,"C\nCROUCH",UDim2.fromOffset(68,68),UDim2.fromOffset(86,37))
local sprinting=false; local crouching=false
local function target()
	local cam=workspace.CurrentCamera; if not cam then return nil end
	local v=cam.ViewportSize; local ray=cam:ViewportPointToRay(v.X/2,v.Y*.47); local hit=workspace:Raycast(ray.Origin,ray.Direction*12); return hit and hit.Instance or nil
end
atk.Activated:Connect(function() local cam=workspace.CurrentCamera; if cam then Action:FireServer("ATTACK",{direction=cam.CFrame.LookVector}) end end)
use.Activated:Connect(function() local t=target(); if t then Action:FireServer("USE",{target=t}) end end)
sprint.Activated:Connect(function() sprinting=not sprinting; Action:FireServer("SPRINT",sprinting) end)
crouch.Activated:Connect(function() crouching=not crouching; Action:FireServer("CROUCH",crouching) end)

local inv=F(root,UDim2.new(.84,0,.82,0),UDim2.new(.08,0,.09,0),C.panel,.01); Rnd(inv,10); Stroke(inv,C.line,.1,1); inv.Visible=false; inv.ZIndex=200
T(inv,"INVENTORY",28,UDim2.fromOffset(24,17),Enum.Font.GothamBlack,C.text)
T(inv,"FIELD STORAGE  /  EQUIPMENT  /  CRAFTING",9,UDim2.fromOffset(26,52),Enum.Font.GothamBold,C.muted)
local close=Btn(inv,"×",UDim2.fromOffset(40,40),UDim2.new(1,-58,0,13)); close.TextSize=22
local grid=F(inv,UDim2.new(.66,-22,1,-106),UDim2.fromOffset(20,86),C.bg,1); grid.ZIndex=201
local gl=Instance.new("UIGridLayout"); gl.CellSize=UDim2.new(.18,0,.21,0); gl.CellPadding=UDim2.new(.025,0,.03,0); gl.Parent=grid
local invSlots={}
for i=1,20 do
	local s=F(grid,UDim2.fromOffset(1,1),UDim2.fromOffset(),C.panel2,0); s.ZIndex=202; Rnd(s,6); Stroke(s,C.line,.35,1)
	local ic=T(s,"",24,UDim2.fromOffset(10,6),Enum.Font.GothamBlack,C.text); ic.Size=UDim2.fromOffset(46,32)
	local nm=T(s,"",8,UDim2.fromOffset(10,42),Enum.Font.GothamBold,C.muted); nm.Size=UDim2.new(1,-20,0,14)
	local q=T(s,"",10,UDim2.new(1,-38,1,-23),Enum.Font.GothamBlack,C.text); q.Size=UDim2.fromOffset(28,16); q.TextXAlignment=Enum.TextXAlignment.Right
	invSlots[i]={icon=ic,name=nm,qty=q}
end
local craft=F(inv,UDim2.new(.31,-22,1,-106),UDim2.new(.68,0,0,86),C.bg,.12); craft.ZIndex=201; Rnd(craft,8); Stroke(craft,C.line,.35,1)
T(craft,"CRAFTING",18,UDim2.fromOffset(16,15),Enum.Font.GothamBlack,C.text)
T(craft,"SERVER-VALIDATED RECIPES",8,UDim2.fromOffset(16,42),Enum.Font.GothamBold,C.muted)
local cy=68
for id,rec in pairs(boot.recipes) do
	local b=Btn(craft,rec.name,UDim2.new(1,-32,0,44),UDim2.fromOffset(16,cy))
	b.Activated:Connect(function() Action:FireServer("CRAFT",id) end); cy+=52
end
local invBtn=Btn(root,"|||\nINVENTORY",UDim2.fromOffset(78,56),UDim2.new(0,30,1,-254))
local function toggle() inv.Visible=not inv.Visible end
invBtn.Activated:Connect(toggle); close.Activated:Connect(toggle)

local damage=F(root,UDim2.fromScale(1,1),UDim2.fromScale(0,0),C.danger,1); damage.ZIndex=180
local notes=F(root,UDim2.fromOffset(320,210),UDim2.new(1,-350,0,94),C.bg,1); notes.ZIndex=300
local function pop(d)
	local card=F(notes,UDim2.fromOffset(300,58),UDim2.fromOffset(330,0),C.panel,.02); Rnd(card,7); Stroke(card,d.kind=="danger" and C.danger or (d.kind=="success" and C.success or C.line),.12,1)
	local h=T(card,string.upper(d.title or "NOTICE"),10,UDim2.fromOffset(13,8),Enum.Font.GothamBlack,C.text); h.Size=UDim2.fromOffset(270,15)
	local b=T(card,d.text or "",9,UDim2.fromOffset(13,29),Enum.Font.GothamBold,C.muted); b.Size=UDim2.fromOffset(270,17)
	card.Parent=notes; TweenService:Create(card,TweenInfo.new(.16),{Position=UDim2.fromOffset(0,0)}):Play()
	task.delay(3,function() if card.Parent then TweenService:Create(card,TweenInfo.new(.14),{Position=UDim2.fromOffset(330,0)}):Play(); task.delay(.18,function() if card then card:Destroy() end end) end end)
end
Notice.OnClientEvent:Connect(pop)

local function update(s)
	for key,dataKey in pairs(map) do local v=s[dataKey] or 0; rows[key].fill.Size=UDim2.fromScale(math.clamp(v/100,0,1),1); rows[key].val.Text=string.format("%d / 100",math.floor(v)) end
	lvl.Text=string.format("SURVIVOR  •  LVL %d",s.Level or 1)
	objective.Text=string.format("SURVIVE THE NIGHT  •  %d XP",s.XP or 0)
	for _,slot in ipairs(hotSlots) do local n=(s.Inventory and s.Inventory[slot.id]) or 0; slot.qty.Text=n>0 and tostring(n) or "" end
	local i=1; for id,def in pairs(boot.items) do if invSlots[i] then local n=(s.Inventory and s.Inventory[id]) or 0; invSlots[i].icon.Text=def.icon; invSlots[i].name.Text=def.name; invSlots[i].qty.Text=n>0 and tostring(n) or ""; i+=1 end end
end

UIS.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.I or input.KeyCode==Enum.KeyCode.Tab then toggle()
	elseif input.KeyCode==Enum.KeyCode.LeftShift then sprinting=true; Action:FireServer("SPRINT",true)
	elseif input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.C then crouching=not crouching; Action:FireServer("CROUCH",crouching)
	elseif input.UserInputType==Enum.UserInputType.MouseButton1 then local cam=workspace.CurrentCamera; if cam then Action:FireServer("ATTACK",{direction=cam.CFrame.LookVector}) end
	elseif input.KeyCode==Enum.KeyCode.One then Action:FireServer("CONSUME","Medkit")
	elseif input.KeyCode==Enum.KeyCode.Two then Action:FireServer("CONSUME","Water")
	elseif input.KeyCode==Enum.KeyCode.Three then Action:FireServer("CONSUME","Food") end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift then sprinting=false; Action:FireServer("SPRINT",false) end end)

local last=100
task.spawn(function()
	while gui.Parent do
		local ok,s=pcall(function() return GetState:InvokeServer() end)
		if ok and s then
			if s.Health<last-8 then damage.BackgroundTransparency=.82; TweenService:Create(damage,TweenInfo.new(.4),{BackgroundTransparency=1}):Play() end
			last=s.Health; update(s)
		end
		task.wait(.35)
	end
end)
Run.RenderStepped:Connect(function()
	local t=target()
	if t and t:GetAttribute("Interactable")==true then prompt.Text="[ E ]  "..tostring(t:GetAttribute("UseText") or "USE"); TweenService:Create(prompt,TweenInfo.new(.1),{TextTransparency=.05}):Play()
	else TweenService:Create(prompt,TweenInfo.new(.1),{TextTransparency=1}):Play() end
end)
pop({title="AFTERFALL",text="THE LAST SHIFT HAS BEGUN.",kind="info"})
