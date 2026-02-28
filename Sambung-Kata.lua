-- =================================================================
-- Nama Script : KAMUS SAKU V12.2 (GHOST MODE FIX)
-- Author      : wondrv x Duckiezt (Enhanced)
-- Description : Auto-Parenting & Force Display
-- =================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // FIX 1: AUTO-PARENTING (Mencoba semua jalur agar UI muncul) // --
local function getSafeParent()
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then return core end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then return pGui end
    
    return game:GetService("StarterGui") -- Last resort
end

local targetParent = getSafeParent()

if targetParent:FindFirstChild("KamusEliteGUI") then
    targetParent.KamusEliteGUI:Destroy()
end

-- // 1. CONFIGURATION // --
local CONFIG = {
    Sources = {
        "https://raw.githubusercontent.com/damzaky/kumpulan-kata-bahasa-indonesia-KBBI/master/list_1.0.0.txt",
        "https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/01-kbbi3-2001-sort-alpha.lst"
    },
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

-- // 2. UI CONSTRUCTION (FORCE DISPLAY) // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KamusEliteGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.IgnoreGuiInset = true -- Menembus batas atas Roblox
ScreenGui.Parent = targetParent

local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 260, 0, 380)
Main.Position = UDim2.new(0.5, -130, 0.5, -190) -- Tengah layar sempurna
Main.BackgroundColor3 = CONFIG.Theme.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = true -- Memastikan terlihat
Main.Parent = ScreenGui

-- Tambahkan UI Scale agar bisa di-resize
local Zoom = Instance.new("UIScale", Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = CONFIG.Theme.Accent
Stroke.Thickness = 2

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "INITIALIZING..."
Title.TextColor3 = CONFIG.Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Tombol-tombol
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

-- Search Box
local SBox = Instance.new("TextBox")
SBox.Size = UDim2.new(1, -30, 0, 38)
SBox.Position = UDim2.new(0, 15, 0, 55)
SBox.BackgroundColor3 = CONFIG.Theme.Input
SBox.PlaceholderText = "Wait..."
SBox.Text = ""
SBox.TextColor3 = CONFIG.Theme.Text
SBox.Font = Enum.Font.Gotham
SBox.TextSize = 14
SBox.TextEditable = false
SBox.Parent = Main
Instance.new("UICorner", SBox)

-- Scroll Area
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -135)
Scroll.Position = UDim2.new(0, 10, 0, 105)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = CONFIG.Theme.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local ResText = Instance.new("TextLabel")
ResText.Size = UDim2.new(1, -10, 0, 0)
ResText.BackgroundTransparency = 1
ResText.TextColor3 = Color3.fromRGB(200, 200, 200)
ResText.Text = "Loading database..."
ResText.Font = Enum.Font.Code
ResText.TextSize = 13
ResText.TextXAlignment = Enum.TextXAlignment.Left
ResText.TextYAlignment = Enum.TextYAlignment.Top
ResText.AutomaticSize = Enum.AutomaticSize.Y
ResText.Parent = Scroll

-- // 3. LOADING ENGINE // --
task.spawn(function()
    local total = 0
    for _, url in ipairs(CONFIG.Sources) do
        local success, res = pcall(function() return game:HttpGet(url, true) end)
        if success and res then
            for line in res:gmatch("[^\r\n]+") do
                local word = line:match("^%s*(%S+)")
                if word and #word >= 3 then
                    local first = word:sub(1,1):lower()
                    if MasterKamus[first] then
                        table.insert(MasterKamus[first], word:lower())
                        total = total + 1
                    end
                end
                if total % 10000 == 0 then task.wait() end
            end
        end
    end
    Title.Text = "KBBI V12.2 READY"
    SBox.PlaceholderText = "Cari kata (3+ Huruf)..."
    SBox.TextEditable = true
    ResText.Text = "Berhasil memuat " .. total .. " kata."
end)

-- // 4. INTERACTION & DRAG // --
local function setupDrag()
    local dragging, dragStart, startPos
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
setupDrag()

Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
print("Kamus V12.2: Berhasil di-inject ke " .. targetParent.Name)
