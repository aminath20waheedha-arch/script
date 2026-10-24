-- lang: Luau, file: mi_admin_v2.lua, target: Roblox LocalScript executor
-- MI's Admin v2 — full Axiom feature integration

print("MI ADMIN: SCRIPT STARTED")

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local camera      = workspace.CurrentCamera

------------------------------------------------------------------ config
local CONFIG = {
    title="MI'S ADMIN", placeholder="type here...",
    toggleKey=Enum.KeyCode.RightShift,
    width=112, headH=15, inputH=18, margin=5,
    saturnId="rbxassetid://15861195995",
    debugHeight=2.4, debugTime=2.6,
    binary={enabled=true,textSize=13,padding=30,fps=30,
            ramp=" .,:;-=+*x#%@",color=Color3.fromRGB(255,255,255),mouse=true},
    helpBinary={enabled=true,textSize=13,padding=30,fps=30,
                ramp=" .,:;-=+*x#%@",color=Color3.fromRGB(255,255,255),mouse=true},
}
local W,HEAD_H,INPUT_H,MARGIN,SOFT,SHADOW_BASE =
    CONFIG.width,CONFIG.headH,CONFIG.inputH,CONFIG.margin,0.22,0.35

------------------------------------------------------------------ colors
local col = {
    bg=Color3.fromRGB(13,13,13), dim=Color3.fromRGB(120,120,120),
    grey=Color3.fromRGB(150,150,150), white=Color3.fromRGB(255,255,255),
    black=Color3.fromRGB(0,0,0), red=Color3.fromRGB(255,57,57),
    green=Color3.fromRGB(110,255,150), inputBg=Color3.fromRGB(22,22,22),
    inputBgFocus=Color3.fromRGB(28,28,28), inputStroke=Color3.fromRGB(48,48,48),
    inputStrokeFocus=Color3.fromRGB(95,95,95), buttonBg=Color3.fromRGB(30,30,30),
    buttonStroke=Color3.fromRGB(70,70,70), saturn=Color3.fromRGB(160,160,160),
    blue=Color3.fromRGB(70,150,255), orange=Color3.fromRGB(255,150,60),
    crimson=Color3.fromRGB(230,60,60), neutral=Color3.fromRGB(200,200,210),
}
local ROLE_COLORS = {
    Guard=col.blue, Inmate=col.orange, Criminal=col.crimson,
    Neutral=col.neutral, Unknown=Color3.fromRGB(180,180,190),
}
local TONES = {
    good={Color3.fromRGB(60,190,100),Color3.fromRGB(110,255,150),Color3.fromRGB(205,255,222)},
    bad ={Color3.fromRGB(190,40,40) ,Color3.fromRGB(255,57,57)  ,Color3.fromRGB(255,175,175)},
}

------------------------------------------------------------------ feature settings
getgenv().SilentAimSettings = getgenv().SilentAimSettings or {
    Enabled=false,ForceFieldCheck=true,TargetPart="HumanoidRootPart",
    Method="Raycast",VisibleCheck=true,TeamCheck=true,Smoothing=0,
    HitChance=100,FOVEnabled=true,FOVRadius=150,FOVColor=Color3.fromRGB(255,255,255),
    FOVThickness=1,FriendCheck=true,TargetTeams={Inmates=true,Guards=true,Criminals=true},
    HostileCheck=false,TrespassCheck=false,TeamOnlyMode=false,
    SilentAimRange=500,AimMode="FOV",TargetOnPlayer={},IgnoreTargets={},
}
getgenv().ESPSettings = {
    Enabled=false,ShowUsername=true,TeamCheck=false,MaxDistance=5000,
    ColorByRole=true,NametagOpacity=0,HighlightEnabled=true,
    HighlightFillAlpha=0.75,HighlightOutlineAlpha=0.35,
    HealthIndicator=true,ShowDistance=true,ShowEquipped=true,
    BoxEnabled=false,HealthBarEnabled=true,HealthBarVertical=true,
}
getgenv().HitboxSettings = getgenv().HitboxSettings or {
    Enabled=false,Size=2,Transparency=0.5,AllParts=false,IncludeSelf=false,Visualizer=true,
}
getgenv().NoclipSettings = {
    Enabled=false,Radius=300,IncludeAnchored=true,IncludeUnanchored=false,
}
getgenv().HumanoidSettings = {
    WalkSpeed=16,JumpPower=50,JumpHeight=7.2,HipHeight=2,MaxHealth=100,
    WalkSpeedLocked=false,JumpPowerLocked=false,JumpHeightLocked=false,
    HipHeightLocked=false,MaxHealthLocked=false,Captured=false,
}
getgenv().AutoGiveSettings = {Enabled=true}
getgenv().ArrestSettings = {
    Enabled=true,StickDistance=2.2,StickHeight=0.0,
    StickDuration=5.0,ToolName="Handcuffs",
}
getgenv().TracerSettings = getgenv().TracerSettings or {
    Enabled=false,Color=Color3.fromRGB(255,182,255),Thickness=0.1,
}

local Settings       = getgenv().SilentAimSettings
local ESPSettings    = getgenv().ESPSettings
local HitboxSettings = getgenv().HitboxSettings
local NoclipSettings = getgenv().NoclipSettings
local HumSettings    = getgenv().HumanoidSettings
local AGSettings     = getgenv().AutoGiveSettings
local ArrSettings    = getgenv().ArrestSettings
local TracerSettings = getgenv().TracerSettings

print("MI ADMIN: SETTINGS STARTED")

------------------------------------------------------------------ cleanup
local oldGui = PlayerGui:FindFirstChild("MiAdmin")
if oldGui then oldGui:Destroy() end

------------------------------------------------------------------ helpers
local function create(class,props,children)
    local ok,inst = pcall(Instance.new,class)
    if not ok then return nil end
    local parent
    for k,v in pairs(props or {}) do
        if k=="Parent" then parent=v else pcall(function() inst[k]=v end) end
    end
    for _,child in pairs(children or {}) do if child then child.Parent=inst end end
    if parent then inst.Parent=parent end
    return inst
end
local function corner(r) return create("UICorner",{CornerRadius=UDim.new(0,r or 8)}) end
local function squareCorner(r)
    local c=create("UICorner",{CornerRadius=UDim.new(0,r or 4)})
    pcall(function() c.TopLeftRadius=UDim.new(0,0); c.BottomRightRadius=UDim.new(0,0) end)
    return c
end
local function tween(obj,t,props,style,dir)
    local tw=TweenService:Create(obj,TweenInfo.new(t,style or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),props)
    tw:Play(); return tw
end
local function isClick(input)
    return input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch
end
local function hoverColor(btn,n,h)
    btn.MouseEnter:Connect(function() tween(btn,0.15,{TextColor3=h}) end)
    btn.MouseLeave:Connect(function() tween(btn,0.2, {TextColor3=n}) end)
end
local function SafeDestroy(obj) if obj then pcall(function() obj:Destroy() end) end end
local function SafeSet(obj,prop,val)
    if not obj then return false end
    return pcall(function() if obj[prop]~=val then obj[prop]=val end end)
end
local function esc(s) return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function seg(text,color) return {text=text,color=color} end
local function toRich(segs)
    local p={}
    for _,s in ipairs(segs) do
        table.insert(p,('<font color="#%s">%s</font>'):format(s.color:ToHex(),esc(s.text)))
    end
    return table.concat(p)
end
local function toPlain(segs)
    local p={}; for _,s in ipairs(segs) do table.insert(p,s.text) end; return table.concat(p)
end

print("MI ADMIN: helpers STARTED")

------------------------------------------------------------------ main screengui
local ScreenGui = create("ScreenGui",{
    Name="MiAdmin",ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999,Parent=PlayerGui,
})

print("MI ADMIN: maingui STARTED")

------------------------------------------------------------------ role / health helpers
local function DetectRole(player)
    if not player or not player.Parent then return "Unknown" end
    local team=player.Team
    if team then
        local n=string.lower(team.Name)
        if n:find("guard") or n:find("police") or n:find("cop") or n:find("officer") then return "Guard"
        elseif n:find("inmate") or n:find("prisoner") then return "Inmate"
        elseif n:find("criminal") or n:find("escapee") or n:find("wanted") then return "Criminal"
        elseif n:find("neutral") or n:find("civilian") then return "Neutral" end
        local ok,c=pcall(function() return team.TeamColor.Color end)
        if ok and c then
            local r,g,b=c.R,c.G,c.B
            if b>0.6 and r<0.4 and g<0.6 then return "Guard"
            elseif r>0.7 and g>0.4 and g<0.8 and b<0.4 then return "Inmate"
            elseif r>0.7 and g<0.4 and b<0.4 then return "Criminal"
            elseif r>0.6 and g>0.6 and b>0.6 then return "Neutral" end
        end
    end
    return "Unknown"
end
local function IsLocalGuard() return DetectRole(LocalPlayer)=="Guard" end
local function GetHealth(player)
    if not player then return 0,100 end
    local char=player.Character
    if not char then return 0,100 end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health,hum.MaxHealth end
    return 0,100
end
local function GetHealthColor(hp,mhp)
    if not mhp or mhp<=0 then return col.white end
    local p=math.clamp(hp/mhp,0,1)
    if p>=0.75 then return Color3.fromRGB(70,220,100)
    elseif p>=0.50 then return Color3.fromRGB(180,220,70)
    elseif p>=0.25 then return Color3.fromRGB(255,180,50)
    else return Color3.fromRGB(230,60,60) end
end

print("MI ADMIN: rolehelpers STARTED")

------------------------------------------------------------------ char cache
local CharCache={}
local cachedPlayersList=Players:GetPlayers()
local function UpdatePlayerCache() cachedPlayersList=Players:GetPlayers() end
local function GetCharacter(player)
    if not player then return nil end
    local cache=CharCache[player]
    if cache then
        local char,root=cache.Char,cache.Root
        if char and char.Parent and char==player.Character and root and root.Parent then
            if not cache.Humanoid or cache.Humanoid.Health>0 then return char,root end
            return nil
        end
        cache.Char,cache.Root,cache.Humanoid=nil,nil,nil
    end
    local character=player.Character
    if not character or not character.Parent then return nil end
    local rootPart=character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then return nil end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health<=0 then return nil end
    if not cache then cache={}; CharCache[player]=cache end
    cache.Char,cache.Root,cache.Humanoid=character,rootPart,humanoid
    cache.Head=character:FindFirstChild("Head")
    return character,rootPart
end

print("MI ADMIN: char cache STARTED")

------------------------------------------------------------------ seqBuilder / pulse / drag (existing)
local function buildSeq(f)
    local n,pts=20,table.create(20)
    for i=0,n-1 do
        local t=i/(n-1)
        local top=math.clamp((f-t)/SOFT,0,1)
        local bot=math.clamp((t-(1-f))/SOFT,0,1)
        pts[i+1]=NumberSequenceKeypoint.new(t,math.max(top,bot))
    end
    return NumberSequence.new(pts)
