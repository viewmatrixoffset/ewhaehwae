shared.Moon = {
    ['Conditions'] = {
        ['Wall Check'] = true,
        ['Knocked'] = true,
        ['Self Knocked'] = true,
        ['Knife Check'] = true,
    },
 
    ['Targeting'] = {
        ['Mode'] = 'Manual',
        ['Offscreen Targeting'] = false,
    },
 
    ['Shared Target'] = {
        ['Enabled'] = false,
    },
 
    ['Keybinds'] = {
        ['Silent Aim'] = 'C',
        ['Aim Assist'] = 'X',
        ['Triggerbot'] = 'V',
        ['Visual Awareness'] = 'Y',
        ['Speed'] = 'Z',
    },
 
    ['Silent Aim'] = {
        ['Enabled'] = true,
        ['Mode'] = 'Toggle',
        ['Hitpart'] = 'Closest Part',
        ['Prediction'] = {
            ['Enabled'] = true,
            ['X'] = 0,
            ['Y'] = 0,
            ['Z'] = 0,
        },
    },
 
    ['Aim Assist'] = {
        ['Enabled'] = true,
        ['Mode'] = 'Toggle',
        ['Hitpart'] = 'Closest Part',
        ['Smoothing'] = {
            ['X'] = 30,
            ['Y'] = 30,
            ['Z'] = 30,
        },
        ['Prediction'] = {
            ['Enabled'] = true,
            ['X'] = 0,
            ['Y'] = 0,
            ['Z'] = 0,
        },
    },
 
    ['Triggerbot'] = {
        ['Enabled'] = true,
        ['Mode'] = 'Hold',
        ['Delay'] = 0.01,
        ['Target Only'] = true,
        ['Specific Weapons'] = {
            ['Enabled'] = false,
            ['Weapons'] = {
                '[Double-Barrel SG]',
                '[Revolver]',
                '[TacticalShotgun]',
            },
        },
    },
 
    ['Automatic Guns'] = {
        ['Enabled'] = false,
        ['Delay'] = 0,
        ['Specific Weapons'] = {
            ['Enabled'] = false,
            ['Weapons'] = {
                '[Double-Barrel SG]',
                '[Revolver]',
                '[TacticalShotgun]',
            },
        },
    },
 
    ['FOV'] = {
        ['Enabled'] = false,
        ['Visible'] = true,
        ['Size'] = 150,
        ['Color'] = Color3.fromRGB(255, 255, 255),
    },
 
    ['Target Line'] = {
        ['Enabled'] = true,
        ['Thickness'] = 1.8,
        ['Transparency'] = 0.8,
        ['Visible'] = Color3.fromRGB(255, 85, 127),
        ['Hidden'] = Color3.fromRGB(150, 150, 150),
    },
 
    ['Spread Modification'] = {
        ['Enabled'] = false,
        ['Weapons'] = {
            ['[Double-Barrel SG]'] = 1,
            ['[TacticalShotgun]'] = 1,
        },
    },
 
    ['Hitbox Expander'] = {
        ['Enabled'] = false,
        ['Size'] = {
            ['X'] = 5,
            ['Y'] = 5,
            ['Z'] = 5,
        },
    },
 
    ['Speed Modification'] = {
        ['Enabled'] = true,
        ['Multiplier'] = 35,
        ['Anti Trip'] = false,
    },
 
    ['Visual Awareness'] = {
        ['Enabled'] = true,
        ['Color'] = Color3.fromRGB(255, 255, 255),
        ['Target Color'] = Color3.fromRGB(0, 255, 0),
    },
 
    ['Hit Visualizer'] = {
        ['Hitsound'] = {
            ['Enabled'] = true,
            ['ID'] = 'rbxassetid://6534948092',
        },
    },
 
    ['Range Enhancer'] = {
        ['Enabled'] = false,
        ['Wallbang'] = {
            ['Enabled'] = false,
        },
    },
 
    ['Rapid Fire'] = {
        ['Enabled'] = false,
    },
 
    ['Headless'] = {
        ['Enabled'] = false,
    },
 
    ['No Jump Cooldown'] = {
        ['Enabled'] = false,
    },
 
    ['Skin Changer'] = {
        ['Enabled'] = false,
        ['Skins'] = {
            ['Double-Barrel SG'] = "Galaxy",
            ['Revolver'] = "Galaxy",
            ['TacticalShotgun'] = "Galaxy",
            ['Knife'] = "GPO-Knife Prestige",
        },
    },
}

local cfg = shared.Moon
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local replicatedstorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local localplayer = players.LocalPlayer
local mouse = localplayer:GetMouse()

currenttarget = nil
silentaimactive = false
camlockactive = false
triggerenabled = false
speedenabled = false
lastvisibletarget = nil
lasttargetscan = 0
scanrate = 1 / 20
camlocksuspended = false
suspendedsource = nil
lastalwaysscan = 0
alwaystarget = nil
mouseHeld = false

rayparams = RaycastParams.new()
rayparams.FilterType = Enum.RaycastFilterType.Exclude
rayparams.IgnoreWater = true

skindata = {}
skinmodulesreq = nil
skinassets = nil
skinknives = nil
skincache = {}
savedJumpPower = 50

function buildskinchanger()
    local skinmodules = replicatedstorage:WaitForChild("SkinModules", 10)
    if skinmodules then
        local ok, result = pcall(require, skinmodules)
        if ok then skinmodulesreq = result end
    end
    skinassets = replicatedstorage:WaitForChild("SkinAssets", 10)
    if not skinmodulesreq or not skinassets then return end

    local skinmodulesobj = replicatedstorage:FindFirstChild("SkinModules")
    skinknives = skinmodulesobj and skinmodulesobj:FindFirstChild("Knives")

    local gunsounds = skinassets:FindFirstChild("GunShootSounds")
    local particlefolder = skinassets:FindFirstChild("GunHandleParticle")

    local tracerfolders = {}
    for _, folder in ipairs(skinassets:GetChildren()) do
        if folder.Name ~= "GunShootSounds" and folder.Name ~= "GunHandleParticle" then
            table.insert(tracerfolders, folder)
        end
    end

    for toolname, skins in pairs(skinmodulesreq) do
        skincache[toolname] = {}
        for skinname, info in pairs(skins) do
            local entry = {}

            if gunsounds then
                local sounds = gunsounds:FindFirstChild(toolname)
                local obj = sounds and sounds:FindFirstChild(skinname)
                if obj and obj:IsA("ValueBase") then
                    entry.soundid = tostring(obj.Value)
                end
            end

            local skinpart = info.TextureID
            if typeof(skinpart) == "Instance" then
                entry.meshclone = skinpart:Clone()
                entry.meshcframe = info.CFrame
                entry.meshisinstance = true
            else
                entry.textureid = skinpart
                entry.meshisinstance = false
            end

            if particlefolder then
                local particlesource = particlefolder:FindFirstChild(skinname)
                local pe = particlesource and particlesource:FindFirstChild("ParticleEmitter")
                if pe then
                    entry.particleclone = pe:Clone()
                end
            end

            entry.tracers = {}
            for _, folder in ipairs(tracerfolders) do
                local source = folder:FindFirstChild(skinname)
                if source then
                    for _, child in ipairs(source:GetChildren()) do
                        local effects = {}
                        for _, effect in ipairs(child:GetChildren()) do
                            if effect:IsA("Beam") or effect:IsA("Trail") or effect:IsA("ParticleEmitter") then
                                table.insert(effects, effect:Clone())
                            end
                        end
                        if #effects > 0 then
                            entry.tracers[child.Name] = effects
                        end
                    end
                end
            end

            skincache[toolname][skinname] = entry
        end
    end
