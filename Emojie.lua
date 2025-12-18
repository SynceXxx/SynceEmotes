local Screen= setmetatable({}, {
__index= function(_, key)
local cam= workspace.CurrentCamera
local size= cam and cam.ViewportSize or Vector2.new(1920, 1080)
if key== "Width" then
return size.X
elseif key== "Height" then
return size.Y
elseif key== "Size" then
return size
end end})

local UserInputService = game:GetService("UserInputService")
local Screen = workspace.CurrentCamera.ViewportSize

function scale(axis, value)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local baseWidth, baseHeight = 1920, 1080
    local scaleFactor = isMobile and 2 or 1.5

    if axis == "X" then
        return value * (Screen.X / baseWidth) * scaleFactor
    elseif axis == "Y" then
        return value * (Screen.Y / baseHeight) * scaleFactor
    end
end

function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback 
end

cloneref = missing("function", cloneref, function(...) return ... end)

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local AvatarEditorService = Services.AvatarEditorService
local HttpService = Services.HttpService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
end)

local Settings = {}
Settings["Stop Emote When Moving"] = true
Settings["Fade In"]     = 0.1
Settings["Fade Out"]    = 0.1
Settings["Weight"]      = 1
Settings["Speed"]       = 1
Settings["Allow Invisible  "]    = true
Settings["Time Position"] = 0
Settings["Freeze On Finish"] = false
Settings["Looped"] = true
Settings["Stop Other Animations On Play"] = true
Settings["Preview"]    = false

local savedEmotes = {}
local SAVE_FILE = "GazeEmotes_NewNEWN3WSaved.json"

local function loadSavedEmotes()
    local success, data = pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
        return {}
    end)
    if success and type(data) == "table" then
        savedEmotes = data
    else
        savedEmotes = {}
    end
    for _, v in ipairs(savedEmotes) do
        if not v.AnimationId then
            if v.AssetId then
                v.AnimationId = "rbxassetid://" .. tostring(v.AssetId)
            else
                v.AnimationId = "rbxassetid://" .. tostring(v.Id)
            end
        end
        if v.Favorite == nil then
            v.Favorite = false
        end
    end
end

local function saveEmotesToData()
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpService:JSONEncode(savedEmotes))
        end
    end)
end

loadSavedEmotes()

local CurrentTrack = nil

local function LoadTrack(id)
    if CurrentTrack then 
        CurrentTrack:Stop(Settings["Fade Out"]) 
    end
    local animId
    local ok, result = pcall(function() 
        return game:GetObjects("rbxassetid://" .. tostring(id)) 
    end)
    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end
    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId
    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4
    local weight = Settings["Weight"]
    if weight == 0 then weight = 0.001 end
    if Settings["Stop Other Animations On Play"] then
    for _,t in pairs(humanoid.Animator:GetPlayingAnimationTracks())do
        if t.Priority ~= Enum.AnimationPriority.Action4 then
            t:Stop()
        end
    end
    end
    newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])
    CurrentTrack = newTrack 
    CurrentTrack.TimePosition = math.clamp(Settings["Time Position"], 0, 1) * (CurrentTrack.Length or 1)
    CurrentTrack.Priority = Enum.AnimationPriority.Action4
    CurrentTrack.Looped = Settings["Looped"]
    return newTrack
end


local function getanimid(assetId)
    -- Try to get the actual animation ID from the asset
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)
    
    if success and objects and #objects > 0 then
        local obj = objects[1]
        if obj:IsA("Animation") then
            return tonumber(obj.AnimationId:match("%d+")) or assetId
        elseif obj:FindFirstChildOfClass("Animation") then
            local anim = obj:FindFirstChildOfClass("Animation")
            return tonumber(anim.AnimationId:match("%d+")) or assetId
        end
    end
    return assetId -- Fallback to the asset ID itself
end

RunService.RenderStepped:Connect(function()



if Settings["Looped"] and CurrentTrack and CurrentTrack.IsPlaying then
	CurrentTrack.Looped = Settings["Looped"]
end

if character:FindFirstChild("HumanoidRootPart") then
	local root = character.HumanoidRootPart
	if Settings["Stop Emote When Moving"] and CurrentTrack and CurrentTrack.IsPlaying then
		local moved = (root.Position - lastPosition).Magnitude > 0.1
		local jumped = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping
		if moved or jumped then
			CurrentTrack:Stop(Settings["Fade Out"])
			CurrentTrack = nil
		end
	end

	lastPosition = root.Position
end

end)
local CoreGui = Services.CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "GazeEmoteGUI"
gui.Parent = CoreGui
gui.Enabled = false
gui.DisplayOrder = 999

local function createGradient(parent, colorSequence) return end

local function createCorner(parent, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = parent
    return corner
end

-- Modern Matcha Color Palette
local MatchaColors = {
    Primary = Color3.fromRGB(158, 193, 163),      -- Soft Matcha Green
    Secondary = Color3.fromRGB(118, 166, 127),    -- Medium Matcha
    Dark = Color3.fromRGB(83, 130, 93),           -- Dark Matcha
    Accent = Color3.fromRGB(182, 215, 168),       -- Light Matcha
    Background = Color3.fromRGB(238, 243, 237),   -- Cream White
    Surface = Color3.fromRGB(250, 252, 250),      -- White Surface
    Text = Color3.fromRGB(52, 73, 56),            -- Dark Green Text
    TextLight = Color3.fromRGB(99, 120, 103),     -- Light Text
    Error = Color3.fromRGB(194, 123, 117),        -- Soft Red
    Success = Color3.fromRGB(139, 184, 145),      -- Success Green
}

local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, scale("X", 600), 0, scale("Y", 400))
mainContainer.Position = UDim2.new(0.5, -scale("X", 300), 0.5, -scale("Y", 200))
mainContainer.BackgroundColor3 = MatchaColors.Surface
mainContainer.BorderSizePixel = 0
mainContainer.Active = true
mainContainer.Draggable = true
mainContainer.Parent = gui
mainContainer.ClipsDescendants = false

-- Shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.85
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = 0
shadow.Parent = mainContainer

local parentFrame = mainContainer.Parent

local function clampPosition()
    local parentSize = parentFrame.AbsoluteSize
    local containerSize = mainContainer.AbsoluteSize

    local extraX = containerSize.X * 0.5
    local extraY = containerSize.Y * 0.5

    local x = mainContainer.Position.X.Scale * parentSize.X + mainContainer.Position.X.Offset
    local y = mainContainer.Position.Y.Scale * parentSize.Y + mainContainer.Position.Y.Offset

    local clampedX = math.clamp(
        x,
        -extraX,
        parentSize.X - containerSize.X + extraX
    )

    local clampedY = math.clamp(
        y,
        -extraY,
        parentSize.Y - containerSize.Y + extraY
    )

    mainContainer.Position = UDim2.new(0, clampedX, 0, clampedY)
end

mainContainer:GetPropertyChangedSignal("Position"):Connect(clampPosition)

createCorner(mainContainer, 16)

-- Subtle gradient overlay
local gradientOverlay = Instance.new("Frame")
gradientOverlay.Size = UDim2.new(1, 0, 1, 0)
gradientOverlay.BackgroundTransparency = 1
gradientOverlay.ZIndex = 1
gradientOverlay.Parent = mainContainer

local g = Instance.new("UIGradient")
g.Color = ColorSequence.new(MatchaColors.Accent, MatchaColors.Surface)
g.Rotation = 135
g.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.95),
    NumberSequenceKeypoint.new(1, 0.98)
}
g.Parent = mainContainer

