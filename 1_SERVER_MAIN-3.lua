--[[
  SERVER_MAIN.lua  |  Konum: ServerScriptService
  Tüm sunucu sistemleri:
    Takım, Leaderstats, Blocky R6, Tool oluşturma, Friendly Fire,
    Handcuff/Hogtie/Chain/Taser/Punch, Kaçış, Forge, Kapı, Emote,
    Aktivite/Gece-Gündüz, OTOMATİK RESPAWN (ölünce aynı takım)
  KRİTİK: BodyTypeScale YOK | CarryEvent YOK | RemoteName ZORUNLU
--]]

local Players    = game:GetService("Players")
local RepStore   = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams      = game:GetService("Teams")
local Lighting   = game:GetService("Lighting")

Players.CharacterAutoLoads = false  -- Sunucu yönetecek

-- ── REMOTE EVENTS ─────────────────────────────────────────────────────────────
local Remotes = RepStore:FindFirstChild("Remotes")
    or (function()
        local f = Instance.new("Folder"); f.Name="Remotes"; f.Parent=RepStore; return f
    end)()

local REMOTE_LIST = {
    "TeamSelect","ActivityUpdate","DayNightSync",
    "ArrestPlayer","HogtiePlayer","ChainPlayer","UnchainPlayer",
    "TaserPlayer","KeycardAccess","RestraintUpdate",
    "CuffModeToggle","EscapeAttempt","EscapeResult",
    "ForgeAction","ForgePrompt","DamagePlayer","PunchPlayer",
    "PlayEmote","PlayAnimation","PlayAnimationState",
    "DoorAccess","RagdollPlayer",
}
for _,n in ipairs(REMOTE_LIST) do
    if not Remotes:FindFirstChild(n) then
        local r=Instance.new("RemoteEvent"); r.Name=n; r.Parent=Remotes
    end
end

-- ── KLASÖRLER ─────────────────────────────────────────────────────────────────
local function getF(p,n)
    local f=p:FindFirstChild(n)
    if not f then f=Instance.new("Folder"); f.Name=n; f.Parent=p end
    return f
end
local Tools       = getF(RepStore,"Tools")
local ToolModels  = getF(RepStore,"ToolModels")
local ToolEffects = getF(RepStore,"ToolEffects")
local _Animations = getF(RepStore,"Animations")

-- ── TAKIMLAR ──────────────────────────────────────────────────────────────────
local TCOLORS = {
    POLICE=BrickColor.new("Bright blue"),
    CRIMINAL=BrickColor.new("Bright red"),
    PRISONER=BrickColor.new("Medium stone grey"),
    HOSTAGE=BrickColor.new("Bright yellow"),
}
local rTeams = {}
for id,col in pairs(TCOLORS) do
    local t=Teams:FindFirstChild(id)
    if not t then
        t=Instance.new("Team"); t.Name=id; t.TeamColor=col
        t.AutoAssignable=false; t.Parent=Teams
    end
    rTeams[id]=t
end

-- ── LEADERSTATS (sadece Team) ──────────────────────────────────────────────────
local function buildLS(p)
    local old=p:FindFirstChild("leaderstats"); if old then old:Destroy() end
    local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=p
    local tv=Instance.new("StringValue")
    tv.Name="Team"; tv.Value=p:GetAttribute("Team") or "NONE"; tv.Parent=ls
end

-- ── BLOCKY KARAKTER  R6  (BodyTypeScale YOKTUR) ───────────────────────────────
local R6SZ = {
    Head=Vector3.new(2,1,1), Torso=Vector3.new(2,2,1),
    ["Left Arm"]=Vector3.new(1,2,1), ["Right Arm"]=Vector3.new(1,2,1),
    ["Left Leg"]=Vector3.new(1,2,1), ["Right Leg"]=Vector3.new(1,2,1),
}
local function makeBlocky(char)
    task.wait(0.4)
    for pname,sz in pairs(R6SZ) do
        local part=char:WaitForChild(pname,5)
        if part and part:IsA("BasePart") then part.Size=sz end
    end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            for _,nm in ipairs({"HeadScale","WidthScale","HeightScale"}) do
                local v=hum:FindFirstChild(nm); if v then v.Value=1 end
            end
        end)
    end