end

task.spawn(buildskinchanger)

skintable = {
    ["Golden Age Tanto"] = {soundid = "rbxassetid://5917819099", animationid = "rbxassetid://13473404819", positionoffset = Vector3.new(0, -0.20, -1.2), rotationoffset = Vector3.new(90, 263.7, 180)},
    ["GPO-Knife"] = {soundid = "rbxassetid://4604390759", animationid = "rbxassetid://14014278925", positionoffset = Vector3.new(0.00, -0.32, -1.07), rotationoffset = Vector3.new(90, -97.4, 90)},
    ["GPO-Knife Prestige"] = {soundid = "rbxassetid://4604390759", animationid = "rbxassetid://14014278925", positionoffset = Vector3.new(0.00, -0.32, -1.07), rotationoffset = Vector3.new(90, -97.4, 90)},
    ["Heaven"] = {soundid = "rbxassetid://14489860007", animationid = "rbxassetid://14500266726", positionoffset = Vector3.new(-0.02, -0.82, 0.20), rotationoffset = Vector3.new(64.42, 3.79, 0.00)},
    ["Love Kukri"] = {soundid = "", animationid = "", positionoffset = Vector3.new(-0.14, 0.14, -1.62), rotationoffset = Vector3.new(-90.00, 180.00, -4.97), particle = true, textureid = "rbxassetid://12124159284"},
    ["Purple Dagger"] = {soundid = "rbxassetid://17822743153", animationid = "rbxassetid://17824999722", positionoffset = Vector3.new(-0.13, -0.24, -1.80), rotationoffset = Vector3.new(89.05, 96.63, 180.00)},
    ["Blue Dagger"] = {soundid = "rbxassetid://17822737046", animationid = "rbxassetid://17824995184", positionoffset = Vector3.new(-0.13, -0.24, -1.80), rotationoffset = Vector3.new(89.05, 96.63, 180.00)},
    ["Green Dagger"] = {soundid = "rbxassetid://17822741762", animationid = "rbxassetid://17825004320", positionoffset = Vector3.new(-0.13, -0.24, -1.07), rotationoffset = Vector3.new(89.05, 96.63, 180.00)},
    ["Red Dagger"] = {soundid = "rbxassetid://17822952417", animationid = "rbxassetid://17825008844", positionoffset = Vector3.new(-0.13, -0.24, -1.07), rotationoffset = Vector3.new(89.05, 96.63, 180.00)},
    ["Portal"] = {soundid = "rbxassetid://16058846352", animationid = "rbxassetid://16058633881", positionoffset = Vector3.new(-0.13, -0.35, -0.57), rotationoffset = Vector3.new(89.05, 96.63, 180.00)},
    ["Emerald Butterfly"] = {soundid = "rbxassetid://14931902491", animationid = "rbxassetid://14918231706", positionoffset = Vector3.new(-0.02, -0.30, -0.65), rotationoffset = Vector3.new(180.00, 90.95, 180.00)},
    ["Boy"] = {soundid = "rbxassetid://18765078331", animationid = "rbxassetid://18789158908", positionoffset = Vector3.new(-0.02, -0.09, -0.73), rotationoffset = Vector3.new(89.05, -88.11, 180.00)},
    ["Girl"] = {soundid = "rbxassetid://18765078331", animationid = "rbxassetid://18789162944", positionoffset = Vector3.new(-0.02, -0.16, -0.73), rotationoffset = Vector3.new(89.05, -88.11, 180.00)},
    ["Dragon"] = {soundid = "rbxassetid://14217789230", animationid = "rbxassetid://14217804400", positionoffset = Vector3.new(-0.02, -0.32, -0.98), rotationoffset = Vector3.new(89.05, 90.95, 180.00)},
    ["Void"] = {soundid = "rbxassetid://14756591763", animationid = "rbxassetid://14774699952", positionoffset = Vector3.new(-0.02, -0.22, -0.85), rotationoffset = Vector3.new(180.00, 90.95, 180.00)},
    ["Wild West"] = {soundid = "rbxassetid://16058689026", animationid = "rbxassetid://16058148839", positionoffset = Vector3.new(-0.02, -0.24, -1.15), rotationoffset = Vector3.new(-91.89, 90.95, 180.00)},
    ["Iced Out"] = {soundid = "rbxassetid://14924261405", animationid = "rbxassetid://18465353361", positionoffset = Vector3.new(0.02, -0.08, 0.99), rotationoffset = Vector3.new(180.00, -90.95, -180.00)},
    ["Reptile"] = {soundid = "rbxassetid://18765103349", animationid = "rbxassetid://18788955930", positionoffset = Vector3.new(-0.03, -0.06, -0.92), rotationoffset = Vector3.new(168.63, 90.00, -180.00)},
    ["Emerald"] = {soundid = "", animationid = "", positionoffset = Vector3.new(-0.03, -0.06, -0.92), rotationoffset = Vector3.new(168.63, 90.00, 108.00)},
    ["Ribbon"] = {soundid = "rbxassetid://130974579277249", animationid = "rbxassetid://124102609796063", positionoffset = Vector3.new(0.02, -0.25, -0.05), rotationoffset = Vector3.new(90.00, 0.00, 180.00)},
}

fovcircle = Drawing.new("Circle")
fovcircle.Thickness = 1
fovcircle.Visible = false
fovcircle.Filled = false
fovcircle.NumSides = 64
fovcircle.Transparency = 0.35
fovcircle.ZIndex = 5