-- Title Bar with modern design
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, scale("Y", 50))
title.BackgroundColor3 = MatchaColors.Primary
title.Text = "🍵 Gaze Emotes"
title.TextColor3 = MatchaColors.Surface
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextScaled = false
title.ZIndex = 2
title.Parent = mainContainer
createCorner(title, 16)

-- Title gradient
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new(MatchaColors.Secondary, MatchaColors.Primary)
titleGrad.Rotation = 90
titleGrad.Parent = title

-- Tab container with smooth animation
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 0, scale("Y", 36))
tabContainer.Position = UDim2.new(0, 10, 0, scale("Y", 60))
tabContainer.BackgroundColor3 = MatchaColors.Background
tabContainer.BackgroundTransparency = 0.3
tabContainer.ZIndex = 2
tabContainer.Parent = mainContainer
createCorner(tabContainer, 18)

-- Tab indicator (sliding pill)
local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0.5, -6, 1, -6)
tabIndicator.Position = UDim2.new(0, 3, 0, 3)
tabIndicator.BackgroundColor3 = MatchaColors.Surface
tabIndicator.ZIndex = 2
tabIndicator.Parent = tabContainer
createCorner(tabIndicator, 15)

-- Tab indicator shadow
local tabShadow = Instance.new("Frame")
tabShadow.Size = UDim2.new(1, 4, 1, 4)
tabShadow.Position = UDim2.new(0, -2, 0, -2)
tabShadow.BackgroundColor3 = MatchaColors.Dark
tabShadow.BackgroundTransparency = 0.9
tabShadow.ZIndex = 1
tabShadow.Parent = tabIndicator
createCorner(tabShadow, 16)

local catalogTabBtn = Instance.new("TextButton")
catalogTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
catalogTabBtn.Position = UDim2.new(0, 0, 0, 0)
catalogTabBtn.BackgroundTransparency = 1
catalogTabBtn.Text = "Catalog"
catalogTabBtn.TextColor3 = MatchaColors.Dark
catalogTabBtn.Font = Enum.Font.GothamBold
catalogTabBtn.TextSize = 16
catalogTabBtn.TextScaled = false
catalogTabBtn.ZIndex = 3
catalogTabBtn.Parent = tabContainer

local savedTabBtn = Instance.new("TextButton")
savedTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
savedTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
savedTabBtn.BackgroundTransparency = 1
savedTabBtn.Text = "Saved"
savedTabBtn.TextColor3 = MatchaColors.TextLight
savedTabBtn.Font = Enum.Font.GothamBold
savedTabBtn.TextSize = 16
savedTabBtn.TextScaled = false
savedTabBtn.ZIndex = 3
savedTabBtn.Parent = tabContainer

-- Tab animation function
local function animateTab(toSaved)
    local targetPos = toSaved and UDim2.new(0.5, 3, 0, 3) or UDim2.new(0, 3, 0, 3)
    TweenService:Create(tabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
    
    -- Update text colors with smooth transition
    TweenService:Create(catalogTabBtn, TweenInfo.new(0.2), {
        TextColor3 = toSaved and MatchaColors.TextLight or MatchaColors.Dark
    }):Play()
    TweenService:Create(savedTabBtn, TweenInfo.new(0.2), {
        TextColor3 = toSaved and MatchaColors.Dark or MatchaColors.TextLight
    }):Play()
end

-- Divider with subtle style
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, 1, 1, -scale("Y", 110))
divider.Position = UDim2.new(0.6, 0, 0, scale("Y", 105))
divider.BackgroundColor3 = MatchaColors.Primary
divider.BackgroundTransparency = 0.7
divider.BorderSizePixel = 0
divider.ZIndex = 2
divider.Parent = mainContainer

-- Catalog Frame
local catalogFrame = Instance.new("Frame")
catalogFrame.Size = UDim2.new(0.6, -scale("X", 10), 1, -scale("Y", 110))
catalogFrame.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 105))
catalogFrame.BackgroundTransparency = 1
catalogFrame.Visible = true
catalogFrame.ZIndex = 2
catalogFrame.Parent = mainContainer

-- Modern Search Box with icon
local searchContainer = Instance.new("Frame")
searchContainer.Size = UDim2.new(0.6, -scale("X", 12), 0, scale("Y", 32))
searchContainer.Position = UDim2.new(0, scale("X", 8), 0, 0)
searchContainer.BackgroundColor3 = MatchaColors.Background
searchContainer.BackgroundTransparency = 0.5
searchContainer.ZIndex = 2
searchContainer.Parent = catalogFrame
createCorner(searchContainer, 16)

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, scale("X", 24), 1, 0)
searchIcon.Position = UDim2.new(0, scale("X", 8), 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextSize = 18
searchIcon.TextColor3 = MatchaColors.TextLight
searchIcon.ZIndex = 3
searchIcon.Parent = searchContainer

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -scale("X", 40), 1, 0)
searchBox.Position = UDim2.new(0, scale("X", 36), 0, 0)
searchBox.PlaceholderText = "Search emotes..."
searchBox.PlaceholderColor3 = MatchaColors.TextLight
searchBox.BackgroundTransparency = 1
searchBox.TextColor3 = MatchaColors.Text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.TextScaled = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Text = ""
searchBox.ZIndex = 3
searchBox.Parent = searchContainer

-- Refresh Button with icon
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.18, -scale("X", 4), 0, scale("Y", 32))
refreshBtn.Position = UDim2.new(0.6, scale("X", 4), 0, 0)
refreshBtn.BackgroundColor3 = MatchaColors.Secondary
refreshBtn.Text = "🔄"
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 18
refreshBtn.TextScaled = false
refreshBtn.TextColor3 = MatchaColors.Surface
refreshBtn.AutoButtonColor = false
refreshBtn.ZIndex = 2
refreshBtn.Parent = catalogFrame
createCorner(refreshBtn, 16)

-- Refresh button hover effect
refreshBtn.MouseEnter:Connect(function()
    TweenService:Create(refreshBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = MatchaColors.Dark
    }):Play()
end)
refreshBtn.MouseLeave:Connect(function()
    TweenService:Create(refreshBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = MatchaColors.Secondary
    }):Play()
end)

-- Sort Button
local sortBtn = Instance.new("TextButton")
sortBtn.Size = UDim2.new(0.22, -scale("X", 8), 0, scale("Y", 32))
sortBtn.Position = UDim2.new(0.78, scale("X", 4), 0, 0)
sortBtn.BackgroundColor3 = MatchaColors.Primary
sortBtn.Text = "Sort: Relevance"
sortBtn.Font = Enum.Font.GothamBold
sortBtn.TextSize = 11
sortBtn.TextScaled = false
sortBtn.TextColor3 = MatchaColors.Surface
sortBtn.AutoButtonColor = false
sortBtn.ZIndex = 2
sortBtn.Parent = catalogFrame
createCorner(sortBtn, 16)

-- Sort button hover effect
sortBtn.MouseEnter:Connect(function()
    TweenService:Create(sortBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = MatchaColors.Secondary
    }):Play()
end)
sortBtn.MouseLeave:Connect(function()
    TweenService:Create(sortBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = MatchaColors.Primary
    }):Play()
end)

-- Saved Frame
local savedFrame = Instance.new("Frame")
savedFrame.Size = UDim2.new(0.6, -scale("X", 10), 1, -scale("Y", 110))
savedFrame.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 105))
savedFrame.BackgroundTransparency = 1
savedFrame.Visible = false
savedFrame.ZIndex = 2
savedFrame.Parent = mainContainer

-- Saved Search Container
local savedSearchContainer = Instance.new("Frame")
savedSearchContainer.Size = UDim2.new(1, -scale("X", 16), 0, scale("Y", 32))
savedSearchContainer.Position = UDim2.new(0, scale("X", 8), 0, 0)
savedSearchContainer.BackgroundColor3 = MatchaColors.Background
savedSearchContainer.BackgroundTransparency = 0.5
savedSearchContainer.ZIndex = 2
savedSearchContainer.Parent = savedFrame
createCorner(savedSearchContainer, 16)

