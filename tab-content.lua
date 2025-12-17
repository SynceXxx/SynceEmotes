--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         SYNCE EMOTES - TAB CONTENT MODULE                 ║
    ║           Catalog, Saved, Settings UI Logic              ║
    ╚═══════════════════════════════════════════════════════════╝
]]

print("🎨 Loading Tab Content Module...")

-- ═══════════════════════════════════════════════════════════
--                      MODULE SETUP
-- ═══════════════════════════════════════════════════════════
local TabContent = {}

-- Services (will be passed from main.lua)
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════
--                    HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createGradient(parent, rotation, colorStart, colorEnd)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colorStart, colorEnd)
    gradient.Rotation = rotation or 45
    gradient.Parent = parent
    return gradient
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- ═══════════════════════════════════════════════════════════
--               VIEWPORT PREVIEW HELPER
-- ═══════════════════════════════════════════════════════════
local function createMiniViewport(size, position, parent, animId, Features)
    if not Features.Settings["Preview"] then return nil end
    
    local viewportContainer = Instance.new("Frame")
    viewportContainer.Size = size
    viewportContainer.Position = position
    viewportContainer.BackgroundTransparency = 1
    viewportContainer.Parent = parent
    
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.Parent = viewportContainer
    
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    viewport.CurrentCamera = camera
    
    local dummy = Players:CreateHumanoidModelFromUserId(Players.LocalPlayer.UserId)
    dummy.Parent = worldModel
    
    local hrp = dummy:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Transparency = 1 end
    
    for _, part in ipairs(dummy:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local root = dummy.PrimaryPart or hrp
    if root then
        dummy.PrimaryPart = root
        dummy:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
        camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 6), root.Position)
    end
    
    -- Load animation
    local dummyHumanoid = dummy:FindFirstChildWhichIsA("Humanoid")
    if dummyHumanoid and animId then
        if not dummyHumanoid:FindFirstChildOfClass("Animator") then
            Instance.new("Animator", dummyHumanoid)
        end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. tostring(animId)
        
        local animator = dummyHumanoid:FindFirstChildOfClass("Animator")
        local animTrack = animator:LoadAnimation(animation)
        animTrack.Looped = true
        animTrack:Play()
        
        -- Rotation
        local rotationAngle = 0
        RunService.RenderStepped:Connect(function(dt)
            if root then
                rotationAngle = rotationAngle + math.rad(25) * dt
                local x = math.sin(rotationAngle) * 5
                local z = math.cos(rotationAngle) * 5
                camera.CFrame = CFrame.new(root.Position + Vector3.new(x, 2.5, z), root.Position)
            end
        end)
    end
    
    return viewportContainer
end