targetline = Drawing.new("Line")
targetline.Visible = false
targetline.Thickness = cfg['Target Line']['Thickness']
targetline.Transparency = cfg['Target Line']['Transparency']
targetline.ZIndex = 999

espobjects = {}

function clearmesh(tool, exclude)
    local children = tool:GetChildren()
    for i = 1, #children do
        local v = children[i]
        if v:IsA("MeshPart") and v ~= exclude then
            v:Destroy()
        end
    end
end

function applygun(tool, name)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    local toolcache = skincache[tool.Name]
    if not toolcache then return end
    local entry = toolcache[name]
    if not entry then return end

    handle:SetAttribute("SkinName", name)
    tool:SetAttribute("SkinName", name)

    local orig = tool:FindFirstChildOfClass("MeshPart")
    if orig then
        clearmesh(tool, orig)
        if entry.meshisinstance then
            local clone = entry.meshclone:Clone()
            clone.Parent = tool
            clone.CFrame = orig.CFrame
            clone.Name = "CurrentSkin"
            local w = Instance.new("Weld")
            w.Part0 = clone
            w.Part1 = orig
            w.C0 = entry.meshcframe:Inverse()
            w.Parent = clone
            orig.Transparency = 1
        else
            orig.TextureID = entry.textureid
            orig.Transparency = 0
        end
        orig:SetAttribute("SkinName", name)
    end

    if entry.soundid then
        local shoot = handle:FindFirstChild("ShootSound")
        if shoot then shoot.SoundId = entry.soundid end
    end

    if entry.particleclone then
        for _, existing in ipairs(handle:GetChildren()) do
            if existing:IsA("ParticleEmitter") then existing:Destroy() end
        end
        entry.particleclone:Clone().Parent = handle
    end

    for attachname, effects in pairs(entry.tracers) do
        local dest = tool:FindFirstChild(attachname, true)
        if dest then
            for _, existing in ipairs(dest:GetChildren()) do
                if existing:IsA("Beam") or existing:IsA("Trail") or existing:IsA("ParticleEmitter") then
                    existing:Destroy()
                end
            end
            for _, effect in ipairs(effects) do
                effect:Clone().Parent = dest
            end
        end
    end

    task.delay(0.15, function()
        if not tool or not tool.Parent then return end
        handle:SetAttribute("SkinName", name)
        tool:SetAttribute("SkinName", name)
    end)
end

function cleanknife(tool)
    local data = skindata[tool]
    if data then
        if data.track then
            data.track:Stop()
            data.track:Destroy()
            data.track = nil
        end
        if data.welds then
            for _, w in ipairs(data.welds) do
                if w then w:Destroy() end
            end
        end
        if data.sounds then
            for _, s in ipairs(data.sounds) do
                if s and s.Parent then s:Destroy() end
            end
        end
    end

    local mesh = tool:FindFirstChild("Default")
    if mesh then
        local children = mesh:GetChildren()
        for i = 1, #children do
            local v = children[i]
            if v.Name == "Handle.R" or v:IsA("Model") or (v:IsA("BasePart") and v.Name ~= "Default") then
                v:Destroy()
            end
        end
        mesh.Transparency = 0
    end

    skindata[tool] = nil
end

function applyknife(char, tool, skin)
    local skincfg = skintable[skin]
    if not skincfg then return end

    local hum = char:FindFirstChild("Humanoid")
    local rhand = char:FindFirstChild("RightHand")
    if not hum or not rhand then return end

    cleanknife(tool)
    skindata[tool] = {track = nil, welds = {}, sounds = {}}
    local data = skindata[tool]

    local mesh = tool:FindFirstChild("Default")
    if not mesh then return end
    mesh.Transparency = 1

    local knives = skinknives
    if not knives then return end

    local skinmodel = knives:FindFirstChild(skin)
    if not skinmodel then return end
    local clone = skinmodel:Clone()
    clone.Name = skin

    local handr = Instance.new("Part")
    handr.Name = "Handle.R"
    handr.Transparency = 1
    handr.CanCollide = false
    handr.Anchored = false
    handr.Size = Vector3.new(0.001, 0.001, 0.001)
    handr.Massless = true
    handr.Parent = mesh

    local m6d = Instance.new("Motor6D")
    m6d.Name = "Handle.R"
    m6d.Part0 = rhand
    m6d.Part1 = handr
    m6d.Parent = rhand

    local offset = CFrame.new(skincfg.positionoffset) * CFrame.Angles(math.rad(skincfg.rotationoffset.X), math.rad(skincfg.rotationoffset.Y), math.rad(skincfg.rotationoffset.Z))

    if clone:IsA("Model") then
        if not clone.PrimaryPart then
            local children = clone:GetChildren()
            for i = 1, #children do
                local c = children[i]
                if c:IsA("BasePart") then
                    clone.PrimaryPart = c
                    break
                end
            end
        end
        if clone.PrimaryPart then
            local descendants = clone:GetDescendants()
            for i = 1, #descendants do
                local p = descendants[i]
                if p:IsA("BasePart") then
                    p.CanCollide = false
                    p.Massless = true
                    p.Anchored = false
                    local w = Instance.new("Weld")
                    w.Part0 = handr
                    w.Part1 = p
                    w.C0 = offset
                    w.C1 = p.CFrame:ToObjectSpace(clone.PrimaryPart.CFrame)
                    w.Parent = p
                    table.insert(data.welds, w)
                end
            end
        end
        clone.Parent = mesh
    elseif clone:IsA("BasePart") then
        clone.CanCollide = false
        clone.Massless = true
        clone.Anchored = false

        if clone:IsA("MeshPart") and skincfg.textureid then
            clone.TextureID = skincfg.textureid
        end

        if skincfg.particle then
            if skinassets then
                local particlefolder = skinassets:FindFirstChild("GunHandleParticle")
                if particlefolder then
                    local particlesource = particlefolder:FindFirstChild(skin)
                    if particlesource then
                        local pe = particlesource:FindFirstChild("ParticleEmitter")
                        if pe then
                            pe:Clone().Parent = clone
                        end
                    end
                end
            end
        end

        clone.Parent = mesh
        local w = Instance.new("Weld")
        w.Part0 = handr
        w.Part1 = clone
        w.C0 = offset
        w.Parent = clone
        table.insert(data.welds, w)
    end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    if skincfg.animationid and skincfg.animationid ~= "" then
        local anim = Instance.new("Animation")
        anim.AnimationId = skincfg.animationid
        local track = animator:LoadAnimation(anim)
        track.Looped = false
        track:Play()
        data.track = track
        anim:Destroy()
        track.Ended:Once(function()
            if data.track == track then
                data.track = nil
            end
            track:Destroy()
        end)
    end
    if skincfg.soundid and skincfg.soundid ~= "" then
        local snd = Instance.new("Sound")
        snd.SoundId = skincfg.soundid
        snd.Parent = workspace
        snd:Play()
        table.insert(data.sounds, snd)
        snd.Ended:Connect(function()
            snd:Destroy()
        end)
    end

    tool:SetAttribute("CurrentKnifeSkin", skin)