local savedSearchIcon = Instance.new("TextLabel")
savedSearchIcon.Size = UDim2.new(0, scale("X", 24), 1, 0)
savedSearchIcon.Position = UDim2.new(0, scale("X", 8), 0, 0)
savedSearchIcon.BackgroundTransparency = 1
savedSearchIcon.Text = "⭐"
savedSearchIcon.TextSize = 16
savedSearchIcon.TextColor3 = MatchaColors.TextLight
savedSearchIcon.ZIndex = 3
savedSearchIcon.Parent = savedSearchContainer

local savedSearch = Instance.new("TextBox")
savedSearch.Size = UDim2.new(1, -scale("X", 40), 1, 0)
savedSearch.Position = UDim2.new(0, scale("X", 36), 0, 0)
savedSearch.PlaceholderText = "Search saved emotes..."
savedSearch.PlaceholderColor3 = MatchaColors.TextLight
savedSearch.BackgroundTransparency = 1
savedSearch.TextColor3 = MatchaColors.Text
savedSearch.Font = Enum.Font.Gotham
savedSearch.TextSize = 14
savedSearch.TextScaled = false
savedSearch.TextXAlignment = Enum.TextXAlignment.Left
savedSearch.ClearTextOnFocus = false
savedSearch.Text = ""
savedSearch.ZIndex = 3
savedSearch.Parent = savedSearchContainer

-- Saved Scroll Frame
local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 44))
savedScroll.Position = UDim2.new(0, scale("X", 8), 0, scale("Y", 40))
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.ScrollBarThickness = 4
savedScroll.ScrollBarImageColor3 = MatchaColors.Primary
savedScroll.BackgroundTransparency = 1
savedScroll.BorderSizePixel = 0
savedScroll.ZIndex = 2
savedScroll.Parent = savedFrame

local savedEmptyLabel = Instance.new("TextLabel")
savedEmptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 36))
savedEmptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 18))
savedEmptyLabel.BackgroundTransparency = 1
savedEmptyLabel.Text = "No saved emotes yet 🍃"
savedEmptyLabel.TextColor3 = MatchaColors.TextLight
savedEmptyLabel.Font = Enum.Font.GothamBold
savedEmptyLabel.TextSize = 16
savedEmptyLabel.TextScaled = false
savedEmptyLabel.Visible = false
savedEmptyLabel.ZIndex = 3
savedEmptyLabel.Parent = savedScroll

local savedLayout = Instance.new("UIGridLayout")
savedLayout.CellSize = UDim2.new(0, scale("X", 120), 0, scale("Y", 200))
savedLayout.CellPadding = UDim2.new(0, scale("X", 10), 0, scale("Y", 10))
savedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
savedLayout.Parent = savedScroll

-- Settings Frame with modern card design
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0.4, -scale("X", 10), 1, -scale("Y", 110))
settingsFrame.Position = UDim2.new(0.6, scale("X", 5), 0, scale("Y", 105))
settingsFrame.BackgroundTransparency = 1
settingsFrame.ZIndex = 2
settingsFrame.Parent = mainContainer

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, scale("Y", 32))
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙️ Settings"
settingsTitle.TextColor3 = MatchaColors.Text
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 18
settingsTitle.TextScaled = false
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.ZIndex = 2
settingsTitle.Parent = settingsFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -scale("X", 8), 1, -scale("Y", 40))
scrollFrame.Position = UDim2.new(0, scale("X", 4), 0, scale("Y", 36))
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = MatchaColors.Primary
scrollFrame.BorderSizePixel = 0
scrollFrame.ZIndex = 2
scrollFrame.Parent = settingsFrame

local function lockX()
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasPosition.Y)
end
scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(lockX)

local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.Padding = UDim.new(0, 8)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

 function GetReal(id)
    local ok, obj = pcall(function()
        return game:GetObjects("rbxassetid://"..tostring(id))
    end)
    if ok and obj and #obj > 0 then
        local anim = obj[1]
        if anim:IsA("Animation") and anim.AnimationId ~= "" then
            return tonumber(anim.AnimationId:match("%d+"))
        end
    end
end

Settings._sliders = {}
Settings._toggles = {}

--// SLIDER CREATOR (Modern Matcha Style)
local function createSlider(name, min, max, default)
    Settings[name] = default or min

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, scale("Y", 72))
    container.BackgroundTransparency = 1
    container.ZIndex = 2
    container.Parent = scrollFrame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = MatchaColors.Background
    bg.BackgroundTransparency = 0.3
    bg.ZIndex = 2
    bg.Parent = container
    createCorner(bg, 12)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -scale("X", 10), 0, scale("Y", 20))
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s: %.2f", name, Settings[name])
    label.TextColor3 = MatchaColors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextScaled = false
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = bg

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.4, -scale("X", 16), 0, scale("Y", 24))
    textBox.Position = UDim2.new(0.6, scale("X", 8), 0, scale("Y", 6))
    textBox.BackgroundColor3 = MatchaColors.Surface
    textBox.Text = tostring(Settings[name])
    textBox.TextColor3 = MatchaColors.Text
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 13
    textBox.TextScaled = false
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 3
    textBox.Parent = bg
    createCorner(textBox, 8)

    -- Subtle border
    local textBoxBorder = Instance.new("UIStroke")
    textBoxBorder.Color = MatchaColors.Primary
    textBoxBorder.Thickness = 1
    textBoxBorder.Transparency = 0.7
    textBoxBorder.Parent = textBox

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -scale("X", 24), 0, scale("Y", 6))
    sliderBar.Position = UDim2.new(0, scale("X", 12), 0, scale("Y", 42))
    sliderBar.BackgroundColor3 = MatchaColors.Background
    sliderBar.BackgroundTransparency = 0.3
    sliderBar.ZIndex = 2
    sliderBar.Parent = bg
    createCorner(sliderBar, 3)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = MatchaColors.Secondary
    sliderFill.ZIndex = 3
    sliderFill.Parent = sliderBar
    createCorner(sliderFill, 3)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, scale("X", 18), 0, scale("Y", 18))
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.BackgroundColor3 = MatchaColors.Surface
    thumb.ZIndex = 4
    thumb.Parent = sliderBar
    createCorner(thumb, 9)

    -- Thumb border
    local thumbBorder = Instance.new("UIStroke")
    thumbBorder.Color = MatchaColors.Secondary
    thumbBorder.Thickness = 2
    thumbBorder.Parent = thumb

    local function tweenVisual(rel)
        local visualRel = math.clamp(rel, 0, 1)
        TweenService:Create(sliderFill, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Size = UDim2.new(visualRel, 0, 1, 0)
        }):Play()
        TweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = UDim2.new(visualRel, 0, 0.5, 0)
        }):Play()
    end

    local function applyValue(value)
        Settings[name] = math.clamp(value, min, max)
        label.Text = string.format("%s: %.2f", name, Settings[name])
        textBox.Text = tostring(Settings[name])
        local rel = (Settings[name] - min) / (max - min)
        tweenVisual(rel)

        if CurrentTrack and CurrentTrack.IsPlaying then
            if name == "Speed" then
                CurrentTrack:AdjustSpeed(Settings["Speed"])
            elseif name == "Weight" then
                local weight = Settings["Weight"]
                if weight == 0 then weight = 0.001 end
                CurrentTrack:AdjustWeight(weight)
            elseif name == "Time Position" then
                if CurrentTrack.Length > 0 then
                    CurrentTrack.TimePosition = math.clamp(value, 0, 1) * CurrentTrack.Length
                end
            end
        end
    end

    local dragging = false
    local function updateFromInput(input)
        local relX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local value = math.floor((min + (max - min) * relX) * 100) / 100
        applyValue(value)
    end

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
            TweenService:Create(thumb, TweenInfo.new(0.1), {Size = UDim2.new(0, scale("X", 22), 0, scale("Y", 22))}):Play()
        end
    end)

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
            TweenService:Create(thumb, TweenInfo.new(0.1), {Size = UDim2.new(0, scale("X", 22), 0, scale("Y", 22))}):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            TweenService:Create(thumb, TweenInfo.new(0.1), {Size = UDim2.new(0, scale("X", 18), 0, scale("Y", 18))}):Play()
        end
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textBox.Text)
            if num then
                applyValue(num)
            else
                textBox.Text = tostring(Settings[name])
            end
        end
    end)

    Settings._sliders[name] = applyValue
    applyValue(Settings[name])