end
local function startPulse(shadow)
    if not shadow then return end
    task.spawn(function()
        while ScreenGui.Parent do
            local ok,tw=pcall(function()
                return TweenService:Create(shadow,
                    TweenInfo.new(0.5+math.random()*0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                    {BlurRadius=UDim.new(0,math.random(16,42))})
            end)
            if not ok or not tw then break end
            tw:Play(); tw.Completed:Wait()
        end
    end)
end
local function makeDraggable(handle,target)
    local dragging,dragInput,dragStart,startPos
    handle.InputBegan:Connect(function(input)
        if dragging or not isClick(input) then return end
        dragging=true
        dragInput=input.UserInputType==Enum.UserInputType.Touch and input or nil
        dragStart,startPos=input.Position,target.Position
        local c; c=input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragging,dragInput=false,nil; c:Disconnect()
            end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local valid=dragInput and (input==dragInput) or (input.UserInputType==Enum.UserInputType.MouseMovement)
        if valid then
            local d=input.Position-dragStart
            target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

print("MI ADMIN: bpd STARTED")

------------------------------------------------------------------ binary backdrop (existing + flash fix)
local function createBinary(holder,width,fullH,cfg)
    local font=Enum.Font.Code
    local huge=Vector2.new(1e5,1e5)
    local size=cfg.textSize
    local cw=TextService:GetTextSize(string.rep("M",40),size,font,huge).X/40
    local h1=TextService:GetTextSize("M",size,font,huge).Y
    local h11=TextService:GetTextSize(string.rep("M\n",10).."M",size,font,huge).Y
    local ch=(h11-h1)/10
    if cw<=0 then cw=size*0.6 end
    if ch<=0 then ch=size end
    local layers={{min=0.1,transparency=0.84},{min=0.4,transparency=0.62},{min=0.7,transparency=0.3}}
    local labels={}
    for i in ipairs(layers) do
        labels[i]=create("TextLabel",{Name="Layer"..i,BackgroundTransparency=1,Font=font,
            TextSize=size,TextColor3=cfg.color or col.white,TextTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
            TextWrapped=false,RichText=false,Text="",ZIndex=0,Parent=holder})
    end
    local ramp={}; for i=1,#cfg.ramp do ramp[i]=cfg.ramp:sub(i,i) end
    local rampLen=#ramp
    local cols,rows,offX,offY=0,0,0,0
    local glow={}; local bufs={{},{},{}}; local lines={{},{},{}}
    local B={fx={alpha=0}}
    function B.setInner(h)
        local area=Vector2.new(width,h)+Vector2.new(cfg.padding*2,cfg.padding*2)
        holder.Size=UDim2.fromOffset(area.X,area.Y)
        cols=math.max(1,math.floor(area.X/cw))
        rows=math.max(1,math.floor(area.Y/ch))
        offX=(area.X-cols*cw)/2; offY=(area.Y-rows*ch)/2
        for _,l in ipairs(labels) do
            l.Position=UDim2.fromOffset(offX,offY)
            l.Size=UDim2.fromOffset(cols*cw+4,rows*ch+4)
        end
        local cx,cy=area.X/2,area.Y/2
        local hw,hh=width/2,h/2
        local pad=cfg.padding
        table.clear(glow)
        for y=0,rows-1 do
            local qy=math.max(math.abs(offY+(y+0.5)*ch-cy)-hh,0)
            for x=0,cols-1 do
                local qx=math.max(math.abs(offX+(x+0.5)*cw-cx)-hw,0)
                local i=y*cols+x+1
                if qx==0 and qy==0 then glow[i]=-1
                else
                    local g=math.clamp(1-math.sqrt(qx*qx+qy*qy)/pad,0,1)
                    glow[i]=g*g*(3-2*g)
                end
            end
        end
        for _,b in ipairs(bufs) do table.clear(b) end
    end
    -- flash fix: define flash here inside createBinary
    function B.flash(kind)
        local tones=TONES[kind]; if not tones then return end
        for i,lbl in ipairs(labels) do
            local c2=tones[math.min(i,#tones)]
            tween(lbl,0.08,{TextColor3=c2})
            task.delay(0.25,function() tween(lbl,0.35,{TextColor3=cfg.color or col.white}) end)
        end
    end
    local noise,sin,cos,sqrt,exp,floor=math.noise,math.sin,math.cos,math.sqrt,math.exp,math.floor
    local min1,min2,min3=layers[1].min,layers[2].min,layers[3].min
    local aspect=ch/cw
    RunService.RenderStepped:Connect(function()
        if not cfg.enabled then return end
        local alpha=B.fx.alpha
        if alpha<=0.001 then return end
        holder.Position=UDim2.fromOffset(-cfg.padding,-cfg.padding)
        local pw,ph=holder.Parent.AbsoluteSize.X,holder.Parent.AbsoluteSize.Y
        if pw>0 and ph>0 and (cols==0 or rows==0) then
            width=pw; fullH=ph; B.setInner(ph)
        end
        local mx,my
        if cfg.mouse and UserInputService.MouseEnabled then
            local m=UserInputService:GetMouseLocation()-holder.AbsolutePosition
            if m.X>=0 and m.Y>=0 and m.X<=holder.AbsoluteSize.X and m.Y<=holder.AbsoluteSize.Y then
                mx,my=m.X,m.Y
            end
        end
        local t=os.clock()
        local mcx,mcy
        if mx then mcx,mcy=(mx-offX)/cw,(my-offY)/ch end
        local b1,b2,b3=bufs[1],bufs[2],bufs[3]
        local l1,l2,l3=lines[1],lines[2],lines[3]
        for y=0,rows-1 do
            local base=y*cols
            local ny=y*0.11-t*0.35
            local wy=cos(y*0.21-t*0.7)
            for x=0,cols-1 do
                local g=glow[base+x+1]
                local c1,c2,c3=" "," "," "
                if g>0 then
                    local v=0.45+noise(x*0.055,ny,t*0.12)*1.3+sin(x*0.12+t*1.1)*wy*0.18
                    if mcx then
                        local dx,dy=x-mcx,(y-mcy)*aspect
                        local d=sqrt(dx*dx+dy*dy)
                        v+=sin(d*0.45-t*7)*exp(-d*0.09)*0.45
                    end
                    v*=g*alpha
                    if v>=min1 then
                        local idx=math.clamp(floor(v*rampLen)+1,2,rampLen)
                        local glyph=ramp[idx]
                        if v>=min3 then c3=glyph elseif v>=min2 then c2=glyph else c1=glyph end
                    end
                end
                b1[x+1],b2[x+1],b3[x+1]=c1,c2,c3
            end
            l1[y+1]=table.concat(b1,"",1,cols)
            l2[y+1]=table.concat(b2,"",1,cols)
            l3[y+1]=table.concat(b3,"",1,cols)
        end
        labels[1].Text=table.concat(l1,"\n",1,rows)
        labels[2].Text=table.concat(l2,"\n",1,rows)
        labels[3].Text=table.concat(l3,"\n",1,rows)
        for i,layer in ipairs(layers) do
            labels[i].TextTransparency=1-(1-layer.transparency)*alpha
        end
    end)
    return B
end

print("MI ADMIN: binary STARTED")

------------------------------------------------------------------ panel factory (existing)
local function createPanel(o)
    local P={state="closed",minimized=false,busy=false}
    local PW,HEAD,BODY=o.width,o.headH,o.bodyH
    local FULL=HEAD+BODY
    P.Root=create("Frame",{Name=o.name,AnchorPoint=Vector2.new(0.5,0.5),
        Position=o.position,Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,Parent=ScreenGui})
    local Main=create("Frame",{Name="Main",AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(PW,FULL),
        BackgroundTransparency=1,Visible=false,Parent=P.Root})
    P.Main=Main
    local Shadow=create("UIShadow",{Transparency=SHADOW_BASE,BlurRadius=UDim.new(0,28)})
    local MainStroke=create("UIStroke",{Color=col.white,Transparency=0,Thickness=0.5})
    local BodyGrad=create("UIGradient",{Rotation=90})
    local StrokeGrad=create("UIGradient",{Rotation=90,Parent=MainStroke})
    create("Frame",{Name="Body",Size=UDim2.fromScale(1,1),BackgroundColor3=col.bg,
        BorderSizePixel=0,ZIndex=1,Parent=Main},{corner(6),Shadow,MainStroke,BodyGrad})
    local Holder=create("Frame",{Name="BinaryBackdrop",AnchorPoint=Vector2.new(0,0),
        Position=UDim2.fromOffset(0,0),BackgroundTransparency=1,ClipsDescendants=true,
        Visible=o.binary.enabled,ZIndex=-1,Parent=Main})
    local ContentGrad=create("UIGradient",{Rotation=90})
    local Content=create("CanvasGroup",{Name="Content",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3,Parent=Main},{ContentGrad})
    P.Content=Content
    local DragArea=create("Frame",{Name="DragArea",Size=UDim2.new(1,-34,0,HEAD),
        BackgroundTransparency=1,ZIndex=1,Parent=Content})
    makeDraggable(DragArea,P.Root)
    create("TextLabel",{Name="Title",Position=UDim2.fromOffset(7,0),
        Size=UDim2.new(1,-44,0,HEAD),BackgroundTransparency=1,Font=Enum.Font.Code,
        Text=o.title,TextSize=8,TextColor3=col.white,TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=2,Parent=Content})
    local function headButton(name,text,xOffset)
        return create("TextButton",{Name=name,AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,xOffset,0,HEAD/2),Size=UDim2.fromOffset(12,12),
            BackgroundTransparency=1,AutoButtonColor=false,Font=Enum.Font.GothamBold,
            Text=text,TextSize=12,TextColor3=col.dim,ZIndex=3,Parent=Content})
    end
    local MinBtn=headButton("MinimizeButton","\u{2013}",-17)
    local CloseBtn=headButton("CloseButton","\u{00D7}",-4)
    hoverColor(MinBtn,col.dim,col.white); hoverColor(CloseBtn,col.dim,col.red)
    startPulse(Shadow)
    local B=createBinary(Holder,PW,FULL,o.binary); P.binary=B
    local minValue=Instance.new("NumberValue")
    local curH=FULL
    minValue.Changed:Connect(function(m)
        curH=HEAD+BODY*(1-m); Main.Size=UDim2.fromOffset(PW,curH)
        B.setInner(curH); if o.onMin then o.onMin(m) end
    end)
    function P.getHeight() return curH end
    local function releaseFocus()
        local f=UserInputService:GetFocusedTextBox()
        if f and f:IsDescendantOf(Main) then f:ReleaseFocus() end
    end
    local minBusy=false
    function P.setMinimized(state)
        if minBusy or P.state~="open" or state==P.minimized then return end
        minBusy=true; P.minimized=state
        if state then releaseFocus() end
        MinBtn.Text=state and "+" or "\u{2013}"
        local tw=tween(minValue,0.45,{Value=state and 1 or 0},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut)
        tw.Completed:Connect(function() minBusy=false end)
    end
    MinBtn.Activated:Connect(function() P.setMinimized(not P.minimized) end)
    local progValue=Instance.new("NumberValue"); progValue.Value=1
    local function setProgress(p)
        local s=buildSeq(p*(0.5+SOFT))
        BodyGrad.Transparency=s; StrokeGrad.Transparency=s; ContentGrad.Transparency=s
        B.fx.alpha=1-p
    end
    progValue.Changed:Connect(setProgress); setProgress(1)
    function P.close()
        if P.busy or P.state~="open" then return false end
        P.busy=true; releaseFocus()
        local tw=tween(progValue,0.8,{Value=1},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        tw.Completed:Connect(function() Main.Visible=false; P.state="closed"; P.busy=false end)
        return true
    end
    function P.open()
        if P.busy or P.state~="closed" then return false end
        P.busy=true; minValue.Value=P.minimized and 1 or 0; Main.Visible=true
        local tw=tween(progValue,0.8,{Value=0},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        tw.Completed:Connect(function() P.state="open"; P.busy=false end)
        return true
    end
    CloseBtn.Activated:Connect(P.close)
    return P
end

print("MI ADMIN: panelfac STARTED")

------------------------------------------------------------------ generic panel UI builder
local function buildPanelContent(panelObj, innerW, bodyH)
    local ROW_H, GAP = 16, 3
    local listGroup=create("CanvasGroup",{Name="ListGroup",
        Position=UDim2.fromOffset(6,panelObj.Main.Size.Y-bodyH),
        Size=UDim2.new(1,-12,0,bodyH-6),BackgroundTransparency=1,
        ClipsDescendants=true,Parent=panelObj.Content})
    local scroll=create("ScrollingFrame",{Name="Scroll",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,ScrollBarThickness=2,Parent=listGroup})
    local sections={}
    local function relayout()
        local y=0
        for _,c in ipairs(sections) do
            local inner=GAP
            for _,row in ipairs(c.rows) do
                local h=row.dynamicH and row.dynamicH() or ROW_H
                row.frame.Position=UDim2.fromOffset(4,ROW_H+inner)
                row.frame.Size=UDim2.fromOffset(innerW-8,h)
                inner=inner+h+GAP
            end
            local h=ROW_H+inner*c.t.Value
            c.frame.Position=UDim2.fromOffset(0,y)
            c.frame.Size=UDim2.fromOffset(innerW,h)
            y=y+h+GAP
        end
        scroll.CanvasSize=UDim2.fromOffset(0,y)
    end
    local function addSection(title,startOpen)
        local c={t=Instance.new("NumberValue"),rows={},innerW=innerW}
        c.t.Value=startOpen and 1 or 0
        c.frame=create("Frame",{Size=UDim2.fromOffset(innerW,ROW_H),
            BackgroundTransparency=1,ClipsDescendants=true,Parent=scroll})
        local header=create("TextButton",{Size=UDim2.fromOffset(innerW,ROW_H),
            BackgroundColor3=col.inputBg,BorderSizePixel=0,AutoButtonColor=false,
            Font=Enum.Font.Code,Text=title,TextSize=9,TextColor3=col.white,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=c.frame},
            {squareCorner(4),create("UIStroke",{Color=col.inputStroke,Thickness=0.6}),
             create("UIPadding",{PaddingLeft=UDim.new(0,6)})})
        local open=startOpen or false
        header.Activated:Connect(function()
            open=not open; tween(c.t,0.35,{Value=open and 1 or 0},Enum.EasingStyle.Quint)
        end)
        c.t.Changed:Connect(relayout); table.insert(sections,c); return c
    end
    local function addCheckbox(section,label,getValue,setValue)
        local row={}
        row.frame=create("Frame",{Size=UDim2.fromOffset(innerW-8,ROW_H),
            BackgroundTransparency=1,Parent=section.frame})
        local box=create("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.fromOffset(8,8),
            BackgroundColor3=col.inputBg,BorderSizePixel=0,Parent=row.frame},
            {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
        local tick=create("Frame",{Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),
            Size=UDim2.fromOffset(4,4),BackgroundColor3=col.green,BorderSizePixel=0,
            Visible=getValue()==true,Parent=box},{squareCorner(1)})
        local btn=create("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=row.frame})
        create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-14,1,0),
            BackgroundTransparency=1,Font=Enum.Font.Code,Text=label,TextSize=8,
            TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=row.frame})
        btn.Activated:Connect(function()
            local nv=not getValue(); setValue(nv); tick.Visible=nv==true
        end)
        row.tick=tick; table.insert(section.rows,row); return row
    end
    local function addSlider(section,label,getValue,setValue,minV,maxV,step)
        local row={}
        row.frame=create("Frame",{Size=UDim2.fromOffset(innerW-8,ROW_H),
            BackgroundTransparency=1,Parent=section.frame})
        create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-44,1,0),
            BackgroundTransparency=1,Font=Enum.Font.Code,Text=label,TextSize=8,
            TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=row.frame})
        local valLbl=create("TextLabel",{AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(30,ROW_H),
            BackgroundTransparency=1,Font=Enum.Font.Code,Text=tostring(getValue()),
            TextSize=8,TextColor3=col.white,TextXAlignment=Enum.TextXAlignment.Right,Parent=row.frame})
        local v0=math.clamp((getValue()-minV)/(maxV-minV),0,1)
        local track=create("Frame",{Position=UDim2.fromOffset(0,ROW_H-5),
            Size=UDim2.new(1,0,0,2),BackgroundColor3=col.inputStroke,
            BorderSizePixel=0,Parent=row.frame},{squareCorner(1)})
        local fill=create("Frame",{Size=UDim2.new(v0,0,1,0),BackgroundColor3=col.green,
            BorderSizePixel=0,Parent=track},{squareCorner(1)})
        local knob=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new(v0,0,0.5,0),Size=UDim2.fromOffset(6,6),
            BackgroundColor3=col.white,BorderSizePixel=0,Parent=track},{corner(3)})
        local drag=create("TextButton",{Position=UDim2.fromOffset(0,ROW_H-10),
            Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,Text="",Parent=row.frame})
        local dragging=false
        local function setFromX(absX)
            local relX=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v=math.clamp(math.floor((minV+(maxV-minV)*relX)/step+0.5)*step,minV,maxV)
            setValue(v); valLbl.Text=tostring(v)
            local p=(v-minV)/(maxV-minV)
            fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
        end
        drag.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true; setFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
        row.valueLabel=valLbl; table.insert(section.rows,row); return row
    end
    local function addDropdown(section,label,options,getValue,setValue)
        local optH=ROW_H-2
        local totalH=#options*optH
        local expandV=Instance.new("NumberValue"); expandV.Value=0
        local expanded=false
        local row={}
        row.dynamicH=function() return ROW_H+totalH*expandV.Value end
        row.frame=create("Frame",{BackgroundTransparency=1,ClipsDescendants=true,Parent=section.frame})
        local headerBg=create("Frame",{Size=UDim2.new(1,0,0,ROW_H),BackgroundColor3=col.inputBg,
            BorderSizePixel=0,Parent=row.frame},
            {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
        create("TextLabel",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.fromOffset(6,0),
            BackgroundTransparency=1,Font=Enum.Font.Code,Text=label,TextSize=8,
            TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=headerBg})
        local valLbl=create("TextLabel",{Size=UDim2.new(0.45,-8,1,0),
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),
            BackgroundTransparency=1,Font=Enum.Font.Code,
            Text=tostring(getValue()).." ▾",TextSize=8,TextColor3=col.white,
            TextXAlignment=Enum.TextXAlignment.Right,Parent=headerBg})
        local clickArea=create("TextButton",{Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,Text="",Parent=headerBg})
        local optBtns={}
        for i,opt in ipairs(options) do
            local isSel=tostring(getValue())==tostring(opt)
            local optBtn=create("TextButton",{
                Position=UDim2.fromOffset(2,ROW_H+(i-1)*optH),
                Size=UDim2.new(1,-4,0,optH-1),
                BackgroundColor3=isSel and Color3.fromRGB(20,30,20) or col.bg,
                BorderSizePixel=0,Font=Enum.Font.Code,Text=tostring(opt),TextSize=8,
                TextColor3=isSel and col.green or col.grey,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=row.frame},
                {create("UIPadding",{PaddingLeft=UDim.new(0,8)})})
            local selBar=create("Frame",{Size=UDim2.fromOffset(2,optH-4),
                Position=UDim2.fromOffset(0,2),BackgroundColor3=col.green,
                BorderSizePixel=0,Visible=isSel,Parent=optBtn})
            optBtns[i]={btn=optBtn,sel=selBar,value=opt}
            optBtn.Activated:Connect(function()
                setValue(opt); valLbl.Text=tostring(opt).." ▾"
                for j,data in ipairs(optBtns) do
                    local s=tostring(data.value)==tostring(opt)
                    tween(data.btn,0.1,{BackgroundColor3=s and Color3.fromRGB(20,30,20) or col.bg})
                    data.btn.TextColor3=s and col.green or col.grey
                    data.sel.Visible=s
                end
                expanded=false; tween(expandV,0.2,{Value=0},Enum.EasingStyle.Quint)
            end)
        end
        clickArea.Activated:Connect(function()
            expanded=not expanded
            valLbl.Text=tostring(getValue())..(expanded and " ▴" or " ▾")
            tween(expandV,0.25,{Value=expanded and 1 or 0},Enum.EasingStyle.Quint)
        end)
        expandV.Changed:Connect(relayout)
        table.insert(section.rows,row); return row
    end
    local function addButton(section,text,onClick)
        local row={}
        row.frame=create("Frame",{BackgroundTransparency=1,Parent=section.frame})
        local btn=create("TextButton",{Size=UDim2.new(1,0,0,ROW_H-2),
            BackgroundColor3=col.buttonBg,BorderSizePixel=0,Font=Enum.Font.Code,
            Text=text,TextSize=8,TextColor3=col.green,Parent=row.frame},
            {squareCorner(3),create("UIStroke",{Color=col.buttonStroke,Thickness=0.6})})
        btn.Activated:Connect(function() if onClick then pcall(onClick) end end)
        table.insert(section.rows,row); return row
    end
    local function addPlayerList(section,getEntries,rowBuilder)
        local row={}; row.frame=create("Frame",{BackgroundTransparency=1,Parent=section.frame})
        local function rebuild()
            for _,ch in ipairs(row.frame:GetChildren()) do ch:Destroy() end
            local entries=getEntries(); local h=#entries*(ROW_H+GAP)
            if h<=0 then
                local lbl=create("TextLabel",{Size=UDim2.new(1,0,0,ROW_H),
                    BackgroundTransparency=1,Font=Enum.Font.Code,Text="no entries",
                    TextSize=8,TextColor3=col.dim,Parent=row.frame})
                h=ROW_H
            else
                for i,entry in ipairs(entries) do
                    rowBuilder(row.frame,entry,(i-1)*(ROW_H+GAP),innerW-8,ROW_H)
                end
            end
            row.frame.Size=UDim2.fromOffset(innerW-8,h)
            row.dynamicH=function() return h end
            relayout()
        end
        row.rebuild=rebuild; rebuild()
        table.insert(section.rows,row); return row
    end
    return {
        addSection=addSection,addCheckbox=addCheckbox,addSlider=addSlider,
        addDropdown=addDropdown,addButton=addButton,addPlayerList=addPlayerList,
        relayout=relayout,sections=sections,scroll=scroll,
    }
end

print("MI ADMIN: genericpanelui STARTED")

------------------------------------------------------------------ ESP backend
local ESP={Objects={},Folder=nil}
local function EnsureESPFolder()
    if ESP.Folder and ESP.Folder.Parent then return ESP.Folder end
    local parent=(gethui and gethui()) or game:GetService("CoreGui")
    ESP.Folder=Instance.new("Folder"); ESP.Folder.Name="MiAdmin_ESP"
    pcall(function() ESP.Folder.Parent=parent end)
    if not ESP.Folder.Parent then ESP.Folder.Parent=game:GetService("CoreGui") end
    return ESP.Folder
end
local function CreateESPNametag(player)
    local folder=EnsureESPFolder()
    local billboard=Instance.new("BillboardGui")
    billboard.Name="ESP_"..player.Name; billboard.Adornee=nil
    billboard.AlwaysOnTop=true; billboard.Size=UDim2.new(0,200,0,80)
    billboard.StudsOffset=Vector3.new(0,3.2,0); billboard.MaxDistance=ESPSettings.MaxDistance
    billboard.Enabled=false; billboard.Parent=folder
    local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Vertical
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
    layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,1); layout.Parent=billboard
    local nameLabel=Instance.new("TextLabel"); nameLabel.Name="NameLabel"
    nameLabel.Size=UDim2.new(1,0,0,16); nameLabel.BackgroundTransparency=1
    nameLabel.Text=player.Name; nameLabel.TextColor3=ROLE_COLORS.Unknown
    nameLabel.TextStrokeTransparency=0; nameLabel.TextStrokeColor3=col.black
    nameLabel.TextSize=13; nameLabel.Font=Enum.Font.Code; nameLabel.LayoutOrder=1
    nameLabel.TextTransparency=ESPSettings.NametagOpacity; nameLabel.Parent=billboard
    local healthNum=Instance.new("TextLabel"); healthNum.Name="HealthNum"
    healthNum.Size=UDim2.new(1,0,0,14); healthNum.BackgroundTransparency=1
    healthNum.Text="100/100"; healthNum.TextColor3=col.white
    healthNum.TextStrokeTransparency=0; healthNum.TextStrokeColor3=col.black
    healthNum.TextSize=11; healthNum.Font=Enum.Font.Code; healthNum.LayoutOrder=2
    healthNum.Visible=ESPSettings.HealthIndicator; healthNum.Parent=billboard
    local distLabel=Instance.new("TextLabel"); distLabel.Name="DistLabel"
    distLabel.Size=UDim2.new(1,0,0,13); distLabel.BackgroundTransparency=1
    distLabel.Text="0 studs"; distLabel.TextColor3=Color3.fromRGB(200,200,200)
    distLabel.TextStrokeTransparency=0; distLabel.TextStrokeColor3=col.black
    distLabel.TextSize=10; distLabel.Font=Enum.Font.Code; distLabel.LayoutOrder=3
    distLabel.Visible=ESPSettings.ShowDistance; distLabel.Parent=billboard
    local eqLabel=Instance.new("TextLabel"); eqLabel.Name="EqLabel"
    eqLabel.Size=UDim2.new(1,0,0,13); eqLabel.BackgroundTransparency=1
    eqLabel.Text="[Unarmed]"; eqLabel.TextColor3=Color3.fromRGB(200,200,200)
    eqLabel.TextStrokeTransparency=0; eqLabel.TextStrokeColor3=col.black
    eqLabel.TextSize=10; eqLabel.Font=Enum.Font.Code; eqLabel.LayoutOrder=4
    eqLabel.Visible=ESPSettings.ShowEquipped; eqLabel.Parent=billboard
    local highlight=Instance.new("Highlight"); highlight.Name="HL_"..player.Name
    highlight.Adornee=nil; highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor=ROLE_COLORS.Unknown; highlight.FillTransparency=ESPSettings.HighlightFillAlpha
    highlight.OutlineColor=ROLE_COLORS.Unknown; highlight.OutlineTransparency=ESPSettings.HighlightOutlineAlpha
    highlight.Enabled=false; highlight.Parent=folder
    ESP.Objects[player]={Nametag=billboard,NameLabel=nameLabel,HealthNum=healthNum,
        DistLabel=distLabel,EqLabel=eqLabel,Highlight=highlight,
        LastName=player.Name,LastRole=nil,LastHealth=-1,LastDist=-1,LastEq=""}