end

toolregistry = {}

function setuptool(tool)
    if not tool:IsA("Tool") then return end
    if toolregistry[tool] then return end
    toolregistry[tool] = true

    tool.Equipped:Connect(function()
        if not cfg['Skin Changer']['Enabled'] then return end

        local char = tool.Parent
        if char ~= localplayer.Character then return end

        local skin = cfg['Skin Changer']['Skins'][tool.Name:gsub('%[', ''):gsub('%]', '')]
        if not skin or skin == "" then return end

        if tool.Name == "[Knife]" then
            task.defer(function()
                applyknife(char, tool, skin)
            end)
        else
            task.defer(function()
                if tool and tool.Parent then
                    applygun(tool, skin)
                end
            end)
        end
    end)

    tool.Unequipped:Connect(function()
        if tool.Name == "[Knife]" then
            local data = skindata[tool]
            if not data then return end
            if data.welds then
                for _, w in ipairs(data.welds) do
                    if w then w:Destroy() end
                end
                data.welds = {}
            end
            if data.sounds then
                for _, s in ipairs(data.sounds) do
                    if s and s.Parent then s:Destroy() end
                end
                data.sounds = {}
            end
            local mesh = tool:FindFirstChild("Default")
            if mesh then
                local children = mesh:GetChildren()
                for i = 1, #children do
                    local v = children[i]
                    if v.Name == "Handle.R" or v:IsA("Model") or (v:IsA("MeshPart") and v.Name ~= "Default") then
                        v:Destroy()
                    end
                end
                mesh.Transparency = 0
            end
        end
    end)

    if tool.Parent == localplayer.Character then
        if not cfg['Skin Changer']['Enabled'] then return end

        local skin = cfg['Skin Changer']['Skins'][tool.Name:gsub('%[', ''):gsub('%]', '')]
        if skin and skin ~= "" then
            if tool.Name == "[Knife]" then
                task.defer(function()
                    applyknife(localplayer.Character, tool, skin)
                end)
            else
                task.defer(function()
                    applygun(tool, skin)
                end)
            end
        end
    end
end

function watchchar(char)
    if not char then return end
    local children = char:GetChildren()
    for i = 1, #children do
        local v = children[i]
        if v:IsA("Tool") then
            setuptool(v)
        end
    end
    char.ChildAdded:Connect(function(v)
        if v:IsA("Tool") then
            setuptool(v)
        end
    end)
end

function holdingknife()
    if not cfg['Conditions']['Knife Check'] then return false end
    local char = localplayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool ~= nil and tool.Name == "[Knife]"
end

function playerknocked(player)
    if not cfg['Conditions']['Knocked'] then return false end
    if not player.Character then return false end
    local bodyeffects = player.Character:FindFirstChild("BodyEffects")
    if not bodyeffects then return false end
    local ko = bodyeffects:FindFirstChild("K.O")
    if ko and ko.Value == true then return true end
    local knocked = bodyeffects:FindFirstChild("Knocked")
    return knocked ~= nil and knocked.Value == true
end

function selfknocked()
    if not cfg['Conditions']['Self Knocked'] then return false end
    if not localplayer.Character then return false end
    local bodyeffects = localplayer.Character:FindFirstChild("BodyEffects")
    if not bodyeffects then return false end
    local ko = bodyeffects:FindFirstChild("K.O")
    if ko and ko.Value == true then return true end
    local knocked = bodyeffects:FindFirstChild("Knocked")
    return knocked ~= nil and knocked.Value == true
end

function cansee(part)
    if not cfg['Conditions']['Wall Check'] then return true end
    if not part or not part.Parent then return false end

    local char = part.Parent
    local origin = camera.CFrame.Position
    local dir = part.Position - origin

    rayparams.FilterDescendantsInstances = {localplayer.Character, char}

    local result = workspace:Raycast(origin, dir, rayparams)
    return result == nil or result.Instance:IsDescendantOf(char)
end

function getbodyparts(char)
    return {
        char:FindFirstChild("Head"),
        char:FindFirstChild("UpperTorso"),
        char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("LowerTorso"),
        char:FindFirstChild("LeftUpperArm"),
        char:FindFirstChild("RightUpperArm"),
        char:FindFirstChild("LeftLowerArm"),
        char:FindFirstChild("RightLowerArm"),
        char:FindFirstChild("LeftHand"),
        char:FindFirstChild("RightHand"),
        char:FindFirstChild("LeftUpperLeg"),
        char:FindFirstChild("RightUpperLeg"),
        char:FindFirstChild("LeftLowerLeg"),
        char:FindFirstChild("RightLowerLeg"),
        char:FindFirstChild("LeftFoot"),
        char:FindFirstChild("RightFoot"),
    }
end

function closestbodypart(char)
    local closestpart = nil
    local shortestdist = math.huge
    local bodyparts = getbodyparts(char)
    local mousepos = uis:GetMouseLocation()
    local mx, my = mousepos.X, mousepos.Y

    for i = 1, #bodyparts do
        local part = bodyparts[i]
        if part then
            local screenpos, onscreen = camera:WorldToViewportPoint(part.Position)
            if onscreen then
                local dx = screenpos.X - mx
                local dy = screenpos.Y - my
                local dist = dx*dx + dy*dy
                if dist < shortestdist then
                    shortestdist = dist
                    closestpart = part
                end
            end
        end
    end

    return closestpart
end

function mouseinfov(targetpart)
    local fovcfg = cfg['FOV']
    if not fovcfg['Enabled'] then return true end
    if not targetpart or not targetpart.Parent then return false end

    local hrp = targetpart.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local screenpos, onscreen = camera:WorldToViewportPoint(hrp.Position)
    if not onscreen or screenpos.Z <= 0 then return false end

    local mpos = uis:GetMouseLocation()
    local dx = screenpos.X - mpos.X
    local dy = screenpos.Y - mpos.Y
    local s = fovcfg['Size']
    return (dx*dx + dy*dy) <= (s*s)