end

--// TOGGLE CREATOR (Modern Matcha Style)
local function createToggle(name)
    Settings[name] = Settings[name] or false

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, scale("Y", 44))
    container.BackgroundColor3 = MatchaColors.Background
    container.BackgroundTransparency = 0.3
    container.ZIndex = 2
    container.Parent = scrollFrame
    createCorner(container, 12)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, -scale("X", 10), 1, 0)
    label.Position = UDim2.new(0, scale("X", 12), 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = MatchaColors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextScaled = false
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = container

    -- Modern toggle switch
    local toggleTrack = Instance.new("Frame")
    toggleTrack.Size = UDim2.new(0, scale("X", 48), 0, scale("Y", 26))
    toggleTrack.Position = UDim2.new(1, -scale("X", 58), 0.5, -scale("Y", 13))
    toggleTrack.BackgroundColor3 = MatchaColors.TextLight
    toggleTrack.BackgroundTransparency = 0.3
    toggleTrack.ZIndex = 2
    toggleTrack.Parent = container
    createCorner(toggleTrack, 13)

    local toggleThumb = Instance.new("Frame")
    toggleThumb.Size = UDim2.new(0, scale("X", 22), 0, scale("Y", 22))
    toggleThumb.Position = UDim2.new(0, scale("X", 2), 0.5, -scale("Y", 11))
    toggleThumb.BackgroundColor3 = MatchaColors.Surface
    toggleThumb.ZIndex = 3
    toggleThumb.Parent = toggleTrack
    createCorner(toggleThumb, 11)

    -- Thumb shadow
    local thumbShadow = Instance.new("UIStroke")
    thumbShadow.Color = MatchaColors.Dark
    thumbShadow.Thickness = 1
    thumbShadow.Transparency = 0.8
    thumbShadow.Parent = toggleThumb

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 4
    toggleBtn.Parent = toggleTrack

    local function applyVisual(state)
        local trackColor = state and MatchaColors.Secondary or MatchaColors.TextLight
        local thumbPos = state and UDim2.new(1, -scale("X", 24), 0.5, -scale("Y", 11)) or UDim2.new(0, scale("X", 2), 0.5, -scale("Y", 11))
        
        TweenService:Create(toggleTrack, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            BackgroundColor3 = trackColor,
            BackgroundTransparency = state and 0 or 0.3
        }):Play()
        
        TweenService:Create(toggleThumb, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = thumbPos
        }):Play()
    end

    toggleBtn.MouseButton1Click:Connect(function()
        Settings[name] = not Settings[name]
        applyVisual(Settings[name])
    end)

    applyVisual(Settings[name])
    Settings._toggles[name] = applyVisual
end

--// UNIFIED EDIT FUNCTIONS
function Settings:EditSlider(targetName, newValue)
    local apply = self._sliders[targetName]
    if apply then
        apply(newValue)
    end
end

function Settings:EditToggle(targetName, newValue)
    local apply = self._toggles[targetName]
    if apply then
        Settings[targetName] = newValue
        apply(newValue)
    end
end

local function createButton(name, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, scale("Y", 48))
    container.BackgroundColor3 = MatchaColors.Background
    container.BackgroundTransparency = 0.3
    container.ZIndex = 2
    container.Parent = scrollFrame
    createCorner(container, 12)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 8))
    button.Position = UDim2.new(0, scale("X", 8), 0, scale("Y", 4))
    button.BackgroundColor3 = MatchaColors.Primary
    button.Text = name
    button.TextColor3 = MatchaColors.Surface
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextScaled = false
    button.AutoButtonColor = false
    button.ZIndex = 3
    button.Parent = container
    createCorner(button, 10)

    -- Gradient effect
    local btnGrad = Instance.new("UIGradient")
    btnGrad.Color = ColorSequence.new(MatchaColors.Secondary, MatchaColors.Primary)
    btnGrad.Rotation = 45
    btnGrad.Parent = button

    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(1, -scale("X", 12), 1, -scale("Y", 4))
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 8))
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(1, -scale("X", 18), 1, -scale("Y", 10))
        }):Play()
        task.wait(0.1)
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 8))
        }):Play()
        
        if typeof(callback) == "function" then
            callback()
        end
    end)

    return button
end

local resetButton = createButton("🔄 Reset Settings", function() end)
createToggle("Preview")
createToggle("Stop Emote When Moving")
createToggle("Looped")
createSlider("Speed", 0, 5, Settings["Speed"])
createSlider("Time Position", 0, 1, Settings["Time Position"])
createSlider("Weight", 0, 1, Settings["Weight"])
createSlider("Fade In", 0, 2, Settings["Fade In"])
createSlider("Fade Out", 0, 2, Settings["Fade Out"])
createToggle("Allow Invisible   ")
createToggle("Stop Other Animations On Play")


resetButton.MouseButton1Click:Connect(function()
    Settings:EditToggle("Stop Emote When Moving", true)
    Settings:EditToggle("Stop Other Animations On Play", true)
    Settings:EditToggle("Preview", false)
    Settings:EditSlider("Fade In", 0.1)
    Settings:EditSlider("Fade Out", 0.1)
    Settings:EditSlider("Weight", 1)
    Settings:EditSlider("Speed", 1)
    Settings:EditToggle("Allow Invisible  ", true)
    Settings:EditSlider("Time Position", 0)
    Settings:EditToggle("Freeze On Finish", false)
    Settings:EditToggle("Looped", true)
end)

local originalCollisionStates = {}
local lastFixClipState = Settings["Allow Invisible  "]

local function saveCollisionStates()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character.PrimaryPart then
            originalCollisionStates[part] = part.CanCollide
        end
    end
end

local function disableCollisionsExceptRootPart()
    if not Settings["Allow Invisible  "] then
        return
    end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character.PrimaryPart then
            part.CanCollide = false
        end
    end
end

local function restoreCollisionStates()
    for part, canCollide in pairs(originalCollisionStates) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end
    originalCollisionStates = {}
end

saveCollisionStates()

local connection
connection = RunService.Stepped:Connect(function()
    if character and character.Parent then
        local currentFixClip = Settings["Allow Invisible  "]
        if lastFixClipState ~= currentFixClip then
            if currentFixClip then
                saveCollisionStates()
                disableCollisionsExceptRootPart()
            else
                restoreCollisionStates()
            end
            lastFixClipState = currentFixClip
        elseif currentFixClip then
            disableCollisionsExceptRootPart()
        end
    else
        restoreCollisionStates()
        if connection then
            connection:Disconnect()
        end
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    restoreCollisionStates()
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    saveCollisionStates()
    lastFixClipState = Settings["Allow Invisible  "]
    if connection then
        connection:Disconnect()
    end
    connection = RunService.Stepped:Connect(function()
        if character and character.Parent then
            local currentFixClip = Settings["Allow Invisible  "]
            if lastFixClipState ~= currentFixClip then
                if currentFixClip then
                    saveCollisionStates()
                    disableCollisionsExceptRootPart()
                else
                    restoreCollisionStates()
                end
                lastFixClipState = currentFixClip
            elseif currentFixClip then
                disableCollisionsExceptRootPart()
            end
        else
            restoreCollisionStates()
            if connection then
                connection:Disconnect()
            end
        end
    end)
end)

