local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Library:CreateWindow{
    Title = "Basketball Legends",
    SubTitle = "Vanta | BETA 1.3",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "phosphor-basketball-bold"
    },
    Dribble = Window:CreateTab{  -- Added new Dribble tab
        Title = "Dribble",
        Icon = "phosphor-shuffle-bold"
    },
    Misc = Window:CreateTab{
        Title = "Misc",
        Icon = "phosphor-faders-horizontal-bold"
    },
    Guard = Window:CreateTab{
        Title = "Guard",
        Icon = "shield"
    },
    Player = Window:CreateTab{  -- Added new Player tab
        Title = "Player",
        Icon = "user"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

local Options = Library.Options

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local visualGui = player.PlayerGui:WaitForChild("Visual")
    local shootingElement = visualGui:WaitForChild("Shooting")
    local Shoot = ReplicatedStorage.Packages.Knit.Services.ControlService.RE.Shoot

    local autoShootEnabled = false
    local visibleConn = nil
    local shootMode = "Legit"  -- Default to Legit mode

    local autoShootToggle = Tabs.Main:CreateToggle("AutoShootToggle", {
        Title = "Auto Time",
        Default = false
    })

    local shootModeValues = {"Legit", "Perfect"}
    local shootModeDropdown = Tabs.Main:CreateDropdown("ShootModeDropdown", {
        Title = "Shot Mode",
        Description = "Select the shooting mode",
        Values = shootModeValues,
        Default = "Legit",
        Multi = false
    })

    shootModeDropdown:OnChanged(function(value)
        shootMode = value
    end)

    local function calculateLegitTiming()
        -- Start with a base timing that's at least 0.8
        local timing = 0.8
        
        -- Check if we can find information about being guarded
        local character = player.Character
        if character then
            -- Get player position and facing direction
            local playerPosition = character:GetPivot().Position
            local playerHRP = character:FindFirstChild("HumanoidRootPart")
            local playerLookVector = playerHRP and playerHRP.CFrame.LookVector or Vector3.new(0, 0, 1)
            
            -- Advanced defensive pressure metrics
            local closestDefenderDistance = math.huge
            local defendersInFOV = 0
            local totalDefensivePressure = 0
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if otherHRP then
                        local otherPosition = otherHRP.Position
                        local distance = (playerPosition - otherPosition).Magnitude
                        
                        -- Calculate defensive pressure based on distance
                        -- Closer defenders create more pressure
                        if distance < 15 then
                            -- Update closest defender distance
                            closestDefenderDistance = math.min(closestDefenderDistance, distance)
                            
                            -- Calculate if defender is in player's field of view
                            local toDefender = (otherPosition - playerPosition).Unit
                            local dotProduct = playerLookVector:Dot(toDefender)
                            
                            -- Defenders in front of player (in FOV) create more pressure
                            local inFOV = dotProduct > 0.3 -- Roughly 70 degree cone in front
                            if inFOV then
                                defendersInFOV = defendersInFOV + 1
                            end
                            
                            -- Calculate individual defensive pressure
                            -- Pressure increases as distance decreases (inverse relationship)
                            local basePressure = 1 - (distance / 15)
                            
                            -- Defenders in FOV create more pressure
                            if inFOV then
                                basePressure = basePressure * 1.5
                            end
                            
                            -- Defenders directly in front create even more pressure
                            if dotProduct > 0.7 then -- Directly in front
                                basePressure = basePressure * 1.3
                            end
                            
                            totalDefensivePressure = totalDefensivePressure + basePressure
                        end
                    end
                end
            end
            
            -- Adjust timing based on advanced defensive metrics
            if closestDefenderDistance == math.huge then
                -- Wide open, no defenders nearby
                timing = 1.0
            else
                -- Calculate timing based on defensive pressure
                -- More pressure = lower timing
                
                -- Normalize pressure to a 0-1 scale
                local normalizedPressure = math.min(totalDefensivePressure / 2, 1)
                
                -- Map normalized pressure to timing range (0.8 to 1.0)
                -- Higher pressure = lower timing
                timing = 1.0 - (normalizedPressure * 0.2)
                
                -- Ensure timing stays within valid range
                timing = math.max(0.8, math.min(1.0, timing))
                
                -- Add some randomness to make it look more human
                -- Less randomness for higher pressure situations
                local randomFactor = (1 - normalizedPressure) * 0.03
                timing = timing + (math.random(-100, 100) / 100 * randomFactor)
                
                -- Ensure timing stays within valid range after randomness
                timing = math.max(0.8, math.min(1.0, timing))
            end
        end
        
        return timing
    end

    local function onVisibleChanged()
        if autoShootEnabled and shootingElement.Visible == true then
            task.wait(0.5)
            
            local shootPower
            if shootMode == "Perfect" then
                shootPower = 1.0  -- Always perfect timing in blatant mode
            else
                shootPower = calculateLegitTiming()  -- Use the smart formula in legit mode
            end
            
            Shoot:FireServer(shootPower)
        end
    end

    autoShootToggle:OnChanged(function(value)
        autoShootEnabled = value
        if value then
            if not visibleConn then
                visibleConn = shootingElement:GetPropertyChangedSignal("Visible"):Connect(onVisibleChanged)
            end
        else
            if visibleConn then
                visibleConn:Disconnect()
                visibleConn = nil
            end
        end
    end)
end

-- Dribble Tab Implementation
do
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    -- Configuration
    local MOVE_SPEED = 20 -- The speed at which the character will move during dribbling
    local DEFAULT_SPEED = 16 -- Default humanoid walk speed
    local isDribbleGlideEnabled = false -- Flag to enable/disable Dribble Glide

    -- Speed mapping function with quadratic interpolation
    local function getSpeedFromSlider(sliderValue)
        -- Known points: (1,5), (2,8), (3,10), (4,15), (5,20)
        local points = {
            {1, 5},
            {2, 8},
            {3, 10},
            {4, 15},
            {5, 20}
        }
        
        -- If exact match, return the exact value
        for _, point in ipairs(points) do
            if math.abs(sliderValue - point[1]) < 0.001 then
                return point[2]
            end
        end
        
        -- Find the two points to interpolate between
        local x1, y1, x2, y2
        for i = 1, #points - 1 do
            if sliderValue >= points[i][1] and sliderValue <= points[i + 1][1] then
                x1, y1 = points[i][1], points[i][2]
                x2, y2 = points[i + 1][1], points[i + 1][2]
                break
            end
        end
        
        -- If outside range, clamp to nearest point
        if not x1 then
            if sliderValue < points[1][1] then
                return points[1][2]
            else
                return points[#points][2]
            end
        end
        
        -- Quadratic interpolation using three points when possible
        local x0, y0, x3, y3
        
        -- Try to get a third point for quadratic interpolation
        for i = 1, #points do
            if points[i][1] == x1 then
                -- Get previous point if available
                if i > 1 then
                    x0, y0 = points[i - 1][1], points[i - 1][2]
                end
                -- Get next next point if available
                if i < #points - 1 then
                    x3, y3 = points[i + 2][1], points[i + 2][2]
                end
                break
            end
        end
        
        -- Use quadratic interpolation if we have three points
        if x0 and y0 then
            -- Use points (x0,y0), (x1,y1), (x2,y2)
            local t = (sliderValue - x1) / (x2 - x1)
            local t0 = (x1 - x0) / (x2 - x0)
            local t2 = (x2 - x0) / (x2 - x0)
            
            -- Quadratic Lagrange interpolation
            local L0 = ((sliderValue - x1) * (sliderValue - x2)) / ((x0 - x1) * (x0 - x2))
            local L1 = ((sliderValue - x0) * (sliderValue - x2)) / ((x1 - x0) * (x1 - x2))
            local L2 = ((sliderValue - x0) * (sliderValue - x1)) / ((x2 - x0) * (x2 - x1))
            
            return y0 * L0 + y1 * L1 + y2 * L2
        elseif x3 and y3 then
            -- Use points (x1,y1), (x2,y2), (x3,y3)
            local L1 = ((sliderValue - x2) * (sliderValue - x3)) / ((x1 - x2) * (x1 - x3))
            local L2 = ((sliderValue - x1) * (sliderValue - x3)) / ((x2 - x1) * (x2 - x3))
            local L3 = ((sliderValue - x1) * (sliderValue - x2)) / ((x3 - x1) * (x3 - x2))
            
            return y1 * L1 + y2 * L2 + y3 * L3
        else
            -- Fall back to linear interpolation
            local t = (sliderValue - x1) / (x2 - x1)
            return y1 + t * (y2 - y1)
        end
    end

    -- Animation IDs Configuration
    local DRIBBLE_ANIMATION_IDS = {
        "rbxassetid://14440986901",
        "rbxassetid://14440987508",
        "rbxassetid://14440935517",
        "rbxassetid://14440936586",
        "rbxassetid://14440955808",
        "rbxassetid://14440955107",
        "rbxassetid://13959759205",
        "rbxassetid://13959759706",
        "rbxassetid://14440968811",
        "rbxassetid://14440968339"
    }

    -- Get the local player
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")
    local isDribbling = false

    -- Function to check if a dribbling animation is currently playing
    local function isPlayingDribblingAnimation()
        local tracks = animator:GetPlayingAnimationTracks()
        
        for _, track in ipairs(tracks) do
            local animationId = track.Animation.AnimationId
            
            -- Check if this animation ID is in our dribbling animations list
            for _, dribblingId in ipairs(DRIBBLE_ANIMATION_IDS) do
                if animationId == dribblingId and track.IsPlaying then
                    return true
                end
            end
        end
        
        return false
    end

    -- Connect to the RenderStepped event for smooth movement
    RunService.RenderStepped:Connect(function(deltaTime)
        -- Only process if Dribble Glide is enabled
        if not isDribbleGlideEnabled then return end
        
        -- Check if a dribbling animation is playing
        local isDribblingNow = isPlayingDribblingAnimation()
        
        -- Update dribbling state
        if isDribblingNow ~= isDribbling then
            isDribbling = isDribblingNow
            
            -- When dribbling starts, disable normal walking
            if isDribbling then
                humanoid.WalkSpeed = 0
            else
                -- When dribbling ends, restore normal walking
                humanoid.WalkSpeed = DEFAULT_SPEED
            end
        end
        
        -- Only apply custom movement during dribbling
        if isDribbling then
            -- Get the movement direction from the Humanoid
            local moveDirection = humanoid.MoveDirection
            
            -- Only apply movement if there is input
            if moveDirection.Magnitude > 0 then
                -- Normalize the direction vector
                moveDirection = moveDirection.Unit
                
                -- Move the character using CFrame
                humanoidRootPart.CFrame = humanoidRootPart.CFrame + 
                    (moveDirection * MOVE_SPEED * deltaTime)
            end
        end
    end)

    -- Handle character respawning
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        animator = humanoid:WaitForChild("Animator")
        isDribbling = false
    end)

    -- Set up animation loaded event to handle new animations
    humanoid.AnimationPlayed:Connect(function(animTrack)
        -- Only process if Dribble Glide is enabled
        if not isDribbleGlideEnabled then return end
        
        -- Check if this new animation is a dribbling animation
        local animationId = animTrack.Animation.AnimationId
        
        for _, dribblingId in ipairs(DRIBBLE_ANIMATION_IDS) do
            if animationId == dribblingId then
                -- This is a dribbling animation that just started playing
                -- The RenderStepped function will handle the state change
                break
            end
        end
    end)

    -- Toggle for Dribble Glide
    local DribbleGlideToggle = Tabs.Dribble:CreateToggle("DribbleGlideToggle", {
        Title = "Dribble Glide",
        Description = "Applys Glide To Dribble Moves",
        Default = false
    })

    DribbleGlideToggle:OnChanged(function(value)
        isDribbleGlideEnabled = value
        
        if value then
            Library:Notify{
                Title = "Dribble Glide",
                Content = "Dribble Glide feature enabled",
                Duration = 3
            }
        else
            -- When disabling, make sure to reset any active dribbling state
            if isDribbling then
                isDribbling = false
                humanoid.WalkSpeed = DEFAULT_SPEED
            end
            
            Library:Notify{
                Title = "Dribble Glide",
                Content = "Dribble Glide feature disabled",
                Duration = 3
            }
        end
    end)

    -- Slider for Move Speed
    local moveSpeedSlider = Tabs.Dribble:CreateSlider("MoveSpeedSlider", {
        Title = "Glide Boost",
        Description = "Amount of Dribble Glide Boost",
        Default = 5,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Suffix = ""
    })

    moveSpeedSlider:OnChanged(function(value)
        -- Use the custom speed mapping function
        MOVE_SPEED = getSpeedFromSlider(value)
        
        -- Provide feedback to the user
        Library:Notify{
            Title = "Move Speed",
            Content = "Speed set to " .. MOVE_SPEED .. " (slider: " .. value .. ")",
            Duration = 2
        }
    end)
end

-- Player Tab Implementation
do
    -- Variables for speed modifier
    local speedModifierEnabled = false
    local moveSpeed = 20 -- Default speed value
    local speedModifierConnection = nil
    
    -- List of animation IDs that should disable the speed boost
    local restrictedAnimationIds = {
        "14440986901",
        "14440987508", 
        "14440935517",
        "14440936586",
        "14440955808",
        "14440955107",
        "13959759205",
        "13959759706",
        "14440968811",
        "14440968339"
    }
    
    -- Function to extract ID from animation string
    local function extractAnimationId(animationId)
        if not animationId then return nil end
        
        -- Remove rbxassetid:// prefix if present
        local id = string.match(animationId, "rbxassetid://(%d+)")
        if id then
            return id
        end
        
        -- If no prefix, check if it's just numbers
        local numbersOnly = string.match(animationId, "^(%d+)$")
        if numbersOnly then
            return numbersOnly
        end
        
        return animationId
    end
    
    -- Function to check if a restricted animation is playing
    local function isRestrictedAnimationPlaying(character)
        if not character then return false end
        
        -- Check Humanoid for animations (more reliable method)
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            -- Get all playing animation tracks from humanoid
            local animator = humanoid:FindFirstChild("Animator")
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    if track.Animation and track.Animation.AnimationId then
                        local playingId = extractAnimationId(track.Animation.AnimationId)
                        
                        -- Check if this animation ID is in our restricted list
                        for _, restrictedId in ipairs(restrictedAnimationIds) do
                            if playingId == restrictedId then
                                return true
                            end
                        end
                    end
                end
            end
        end
        
        -- Also check AnimationController as backup
        local animationController = character:FindFirstChildOfClass("AnimationController")
        if animationController then
            for _, track in pairs(animationController:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId then
                    local playingId = extractAnimationId(track.Animation.AnimationId)
                    
                    -- Check if this animation ID is in our restricted list
                    for _, restrictedId in ipairs(restrictedAnimationIds) do
                        if playingId == restrictedId then
                            return true
                        end
                    end
                end
            end
        end
        
        return false
    end
    
    -- Function to check if the Shooting GUI is visible
    local function isShootingGuiVisible()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        -- Check if PlayerGui exists
        if player and player:FindFirstChild("PlayerGui") then
            -- Check if Visual folder exists
            local visual = player.PlayerGui:FindFirstChild("Visual")
            if visual then
                -- Check if Shooting element exists and is visible
                local shooting = visual:FindFirstChild("Shooting")
                if shooting and shooting.Visible == true then
                    return true
                end
            end
        end
        
        return false
    end
    
    -- Function to check if speed boost should be suspended
    local function shouldSuspendSpeedBoost(character)
        -- Check if any restricted animation is playing
        if isRestrictedAnimationPlaying(character) then
            return true
        end
        
        -- Check if Shooting GUI is visible
        if isShootingGuiVisible() then
            return true
        end
        
        return false
    end
    
    -- Function to enable/disable speed modifier
    local function toggleSpeedModifier(enabled)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer
        
        -- Disconnect existing connection if there is one
        if speedModifierConnection then
            speedModifierConnection:Disconnect()
            speedModifierConnection = nil
        end
        
        if enabled then
            -- Create a new connection for the speed modifier
            speedModifierConnection = RunService.RenderStepped:Connect(function(deltaTime)
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and humanoidRootPart then
                        -- Check if speed boost should be suspended
                        if shouldSuspendSpeedBoost(character) then
                            -- Skip speed modification if conditions for suspension are met
                            return
                        end
                        
                        -- Get the movement direction from the Humanoid
                        local moveDirection = humanoid.MoveDirection
                        
                        -- Only apply movement if there is input
                        if moveDirection.Magnitude > 0 then
                            -- Normalize the direction vector
                            moveDirection = moveDirection.Unit
                            
                            -- Move the character using CFrame
                            humanoidRootPart.CFrame = humanoidRootPart.CFrame + 
                                (moveDirection * moveSpeed * deltaTime)
                        end
                    end
                end
            end)
        end
    end
    
    -- Create a toggle for the speed modifier
    local speedToggle = Tabs.Player:CreateToggle("SpeedModifier", {
        Title = "Speed Modifier",
        Description = "Modify your movement speed using CFrame (disables during animations and shooting)",
        Default = false
    })

    speedToggle:OnChanged(function(value)
        speedModifierEnabled = value
        toggleSpeedModifier(value)
        
        if value then
            Library:Notify{
                Title = "Speed Modifier",
                Content = "Speed modifier enabled (pauses during animations and shooting)",
                Duration = 3
            }
        else
            Library:Notify{
                Title = "Speed Modifier",
                Content = "Speed modifier disabled",
                Duration = 3
            }
        end
    end)

    -- Create a slider for the speed value
    local speedSlider = Tabs.Player:CreateSlider("SpeedValue", {
        Title = "Movement Speed",
        Description = "Adjust your movement speed (when speed modifier is enabled)",
        Default = 20,
        Min = 1,
        Max = 25,
        Rounding = 1,
        Suffix = "x"
    })

    speedSlider:OnChanged(function(value)
        moveSpeed = value
        Library:Notify{
            Title = "Speed Setting",
            Content = "Movement speed set to " .. value .. "x",
            Duration = 2
        }
        
        -- Update the speed modifier if it's currently enabled
        if speedModifierEnabled then
            toggleSpeedModifier(false) -- Disconnect current connection
            toggleSpeedModifier(true)  -- Reconnect with new speed
        end
    end)
end

-- Auto Guard Feature
local autoGuardEnabled = false -- Make this a global variable for the entire script
local guardMode = 1 -- 1 = Current Logic, 2 = Advanced Humanoid MoveTo

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer

    local previousPositions = {}

    local function getPlayerModel(player)
        return Workspace:FindFirstChild(player.Name)
    end

    local autoGuardConnection = nil
    local guardingAttributeConnection = nil

    -- Moved the Auto Guard toggle from Main tab to Player tab
    local autoGuardToggle = Tabs.Guard:CreateToggle("AutoGuardToggle", {
        Title = "Auto Guard",
        Description = "Auto Guards Player",
        Default = false
    })

    autoGuardToggle:OnChanged(function(value)
        autoGuardEnabled = value
    end)

    -- New dropdown for guard mode selection
    local guardModeDropdown = Tabs.Guard:CreateDropdown("GuardModeDropdown", {
        Title = "Guard Mode",
        Description = "V1 = Perfect V2 = Works on Trash executors may have bugs",
        Values = {"V1", "V2"},
        Multi = false,
        Default = 1,
    })

    guardModeDropdown:OnChanged(function(value)
        if value == "V1" then
            guardMode = 1
        elseif value == "V2" then
            guardMode = 2
        end
    end)
end

local services = setmetatable({}, {
    __index = function(self, key)
        local service = pcall(cloneref, game:FindService(key)) and cloneref(game:GetService(key)) or Instance.new(key)
        rawset(self, key, service)
        return rawget(self, key)
    end
})

local players = services.Players
local virtualinputmanager = services.VirtualInputManager
local client = players.LocalPlayer
local runService = services.RunService

local baskets = {}; do
    for i, v in (workspace.Game:GetChildren()) do
        if v:IsA('Model') and v.Name:find('Basket') then
            table.insert(baskets, v)
        end
    end

    if (workspace.Game:FindFirstChild('Courts')) then
        for i, v in (workspace.Game.Courts:GetChildren()) do
            for i, v in (v:GetChildren()) do
                if v:IsA('Model') and v.Name:find('Basket') then
                    table.insert(baskets, v)
                end
            end
        end
    end
end

local get_char, get_root, get_hum, position_between_two_instances, get_closest_in_table; do
    get_char = function(player)
        return player.Character
    end

    get_root = function(char)
        return char and char:FindFirstChild('HumanoidRootPart')
    end

    get_hum = function(char)
        return char and char:FindFirstChildWhichIsA('Humanoid')
    end

    position_between_two_instances = function(instance, instance2, distance)
        local pivot_pos, pivot_pos2 = instance:GetPivot().Position, instance2:GetPivot().Position
        local magnitude = vector.magnitude(pivot_pos - pivot_pos2)
        return (pivot_pos):Lerp(pivot_pos2, distance / magnitude)
    end

    get_closest_in_table = function(tbl, range)
        local char = get_char(client)
        local root = get_root(char)
        local dist, closest = math.huge

        if not (char and root) then return end

        for i, v in (tbl) do
            local mag = vector.magnitude(v:GetPivot().Position - root.Position)
            if (range and mag > range) then continue end
            if (mag < dist) then
                closest = v
                dist = mag
            end
        end

        return closest, dist
    end
end

local function LerpTo(instance, target, distance)
    local position = position_between_two_instances(instance, target, distance)
    return position
end

-- Advanced mathematical position calculation for MoveTo mode
local function CalculateAdvancedPosition(playerInstance, targetInstance, distance)
    local playerPos = playerInstance:GetPivot().Position
    local targetPos = targetInstance:GetPivot().Position
    
    -- Calculate the direction vector from player to target
    local direction = (targetPos - playerPos)
    local magnitude = direction.Magnitude
    
    -- Normalize the direction vector
    local normalizedDirection = direction.Unit
    
    -- Calculate the exact position at the specified distance from player towards target
    local calculatedPosition = playerPos + (normalizedDirection * distance)
    
    return calculatedPosition
end

-- Advanced prediction system for MoveTo mode
local function PredictOptimalGuardPosition(playerWithBall, closestHoop, isPlayerJumping)
    local ballPlayerPos = playerWithBall.HumanoidRootPart.Position
    local hoopPos = closestHoop:GetPivot().Position
    
    -- Calculate the optimal distance based on jumping state (same logic as original)
    local optimalDistance = isPlayerJumping and 1 or 6
    
    -- Use advanced math to calculate the exact position
    local guardPosition = CalculateAdvancedPosition(playerWithBall.HumanoidRootPart, closestHoop, optimalDistance)
    
    return guardPosition
end

local function setupGuardingDebug()
    local char = get_char(client)
    if char then
        char:GetAttributeChangedSignal("Guarding"):Connect(function()
            local isGuarding = char:GetAttribute("Guarding")
        end)
    end

    client.CharacterAdded:Connect(function(newChar)
        newChar:GetAttributeChangedSignal("Guarding"):Connect(function()
            local isGuarding = newChar:GetAttribute("Guarding")
        end)
    end)
end

setupGuardingDebug()

local autoGuardLoop = nil
local heartbeatConnection = nil
local lastLoopTime = tick()

-- Main auto guard logic function
local function executeAutoGuardLogic()
    local success, error = pcall(function()
        local char = get_char(client)
        local root = get_root(char)
        local hum = get_hum(char)

        if not (char and root and hum) then return end

        -- Only use firetouchinterest for Current Logic mode to prevent glitching in Advanced MoveTo
        if guardMode == 1 then
            for i, v in (workspace:GetChildren()) do
                if (not v:IsA('Part') or v.Name ~= 'Basketball') then continue end
                local mag = vector.magnitude(v.Position - root.Position)
                if (mag < 6) then
                    firetouchinterest(v, root, 0)
                end
            end
        end

        local player_with_ball = (function()
            local dist, closest = math.huge
            for _, v in (players:GetPlayers()) do
                if (v == client) then continue end
                local p_char = v.Character
                local p_root = p_char and p_char:FindFirstChild('HumanoidRootPart')
                if p_root and p_char:FindFirstChild("Basketball") then
                    local distance = vector.magnitude(p_root.Position - root.Position)
                    if (distance > 25) then continue end
                    if (distance < dist) then
                        dist = distance
                        closest = p_char
                    end
                end
            end
            return closest
        end)()

        if (player_with_ball) then
            local mag = vector.magnitude(player_with_ball.HumanoidRootPart.Position - root.Position)
            
            -- Only use firetouchinterest for Current Logic mode to prevent glitching in Advanced MoveTo
            if guardMode == 1 then
                if (mag < 6 and player_with_ball:FindFirstChild('Basketball') and player_with_ball.Basketball:FindFirstChild('Attach')) then
                    firetouchinterest(player_with_ball.Basketball.Attach, root, 0)
                end
            end

            if (char:GetAttribute('Guarding')) then
                local closest_hoop, hoop_dist = get_closest_in_table(baskets)
                if (closest_hoop) then
                    local isPlayerJumping = player_with_ball.Head.Position.Y > (char.Head.Position.Y + 1)
                    
                    if (hoop_dist <= 15 and isPlayerJumping) then
                        virtualinputmanager:SendKeyEvent(true, 'Space', false, nil)
                    end

                    -- Check guard mode and apply appropriate movement method
                    if guardMode == 1 then
                        -- Current logic using WalkToPoint and lerp
                        local lerpto_position = LerpTo(player_with_ball.HumanoidRootPart, closest_hoop, isPlayerJumping and 1 or 6)
                        if vector.magnitude(lerpto_position - root.Position) > 0.2 then
                            hum.WalkToPoint = lerpto_position
                        end
                    elseif guardMode == 2 then
                        -- Advanced mode using Humanoid MoveTo without firetouchinterest to prevent glitching
                        local advanced_position = PredictOptimalGuardPosition(player_with_ball, closest_hoop, isPlayerJumping)
                        if vector.magnitude(advanced_position - root.Position) > 0.2 then
                            hum:MoveTo(advanced_position)
                        end
                    end
                end
            end
        end

        -- Update last loop time to track if loop is running
        lastLoopTime = tick()
    end)
    
    if not success then
        warn("Auto Guard Error: " .. tostring(error))
    end
end

local function startAutoGuardLoop()
    if autoGuardLoop then return end

    autoGuardLoop = task.spawn(function()
        while autoGuardEnabled do
            executeAutoGuardLogic()
            task.wait(0.1) -- Slightly longer wait to reduce load
        end
    end)
end

local function stopAutoGuardLoop()
    if autoGuardLoop then
        task.cancel(autoGuardLoop)
        autoGuardLoop = nil
    end
end

-- Heartbeat connection to monitor and restart the loop if it stops
local function setupHeartbeatMonitor()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
    heartbeatConnection = runService.Heartbeat:Connect(function()
        if autoGuardEnabled then
            -- Check if the loop has stopped running (no update in last 2 seconds)
            if tick() - lastLoopTime > 2 then
                warn("Auto Guard loop stopped, restarting...")
                stopAutoGuardLoop()
                task.wait(0.1)
                startAutoGuardLoop()
            end
        end
    end)
end

-- Character respawn handler
local function setupCharacterRespawnHandler()
    client.CharacterAdded:Connect(function(newChar)
        if autoGuardEnabled then
            task.wait(1) -- Wait for character to fully load
            stopAutoGuardLoop()
            task.wait(0.1)
            startAutoGuardLoop()
        end
    end)
end

local function setupToggleConnection()
    setupHeartbeatMonitor()
    setupCharacterRespawnHandler()
    
    if autoGuardEnabled then
        startAutoGuardLoop()
    end

    task.spawn(function()
        local lastState = autoGuardEnabled
        while task.wait(0.1) do
            if autoGuardEnabled ~= lastState then
                if autoGuardEnabled then
                    startAutoGuardLoop()
                else
                    stopAutoGuardLoop()
                end
                lastState = autoGuardEnabled
            end
        end
    end)
end

setupToggleConnection()

-- LocalScript inside StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- List of animation IDs to detect
local TARGET_ANIMATION_IDS = {
    ["rbxassetid://14440844682"] = true,
    ["rbxassetid://13904845327"] = true,
    ["rbxassetid://15239383987"] = true,
    ["rbxassetid://15239550515"] = true,
    ["rbxassetid://15239583201"] = true,
    ["rbxassetid://14440873945"] = true,
    ["rbxassetid://14440886065"] = true,
    ["rbxassetid://14023463349"] = true,
}

-- Animation modes with their IDs
local ANIMATION_MODES = {
    {name = "360 Two Hand", id = "rbxassetid://14440844682"},
    {name = "Default", id = "rbxassetid://13904845327"},
    {name = "Under Legs", id = "rbxassetid://15239383987"},
    {name = "Between The Legs", id = "rbxassetid://15239550515"},
    {name = "DoubleClutch", id = "rbxassetid://15239583201"},
    {name = "Tomahawk", id = "rbxassetid://14440873945"},
    {name = "Windmill", id = "rbxassetid://14440886065"},
    {name = "Reverse", id = "rbxassetid://14023463349"},
}

-- Default replacement animation ID (will be changed by dropdown)
local REPLACEMENT_ANIMATION_ID = ANIMATION_MODES[5].id  -- Default to Reverse (15239583201)

-- Cache for replacement animations
local replacementAnimations = {}

-- Function to update all loaded animations with the new ID
local function updateReplacementAnimations(newAnimationId)
    REPLACEMENT_ANIMATION_ID = newAnimationId
    
    -- Update all existing loaded animations
    for character, oldTrack in pairs(replacementAnimations) do
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                -- Stop the old animation
                oldTrack:Stop(0)
                
                -- Create and load the new animation
                local newAnimation = Instance.new("Animation")
                newAnimation.AnimationId = REPLACEMENT_ANIMATION_ID
                replacementAnimations[character] = animator:LoadAnimation(newAnimation)
            end
        end
    end
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    -- Create and cache the replacement animation
    local replacementAnimation = Instance.new("Animation")
    replacementAnimation.AnimationId = REPLACEMENT_ANIMATION_ID
    replacementAnimations[character] = animator:LoadAnimation(replacementAnimation)

    -- Connect to AnimationPlayed signal
    animator.AnimationPlayed:Connect(function(animationTrack)
        if animationTrack.Animation and TARGET_ANIMATION_IDS[animationTrack.Animation.AnimationId] then
            -- Stop the original animation
            animationTrack:Stop(0)

            -- Play the replacement animation
            local replacementTrack = replacementAnimations[character]
            if replacementTrack then
                replacementTrack:AdjustSpeed(animationTrack.Speed)
                replacementTrack:AdjustWeight(animationTrack.WeightCurrent)
                replacementTrack:Play(0.1)

                -- Stop replacement when original stops
                animationTrack.Stopped:Connect(function()
                    replacementTrack:Stop(0.1)
                end)
            end
        end
    end)
end

-- Handle the current character if it exists
if player.Character then
    onCharacterAdded(player.Character)
end

-- Handle future characters
player.CharacterAdded:Connect(onCharacterAdded)

-- Clean up when characters are removed
player.CharacterRemoving:Connect(function(character)
    replacementAnimations[character] = nil
end)

-- Misc Tab UI Elements
-- This assumes you have a UI library with Tabs.Misc already defined

-- Create dropdown UI for animation modes
-- Create dropdown options
local dropdownOptions = {}
for _, mode in ipairs(ANIMATION_MODES) do
    table.insert(dropdownOptions, mode.name)
end

-- Create the dropdown in the Misc tab
Tabs.Misc:CreateDropdown("AnimationModeDropdown", {
    Title = "Dunk Animation",
    Description = "Changes Dunk Animation",
    Values = dropdownOptions,
    Default = 5,  -- Default to Reverse to match the initial REPLACEMENT_ANIMATION_ID
    Multi = false,
    AllowNull = false
}):OnChanged(function(value)
    for index, modeName in ipairs(dropdownOptions) do
        if modeName == value then
            updateReplacementAnimations(ANIMATION_MODES[index].id)
            break
        end
    end
end)

-- Add a toggle to enable/disable animation replacement
Tabs.Misc:CreateToggle("AnimationReplaceToggle", {
    Title = "Dunk Animation Spoofer",
    Description = "Spoofs Dunk Animation",
    Default = true
}):OnChanged(function(value)
    _G.ReplaceAnimations = value
end)

-- Set initial value
_G.ReplaceAnimations = true

-- Show all Records/Streaks functionality
local function setBGVisibleToTrue()
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = model.HumanoidRootPart
            for _, obj in pairs(humanoidRootPart:GetDescendants()) do
                if obj:IsA("BillboardGui") and obj.Name == "Info" then
                    for _, frame in pairs(obj:GetDescendants()) do
                        if frame:IsA("Frame") and frame.Name == "BG" then
                            frame.Visible = true
                        end
                    end
                end
            end
        end
    end
end

local function setBGVisibleToFalse()
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = model.HumanoidRootPart
            for _, obj in pairs(humanoidRootPart:GetDescendants()) do
                if obj:IsA("BillboardGui") and obj.Name == "Info" then
                    for _, frame in pairs(obj:GetDescendants()) do
                        if frame:IsA("Frame") and frame.Name == "BG" then
                            frame.Visible = false
                        end
                    end
                end
            end
        end
    end
end

local bgToggle = Tabs.Misc:CreateToggle("BGVisibleToggle", {
    Title = "Show all Records/Streaks",
    Description = "Unhide all records and streaks",
    Default = false
})

bgToggle:OnChanged(function(value)
    if value then
        setBGVisibleToTrue()
    else
        setBGVisibleToFalse()
    end
end)

local TeleportService = game:GetService("TeleportService")
local PlaceId = 17652853807

local function teleportToPlace()
    TeleportService:Teleport(PlaceId)
end

Tabs.Misc:CreateButton{
    Title = "Teleport to Ranked without 40 OVR",
    Description = "Teleports you to ranked without being 40 ovr",
    Callback = function()
        teleportToPlace()
    end
}

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("VantaBETA")
SaveManager:SetFolder("VantaBETA/Basketball legends")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Library:Notify{
    Title = "Done",
    Content = "Enjoy Vanta.",
    Duration = 8
}

SaveManager:LoadAutoloadConfig()