end

function findtarget(knifecheck)
    if knifecheck and holdingknife() then return nil end

    local fovcfg = cfg['FOV']
    local fovenabled = fovcfg['Enabled']
    local besttarget = nil
    local bestdist = math.huge
    local mpos = uis:GetMouseLocation()
    local mx, my = mpos.X, mpos.Y

    local offscreen = cfg['Targeting']['Offscreen Targeting']

    for _, player in pairs(players:GetPlayers()) do
        if player == localplayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if playerknocked(player) then continue end

        local screenpos, onscreen = camera:WorldToViewportPoint(hrp.Position)
        if not offscreen and (not onscreen or screenpos.Z <= 0) then continue end

        local dx, dy
        if onscreen then
            dx = screenpos.X - mx
            dy = screenpos.Y - my
        else
            dx = math.huge
            dy = math.huge
        end

        if fovenabled then
            local s = fovcfg['Size']
            if (dx*dx + dy*dy) > (s*s) then continue end
        end

        if not cansee(hrp) then continue end

        local dist = onscreen and (dx*dx + dy*dy) or math.huge
        if dist < bestdist then
            bestdist = dist
            besttarget = hrp
        end
    end

    if besttarget then
        return closestbodypart(besttarget.Parent) or besttarget
    end

    return nil
end

function updatefov()
    local fovcfg = cfg['FOV']
    if not fovcfg['Enabled'] or not fovcfg['Visible'] then
        fovcircle.Visible = false
        return
    end

    local mpos = uis:GetMouseLocation()
    fovcircle.Position = Vector2.new(mpos.X, mpos.Y)
    fovcircle.Radius = fovcfg['Size']
    fovcircle.Color = fovcfg['Color']
    fovcircle.Visible = true
end

function updatetargetline()
    if not cfg['Target Line']['Enabled'] then
        targetline.Visible = false
        return
    end

    if not currenttarget or not currenttarget.Parent or (not silentaimactive and not camlockactive) then
        targetline.Visible = false
        return
    end

    if cfg['FOV']['Enabled'] and not mouseinfov(currenttarget) then
        targetline.Visible = false
        return
    end

    local hrp = currenttarget.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then
        targetline.Visible = false
        return
    end

    local screenpos, onscreen = camera:WorldToViewportPoint(hrp.Position)
    if not onscreen or screenpos.Z <= 0 then
        targetline.Visible = false
        return
    end

    local mpos = uis:GetMouseLocation()
    targetline.From = Vector2.new(mpos.X, mpos.Y)
    targetline.To = Vector2.new(screenpos.X, screenpos.Y)
    targetline.Thickness = cfg['Target Line']['Thickness']
    targetline.Transparency = cfg['Target Line']['Transparency']
    local targetplayer = players:GetPlayerFromCharacter(currenttarget.Parent)
    local isknocked = targetplayer and playerknocked(targetplayer)
    targetline.Color = (not isknocked and cansee(currenttarget)) and cfg['Target Line']['Visible'] or cfg['Target Line']['Hidden']
    targetline.Visible = true
end

function getcamlocktarget()
    if camlockactive and currenttarget then
        local player = players:GetPlayerFromCharacter(currenttarget.Parent)
        if player and not playerknocked(player) then
            local targetpart

            if cfg['Aim Assist']['Hitpart'] == 'Closest Part' then
                local now = tick()
                if now - lasttargetscan >= scanrate then
                    lasttargetscan = now
                    targetpart = closestbodypart(currenttarget.Parent)
                    if targetpart then
                        currenttarget = targetpart
                    end
                else
                    targetpart = currenttarget
                end
            else
                targetpart = currenttarget.Parent:FindFirstChild(cfg['Aim Assist']['Hitpart'])
            end

            if targetpart then
                if not cfg['Targeting']['Offscreen Targeting'] then
                    local screenpos, onscreen = camera:WorldToViewportPoint(targetpart.Position)
                    if not onscreen or screenpos.Z <= 0 then return nil end
                end
                if cansee(targetpart) then
                    lastvisibletarget = targetpart
                    return targetpart
                end
                return nil
            end
        else
            currenttarget = nil
            camlockactive = false
            lastvisibletarget = nil
            targetline.Visible = false
            return nil
        end
        return nil
    else
        return findtarget(true)
    end
end

function applycamlock()
    if not camlockactive then return end

    if selfknocked() then
        currenttarget = nil
        camlockactive = false
        lastvisibletarget = nil
        targetline.Visible = false
        return
    end

    if holdingknife() then return end

    if cfg['FOV']['Enabled'] and currenttarget and not mouseinfov(currenttarget) then return end

    local target = getcamlocktarget()

    if target then
        local targetpos
        if cfg['Aim Assist']['Prediction']['Enabled'] then
            local vel = target.Velocity
            local pred = cfg['Aim Assist']['Prediction']
            targetpos = target.Position + Vector3.new(vel.X * pred['X'], vel.Y * pred['Y'], vel.Z * pred['Z'])
        else
            targetpos = target.Position
        end
        local camcf = camera.CFrame
        local targetcf = CFrame.new(camcf.Position, targetpos)
        local smooth = cfg['Aim Assist']['Smoothing']
        local bx = 1 / smooth['X']
        local by = 1 / smooth['Y']
        local bz = 1 / smooth['Z']
        local avgb = (bx + by + bz) / 3
        camera.CFrame = camcf:Lerp(targetcf, avgb)
    else
        if lastvisibletarget then
            local player = players:GetPlayerFromCharacter(lastvisibletarget.Parent)
            if player and not playerknocked(player) then
                if cansee(lastvisibletarget) then
                    currenttarget = lastvisibletarget
                end
            end
        end
    end
end

triggerconnection = nil

function stoptriggerloop()
    if triggerconnection then
        triggerconnection:Disconnect()
        triggerconnection = nil
    end
end