-- Catalog API Configuration
local CATALOG_URL = "https://catalog.roproxy.com/v2/search/items/details"
local EMOTE_ASSET_TYPE = 61
local BIG_FETCH_LIMIT = 120
local PAGE_SIZE_TINY = 10
local THE_SORT_LIST = {"Updated", "Relevance", "Favorited", "Sales", "PriceAsc", "PriceDesc"}

-- State Management
local ITEM_CACHE = {}
local NEXT_API_CURSOR = nil
local CURRENT_PAGE_NUMBER = 1
local CURRENT_SORT_OPTION = "Updated"
local CURRENT_SEARCH_TEXT = ""

local function GetEmoteDataFromWeb()
    local url_parts = {
        CATALOG_URL .. "?model.assetTypeIds=" .. EMOTE_ASSET_TYPE,
        "&model.includeNotForSale=true",
        "&limit=" .. BIG_FETCH_LIMIT,
        "&sortOrder=Desc",
        "&model.sortType=" .. CURRENT_SORT_OPTION
    }
    
    if CURRENT_SEARCH_TEXT ~= "" then
        url_parts[#url_parts + 1] = "&model.keyword=" .. HttpService:UrlEncode(CURRENT_SEARCH_TEXT)
    end
    
    if NEXT_API_CURSOR then
        url_parts[#url_parts + 1] = "&cursor=" .. NEXT_API_CURSOR
    end
    
    local final_url = table.concat(url_parts)
print("[API] Fetching: " .. final_url)

local response
local success, result = pcall(function()
    return request({
        Url = final_url,
        Method = "GET"
    })
end)

if not success or not result or not result.Success then
    warn("[API] Request failed: " .. tostring(result and result.StatusMessage))
    return false
end

response = result.Body

local data_table
success, data_table = pcall(function()
    return HttpService:JSONDecode(response)
end)

if not success or not data_table or not data_table.data then
    warn("[API] JSON parse failed or missing data field.")
    return false
end

for _, item in pairs(data_table.data) do
    table.insert(ITEM_CACHE, item)
end
    
    NEXT_API_CURSOR = data_table.nextPageCursor
    print(string.format("[API] Got %d new items. Total cached: %d", #data_table.data, #ITEM_CACHE))
    
    return true
end

local function createViewport(size, position, parent)
    local viewportContainer = Instance.new("Frame")
    viewportContainer.Size = size
    viewportContainer.BackgroundTransparency = 1
    viewportContainer.Position = position
    viewportContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    viewportContainer.BorderSizePixel = 0
    viewportContainer.ZIndex = 2
    viewportContainer.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = viewportContainer
    
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, -4, 1, -4)
    viewport.Position = UDim2.new(0, 2, 0, 2)
    viewport.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.ZIndex = 3
    viewport.Parent = viewportContainer
    
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    viewport.CurrentCamera = camera
    
    local dummy = Players:CreateHumanoidModelFromUserId(game:GetService("Players").LocalPlayer.UserId)
    dummy.Parent = worldModel
    
    local hrp = dummy:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Transparency = 1
    end
    
    for _, part in ipairs(dummy:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local root = dummy.PrimaryPart or dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChildWhichIsA("BasePart")
    if root then
        dummy.PrimaryPart = root
        dummy:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
    end
    
    if root then
        camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 8), root.Position)
    end
    
    local dummyData = {
        Dummy = dummy,
        Viewport = viewport,
        Camera = camera,
        WorldModel = worldModel,
        Humanoid = dummy:FindFirstChildWhichIsA("Humanoid"),
        CurrentAnim = nil
    }
    
    local rotationAngle = 0
    local rotationSpeed = math.rad(30)
    
    game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
        if dummyData.Humanoid and root then
            rotationAngle = rotationAngle + rotationSpeed * deltaTime
            
            local x = math.sin(rotationAngle) * 6
            local z = math.cos(rotationAngle) * 6
            dummyData.Camera.CFrame = CFrame.new(root.Position + Vector3.new(x, 3, z), root.Position)
        end
    end)
    
    return viewportContainer, dummyData
end


local function playAnimation(dummyData, animId)
    if not dummyData or not dummyData.Humanoid then return end
    
    if dummyData.CurrentAnim then
        dummyData.CurrentAnim:Stop()
        dummyData.CurrentAnim:Destroy()
    end
    
    if not dummyData.Humanoid:FindFirstChildOfClass("Animator") then
        Instance.new("Animator", dummyData.Humanoid)
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(animId)
    
    local animator = dummyData.Humanoid:FindFirstChildOfClass("Animator")
    local animTrack = animator:LoadAnimation(animation)
    
    dummyData.CurrentAnim = animTrack
    animTrack.Looped = true
    animTrack:Play()
    
    return animTrack
end

local function createCard(item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
    card.BackgroundColor3 = MatchaColors.Surface
    card.ZIndex = 2
    createCorner(card, 12)
    
    -- Card shadow
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = MatchaColors.Primary
    cardBorder.Thickness = 1
    cardBorder.Transparency = 0.85
    cardBorder.Parent = card
    
    local thumbId = item.AssetId or item.Id
    
    if Settings["Preview"] == true then
        local viewport, dummy = createViewport(
            UDim2.fromScale(1, 0.5),
            UDim2.fromScale(0, 0),
            card
        )
        playAnimation(dummy, getanimid(thumbId))
    else
        local imgContainer = Instance.new("Frame")
        imgContainer.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 90))
        imgContainer.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
        imgContainer.BackgroundColor3 = MatchaColors.Background
        imgContainer.BackgroundTransparency = 0.5
        imgContainer.ZIndex = 2
        imgContainer.Parent = card
        createCorner(imgContainer, 8)
        
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 3
        pcall(function()
            img.Image = "rbxthumb://type=Asset&id=" .. tonumber(thumbId) .. "&w=150&h=150"
        end)
        img.Parent = imgContainer
    end
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    name.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 100))
    name.BackgroundTransparency = 1
    name.Text = item.Name 
    name.TextSize = 11
    name.TextScaled = false
    name.TextWrapped = true
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = MatchaColors.Text
    name.ZIndex = 3
    name.Parent = card
    
    local url = "https://www.roblox.com/catalog/" .. tonumber(item.Id)
    local copyLinkButton = Instance.new("TextButton")
    copyLinkButton.Parent = card
    copyLinkButton.Size = UDim2.new(0, scale("X", 32), 0, scale("Y", 32))
    copyLinkButton.Position = UDim2.new(1, -scale("X", 38), 0, scale("Y", 8))
    copyLinkButton.BackgroundColor3 = MatchaColors.Background
    copyLinkButton.BackgroundTransparency = 0.3
    copyLinkButton.Text = "🛒"
    copyLinkButton.Font = Enum.Font.GothamBold
    copyLinkButton.TextSize = 16
    copyLinkButton.TextScaled = false
    copyLinkButton.TextColor3 = MatchaColors.Text
    copyLinkButton.AutoButtonColor = false
    copyLinkButton.ZIndex = 4
    createCorner(copyLinkButton, 8)
    
    copyLinkButton.MouseButton1Click:Connect(function()
        setclipboard(url)
        copyLinkButton.Text = "✅"
        copyLinkButton.BackgroundColor3 = MatchaColors.Success
        TweenService:Create(copyLinkButton, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        task.wait(0.7)
        copyLinkButton.Text = "🛒"
        TweenService:Create(copyLinkButton, TweenInfo.new(0.2), {
            BackgroundColor3 = MatchaColors.Background,
            BackgroundTransparency = 0.3
        }):Play()
    end)

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    buttonContainer.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 33))
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = 2
    buttonContainer.Parent = card
    
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.48, 0, 1, 0)
    playBtn.Position = UDim2.new(0, 0, 0, 0)
    playBtn.BackgroundColor3 = MatchaColors.Secondary
    playBtn.Text = "▶ Play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 12
    playBtn.TextScaled = false
    playBtn.TextColor3 = MatchaColors.Surface
    playBtn.AutoButtonColor = false
    playBtn.ZIndex = 3
    playBtn.Parent = buttonContainer
    createCorner(playBtn, 8)
    
    playBtn.MouseEnter:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Dark}):Play()
    end)
    playBtn.MouseLeave:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Secondary}):Play()
    end)
    
    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(thumbId)
        TweenService:Create(playBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.46, 0, 0.9, 0)}):Play()
        task.wait(0.1)
        TweenService:Create(playBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1, 0)}):Play()
    end)
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.48, 0, 1, 0)
    saveBtn.Position = UDim2.new(0.52, 0, 0, 0)
    saveBtn.BackgroundColor3 = MatchaColors.Primary
    saveBtn.Text = "💾 Save"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.TextScaled = false
    saveBtn.TextColor3 = MatchaColors.Surface
    saveBtn.AutoButtonColor = false
    saveBtn.ZIndex = 3
    saveBtn.Parent = buttonContainer
    createCorner(saveBtn, 8)
    
    saveBtn.MouseEnter:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Secondary}):Play()
    end)
    saveBtn.MouseLeave:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Primary}):Play()
    end)
    
    saveBtn.MouseButton1Click:Connect(function()
        local alreadySaved = false
        for _, saved in ipairs(savedEmotes) do
            if saved.Id == item.Id then
                alreadySaved = true
                break
            end
        end
        if not alreadySaved then
            function GetReal(id)
                local ok, obj = pcall(function()
                    return game:GetObjects("rbxassetid://"..tostring(id))
                end)
                if not ok or not obj or #obj == 0 then return end

                local target = obj[1]
                if target:IsA("Animation") and target.AnimationId ~= "" then
                    return tonumber(target.AnimationId:match("%d+"))
                elseif target:FindFirstChildOfClass("Animation") then
                    local anim = target:FindFirstChildOfClass("Animation")
                    return tonumber(anim.AnimationId:match("%d+"))
                end
            end
            table.insert(savedEmotes, {
                Id = item.Id,
                AssetId = thumbId,
                Name = item.Name or "Unknown",
                AnimationId = "rbxassetid://" .. GetReal(thumbId),
                Favorite = false
            })
            saveEmotesToData()
            saveBtn.Text = "✓ Saved"
            saveBtn.BackgroundColor3 = MatchaColors.Success
            task.wait(1)
            saveBtn.Text = "💾 Save"
            saveBtn.BackgroundColor3 = MatchaColors.Primary
        else
            saveBtn.Text = "✓ Already"
            task.wait(0.7)
            saveBtn.Text = "💾 Save"
        end
    end)
    
    return card
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -scale("X", 16), 1, -scale("Y", 110))
scroll.Position = UDim2.new(0, scale("X", 8), 0, scale("Y", 40))
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = MatchaColors.Primary
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ZIndex = 2
scroll.Parent = catalogFrame