-- ═══════════════════════════════════════════════════════════
--                    CATALOG TAB CONTENT
-- ═══════════════════════════════════════════════════════════
function TabContent.Catalog(container, Features, Theme, scale, Animations)
    local catalogFrame = Instance.new("Frame")
    catalogFrame.Name = "CatalogContent"
    catalogFrame.Size = UDim2.new(1, 0, 1, 0)
    catalogFrame.BackgroundTransparency = 1
    catalogFrame.Parent = container
    
    -- Search Bar & Controls
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(1, 0, 0, scale("Y", 40))
    searchContainer.BackgroundTransparency = 1
    searchContainer.Parent = catalogFrame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.5, -scale("X", 5), 1, 0)
    searchBox.BackgroundColor3 = Theme.Surface
    searchBox.PlaceholderText = "🔍 Search emotes..."
    searchBox.PlaceholderColor3 = Theme.TextDisabled
    searchBox.Text = ""
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = scale("Y", 14)
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    createCorner(searchBox, 10)
    createStroke(searchBox, Theme.Primary, 2)
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.25, -scale("X", 5), 1, 0)
    refreshBtn.Position = UDim2.new(0.5, scale("X", 5), 0, 0)
    refreshBtn.BackgroundColor3 = Theme.Primary
    refreshBtn.Text = "🔄 Refresh"
    refreshBtn.TextColor3 = Theme.TextPrimary
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = scale("Y", 13)
    refreshBtn.Parent = searchContainer
    createCorner(refreshBtn, 10)
    
    local sortBtn = Instance.new("TextButton")
    sortBtn.Size = UDim2.new(0.25, -scale("X", 5), 1, 0)
    sortBtn.Position = UDim2.new(0.75, scale("X", 5), 0, 0)
    sortBtn.BackgroundColor3 = Theme.Secondary
    sortBtn.Text = "📊 Sort: Updated"
    sortBtn.TextColor3 = Theme.TextPrimary
    sortBtn.Font = Enum.Font.GothamBold
    sortBtn.TextSize = scale("Y", 13)
    sortBtn.Parent = searchContainer
    createCorner(sortBtn, 10)
    
    -- Scroll Frame for Emotes
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -scale("Y", 95))
    scrollFrame.Position = UDim2.new(0, 0, 0, scale("Y", 50))
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Theme.Primary
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = catalogFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, scale("X", 140), 0, scale("Y", 200))
    gridLayout.CellPadding = UDim2.new(0, scale("X", 10), 0, scale("Y", 10))
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent = scrollFrame
    
    -- Empty State
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 50))
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 25))
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "🌊 No emotes found"
    emptyLabel.TextColor3 = Theme.TextSecondary
    emptyLabel.Font = Enum.Font.GothamBold
    emptyLabel.TextSize = scale("Y", 18)
    emptyLabel.Visible = false
    emptyLabel.Parent = scrollFrame
    
    -- Pagination Controls
    local paginationFrame = Instance.new("Frame")
    paginationFrame.Size = UDim2.new(1, 0, 0, scale("Y", 40))
    paginationFrame.Position = UDim2.new(0, 0, 1, -scale("Y", 40))
    paginationFrame.BackgroundTransparency = 1
    paginationFrame.Parent = catalogFrame
    
    local prevBtn = Instance.new("TextButton")
    prevBtn.Size = UDim2.new(0.3, -scale("X", 5), 1, 0)
    prevBtn.BackgroundColor3 = Theme.Surface
    prevBtn.Text = "◀ Previous"
    prevBtn.TextColor3 = Theme.TextPrimary
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.TextSize = scale("Y", 12)
    prevBtn.Parent = paginationFrame
    createCorner(prevBtn, 10)
    
    local pageLabel = Instance.new("TextLabel")
    pageLabel.Size = UDim2.new(0.4, -scale("X", 10), 1, 0)
    pageLabel.Position = UDim2.new(0.3, scale("X", 5), 0, 0)
    pageLabel.BackgroundTransparency = 1
    pageLabel.Text = "Page 1"
    pageLabel.TextColor3 = Theme.TextPrimary
    pageLabel.Font = Enum.Font.GothamBold
    pageLabel.TextSize = scale("Y", 14)
    pageLabel.Parent = paginationFrame
    
    local nextBtn = Instance.new("TextButton")
    nextBtn.Size = UDim2.new(0.3, -scale("X", 5), 1, 0)
    nextBtn.Position = UDim2.new(0.7, scale("X", 5), 0, 0)
    nextBtn.BackgroundColor3 = Theme.Surface
    nextBtn.Text = "Next ▶"
    nextBtn.TextColor3 = Theme.TextPrimary
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = scale("Y", 12)
    nextBtn.Parent = paginationFrame
    createCorner(nextBtn, 10)
    
    -- Card Creation Function
    local function createEmoteCard(item)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, scale("X", 140), 0, scale("Y", 200))
        card.BackgroundColor3 = Theme.Surface
        card.Parent = scrollFrame
        createCorner(card, 12)
        
        -- Image/Preview
        if Features.Settings["Preview"] then
            createMiniViewport(
                UDim2.new(1, -scale("X", 10), 0, scale("Y", 100)),
                UDim2.new(0, scale("X", 5), 0, scale("Y", 5)),
                card,
                Features.GetAnimationId(item.id),
                Features
            )
        else
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 100))
            img.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
            img.BackgroundColor3 = Theme.Background
            img.Image = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150"
            img.ScaleType = Enum.ScaleType.Fit
            img.Parent = card
            createCorner(img, 10)
        end
        
        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 35))
        nameLabel.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 110))
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name or "Unknown"
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = scale("Y", 12)
        nameLabel.TextWrapped = true
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card
        
        -- Play Button
        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.new(0.48, 0, 0, scale("Y", 30))
        playBtn.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 35))
        playBtn.BackgroundColor3 = Theme.Success
        playBtn.Text = "▶ Play"
        playBtn.TextColor3 = Theme.TextPrimary
        playBtn.Font = Enum.Font.GothamBold
        playBtn.TextSize = scale("Y", 11)
        playBtn.Parent = card
        createCorner(playBtn, 8)
        
        playBtn.MouseButton1Click:Connect(function()
            Features.LoadTrack(item.id)
            playBtn.Text = "✓ Playing"
            TweenService:Create(playBtn, Animations.Quick, {BackgroundColor3 = Theme.Accent}):Play()
            wait(1)
            playBtn.Text = "▶ Play"
            TweenService:Create(playBtn, Animations.Quick, {BackgroundColor3 = Theme.Success}):Play()
        end)
        
        -- Save Button
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0.48, 0, 0, scale("Y", 30))
        saveBtn.Position = UDim2.new(0.52, scale("X", 5), 1, -scale("Y", 35))
        saveBtn.BackgroundColor3 = Theme.Primary
        saveBtn.Text = "💾 Save"
        saveBtn.TextColor3 = Theme.TextPrimary
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = scale("Y", 11)
        saveBtn.Parent = card
        createCorner(saveBtn, 8)
        
        saveBtn.MouseButton1Click:Connect(function()
            local alreadySaved = false
            for _, saved in ipairs(Features.savedEmotes) do
                if saved.Id == item.id then
                    alreadySaved = true
                    break
                end
            end
            
            if not alreadySaved then
                table.insert(Features.savedEmotes, {
                    Id = item.id,
                    Name = item.name or "Unknown",
                    AnimationId = "rbxassetid://" .. Features.GetAnimationId(item.id),
                    Favorite = false
                })
                Features.saveEmotesToData()
                saveBtn.Text = "✓ Saved"
                TweenService:Create(saveBtn, Animations.Quick, {BackgroundColor3 = Theme.Success}):Play()
                wait(1.5)
                saveBtn.Text = "💾 Save"
                TweenService:Create(saveBtn, Animations.Quick, {BackgroundColor3 = Theme.Primary}):Play()
            else
                saveBtn.Text = "Already Saved"
                wait(1)
                saveBtn.Text = "💾 Save"
            end
        end)
        
        return card
    end
    
    -- Display Function
    local function displayPage()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and child ~= emptyLabel then
                child:Destroy()
            end
        end
        
        local start_index = (Features.CURRENT_PAGE_NUMBER - 1) * Features.PAGE_SIZE + 1
        local end_index = start_index + Features.PAGE_SIZE - 1
        
        if start_index > #Features.ITEM_CACHE and Features.NEXT_API_CURSOR then
            Features.GetEmoteDataFromWeb()
        end
        
        local hasItems = false
        for i = start_index, math.min(end_index, #Features.ITEM_CACHE) do
            local item = Features.ITEM_CACHE[i]
            if item then
                createEmoteCard(item)
                hasItems = true
            end
        end
        
        emptyLabel.Visible = not hasItems
        pageLabel.Text = "Page " .. Features.CURRENT_PAGE_NUMBER
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- Search Function
    local function doSearch(keyword)
        Features.CURRENT_SEARCH_TEXT = keyword or ""
        Features.CURRENT_PAGE_NUMBER = 1
        Features.NEXT_API_CURSOR = nil
        Features.ITEM_CACHE = {}
        Features.GetEmoteDataFromWeb()
        displayPage()
    end
    
    -- Sort Cycling
    local currentSortIndex = 1
    sortBtn.MouseButton1Click:Connect(function()
        currentSortIndex = currentSortIndex % #Features.SORT_OPTIONS + 1
        Features.CURRENT_SORT_OPTION = Features.SORT_OPTIONS[currentSortIndex]
        sortBtn.Text = "📊 Sort: " .. Features.CURRENT_SORT_OPTION
        doSearch(Features.CURRENT_SEARCH_TEXT)
    end)
    
    -- Button Events
    refreshBtn.MouseButton1Click:Connect(function() doSearch(searchBox.Text) end)
    searchBox.FocusLost:Connect(function(enter) if enter then doSearch(searchBox.Text) end end)
    
    prevBtn.MouseButton1Click:Connect(function()
        if Features.CURRENT_PAGE_NUMBER > 1 then
            Features.CURRENT_PAGE_NUMBER = Features.CURRENT_PAGE_NUMBER - 1
            displayPage()
        end
    end)
    
    nextBtn.MouseButton1Click:Connect(function()
        local canGoNext = ((Features.CURRENT_PAGE_NUMBER * Features.PAGE_SIZE) < #Features.ITEM_CACHE) or Features.NEXT_API_CURSOR
        if canGoNext then
            Features.CURRENT_PAGE_NUMBER = Features.CURRENT_PAGE_NUMBER + 1
            displayPage()
        end
    end)
    
    -- Initial Load
    doSearch("")
end

-- ═══════════════════════════════════════════════════════════
--                    SAVED TAB CONTENT
-- ═══════════════════════════════════════════════════════════
function TabContent.Saved(container, Features, Theme, scale, Animations)
    local savedFrame = Instance.new("Frame")
    savedFrame.Name = "SavedContent"
    savedFrame.Size = UDim2.new(1, 0, 1, 0)
    savedFrame.BackgroundTransparency = 1
    savedFrame.Parent = container
    
    -- Search Bar
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, 0, 0, scale("Y", 40))
    searchBox.BackgroundColor3 = Theme.Surface
    searchBox.PlaceholderText = "🔍 Search saved emotes..."
    searchBox.PlaceholderColor3 = Theme.TextDisabled
    searchBox.Text = ""
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = scale("Y", 14)
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = savedFrame
    createCorner(searchBox, 10)
    createStroke(searchBox, Theme.Primary, 2)
    
    -- Scroll Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -scale("Y", 50))
    scrollFrame.Position = UDim2.new(0, 0, 0, scale("Y", 50))
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Theme.Primary
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = savedFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, scale("X", 140), 0, scale("Y", 220))
    gridLayout.CellPadding = UDim2.new(0, scale("X", 10), 0, scale("Y", 10))
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent = scrollFrame
    
    -- Empty State
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 80))
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 40))
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "⭐ No saved emotes yet\nSave emotes from Catalog tab!"
    emptyLabel.TextColor3 = Theme.TextSecondary
    emptyLabel.Font = Enum.Font.GothamBold
    emptyLabel.TextSize = scale("Y", 16)
    emptyLabel.Visible = false
    emptyLabel.Parent = scrollFrame
    
    -- Create Saved Card Function
    local function createSavedCard(item)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, scale("X", 140), 0, scale("Y", 220))
        card.BackgroundColor3 = Theme.Surface
        card.Parent = scrollFrame
        createCorner(card, 12)
        
        -- Favorite Button (Top Right)
        local favBtn = Instance.new("TextButton")
        favBtn.Size = UDim2.new(0, scale("X", 30), 0, scale("Y", 30))
        favBtn.Position = UDim2.new(1, -scale("X", 35), 0, scale("Y", 5))
        favBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        favBtn.Text = item.Favorite and "★" or "☆"
        favBtn.TextSize = scale("Y", 16)
        favBtn.Parent = card
        createCorner(favBtn, 8)
        
        favBtn.MouseButton1Click:Connect(function()
            item.Favorite = not item.Favorite
            favBtn.Text = item.Favorite and "★" or "☆"
            Features.saveEmotesToData()
            -- Refresh to re-sort
            task.wait(0.1)
            refreshSavedTab()
        end)
        
        -- Image/Preview
        if Features.Settings["Preview"] then
            createMiniViewport(
                UDim2.new(1, -scale("X", 10), 0, scale("Y", 100)),
                UDim2.new(0, scale("X", 5), 0, scale("Y", 5)),
                card,
                Features.GetAnimationId(item.Id),
                Features
            )
        else
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 100))
            img.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
            img.BackgroundColor3 = Theme.Background
            img.Image = "rbxthumb://type=Asset&id=" .. item.Id .. "&w=150&h=150"
            img.ScaleType = Enum.ScaleType.Fit
            img.Parent = card
            createCorner(img, 10)
        end
        
        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 35))
        nameLabel.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 110))
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.Name or "Unknown"
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = scale("Y", 12)
        nameLabel.TextWrapped = true
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card
        
        -- Copy AnimID Button
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 25))
        copyBtn.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 150))
        copyBtn.BackgroundColor3 = Theme.Secondary
        copyBtn.Text = "📋 Copy ID"
        copyBtn.TextColor3 = Theme.TextPrimary
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = scale("Y", 10)
        copyBtn.Parent = card
        createCorner(copyBtn, 8)
        
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                local animId = item.AnimationId:gsub("rbxassetid://", "")
                setclipboard(animId)
                copyBtn.Text = "✓ Copied!"
                TweenService:Create(copyBtn, Animations.Quick, {BackgroundColor3 = Theme.Success}):Play()
                wait(1.5)
                copyBtn.Text = "📋 Copy ID"
                TweenService:Create(copyBtn, Animations.Quick, {BackgroundColor3 = Theme.Secondary}):Play()
            end
        end)
        
        -- Play Button
        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.new(0.48, 0, 0, scale("Y", 30))
        playBtn.Position = UDim2.new(0, scale("X", 5), 1, -scale("Y", 35))
        playBtn.BackgroundColor3 = Theme.Success
        playBtn.Text = "▶ Play"
        playBtn.TextColor3 = Theme.TextPrimary
        playBtn.Font = Enum.Font.GothamBold
        playBtn.TextSize = scale("Y", 11)
        playBtn.Parent = card
        createCorner(playBtn, 8)
        
        playBtn.MouseButton1Click:Connect(function()
            Features.LoadTrack(item.Id)
            playBtn.Text = "✓ Playing"
            TweenService:Create(playBtn, Animations.Quick, {BackgroundColor3 = Theme.Accent}):Play()
            wait(1)
            playBtn.Text = "▶ Play"
            TweenService:Create(playBtn, Animations.Quick, {BackgroundColor3 = Theme.Success}):Play()
        end)
        
        -- Remove Button
        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0.48, 0, 0, scale("Y", 30))
        removeBtn.Position = UDim2.new(0.52, scale("X", 5), 1, -scale("Y", 35))
        removeBtn.BackgroundColor3 = Theme.Error
        removeBtn.Text = "🗑 Remove"
        removeBtn.TextColor3 = Theme.TextPrimary
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = scale("Y", 11)
        removeBtn.Parent = card
        createCorner(removeBtn, 8)
        
        removeBtn.MouseButton1Click:Connect(function()
            for i, saved in ipairs(Features.savedEmotes) do
                if saved.Id == item.Id then
                    table.remove(Features.savedEmotes, i)
                    Features.saveEmotesToData()
                    refreshSavedTab()
                    break
                end
            end
        end)
        
        return card
    end
    
    -- Refresh Function
    function refreshSavedTab()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and child ~= emptyLabel then
                child:Destroy()
            end
        end
        
        local searchText = searchBox.Text:lower()
        local filtered = {}
        
        -- Filter by search
        for _, item in ipairs(Features.savedEmotes) do
            if searchText == "" or (item.Name and item.Name:lower():find(searchText)) then
                table.insert(filtered, item)
            end
        end
        
        -- Sort: Favorites first
        table.sort(filtered, function(a, b)
            if a.Favorite ~= b.Favorite then
                return a.Favorite
            end
            return false
        end)
        
        -- Display
        if #filtered > 0 then
            emptyLabel.Visible = false
            for _, item in ipairs(filtered) do
                createSavedCard(item)
            end
        else
            emptyLabel.Visible = true
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- Search Event
    searchBox:GetPropertyChangedSignal("Text"):Connect(refreshSavedTab)
    
    -- Initial Load
    refreshSavedTab()
