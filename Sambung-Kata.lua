-- =================================================================
-- Nama Script : KAMUS SAKU V12.1 (FINAL COMPATIBILITY FIX)
-- Author      : wondrv x Duckiezt (Enhanced)
-- Description : PlayerGui Priority, Anti-Scheduler Error
-- =================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // FIX: Gunakan PlayerGui sebagai prioritas utama untuk menghindari Scheduler Error // --
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("KamusEliteGUI") then
    parentGui.KamusEliteGUI:Destroy()
end

-- // 1. CONFIGURATION // --
local CONFIG = {
    Sources = {
        "https://raw.githubusercontent.com/damzaky/kumpulan-kata-bahasa-indonesia-KBBI/master/list_1.0.0.txt",
        "https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/01-kbbi3-2001-sort-alpha.lst"
    },
    FallbackData = {"kamu", "saya", "adalah", "bahasa", "indonesia", "script", "roblox", "makan", "minum", "tidur"},
    Theme = {
        Accent = Color3.fromRGB(0, 255, 180),
        BG = Color3.fromRGB(12, 12, 15),
        Input = Color3.fromRGB(25, 25, 35),
        Text = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(40, 40, 50),
        GhostText = Color3.fromRGB(100, 100, 110)
    }
}

local MasterKamus = {} 
for i = 97, 122 do MasterKamus[string.char(i)] = {} end

local SortMode = 1
local BestSuggestion = ""

-- // 2. UTILITY // --
local function normalize(text)
    if not text then return "" end
    local map = {["é"]="e", ["è"]="e", ["ë"]="e", ["â"]="a", ["î"]="i", ["ô"]="o", ["û"]="u"}
    local clean = text:lower()
    for k, v in pairs(map) do clean = clean:gsub(k, v) end
    clean = clean:gsub("[^a-z]", "") 
    return clean
end

-- // 3. UI CONSTRUCTION // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KamusEliteGUI"
ScreenGui.ResetOnSpawn = false -- Agar UI tidak hilang saat mati di game
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999 -- Pastikan di atas UI lain
ScreenGui.Parent = parentGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 380)
Main.Position = UDim2.new(0.5, -130, 0.5, -190)
Main.BackgroundColor3 = CONFIG.Theme.BG
Main.BorderSizePixel = 0
Main.Active = true -- Penting untuk drag
Main.Draggable = false -- Kita pakai custom drag logic di bawah
Main.Parent = ScreenGui

local Zoom = Instance.new("UIScale", Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = CONFIG.Theme.Accent
Stroke.Thickness = 2

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "STABILIZING..."
Title.TextColor3 = CONFIG.Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local function createBtn(txt, pos, clr)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.Position = pos
    b.BackgroundColor3 = clr
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = Header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local Close = createBtn("×", UDim2.new(1, -35, 0, 10), Color3.fromRGB(255, 80, 80))
local Min = createBtn("−", UDim2.new(1, -65, 0, 10), Color3.fromRGB(200, 160, 50))
local SortBtn = createBtn("⇅", UDim2.new(1, -95, 0, 10), CONFIG.Theme.Secondary)

local SBox = Instance.new("TextBox")
SBox.Size = UDim2.new(1, -30, 0, 38)
SBox.Position = UDim2.new(0, 15, 0, 55)
SBox.BackgroundColor3 = CONFIG.Theme.Input
SBox.PlaceholderText = "Sinkronisasi..."
SBox.Text = ""
SBox.TextColor3 = CONFIG.Theme.Text
SBox.Font = Enum.Font.Gotham
SBox.TextSize = 14
SBox.TextEditable = false
SBox.Parent = Main
Instance.new("UICorner", SBox)

local SuggestionBtn = Instance.new("TextButton")
SuggestionBtn.Size = UDim2.new(1, -30, 0, 20)
SuggestionBtn.Position = UDim2.new(0, 15, 0, 95)
SuggestionBtn.BackgroundTransparency = 1
SuggestionBtn.Text = ""
SuggestionBtn.TextColor3 = CONFIG.Theme.GhostText
SuggestionBtn.Font = Enum.Font.GothamItalic
SuggestionBtn.TextSize = 11
SuggestionBtn.TextXAlignment = Enum.TextXAlignment.Left
SuggestionBtn.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -155)
Scroll.Position = UDim2.new(0, 10, 0, 120)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = CONFIG.Theme.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local ResText = Instance.new("TextLabel")
ResText.Size = UDim2.new(1, -10, 0, 0)
ResText.BackgroundTransparency = 1
ResText.TextColor3 = Color3.fromRGB(200, 200, 200)
ResText.Text = "Menunggu data GitHub..."
ResText.Font = Enum.Font.Code
ResText.TextSize = 13
ResText.TextXAlignment = Enum.TextXAlignment.Left
ResText.TextYAlignment = Enum.TextYAlignment.Top
ResText.AutomaticSize = Enum.AutomaticSize.Y
ResText.Parent = Scroll

