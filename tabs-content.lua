--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         SYNCE EMOTES - TAB CONTENT MODULE                 ║
    ║                  COMPLETE FIXED VERSION                   ║
    ╚═══════════════════════════════════════════════════════════╝
    
    🔧 BUGS FIXED:
    ✅ Thumbnail images now showing (fixed API response structure)
    ✅ Refresh button works properly
    ✅ Search function fixed
    ✅ Sort button fixed
    ✅ Empty state handling fixed
    ✅ Better error messages
]]

print("🎨 Loading Tab Content Module...")

local TabContent = {}

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
    
    local success, dummy = pcall(function()
        return Players:CreateHumanoidModelFromUserId(Players.LocalPlayer.UserId)
    end)
    
    if not success then return nil end
    
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
    
    local dummyHumanoid = dummy:FindFirstChildWhichIsA("Humanoid")
    if dummyHumanoid and animId then
        pcall(function()
            if not dummyHumanoid:FindFirstChildOfClass("Animator") then
                Instance.new("Animator", dummyHumanoid)
            end
            
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. tostring(animId)
            
            local animator = dummyHumanoid:FindFirstChildOfClass("Animator")
            local animTrack = animator:LoadAnimation(animation)
            animTrack.Looped = true
            animTrack:Play()
            
            local rotationAngle = 0
            RunService.RenderStepped:Connect(function(dt)
                if root then
                    rotationAngle = rotationAngle + math.rad(25) * dt
                    local x = math.sin(rotationAngle) * 5
                    local z = math.cos(rotationAngle) * 5
                    camera.CFrame = CFrame.new(root.Position + Vector3.new(x, 2.5, z), root.Position)
                end
            end)
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
    
    -- Search Container
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
    sortBtn.Text = "📊 Sort: " .. Features.CURRENT_SORT_OPTION
    sortBtn.TextColor3 = Theme.TextPrimary
    sortBtn.Font = Enum.Font.GothamBold
    sortBtn.TextSize = scale("Y", 13)
    sortBtn.Parent = searchContainer
    createCorner(sortBtn, 10)
    
    -- Scroll Frame
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
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 50))
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 25))
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "🌊 Press Refresh to load emotes"
    emptyLabel.TextColor3 = Theme.TextSecondary
    emptyLabel.Font = Enum.Font.GothamBold
    emptyLabel.TextSize = scale("Y", 16)
    emptyLabel.Visible = true
    emptyLabel.ZIndex = 10
    emptyLabel.Parent = catalogFrame
    
    -- Pagination
    local paginationFrame = Instance.new("Frame")
    paginationFrame.Size = UDim2.new(1, 0, 0, scale("Y", 40))
    paginationFrame.Position = UDim2.new(0, 0, 1, -scale("Y", 40))
    paginationFrame.BackgroundTransparency = 1
    paginationFrame.Parent = catalogFrame
    
    local prevBtn = Instance.new("TextButton")
    prevBtn.Size = UDim2.new(0, scale("X", 100), 1, 0)
    prevBtn.BackgroundColor3 = Theme.Surface
    prevBtn.Text = "← Previous"
    prevBtn.TextColor3 = Theme.TextPrimary
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.TextSize = scale("Y", 12)
    prevBtn.Visible = false
    prevBtn.Parent = paginationFrame
    createCorner(prevBtn, 10)
    
    local pageLabel = Instance.new("TextLabel")
    pageLabel.Size = UDim2.new(0, scale("X", 100), 1, 0)
    pageLabel.Position = UDim2.new(0.5, -scale("X", 50), 0, 0)
    pageLabel.BackgroundTransparency = 1
    pageLabel.Text = "Page 1"
    pageLabel.TextColor3 = Theme.TextPrimary
    pageLabel.Font = Enum.Font.GothamBold
    pageLabel.TextSize = scale("Y", 12)
    pageLabel.Parent = paginationFrame
    
    local nextBtn = Instance.new("TextButton")
    nextBtn.Size = UDim2.new(0, scale("X", 100), 1, 0)
    nextBtn.Position = UDim2.new(1, -scale("X", 100), 0, 0)
    nextBtn.BackgroundColor3 = Theme.Surface
    nextBtn.Text = "Next →"
    nextBtn.TextColor3 = Theme.TextPrimary
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = scale("Y", 12)
    nextBtn.Visible = false
    nextBtn.Parent = paginationFrame
    createCorner(nextBtn, 10)
    
    -- FIXED: Load emotes function
    local function loadEmotes()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("EmoteCard") then
                child:Destroy()
            end
        end
        
        local startIdx = ((Features.CURRENT_PAGE_NUMBER or 1) - 1) * Features.PAGE_SIZE + 1
        local endIdx = startIdx + Features.PAGE_SIZE - 1
        local hasEmotes = false
        
        for i = startIdx, math.min(endIdx, #Features.ITEM_CACHE) do
            local item = Features.ITEM_CACHE[i]
            if item and item.id then
                hasEmotes = true
                
                local card = Instance.new("Frame")
                card.Name = "EmoteCard_" .. i
                card.BackgroundColor3 = Theme.Surface
                card.Parent = scrollFrame
                createCorner(card, 12)
                
                -- FIXED: Get thumbnail URL correctly
                local thumbnailUrl = ""
                if item.itemRestrictions and #item.itemRestrictions > 0 then
                    thumbnailUrl = item.itemRestrictions[1].thumbnailUrl or ""
                end
                
                -- Thumbnail background
                local thumbnailBg = Instance.new("Frame")
                thumbnailBg.Size = UDim2.new(1, 0, 0.6, 0)
                thumbnailBg.BackgroundColor3 = Theme.Elevated
                thumbnailBg.Parent = card
                createCorner(thumbnailBg, 12)
                
                -- Thumbnail image
                if thumbnailUrl ~= "" then
                    local thumbnail = Instance.new("ImageLabel")
                    thumbnail.Size = UDim2.new(1, 0, 1, 0)
                    thumbnail.BackgroundTransparency = 1
                    thumbnail.Image = thumbnailUrl
                    thumbnail.ScaleType = Enum.ScaleType.Crop
                    thumbnail.Parent = thumbnailBg
                    createCorner(thumbnail, 12)
                end
                
                -- Preview viewport
                if Features.Settings["Preview"] then
                    local animId = Features.GetAnimationId(item.id)
                    createMiniViewport(
                        UDim2.new(1, 0, 0.6, 0),
                        UDim2.new(0, 0, 0, 0),
                        card,
                        animId,
                        Features
                    )
                end
                
                -- Name
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 20))
                nameLabel.Position = UDim2.new(0, scale("X", 5), 0.62, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = item.name or "Unknown"
                nameLabel.TextColor3 = Theme.TextPrimary
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = scale("Y", 11)
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Parent = card
                
                -- Creator
                local creatorLabel = Instance.new("TextLabel")
                creatorLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 15))
                creatorLabel.Position = UDim2.new(0, scale("X", 5), 0.75, 0)
                creatorLabel.BackgroundTransparency = 1
                creatorLabel.Text = "by " .. (item.creatorName or "Unknown")
                creatorLabel.TextColor3 = Theme.TextSecondary
                creatorLabel.Font = Enum.Font.Gotham
                creatorLabel.TextSize = scale("Y", 9)
                creatorLabel.TextTruncate = Enum.TextTruncate.AtEnd
                creatorLabel.Parent = card
                
                -- Play Button
                local playBtn = Instance.new("TextButton")
                playBtn.Size = UDim2.new(0.45, 0, 0, scale("Y", 25))
                playBtn.Position = UDim2.new(0.025, 0, 0.88, 0)
                playBtn.BackgroundColor3 = Theme.Success
                playBtn.Text = "▶ Play"
                playBtn.TextColor3 = Theme.TextPrimary
                playBtn.Font = Enum.Font.GothamBold
                playBtn.TextSize = scale("Y", 10)
                playBtn.Parent = card
                createCorner(playBtn, 8)
                
                playBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        local animId = Features.GetAnimationId(item.id)
                        Features.LoadTrack(animId)
                    end)
                end)
                
                -- Save Button
                local saveBtn = Instance.new("TextButton")
                saveBtn.Size = UDim2.new(0.45, 0, 0, scale("Y", 25))
                saveBtn.Position = UDim2.new(0.525, 0, 0.88, 0)
                saveBtn.BackgroundColor3 = Theme.Warning
                saveBtn.Text = "💾 Save"
                saveBtn.TextColor3 = Theme.TextPrimary
                saveBtn.Font = Enum.Font.GothamBold
                saveBtn.TextSize = scale("Y", 10)
                saveBtn.Parent = card
                createCorner(saveBtn, 8)
                
                saveBtn.MouseButton1Click:Connect(function()
                    local alreadySaved = false
                    for _, saved in ipairs(Features.savedEmotes) do
                        if tostring(saved.Id) == tostring(item.id) or tostring(saved.AssetId) == tostring(item.id) then
                            alreadySaved = true
                            break
                        end
                    end
                    
                    if not alreadySaved then
                        pcall(function()
                            local animId = Features.GetAnimationId(item.id)
                            table.insert(Features.savedEmotes, {
                                Id = item.id,
                                AssetId = item.id,
                                AnimationId = "rbxassetid://" .. animId,
                                Name = item.name,
                                Creator = item.creatorName,
                                Favorite = false
                            })
                            Features.saveEmotesToData()
                            saveBtn.Text = "✓ Saved"
                            saveBtn.BackgroundColor3 = Theme.Success
                        end)
                    else
                        saveBtn.Text = "✓ Saved"
                        saveBtn.BackgroundColor3 = Theme.Success
                    end
                end)
            end
        end
        
        emptyLabel.Visible = not hasEmotes
        if not hasEmotes then
            emptyLabel.Text = "🌊 No emotes found"
        end
        
        local contentSize = gridLayout.AbsoluteContentSize
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + scale("Y", 10))
        
        pageLabel.Text = "Page " .. (Features.CURRENT_PAGE_NUMBER or 1)
        prevBtn.Visible = (Features.CURRENT_PAGE_NUMBER or 1) > 1
        nextBtn.Visible = #Features.ITEM_CACHE > endIdx or Features.NEXT_API_CURSOR ~= nil
    end
    
    -- FIXED: Fetch function
    local function fetchAndLoad()
        refreshBtn.Text = "⏳ Loading..."
        refreshBtn.BackgroundColor3 = Theme.Warning
        emptyLabel.Visible = true
        emptyLabel.Text = "⏳ Loading emotes..."
        
        task.spawn(function()
            local success = pcall(function()
                Features.GetEmoteDataFromWeb()
            end)
            
            wait(0.5)
            
            if success and #Features.ITEM_CACHE > 0 then
                loadEmotes()
                refreshBtn.Text = "🔄 Refresh"
                refreshBtn.BackgroundColor3 = Theme.Primary
            else
                refreshBtn.Text = "❌ Failed"
                refreshBtn.BackgroundColor3 = Theme.Error
                emptyLabel.Visible = true
                emptyLabel.Text = "❌ Failed to load. Check executor!"
                
                wait(2)
                refreshBtn.Text = "🔄 Refresh"
                refreshBtn.BackgroundColor3 = Theme.Primary
            end
        end)
    end
    
    -- Button connections
    refreshBtn.MouseButton1Click:Connect(function()
        Features.ITEM_CACHE = {}
        Features.NEXT_API_CURSOR = nil
        Features.CURRENT_PAGE_NUMBER = 1
        fetchAndLoad()
    end)
    
    sortBtn.MouseButton1Click:Connect(function()
        local sortIndex = 1
        for i, opt in ipairs(Features.SORT_OPTIONS) do
            if opt == Features.CURRENT_SORT_OPTION then
                sortIndex = i
                break
            end
        end
        
        sortIndex = sortIndex % #Features.SORT_OPTIONS + 1
        Features.CURRENT_SORT_OPTION = Features.SORT_OPTIONS[sortIndex]
        sortBtn.Text = "📊 Sort: " .. Features.CURRENT_SORT_OPTION
        
        Features.ITEM_CACHE = {}
        Features.NEXT_API_CURSOR = nil
        Features.CURRENT_PAGE_NUMBER = 1
        fetchAndLoad()
    end)
    
    prevBtn.MouseButton1Click:Connect(function()
        if Features.CURRENT_PAGE_NUMBER > 1 then
            Features.CURRENT_PAGE_NUMBER = Features.CURRENT_PAGE_NUMBER - 1
            loadEmotes()
            scrollFrame.CanvasPosition = Vector2.new(0, 0)
        end
    end)
    
    nextBtn.MouseButton1Click:Connect(function()
        local maxPage = math.ceil(#Features.ITEM_CACHE / Features.PAGE_SIZE)
        if Features.CURRENT_PAGE_NUMBER < maxPage then
            Features.CURRENT_PAGE_NUMBER = Features.CURRENT_PAGE_NUMBER + 1
            loadEmotes()
            scrollFrame.CanvasPosition = Vector2.new(0, 0)
        elseif Features.NEXT_API_CURSOR then
            Features.CURRENT_PAGE_NUMBER = Features.CURRENT_PAGE_NUMBER + 1
            fetchAndLoad()
        end
    end)
    
    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            Features.CURRENT_SEARCH_TEXT = searchBox.Text
            Features.ITEM_CACHE = {}
            Features.NEXT_API_CURSOR = nil
            Features.CURRENT_PAGE_NUMBER = 1
            fetchAndLoad()
        end
    end)
    
    -- Initial check
    if #Features.ITEM_CACHE > 0 then
        loadEmotes()
    end
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
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, 0, 0, scale("Y", 35))
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "⭐ Saved Emotes (" .. #Features.savedEmotes .. ")"
    headerLabel.TextColor3 = Theme.TextPrimary
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = scale("Y", 16)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = savedFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -scale("Y", 45))
    scrollFrame.Position = UDim2.new(0, 0, 0, scale("Y", 45))
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Theme.Primary
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = savedFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, scale("X", 140), 0, scale("Y", 200))
    gridLayout.CellPadding = UDim2.new(0, scale("X", 10), 0, scale("Y", 10))
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent = scrollFrame
    
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, 0, 0, scale("Y", 50))
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -scale("Y", 25))
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "💾 No saved emotes yet"
    emptyLabel.TextColor3 = Theme.TextSecondary
    emptyLabel.Font = Enum.Font.GothamBold
    emptyLabel.TextSize = scale("Y", 16)
    emptyLabel.Visible = #Features.savedEmotes == 0
    emptyLabel.Parent = savedFrame
    
    local function loadSavedEmotes()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        for i, emote in ipairs(Features.savedEmotes) do
            local card = Instance.new("Frame")
            card.Name = "SavedCard_" .. i
            card.BackgroundColor3 = Theme.Surface
            card.Parent = scrollFrame
            createCorner(card, 12)
            
            local favBtn = Instance.new("TextButton")
            favBtn.Size = UDim2.new(0, scale("X", 25), 0, scale("Y", 25))
            favBtn.Position = UDim2.new(1, -scale("X", 30), 0, scale("Y", 5))
            favBtn.BackgroundColor3 = Theme.Warning
            favBtn.Text = emote.Favorite and "⭐" or "☆"
            favBtn.TextSize = scale("Y", 14)
            favBtn.ZIndex = 2
            favBtn.Parent = card
            createCorner(favBtn, 8)
            
            favBtn.MouseButton1Click:Connect(function()
                emote.Favorite = not emote.Favorite
                favBtn.Text = emote.Favorite and "⭐" or "☆"
                Features.saveEmotesToData()
            end)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 25))
            nameLabel.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 5))
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = emote.Name or "Unknown"
            nameLabel.TextColor3 = Theme.TextPrimary
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = scale("Y", 12)
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = card
            
            local creatorLabel = Instance.new("TextLabel")
            creatorLabel.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 18))
            creatorLabel.Position = UDim2.new(0, scale("X", 5), 0, scale("Y", 30))
            creatorLabel.BackgroundTransparency = 1
            creatorLabel.Text = "by " .. (emote.Creator or "Unknown")
            creatorLabel.TextColor3 = Theme.TextSecondary
            creatorLabel.Font = Enum.Font.Gotham
            creatorLabel.TextSize = scale("Y", 9)
            creatorLabel.TextTruncate = Enum.TextTruncate.AtEnd
            creatorLabel.Parent = card
            
            if Features.Settings["Preview"] then
                local animId = tonumber(emote.AnimationId:match("%d+"))
                if animId then
                    createMiniViewport(
                        UDim2.new(1, 0, 0.5, 0),
                        UDim2.new(0, 0, 0, scale("Y", 55)),
                        card,
                        animId,
                        Features
                    )
                end
            end
            
            local playBtn = Instance.new("TextButton")
            playBtn.Size = UDim2.new(0.45, 0, 0, scale("Y", 30))
            playBtn.Position = UDim2.new(0.025, 0, 0.82, 0)
            playBtn.BackgroundColor3 = Theme.Success
            playBtn.Text = "▶ Play"
            playBtn.TextColor3 = Theme.TextPrimary
            playBtn.Font = Enum.Font.GothamBold
            playBtn.TextSize = scale("Y", 11)
            playBtn.Parent = card
            createCorner(playBtn, 8)
            
            playBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    local animId = tonumber(emote.AnimationId:match("%d+"))
                    if animId then
                        Features.LoadTrack(animId)
                    end
                end)
            end)
            
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0.45, 0, 0, scale("Y", 30))
            delBtn.Position = UDim2.new(0.525, 0, 0.82, 0)
            delBtn.BackgroundColor3 = Theme.Error
            delBtn.Text = "🗑 Delete"
            delBtn.TextColor3 = Theme.TextPrimary
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = scale("Y", 11)
            delBtn.Parent = card
            createCorner(delBtn, 8)
            
            delBtn.MouseButton1Click:Connect(function()
                table.remove(Features.savedEmotes, i)
                Features.saveEmotesToData()
                loadSavedEmotes()
                headerLabel.Text = "⭐ Saved Emotes (" .. #Features.savedEmotes .. ")"
                emptyLabel.Visible = #Features.savedEmotes == 0
            end)
        end
        
        local contentSize = gridLayout.AbsoluteContentSize
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + scale("Y", 10))
    end
    
    loadSavedEmotes()
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
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Theme.Primary
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = settingsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, scale("Y", 10))
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = scrollFrame
    
    local function createSlider(name, min, max, defaultValue)
        Features.Settings[name] = Features.Settings[name] or defaultValue
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 70))
        container.BackgroundColor3 = Theme.Surface
        container.Parent = scrollFrame
        createCorner(container, 10)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 0, scale("Y", 20))
        label.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 8))
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Theme.TextPrimary
        label.Font = Enum.Font.GothamBold
        label.TextSize = scale("Y", 12)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(0, scale("X", 60), 0, scale("Y", 25))
        textBox.Position = UDim2.new(1, -scale("X", 70), 0, scale("Y", 5))
        textBox.BackgroundColor3 = Theme.Elevated
        textBox.TextColor3 = Theme.TextPrimary
        textBox.Font = Enum.Font.GothamBold
        textBox.TextSize = scale("Y", 11)
        textBox.Parent = container
        createCorner(textBox, 8)
        
        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(1, -scale("X", 20), 0, scale("Y", 8))
        sliderBar.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 45))
        sliderBar.BackgroundColor3 = Theme.Elevated
        sliderBar.Parent = container
        createCorner(sliderBar, 4)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Primary
        fill.Parent = sliderBar
        createCorner(fill, 4)
        createGradient(fill, 90, Theme.Primary, Theme.Secondary)
        
        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.new(0, scale("X", 15), 0, scale("Y", 15))
        thumb.BackgroundColor3 = Theme.TextPrimary
        thumb.Parent = sliderBar
        createCorner(thumb, 100)
        
        local dragging = false
        
        local function applyValue(value)
            value = math.clamp(value, min, max)
            Features.Settings[name] = value
            textBox.Text = tostring(value)
            
            local percent = (value - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            thumb.Position = UDim2.new(percent, -scale("X", 7.5), 0.5, -scale("Y", 7.5))
        end
        
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
    
    local function createToggle(name)
        Features.Settings[name] = Features.Settings[name] or false
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 45))
        container.BackgroundColor3 = Theme.Surface
        container.Parent = scrollFrame
        createCorner(container, 10)
        
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
    
    local resetContainer = Instance.new("Frame")
    resetContainer.Size = UDim2.new(1, -scale("X", 10), 0, scale("Y", 50))
    resetContainer.BackgroundColor3 = Theme.Surface
    resetContainer.Parent = scrollFrame
    createCorner(resetContainer, 10)
    
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, -scale("X", 20), 1, -scale("Y", 10))
    resetBtn.Position = UDim2.new(0, scale("X", 10), 0, scale("Y", 5))
    resetBtn.BackgroundColor3 = Theme.Primary
    resetBtn.Text = "🔄 Reset All Settings to Default"
    resetBtn.TextColor3 = Theme.TextPrimary
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = scale("Y", 13)
    resetBtn.Parent = resetContainer
    createCorner(resetBtn, 8)
    createGradient(resetBtn, 90, Theme.Primary, Theme.Secondary)
    
    resetBtn.MouseButton1Click:Connect(function()
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
    
    local contentSize = listLayout.AbsoluteContentSize
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + scale("Y", 20))
end

print("✅ Tab Content Module Loaded Successfully!")

return TabContent