end
local function RemoveESPNametag(player)
    local d=ESP.Objects[player]; if not d then return end
    SafeDestroy(d.Nametag); SafeDestroy(d.Highlight); ESP.Objects[player]=nil
end
local function UpdateESPNametag(player)
    local d=ESP.Objects[player]; if not d then return end
    local shouldShow=ESPSettings.Enabled
    if shouldShow and ESPSettings.TeamCheck then
        if player.Team and LocalPlayer.Team and player.Team==LocalPlayer.Team then shouldShow=false end
    end
    if player==LocalPlayer then shouldShow=false end
    local char=player.Character
    local root=char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then shouldShow=false end
    local dist=0
    if shouldShow then
        local myRoot=LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        if myRoot then
            dist=(root.Position-myRoot.Position).Magnitude
            if dist>ESPSettings.MaxDistance then shouldShow=false end
        end
    end
    if not shouldShow then
        SafeSet(d.Nametag,"Enabled",false)
        if d.Highlight then SafeSet(d.Highlight,"Enabled",false) end
        return
    end
    if d.Nametag.Adornee~=root then d.Nametag.Adornee=root end
    SafeSet(d.Nametag,"Enabled",true)
    SafeSet(d.Nametag,"MaxDistance",ESPSettings.MaxDistance)
    if d.Highlight then
        if d.Highlight.Adornee~=char then d.Highlight.Adornee=char end
        SafeSet(d.Highlight,"Enabled",ESPSettings.HighlightEnabled)
        SafeSet(d.Highlight,"FillTransparency",ESPSettings.HighlightFillAlpha)
        SafeSet(d.Highlight,"OutlineTransparency",ESPSettings.HighlightOutlineAlpha)
    end
    if ESPSettings.ShowUsername then
        if d.LastName~=player.Name then d.LastName=player.Name; SafeSet(d.NameLabel,"Text",player.Name) end
        SafeSet(d.NameLabel,"Visible",true)
    else SafeSet(d.NameLabel,"Visible",false) end
    local hp,mhp=GetHealth(player)
    SafeSet(d.HealthNum,"Visible",ESPSettings.HealthIndicator)
    if d.LastHealth~=math.floor(hp) then
        d.LastHealth=math.floor(hp)
        SafeSet(d.HealthNum,"Text",string.format("%d/%d",math.floor(hp),math.floor(mhp)))
        SafeSet(d.HealthNum,"TextColor3",GetHealthColor(hp,mhp))
    end
    SafeSet(d.DistLabel,"Visible",ESPSettings.ShowDistance)
    local dr=math.floor(dist)
    if math.abs(d.LastDist-dr)>=1 then d.LastDist=dr; SafeSet(d.DistLabel,"Text",dr.." studs") end
    SafeSet(d.EqLabel,"Visible",ESPSettings.ShowEquipped)
    local tool=char:FindFirstChildOfClass("Tool")
    local eq="["..(tool and tool.Name or "Unarmed").."]"
    if d.LastEq~=eq then d.LastEq=eq; SafeSet(d.EqLabel,"Text",eq) end
    local role=ESPSettings.ColorByRole and DetectRole(player) or nil
    local roleKey=role or "plain"
    if d.LastRole~=roleKey then
        d.LastRole=roleKey
        local clr=role and (ROLE_COLORS[role] or ROLE_COLORS.Unknown) or ROLE_COLORS.Neutral
        SafeSet(d.NameLabel,"TextColor3",clr)
        if d.Highlight then SafeSet(d.Highlight,"FillColor",clr); SafeSet(d.Highlight,"OutlineColor",clr) end
    end
    local op=ESPSettings.NametagOpacity
    SafeSet(d.NameLabel,"TextTransparency",op)
    SafeSet(d.HealthNum,"TextTransparency",op)
    SafeSet(d.DistLabel,"TextTransparency",op)
    SafeSet(d.EqLabel,"TextTransparency",op)
end
local function RefreshESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            if not ESP.Objects[p] then CreateESPNametag(p) end
            UpdateESPNametag(p)
        end
    end
    for p in pairs(ESP.Objects) do
        if not p.Parent then RemoveESPNametag(p) end
    end
end

print("MI ADMIN: espbeckend STARTED")

-- 2D box ESP
local ESP2D={Objects={},Gui=nil}
local function EnsureESP2DGui()
    if ESP2D.Gui and ESP2D.Gui.Parent then return ESP2D.Gui end
    local gui=Instance.new("ScreenGui"); gui.Name="MiAdmin_ESP2D"
    gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=998
    local parent=(gethui and gethui()) or game:GetService("CoreGui")
    local ok=pcall(function() gui.Parent=parent end)
    if not ok or not gui.Parent then gui.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    ESP2D.Gui=gui; return gui
end
local function CreateESP2D(player)
    local gui=EnsureESP2DGui()
    local root=Instance.new("Frame"); root.Name="P_"..player.UserId
    root.BackgroundTransparency=1; root.BorderSizePixel=0; root.Visible=false; root.Parent=gui
    local box=Instance.new("Frame"); box.Name="Box"; box.BackgroundTransparency=1
    box.BorderSizePixel=0; box.Size=UDim2.fromScale(1,1); box.Parent=root
    local stroke=Instance.new("UIStroke"); stroke.Thickness=1.5
    stroke.Color=ROLE_COLORS.Unknown; stroke.Transparency=0.04; stroke.Parent=box
    local hbg=Instance.new("Frame"); hbg.Name="HealthBG"
    hbg.BackgroundColor3=Color3.fromRGB(12,15,19); hbg.BackgroundTransparency=0.12
    hbg.BorderSizePixel=0; hbg.Visible=false; hbg.Parent=gui
    local hfill=Instance.new("Frame"); hfill.Name="HealthFill"
    hfill.BackgroundColor3=Color3.fromRGB(80,230,130); hfill.BorderSizePixel=0; hfill.Parent=hbg
    ESP2D.Objects[player]={Root=root,Box=box,Stroke=stroke,HealthBG=hbg,HealthFill=hfill}
end
local function RemoveESP2D(player)
    local d=ESP2D.Objects[player]; if not d then return end
    SafeDestroy(d.Root); SafeDestroy(d.HealthBG); ESP2D.Objects[player]=nil
end
local function UpdateESP2D()
    local cam=workspace.CurrentCamera; if not cam then return end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer then
            if not ESP2D.Objects[player] then CreateESP2D(player) end
            local d=ESP2D.Objects[player]
            local char=player.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            local show=ESPSettings.Enabled and (ESPSettings.BoxEnabled or ESPSettings.HealthBarEnabled)
                and char and hum and hum.Health>0
            if show and ESPSettings.TeamCheck and player.Team and LocalPlayer.Team and player.Team==LocalPlayer.Team then show=false end
            if show then
                local ok,cf,sz=pcall(function() return char:GetBoundingBox() end)
                if ok and cf and sz then
                    local half=sz*0.5
                    local corners={
                        Vector3.new(-half.X,-half.Y,-half.Z),Vector3.new(-half.X,-half.Y,half.Z),
                        Vector3.new(-half.X,half.Y,-half.Z),Vector3.new(-half.X,half.Y,half.Z),
                        Vector3.new(half.X,-half.Y,-half.Z),Vector3.new(half.X,-half.Y,half.Z),
                        Vector3.new(half.X,half.Y,-half.Z),Vector3.new(half.X,half.Y,half.Z),
                    }
                    local mnX,mnY,mxX,mxY=math.huge,math.huge,-math.huge,-math.huge
                    local valid=false
                    for _,c2 in ipairs(corners) do
                        local v=cam:WorldToViewportPoint(cf:PointToWorldSpace(c2))
                        if v.Z>0 then valid=true
                            mnX,mnY=math.min(mnX,v.X),math.min(mnY,v.Y)
                            mxX,mxY=math.max(mxX,v.X),math.max(mxY,v.Y)
                        end
                    end
                    if valid and mxX>mnX and mxY>mnY then
                        mnX,mnY=math.floor(mnX),math.floor(mnY)
                        mxX,mxY=math.floor(mxX),math.floor(mxY)
                        d.Root.Position=UDim2.fromOffset(mnX,mnY)
                        d.Root.Size=UDim2.fromOffset(math.max(2,mxX-mnX),math.max(2,mxY-mnY))
                        d.Root.Visible=true; d.Box.Visible=ESPSettings.BoxEnabled
                        local clr=ROLE_COLORS.Neutral
                        if ESPSettings.ColorByRole then
                            clr=ROLE_COLORS[DetectRole(player)] or ROLE_COLORS.Unknown
                        end
                        d.Stroke.Color=clr
                        local hp,mhp=GetHealth(player)
                        local pct=math.clamp(hp/math.max(mhp,1),0,1)
                        local hpClr=GetHealthColor(hp,mhp)
                        d.HealthBG.Visible=ESPSettings.HealthBarEnabled
                        d.HealthFill.BackgroundColor3=hpClr
                        if ESPSettings.HealthBarVertical then
                            d.HealthBG.Position=UDim2.fromOffset(mnX-7,mnY)
                            d.HealthBG.Size=UDim2.fromOffset(4,math.max(2,mxY-mnY))
                            d.HealthFill.AnchorPoint=Vector2.new(0,1)
                            d.HealthFill.Position=UDim2.new(0,0,1,0)
                            d.HealthFill.Size=UDim2.new(1,0,pct,0)
                        else
                            d.HealthBG.Position=UDim2.fromOffset(mnX,mxY+4)
                            d.HealthBG.Size=UDim2.fromOffset(math.max(2,mxX-mnX),4)
                            d.HealthFill.AnchorPoint=Vector2.new(0,0)
                            d.HealthFill.Position=UDim2.fromOffset(0,0)
                            d.HealthFill.Size=UDim2.new(pct,0,1,0)
                        end
                    else d.Root.Visible=false; d.HealthBG.Visible=false end
                else d.Root.Visible=false; d.HealthBG.Visible=false end
            else d.Root.Visible=false; if d.HealthBG then d.HealthBG.Visible=false end end
        end
    end
    for player in pairs(ESP2D.Objects) do
        if not player.Parent then RemoveESP2D(player) end
    end
end

------------------------------------------------------------------ hitbox backend (upgraded)
local HitboxState={Original={}}
local function HitboxRemember(part)
    if not HitboxState.Original[part] then
        HitboxState.Original[part]={Size=part.Size,Transparency=part.Transparency}
    end
end
local function HitboxRestoreChar(char)
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do
        local orig=HitboxState.Original[part]
        if part:IsA("BasePart") and orig then
            pcall(function() part.Size=orig.Size; part.Transparency=orig.Transparency end)
            HitboxState.Original[part]=nil
        end
    end
    local viz=char:FindFirstChild("MiHitboxViz"); if viz then viz:Destroy() end
end
local function HitboxApplyChar(char)
    if not HitboxSettings.Enabled or not char then return end
    local player=Players:GetPlayerFromCharacter(char)
    if not player or (player==LocalPlayer and not HitboxSettings.IncludeSelf) then return end
    local parts={}
    if HitboxSettings.AllParts then
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(parts,part) end
        end
    else
        local hrp=char:FindFirstChild("HumanoidRootPart"); if hrp then table.insert(parts,hrp) end
    end
    for _,part in ipairs(parts) do
        HitboxRemember(part)
        pcall(function()
            part.Size=Vector3.new(HitboxSettings.Size,HitboxSettings.Size,HitboxSettings.Size)
            part.Transparency=HitboxSettings.Transparency
        end)
    end
    if HitboxSettings.Visualizer then
        if not char:FindFirstChild("MiHitboxViz") then
            local hl=Instance.new("Highlight"); hl.Name="MiHitboxViz"
            hl.FillColor=col.blue; hl.FillTransparency=0.55
            hl.OutlineColor=col.blue; hl.OutlineTransparency=0.05
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee=char; hl.Parent=char
        end
    else
        local viz=char:FindFirstChild("MiHitboxViz"); if viz then viz:Destroy() end
    end
end
local function HitboxRestoreAll()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character then HitboxRestoreChar(p.Character) end
    end
    table.clear(HitboxState.Original)
end
local function HitboxRefreshAll()
    HitboxRestoreAll()
    if HitboxSettings.Enabled then
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then HitboxApplyChar(p.Character) end
        end
    end
end
for _,p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(char)
        task.wait(0.35)
        if HitboxSettings.Enabled then HitboxApplyChar(char) end
    end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.35)
        if HitboxSettings.Enabled then HitboxApplyChar(char) end
    end)
end)

------------------------------------------------------------------ noclip backend
local Noclip={Broken={},BrokenCount=0}
local Noclip_OP=OverlapParams.new(); Noclip_OP.FilterType=Enum.RaycastFilterType.Exclude; Noclip_OP.MaxParts=0
local Noclip_RP=RaycastParams.new(); Noclip_RP.FilterType=Enum.RaycastFilterType.Exclude; Noclip_RP.IgnoreWater=true
local function NoclipShouldBreak(part)
    if not part or not part:IsA("BasePart") or part:IsA("Terrain") or not part.Parent then return false end
    local myChar=LocalPlayer.Character
    if myChar and part:IsDescendantOf(myChar) then return false end
    local model=part:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return false end
    if part:IsA("SpawnLocation") then return false end
    local n=string.lower(part.Name)
    if n=="baseplate" or n=="ground" or n=="floor" or n=="base" or n=="terrain" then return false end
    if part.Size.X>400 and part.Size.Z>400 then return false end
    if part.Anchored then
        if not NoclipSettings.IncludeAnchored then return false end
    else
        if not NoclipSettings.IncludeUnanchored then return false end
    end
    return true
end
local function NoclipBreakPart(part)
    if Noclip.Broken[part] then
        if part.CanCollide then pcall(function() part.CanCollide=false end) end
        return
    end
    Noclip.Broken[part]={cc=part.CanCollide}
    Noclip.BrokenCount=Noclip.BrokenCount+1
    pcall(function() part.CanCollide=false end)
end
local function NoclipRestoreAll()
    for part,data in pairs(Noclip.Broken) do
        pcall(function()
            if part and part.Parent and type(data)=="table" then
                part.CanCollide=data.cc
            end
        end)
    end
    Noclip.Broken={}; Noclip.BrokenCount=0
end
local function NoclipScan()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return end
    local ign={char}; Noclip_OP.FilterDescendantsInstances=ign
    local ok,parts=pcall(function() return workspace:GetPartBoundsInRadius(root.Position,NoclipSettings.Radius,Noclip_OP) end)
    if not ok or not parts then return end
    for _,part in ipairs(parts) do
        if NoclipShouldBreak(part) then NoclipBreakPart(part) end
    end