end

-- ── TOOL TANIMLARI ────────────────────────────────────────────────────────────
local TOOL_DEFS = {
    {n="Handcuff",r="ArrestPlayer",  ef="HandcuffEffect",col=BrickColor.new("Dark grey"),          gp=Vector3.new(0,-.05,-.5)},
    {n="Taser",   r="TaserPlayer",   ef=nil,              col=BrickColor.new("Bright yellow"),       gp=Vector3.new(0,-.1, -.7)},
    {n="Chain",   r="ChainPlayer",   ef="CollarEffect",   col=BrickColor.new("Medium stone grey"),   gp=Vector3.new(0,-.05,-.5)},
    {n="Rope",    r="HogtiePlayer",  ef="RopeEffect",     col=BrickColor.new("Brown"),               gp=Vector3.new(0,-.05,-.5)},
    {n="Keycard", r="KeycardAccess", ef=nil,              col=BrickColor.new("Bright blue"),         gp=Vector3.new(0,0,  -.1)},
    {n="Punch",   r="PunchPlayer",   ef=nil,              col=BrickColor.new("Bright red"),          gp=Vector3.new(0,0,  -.5),inv=true},
}

local function mkHandle(tool,col,inv)
    local h=Instance.new("Part"); h.Name="Handle"
    h.BrickColor=col or BrickColor.new("Medium stone grey")
    h.Material=Enum.Material.SmoothPlastic; h.CanCollide=false
    if inv then h.Size=Vector3.new(0.1,0.1,0.1); h.Transparency=1
    else        h.Size=Vector3.new(0.8,0.8,1.5); h.Transparency=0 end
    h.Parent=tool
end

for _,d in ipairs(TOOL_DEFS) do
    local tool=Tools:FindFirstChild(d.n)
    if not tool then
        tool=Instance.new("Tool"); tool.Name=d.n
        tool.RequiresHandle=true; tool.CanBeDropped=false
        tool.GripPos=d.gp; tool.GripForward=Vector3.new(0,0,1); tool.GripUp=Vector3.new(0,1,0)
        local handled=false
        local mdl=ToolModels:FindFirstChild(d.n.."Model")
        if mdl then
            local hp=mdl:FindFirstChild("Handle") or mdl.PrimaryPart
            if hp and hp:IsA("BasePart") then
                local nh=hp:Clone(); nh.Name="Handle"; nh.CanCollide=false
                if d.inv then nh.Size=Vector3.new(0.1,0.1,0.1); nh.Transparency=1 end
                nh.Parent=tool; handled=true
            end
        end
        if not handled then mkHandle(tool,d.col,d.inv) end
        tool:SetAttribute("RemoteName",d.r)
        if d.ef then tool:SetAttribute("EffectName",d.ef) end
        tool.Parent=Tools
    else
        tool:SetAttribute("RemoteName",d.r)
        if d.ef then tool:SetAttribute("EffectName",d.ef) end
        if not tool:FindFirstChild("Handle") then mkHandle(tool,d.col,d.inv) end
    end
end

-- ── SPAWN NOKTALARI ───────────────────────────────────────────────────────────
local SPAWN_MAP={POLICE="SpawnPolice",CRIMINAL="SpawnCriminal",PRISONER="SpawnPrisoner",HOSTAGE="SpawnHostage"}

local function getSpawnCF(tid)
    local n=SPAWN_MAP[tid]; if not n then return nil end
    local sp=workspace:FindFirstChild(n); if not sp then return nil end
    if sp:IsA("BasePart") then return sp.CFrame end
    if sp:IsA("Model") and sp.PrimaryPart then return sp.PrimaryPart.CFrame end
    return nil
end

-- ── STATE YÖNETİMİ ────────────────────────────────────────────────────────────
local SPEEDS={Free=16,Handcuffed=6,Hogtied=0,Chained=8,Stunned=0}