end

-- ═══════════════════════════════════════════════════════════
--                   SETTINGS TAB CONTENT
-- ═══════════════════════════════════════════════════════════
function TabContent.Settings(container, Features, Theme, scale, Animations)
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsContent"
    settingsFrame.Size = UDim2.new(1, 0, 1, 0)
    settingsFrame.BackgroundTransparency = 1
    settingsFrame.Parent = container
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, scale("Y", 30))
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚙️ Animation Settings"
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = scale("Y", 18)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = settingsFrame
    
    -- Scroll Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -scale("X", 10), 1, -scale("Y", 40))
    scrollFrame.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 35))
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Theme.Primary
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = settingsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- ═══════════════════════════════════════════════════════
    --                 SLIDER CREATOR
    -- ═══════════════════════════════════════════════════════
    local function createSlider(name, min, max, default)
        Features.Settings[name] = default or min
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, scale("Y", 70))
        container.BackgroundColor3 = Theme.Surface
        container.Parent = scrollFrame
        createCorner(container, 10)
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, -scale("X", 10), 0, scale("Y", 20))
        label.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 5))
        label.BackgroundTransparency = 1
        label.Text = string.format("%s: %.2f", name, Features.Settings[name])
        label.TextColor3 = Theme.TextPrimary
        label.Font = Enum.Font.GothamBold
        label.TextSize = scale("Y", 12)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        
        -- TextBox Input
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(0.4, -scale("X", 20), 0, scale("Y", 20))
        textBox.Position = UDim2.new(0.6, scale("X", 10), 0, scale("Y", 5))
        textBox.BackgroundColor3 = Theme.Elevated
        textBox.Text = tostring(Features.Settings[name])
        textBox.TextColor3 = Theme.TextPrimary
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = scale("Y", 11)
        textBox.ClearTextOnFocus = false
        textBox.Parent = container
        createCorner(textBox, 6)
        createStroke(textBox, Theme.Primary, 1)
        
        -- Slider Bar
        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(1, -scale("X", 40), 0, scale("Y", 12))
        sliderBar.Position = UDim2.new(0, scale("X", 20), 0, scale("Y", 40))
        sliderBar.BackgroundColor3 = Theme.Elevated
        sliderBar.Parent = container
        createCorner(sliderBar, 6)
        
        -- Slider Fill
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new(0, 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.Accent
        sliderFill.Parent = sliderBar
        createCorner(sliderFill, 6)
        createGradient(sliderFill, 90, Theme.Primary, Theme.Accent)
        
        -- Thumb
        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.new(0, scale("X", 20), 0, scale("Y", 20))
        thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        thumb.Position = UDim2.new(0, 0, 0.5, 0)
        thumb.BackgroundColor3 = Theme.TextPrimary
        thumb.Parent = sliderBar
        createCorner(thumb, 10)
        
        -- Apply Value Function
        local function applyValue(value)
            Features.Settings[name] = math.clamp(value, min, max)
            label.Text = string.format("%s: %.2f", name, Features.Settings[name])
            textBox.Text = tostring(Features.Settings[name])
            
            local rel = (Features.Settings[name] - min) / (max - min)
            TweenService:Create(sliderFill, Animations.Quick, {Size = UDim2.new(rel, 0, 1, 0)}):Play()
            TweenService:Create(thumb, Animations.Quick, {Position = UDim2.new(rel, 0, 0.5, 0)}):Play()
            
            -- Apply to current track
            if Features.CurrentTrack and Features.CurrentTrack.IsPlaying then
                if name == "Speed" then
                    Features.CurrentTrack:AdjustSpeed(Features.Settings["Speed"])
                elseif name == "Weight" then
                    local weight = Features.Settings["Weight"]
                    if weight == 0 then weight = 0.001 end
                    Features.CurrentTrack:AdjustWeight(weight)
                elseif name == "Time Position" then
                    if Features.CurrentTrack.Length > 0 then
                        Features.CurrentTrack.TimePosition = math.clamp(value, 0, 1) * Features.CurrentTrack.Length
                    end
                end
            end
        end
        
        -- Dragging
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
            end
        end)
        
        thumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
            end
        end)
        
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local num = tonumber(textBox.Text)
                if num then
                    applyValue(num)
                else
                    textBox.Text = tostring(Features.Settings[name])
                end
            end
        end)
        
        Features.Settings._sliders[name] = applyValue
        applyValue(Features.Settings[name])
    end
    
    -- ═══════════════════════════════════════════════════════
    --                 TOGGLE CREATOR
    -- ═══════════════════════════════════════════════════════
    local function createToggle(name)
        Features.Settings[name] = Features.Settings[name] or false
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, scale("Y", 45))
        container.BackgroundColor3 = Theme.Surface
        container.Parent = scrollFrame
        createCorner(container, 10)
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, -scale("X", 10), 1, 0)
        label.Position = UDim2.new(0, scale("X", 10), 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Theme.TextPrimary
        label.Font = Enum.Font.GothamBold
        label.TextSize = scale("Y", 12)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        
        -- Toggle Button
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, scale("X", 70), 0, scale("Y", 28))
        toggleBtn.Position = UDim2.new(1, -scale("X", 80), 0.5, -scale("Y", 14))
        toggleBtn.TextColor3 = Theme.TextPrimary
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = scale("Y", 11)
        toggleBtn.Parent = container
        createCorner(toggleBtn, 14)
        
        local function applyVisual(state)
            toggleBtn.Text = state and "ON" or "OFF"
            TweenService:Create(toggleBtn, Animations.Quick, {
                BackgroundColor3 = state and Theme.Success or Theme.Error
            }):Play()
        end
        
        toggleBtn.MouseButton1Click:Connect(function()
            Features.Settings[name] = not Features.Settings[name]
            applyVisual(Features.Settings[name])
        end)
        
        applyVisual(Features.Settings[name])
        Features.Settings._toggles[name] = applyVisual
    end
    
    -- ═══════════════════════════════════════════════════════
    --                 BUTTON CREATOR
    -- ═══════════════════════════════════════════════════════
    local function createButton(name, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, scale("Y", 50))
        container.BackgroundColor3 = Theme.Surface
        container.Parent = scrollFrame
        createCorner(container, 10)
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -scale("X", 20), 1, -scale("Y", 10))
        button.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 5))
        button.BackgroundColor3 = Theme.Primary
        button.Text = name
        button.TextColor3 = Theme.TextPrimary
        button.Font = Enum.Font.GothamBold
        button.TextSize = scale("Y", 13)
        button.Parent = container
        createCorner(button, 8)
        createGradient(button, 90, Theme.Primary, Theme.Secondary)
        
        button.MouseButton1Click:Connect(function()
            if typeof(callback) == "function" then
                callback()
            end
        end)
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, Animations.Quick, {Size = UDim2.new(1, -scale("X", 15), 1, -scale("Y", 5))}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, Animations.Quick, {Size = UDim2.new(1, -scale("X", 20), 1, -scale("Y", 10))}):Play()
        end)
        
        return button
    end
    
    -- ═══════════════════════════════════════════════════════
    --              CREATE ALL SETTINGS
    -- ═══════════════════════════════════════════════════════
    createToggle("Preview")
    createToggle("Stop Emote When Moving")
    createToggle("Looped")
    createToggle("Stop Other Animations On Play")
    createToggle("Allow Invisible")
    
    createSlider("Speed", 0, 5, Features.Settings["Speed"])
    createSlider("Weight", 0, 1, Features.Settings["Weight"])
    createSlider("Time Position", 0, 1, Features.Settings["Time Position"])
    createSlider("Fade In", 0, 2, Features.Settings["Fade In"])
    createSlider("Fade Out", 0, 2, Features.Settings["Fade Out"])
    
    -- Reset Button
    local resetBtn = createButton("🔄 Reset All Settings to Default", function()
        Features.Settings["Stop Emote When Moving"] = true
        Features.Settings["Stop Other Animations On Play"] = true
        Features.Settings["Preview"] = false
        Features.Settings["Looped"] = true
        Features.Settings["Allow Invisible"] = true
        
        if Features.Settings._sliders["Fade In"] then Features.Settings._sliders["Fade In"](0.1) end
        if Features.Settings._sliders["Fade Out"] then Features.Settings._sliders["Fade Out"](0.1) end
        if Features.Settings._sliders["Weight"] then Features.Settings._sliders["Weight"](1) end
        if Features.Settings._sliders["Speed"] then Features.Settings._sliders["Speed"](1) end
        if Features.Settings._sliders["Time Position"] then Features.Settings._sliders["Time Position"](0) end
        
        if Features.Settings._toggles["Stop Emote When Moving"] then Features.Settings._toggles["Stop Emote When Moving"](true) end
        if Features.Settings._toggles["Stop Other Animations On Play"] then Features.Settings._toggles["Stop Other Animations On Play"](true) end
        if Features.Settings._toggles["Preview"] then Features.Settings._toggles["Preview"](false) end
        if Features.Settings._toggles["Looped"] then Features.Settings._toggles["Looped"](true) end
        if Features.Settings._toggles["Allow Invisible"] then Features.Settings._toggles["Allow Invisible"](true) end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    EDIT FUNCTIONS
-- ═══════════════════════════════════════════════════════════
function TabContent.EditSlider(targetName, newValue, Features)
    local apply = Features.Settings._sliders[targetName]
    if apply then
        apply(newValue)
    end
end

function TabContent.EditToggle(targetName, newValue, Features)
    local apply = Features.Settings._toggles[targetName]
    if apply then
        Features.Settings[targetName] = newValue
        apply(newValue)
    end
end

-- ═══════════════════════════════════════════════════════════
--                    MODULE EXPORT
-- ═══════════════════════════════════════════════════════════
print("✅ Tab Content Module Loaded Successfully!")

return TabContent