end
local function NoclipEnforce()
    local toRemove=nil
    for part,_ in pairs(Noclip.Broken) do
        if not part or not part.Parent then
            toRemove=toRemove or {}; toRemove[#toRemove+1]=part
        elseif part.CanCollide then
            pcall(function() part.CanCollide=false end)
        end
    end
    if toRemove then
        for _,part in ipairs(toRemove) do
            Noclip.Broken[part]=nil; Noclip.BrokenCount=math.max(0,Noclip.BrokenCount-1)
        end
    end
end

------------------------------------------------------------------ humanoid backend
local HumCapture={Original={},Done=false}
local HUM_PROPS={WalkSpeed="WalkSpeed",JumpPower="JumpPower",JumpHeight="JumpHeight",HipHeight="HipHeight",MaxHealth="MaxHealth"}
local function CaptureHumanoid()
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    for flagK,prop in pairs(HUM_PROPS) do
        local ok,val=pcall(function() return hum[prop] end)
        if ok and val~=nil then
            HumCapture.Original[flagK]=val
            if not HumSettings[flagK.."Locked"] and not HumCapture.Done then
                HumSettings[flagK]=val
            end
        end
    end
    HumCapture.Done=true
end
local function ApplyHumanoid()
    if not HumCapture.Done then return end
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    for flagK,prop in pairs(HUM_PROPS) do
        if HumSettings[flagK.."Locked"] then
            local val=HumSettings[flagK]
            if val~=nil then pcall(function() if hum[prop]~=val then hum[prop]=val end end) end
        end
    end
end

------------------------------------------------------------------ tracer beams backend
local tracerBeams={}
local function RemoveTracer(plr)
    if tracerBeams[plr] then
        if tracerBeams[plr].Beam then tracerBeams[plr].Beam:Destroy() end
        if tracerBeams[plr].Start then tracerBeams[plr].Start:Destroy() end
        if tracerBeams[plr].End then tracerBeams[plr].End:Destroy() end
        tracerBeams[plr]=nil
    end
end
local function UpdateTracer(plr)
    local char=plr.Character; local localChar=LocalPlayer.Character
    local localHRP=localChar and localChar:FindFirstChild("HumanoidRootPart")
    local targetHRP=char and char:FindFirstChild("HumanoidRootPart")
    if not char or not localHRP or not targetHRP then RemoveTracer(plr); return end
    local data=tracerBeams[plr]
    if not data then
        local att0=Instance.new("Attachment",localHRP)
        local att1=Instance.new("Attachment",targetHRP)
        local beam=Instance.new("Beam",targetHRP)
        beam.Attachment0=att0; beam.Attachment1=att1; beam.FaceCamera=true
        data={Beam=beam,Start=att0,End=att1}; tracerBeams[plr]=data
    end
    data.Beam.Color=ColorSequence.new(TracerSettings.Color)
    data.Beam.Width0=TracerSettings.Thickness; data.Beam.Width1=TracerSettings.Thickness
    data.Beam.Enabled=true
end

------------------------------------------------------------------ auto-give backend
local AutoGive={Running=false}
local MP5_POS=Vector3.new(813.698,97.850,2229.396)
local REM_POS=Vector3.new(820.298,97.850,2229.396)
local function FindTouchGiver(targetPos)
    for _,obj in ipairs(workspace:GetChildren()) do
        if obj.Name=="TouchGiver" and obj:IsA("Model") then
            local ok,pos=pcall(function()
                local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                return p and p.Position
            end)
            if ok and pos and (pos-targetPos).Magnitude<5 then return obj,pos end
        end
    end
    return nil
end
local function GetMyRoot()
    local char=LocalPlayer.Character; if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end
local function TeleportToTouchGiver(touchPos,myRoot,homeCFrame)
    if not myRoot or not touchPos then return end
    pcall(function() myRoot.CFrame=CFrame.new(touchPos+Vector3.new(0,6,0)) end)
    task.wait(0.8)
    pcall(function() myRoot.CFrame=homeCFrame end)
    task.wait(0.1)
end
local function RunAutoGive(force)
    if not force and not AGSettings.Enabled then return end
    if AutoGive.Running then return end
    AutoGive.Running=true
    task.wait(1.2)
    local myRoot=GetMyRoot()
    if not myRoot then AutoGive.Running=false; return end
    local homeCF=myRoot.CFrame
    local _,mp5Pos=FindTouchGiver(MP5_POS)
    local _,remPos=FindTouchGiver(REM_POS)
    if not mp5Pos and not remPos then AutoGive.Running=false; return end
    if remPos then TeleportToTouchGiver(remPos,myRoot,homeCF); myRoot=GetMyRoot(); if myRoot then homeCF=myRoot.CFrame end end
    if mp5Pos then TeleportToTouchGiver(mp5Pos,myRoot,homeCF) end
    local finalRoot=GetMyRoot(); if finalRoot then pcall(function() finalRoot.CFrame=homeCF end) end
    AutoGive.Running=false
end

------------------------------------------------------------------ arrest backend
local ArrestState={Running=false,SelectedPlayer=nil,ChaserConn=nil,EndTime=0,HomeCFrame=nil}
local function GetCriminalsList()
    local out={}
    for _,p in ipairs(cachedPlayersList) do
        if p~=LocalPlayer and p.Parent then
            local role=DetectRole(p)
            if role=="Criminal" then
                local char,root=GetCharacter(p)
                if char and root then
                    local myRoot=GetMyRoot()
                    local dist=myRoot and (root.Position-myRoot.Position).Magnitude or 0
                    table.insert(out,{player=p,dist=dist})
                end
            end
        end
    end
    table.sort(out,function(a,b) return a.dist<b.dist end)
    return out
end
local function EquipTool(toolName)
    local char=LocalPlayer.Character; local bp=LocalPlayer:FindFirstChild("Backpack")
    if not char or not bp then return false end
    local equipped=char:FindFirstChildOfClass("Tool")
    if equipped and equipped.Name==toolName then return true end
    local tool=bp:FindFirstChild(toolName)
    if not tool or not tool:IsA("Tool") then return false end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    pcall(function() hum:EquipTool(tool) end); return true
end
local function GetBehindCF(targetRoot)
    if not targetRoot then return nil end
    return targetRoot.CFrame*CFrame.new(0,ArrSettings.StickHeight,ArrSettings.StickDistance)
end
local function StopArrest(restoreCF)
    if ArrestState.ChaserConn then pcall(function() ArrestState.ChaserConn:Disconnect() end); ArrestState.ChaserConn=nil end
    local char=LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.AutoRotate=true end) end
    local myRoot=char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if myRoot and restoreCF then pcall(function() myRoot.CFrame=restoreCF end) end
    ArrestState.Running=false; ArrestState.HomeCFrame=nil
end
local Notify -- forward declare

local function ArrestPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent or ArrestState.Running then return false end
    ArrestState.Running=true
    local myChar=LocalPlayer.Character
    local myRoot=myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    if not myRoot then ArrestState.Running=false; return false end
    local homeCF=myRoot.CFrame
    if not EquipTool(ArrSettings.ToolName) then
        Notify("Arrest","No "..ArrSettings.ToolName.." in backpack.")
        ArrestState.Running=false; return false
    end
    task.wait(0.2)
    local targetChar,targetRoot=GetCharacter(targetPlayer)
    if not targetChar or not targetRoot then
        Notify("Arrest","Target not found.")
        pcall(function() myRoot.CFrame=homeCF end); ArrestState.Running=false; return false
    end
    local behind=GetBehindCF(targetRoot)
    if behind then pcall(function() myRoot.CFrame=behind end); task.wait(0.1) end
    ArrestState.HomeCFrame=homeCF
    ArrestState.EndTime=tick()+ArrSettings.StickDuration
    local char2=LocalPlayer.Character; local hum2=char2 and char2:FindFirstChildOfClass("Humanoid")
    if hum2 then pcall(function() hum2.AutoRotate=false end) end
    ArrestState.ChaserConn=RunService.RenderStepped:Connect(function()
        local myR=LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        if not myR then return end
        local b2=GetBehindCF(targetRoot)
        if b2 then pcall(function() myR.CFrame=b2; myR.AssemblyLinearVelocity=Vector3.zero end) end
    end)
    task.spawn(function()
        while ArrestState.Running do
            task.wait(0.1)
            if tick()>=ArrestState.EndTime then
                StopArrest(homeCF); Notify("Arrest","Stick ended."); break
            end
        end
    end)
    Notify("Arrest",string.format("Sticking to %s for %.0fs.",targetPlayer.Name,ArrSettings.StickDuration))
    return true
end

------------------------------------------------------------------ teleport backend
local SavedLocations={}
local CONFIG_FILE="MiAdmin_Config.json"
local LOC_FILE="MiAdmin_Locations.json"
local function SaveLocations()
    if not writefile then return end
    pcall(function()
        writefile(LOC_FILE,HttpService:JSONEncode(SavedLocations))
    end)
end
local function LoadLocations()
    if not (isfile and readfile) then return end
    pcall(function()
        if isfile(LOC_FILE) then
            local decoded=HttpService:JSONDecode(readfile(LOC_FILE))
            if type(decoded)=="table" then SavedLocations=decoded end
        end
    end)
end
LoadLocations()
local TELEPORT_PRESETS={
    {name="Entrance Tower",pos=Vector3.new(510,122,2325)},
    {name="Police Car Spawn",pos=Vector3.new(595,98,2497)},
    {name="Police Armory",pos=Vector3.new(816,99,2237)},
    {name="Rooftop (Escape)",pos=Vector3.new(946,135,2201)},
    {name="Yard Tower",pos=Vector3.new(822,125,2587)},
    {name="Hammer",pos=Vector3.new(806,98,2525)},
    {name="Knife",pos=Vector3.new(707,97,2508)},
    {name="Criminal Armory",pos=Vector3.new(-936,94,2043)},
    {name="Criminal Car Spawn",pos=Vector3.new(-912,95,2160)},
    {name="Criminal Tower Rooftop",pos=Vector3.new(-371,114,1992)},
}
local function TeleportTo(pos)
    if typeof(pos)~="Vector3" then return false end
    local char=LocalPlayer.Character; if not char then return false end
    local root=char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return false end
    pcall(function()
        root.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
        root.AssemblyLinearVelocity=Vector3.zero
    end)
    return true
end
local function GetCurrentPos()
    local char=LocalPlayer.Character; if not char then return nil end
    local root=char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    return root and root.Position
end

------------------------------------------------------------------ UDim2 serialize helpers (config fix)
local function serUDim2(u) return {XS=u.X.Scale,XO=u.X.Offset,YS=u.Y.Scale,YO=u.Y.Offset} end
local function desUDim2(t)
    if type(t)~="table" then return nil end
    return UDim2.new(t.XS or 0,t.XO or 0,t.YS or 0,t.YO or 0)
end

------------------------------------------------------------------ notification
local NotifyGui,NotifyContainer
local function EnsureNotifyGui()
    if NotifyGui and NotifyGui.Parent then return end
    local parent=(gethui and gethui()) or game:GetService("CoreGui")
    NotifyGui=Instance.new("ScreenGui"); NotifyGui.Name="MiAdmin_Notify"
    NotifyGui.DisplayOrder=1001; NotifyGui.IgnoreGuiInset=true; NotifyGui.ResetOnSpawn=false
    pcall(function() NotifyGui.Parent=parent end)
    if not NotifyGui.Parent then NotifyGui.Parent=game:GetService("CoreGui") end
    NotifyContainer=Instance.new("Frame"); NotifyContainer.Name="Container"
    NotifyContainer.Size=UDim2.new(0,220,1,-40)
    NotifyContainer.Position=UDim2.new(1,-10,1,-10)
    NotifyContainer.AnchorPoint=Vector2.new(1,1)
    NotifyContainer.BackgroundTransparency=1; NotifyContainer.Parent=NotifyGui
    local layout=Instance.new("UIListLayout")
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Right
    layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
    layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,6); layout.Parent=NotifyContainer
end
Notify=function(title,text)
    EnsureNotifyGui()
    local frame=Instance.new("Frame"); frame.Size=UDim2.new(0,210,0,0)
    frame.AutomaticSize=Enum.AutomaticSize.Y; frame.BackgroundColor3=col.bg
    frame.BackgroundTransparency=1; frame.BorderSizePixel=0; frame.Parent=NotifyContainer
    create("UICorner",{CornerRadius=UDim.new(0,6),Parent=frame})
    local stroke=Instance.new("UIStroke"); stroke.Color=col.green; stroke.Thickness=0.5
    stroke.Transparency=1; stroke.Parent=frame
    local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,7); pad.PaddingBottom=UDim.new(0,7)
    pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.Parent=frame
    local tLbl=Instance.new("TextLabel"); tLbl.Size=UDim2.new(1,0,0,13)
    tLbl.BackgroundTransparency=1; tLbl.Text=title; tLbl.Font=Enum.Font.Code
    tLbl.TextSize=9; tLbl.TextColor3=col.green; tLbl.TextXAlignment=Enum.TextXAlignment.Left
    tLbl.TextTransparency=1; tLbl.Parent=frame
    local bLbl=Instance.new("TextLabel"); bLbl.Size=UDim2.new(1,0,0,0)
    bLbl.AutomaticSize=Enum.AutomaticSize.Y; bLbl.Position=UDim2.new(0,0,0,15)
    bLbl.BackgroundTransparency=1; bLbl.Text=tostring(text or ""); bLbl.Font=Enum.Font.Code
    bLbl.TextSize=8; bLbl.TextColor3=col.grey; bLbl.TextWrapped=true
    bLbl.TextXAlignment=Enum.TextXAlignment.Left; bLbl.TextTransparency=1; bLbl.Parent=frame
    tween(frame,0.18,{BackgroundTransparency=0.06})
    tween(stroke,0.18,{Transparency=0.5}); tween(tLbl,0.18,{TextTransparency=0}); tween(bLbl,0.18,{TextTransparency=0})
    task.delay(3,function()
        tween(frame,0.2,{BackgroundTransparency=1}); tween(stroke,0.2,{Transparency=1})
        local t2=tween(tLbl,0.2,{TextTransparency=1}); tween(bLbl,0.2,{TextTransparency=1})
        t2.Completed:Connect(function() SafeDestroy(frame) end)
    end)
end

------------------------------------------------------------------ PANELS FORWARD DECLARES
local InputFrame,InputBox,InputStroke,ClickBtn,ClickScale,showClickBtn,hideClickBtn
local HelpPanel,MainPanel,SilentAimPanel
local ESPPanel,HitboxPanel,NoclipPanel,HumanoidPanel,TeleportPanel,GotoPanel,AutoGivePanel,ArrestPanel

-- PANEL OPEN/CLOSE helpers
local ALL_PANELS_REF={}
local function openPanelOnce(p)
    if p.state=="closed" then p.open() elseif p.minimized then p.setMinimized(false) end
end

------------------------------------------------------------------ main bar (existing)
MainPanel=createPanel({
    name="MiAdminMain",title=CONFIG.title,width=W,headH=HEAD_H,bodyH=INPUT_H+MARGIN,
    position=UDim2.fromScale(0.5,0.58),binary=CONFIG.binary,
    onMin=function(m)
        if not InputFrame then return end
        InputFrame.Size=UDim2.new(1,-12,0,INPUT_H*(1-m))
        InputFrame.BackgroundTransparency=m; InputStroke.Transparency=m
        InputBox.TextTransparency=m; InputFrame.Visible=m<0.99
    end,
})
MainPanel.binary.setInner(INPUT_H+MARGIN)
InputStroke=create("UIStroke",{Color=col.inputStroke,Transparency=0,Thickness=0.6})
InputFrame=create("Frame",{Name="InputFrame",Position=UDim2.fromOffset(6,HEAD_H),
    Size=UDim2.new(1,-12,0,INPUT_H),BackgroundColor3=col.inputBg,BorderSizePixel=0,
    ClipsDescendants=true,ZIndex=2,Parent=MainPanel.Content},
    {squareCorner(4),InputStroke})
InputBox=create("TextBox",{Name="InputBox",Position=UDim2.fromOffset(6,0),
    Size=UDim2.new(1,-12,1,0),BackgroundTransparency=1,Font=Enum.Font.Code,
    PlaceholderText=CONFIG.placeholder,PlaceholderColor3=col.dim,Text="",TextSize=10,
    TextColor3=col.white,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,
    ZIndex=3,Parent=InputFrame})
InputBox.Focused:Connect(function()
    tween(InputStroke,0.2,{Color=col.inputStrokeFocus})
    tween(InputFrame,0.2,{BackgroundColor3=col.inputBgFocus})
end)
ClickScale=create("UIScale",{Scale=0})
ClickBtn=create("TextButton",{Name="ClickGui",AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromOffset(0,(HEAD_H+INPUT_H+MARGIN)/2),Size=UDim2.fromOffset(30,30),
    BackgroundColor3=col.bg,BorderSizePixel=0,AutoButtonColor=false,Text="",Visible=false,
    Parent=MainPanel.Root},{corner(10),create("UIStroke",{Color=col.buttonStroke,Thickness=1}),ClickScale,
    create("ImageLabel",{Name="Saturn",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromScale(0.62,0.62),BackgroundTransparency=1,Image=CONFIG.saturnId,
        ImageColor3=col.saturn,ScaleType=Enum.ScaleType.Fit})})
showClickBtn=function()
    ClickBtn.Position=UDim2.fromOffset(0,MainPanel.getHeight()/2); ClickBtn.Visible=true; ClickScale.Scale=0
    tween(ClickScale,0.45,{Scale=1},Enum.EasingStyle.Back)