local function setState(char,state,mode,eff)
    if not char or not char.Parent then return end
    char:SetAttribute("State",state)
    if mode then char:SetAttribute("CuffMode",mode) end
    if eff  then char:SetAttribute("EffectName",eff) end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed=SPEEDS[state] or 16
        local jump=(state=="Free" or state=="Chained")
        pcall(function() hum.JumpPower=jump and 50 or 0 end)
        pcall(function() hum.JumpHeight=jump and 7.2 or 0 end)
    end
    Remotes.RestraintUpdate:FireAllClients(char,state,mode or "Front",eff)
end

-- ── FRIENDLY FIRE ─────────────────────────────────────────────────────────────
local function canDmg(a,v)
    if not a or not v or a==v then return false end
    local at=a:GetAttribute("Team"); local vt=v:GetAttribute("Team")
    if at and vt and at~="NONE" and at==vt then return false end
    return true
end

local function dealDmg(atkP,vicP,amt)
    if not atkP or not vicP then return false end
    if not canDmg(atkP,vicP) then return false end
    local ac=atkP.Character; local vc=vicP.Character
    if not ac or not vc then return false end
    local ar=ac:FindFirstChild("HumanoidRootPart") or ac:FindFirstChild("Torso")
    local vr=vc:FindFirstChild("HumanoidRootPart") or vc:FindFirstChild("Torso")
    if not ar or not vr then return false end
    if (ar.Position-vr.Position).Magnitude>22 then return false end
    local hum=vc:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-(amt or 5)); return true end
    return false
end