function starttriggerloop()
    stoptriggerloop()

    local running = true
    triggerconnection = {Disconnect = function() running = false end}

    task.spawn(function()
        while running do
            task.wait(cfg['Triggerbot']['Delay'])
            if not running then break end
            if not cfg['Triggerbot']['Enabled'] or not triggerenabled then continue end
            if holdingknife() then continue end
            if cfg['Triggerbot']['Target Only'] and not currenttarget then continue end

            if currenttarget then
                local char = currenttarget.Parent
                if not char then continue end
                local player = players:GetPlayerFromCharacter(char)
                if not player then continue end
                if playerknocked(player) then continue end
                if not cansee(currenttarget) then continue end
                if cfg['FOV']['Enabled'] and not mouseinfov(currenttarget) then continue end
            end

            local tool = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Tool")
            if not tool then continue end

            if cfg['Triggerbot']['Specific Weapons']['Enabled'] then
                local valid = false
                local weapons = cfg['Triggerbot']['Specific Weapons']['Weapons']
                for i = 1, #weapons do
                    local wname = weapons[i]
                    local clean = wname:gsub("%[", ""):gsub("%]", "")
                    if tool.Name == wname or tool.Name:find(clean) then
                        valid = true
                        break
                    end
                end
                if not valid then continue end
            end

            tool:Activate()
        end
    end)
end

espgui = Instance.new("ScreenGui")
espgui.Name = "Moon"
espgui.ResetOnSpawn = false
espgui.IgnoreGuiInset = true
espgui.DisplayOrder = 999
espgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espgui.Parent = game:GetService("CoreGui")

function destroyespobject(userid)
    local obj = espobjects[userid]
    if not obj then return end
    obj.label:Destroy()
    espobjects[userid] = nil
end

function addesp(player)
    if player == localplayer then return end
    if not cfg['Visual Awareness']['Enabled'] then return end
    if espobjects[player.UserId] then return end

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 200, 0, 20)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.new(0, -999, 0, -999)
    label.Text = ""
    label.TextColor3 = cfg['Visual Awareness']['Color']
    label.TextSize = 14
    label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Visible = false
    label.ZIndex = 1000
    label.Parent = espgui

    espobjects[player.UserId] = {player = player, label = label}
end

function removeesp(player)
    destroyespobject(player.UserId)
end

function updateesp()
    if not cfg['Visual Awareness']['Enabled'] then
        for userid in pairs(espobjects) do
            destroyespobject(userid)
        end
        return
    end

    local espcfg = cfg['Visual Awareness']
    local defaultColor = espcfg['Color']
    local targetColor = espcfg['Target Color']
    local alwaysactive = cfg['Silent Aim']['Mode'] == 'Always' and cfg['Silent Aim']['Enabled']

    for userid, obj in pairs(espobjects) do
        local player = obj.player

        if not player or not player.Parent then
            destroyespobject(userid)
            continue
        end

        local char = player.Character
        if not char or not char.Parent then
            obj.label.Visible = false
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not hrp or not hum or hum.Health <= 0 then
            obj.label.Visible = false
            continue
        end

        local worldpos = hrp.Position - Vector3.new(0, 2.5, 0)
        local screenpos, onscreen = camera:WorldToViewportPoint(worldpos)

        if not onscreen or screenpos.Z <= 0 then
            obj.label.Visible = false
            continue
        end

        local activetarget = alwaysactive and alwaystarget or currenttarget
        local isactive = (silentaimactive or camlockactive) or (alwaysactive and alwaystarget ~= nil)

        obj.label.Position = UDim2.fromOffset(screenpos.X, screenpos.Y + 10)
        obj.label.Text = player.DisplayName
        obj.label.TextColor3 = (activetarget and activetarget.Parent == char and isactive) and targetColor or defaultColor
        obj.label.Visible = true
    end
end

hitsound = Instance.new("Sound")
hitsound.SoundId = cfg['Hit Visualizer']['Hitsound']['ID']
hitsound.Volume = 1
hitsound.RollOffMaxDistance = 0
hitsound.Parent = workspace

hitconnections = {}

function setuphitdetection(player)
    if player == localplayer then return end

    local function connectchar(char)
        if hitconnections[player.UserId] then
            hitconnections[player.UserId] = false
        end

        local running = true
        hitconnections[player.UserId] = true

        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 5)
            if not hum then return end

            local bodyeffects = char:WaitForChild("BodyEffects", 5)
            local armor = bodyeffects and bodyeffects:FindFirstChild("Armor")

            local lasthealth = hum.Health
            local lastarmor = armor and armor.Value or 0
            local lasthittime = 0
            local trackedplayer = players:GetPlayerFromCharacter(char)

            while hitconnections[player.UserId] and char.Parent do
                task.wait()

                local health = hum.Health
                local armorval = armor and armor.Value or 0
                local tookdmg = health < lasthealth or armorval < lastarmor

                if tookdmg then
                    local now = tick()
                    if now - lasthittime >= 0.1 then
                        if currenttarget and players:GetPlayerFromCharacter(currenttarget.Parent) == trackedplayer then
                            lasthittime = now
                            local hitviz = cfg['Hit Visualizer']
                            if hitviz['Hitsound']['Enabled'] then
                                hitsound.SoundId = hitviz['Hitsound']['ID']
                                hitsound:Stop()
                                hitsound:Play()
                            end
                        end
                    end
                end

                lasthealth = health
                lastarmor = armorval
            end
        end)
    end

    if player.Character then
        task.spawn(connectchar, player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        task.spawn(connectchar, char)
    end)
end

for _, player in pairs(players:GetPlayers()) do
    setuphitdetection(player)
end

players.PlayerAdded:Connect(function(player)
    setuphitdetection(player)
end)

players.PlayerRemoving:Connect(function(player)
    hitconnections[player.UserId] = false
end)

local gun_handler = require(replicatedstorage.Modules.GunHandler)
local OriginalGetAim = gun_handler.getAim

gun_handler.getAim = function(origin, range)
    if cfg['Silent Aim']['Enabled'] and silentaimactive then
        local target = nil

        if cfg['Silent Aim']['Mode'] == 'Always' then
            target = alwaystarget
        else
            target = currenttarget
        end

        if target and target.Parent then
            local player = players:GetPlayerFromCharacter(target.Parent)
            if player and not playerknocked(player) and cansee(target) then
                local finalTarget = target
                
                if cfg['Silent Aim']['Hitpart'] == 'Closest Part' then
                    local closestPart = closestbodypart(target.Parent)
                    if closestPart then
                        finalTarget = closestPart
                        if cfg['Silent Aim']['Mode'] == 'Always' then
                            alwaystarget = closestPart
                        else
                            currenttarget = closestPart
                        end
                    end
                else
                    local specificPart = target.Parent:FindFirstChild(cfg['Silent Aim']['Hitpart'])
                    if specificPart then
                        finalTarget = specificPart
                        if cfg['Silent Aim']['Mode'] == 'Always' then
                            alwaystarget = specificPart
                        else
                            currenttarget = specificPart
                        end
                    end
                end
                
                local targetpos
                if cfg['Silent Aim']['Prediction']['Enabled'] then
                    local vel = finalTarget.Velocity
                    local pred = cfg['Silent Aim']['Prediction']
                    targetpos = finalTarget.Position + Vector3.new(vel.X * pred['X'], vel.Y * pred['Y'], vel.Z * pred['Z'])
                else
                    targetpos = finalTarget.Position
                end
                local dir = (targetpos - origin)
                return dir.Unit, math.min(dir.Magnitude, range or 200)
            end
        end
    end

    return OriginalGetAim(origin, range)