end
hideClickBtn=function()
    local tw=tween(ClickScale,0.2,{Scale=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tw.Completed:Connect(function() if MainPanel.state~="closed" then ClickBtn.Visible=false end end)
end
ClickBtn.Activated:Connect(function() MainPanel.open() end)

------------------------------------------------------------------ debug billboard (billboard fix)
local Debug={}
do
    local gui=create("BillboardGui",{Name="DebugBillboard",Size=UDim2.fromOffset(340,30),
        StudsOffset=Vector3.new(0,CONFIG.debugHeight,0),AlwaysOnTop=true,
        ResetOnSpawn=false,Enabled=false,Parent=PlayerGui})
    local AnimScale=create("UIScale",{Scale=1})
    local Anim=create("Frame",{Name="Anim",AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,Parent=gui},{AnimScale})
    local ShadowLabel=create("TextLabel",{Name="Shadow",Position=UDim2.fromOffset(1,2),
        Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.SourceSansItalic,
        TextSize=18,TextColor3=col.black,TextTransparency=1,Text="",Parent=Anim})
    local DebugStroke=create("UIStroke",{Color=col.black,Thickness=1,Transparency=1})
    local DebugLabel=create("TextLabel",{Name="Debug",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,Font=Enum.Font.SourceSansItalic,TextSize=18,
        TextColor3=col.white,TextTransparency=1,RichText=true,Text="",Parent=Anim},{DebugStroke})
    local showId=0
    function Debug.show(segs,isError)
        showId+=1; local id=showId
        task.spawn(function()
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local head=char:WaitForChild("Head",5)
            if not head or id~=showId then return end
            gui.Adornee=head; gui.Enabled=true
            DebugLabel.Text=toRich(segs); ShadowLabel.Text=toPlain(segs)
            AnimScale.Scale=0.8; tween(AnimScale,0.35,{Scale=1},Enum.EasingStyle.Back)
            tween(DebugLabel,0.2,{TextTransparency=0},Enum.EasingStyle.Quad)
            tween(ShadowLabel,0.2,{TextTransparency=0.55},Enum.EasingStyle.Quad)
            task.delay(CONFIG.debugTime,function()
                if id~=showId then return end
                tween(DebugLabel,0.3,{TextTransparency=1},Enum.EasingStyle.Quad)
                tween(ShadowLabel,0.3,{TextTransparency=1},Enum.EasingStyle.Quad)
                task.delay(0.36,function() if id==showId then gui.Enabled=false end end)
            end)
        end)
    end
end

------------------------------------------------------------------ silent aim module (existing)
local currentTarget=nil
local screenGui2=Instance.new("ScreenGui"); screenGui2.Name="FOVGui"
screenGui2.ResetOnSpawn=false; screenGui2.Parent=PlayerGui
local fovCircle=Instance.new("Frame",screenGui2)
fovCircle.Size=UDim2.new(0,Settings.FOVRadius*2,0,Settings.FOVRadius*2)
fovCircle.AnchorPoint=Vector2.new(0.5,0.5); fovCircle.Position=UDim2.new(0.5,0,0.5,0)
fovCircle.BackgroundTransparency=1
Instance.new("UICorner",fovCircle).CornerRadius=UDim.new(1,0)
local fovStroke=Instance.new("UIStroke",fovCircle)
fovStroke.Color=Settings.FOVColor; fovStroke.Thickness=Settings.FOVThickness; fovCircle.Visible=false
RunService.RenderStepped:Connect(function()
    if not fovCircle then return end
    fovCircle.Size=UDim2.new(0,Settings.FOVRadius*2,0,Settings.FOVRadius*2)
    local usingTouch=UserInputService:GetLastInputType()==Enum.UserInputType.Touch
    if usingTouch then fovCircle.Position=UDim2.new(0.5,0,0.5,0)
    else
        local mp=UserInputService:GetMouseLocation(); local inset=GuiService:GetGuiInset()
        fovCircle.Position=UDim2.new(0,mp.X-inset.X,0,mp.Y-inset.Y)
    end
    fovCircle.Visible=Settings.Enabled and Settings.FOVEnabled
end)
local function isVisible_SA(targetCharacter)
    if not targetCharacter then return false end
    local targetHRP=targetCharacter:FindFirstChild("HumanoidRootPart"); if not targetHRP then return false end
    local localChar=LocalPlayer.Character; local localHRP=localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return false end
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances={LocalPlayer.Character,targetCharacter}
    local result=workspace:Raycast(targetHRP.Position,localHRP.Position-targetHRP.Position,params)
    return result==nil
end
local function getAdjustedMouse()
    local mp=UserInputService:GetMouseLocation(); local inset=GuiService:GetGuiInset()
    return Vector2.new(mp.X-inset.X,mp.Y-inset.Y)
end
local function isValidTarget_SA(plr)
    if not plr or plr==LocalPlayer or not plr.Character then return false end
    if Settings.IgnoreTargets and #Settings.IgnoreTargets>0 then
        for _,n in ipairs(Settings.IgnoreTargets) do if plr.Name==n then return false end end
    end
    local hum=plr.Character:FindFirstChildOfClass("Humanoid")
    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health<=0 or not hrp then return false end
    if Settings.FriendCheck and LocalPlayer:IsFriendsWith(plr.UserId) then return false end
    if Settings.TeamCheck and LocalPlayer.Team and plr.Team==LocalPlayer.Team then return false end
    if plr.Team and Settings.TargetTeams and not Settings.TargetTeams[plr.Team.Name] then return false end
    if Settings.SilentAimRange then
        local lr=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if lr and (hrp.Position-lr.Position).Magnitude>Settings.SilentAimRange then return false end
    end
    if Settings.VisibleCheck and not isVisible_SA(plr.Character) then return false end
    if Settings.ForceFieldCheck and plr.Character:FindFirstChildOfClass("ForceField") then return false end
    return true
end
local function getClosestTarget_SA()
    local localRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    local screenCenter=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local mousePos=getAdjustedMouse()
    local useMouse=not UserInputService.TouchEnabled
    local closest,shortestDist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if isValidTarget_SA(plr) then
            local part=plr.Character:FindFirstChild(Settings.TargetPart) or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local screenPos,onScreen=camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local ref=useMouse and mousePos or screenCenter
                    local d=(Vector2.new(screenPos.X,screenPos.Y)-ref).Magnitude
                    if d<=Settings.FOVRadius then
                        local wd=(part.Position-localRoot.Position).Magnitude
                        if wd<shortestDist then closest=part; shortestDist=wd end
                    end
                end
            end
        end
    end
    return closest
end
local smoothedPos=nil
local ExpectedArgs={
    FindPartOnRayWithIgnoreList={ArgCountRequired=3,Args={"Instance","Ray","table","boolean","boolean"}},
    FindPartOnRayWithWhitelist ={ArgCountRequired=3,Args={"Instance","Ray","table","boolean"}},
    FindPartOnRay              ={ArgCountRequired=2,Args={"Instance","Ray","Instance","boolean","boolean"}},
    Raycast                    ={ArgCountRequired=3,Args={"Instance","Vector3","Vector3","RaycastParams"}},
}
local function CalcChance(pct)
    return math.floor(Random.new().NextNumber(Random.new(),0,1)*100)/100 <= pct/100
end
local function ValidArgs(args,rm)
    local m=0; if #args<rm.ArgCountRequired then return false end
    for pos,arg in next,args do if typeof(arg)==rm.Args[pos] then m+=1 end end
    return m>=rm.ArgCountRequired
end
local function getSpreadDir(Origin,OrigDir,HitPart)
    if typeof(HitPart)~="Instance" or not HitPart.Parent then return OrigDir end
    local od=OrigDir.Magnitude; if od==0 then od=1000 end
    local ps=HitPart.Size
    local ro=Vector3.new((math.random()-0.5)*(ps.X+2)*0.2,(math.random()-0.5)*(ps.Y+2)*0.2,(math.random()-0.5)*(ps.Z+2)*0.2)
    if ro.Magnitude==0 then ro=Vector3.new(0.1,0.1,0.1) end
    local bp=smoothedPos or HitPart.Position
    local nd=(bp+ro)-Origin; local ndm=nd.Magnitude
    if ndm==0 then return OrigDir end
    return nd.Unit*math.max(od,ndm)
end
local function getRedirected(Origin,OrigDir)
    if currentTarget and currentTarget.Parent then return getSpreadDir(Origin,OrigDir,currentTarget) end
    return nil
end
local function isShooting(args,method,Origin,OrigDir)
    local lc=LocalPlayer.Character; if not lc then return false end
    local rl=OrigDir and OrigDir.Magnitude or 0
    if Origin and (Origin-camera.CFrame.Position).Magnitude<=2 and rl<30 then return false end
    local ign=nil
    if method=="Raycast" then local p=args[4]; if typeof(p)=="RaycastParams" then ign=p.FilterDescendantsInstances end
    elseif method=="FindPartOnRayWithIgnoreList" then if typeof(args[3])=="table" then ign=args[3] end
    elseif method=="FindPartOnRay" or method=="findPartOnRay" then
        if typeof(args[3])=="table" then ign=args[3] elseif typeof(args[4])=="table" then ign=args[4] end end
    if ign then for _,inst in next,ign do if inst==lc then return true end end end
    if Origin and (Origin-camera.CFrame.Position).Magnitude<=2 then return true end
    return false
end
local function tryGetOD(method,args)
    if method=="FindPartOnRayWithIgnoreList" or method=="FindPartOnRayWithWhitelist" or method=="FindPartOnRay" or method=="findPartOnRay" then
        local r=args[2]; if typeof(r)=="Ray" then return r.Origin,r.Direction end
    elseif method=="Raycast" then
        local ao,ad=args[2],args[3]
        if typeof(ao)=="Vector3" and typeof(ad)=="Vector3" then return ao,ad end
    end
    return nil,nil
end
local oldNamecall; oldNamecall=hookmetamethod(game,"__namecall",newcclosure(function(...)
    local method=getnamecallmethod(); local args={...}; local self=args[1]
    if self==workspace and not checkcaller() then
        local Origin,Dir=tryGetOD(method,args)
        if Origin and Dir and isShooting(args,method,Origin,Dir) then
            if Settings.Enabled and Settings.Method:lower()==method:lower() then
                if CalcChance(Settings.HitChance) then
                    if method=="FindPartOnRayWithIgnoreList" and ValidArgs(args,ExpectedArgs.FindPartOnRayWithIgnoreList) then
                        local nd=getRedirected(Origin,Dir); if nd then args[2]=Ray.new(Origin,nd) end
                    elseif method=="FindPartOnRayWithWhitelist" and ValidArgs(args,ExpectedArgs.FindPartOnRayWithWhitelist) then
                        local nd=getRedirected(Origin,Dir); if nd then args[2]=Ray.new(Origin,nd) end
                    elseif (method=="FindPartOnRay" or method=="findPartOnRay") and ValidArgs(args,ExpectedArgs.FindPartOnRay) then
                        local nd=getRedirected(Origin,Dir); if nd then args[2]=Ray.new(Origin,nd) end
                    elseif method=="Raycast" and ValidArgs(args,ExpectedArgs.Raycast) then
                        local nd=getRedirected(Origin,Dir); if nd then args[3]=nd end
                    end
                end
            end
            local rets=table.pack(oldNamecall(unpack(args))); return table.unpack(rets,1,rets.n)
        end
    end
    return oldNamecall(...)
end))
RunService.RenderStepped:Connect(function(dt)
    if Settings.Enabled and currentTarget and currentTarget.Parent then
        if not smoothedPos then smoothedPos=currentTarget.Position
        else
            local tau=Settings.Smoothing*1.5
            local alpha=tau>0.0001 and (1-math.exp(-dt/tau)) or 1
            smoothedPos=smoothedPos:Lerp(currentTarget.Position,alpha)
        end
    else smoothedPos=nil end
end)
task.spawn(function()
    while task.wait(0.1) do
        if Settings.Enabled then currentTarget=getClosestTarget_SA()
        else currentTarget=nil end
    end
end)

------------------------------------------------------------------ silent aim panel (existing + method dropdown)
local SA_W,SA_HEAD,SA_BODY=150,15,120
local SA_ROW_H,SA_GAP=16,3
local saInnerW=SA_W-12-4
SilentAimPanel=createPanel({name="MiAdminSilentAim",title="SILENT AIM",width=SA_W,headH=SA_HEAD,bodyH=SA_BODY,
    position=UDim2.fromScale(0.5,0.32),binary=CONFIG.helpBinary,onMin=function() end})
SilentAimPanel.binary.setInner(SA_BODY)
local saListGroup=create("CanvasGroup",{Name="ListGroup",Position=UDim2.fromOffset(6,SA_HEAD),
    Size=UDim2.new(1,-12,0,SA_BODY-6),BackgroundTransparency=1,ClipsDescendants=true,Parent=SilentAimPanel.Content})
local saScroll=create("ScrollingFrame",{Name="Scroll",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,Parent=saListGroup})
local saNodes={}
local function saRelayout()
    local y=0
    for _,c in ipairs(saNodes) do
        local inner=SA_GAP
        for _,row in ipairs(c.rows) do
            local h=row.dynamicH and row.dynamicH() or SA_ROW_H
            row.frame.Position=UDim2.fromOffset(4,SA_ROW_H+inner)
            row.frame.Size=UDim2.fromOffset(saInnerW-8,h)
            inner=inner+h+SA_GAP
        end
        local h=SA_ROW_H+inner*c.t.Value
        c.frame.Position=UDim2.fromOffset(0,y); c.frame.Size=UDim2.fromOffset(saInnerW,h)
        y=y+h+SA_GAP
    end
    saScroll.CanvasSize=UDim2.fromOffset(0,y)
end
local function saAddSection(title)
    local c={t=Instance.new("NumberValue"),rows={}}
    c.frame=create("Frame",{Size=UDim2.fromOffset(saInnerW,SA_ROW_H),BackgroundTransparency=1,ClipsDescendants=true,Parent=saScroll})
    local header=create("TextButton",{Size=UDim2.fromOffset(saInnerW,SA_ROW_H),BackgroundColor3=col.inputBg,BorderSizePixel=0,
        AutoButtonColor=false,Font=Enum.Font.Code,Text=title,TextSize=9,TextColor3=col.white,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=c.frame},
        {squareCorner(4),create("UIStroke",{Color=col.inputStroke,Thickness=0.6}),create("UIPadding",{PaddingLeft=UDim.new(0,6)})})
    local open=false
    header.Activated:Connect(function() open=not open; tween(c.t,0.35,{Value=open and 1 or 0},Enum.EasingStyle.Quint) end)
    c.t.Changed:Connect(saRelayout); table.insert(saNodes,c); return c
end
local function saAddCheckbox(section,label,key)
    local row={}
    row.frame=create("Frame",{Size=UDim2.fromOffset(saInnerW-8,SA_ROW_H),BackgroundTransparency=1,Parent=section.frame})
    local box=create("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.fromOffset(8,8),BackgroundColor3=col.inputBg,BorderSizePixel=0,Parent=row.frame},
        {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
    local tick=create("Frame",{Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(4,4),
        BackgroundColor3=col.green,BorderSizePixel=0,Visible=Settings[key]==true,Parent=box},{squareCorner(1)})
    local btn=create("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=row.frame})
    create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-14,1,0),BackgroundTransparency=1,
        Font=Enum.Font.Code,Text=label,TextSize=8,TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=row.frame})
    btn.Activated:Connect(function()
        Settings[key]=not Settings[key]; tick.Visible=Settings[key]==true
        if key=="Enabled" and not Settings.Enabled then currentTarget=nil; smoothedPos=nil end
    end)
    table.insert(section.rows,row)
end
local function saAddSlider(section,label,key,minV,maxV,step)
    local row={}
    row.frame=create("Frame",{Size=UDim2.fromOffset(saInnerW-8,SA_ROW_H),BackgroundTransparency=1,Parent=section.frame})
    create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-44,1,0),BackgroundTransparency=1,
        Font=Enum.Font.Code,Text=label,TextSize=8,TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=row.frame})
    local valLbl=create("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
        Size=UDim2.fromOffset(30,SA_ROW_H),BackgroundTransparency=1,Font=Enum.Font.Code,
        Text=tostring(Settings[key]),TextSize=8,TextColor3=col.white,TextXAlignment=Enum.TextXAlignment.Right,Parent=row.frame})
    local track=create("Frame",{Position=UDim2.fromOffset(0,SA_ROW_H-5),Size=UDim2.new(1,0,0,2),
        BackgroundColor3=col.inputStroke,BorderSizePixel=0,Parent=row.frame},{squareCorner(1)})
    local fill=create("Frame",{Size=UDim2.new((Settings[key]-minV)/(maxV-minV),0,1,0),BackgroundColor3=col.green,BorderSizePixel=0,Parent=track},{squareCorner(1)})
    local knob=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((Settings[key]-minV)/(maxV-minV),0,0.5,0),
        Size=UDim2.fromOffset(6,6),BackgroundColor3=col.white,BorderSizePixel=0,Parent=track},{corner(3)})
    local drag=create("TextButton",{Position=UDim2.fromOffset(0,SA_ROW_H-10),Size=UDim2.new(1,0,0,10),
        BackgroundTransparency=1,Text="",Parent=row.frame})
    local dragging=false
    local function setFromX(absX)
        local relX=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.clamp(math.floor((minV+(maxV-minV)*relX)/step+0.5)*step,minV,maxV)
        Settings[key]=v; valLbl.Text=tostring(v); local p=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
    end
    drag.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; setFromX(input.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            setFromX(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    table.insert(section.rows,row)
end
-- new: dropdown for SA panel
local function saAddDropdown(section,label,options,getValue,setValue)
    local optH=SA_ROW_H-2; local totalH=#options*optH
    local expandV=Instance.new("NumberValue"); local expanded=false
    local row={}
    row.dynamicH=function() return SA_ROW_H+totalH*expandV.Value end
    row.frame=create("Frame",{BackgroundTransparency=1,ClipsDescendants=true,Parent=section.frame})
    local hBg=create("Frame",{Size=UDim2.new(1,0,0,SA_ROW_H),BackgroundColor3=col.inputBg,BorderSizePixel=0,Parent=row.frame},
        {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
    create("TextLabel",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.fromOffset(6,0),BackgroundTransparency=1,
        Font=Enum.Font.Code,Text=label,TextSize=8,TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=hBg})
    local valLbl=create("TextLabel",{Size=UDim2.new(0.45,-8,1,0),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-4,0.5,0),BackgroundTransparency=1,Font=Enum.Font.Code,
        Text=tostring(getValue()).." ▾",TextSize=8,TextColor3=col.white,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=hBg})
    local clkArea=create("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=hBg})
    local optBtns={}
    for i,opt in ipairs(options) do
        local isSel=tostring(getValue())==tostring(opt)
        local ob=create("TextButton",{Position=UDim2.fromOffset(2,SA_ROW_H+(i-1)*optH),
            Size=UDim2.new(1,-4,0,optH-1),
            BackgroundColor3=isSel and Color3.fromRGB(20,30,20) or col.bg,
            BorderSizePixel=0,Font=Enum.Font.Code,Text=tostring(opt),TextSize=8,
            TextColor3=isSel and col.green or col.grey,TextXAlignment=Enum.TextXAlignment.Left,
            Parent=row.frame},{create("UIPadding",{PaddingLeft=UDim.new(0,8)})})
        local selBar=create("Frame",{Size=UDim2.fromOffset(2,optH-4),Position=UDim2.fromOffset(0,2),
            BackgroundColor3=col.green,BorderSizePixel=0,Visible=isSel,Parent=ob})
        optBtns[i]={btn=ob,sel=selBar,value=opt}
        ob.Activated:Connect(function()
            setValue(opt); valLbl.Text=tostring(opt).." ▾"
            for _,d in ipairs(optBtns) do
                local s=tostring(d.value)==tostring(opt)
                tween(d.btn,0.1,{BackgroundColor3=s and Color3.fromRGB(20,30,20) or col.bg})
                d.btn.TextColor3=s and col.green or col.grey; d.sel.Visible=s
            end
            expanded=false; tween(expandV,0.2,{Value=0},Enum.EasingStyle.Quint)
        end)
    end
    clkArea.Activated:Connect(function()
        expanded=not expanded; valLbl.Text=tostring(getValue())..(expanded and " ▴" or " ▾")
        tween(expandV,0.25,{Value=expanded and 1 or 0},Enum.EasingStyle.Quint)
    end)
    expandV.Changed:Connect(saRelayout); table.insert(section.rows,row); return row
end

-- build SA sections
local saMain=saAddSection("MAIN")
saAddCheckbox(saMain,"silent aim","Enabled")
saAddCheckbox(saMain,"team-only mode","TeamOnlyMode")
-- aim mode buttons (existing)
local saAMRow={}; saAMRow.frame=create("Frame",{Size=UDim2.fromOffset(saInnerW-8,SA_ROW_H),BackgroundTransparency=1,Parent=saMain.frame})
create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.fromOffset(600,SA_ROW_H),BackgroundTransparency=1,Font=Enum.Font.Code,Text="aim mode",TextSize=8,TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=saAMRow.frame})
local function mkSABtn(text,xOff)
    return create("TextButton",{Position=UDim2.fromOffset(xOff,3),Size=UDim2.fromOffset(35,10),
        BackgroundColor3=Settings.AimMode==text:upper() and col.green or col.inputBg,
        BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.Code,Text=text,TextSize=7,TextColor3=col.white,Parent=saAMRow.frame},
        {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
end
local fovBtn=mkSABtn("FOV",saInnerW-80); local distBtn=mkSABtn("DIST",saInnerW-40)
local function refreshAimMode()
    fovBtn.BackgroundColor3=Settings.AimMode=="FOV" and col.green or col.inputBg
    distBtn.BackgroundColor3=Settings.AimMode=="Distance" and col.green or col.inputBg
end
fovBtn.Activated:Connect(function() Settings.AimMode="FOV"; refreshAimMode() end)
distBtn.Activated:Connect(function() Settings.AimMode="Distance"; refreshAimMode() end)
table.insert(saMain.rows,saAMRow)
-- method dropdown (new)
local saMethodSec=saAddSection("METHOD")
saAddDropdown(saMethodSec,"raycast type",
    {"Raycast","FindPartOnRay","FindPartOnRayWithIgnoreList","FindPartOnRayWithWhitelist"},
    function() return Settings.Method end,
    function(v) Settings.Method=v end)
-- target part dropdown (new)
saAddDropdown(saMethodSec,"target part",
    {"HumanoidRootPart","Head","Torso","UpperTorso","LowerTorso","Left Arm","Right Arm","Left Leg","Right Leg","Random"},
    function() return Settings.TargetPart end,
    function(v) Settings.TargetPart=v end)
local saAcc=saAddSection("ACCURACY")
saAddSlider(saAcc,"hit chance","HitChance",0,100,1)
saAddSlider(saAcc,"aim range","SilentAimRange",50,1000,10)
saAddSlider(saAcc,"smoothing","Smoothing",0,1,0.05)
local saFov=saAddSection("FOV")
saAddCheckbox(saFov,"fov enabled","FOVEnabled")
saAddSlider(saFov,"fov radius","FOVRadius",10,500,1)
local saChecks=saAddSection("CHECKS")
saAddCheckbox(saChecks,"visible check","VisibleCheck")
saAddCheckbox(saChecks,"team check","TeamCheck")
saAddCheckbox(saChecks,"friend check","FriendCheck")
saAddCheckbox(saChecks,"forcefield check","ForceFieldCheck")
local saTeams=saAddSection("TARGET TEAMS")
local function addTeamRow(name)
    local r={}
    r.frame=create("Frame",{Size=UDim2.fromOffset(saInnerW-8,SA_ROW_H),BackgroundTransparency=1,Parent=saTeams.frame})
    local box=create("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.fromOffset(8,8),BackgroundColor3=col.inputBg,BorderSizePixel=0,Parent=r.frame},{squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
    local tick=create("Frame",{Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(4,4),BackgroundColor3=col.green,BorderSizePixel=0,Visible=Settings.TargetTeams[name]==true,Parent=box},{squareCorner(1)})
    local btn=create("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=r.frame})
    create("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-14,1,0),BackgroundTransparency=1,Font=Enum.Font.Code,Text=name,TextSize=8,TextColor3=col.grey,TextXAlignment=Enum.TextXAlignment.Left,Parent=r.frame})
    btn.Activated:Connect(function() Settings.TargetTeams[name]=not Settings.TargetTeams[name]; tick.Visible=Settings.TargetTeams[name]==true end)
    table.insert(saTeams.rows,r)
end
addTeamRow("Inmates"); addTeamRow("Guards"); addTeamRow("Criminals")
local saFilters=saAddSection("TARGET FILTERS")
saAddCheckbox(saFilters,"hostile check","HostileCheck"); saAddCheckbox(saFilters,"trespass check","TrespassCheck")
saRelayout()

------------------------------------------------------------------ ESP PANEL
local ESP_W,ESP_HEAD,ESP_BODY=160,15,165
local espInnerW=ESP_W-12-4
ESPPanel=createPanel({name="MiAdminESP",title="ESP",width=ESP_W,headH=ESP_HEAD,bodyH=ESP_BODY,
    position=UDim2.fromScale(0.28,0.45),binary=CONFIG.helpBinary,onMin=function() end})
ESPPanel.binary.setInner(ESP_BODY)
local espUI=buildPanelContent(ESPPanel,espInnerW,ESP_BODY)
local espDisp=espUI.addSection("DISPLAY")
espUI.addCheckbox(espDisp,"enable esp",function() return ESPSettings.Enabled end,function(v) ESPSettings.Enabled=v end)
espUI.addCheckbox(espDisp,"show username",function() return ESPSettings.ShowUsername end,function(v) ESPSettings.ShowUsername=v end)
espUI.addCheckbox(espDisp,"color by role",function() return ESPSettings.ColorByRole end,function(v) ESPSettings.ColorByRole=v end)
espUI.addCheckbox(espDisp,"hide teammates",function() return ESPSettings.TeamCheck end,function(v) ESPSettings.TeamCheck=v end)
espUI.addCheckbox(espDisp,"show health",function() return ESPSettings.HealthIndicator end,function(v) ESPSettings.HealthIndicator=v end)
espUI.addCheckbox(espDisp,"show distance",function() return ESPSettings.ShowDistance end,function(v) ESPSettings.ShowDistance=v end)
espUI.addCheckbox(espDisp,"show equipped",function() return ESPSettings.ShowEquipped end,function(v) ESPSettings.ShowEquipped=v end)
espUI.addSlider(espDisp,"max distance",function() return ESPSettings.MaxDistance end,function(v) ESPSettings.MaxDistance=v end,50,5000,50)
local esp2DSec=espUI.addSection("2D BOX")
espUI.addCheckbox(esp2DSec,"enable box esp",function() return ESPSettings.BoxEnabled end,function(v) ESPSettings.BoxEnabled=v end)
espUI.addCheckbox(esp2DSec,"health bar",function() return ESPSettings.HealthBarEnabled end,function(v) ESPSettings.HealthBarEnabled=v end)
espUI.addCheckbox(esp2DSec,"vertical bar",function() return ESPSettings.HealthBarVertical end,function(v) ESPSettings.HealthBarVertical=v end)
local espHLSec=espUI.addSection("HIGHLIGHT")
espUI.addCheckbox(espHLSec,"enable highlight",function() return ESPSettings.HighlightEnabled end,function(v) ESPSettings.HighlightEnabled=v end)
espUI.addSlider(espHLSec,"fill alpha",function() return ESPSettings.HighlightFillAlpha end,function(v) ESPSettings.HighlightFillAlpha=v end,0,1,0.05)
espUI.addSlider(espHLSec,"outline alpha",function() return ESPSettings.HighlightOutlineAlpha end,function(v) ESPSettings.HighlightOutlineAlpha=v end,0,1,0.05)
espUI.relayout()

------------------------------------------------------------------ HITBOX PANEL
local HB_W,HB_HEAD,HB_BODY=150,15,105
local hbInnerW=HB_W-12-4
HitboxPanel=createPanel({name="MiAdminHitbox",title="HITBOX",width=HB_W,headH=HB_HEAD,bodyH=HB_BODY,
    position=UDim2.fromScale(0.72,0.45),binary=CONFIG.helpBinary,onMin=function() end})
HitboxPanel.binary.setInner(HB_BODY)
local hbUI=buildPanelContent(HitboxPanel,hbInnerW,HB_BODY)
local hbSec=hbUI.addSection("HITBOX")
hbUI.addCheckbox(hbSec,"enable hitbox",function() return HitboxSettings.Enabled end,function(v) HitboxSettings.Enabled=v; if v then HitboxRefreshAll() else HitboxRestoreAll() end end)
hbUI.addCheckbox(hbSec,"all body parts",function() return HitboxSettings.AllParts end,function(v) HitboxSettings.AllParts=v; if HitboxSettings.Enabled then HitboxRefreshAll() end end)
hbUI.addCheckbox(hbSec,"include self",function() return HitboxSettings.IncludeSelf end,function(v) HitboxSettings.IncludeSelf=v; if HitboxSettings.Enabled then HitboxRefreshAll() end end)
hbUI.addCheckbox(hbSec,"show visualizer",function() return HitboxSettings.Visualizer end,function(v) HitboxSettings.Visualizer=v; if HitboxSettings.Enabled then HitboxRefreshAll() end end)
hbUI.addSlider(hbSec,"size",function() return HitboxSettings.Size end,function(v) HitboxSettings.Size=v; if HitboxSettings.Enabled then HitboxRefreshAll() end end,1,100,1)
hbUI.addSlider(hbSec,"transparency",function() return HitboxSettings.Transparency end,function(v) HitboxSettings.Transparency=v; if HitboxSettings.Enabled then HitboxRefreshAll() end end,0,1,0.05)
local hbAct=hbUI.addSection("ACTIONS")
hbUI.addButton(hbAct,"reapply",function() HitboxRefreshAll() end)
hbUI.addButton(hbAct,"restore all",function() HitboxRestoreAll() end)
hbUI.relayout()

------------------------------------------------------------------ NOCLIP PANEL
local NC_W,NC_HEAD,NC_BODY=150,15,90
local ncInnerW=NC_W-12-4
NoclipPanel=createPanel({name="MiAdminNoclip",title="NOCLIP",width=NC_W,headH=NC_HEAD,bodyH=NC_BODY,
    position=UDim2.fromScale(0.28,0.68),binary=CONFIG.helpBinary,onMin=function() end})
NoclipPanel.binary.setInner(NC_BODY)
local ncUI=buildPanelContent(NoclipPanel,ncInnerW,NC_BODY)
local ncSec=ncUI.addSection("NOCLIP")
ncUI.addCheckbox(ncSec,"enable noclip",function() return NoclipSettings.Enabled end,function(v)
    NoclipSettings.Enabled=v
    if v then task.spawn(function() NoclipScan(); Notify("Noclip","Done. Broken: "..Noclip.BrokenCount) end)
    else NoclipRestoreAll(); Notify("Noclip","Walls restored.") end
end)
ncUI.addCheckbox(ncSec,"include anchored",function() return NoclipSettings.IncludeAnchored end,function(v) NoclipSettings.IncludeAnchored=v end)
ncUI.addCheckbox(ncSec,"include unanchored",function() return NoclipSettings.IncludeUnanchored end,function(v) NoclipSettings.IncludeUnanchored=v end)
ncUI.addSlider(ncSec,"radius",function() return NoclipSettings.Radius end,function(v) NoclipSettings.Radius=v end,50,1000,25)
local ncAct=ncUI.addSection("ACTIONS")
ncUI.addButton(ncAct,"force rescan",function()
    if NoclipSettings.Enabled then task.spawn(function() NoclipScan(); Notify("Noclip","Done. Broken: "..Noclip.BrokenCount) end)
    else Notify("Noclip","Enable noclip first.") end
end)
ncUI.addButton(ncAct,"restore all",function() NoclipRestoreAll(); Notify("Noclip","Restored.") end)
ncUI.relayout()

------------------------------------------------------------------ HUMANOID PANEL
local HUM_W,HUM_HEAD,HUM_BODY=160,15,110
local humInnerW=HUM_W-12-4
HumanoidPanel=createPanel({name="MiAdminHumanoid",title="HUMANOID",width=HUM_W,headH=HUM_HEAD,bodyH=HUM_BODY,
    position=UDim2.fromScale(0.72,0.68),binary=CONFIG.helpBinary,onMin=function() end})
HumanoidPanel.binary.setInner(HUM_BODY)
local humUI=buildPanelContent(HumanoidPanel,humInnerW,HUM_BODY)
local humMove=humUI.addSection("MOVEMENT")
local function humApply(key,prop)
    local char=LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum[prop]=HumSettings[key] end) end
end
humUI.addSlider(humMove,"walk speed",function() return HumSettings.WalkSpeed end,function(v) HumSettings.WalkSpeed=v; humApply("WalkSpeed","WalkSpeed") end,0,500,1)
humUI.addSlider(humMove,"jump power",function() return HumSettings.JumpPower end,function(v) HumSettings.JumpPower=v; humApply("JumpPower","JumpPower") end,0,500,1)
humUI.addSlider(humMove,"jump height",function() return HumSettings.JumpHeight end,function(v) HumSettings.JumpHeight=v; humApply("JumpHeight","JumpHeight") end,0,200,0.5)
humUI.addSlider(humMove,"hip height",function() return HumSettings.HipHeight end,function(v) HumSettings.HipHeight=v; humApply("HipHeight","HipHeight") end,0,50,0.5)
local humHealth=humUI.addSection("HEALTH")
humUI.addSlider(humHealth,"max health",function() return HumSettings.MaxHealth end,function(v) HumSettings.MaxHealth=v; humApply("MaxHealth","MaxHealth") end,0,2000,1)
local humLock=humUI.addSection("LOCK (persist on spawn)")
humUI.addCheckbox(humLock,"lock walk speed",function() return HumSettings.WalkSpeedLocked end,function(v) HumSettings.WalkSpeedLocked=v end)
humUI.addCheckbox(humLock,"lock jump power",function() return HumSettings.JumpPowerLocked end,function(v) HumSettings.JumpPowerLocked=v end)
humUI.addCheckbox(humLock,"lock max health",function() return HumSettings.MaxHealthLocked end,function(v) HumSettings.MaxHealthLocked=v end)
humUI.relayout()

------------------------------------------------------------------ TELEPORT PANEL
local TP_W,TP_HEAD,TP_BODY=200,15,200
local tpInnerW=TP_W-12-4
TeleportPanel=createPanel({name="MiAdminTeleport",title="TELEPORT",width=TP_W,headH=TP_HEAD,bodyH=TP_BODY,
    position=UDim2.fromScale(0.14,0.5),binary=CONFIG.helpBinary,onMin=function() end})
TeleportPanel.binary.setInner(TP_BODY)
local tpUI=buildPanelContent(TeleportPanel,tpInnerW,TP_BODY)
local tpPresets=tpUI.addSection("PRESETS",true)
for _,loc in ipairs(TELEPORT_PRESETS) do
    tpUI.addButton(tpPresets,loc.name,function()
        TeleportTo(loc.pos)
        Notify("TP","→ "..loc.name)
    end)
end
local tpSaved=tpUI.addSection("SAVED LOCATIONS")
local savedListRow  -- defined after refresh function
local tpSaveNameInput=nil
-- save name input row
local tpSaveInputRow={}
tpSaveInputRow.frame=create("Frame",{BackgroundTransparency=1,Parent=tpSaved.frame})
local tpInput=create("TextBox",{Size=UDim2.new(0.62,0,0,14),Position=UDim2.fromOffset(0,1),
    BackgroundColor3=col.inputBg,BorderSizePixel=0,Font=Enum.Font.Code,
    PlaceholderText="name...",PlaceholderColor3=col.dim,Text="",TextSize=8,
    TextColor3=col.white,ClearTextOnFocus=false,Parent=tpSaveInputRow.frame},
    {squareCorner(2),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
local tpSaveBtn=create("TextButton",{Size=UDim2.new(0.35,0,0,14),
    Position=UDim2.new(0.65,2,0,1),BackgroundColor3=col.buttonBg,BorderSizePixel=0,
    Font=Enum.Font.Code,Text="save",TextSize=8,TextColor3=col.green,
    Parent=tpSaveInputRow.frame},
    {squareCorner(2),create("UIStroke",{Color=col.buttonStroke,Thickness=0.6})})
table.insert(tpSaved.rows,tpSaveInputRow)

-- saved locations list row
local function RefreshSavedLocationsList()
    -- rebuild dynamic row
    for _,row in ipairs(tpSaved.rows) do
        if row._isSavedList then
            -- clear and repopulate
            for _,ch in ipairs(row.frame:GetChildren()) do ch:Destroy() end
            local names={}
            for n in pairs(SavedLocations) do table.insert(names,n) end
            table.sort(names)
            local rowH=16; local gap=2
            local total=#names*(rowH+gap)
            if total==0 then total=rowH end
            row.frame.Size=UDim2.fromOffset(tpInnerW-8,total)
            row.dynamicH=function() return total end
            if #names==0 then
                create("TextLabel",{Size=UDim2.new(1,0,0,rowH),BackgroundTransparency=1,
                    Font=Enum.Font.Code,Text="no saved locations",TextSize=8,
                    TextColor3=col.dim,Parent=row.frame})
            else
                for i,name in ipairs(names) do
                    local posT=SavedLocations[name]
                    local y=(i-1)*(rowH+gap)
                    local entryF=create("Frame",{Position=UDim2.fromOffset(0,y),
                        Size=UDim2.fromOffset(tpInnerW-8,rowH),BackgroundTransparency=1,
                        Parent=row.frame})
                    create("TextLabel",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.fromOffset(0,0),
                        BackgroundTransparency=1,Font=Enum.Font.Code,Text=name,TextSize=8,
                        TextColor3=col.white,TextXAlignment=Enum.TextXAlignment.Left,Parent=entryF})
                    local goBtn=create("TextButton",{Size=UDim2.new(0.22,0,0,rowH-2),
                        Position=UDim2.new(0.56,0,0,1),BackgroundColor3=col.buttonBg,
                        BorderSizePixel=0,Font=Enum.Font.Code,Text="go",TextSize=8,
                        TextColor3=col.green,Parent=entryF},
                        {squareCorner(2),create("UIStroke",{Color=col.buttonStroke,Thickness=0.6})})
                    local delBtn=create("TextButton",{Size=UDim2.new(0.2,0,0,rowH-2),
                        Position=UDim2.new(0.79,2,0,1),BackgroundColor3=col.inputBg,
                        BorderSizePixel=0,Font=Enum.Font.Code,Text="del",TextSize=8,
                        TextColor3=col.red,Parent=entryF},
                        {squareCorner(2),create("UIStroke",{Color=col.red,Thickness=0.6})})
                    goBtn.Activated:Connect(function()
                        if posT then TeleportTo(Vector3.new(posT.X,posT.Y,posT.Z)); Notify("TP","→ "..name) end
                    end)
                    delBtn.Activated:Connect(function()
                        SavedLocations[name]=nil; SaveLocations()
                        Notify("TP","Deleted '"..name.."'"); RefreshSavedLocationsList()
                    end)
                end
            end
            tpUI.relayout(); return
        end
    end
end

-- add the saved list row dynamically
local savedListRow2={}
savedListRow2._isSavedList=true
savedListRow2.frame=create("Frame",{BackgroundTransparency=1,Parent=tpSaved.frame})
savedListRow2.dynamicH=function() return 16 end
table.insert(tpSaved.rows,savedListRow2)

tpSaveBtn.Activated:Connect(function()
    local name=tpInput.Text:gsub("^%s+",""):gsub("%s+$","")
    if name=="" then Notify("TP","Enter a name."); return end
    local pos=GetCurrentPos()
    if not pos then Notify("TP","No character."); return end
    SavedLocations[name]={X=pos.X,Y=pos.Y,Z=pos.Z}
    SaveLocations(); tpInput.Text=""
    Notify("TP","Saved '"..name.."'"); RefreshSavedLocationsList()
end)

RefreshSavedLocationsList()
tpUI.relayout()

------------------------------------------------------------------ GOTO PLAYERS PANEL
local GOTO_W,GOTO_HEAD,GOTO_BODY=170,15,160
local gotoInnerW=GOTO_W-12-4
GotoPanel=createPanel({name="MiAdminGoto",title="GO-TO PLAYERS",width=GOTO_W,headH=GOTO_HEAD,bodyH=GOTO_BODY,
    position=UDim2.fromScale(0.86,0.5),binary=CONFIG.helpBinary,onMin=function() end})
GotoPanel.binary.setInner(GOTO_BODY)
local gotoUI=buildPanelContent(GotoPanel,gotoInnerW,GOTO_BODY)

local RoleFilter={Guard=true,Inmate=true,Criminal=true,Neutral=true,Unknown=true}

-- filter row
local gotoFilterSec=gotoUI.addSection("FILTER",true)
local gotoFilterRow={}
gotoFilterRow.frame=create("Frame",{BackgroundTransparency=1,Parent=gotoFilterSec.frame})
local roleFilterBtns={}
local gotoRefreshRef=nil
local filterRoles={"Guard","Inmate","Criminal","Neutral","Unknown"}
local roleColors2={Guard=col.blue,Inmate=col.orange,Criminal=col.crimson,
    Neutral=col.neutral,Unknown=Color3.fromRGB(180,180,190)}
for i,roleName in ipairs(filterRoles) do
    local btn=create("TextButton",{
        Position=UDim2.fromOffset((i-1)*((gotoInnerW-8)/5)+1,0),
        Size=UDim2.fromOffset(math.floor((gotoInnerW-8)/5)-2,12),
        BackgroundColor3=roleColors2[roleName],
        BackgroundTransparency=RoleFilter[roleName] and 0.3 or 0.8,
        BorderSizePixel=0,Font=Enum.Font.Code,Text=roleName:sub(1,3),
        TextSize=7,TextColor3=col.white,Parent=gotoFilterRow.frame},
        {squareCorner(2)})
    btn.Activated:Connect(function()
        RoleFilter[roleName]=not RoleFilter[roleName]
        btn.BackgroundTransparency=RoleFilter[roleName] and 0.3 or 0.8
        if gotoRefreshRef then pcall(gotoRefreshRef) end
    end)
    roleFilterBtns[roleName]=btn
end
table.insert(gotoFilterSec.rows,gotoFilterRow)

-- player list section
local gotoPlayersSec=gotoUI.addSection("PLAYERS",true)
local gotoListRow={}
gotoListRow.frame=create("Frame",{BackgroundTransparency=1,Parent=gotoPlayersSec.frame})
gotoListRow.dynamicH=function() return gotoListRow._h or 16 end

local function RefreshGotoList()
    for _,ch in ipairs(gotoListRow.frame:GetChildren()) do ch:Destroy() end
    local myRoot=GetMyRoot()
    local myPos=myRoot and myRoot.Position or Vector3.zero
    local groups={Guard={},Inmate={},Criminal={},Neutral={},Unknown={}}
    for _,p in ipairs(cachedPlayersList) do
        if p~=LocalPlayer and p.Parent then
            local char,root=GetCharacter(p)
            if char and root then
                local role=DetectRole(p)
                if not groups[role] then role="Unknown" end
                local dist=(root.Position-myPos).Magnitude
                table.insert(groups[role],{player=p,dist=dist})
            end
        end
    end
    local ROW=17; local GAP2=2
    local y=0; local anyVisible=false
    for _,roleName in ipairs(filterRoles) do
        if RoleFilter[roleName] then
            local list=groups[roleName]
            if list and #list>0 then
                anyVisible=true
                table.sort(list,function(a,b) return a.dist<b.dist end)
                -- role header
                local hdrF=create("Frame",{Position=UDim2.fromOffset(0,y),
                    Size=UDim2.fromOffset(gotoInnerW-8,12),BackgroundTransparency=1,
                    Parent=gotoListRow.frame})
                create("TextLabel",{Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(2,0),
                    BackgroundTransparency=1,Font=Enum.Font.Code,
                    Text=roleName:upper().." ("..#list..")",TextSize=8,
                    TextColor3=roleColors2[roleName],TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=hdrF})
                y=y+14
                for _,entry in ipairs(list) do
                    local p=entry.player; local dist=math.floor(entry.dist)
                    local entryF=create("Frame",{Position=UDim2.fromOffset(0,y),
                        Size=UDim2.fromOffset(gotoInnerW-8,ROW),
                        BackgroundColor3=col.inputBg,BorderSizePixel=0,
                        Parent=gotoListRow.frame},
                        {squareCorner(3),create("UIStroke",{Color=col.inputStroke,Thickness=0.6})})
                    -- color bar
                    create("Frame",{Size=UDim2.fromOffset(2,ROW-4),Position=UDim2.fromOffset(2,2),
                        BackgroundColor3=roleColors2[roleName],BorderSizePixel=0,
                        Parent=entryF},{squareCorner(1)})
                    create("TextLabel",{Size=UDim2.new(0.55,0,0,10),Position=UDim2.fromOffset(8,1),
                        BackgroundTransparency=1,Font=Enum.Font.Code,
                        Text=p.DisplayName or p.Name,TextSize=8,
                        TextColor3=roleColors2[roleName],TextXAlignment=Enum.TextXAlignment.Left,
                        Parent=entryF})
                    create("TextLabel",{Size=UDim2.new(0.55,0,0,8),Position=UDim2.fromOffset(8,9),
                        BackgroundTransparency=1,Font=Enum.Font.Code,
                        Text="@"..p.Name.."  "..dist.."st",TextSize=7,
                        TextColor3=col.dim,TextXAlignment=Enum.TextXAlignment.Left,
                        Parent=entryF})
                    local goBtn=create("TextButton",{Size=UDim2.new(0.38,0,0,ROW-4),
                        AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-2,0.5,0),
                        BackgroundColor3=roleColors2[roleName],BorderSizePixel=0,
                        Font=Enum.Font.Code,Text="GOTO",TextSize=8,
                        TextColor3=col.black,Parent=entryF},{squareCorner(2)})
                    goBtn.Activated:Connect(function()
                        local char2,root2=GetCharacter(p)
                        if char2 and root2 then
                            TeleportTo(root2.Position+Vector3.new(0,0,3))
                            Notify("GOTO","→ "..(p.DisplayName or p.Name))
                        else Notify("GOTO","No character.") end
                    end)
                    y=y+ROW+GAP2
                end
            end
        end
    end
    if not anyVisible then
        create("TextLabel",{Size=UDim2.fromOffset(gotoInnerW-8,16),
            BackgroundTransparency=1,Font=Enum.Font.Code,Text="no players found",
            TextSize=8,TextColor3=col.dim,Parent=gotoListRow.frame})
        y=16
    end
    gotoListRow._h=y
    gotoUI.relayout()
end

gotoRefreshRef=RefreshGotoList
table.insert(gotoPlayersSec.rows,gotoListRow)
gotoUI.relayout()

task.spawn(function()
    while true do
        task.wait(2)
        if GotoPanel and GotoPanel.state=="open" then pcall(RefreshGotoList) end
    end
end)

------------------------------------------------------------------ AUTO-GIVE PANEL
local AG_W,AG_HEAD,AG_BODY=150,15,55
local agInnerW=AG_W-12-4
AutoGivePanel=createPanel({name="MiAdminAutoGive",title="AUTO-GIVE",width=AG_W,headH=AG_HEAD,bodyH=AG_BODY,
    position=UDim2.fromScale(0.5,0.18),binary=CONFIG.helpBinary,onMin=function() end})
AutoGivePanel.binary.setInner(AG_BODY)
local agUI=buildPanelContent(AutoGivePanel,agInnerW,AG_BODY)
local agSec=agUI.addSection("AUTO-GIVE",true)
agUI.addCheckbox(agSec,"enable auto-give",
    function() return AGSettings.Enabled end,
    function(v) AGSettings.Enabled=v
        if v then task.spawn(function() RunAutoGive() end); Notify("Auto-Give","Enabled.") 
        else Notify("Auto-Give","Disabled.") end
    end)
agUI.addButton(agSec,"visit touchgivers now",function()
    task.spawn(function() RunAutoGive(true); Notify("Auto-Give","Visited.") end)
end)
agUI.relayout()

------------------------------------------------------------------ ARREST PANEL
local ARR_W,ARR_HEAD,ARR_BODY=170,15,175
local arrInnerW=ARR_W-12-4
ArrestPanel=createPanel({name="MiAdminArrest",title="ARREST",width=ARR_W,headH=ARR_HEAD,bodyH=ARR_BODY,
    position=UDim2.fromScale(0.5,0.75),binary=CONFIG.helpBinary,onMin=function() end})
ArrestPanel.binary.setInner(ARR_BODY)
local arrUI=buildPanelContent(ArrestPanel,arrInnerW,ARR_BODY)

local arrStatusSec=arrUI.addSection("STATUS",true)
local arrStatusRow={}
arrStatusRow.frame=create("Frame",{BackgroundTransparency=1,Parent=arrStatusSec.frame})
local arrStatusLbl=create("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,
    Font=Enum.Font.Code,Text="checking role...",TextSize=8,TextColor3=col.dim,
    TextWrapped=true,Parent=arrStatusRow.frame})
table.insert(arrStatusSec.rows,arrStatusRow)

local arrSettSec=arrUI.addSection("SETTINGS")
arrUI.addCheckbox(arrSettSec,"enable arrest",
    function() return ArrSettings.Enabled end,
    function(v) ArrSettings.Enabled=v end)
arrUI.addSlider(arrSettSec,"stick distance",
    function() return ArrSettings.StickDistance end,
    function(v) ArrSettings.StickDistance=v end,0.5,20,0.5)
arrUI.addSlider(arrSettSec,"stick height",
    function() return ArrSettings.StickHeight end,
    function(v) ArrSettings.StickHeight=v end,-5,10,0.5)
arrUI.addSlider(arrSettSec,"stick duration",
    function() return ArrSettings.StickDuration end,
    function(v) ArrSettings.StickDuration=v end,0.5,60,0.5)

local arrCrimSec=arrUI.addSection("CRIMINALS")
local arrListRow={}
arrListRow.frame=create("Frame",{BackgroundTransparency=1,Parent=arrCrimSec.frame})
arrListRow.dynamicH=function() return arrListRow._h or 16 end

local function RefreshArrestList()
    for _,ch in ipairs(arrListRow.frame:GetChildren()) do ch:Destroy() end
    local isGuard=IsLocalGuard()
    if not isGuard then
        arrStatusLbl.Text="not a guard"
        arrStatusLbl.TextColor3=col.red
        create("TextLabel",{Size=UDim2.fromOffset(arrInnerW-8,16),BackgroundTransparency=1,
            Font=Enum.Font.Code,Text="join guards to use arrest",TextSize=8,
            TextColor3=col.dim,Parent=arrListRow.frame})
        arrListRow._h=16; arrUI.relayout(); return
    end
    local hasCuffs=false
    local bp=LocalPlayer:FindFirstChild("Backpack"); local char3=LocalPlayer.Character
    if bp and bp:FindFirstChild(ArrSettings.ToolName) then hasCuffs=true end
    if char3 and char3:FindFirstChild(ArrSettings.ToolName) then hasCuffs=true end
    local criminals=GetCriminalsList()
    arrStatusLbl.Text=(hasCuffs and "✓ guard | cuffs ready | " or "⚠ no cuffs | ")..#criminals.." criminal(s)"
    arrStatusLbl.TextColor3=hasCuffs and col.green or col.orange
    local ROW=20; local GAP2=2; local y=0
    if #criminals==0 then
        create("TextLabel",{Size=UDim2.fromOffset(arrInnerW-8,16),BackgroundTransparency=1,
            Font=Enum.Font.Code,Text="no criminals",TextSize=8,TextColor3=col.dim,Parent=arrListRow.frame})
        y=16
    else
        for _,data in ipairs(criminals) do
            local p=data.player; local dist=math.floor(data.dist)
            local entryF=create("Frame",{Position=UDim2.fromOffset(0,y),
                Size=UDim2.fromOffset(arrInnerW-8,ROW),BackgroundColor3=col.inputBg,
                BorderSizePixel=0,Parent=arrListRow.frame},
                {squareCorner(3),create("UIStroke",{Color=col.crimson,Thickness=0.5})})
            create("TextLabel",{Size=UDim2.new(0.55,0,0,11),Position=UDim2.fromOffset(6,1),
                BackgroundTransparency=1,Font=Enum.Font.Code,Text=p.DisplayName or p.Name,
                TextSize=8,TextColor3=col.crimson,TextXAlignment=Enum.TextXAlignment.Left,Parent=entryF})
            create("TextLabel",{Size=UDim2.new(0.55,0,0,9),Position=UDim2.fromOffset(6,11),
                BackgroundTransparency=1,Font=Enum.Font.Code,Text=dist.." studs",
                TextSize=7,TextColor3=col.dim,TextXAlignment=Enum.TextXAlignment.Left,Parent=entryF})
            local stickBtn=create("TextButton",{Size=UDim2.new(0.38,0,0,ROW-4),
                AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-2,0.5,0),
                BackgroundColor3=Color3.fromRGB(80,20,20),BorderSizePixel=0,
                Font=Enum.Font.Code,Text="STICK",TextSize=8,TextColor3=col.red,
                Parent=entryF},{squareCorner(2),create("UIStroke",{Color=col.red,Thickness=0.5})})
            stickBtn.Activated:Connect(function()
                if not ArrSettings.Enabled then Notify("Arrest","Enable arrest first."); return end
                if not IsLocalGuard() then Notify("Arrest","Must be a guard."); return end
                if ArrestState.Running then StopArrest(ArrestState.HomeCFrame) end
                task.spawn(function() ArrestPlayer(p) end)
            end)
            y=y+ROW+GAP2
        end
    end
    arrListRow._h=y; arrUI.relayout()
end

table.insert(arrCrimSec.rows,arrListRow)
local arrActSec=arrUI.addSection("ACTIONS")
arrUI.addButton(arrActSec,"stop sticking",function() StopArrest(ArrestState.HomeCFrame); Notify("Arrest","Stopped.") end)
arrUI.addButton(arrActSec,"refresh list",function() RefreshArrestList() end)
arrUI.relayout()

task.spawn(function()
    while true do
        task.wait(2)
        if ArrestPanel and ArrestPanel.state=="open" then pcall(RefreshArrestList) end
    end
end)

------------------------------------------------------------------ TRACERS PANEL
local TR_W,TR_HEAD,TR_BODY=150,15,55
local trInnerW=TR_W-12-4
local TracersPanel=createPanel({name="MiAdminTracers",title="TRACERS",width=TR_W,headH=TR_HEAD,bodyH=TR_BODY,
    position=UDim2.fromScale(0.5,0.88),binary=CONFIG.helpBinary,onMin=function() end})
TracersPanel.binary.setInner(TR_BODY)
local trUI=buildPanelContent(TracersPanel,trInnerW,TR_BODY)
local trSec=trUI.addSection("TRACERS",true)
trUI.addCheckbox(trSec,"enable tracers",
    function() return TracerSettings.Enabled end,
    function(v) TracerSettings.Enabled=v
        if not v then for plr in pairs(tracerBeams) do RemoveTracer(plr) end end
    end)
trUI.addSlider(trSec,"thickness",
    function() return TracerSettings.Thickness end,
    function(v) TracerSettings.Thickness=v end,0.05,2,0.05)
trUI.relayout()

------------------------------------------------------------------ commands menu (existing + new commands)
local HELP_W,HELP_HEAD,HELP_BODY=155,15,65
local LIST_H=HELP_BODY-6
local ROW_H_H,GAP_H=16,3
local innerW_H=HELP_W-12-4
HelpPanel=createPanel({name="MiAdminCommands",title="COMMANDS",width=HELP_W,headH=HELP_HEAD,bodyH=HELP_BODY,
    position=UDim2.fromScale(0.5,0.14),binary=CONFIG.helpBinary,onMin=function() end})
HelpPanel.binary.setInner(HELP_BODY)
local listGroupH=create("CanvasGroup",{Name="ListGroup",Position=UDim2.fromOffset(6,HELP_HEAD),
    Size=UDim2.new(1,-12,0,LIST_H),BackgroundTransparency=1,Parent=HelpPanel.Content})
local scrollH=create("ScrollingFrame",{Name="Scroll",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,Parent=listGroupH})
local nodesH={}
local function relayoutH()
    local y=0
    for _,c in ipairs(nodesH) do
        local inner=GAP_H
        for _,n in ipairs(c.cmds) do
            local h=ROW_H_H+n.detailH*n.t.Value
            n.frame.Position=UDim2.fromOffset(4,ROW_H_H+inner)
            n.frame.Size=UDim2.fromOffset(innerW_H-8,h)
            inner=inner+h+GAP_H
        end
        local h=ROW_H_H+inner*c.t.Value
        c.frame.Position=UDim2.fromOffset(0,y); c.frame.Size=UDim2.fromOffset(innerW_H,h); y=y+h+GAP_H
    end
    scrollH.CanvasSize=UDim2.fromOffset(0,y)
end

------------------------------------------------------------------ command system
local commandList,aliasMap={},{}
local categories={"combat","esp","world","misc"}
local function defineCommand(def)
    table.insert(commandList,def); aliasMap[def.name]=def
    for _,a in ipairs(def.aliases or {}) do aliasMap[a]=def end
end
local function good(main,detail)
    local s={seg(main,col.green)}
    if detail then table.insert(s,seg(" ("..detail..")",col.grey)) end
    return true,s
end
local function bad(main,detail)
    local s={seg(main,col.red)}
    if detail then table.insert(s,seg(" ("..detail..")",col.grey)) end
    return false,s
end
local function usage(text)
    return false,{seg("usage:",col.red),seg(" "..text,col.grey)}
end

-- COMBAT
defineCommand({name="silentaim",aliases={"aim"},category="combat",
    description="toggle silent aim / open menu",usage="silentaim [on/off]",
    run=function(args)
        local arg=args[1] and args[1]:lower()
        if not arg then openPanelOnce(SilentAimPanel); return good("silent aim menu opened") end
        if arg=="on" then Settings.Enabled=true; openPanelOnce(SilentAimPanel); return good("silent aim enabled")
        elseif arg=="off" then Settings.Enabled=false; return good("silent aim disabled")
        else return usage("silentaim [on/off]") end
    end})

defineCommand({name="hitbox",category="combat",
    description="set hitbox expansion size",usage="hitbox <size>",
    run=function(args)
        local size=tonumber(args[1]); if not size then return usage("hitbox <size>") end
        HitboxSettings.Size=size; HitboxSettings.Enabled=size>0
        if HitboxSettings.Enabled then HitboxRefreshAll() else HitboxRestoreAll() end
        openPanelOnce(HitboxPanel)
        return good("hitbox",tostring(size))
    end})

defineCommand({name="tracers",category="combat",
    description="toggle tracer beams",usage="tracers <on/off>",
    run=function(args)
        local arg=args[1] and args[1]:lower()
        if not arg or (arg~="on" and arg~="off") then return usage("tracers <on/off>") end
        TracerSettings.Enabled=(arg=="on")
        if not TracerSettings.Enabled then for plr in pairs(tracerBeams) do RemoveTracer(plr) end end
        return good("tracers "..arg)
    end})

defineCommand({name="arrest",category="combat",
    description="open arrest panel",usage="arrest",
    run=function()
        openPanelOnce(ArrestPanel); return good("arrest panel opened")
    end})

-- ESP
defineCommand({name="esp",category="esp",
    description="toggle esp or open panel",usage="esp [on/off]",
    run=function(args)
        local arg=args[1] and args[1]:lower()
        if not arg then openPanelOnce(ESPPanel); return good("esp panel opened") end
        if arg=="on" then ESPSettings.Enabled=true; return good("esp enabled")
        elseif arg=="off" then ESPSettings.Enabled=false; return good("esp disabled")
        else return usage("esp [on/off]") end
    end})

-- WORLD
defineCommand({name="noclip",category="world",
    description="toggle noclip",usage="noclip [on/off]",
    run=function(args)
        local arg=args[1] and args[1]:lower()
        if not arg then
            NoclipSettings.Enabled=not NoclipSettings.Enabled
        elseif arg=="on" then NoclipSettings.Enabled=true
        elseif arg=="off" then NoclipSettings.Enabled=false
        else return usage("noclip [on/off]") end
        if NoclipSettings.Enabled then
            task.spawn(function() NoclipScan(); Notify("Noclip","Done. "..Noclip.BrokenCount.." broken.") end)
        else NoclipRestoreAll() end
        openPanelOnce(NoclipPanel)
        return good("noclip "..(NoclipSettings.Enabled and "on" or "off"))
    end})

defineCommand({name="tp",aliases={"teleport"},category="world",
    description="teleport to preset or coords",usage="tp <name|x y z>",
    run=function(args)
        if #args>=3 then
            local x,y,z=tonumber(args[1]),tonumber(args[2]),tonumber(args[3])
            if not x or not y or not z then return bad("invalid coords") end
            TeleportTo(Vector3.new(x,y,z))
            return good("teleported",string.format("%.0f %.0f %.0f",x,y,z))
        end
        local query=table.concat(args," "):lower()
        for _,loc in ipairs(TELEPORT_PRESETS) do
            if loc.name:lower():find(query) then
                TeleportTo(loc.pos); return good("teleported","→ "..loc.name)
            end
        end
        openPanelOnce(TeleportPanel); return good("teleport menu opened")
    end})

defineCommand({name="goto",aliases={"gtp"},category="world",
    description="teleport to player",usage="goto <name>",
    run=function(args)
        if not args[1] then openPanelOnce(GotoPanel); return good("goto panel opened") end
        local query=args[1]:lower()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Name:lower():find(query) then
                local char2,root2=GetCharacter(p)
                if char2 and root2 then
                    TeleportTo(root2.Position+Vector3.new(0,0,3))
                    return good("teleported","→ "..p.Name)
                end
            end
        end
        return bad("player not found",args[1])
    end})

defineCommand({name="speed",category="world",
    description="set walk speed",usage="speed <value>",
    run=function(args)
        local v=tonumber(args[1]); if not v then return usage("speed <value>") end
        HumSettings.WalkSpeed=v; HumSettings.WalkSpeedLocked=true
        local char4=LocalPlayer.Character; local hum4=char4 and char4:FindFirstChildOfClass("Humanoid")
        if hum4 then pcall(function() hum4.WalkSpeed=v end) end
        return good("speed",tostring(v))
    end})

defineCommand({name="jump",category="world",
    description="set jump power",usage="jump <value>",
    run=function(args)
        local v=tonumber(args[1]); if not v then return usage("jump <value>") end
        HumSettings.JumpPower=v; HumSettings.JumpPowerLocked=true
        local char4=LocalPlayer.Character; local hum4=char4 and char4:FindFirstChildOfClass("Humanoid")
        if hum4 then pcall(function() hum4.JumpPower=v end) end
        return good("jump power",tostring(v))
    end})

-- MISC
defineCommand({name="cmd",aliases={"cmds","commands","help"},category="misc",
    description="open commands menu",usage="cmd",
    run=function()
        openPanelOnce(HelpPanel); return good("commands menu opened")
    end})

defineCommand({name="autogive",aliases={"ag"},category="misc",
    description="toggle auto-give or open panel",usage="autogive [on/off]",
    run=function(args)
        local arg=args[1] and args[1]:lower()
        if not arg then openPanelOnce(AutoGivePanel); return good("auto-give panel opened") end
        if arg=="on" then AGSettings.Enabled=true; task.spawn(function() RunAutoGive() end); return good("auto-give enabled")
        elseif arg=="off" then AGSettings.Enabled=false; return good("auto-give disabled")
        else return usage("autogive [on/off]") end
    end})

defineCommand({name="saveconfig",category="misc",
    description="save settings and panel positions",usage="saveconfig",
    run=function()
        local ok,err=pcall(function()
            local data={}
            local settTbls={SilentAimSettings=Settings,ESPSettings=ESPSettings,
                HitboxSettings=HitboxSettings,NoclipSettings=NoclipSettings,
                HumanoidSettings=HumSettings,AutoGiveSettings=AGSettings,
                ArrestSettings=ArrSettings,TracerSettings=TracerSettings}
            for name,tbl in pairs(settTbls) do
                data[name]={}
                for k,v in pairs(tbl) do
                    if type(v)=="Color3" then data[name][k]={__Color=true,r=v.R,g=v.G,b=v.B}
                    elseif type(v)=="table" then
                        data[name][k]={}
                        for sk,sv in pairs(v) do
                            if type(sv)=="Color3" then data[name][k][sk]={__Color=true,r=sv.R,g=sv.G,b=sv.B}
                            else data[name][k][sk]=sv end
                        end
                    else data[name][k]=v end
                end
            end
            -- panel positions (UDim2 → plain table)
            local panels={
                MainPanel=MainPanel,HelpPanel=HelpPanel,SilentAimPanel=SilentAimPanel,
                ESPPanel=ESPPanel,HitboxPanel=HitboxPanel,NoclipPanel=NoclipPanel,
                HumanoidPanel=HumanoidPanel,TeleportPanel=TeleportPanel,
                GotoPanel=GotoPanel,AutoGivePanel=AutoGivePanel,
                ArrestPanel=ArrestPanel,TracersPanel=TracersPanel,
            }
            data.UI={}
            for k,p in pairs(panels) do
                if p then
                    data.UI[k]={Pos=serUDim2(p.Root.Position),Open=(p.state=="open")}
                end
            end
            writefile(CONFIG_FILE,HttpService:JSONEncode(data))
        end)
        if ok then return good("config saved") else return bad("save failed",tostring(err)) end
    end})

defineCommand({name="loadconfig",category="misc",
    description="load saved config",usage="loadconfig",
    run=function()
        local ok,err=pcall(function()
            if not isfile(CONFIG_FILE) then return end
            local decoded=HttpService:JSONDecode(readfile(CONFIG_FILE))
            if not decoded then return end
            local settTbls={SilentAimSettings=Settings,ESPSettings=ESPSettings,
                HitboxSettings=HitboxSettings,NoclipSettings=NoclipSettings,
                HumanoidSettings=HumSettings,AutoGiveSettings=AGSettings,
                ArrestSettings=ArrSettings,TracerSettings=TracerSettings}
            for name,tbl in pairs(settTbls) do
                local saved=decoded[name]
                if saved and type(saved)=="table" then
                    for k,v in pairs(saved) do
                        if type(v)=="table" then
                            if v.__Color then tbl[k]=Color3.new(v.r,v.g,v.b)
                            elseif type(tbl[k])=="table" then
                                for sk,sv in pairs(v) do
                                    if type(sv)=="table" and sv.__Color then tbl[k][sk]=Color3.new(sv.r,sv.g,sv.b)
                                    else tbl[k][sk]=sv end
                                end
                            end
                        else tbl[k]=v end
                    end
                end
            end
            if decoded.UI then
                task.delay(0.5,function()
                    local panelRefs={MainPanel=MainPanel,HelpPanel=HelpPanel,SilentAimPanel=SilentAimPanel,
                        ESPPanel=ESPPanel,HitboxPanel=HitboxPanel,NoclipPanel=NoclipPanel,
                        HumanoidPanel=HumanoidPanel,TeleportPanel=TeleportPanel,
                        GotoPanel=GotoPanel,AutoGivePanel=AutoGivePanel,
                        ArrestPanel=ArrestPanel,TracersPanel=TracersPanel}
                    for k,d in pairs(decoded.UI) do
                        local p=panelRefs[k]
                        if p then
                            local pos=desUDim2(d.Pos)
                            if pos then p.Root.Position=pos end
                            if d.Open then p.open() end
                        end
                    end
                end)
            end
        end)
        if ok then return good("config loaded") else return bad("load failed",tostring(err)) end
    end})

-- build help list
for _,catName in ipairs(categories) do
    local list={}
    for _,def in ipairs(commandList) do
        if def.category==catName then table.insert(list,def) end
    end
    if #list>0 then
        local c={t=Instance.new("NumberValue"),cmds={}}
        c.frame=create("Frame",{Size=UDim2.fromOffset(innerW_H,ROW_H_H),
            BackgroundTransparency=1,ClipsDescendants=true,Parent=scrollH})
        create("TextButton",{Size=UDim2.fromOffset(innerW_H,ROW_H_H),
            BackgroundColor3=col.inputBg,BorderSizePixel=0,AutoButtonColor=false,
            Font=Enum.Font.Code,Text=catName:upper(),TextSize=9,TextColor3=col.white,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=c.frame},
            {squareCorner(4),create("UIStroke",{Color=col.inputStroke,Thickness=0.6}),
             create("UIPadding",{PaddingLeft=UDim.new(0,6)})}).Activated:Connect(function()
                local open2=c.t.Value<0.5
                tween(c.t,0.35,{Value=open2 and 1 or 0},Enum.EasingStyle.Quint)
            end)
        for _,def in ipairs(list) do
            local cmdFrame=create("Frame",{Size=UDim2.fromOffset(innerW_H-8,ROW_H_H),
                BackgroundTransparency=1,Parent=c.frame})
            local cmdBtn=create("TextButton",{Size=UDim2.new(1,-4,1,0),
                Position=UDim2.fromOffset(4,0),BackgroundTransparency=1,
                Font=Enum.Font.Code,Text=def.name,TextSize=8,TextColor3=col.white,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=cmdFrame})
            cmdBtn.Activated:Connect(function()
                InputBox.Text=def.name; InputBox:CaptureFocus()
            end)
            hoverColor(cmdBtn,col.white,col.green)
            table.insert(c.cmds,{frame=cmdFrame,t=Instance.new("NumberValue"),detailH=20})
        end
        c.t.Changed:Connect(relayoutH); table.insert(nodesH,c)
    end
end
relayoutH()

------------------------------------------------------------------ execute
local function execute(raw)
    raw=raw:gsub("^[:;!/]","")
    local args={}; for word in raw:gmatch("%S+") do table.insert(args,word) end
    local name=table.remove(args,1)
    if not name then return bad("no command") end
    local cmd=aliasMap[name:lower()]
    if not cmd then return bad("command not found",name:lower()) end
    local okRun,a,b=pcall(cmd.run,args)
    if not okRun then return bad("command errored") end
    return a,b
end

InputBox.FocusLost:Connect(function(enterPressed)
    tween(InputFrame,0.2,{BackgroundColor3=col.inputBg})
    if not enterPressed then return end
    local text=InputBox.Text:match("^%s*(.-)%s*$")
    if text=="" then
        InputStroke.Color=col.red; MainPanel.binary.flash("bad")
    else
        local success,segs=execute(text)
        InputStroke.Color=success and col.green or col.red
        MainPanel.binary.flash(success and "good" or "bad")
        Debug.show(segs,not success)
        if success then InputBox.Text="" end
    end
    tween(InputStroke,0.6,{Color=col.inputStroke})
end)

------------------------------------------------------------------ toggle key
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe or input.KeyCode~=CONFIG.toggleKey then return end
    if MainPanel.state=="open" then MainPanel.close() else MainPanel.open() end
end)

------------------------------------------------------------------ player lifecycle
Players.PlayerAdded:Connect(function(p)
    UpdatePlayerCache()
    p.CharacterAdded:Connect(function(char)
        task.wait(0.35); if HitboxSettings.Enabled then HitboxApplyChar(char) end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    UpdatePlayerCache(); RemoveESPNametag(p); RemoveESP2D(p)
    if p.Character then HitboxRestoreChar(p.Character) end
    RemoveTracer(p); CharCache[p]=nil
end)
UpdatePlayerCache()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); CaptureHumanoid()
    task.wait(0.3)
    local char5=LocalPlayer.Character; local hum5=char5 and char5:FindFirstChildOfClass("Humanoid")
    if hum5 then
        for flagK,prop in pairs(HUM_PROPS) do
            if HumSettings[flagK.."Locked"] then
                local v=HumSettings[flagK]
                if v~=nil then pcall(function() hum5[prop]=v end) end
            end
        end
    end
    if AGSettings.Enabled then task.spawn(function() RunAutoGive() end) end
    task.wait(0.5); pcall(RefreshArrestList)
end)
if LocalPlayer.Character then
    task.spawn(function()
        task.wait(1); CaptureHumanoid()
        if AGSettings.Enabled then RunAutoGive() end
        task.wait(0.5); pcall(RefreshArrestList)
    end)
end

------------------------------------------------------------------ main loops
local lastESP=0; local lastNCScan=0; local lastNCEnforce=0; local lastHum=0
RunService.Heartbeat:Connect(function()
    local now=tick()
    if now-lastESP>=0.1 then
        lastESP=now
        if ESPSettings.Enabled then RefreshESP() end
    end
    if NoclipSettings.Enabled then
        if now-lastNCScan>=0.75 then lastNCScan=now; NoclipScan() end
        if now-lastNCEnforce>=0.2 then lastNCEnforce=now; NoclipEnforce() end
    end
    if now-lastHum>=0.1 then lastHum=now; ApplyHumanoid() end
    -- prune char cache
    for p,cache in pairs(CharCache) do
        if not p.Parent then cache.Char,cache.Root,cache.Humanoid=nil,nil,nil; CharCache[p]=nil
        elseif cache.Char and not cache.Char.Parent then cache.Char,cache.Root,cache.Humanoid=nil,nil,nil end
    end
end)
RunService.RenderStepped:Connect(function()
    UpdateESP2D()
    if TracerSettings.Enabled then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                UpdateTracer(p)
            end
        end
    else
        for p in pairs(tracerBeams) do RemoveTracer(p) end
    end
end)
-- hitbox drift correction
task.spawn(function()
    while true do task.wait(0.5)
        if HitboxSettings.Enabled then
            for _,p in ipairs(Players:GetPlayers()) do
                local char6=p.Character
                local hrp6=char6 and char6:FindFirstChild("HumanoidRootPart")
                if hrp6 and math.abs(hrp6.Size.X-HitboxSettings.Size)>0.1 then
                    HitboxApplyChar(char6)
                end
            end
        end
    end
end)

------------------------------------------------------------------ open
Debug.show({seg("MI: alive",col.green)})
MainPanel.open()