-- ── RAGDOLL ───────────────────────────────────────────────────────────────────
local function ragdoll(char,dur)
    if not char then return end
    local torso=char:FindFirstChild("Torso"); if not torso then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local motors={}
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then table.insert(motors,m); m.Enabled=false end
    end
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    task.delay(dur or 3,function()
        if char and char.Parent then
            for _,m in ipairs(motors) do if m and m.Parent then m.Enabled=true end end
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end
Remotes.RagdollPlayer.OnServerEvent:Connect(function(_,tp)
    if tp and tp.Character then ragdoll(tp.Character,3) end
end)

-- ── KAPI SİSTEMİ ──────────────────────────────────────────────────────────────
local DOOR_NAMES={"YardDoor","CafeDoor","CellDoor","Cafeteria","WorkDoor"}
local doorCache={}
task.spawn(function()
    for _,n in ipairs(DOOR_NAMES) do
        local d=workspace:WaitForChild(n,120)
        if d then doorCache[n]=d else warn("[DOOR] Bulunamadı:",n) end
    end
end)

local DOOR_EXCL={"frame","hinge","handle","doorframe","knob","lock","trim","post","border","metal","support"}
local function doorExcluded(name)
    local low=name:lower()
    for _,kw in ipairs(DOOR_EXCL) do if low:find(kw,1,true) then return true end end
    return false
end

Remotes.KeycardAccess.OnServerEvent:Connect(function(plr,target)
    if plr:GetAttribute("Team")~="POLICE" then return end
    if not target or not target:IsA("BasePart") then return end
    local dm=target:FindFirstAncestorOfClass("Model"); if not dm then return end
    local valid=false
    for _,dName in ipairs(DOOR_NAMES) do
        if dm.Name==dName or doorCache[dName]==(dm) or
           (doorCache[dName] and dm:IsDescendantOf(doorCache[dName])) then
            valid=true; break
        end
    end
    if not valid then return end
    local cache={}
    for _,p in ipairs(dm:GetDescendants()) do
        if p:IsA("BasePart") and p.Name:lower():find("glass",1,true) and not doorExcluded(p.Name) then
            table.insert(cache,{part=p,t=p.Transparency,cc=p.CanCollide})
            p.Transparency=1; p.CanCollide=false
        end
    end
    task.delay(1,function()
        for _,d in ipairs(cache) do
            if d.part and d.part.Parent then d.part.Transparency=d.t; d.part.CanCollide=d.cc end
        end
    end)
end)

-- ── POLICE TOOL VERİMİ ────────────────────────────────────────────────────────
local function givePoliceTools(p)
    local bp=p:WaitForChild("Backpack",6)
    if not bp then return end
    for _,c in ipairs(bp:GetChildren()) do c:Destroy() end
    if p.Character then
        for _,c in ipairs(p.Character:GetChildren()) do if c:IsA("Tool") then c:Destroy() end end
    end
    for _,t in ipairs(Tools:GetChildren()) do
        if t:IsA("Tool") then
            local cl=t:Clone()
            cl:SetAttribute("RemoteName",t:GetAttribute("RemoteName") or "")
            local ef=t:GetAttribute("EffectName"); if ef then cl:SetAttribute("EffectName",ef) end
            cl.Parent=bp
        end
    end
end

-- ── PLAYER / CHARACTER ADDED ──────────────────────────────────────────────────
local activeChains={}

local function onCharAdded(p,char)
    task.spawn(makeBlocky,char)
    local tid=p:GetAttribute("Team") or "NONE"

    -- Spawn noktasına yerleştir
    local sf=getSpawnCF(tid)
    if sf then
        local root=char:WaitForChild("HumanoidRootPart",5) or char:FindFirstChild("Torso")
        if root then
            root.CFrame=sf*CFrame.new(math.random(-2,2),3,math.random(-2,2))
        end
    end

    setState(char,"Free")

    if tid=="POLICE" then
        task.delay(0.7,function() givePoliceTools(p) end)
    end

    -- ÖLÜNCE → AYNI TAKIMDAN OTOMATİK RESPAWN (3 saniye sonra)
    local hum=char:WaitForChild("Humanoid",6)
    if hum then
        hum.Died:Connect(function()
            for k,v in pairs(activeChains) do
                if k==char or v==char then activeChains[k]=nil end
            end
            task.delay(3,function()
                if p and p.Parent then
                    p:LoadCharacter()
                end
            end)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    buildLS(p)
    p:SetAttribute("Team","NONE")
    p:SetAttribute("CuffMode","Front")
    -- Karakter YÜKLENMIYOR → client takım seçim ekranını gösterir
    p.CharacterAdded:Connect(function(c) onCharAdded(p,c) end)
end)

for _,p in ipairs(Players:GetPlayers()) do
    buildLS(p)
    if not p:GetAttribute("Team") then p:SetAttribute("Team","NONE") end
    if not p:GetAttribute("CuffMode") then p:SetAttribute("CuffMode","Front") end
    if p.Character then task.spawn(onCharAdded,p,p.Character) end
    p.CharacterAdded:Connect(function(c) onCharAdded(p,c) end)
end

-- ── TAKIM SEÇİMİ ──────────────────────────────────────────────────────────────
Remotes.TeamSelect.OnServerEvent:Connect(function(p,teamId)
    if not TCOLORS[teamId] then return end
    p:SetAttribute("Team",teamId)
    if rTeams[teamId] then p.Team=rTeams[teamId] end
    local ls=p:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Team") then ls.Team.Value=teamId end
    if p.Character then p.Character:Destroy() end
    p:LoadCharacter()
end)

-- ── RESTRAINT YARDIMCILARI ────────────────────────────────────────────────────
local function resolveTarget(tgt)
    if typeof(tgt)~="Instance" then return nil,nil end
    if tgt:IsA("Player") then return tgt,tgt.Character end
    if tgt:IsA("Model") and tgt:FindFirstChildOfClass("Humanoid") then
        return Players:GetPlayerFromCharacter(tgt),tgt
    end
    return nil,nil
end

local function proxOk(c1,c2,maxD)
    if not c1 or not c2 then return false end
    local r1=c1:FindFirstChild("HumanoidRootPart") or c1:FindFirstChild("Torso")
    local r2=c2:FindFirstChild("HumanoidRootPart") or c2:FindFirstChild("Torso")
    if not r1 or not r2 then return false end
    return (r1.Position-r2.Position).Magnitude<=maxD
end

-- ── HANDCUFF ──────────────────────────────────────────────────────────────────
Remotes.ArrestPlayer.OnServerEvent:Connect(function(plr,tgt)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local _,char=resolveTarget(tgt)
    if not char or not plr.Character then return end
    if not proxOk(plr.Character,char,15) then return end
    local m=plr:GetAttribute("CuffMode") or "Front"
    setState(char,"Handcuffed",m,"HandcuffEffect")
    local vp=Players:GetPlayerFromCharacter(char)
    if vp then Remotes.PlayAnimation:FireClient(vp,m=="Back" and "Cuff2" or "Cuff1",true) end
end)

-- ── HOGTIE ────────────────────────────────────────────────────────────────────
Remotes.HogtiePlayer.OnServerEvent:Connect(function(plr,tgt)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local _,char=resolveTarget(tgt)
    if not char or not plr.Character then return end
    if not proxOk(plr.Character,char,10) then return end
    setState(char,"Hogtied","Back","RopeEffect")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    local vp=Players:GetPlayerFromCharacter(char)
    if vp then Remotes.PlayAnimation:FireClient(vp,"RopeAnim",true) end
end)

-- ── CHAIN ─────────────────────────────────────────────────────────────────────
Remotes.ChainPlayer.OnServerEvent:Connect(function(plr,tgt)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local _,char=resolveTarget(tgt)
    if not char or not plr.Character then return end
    if not proxOk(plr.Character,char,10) then return end
    setState(char,"Chained","Collar","CollarEffect")
    activeChains[char]=plr.Character
end)

-- ── UNCHAIN ───────────────────────────────────────────────────────────────────
Remotes.UnchainPlayer.OnServerEvent:Connect(function(plr,tgt)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local _,char=resolveTarget(tgt)
    if not char then return end
    setState(char,"Free"); activeChains[char]=nil
end)

-- ── TASER (1 hasar, min 1 HP, 3s stunned) ────────────────────────────────────
Remotes.TaserPlayer.OnServerEvent:Connect(function(plr,tgt)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local _,char=resolveTarget(tgt)
    if not char or not plr.Character then return end
    if not proxOk(plr.Character,char,30) then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health>0 then hum.Health=math.max(1,hum.Health-1) end
    setState(char,"Stunned")
    local vp=Players:GetPlayerFromCharacter(char)
    if vp then Remotes.PlayAnimation:FireClient(vp,"TaserAnim",false) end
    task.delay(3.2,function()
        if char and char.Parent and char:GetAttribute("State")=="Stunned" then setState(char,"Free") end
    end)
end)

-- ── CUFF MODE TOGGLE ──────────────────────────────────────────────────────────
Remotes.CuffModeToggle.OnServerEvent:Connect(function(plr)
    if plr:GetAttribute("Team")~="POLICE" then return end
    local cur=plr:GetAttribute("CuffMode") or "Front"
    local nxt=cur=="Front" and "Back" or "Front"
    plr:SetAttribute("CuffMode",nxt)
    Remotes.CuffModeToggle:FireClient(plr,nxt)
end)

-- ── PUNCH (5 hasar, 0.8s CD, friendly fire kontrolü) ─────────────────────────
Remotes.PunchPlayer.OnServerEvent:Connect(function(atk,vicPlayer)
    if not vicPlayer or not vicPlayer:IsA("Player") then return end
    local now=tick(); local last=atk:GetAttribute("LastPunch") or 0
    if now-last<0.8 then return end
    if dealDmg(atk,vicPlayer,5) then
        atk:SetAttribute("LastPunch",now)
        Remotes.PlayAnimation:FireClient(atk,"PunchAnim",false)
        Remotes.PlayAnimation:FireClient(vicPlayer,"HitAnim",false)
    end
end)

Remotes.DamagePlayer.OnServerEvent:Connect(function(atk,vic,amt)
    if not vic then return end
    local vp=vic:IsA("Player") and vic or Players:GetPlayerFromCharacter(vic)
    if vp then dealDmg(atk,vp,amt or 5) end
end)

-- ── KAÇIŞ ─────────────────────────────────────────────────────────────────────
Remotes.EscapeAttempt.OnServerEvent:Connect(function(plr,success,targetChar)
    local t=targetChar or plr.Character; if not t then return end
    local s=t:GetAttribute("State")
    if not s or s=="Free" or s=="Stunned" then return end
    if targetChar and targetChar~=plr.Character then
        if not proxOk(plr.Character,targetChar,5) then return end
    end
    if success then
        setState(t,"Free"); activeChains[t]=nil
        Remotes.EscapeResult:FireClient(plr,true,targetChar)
        if targetChar then
            local tp=Players:GetPlayerFromCharacter(targetChar)
            if tp then Remotes.EscapeResult:FireClient(tp,true,nil) end
        end
    end
end)

-- ── FORGE ─────────────────────────────────────────────────────────────────────
Remotes.ForgeAction.OnServerEvent:Connect(function(plr,targetName)
    local tp=Players:FindFirstChild(tostring(targetName)); if not tp then return end
    local tc=tp.Character; if not tc then return end
    if not proxOk(plr.Character,tc,8) then return end
    local s=tc:GetAttribute("State")
    if s=="Handcuffed" or s=="Hogtied" or s=="Chained" then
        setState(tc,"Free"); activeChains[tc]=nil
    end
end)

-- Throttle: her 0.5s'de bir gönder (her frame değil — performans)
local forgeTimer = 0
RunService.Heartbeat:Connect(function(dt)
    forgeTimer = forgeTimer + dt
    if forgeTimer < 0.5 then return end
    forgeTimer = 0
    for _,p in ipairs(Players:GetPlayers()) do
        local c=p.Character; if not c then continue end
        local r=c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"); if not r then continue end
        local nearby={}
        for _,o in ipairs(Players:GetPlayers()) do
            if o~=p and o.Character then
                local or_=o.Character:FindFirstChild("HumanoidRootPart") or o.Character:FindFirstChild("Torso")
                if or_ and (r.Position-or_.Position).Magnitude<8 then
                    table.insert(nearby,{name=o.Name,state=o.Character:GetAttribute("State") or "Free"})
                end
            end
        end
        Remotes.ForgePrompt:FireClient(p,nearby)
    end
end)

-- ── EMOTE ─────────────────────────────────────────────────────────────────────
local VALID_EMOTES={Wave=true,Sit=true,Dance=true,Clap=true,Kneel=true,HandsUp=true,Lay=true}
Remotes.PlayEmote.OnServerEvent:Connect(function(plr,emoteName)
    if not VALID_EMOTES[emoteName] then return end
    local c=plr.Character; if not c then return end
    if (c:GetAttribute("State") or "Free")~="Free" then return end
    Remotes.PlayAnimation:FireAllClients(plr,emoteName.."Anim",false)
end)

-- ── AKTİVİTE & GECE/GÜNDÜZ ───────────────────────────────────────────────────
local ACTS={"WAKE UP","BREAKFAST","WORK","YARD TIME","DINNER","LOCKDOWN","SLEEP"}
local ai=1
task.delay(2,function() Remotes.ActivityUpdate:FireAllClients(ACTS[ai]) end)
task.spawn(function()
    while true do
        task.wait(300); ai=ai%#ACTS+1
        Remotes.ActivityUpdate:FireAllClients(ACTS[ai])
    end
end)
-- Throttle: her 0.5s'de bir gönder (her frame değil)
local dayTimer=0; local st=tick()
RunService.Heartbeat:Connect(function(dt)
    dayTimer=dayTimer+dt; if dayTimer<0.5 then return end; dayTimer=0
    local t=6+((tick()-st)/60)%24
    Lighting.ClockTime=t
    Remotes.DayNightSync:FireAllClients(t)
end)

print(("="):rep(60))
print("[SERVER_MAIN] ✅ HAZIR | Remotes:"..#REMOTE_LIST.." | Tools:"..#TOOL_DEFS)
print("[SERVER_MAIN] Ölüm → Aynı takım respawn | BodyTypeScale:YOK | CarryEvent:YOK")
print(("="):rep(60))