end

local oldAim
oldAim = hookfunction(gun_handler.getAim, function(hit, dist)
    if cfg['Range Enhancer']['Enabled'] then
        return oldAim(hit, 10e10)
    end
    return oldAim(hit, dist)
end)

local oldShoot
oldShoot = hookfunction(gun_handler.shoot, function(p46)
    if cfg['Range Enhancer']['Enabled'] then
        p46.Range = 10e10
    end
    return oldShoot(p46)
end)

task.spawn(function()
    if cfg['Range Enhancer']['Wallbang']['Enabled'] then
        local ok, Handler = pcall(function()
            return game:FindService("ReplicatedStorage").MainModule
        end)
        if ok and Handler then
            local ok2, Module = pcall(require, Handler)
            if ok2 and Module then
                Module.Ignored = {
                    workspace:WaitForChild("Vehicles"),
                    workspace:WaitForChild("MAP"),
                    workspace:WaitForChild("Ignored"),
                }
            end
        end
    end
end)

local MainEvent = replicatedstorage:WaitForChild("MainEvent", 10)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if cfg['Range Enhancer']['Enabled'] and self == MainEvent and method == "FireServer" and args[1] == "ShootGun" then
        local hitPos = args[3]
        local muzzlePos = args[6]

        if typeof(hitPos) == "Vector3" and typeof(muzzlePos) == "Vector3" then
            local randomBypass = math.random(15, 50)
            local direction = (hitPos - muzzlePos).Unit
            local fakeHitPos = muzzlePos + (direction * randomBypass)

            args[3] = fakeHitPos
            args[5] = fakeHitPos
        end
    end

    return oldNamecall(self, unpack(args))
end)

local oldrandom
oldrandom = hookfunction(math.random, function(...)
    local args = {...}
    if checkcaller() then
        return oldrandom(...)
    end

    if (#args == 0) or (args[1] == -0.05 and args[2] == 0.05) or (args[1] == -0.1) or (args[1] == -0.05) then
        if cfg['Spread Modification']['Enabled'] then
            local tool = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local weapons = cfg['Spread Modification']['Weapons']
                for weaponname, amount in pairs(weapons) do
                    if tool.Name == weaponname then
                        return oldrandom(...) * (amount / 100)
                    end
                end
            end
        end
    end

    return oldrandom(...)
end)

for _, player in pairs(players:GetPlayers()) do
    if player ~= localplayer then
        addesp(player)

        player.CharacterAdded:Connect(function(char)
            removeesp(player)
            char:WaitForChild("HumanoidRootPart")
            task.wait(0.1)
            addesp(player)
        end)

        player.CharacterRemoving:Connect(function()
            removeesp(player)
        end)
    end
end

players.PlayerAdded:Connect(function(player)
    if player == localplayer then return end

    player.CharacterAdded:Connect(function(char)
        removeesp(player)
        char:WaitForChild("HumanoidRootPart")
        task.wait(0.1)
        addesp(player)
    end)

    player.CharacterRemoving:Connect(function()
        removeesp(player)
    end)
end)

players.PlayerRemoving:Connect(function(player)
    removeesp(player)
end)

function applyJumpFix(hum)
    if not cfg['No Jump Cooldown']['Enabled'] then return end

    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if hum.JumpPower == 0 then
            hum.JumpPower = savedJumpPower
        else
            savedJumpPower = hum.JumpPower
        end
    end)
end

if localplayer.Character then
    watchchar(localplayer.Character)

    local humanoid = localplayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        savedJumpPower = humanoid.JumpPower
        applyJumpFix(humanoid)
    end
end

localplayer.CharacterAdded:Connect(function(char)
    speedenabled = false
    watchchar(char)

    local humanoid = char:WaitForChild("Humanoid")
    if humanoid then
        humanoid.JumpPower = savedJumpPower
        applyJumpFix(humanoid)
    end
end)

local backpacktools = localplayer.Backpack:GetChildren()
for i = 1, #backpacktools do
    local v = backpacktools[i]
    if v:IsA("Tool") then
        setuptool(v)
    end
end

localplayer.Backpack.ChildAdded:Connect(function(v)
    if v:IsA("Tool") then
        setuptool(v)
    end
end)

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not cfg['Automatic Guns']['Enabled'] then return end
        
        mouseHeld = true

        task.spawn(function()
            while mouseHeld and cfg['Automatic Guns']['Enabled'] do
                local character = localplayer.Character
                local tool = character and character:FindFirstChildOfClass("Tool")

                if tool then
                    if cfg['Automatic Guns']['Specific Weapons']['Enabled'] then
                        local valid = false
                        local weapons = cfg['Automatic Guns']['Specific Weapons']['Weapons']
                        for i = 1, #weapons do
                            local wname = weapons[i]
                            local clean = wname:gsub("%[", ""):gsub("%]", "")
                            if tool.Name == wname or tool.Name:find(clean) then
                                valid = true
                                break
                            end
                        end
                        if valid then
                            tool:Activate()
                        end
                    else
                        tool:Activate()
                    end
                end

                local delay = cfg['Automatic Guns']['Delay']
                task.wait(delay > 0 and delay or 0.05)
            end
        end)
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseHeld = false
    end
end)

