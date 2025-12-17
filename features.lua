--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║              SYNCE EMOTES - FEATURES MODULE               ║
    ║          All Functions, Settings & Utilities              ║
    ╚═══════════════════════════════════════════════════════════╝
]]

print("🔧 Loading Features Module...")

-- ═══════════════════════════════════════════════════════════
--                      SERVICES
-- ═══════════════════════════════════════════════════════════
local cloneref = cloneref or function(...) return ... end
local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local UserInputService = Services.UserInputService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

-- Update character reference on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
end)

-- ═══════════════════════════════════════════════════════════
--                      SETTINGS SYSTEM
-- ═══════════════════════════════════════════════════════════
local Settings = {
    ["Stop Emote When Moving"] = true,
    ["Fade In"] = 0.1,
    ["Fade Out"] = 0.1,
    ["Weight"] = 1,
    ["Speed"] = 1,
    ["Allow Invisible"] = true,
    ["Time Position"] = 0,
    ["Freeze On Finish"] = false,
    ["Looped"] = true,
    ["Stop Other Animations On Play"] = true,
    ["Preview"] = false,
    
    _sliders = {},
    _toggles = {}
}

-- ═══════════════════════════════════════════════════════════
--                   SAVED EMOTES SYSTEM
-- ═══════════════════════════════════════════════════════════
local savedEmotes = {}
local SAVE_FILE = "SynceEmotes_SaveData.json"

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
    
    -- Ensure all emotes have required fields
    for _, emote in ipairs(savedEmotes) do
        if not emote.AnimationId then
            if emote.AssetId then
                emote.AnimationId = "rbxassetid://" .. tostring(emote.AssetId)
            else
                emote.AnimationId = "rbxassetid://" .. tostring(emote.Id)
            end
        end
        if emote.Favorite == nil then
            emote.Favorite = false
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

-- ═══════════════════════════════════════════════════════════
--                   ANIMATION TRACK SYSTEM
-- ═══════════════════════════════════════════════════════════
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
        for _, t in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
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

local function GetAnimationId(assetId)
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
    return assetId
end

-- ═══════════════════════════════════════════════════════════
--                   MOVEMENT DETECTION
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
--                   COLLISION FIX SYSTEM
-- ═══════════════════════════════════════════════════════════
local originalCollisionStates = {}
local lastFixClipState = Settings["Allow Invisible"]

local function saveCollisionStates()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character.PrimaryPart then
            originalCollisionStates[part] = part.CanCollide
        end
    end
end

local function disableCollisionsExceptRootPart()
    if not Settings["Allow Invisible"] then return end
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
        local currentFixClip = Settings["Allow Invisible"]
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
        if connection then connection:Disconnect() end
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    restoreCollisionStates()
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    saveCollisionStates()
    lastFixClipState = Settings["Allow Invisible"]
    if connection then connection:Disconnect() end
    
    connection = RunService.Stepped:Connect(function()
        if character and character.Parent then
            local currentFixClip = Settings["Allow Invisible"]
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
            if connection then connection:Disconnect() end
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════
--                   CATALOG API SYSTEM
-- ═══════════════════════════════════════════════════════════
local CATALOG_URL = "https://catalog.roproxy.com/v2/search/items/details"
local EMOTE_ASSET_TYPE = 61
local BIG_FETCH_LIMIT = 120
local PAGE_SIZE = 10

local ITEM_CACHE = {}
local NEXT_API_CURSOR = nil
local CURRENT_PAGE_NUMBER = 1
local CURRENT_SORT_OPTION = "Updated"
local CURRENT_SEARCH_TEXT = ""
local SORT_OPTIONS = {"Updated", "Relevance", "Favorited", "Sales", "PriceAsc", "PriceDesc"}

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
    
    local response
    local success, result = pcall(function()
        return request({
            Url = final_url,
            Method = "GET"
        })
    end)

    if not success or not result or not result.Success then
        warn("[Synce API] Request failed")
        return false
    end

    response = result.Body
    
    local data_table
    success, data_table = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not success or not data_table or not data_table.data then
        warn("[Synce API] JSON parse failed")
        return false
    end

    for _, item in pairs(data_table.data) do
        table.insert(ITEM_CACHE, item)
    end
    
    NEXT_API_CURSOR = data_table.nextPageCursor
    return true
end

-- ═══════════════════════════════════════════════════════════
--                   VIEWPORT PREVIEW SYSTEM
-- ═══════════════════════════════════════════════════════════
local function createViewport(size, position, parent)
    local viewportContainer = Instance.new("Frame")
    viewportContainer.Size = size
    viewportContainer.Position = position
    viewportContainer.BackgroundTransparency = 1
    viewportContainer.Parent = parent
    
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, -4, 1, -4)
    viewport.Position = UDim2.new(0, 2, 0, 2)
    viewport.BackgroundTransparency = 1
    viewport.Parent = viewportContainer
    
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    viewport.CurrentCamera = camera
    
    local dummy = Players:CreateHumanoidModelFromUserId(player.UserId)
    dummy.Parent = worldModel
    
    local hrp = dummy:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Transparency = 1 end
    
    for _, part in ipairs(dummy:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local root = dummy.PrimaryPart or dummy:FindFirstChild("HumanoidRootPart")
    if root then
        dummy.PrimaryPart = root
        dummy:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
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
    
    -- Rotation animation
    local rotationAngle = 0
    local rotationSpeed = math.rad(30)
    
    RunService.RenderStepped:Connect(function(deltaTime)
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

-- ═══════════════════════════════════════════════════════════
--                      EXPORT MODULE
-- ═══════════════════════════════════════════════════════════
return {
    -- Settings
    Settings = Settings,
    
    -- Animation Functions
    LoadTrack = LoadTrack,
    GetAnimationId = GetAnimationId,
    CurrentTrack = CurrentTrack,
    
    -- Saved Emotes
    savedEmotes = savedEmotes,
    loadSavedEmotes = loadSavedEmotes,
    saveEmotesToData = saveEmotesToData,
    
    -- Catalog API
    GetEmoteDataFromWeb = GetEmoteDataFromWeb,
    ITEM_CACHE = ITEM_CACHE,
    NEXT_API_CURSOR = NEXT_API_CURSOR,
    CURRENT_PAGE_NUMBER = CURRENT_PAGE_NUMBER,
    CURRENT_SORT_OPTION = CURRENT_SORT_OPTION,
    CURRENT_SEARCH_TEXT = CURRENT_SEARCH_TEXT,
    SORT_OPTIONS = SORT_OPTIONS,
    PAGE_SIZE = PAGE_SIZE,
    
    -- Viewport
    createViewport = createViewport,
    playAnimation = playAnimation,
    
    -- Services
    Services = Services,
    Player = player,
    Character = character,
    Humanoid = humanoid
}