local Rez = Instance.new("TextButton")
Rez.Size = UDim2.new(0, 20, 0, 20)
Rez.Position = UDim2.new(1, -20, 1, -20)
Rez.BackgroundColor3 = CONFIG.Theme.Accent
Rez.Text = ""
Rez.Parent = Main
Instance.new("UICorner", Rez).CornerRadius = UDim.new(1,0)

-- // 4. LOGIC ENGINE // --

local function updateSearch()
    local q = normalize(SBox.Text)
    if q == "" or #q < 1 then 
        ResText.Text = "Minimal 3 huruf..." 
        SuggestionBtn.Text = ""
        BestSuggestion = ""
        return 
    end
    
    local firstChar = q:sub(1,1)
    local pool = MasterKamus[firstChar]
    if not pool then return end
    
    local matches = {}
    for _, word in ipairs(pool) do
        if word:sub(1, #q) == q then
            table.insert(matches, word)
        end
    end
    
    if SortMode == 2 then
        table.sort(matches, function(a, b) return #a < #b end)
    elseif SortMode == 3 then
        table.sort(matches, function(a, b) return #a > #b end)
    end
    
    if #matches > 0 then
        BestSuggestion = matches[1]
        SuggestionBtn.Text = "Saran: " .. BestSuggestion .. " (Klik)"
    else
        SuggestionBtn.Text = ""
        BestSuggestion = ""
    end
    
    local display = {}
    for i = 1, math.min(#matches, 60) do
        local word = matches[i]
        table.insert(display, string.format("[%02d] » %s", #word, word:upper()))
    end
    
    ResText.Text = #display > 0 and table.concat(display, "\n") or "Tidak ditemukan."
end

SuggestionBtn.MouseButton1Click:Connect(function()
    if BestSuggestion ~= "" then
        SBox.Text = BestSuggestion
        updateSearch()
    end
end)

-- SAFE LOADER WITH RETRY
task.spawn(function()
    local total = 0
    local seen = {}
    
    for _, url in ipairs(CONFIG.Sources) do
        local success, res
        -- Percobaan download 2x jika gagal
        for i = 1, 2 do
            success, res = pcall(function() return game:HttpGet(url, true) end)
            if success then break end
            task.wait(1)
        end
        
        if success and res then
            for line in res:gmatch("[^\r\n]+") do
                local raw = line:match("^%s*(%S+)")
                if raw then
                    local clean = normalize(raw)
                    if #clean >= 3 and not seen[clean] then
                        seen[clean] = true
                        local first = clean:sub(1,1)
                        if MasterKamus[first] then
                            table.insert(MasterKamus[first], clean)
                            total = total + 1
                        end
                    end
                end
                if total % 10000 == 0 then task.wait() end
            end
        end
    end

    if total == 0 then
        for _, word in ipairs(CONFIG.FallbackData) do
            local first = word:sub(1,1)
            table.insert(MasterKamus[first], word)
            total = total + 1
        end
        Title.Text = "V12.1 - OFFLINE MODE"
    else
        Title.Text = "V12.1 - ONLINE"
    end
    
    for _, folder in pairs(MasterKamus) do table.sort(folder) end
    SBox.PlaceholderText = "Cari kata..."
    SBox.TextEditable = true
    ResText.Text = "Siap. Memuat " .. total .. " kata."
end)

SBox:GetPropertyChangedSignal("Text"):Connect(updateSearch)
SortBtn.MouseButton1Click:Connect(function()
    SortMode = SortMode + 1
    if SortMode > 3 then SortMode = 1 end
    local labels = {"A-Z", "PENDEK", "PANJANG"}
    Title.Text = "MODE: " .. labels[SortMode]
    task.wait(0.5)
    Title.Text = total == 0 and "V12.1 - OFFLINE" or "V12.1 - ONLINE"
    updateSearch()
end)

-- CUSTOM DRAG LOGIC (Lebih stabil dari Draggable = true)
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Resize & Close
Rez.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local rDragging = true
        local startScale = Zoom.Scale
        local startM = i.Position
        local moveConn
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if rDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startM
                Zoom.Scale = math.clamp(startScale + (delta.X / 250), 0.5, 3)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                rDragging = false
                if moveConn then moveConn:Disconnect() end
            end
        end)
    end
end)

Min.MouseButton1Click:Connect(function()
    local isMin = Main.ClipsDescendants
    Main.ClipsDescendants = not isMin
    TweenService:Create(Main, TweenInfo.new(0.3), {Size = isMin and UDim2.new(0, 260, 0, 45) or UDim2.new(0, 260, 0, 380)}):Play()
    Min.Text = isMin and "+" or "−"
end)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