local layout = Instance.new("UIGridLayout", scroll)
layout.CellSize = UDim2.new(0, scale("X", 120), 0, scale("Y", 180))
layout.CellPadding = UDim2.new(0, scale("X", 8), 0, scale("Y", 8))

local emptyLabel = Instance.new("TextLabel", scroll)
emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 36))
emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 18))
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "Nothing found 🍃"
emptyLabel.TextColor3 = MatchaColors.TextLight
emptyLabel.Font = Enum.Font.GothamBold
emptyLabel.TextSize = 16
emptyLabel.TextScaled = false
emptyLabel.Visible = false
emptyLabel.ZIndex = 3

-- Navigation Container
local navContainer = Instance.new("Frame")
navContainer.Size = UDim2.new(1, -scale("X", 16), 0, scale("Y", 40))
navContainer.Position = UDim2.new(0, scale("X", 8), 1, -scale("Y", 44))
navContainer.BackgroundTransparency = 1
navContainer.ZIndex = 2
navContainer.Parent = catalogFrame

local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0.35, -scale("X", 4), 1, 0)
prevBtn.Position = UDim2.new(0, 0, 0, 0)
prevBtn.BackgroundColor3 = MatchaColors.Primary
prevBtn.Text = "← Prev"
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 14
prevBtn.TextScaled = false
prevBtn.TextColor3 = MatchaColors.Surface
prevBtn.AutoButtonColor = false
prevBtn.ZIndex = 3
prevBtn.Parent = navContainer
createCorner(prevBtn, 12)

prevBtn.MouseEnter:Connect(function()
    TweenService:Create(prevBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Secondary}):Play()
end)
prevBtn.MouseLeave:Connect(function()
    TweenService:Create(prevBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Primary}):Play()
end)

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0.35, -scale("X", 4), 1, 0)
nextBtn.Position = UDim2.new(0.65, scale("X", 4), 0, 0)
nextBtn.BackgroundColor3 = MatchaColors.Primary
nextBtn.Text = "Next →"
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 14
nextBtn.TextScaled = false
nextBtn.TextColor3 = MatchaColors.Surface
nextBtn.AutoButtonColor = false
nextBtn.ZIndex = 3
nextBtn.Parent = navContainer
createCorner(nextBtn, 12)

nextBtn.MouseEnter:Connect(function()
    TweenService:Create(nextBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Secondary}):Play()
end)
nextBtn.MouseLeave:Connect(function()
    TweenService:Create(nextBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Primary}):Play()
end)

local pageBoxContainer = Instance.new("Frame")
pageBoxContainer.Size = UDim2.new(0.3, -scale("X", 8), 1, 0)
pageBoxContainer.Position = UDim2.new(0.35, scale("X", 4), 0, 0)
pageBoxContainer.BackgroundColor3 = MatchaColors.Background
pageBoxContainer.BackgroundTransparency = 0.3
pageBoxContainer.ZIndex = 2
pageBoxContainer.Parent = navContainer
createCorner(pageBoxContainer, 12)

local pageBox = Instance.new("TextBox")
pageBox.Size = UDim2.new(1, 0, 1, 0)
pageBox.BackgroundTransparency = 1
pageBox.Font = Enum.Font.GothamBold
pageBox.TextSize = 13
pageBox.TextScaled = false
pageBox.TextColor3 = MatchaColors.Text
pageBox.Text = "Page 1"
pageBox.ZIndex = 3
pageBox.Parent = pageBoxContainer

local pageNotif = Instance.new("TextLabel", catalogFrame)
pageNotif.Size = UDim2.new(0.4, 0, 0, scale("Y", 24))
pageNotif.Position = UDim2.new(0.3, 0, 1, -scale("Y", 72))
pageNotif.BackgroundTransparency = 1
pageNotif.TextColor3 = MatchaColors.Error
pageNotif.Font = Enum.Font.GothamBold
pageNotif.TextSize = 12
pageNotif.TextScaled = false
pageNotif.Text = ""
pageNotif.Visible = false
pageNotif.ZIndex = 3