uis.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Silent Aim']] then
        if cfg['Silent Aim']['Enabled'] and cfg['Silent Aim']['Mode'] ~= 'Always' then
            if cfg['Silent Aim']['Mode'] == 'Toggle' then
                if silentaimactive then
                    silentaimactive = false
                    if cfg['Shared Target']['Enabled'] then
                        camlockactive = false
                    end
                    if not camlockactive then
                        currenttarget = nil
                        lastvisibletarget = nil
                        targetline.Visible = false
                    end
                else
                    local target = findtarget(false)
                    if target then
                        currenttarget = target
                        lastvisibletarget = target
                        silentaimactive = true
                        if cfg['Shared Target']['Enabled'] then
                            camlockactive = true
                            camlocksuspended = false
                            suspendedsource = nil
                        end
                    end
                end
            elseif cfg['Silent Aim']['Mode'] == 'Hold' then
                local target = findtarget(false)
                if target then
                    currenttarget = target
                    lastvisibletarget = target
                    silentaimactive = true
                    if cfg['Shared Target']['Enabled'] then
                        camlockactive = true
                        camlocksuspended = false
                        suspendedsource = nil
                    end
                end
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Aim Assist']] then
        if cfg['Aim Assist']['Enabled'] then
            if cfg['Aim Assist']['Mode'] == 'Toggle' then
                if camlockactive then
                    camlockactive = false
                    camlocksuspended = false
                    suspendedsource = nil
                    if cfg['Shared Target']['Enabled'] then
                        silentaimactive = false
                    end
                    if not silentaimactive then
                        currenttarget = nil
                        lastvisibletarget = nil
                        targetline.Visible = false
                    end
                else
                    local target = findtarget(true)
                    if target then
                        currenttarget = target
                        lastvisibletarget = target
                        camlockactive = true
                        camlocksuspended = false
                        suspendedsource = nil
                        if cfg['Shared Target']['Enabled'] and cfg['Silent Aim']['Mode'] ~= 'Always' then
                            silentaimactive = true
                        end
                    end
                end
            elseif cfg['Aim Assist']['Mode'] == 'Hold' then
                local target = findtarget(true)
                if target then
                    currenttarget = target
                    lastvisibletarget = target
                    camlockactive = true
                    camlocksuspended = false
                    suspendedsource = nil
                    if cfg['Shared Target']['Enabled'] and cfg['Silent Aim']['Mode'] ~= 'Always' then
                        silentaimactive = true
                    end
                end
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Triggerbot']] then
        if cfg['Triggerbot']['Mode'] == 'Toggle' then
            triggerenabled = not triggerenabled
            if triggerenabled then
                starttriggerloop()
            else
                stoptriggerloop()
            end
        elseif cfg['Triggerbot']['Mode'] == 'Hold' then
            triggerenabled = true
            starttriggerloop()
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Visual Awareness']] then
        cfg['Visual Awareness']['Enabled'] = not cfg['Visual Awareness']['Enabled']
        if cfg['Visual Awareness']['Enabled'] then
            for _, player in pairs(players:GetPlayers()) do
                if player ~= localplayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    addesp(player)
                end
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Speed']] then
        if cfg['Speed Modification']['Enabled'] then
            speedenabled = not speedenabled
        end
    end
end)

uis.InputEnded:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Silent Aim']] then
        if cfg['Silent Aim']['Enabled'] and cfg['Silent Aim']['Mode'] == 'Hold' then
            silentaimactive = false
            if cfg['Shared Target']['Enabled'] then
                camlockactive = false
            end
            if not camlockactive then
                currenttarget = nil
                lastvisibletarget = nil
                targetline.Visible = false
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Aim Assist']] then
        if cfg['Aim Assist']['Enabled'] and cfg['Aim Assist']['Mode'] == 'Hold' then
            camlockactive = false
            if cfg['Shared Target']['Enabled'] then
                silentaimactive = false
            end
            if not silentaimactive then
                currenttarget = nil
                lastvisibletarget = nil
                targetline.Visible = false
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[cfg['Keybinds']['Triggerbot']] then
        if cfg['Triggerbot']['Mode'] == 'Hold' then
            triggerenabled = false
            stoptriggerloop()
        end
    end
end)

runservice.RenderStepped:Connect(function()
    if cfg['Silent Aim']['Mode'] == 'Always' and cfg['Silent Aim']['Enabled'] then
        local now = tick()
        if now - lastalwaysscan >= scanrate then
            lastalwaysscan = now
            alwaystarget = findtarget(false)
        end
        silentaimactive = alwaystarget ~= nil
    else
        alwaystarget = nil
    end

    if selfknocked() then
        currenttarget = nil
        silentaimactive = false
        camlockactive = false
        lastvisibletarget = nil
        targetline.Visible = false
    end

    if cfg['Speed Modification']['Enabled'] and speedenabled then
        local char = localplayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16 * cfg['Speed Modification']['Multiplier']
        end
        if hrp and cfg['Speed Modification']['Anti Trip'] then
            local vel = hrp.AssemblyLinearVelocity
            if vel.Y > 75 then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
            end
        end
    end

    if cfg['Hitbox Expander']['Enabled'] then
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localplayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local s = cfg['Hitbox Expander']['Size']
                    hrp.Size = Vector3.new(s['x'], s['y'], s['z'])
                    hrp.Transparency = 1
                end
            end
        end
    end

    updatefov()
    updatetargetline()
    updateesp()

    if cfg['Aim Assist']['Enabled'] or (cfg['Shared Target']['Enabled'] and camlockactive) then
        applycamlock()
    end
end)

function applyheadless(character)
    if not cfg['Headless']['Enabled'] then return end

    local head = character:WaitForChild("Head", 5)
    if not head then return end

    head.Transparency = 1

    local face = head:FindFirstChild("face")
    if face then
        face.Transparency = 1
    end
end

if localplayer.Character then
    task.spawn(function()
        applyheadless(localplayer.Character)
    end)
end

localplayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        applyheadless(char)
    end)
end)

rapidfireoriginals = {}

runservice.RenderStepped:Connect(function()
    local tool = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("GunScript") then
        if not cfg['Rapid Fire']['Enabled'] then
            if next(rapidfireoriginals) then
                for _, connection in ipairs(getconnections(tool.Activated)) do
                    local func = connection.Function
                    if func then
                        local funcInfo = debug.getinfo(func)
                        for i = 1, funcInfo.nups do
                            if rapidfireoriginals[i] then
                                debug.setupvalue(func, i, rapidfireoriginals[i])
                            end
                        end
                    end
                end
                rapidfireoriginals = {}
            end
            return
        end
        for _, connection in ipairs(getconnections(tool.Activated)) do
            local func = connection.Function
            if func then
                local funcInfo = debug.getinfo(func)
                for i = 1, funcInfo.nups do
                    local c = debug.getupvalue(func, i)
                    if type(c) == "number" then
                        if not rapidfireoriginals[i] then
                            rapidfireoriginals[i] = c
                        end
                        debug.setupvalue(func, i, 0.00000000000000000001)
                    end
                end
            end
        end
    else
        if next(rapidfireoriginals) then
            rapidfireoriginals = {}
        end
    end
end)