local function updateNavVisibility()
    prevBtn.Visible = (currentPageNumber > 1)
    if currentPages and typeof(currentPages.IsFinished) == "boolean" then
        nextBtn.Visible = not currentPages.IsFinished
    else
        nextBtn.Visible = true
    end
end

local RunService = game:GetService("RunService")
local isLoading = false

local function showPage()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local start_index = (CURRENT_PAGE_NUMBER - 1) * PAGE_SIZE_TINY + 1
    local end_index = start_index + PAGE_SIZE_TINY - 1

    local needsMoreData = false
    if start_index > #ITEM_CACHE and NEXT_API_CURSOR then
        needsMoreData = true
    end
    
    if needsMoreData then
        if pageBox then pageBox.Text = "Loading..." end
        local fetchWorked = GetEmoteDataFromWeb()
        if not fetchWorked then
            if pageBox then pageBox.Text = "API Error" end
            return
        end
        start_index = (CURRENT_PAGE_NUMBER - 1) * PAGE_SIZE_TINY + 1
        end_index = start_index + PAGE_SIZE_TINY - 1
    end

    if pageBox then
        pageBox.Text = "Page " .. tostring(CURRENT_PAGE_NUMBER)
    end
    if prevBtn then
        prevBtn.Active = (CURRENT_PAGE_NUMBER > 1)
        prevBtn.BackgroundTransparency = (CURRENT_PAGE_NUMBER > 1) and 0 or 0.5
    end
    if nextBtn then
        local canGoNext = (end_index < #ITEM_CACHE) or (NEXT_API_CURSOR ~= nil)
        nextBtn.Active = canGoNext
        nextBtn.BackgroundTransparency = canGoNext and 0 or 0.5
    end

    for i = start_index, math.min(end_index, #ITEM_CACHE) do
        local item = ITEM_CACHE[i]
        
        local card = createCard({
            Id = item.id,
            AssetId = item.id,
            Name = item.name or "Unknown",
            Description = item.description,
            CreatorName = item.creatorName or "Roblox",
            Price = item.price or 0,
        })
        
        if card then
            card.Parent = scroll
        end
        
        task.wait(0.01)
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    
    if emptyLabel then
        emptyLabel.Visible = (#ITEM_CACHE == 0)
    end
end


local function fetchPagesTo(targetPage)
local pages = getPages(currentKeyword)
if not pages then return nil end
for i = 2, targetPage do
if pages.IsFinished then break end
local ok, err = pcall(function() pages:AdvanceToNextPageAsync() end)
if not ok then break end
end
return pages
end

local function doNewSearch(keyword)
    CURRENT_SEARCH_TEXT = keyword or ""
    CURRENT_PAGE_NUMBER = 1
    NEXT_API_CURSOR = nil
    ITEM_CACHE = {}
    
    if pageBox then
        pageBox.Text = "Loading..."
    end
    
    local fetchSuccess = GetEmoteDataFromWeb()
    
    if fetchSuccess then
        showPage()
    else
        if pageBox then
            pageBox.Text = "Failed to load"
        end
    end
end

refreshBtn.MouseButton1Click:Connect(function()
    doNewSearch(searchBox.Text)
end)

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        doNewSearch(searchBox.Text)
    end
end)

local currentSortIndex = 1

sortBtn.MouseButton1Click:Connect(function()
    currentSortIndex = currentSortIndex % #THE_SORT_LIST + 1
    CURRENT_SORT_OPTION = THE_SORT_LIST[currentSortIndex]
    sortBtn.Text = "Sort: " .. CURRENT_SORT_OPTION
    doNewSearch(CURRENT_SEARCH_TEXT)
end)

local UserInputService = game:GetService("UserInputService")

local function goNextPage()
    local currentStart = (CURRENT_PAGE_NUMBER * PAGE_SIZE_TINY) + 1
    if currentStart <= #ITEM_CACHE or NEXT_API_CURSOR ~= nil then
        CURRENT_PAGE_NUMBER = CURRENT_PAGE_NUMBER + 1
        showPage()
    end
end

local function goPrevPage()
    if CURRENT_PAGE_NUMBER > 1 then
        CURRENT_PAGE_NUMBER = CURRENT_PAGE_NUMBER - 1
        showPage()
    end
end

nextBtn.MouseButton1Click:Connect(goNextPage)
prevBtn.MouseButton1Click:Connect(goPrevPage)

UserInputService.InputBegan:Connect(function(input)
    
    if input.KeyCode == Enum.KeyCode.Right then
        goNextPage()
    elseif input.KeyCode == Enum.KeyCode.Left then
        goPrevPage()
    end
end)

pageBox.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    
    local text = pageBox.Text:gsub("%s+", "")
    local num = tonumber(text:match("%d+"))
    
    if not num or num < 1 then
        pageNotif.Text = "Invalid page"
        pageNotif.Visible = true
        task.delay(2, function() 
            if pageNotif then 
                pageNotif.Visible = false 
            end 
        end)
        pageBox.Text = "Page " .. tostring(CURRENT_PAGE_NUMBER)
        return
    end
    
    local targetPage = math.floor(num)
    if targetPage == CURRENT_PAGE_NUMBER then
        pageBox.Text = "Page " .. tostring(CURRENT_PAGE_NUMBER)
        return
    end
    
    local requiredItems = (targetPage * PAGE_SIZE_TINY)
    while #ITEM_CACHE < requiredItems and NEXT_API_CURSOR ~= nil do
        GetEmoteDataFromWeb()
    end
    
    if #ITEM_CACHE >= requiredItems then
        CURRENT_PAGE_NUMBER = targetPage
        showPage()
    else
        pageBox.Text = "Not available"
    end
end)

catalogTabBtn.MouseButton1Click:Connect(function()
    catalogFrame.Visible = true
    savedFrame.Visible = false
    animateTab(false)
end)

local function createSavedCard(item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, scale("X", 120), 0, scale("Y", 200))
    card.BackgroundColor3 = MatchaColors.Surface
    card.ZIndex = 2
    createCorner(card, 12)
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = MatchaColors.Primary
    cardBorder.Thickness = 1
    cardBorder.Transparency = 0.85
    cardBorder.Parent = card
    
    if Settings["Preview"] == true then
        local viewport, dummy = createViewport(
            UDim2.fromScale(1, 0.5),
            UDim2.fromScale(0, 0),
            card
        )
        playAnimation(dummy, getanimid(item.Id))
    else
        local imgContainer = Instance.new("Frame")
        imgContainer.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 90))
        imgContainer.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
        imgContainer.BackgroundColor3 = MatchaColors.Background
        imgContainer.BackgroundTransparency = 0.5
        imgContainer.ZIndex = 2
        imgContainer.Parent = card
        createCorner(imgContainer, 8)
        
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Fit
        img.Image = "rbxthumb://type=Asset&id=11768914234&w=150&h=150"
        img.ZIndex = 3
        img.Parent = imgContainer
    end
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    name.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 100))
    name.BackgroundTransparency = 1
    name.Text = item.Name or "Unknown"
    name.TextSize = 11
    name.TextScaled = false
    name.TextWrapped = true
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = MatchaColors.Text
    name.ZIndex = 3
    name.Parent = card
    
    local favBtn = Instance.new("TextButton")
    favBtn.Size = UDim2.new(0, scale("X", 28), 0, scale("Y", 28))
    favBtn.Position = UDim2.new(1, -scale("X", 34), 0, scale("Y", 8))
    favBtn.Text = item.Favorite and "★" or "☆"
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 18
    favBtn.TextScaled = false
    favBtn.TextColor3 = MatchaColors.Accent
    favBtn.BackgroundTransparency = 1
    favBtn.ZIndex = 4
    favBtn.Parent = card
    
    favBtn.MouseButton1Click:Connect(function()
        item.Favorite = not item.Favorite
        favBtn.Text = item.Favorite and "★" or "☆"
        TweenService:Create(favBtn, TweenInfo.new(0.2), {
            Rotation = item.Favorite and 360 or 0
        }):Play()
        task.wait(0.2)
        favBtn.Rotation = 0
        saveEmotesToData()
    end)
    
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 26))
    copyBtn.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 132))
    copyBtn.BackgroundColor3 = MatchaColors.Background
    copyBtn.BackgroundTransparency = 0.3
    copyBtn.Text = "📋 Copy ID"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 11
    copyBtn.TextScaled = false
    copyBtn.TextColor3 = MatchaColors.Text
    copyBtn.AutoButtonColor = false
    copyBtn.ZIndex = 3
    copyBtn.Parent = card
    createCorner(copyBtn, 8)
    
    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(item.AnimationId:gsub("rbxassetid://", ""))
        end
        copyBtn.Text = "✓ Copied!"
        copyBtn.BackgroundColor3 = MatchaColors.Success
        TweenService:Create(copyBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        task.wait(0.7)
        copyBtn.Text = "📋 Copy ID"
        TweenService:Create(copyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = MatchaColors.Background,
            BackgroundTransparency = 0.3
        }):Play()
    end)
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 28))
    buttonContainer.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 33))
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = 2
    buttonContainer.Parent = card
    
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.48, 0, 1, 0)
    playBtn.Position = UDim2.new(0, 0, 0, 0)
    playBtn.BackgroundColor3 = MatchaColors.Secondary
    playBtn.Text = "▶ Play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 12
    playBtn.TextScaled = false
    playBtn.TextColor3 = MatchaColors.Surface
    playBtn.AutoButtonColor = false
    playBtn.ZIndex = 3
    playBtn.Parent = buttonContainer
    createCorner(playBtn, 8)
    
    playBtn.MouseEnter:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Dark}):Play()
    end)
    playBtn.MouseLeave:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Secondary}):Play()
    end)
    
    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(item.Id)
    end)
    
    local removeBtn = Instance.new("TextButton")
    removeBtn.Size = UDim2.new(0.48, 0, 1, 0)
    removeBtn.Position = UDim2.new(0.52, 0, 0, 0)
    removeBtn.BackgroundColor3 = MatchaColors.Error
    removeBtn.Text = "🗑️ Remove"
    removeBtn.Font = Enum.Font.GothamBold
    removeBtn.TextSize = 11
    removeBtn.TextScaled = false
    removeBtn.TextColor3 = MatchaColors.Surface
    removeBtn.AutoButtonColor = false
    removeBtn.ZIndex = 3
    removeBtn.Parent = buttonContainer
    createCorner(removeBtn, 8)
    
    removeBtn.MouseEnter:Connect(function()
        TweenService:Create(removeBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(150, 90, 85)
        }):Play()
    end)
    removeBtn.MouseLeave:Connect(function()
        TweenService:Create(removeBtn, TweenInfo.new(0.2), {BackgroundColor3 = MatchaColors.Error}):Play()
    end)
    
    removeBtn.MouseButton1Click:Connect(function()
        for i, saved in ipairs(savedEmotes) do
            if saved.Id == item.Id then
                table.remove(savedEmotes, i)
                saveEmotesToData()
                refreshSavedTab()
                break
            end
        end
    end)
    
    return card
end

function refreshSavedTab()
    for _, child in ipairs(savedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local text = (savedSearch.Text or ""):lower()
    local results = {}
    for _, item in ipairs(savedEmotes) do
        if text == "" or (item.Name and item.Name:lower():find(text)) then
            table.insert(results, item)
        end
    end
    table.sort(results, function(a, b)
        if a.Favorite ~= b.Favorite then
            return a.Favorite
        else
            return false
        end
    end)
    if #results > 0 then
        savedEmptyLabel.Visible = false
        for _, item in ipairs(results) do
            createSavedCard(item).Parent = savedScroll
        end
    else
        savedEmptyLabel.Visible = true
    end
    savedScroll.CanvasSize = UDim2.new(0, 0, 0, savedLayout.AbsoluteContentSize.Y + 8)
end

savedSearch:GetPropertyChangedSignal("Text"):Connect(refreshSavedTab)

savedTabBtn.MouseButton1Click:Connect(function()
    catalogFrame.Visible = false
    savedFrame.Visible = true
    animateTab(true)
    refreshSavedTab()
end)

local function doNewSearchInitial()
    doNewSearch("")
end

doNewSearchInitial()

local targetGui = gui

local function toggleGui()
    targetGui.Enabled = not targetGui.Enabled
end

-- Modern Toggle Button with Matcha Theme
local screonGui = Instance.new("ScreenGui")
screonGui.Name = "ToggleButtonGui"
screonGui.ResetOnSpawn = false
screonGui.Parent = CoreGui
screonGui.Enabled = true

local btn = Instance.new("TextButton")
btn.Parent = screonGui
btn.Text = "🍵"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 26
btn.TextScaled = false
btn.Size = UDim2.new(0, 56, 0, 56)
btn.Position = UDim2.new(0, 20, 0.5, -28)
btn.AnchorPoint = Vector2.new(0, 0.5)
btn.BackgroundColor3 = MatchaColors.Primary
btn.TextColor3 = MatchaColors.Surface
btn.Active = true
btn.AutoButtonColor = false
pcall(function() btn.Draggable = true end)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.Parent = btn
aspect.AspectRatio = 1
local corner = Instance.new("UICorner")
corner.Parent = btn
corner.CornerRadius = UDim.new(0, 16)

-- Button gradient
local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new(MatchaColors.Secondary, MatchaColors.Primary)
btnGrad.Rotation = 135
btnGrad.Parent = btn

-- Button shadow
local btnShadow = Instance.new("ImageLabel")
btnShadow.Name = "Shadow"
btnShadow.BackgroundTransparency = 1
btnShadow.Position = UDim2.new(0, -10, 0, -10)
btnShadow.Size = UDim2.new(1, 20, 1, 20)
btnShadow.Image = "rbxassetid://1316045217"
btnShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
btnShadow.ImageTransparency = 0.8
btnShadow.ScaleType = Enum.ScaleType.Slice
btnShadow.SliceCenter = Rect.new(10, 10, 118, 118)
btnShadow.ZIndex = 0
btnShadow.Parent = btn

-- Hover effects
btn.MouseEnter:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 60, 0, 60),
        BackgroundColor3 = MatchaColors.Secondary
    }):Play()
end)

btn.MouseLeave:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 56, 0, 56),
        BackgroundColor3 = MatchaColors.Primary
    }):Play()
end)

local btnFrame = btn.Parent

local function clampButtonPosition()
    local parentSize = btnFrame.AbsoluteSize
    local btnSize = btn.AbsoluteSize

    local clampedX = math.clamp(btn.Position.X.Scale * parentSize.X + btn.Position.X.Offset, 0, parentSize.X - btnSize.X)
    local clampedY = math.clamp(btn.Position.Y.Scale * parentSize.Y + btn.Position.Y.Offset, 0, parentSize.Y - btnSize.Y)

    btn.Position = UDim2.new(0, clampedX, 0, clampedY)
end

btn:GetPropertyChangedSignal("Position"):Connect(clampButtonPosition)

btn.MouseButton1Click:Connect(function()
    toggleGui()
    TweenService:Create(btn, TweenInfo.new(0.1), {Rotation = 360}):Play()
    task.wait(0.1)
    btn.Rotation = 0
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.G then
        toggleGui()
    end
end)

gui.Enabled = true
refreshSavedTab()