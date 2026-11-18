-- MooPing Hub | Custom Color & Noclip Edition
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GrillActionEvent = nil
pcall(function()
    GrillActionEvent = ReplicatedStorage:WaitForChild("MooRemotes", 3):WaitForChild("GrillAction", 3)
end)

local startTime = tick()

-- 💾 ระบบจัดการไฟล์คอนฟิค
local CONFIG_FILE = "MooPingHub_Config.json"
local savedCheckpoints = {}
local checkpointHotkeys = {
    [1] = Enum.KeyCode.Q,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four
}
local customSpeed = 30
local targetFpsCap = 60
local savedSpeedState = false
local uiToggleKey = Enum.KeyCode.LeftControl
local customAccentColor = {R = 220, G = 105, B = 30} -- สีส้มเริ่มต้น

-- ฟังก์ชันแปลง CFrame เป็น Table
local function cframeToTable(cf)
    local components = {cf:GetComponents()}
    return components
end

-- ฟังก์ชันแปลง Table กลับเป็น CFrame
local function tableToCFrame(tbl)
    if not tbl or #tbl < 12 then return nil end
    return CFrame.new(unpack(tbl))
end

-- โหลดข้อมูลไฟล์เก่า (ถ้ามี)
if readfile and pcall(readfile, CONFIG_FILE) then
    pcall(function()
        local content = readfile(CONFIG_FILE)
        local data = HttpService:JSONDecode(content)
        if data then
            if data.speed then customSpeed = data.speed end
            if data.fpsCap then targetFpsCap = data.fpsCap end
            if data.speedState ~= nil then savedSpeedState = data.speedState end
            if data.accentColor then customAccentColor = data.accentColor end
            if data.toggleKey and Enum.KeyCode[data.toggleKey] then 
                uiToggleKey = Enum.KeyCode[data.toggleKey] 
            end
            if data.checkpoints then
                for i, tbl in pairs(data.checkpoints) do
                    local cf = tableToCFrame(tbl)
                    if cf then
                        savedCheckpoints[tonumber(i)] = cf
                    end
                end
            end
        end
    end)
end

local activeAccentColor3 = Color3.fromRGB(customAccentColor.R, customAccentColor.G, customAccentColor.B)

-- ฟังก์ชันค้นหา Plot อัตโนมัติ
local function getMyPlot()
    local stalls = Workspace:FindFirstChild("Stalls")
    if not stalls then return nil end
    
    for _, plot in ipairs(stalls:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            if plot.Name == LocalPlayer.Name or (plot:FindFirstChild("Owner") and plot.Owner.Value == LocalPlayer) then
                return plot
            end
        end
    end
    
    local closestPlot = nil
    local shortestDistance = math.huge
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    for _, plot in ipairs(stalls:GetChildren()) do
        local targetPart = plot:FindFirstChildWhichIsA("BasePart")
        if rootPart and targetPart then
            local distance = (rootPart.Position - targetPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlot = plot
            end
        end
    end
    
    return closestPlot or stalls:GetChildren()[1]
end

-- เคลียร์ UI เก่าทิ้งก่อน
pcall(function()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui.Name == "MooPingSafeHub" then gui:Destroy() end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name == "MooPingSafeHub" then gui:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MooPingSafeHub"
ScreenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    pcall(function() syn.protect_gui(ScreenGui) end)
    ScreenGui.Parent = CoreGui
elseif gethui then
    pcall(function() ScreenGui.Parent = gethui() end)
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- 🔔 ระบบแจ้งเตือน
local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 260, 0, 300)
NotifContainer.Position = UDim2.new(1, -270, 0, 20)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local function showNotification(title, message, notifType)
    pcall(function()
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 55)
        card.Position = UDim2.new(1, 20, 0, 0)
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        card.BorderSizePixel = 0
        card.Parent = NotifContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = notifType == "success" and Color3.fromRGB(40, 180, 90) or (notifType == "error" and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(70, 130, 220))
        stroke.Thickness = 1.5
        stroke.Parent = card

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -15, 0, 22)
        titleLbl.Position = UDim2.new(0, 12, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.TextSize = 13
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = card

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -15, 0, 20)
        msgLbl.Position = UDim2.new(0, 12, 0, 26)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text = message
        msgLbl.TextColor3 = Color3.fromRGB(170, 170, 190)
        msgLbl.TextSize = 11
        msgLbl.Font = Enum.Font.Gotham
        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
        msgLbl.Parent = card

        local function updatePositions()
            local yOffset = 0
            for _, child in ipairs(NotifContainer:GetChildren()) do
                if child:IsA("Frame") then
                    TweenService:Create(child, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 0, 0, yOffset)
                    }):Play()
                    yOffset = yOffset + 62
                end
            end
        end

        updatePositions()
        TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, card.Position.Y.Scale, card.Position.Y.Offset)
        }):Play()

        task.spawn(function()
            task.wait(2.5)
            TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 300, card.Position.Y.Scale, card.Position.Y.Offset)
            }):Play()
            task.wait(0.3)
            card:Destroy()
            updatePositions()
        end)
    end)
end

-- 🌟 หน้าต่างสถิติลอยได้
local FloatingStats = Instance.new("Frame")
FloatingStats.Name = "FloatingStats"
FloatingStats.Size = UDim2.new(0, 225, 0, 130)
FloatingStats.Position = UDim2.new(0, 20, 0.15, 0)
FloatingStats.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
FloatingStats.BorderSizePixel = 0
FloatingStats.Active = true
FloatingStats.Draggable = true
FloatingStats.Parent = ScreenGui

local FSCorner = Instance.new("UICorner")
FSCorner.CornerRadius = UDim.new(0, 10)
FSCorner.Parent = FloatingStats

local FSStroke = Instance.new("UIStroke")
FSStroke.Color = Color3.fromRGB(60, 60, 90)
FSStroke.Thickness = 1.5
FSStroke.Parent = FloatingStats

local FSTitle = Instance.new("TextLabel")
FSTitle.Size = UDim2.new(1, -12, 0, 24)
FSTitle.Position = UDim2.new(0, 10, 0, 6)
FSTitle.BackgroundTransparency = 1
FSTitle.Text = "📊 สถานะระบบ (ลากย้ายได้)"
FSTitle.TextColor3 = Color3.fromRGB(220, 220, 240)
FSTitle.TextSize = 11
FSTitle.Font = Enum.Font.GothamBold
FSTitle.TextXAlignment = Enum.TextXAlignment.Left
FSTitle.Parent = FloatingStats

local function createFloatStatRow(posY, labelText)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(170, 170, 190)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = FloatingStats
    return lbl
end

local FloatFpsKey = createFloatStatRow(30, "🖥️ FPS: กำลังโหลด...")
local FloatPingKey = createFloatStatRow(48, "📶 Ping: กำลังโหลด...")
local FloatPlayersKey = createFloatStatRow(66, "👥 ผู้เล่น: กำลังโหลด...")
local FloatRealTimeKey = createFloatStatRow(84, "🕒 เวลาจริง: 00:00:00")
local FloatRunTimeKey = createFloatStatRow(102, "⏱️ รันมาแล้ว: 00:00:00")

-- 🌟 หน้าต่างหลัก (Main Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 600)
MainFrame.Position = UDim2.new(0.5, -170, 0.4, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 12)
HeaderCover.Position = UDim2.new(0, 0, 1, -12)
HeaderCover.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🍖 MooPing Hub | Custom Edition"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0.88, 0, 0, 35)
TabBar.Position = UDim2.new(0.06, 0, 0.09, 0)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local function createTabButton(posX, sizeX, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(sizeX, 0, 1, 0)
    btn.Position = UDim2.new(posX, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(160, 160, 180)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local Tab1Button = createTabButton(0, 0.31, "🔥 ทั่วไป")
local Tab2Button = createTabButton(0.33, 0.34, "📍 วาร์ป")
local Tab3Button = createTabButton(0.69, 0.31, "🛠️ เพิ่มเติม")

Tab1Button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
Tab1Button.TextColor3 = Color3.fromRGB(255, 255, 255)

local GeneralContainer = Instance.new("Frame")
GeneralContainer.Size = UDim2.new(1, 0, 0.85, 0)
GeneralContainer.Position = UDim2.new(0, 0, 0.15, 0)
GeneralContainer.BackgroundTransparency = 1
GeneralContainer.Visible = true
GeneralContainer.Parent = MainFrame

local TeleportContainer = Instance.new("Frame")
TeleportContainer.Size = UDim2.new(1, 0, 0.85, 0)
TeleportContainer.Position = UDim2.new(0, 0, 0.15, 0)
TeleportContainer.BackgroundTransparency = 1
TeleportContainer.Visible = false
TeleportContainer.Parent = MainFrame

local ExtraContainer = Instance.new("Frame")
ExtraContainer.Size = UDim2.new(1, 0, 0.85, 0)
ExtraContainer.Position = UDim2.new(0, 0, 0.15, 0)
ExtraContainer.BackgroundTransparency = 1
ExtraContainer.Visible = false
ExtraContainer.Parent = MainFrame

-- ==================== หมวดหมู่ที่ 1: ทั่วไป (General) ====================
local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0.88, 0, 0, 26)
StatusBadge.Position = UDim2.new(0.06, 0, 0.01, 0)
StatusBadge.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
StatusBadge.BorderSizePixel = 0
StatusBadge.Parent = GeneralContainer

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 8)
BadgeCorner.Parent = StatusBadge

local PlotStatus = Instance.new("TextLabel")
PlotStatus.Size = UDim2.new(1, -15, 1, 0)
PlotStatus.Position = UDim2.new(0, 12, 0, 0)
PlotStatus.BackgroundTransparency = 1
PlotStatus.Text = "🔍 กำลังค้นหาเตาอัตโนมัติ..."
PlotStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
PlotStatus.TextSize = 12
PlotStatus.Font = Enum.Font.GothamMedium
PlotStatus.TextXAlignment = Enum.TextXAlignment.Left
PlotStatus.Parent = StatusBadge

task.spawn(function()
    while task.wait(1) do
        local p = getMyPlot()
        if p then
            PlotStatus.Text = "📌 เตาที่ใช้งาน: " .. p.Name
        else
            PlotStatus.Text = "⚠️ ไม่พบเตา (โปรดเข้าใกล้เตา)"
        end
    end
end)

local isPlacing = false
local isCollecting = false
local isSpeedEnabled = savedSpeedState
local isClickTPEnabled = false
local isNoclipEnabled = false

local COLOR_OFF_PLACE = activeAccentColor3
local COLOR_OFF_COLLECT = Color3.fromRGB(35, 130, 85)
local COLOR_OFF_SPEED = Color3.fromRGB(70, 90, 180)
local COLOR_OFF_TP = Color3.fromRGB(140, 50, 160)
local COLOR_OFF_NOCLIP = Color3.fromRGB(100, 100, 130)
local COLOR_ON = Color3.fromRGB(40, 180, 90)

local PlaceButton = Instance.new("TextButton")
PlaceButton.Size = UDim2.new(0.88, 0, 0, 34)
PlaceButton.Position = UDim2.new(0.06, 0, 0.12, 0)
PlaceButton.BackgroundColor3 = COLOR_OFF_PLACE
PlaceButton.Text = "🔥  เริ่มปิ้งหมู  [ ปิดอยู่ ]"
PlaceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlaceButton.TextSize = 12
PlaceButton.Font = Enum.Font.GothamBold
PlaceButton.Parent = GeneralContainer

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 8)
BtnCorner1.Parent = PlaceButton

local CollectButton = Instance.new("TextButton")
CollectButton.Size = UDim2.new(0.88, 0, 0, 34)
CollectButton.Position = UDim2.new(0.06, 0, 0.26, 0)
CollectButton.BackgroundColor3 = COLOR_OFF_COLLECT
CollectButton.Text = "📦  เก็บหมูปิ้ง  [ ปิดอยู่ ]"
CollectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CollectButton.TextSize = 12
CollectButton.Font = Enum.Font.GothamBold
CollectButton.Parent = GeneralContainer

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 8)
BtnCorner2.Parent = CollectButton

local SpeedButton = Instance.new("TextButton")
SpeedButton.Size = UDim2.new(0.88, 0, 0, 34)
SpeedButton.Position = UDim2.new(0.06, 0, 0.40, 0)
SpeedButton.BackgroundColor3 = isSpeedEnabled and COLOR_ON or COLOR_OFF_SPEED
SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ " .. (isSpeedEnabled and "เปิดใช้งาน" or "ปิดอยู่") .. " ]"
SpeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedButton.TextSize = 12
SpeedButton.Font = Enum.Font.GothamBold
SpeedButton.Parent = GeneralContainer

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 8)
BtnCorner3.Parent = SpeedButton

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.88, 0, 0, 28)
SpeedBox.Position = UDim2.new(0.06, 0, 0.54, 0)
SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderText = "ใส่ความเร็ว (เช่น 35, 50)"
SpeedBox.Text = tostring(customSpeed)
SpeedBox.TextSize = 11
SpeedBox.Font = Enum.Font.GothamMedium
SpeedBox.Parent = GeneralContainer

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = SpeedBox

SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    if val then
        customSpeed = val
        if isSpeedEnabled then
            SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ เปิดใช้งาน ]"
        else
            SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ ปิดอยู่ ]"
        end
        showNotification("ตั้งค่าสำเร็จ", "เปลี่ยนความเร็ววิ่งเป็น: " .. customSpeed, "info")
    else
        SpeedBox.Text = tostring(customSpeed)
    end
end)

local TPButton = Instance.new("TextButton")
TPButton.Size = UDim2.new(0.88, 0, 0, 34)
TPButton.Position = UDim2.new(0.06, 0, 0.67, 0)
TPButton.BackgroundColor3 = COLOR_OFF_TP
TPButton.Text = "📍  คลิกวาร์ป (Ctrl + คลิก)  [ ปิดอยู่ ]"
TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TPButton.TextSize = 12
TPButton.Font = Enum.Font.GothamBold
TPButton.Parent = GeneralContainer

local BtnCorner4 = Instance.new("UICorner")
BtnCorner4.CornerRadius = UDim.new(0, 8)
BtnCorner4.Parent = TPButton

local NoclipButton = Instance.new("TextButton")
NoclipButton.Size = UDim2.new(0.88, 0, 0, 34)
NoclipButton.Position = UDim2.new(0.06, 0, 0.81, 0)
NoclipButton.BackgroundColor3 = COLOR_OFF_NOCLIP
NoclipButton.Text = "🧱  ระบบทะลุกำแพง (Noclip) [ ปิดอยู่ ]"
NoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipButton.TextSize = 12
NoclipButton.Font = Enum.Font.GothamBold
NoclipButton.Parent = GeneralContainer

local BtnCorner5 = Instance.new("UICorner")
BtnCorner5.CornerRadius = UDim.new(0, 8)
BtnCorner5.Parent = NoclipButton

NoclipButton.MouseButton1Click:Connect(function()
    isNoclipEnabled = not isNoclipEnabled
    if isNoclipEnabled then
        NoclipButton.Text = "🧱  ระบบทะลุกำแพง (Noclip) [ เปิดใช้งาน ]"
        NoclipButton.BackgroundColor3 = COLOR_ON
        showNotification("เปิดใช้งาน", "เปิดระบบทะลุกำแพงแล้ว", "success")
    else
        NoclipButton.Text = "🧱  ระบบทะลุกำแพง (Noclip) [ ปิดอยู่ ]"
        NoclipButton.BackgroundColor3 = COLOR_OFF_NOCLIP
        showNotification("ปิดใช้งาน", "ปิดระบบทะลุกำแพงแล้ว", "error")
    end
end)

RunService.Stepped:Connect(function()
    if isNoclipEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- ==================== หมวดหมู่ที่ 2: วาร์ป (Teleport) ====================
local bindingIndex = nil

local SaveTPButton = Instance.new("TextButton")
SaveTPButton.Size = UDim2.new(0.88, 0, 0, 36)
SaveTPButton.Position = UDim2.new(0.06, 0, 0.02, 0)
SaveTPButton.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
SaveTPButton.Text = "💾  เซฟจุดพอยต์ปัจจุบัน (ถัดไป)"
SaveTPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveTPButton.TextSize = 13
SaveTPButton.Font = Enum.Font.GothamBold
SaveTPButton.Parent = TeleportContainer

local STPCorner = Instance.new("UICorner")
STPCorner.CornerRadius = UDim.new(0, 8)
STPCorner.Parent = SaveTPButton

local function createCheckpointRow(posY, index, defaultKeyName)
    local hotkeyBtn = Instance.new("TextButton")
    hotkeyBtn.Size = UDim2.new(0.22, 0, 0, 34)
    hotkeyBtn.Position = UDim2.new(0.06, 0, posY, 0)
    hotkeyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    hotkeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hotkeyBtn.Text = defaultKeyName
    hotkeyBtn.TextSize = 11
    hotkeyBtn.Font = Enum.Font.GothamBold
    hotkeyBtn.Parent = TeleportContainer

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = hotkeyBtn

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.64, 0, 0, 34)
    btn.Position = UDim2.new(0.30, 0, posY, 0)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    btn.Text = "🚀 จุดที่ " .. index .. " [ยังไม่บันทึก]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TeleportContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    if savedCheckpoints[index] then
        btn.Text = "🚀 จุดที่ " .. index .. " [บันทึกแล้ว ✓]"
        btn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    hotkeyBtn.MouseButton1Click:Connect(function()
        bindingIndex = index
        hotkeyBtn.Text = "[...]"
        hotkeyBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 30)
        showNotification("ตั้งค่าคีย์ลัด", "กรุณากดปุ่มบนคีย์บอร์ดสำหรับจุดที่ " .. index, "info")
    end)

    return btn, hotkeyBtn
end

local TP1Button, HB1 = createCheckpointRow(0.16, 1, "Q")
local TP2Button, HB2 = createCheckpointRow(0.30, 2, "Two")
local TP3Button, HB3 = createCheckpointRow(0.44, 3, "Three")
local TP4Button, HB4 = createCheckpointRow(0.58, 4, "Four")

local hotkeyButtons = {HB1, HB2, HB3, HB4}

local ClearTPButton = Instance.new("TextButton")
ClearTPButton.Size = UDim2.new(0.88, 0, 0, 36)
ClearTPButton.Position = UDim2.new(0.06, 0, 0.73, 0)
ClearTPButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ClearTPButton.Text = "🗑️  ลบบันทึกจุดวาร์ปทั้งหมด"
ClearTPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearTPButton.TextSize = 13
ClearTPButton.Font = Enum.Font.GothamBold
ClearTPButton.Parent = TeleportContainer

local CTPCorner = Instance.new("UICorner")
CTPCorner.CornerRadius = UDim.new(0, 8)
CTPCorner.Parent = ClearTPButton

local currentSaveIndex = 0

SaveTPButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        currentSaveIndex = currentSaveIndex + 1
        if currentSaveIndex > 4 then currentSaveIndex = 1 end
        
        savedCheckpoints[currentSaveIndex] = rootPart.CFrame
        
        local buttons = {TP1Button, TP2Button, TP3Button, TP4Button}
        buttons[currentSaveIndex].Text = "🚀 จุดที่ " .. currentSaveIndex .. " [บันทึกแล้ว ✓]"
        buttons[currentSaveIndex].BackgroundColor3 = Color3.fromRGB(40, 150, 90)
        buttons[currentSaveIndex].TextColor3 = Color3.fromRGB(255, 255, 255)
        
        showNotification("บันทึกพอยต์สำเร็จ", "บันทึกพิกัดลงจุดที่ " .. currentSaveIndex .. " เรียบร้อย!", "success")
    end
end)

ClearTPButton.MouseButton1Click:Connect(function()
    savedCheckpoints = {}
    currentSaveIndex = 0
    local buttons = {TP1Button, TP2Button, TP3Button, TP4Button}
    for i, btn in ipairs(buttons) do
        btn.Text = "🚀 จุดที่ " .. i .. " [ยังไม่บันทึก]"
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    showNotification("ล้างข้อมูล", "ลบบันทึกจุดวาร์ปทั้งหมดแล้ว", "error")
end)

local function teleportTo(index)
    if savedCheckpoints[index] then
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if rootPart then 
            rootPart.CFrame = savedCheckpoints[index] 
            showNotification("วาร์ปสำเร็จ", "วาร์ปไปยังจุดที่ " .. index .. " แล้ว!", "success")
        end
    else
        showNotification("ไม่สามารถวาร์ปได้", "จุดที่ " .. index .. " ยังไม่ได้บันทึกพิกัด!", "error")
    end
end

TP1Button.MouseButton1Click:Connect(function() teleportTo(1) end)
TP2Button.MouseButton1Click:Connect(function() teleportTo(2) end)
TP3Button.MouseButton1Click:Connect(function() teleportTo(3) end)
TP4Button.MouseButton1Click:Connect(function() teleportTo(4) end)

-- ==================== หมวดหมู่ที่ 3: เพิ่มเติม (Extra & Tools) ====================
local isAntiAFKEnabled = true
local isFloatingStatsVisible = true
local isFPSCapEnabled = false
local isBindingUIKey = false

-- 👤 การ์ดโปรไฟล์
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0.88, 0, 0, 60)
ProfileCard.Position = UDim2.new(0.06, 0, 0.01, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = ExtraContainer

local PCarCorner = Instance.new("UICorner")
PCarCorner.CornerRadius = UDim.new(0, 10)
PCarCorner.Parent = ProfileCard

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 44, 0, 44)
AvatarImg.Position = UDim2.new(0, 8, 0.5, -22)
AvatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
pcall(function()
    AvatarImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
AvatarImg.Parent = ProfileCard

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImg

local NameLabel = Instance.new("TextLabel")
NameLabel.Size = UDim2.new(1, -60, 0, 18)
NameLabel.Position = UDim2.new(0, 58, 0, 11)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = LocalPlayer.Name
NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NameLabel.TextSize: 11
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Parent = ProfileCard

local SubNameLabel = Instance.new("TextLabel")
SubNameLabel.Size = UDim2.new(1, -60, 0, 16)
SubNameLabel.Position = UDim2.new(0, 58, 0, 30)
SubNameLabel.BackgroundTransparency = 1
SubNameLabel.Text = "✨ สถานะ: ออนไลน์"
SubNameLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
SubNameLabel.TextSize = 10
SubNameLabel.Font = Enum.Font.Gotham
SubNameLabel.TextXAlignment = Enum.TextXAlignment.Left
SubNameLabel.Parent = ProfileCard

local function createExtraButton(posY, text, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.88, 0, 0, 26)
    btn.Position = UDim2.new(0.06, 0, posY, 0)
    btn.BackgroundColor3 = defaultColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ExtraContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local AntiAFKButton = createExtraButton(0.11, "🛡️  Anti-AFK [ เปิดใช้งาน ]", Color3.fromRGB(40, 180, 90))
local ToggleStatsButton = createExtraButton(0.17, "👁️  แสดงหน้าต่างสถิติ [ เปิดอยู่ ]", Color3.fromRGB(40, 150, 90))
local ToggleKeyButton = createExtraButton(0.23, "⌨️  ปุ่มซ่อน UI: [" .. tostring(uiToggleKey.Name) .. "]", Color3.fromRGB(70, 70, 100))
local FPSCapButton = createExtraButton(0.29, "🎯  ล็อก FPS: " .. targetFpsCap .. " [ ปิดอยู่ ]", Color3.fromRGB(70, 90, 180))

local FPSBox = Instance.new("TextBox")
FPSBox.Size = UDim2.new(0.88, 0, 0, 24)
FPSBox.Position = UDim2.new(0.06, 0, 0.35, 0)
FPSBox.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
FPSBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSBox.PlaceholderText = "ใส่ค่า FPS (เช่น 30, 60, 120)"
FPSBox.Text = tostring(targetFpsCap)
FPSBox.TextSize = 10
FPSBox.Font = Enum.Font.GothamMedium
FPSBox.Parent = ExtraContainer

local BoxCornerFPS = Instance.new("UICorner")
BoxCornerFPS.CornerRadius = UDim.new(0, 8)
BoxCornerFPS.Parent = FPSBox

FPSBox.FocusLost:Connect(function()
    local val = tonumber(FPSBox.Text)
    if val and val > 0 then
        targetFpsCap = val
        if isFPSCapEnabled then
            pcall(function() setfpscap(targetFpsCap) end)
            FPSCapButton.Text = "🎯  ล็อก FPS: " .. targetFpsCap .. " [ เปิดใช้งาน ]"
        else
            FPSCapButton.Text = "🎯  ล็อก FPS: " .. targetFpsCap .. " [ ปิดอยู่ ]"
        end
        showNotification("ตั้งค่า FPS", "เปลี่ยนเป้าหมายล็อก FPS เป็น: " .. targetFpsCap, "info")
    else
        FPSBox.Text = tostring(targetFpsCap)
    end
end)

-- 🎨 ช่องปรับแต่งสี Theme (Custom Color Picker)
local ColorPickerBox = Instance.new("TextBox")
ColorPickerBox.Size = UDim2.new(0.88, 0, 0, 26)
ColorPickerBox.Position = UDim2.new(0.06, 0, 0.42, 0)
ColorPickerBox.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
ColorPickerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ColorPickerBox.PlaceholderText = "ใส่ค่าสี RGB เช่น 220,105,30"
ColorPickerBox.Text = customAccentColor.R .. "," .. customAccentColor.G .. "," .. customAccentColor.B
ColorPickerBox.TextSize = 10
ColorPickerBox.Font = Enum.Font.GothamMedium
ColorPickerBox.Parent = ExtraContainer

local CPCorner = Instance.new("UICorner")
CPCorner.CornerRadius = UDim.new(0, 8)
CPCorner.Parent = ColorPickerBox

ColorPickerBox.FocusLost:Connect(function()
    local r, g, b = ColorPickerBox.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r and g and b and r <= 255 and g <= 255 and b <= 255 then
        customAccentColor = {R = r, G = g, B = b}
        activeAccentColor3 = Color3.fromRGB(r, g, b)
        PlaceButton.BackgroundColor3 = activeAccentColor3
        showNotification("เปลี่ยนสีธีม", "อัปเดตสีไฮไลต์สำเร็จ!", "success")
    else
        showNotification("ข้อผิดพลาด", "รูปแบบสีไม่ถูกต้อง (ใช้ R,G,B เช่น 220,105,30)", "error")
        ColorPickerBox.Text = customAccentColor.R .. "," .. customAccentColor.G .. "," .. customAccentColor.B
    end
end)

-- ฟังก์ชันปุ่มเสริมด้านล่าง
local InfiniteYieldButton = createExtraButton(0.50, "🚀  รันสคริปต์ Infinite Yield", Color3.fromRGB(200, 80, 50))
local ServerHopButton = createExtraButton(0.56, "🌐  เปลี่ยนเซิร์ฟเวอร์ (Server Hop)", Color3.fromRGB(180, 120, 30))
local RejoinButton = createExtraButton(0.62, "🔄  เข้าเซิร์ฟเดิมใหม่ (Rejoin)", Color3.fromRGB(140, 50, 160))
local SaveConfigButton = createExtraButton(0.68, "💾  บันทึกคอนฟิค (Manual Save)", Color3.fromRGB(40, 120, 200))
local FPSBoostButton = createExtraButton(0.74, "🚀  FPS Boost / ลดกราฟิก [ ปิดอยู่ ]", Color3.fromRGB(70, 90, 180))

AntiAFKButton.MouseButton1Click:Connect(function()
    isAntiAFKEnabled = not isAntiAFKEnabled
    if isAntiAFKEnabled then
        AntiAFKButton.Text = "🛡️  Anti-AFK [ เปิดใช้งาน ]"
        AntiAFKButton.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        showNotification("เปิดใช้งาน", "เปิดระบบป้องกันการโดนเตะ AFK แล้ว", "success")
    else
        AntiAFKButton.Text = "🛡️  Anti-AFK [ ปิดอยู่ ]"
        AntiAFKButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        showNotification("ปิดใช้งาน", "ปิดระบบป้องกัน Anti-AFK แล้ว", "error")
    end
end)

ToggleStatsButton.MouseButton1Click:Connect(function()
    isFloatingStatsVisible = not isFloatingStatsVisible
    FloatingStats.Visible = isFloatingStatsVisible
    if isFloatingStatsVisible then
        ToggleStatsButton.Text = "👁️  แสดงหน้าต่างสถิติ [ เปิดอยู่ ]"
        ToggleStatsButton.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
        showNotification("เปิดหน้าต่าง", "แสดงหน้าต่างสถิติลอยแล้ว", "success")
    else
        ToggleStatsButton.Text = "👁️  แสดงหน้าต่างสถิติ [ ปิดอยู่ ]"
        ToggleStatsButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        showNotification("ปิดหน้าต่าง", "ซ่อนหน้าต่างสถิติลอยแล้ว", "error")
    end
end)

ToggleKeyButton.MouseButton1Click:Connect(function()
    isBindingUIKey = true
    ToggleKeyButton.Text = "⌨️  กดปุ่มใหม่ที่จะใช้ซ่อน UI..."
    ToggleKeyButton.BackgroundColor3 = Color3.fromRGB(180, 120, 30)
    showNotification("เปลี่ยนปุ่มลัด", "กรุณากดปุ่มบนคีย์บอร์ดที่ต้องการตั้งเป็นปุ่มซ่อน/เปิด UI", "info")
end)

FPSCapButton.MouseButton1Click:Connect(function()
    isFPSCapEnabled = not isFPSCapEnabled
    if isFPSCapEnabled then
        FPSCapButton.Text = "🎯  ล็อก FPS: " .. targetFpsCap .. " [ เปิดใช้งาน ]"
        FPSCapButton.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        pcall(function() setfpscap(targetFpsCap) end)
        showNotification("ล็อก FPS", "ตั้งขีดจำกัด FPS ที่ " .. targetFpsCap .. " เรียบร้อย", "success")
    else
        FPSCapButton.Text = "🎯  ล็อก FPS: " .. targetFpsCap .. " [ ปิดอยู่ ]"
        FPSCapButton.BackgroundColor3 = Color3.fromRGB(70, 90, 180)
        pcall(function() setfpscap(60) end) -- ล็อกเซฟไว้ที่ 60 FPS ป้องกันคอมร้อน
        showNotification("ปลดล็อก FPS", "คืนค่าขีดจำกัด FPS กลับสู่ 60 FPS แล้ว", "info")
    end
end)

InfiniteYieldButton.MouseButton1Click:Connect(function()
    showNotification("Infinite Yield", "กำลังโหลดและรัน Infinite Yield...", "success")
    pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
end)

ServerHopButton.MouseButton1Click:Connect(function()
    showNotification("Server Hop", "กำลังค้นหาและย้ายไปเซิร์ฟเวอร์อื่น...", "info")
    task.spawn(function()
        pcall(function()
            local servers = {}
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            local body = HttpService:JSONDecode(req)
            if body and body.data then
                for _, s in ipairs(body.data) do
                    if type(s) == "table" and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end
            end
            if #servers > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end)
    end)
end)

RejoinButton.MouseButton1Click:Connect(function()
    showNotification("Rejoin", "กำลังเชื่อมต่อเข้าเซิร์ฟเวอร์เดิมใหม่...", "info")
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("กำลังรีจอยส์เซิร์ฟเวอร์...")
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end)

SaveConfigButton.MouseButton1Click:Connect(function()
    pcall(function()
        if writefile then
            local saveData = {
                speed = customSpeed,
                fpsCap = targetFpsCap,
                speedState = isSpeedEnabled,
                accentColor = customAccentColor,
                toggleKey = tostring(uiToggleKey.Name),
                checkpoints = {}
            }
            for i, cf in pairs(savedCheckpoints) do
                saveData.checkpoints[tostring(i)] = cframeToTable(cf)
            end
            
            local jsonString = HttpService:JSONEncode(saveData)
            writefile(CONFIG_FILE, jsonString)
            showNotification("บันทึกสำเร็จ", "บันทึกจุดวาร์ป, สีธีม และปุ่มลัดลงไฟล์เรียบร้อย!", "success")
        else
            showNotification("ข้อผิดพลาด", "Executor ของคุณไม่รองรับคำสั่ง writefile", "error")
        end
    end)
end)

local isFPSBoostEnabled = false
FPSBoostButton.MouseButton1Click:Connect(function()
    isFPSBoostEnabled = not isFPSBoostEnabled
    if isFPSBoostEnabled then
        FPSBoostButton.Text = "🚀  FPS Boost / ลดกราฟิก [ เปิดใช้งาน ]"
        FPSBoostButton.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        showNotification("FPS Boost", "เปิดโหมดประหยัดทรัพยากร/ลดกราฟิกแล้ว", "success")
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 999999
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
        end)
    else
        FPSBoostButton.Text = "🚀  FPS Boost / ลดกราฟิก [ ปิดอยู่ ]"
        FPSBoostButton.BackgroundColor3 = Color3.fromRGB(70, 90, 180)
        showNotification("FPS Boost", "ปิดโหมดเพิ่ม FPS แล้ว", "info")
    end
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if isAntiAFKEnabled then
            pcall(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
            showNotification("Anti-AFK", "ระบบป้องกันการเตะ AFK ทำงานอัตโนมัติแล้ว!", "info")
        end
    end)
end)

task.spawn(function()
    local lastTick = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
    end)
    
    while task.wait(1) do
        local currentTick = tick()
        local fps = math.floor(frameCount / (currentTick - lastTick))
        frameCount = 0
        lastTick = currentTick
        
        local ping = 0
        pcall(function()
            ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        
        local totalPlayers = #Players:GetPlayers()
        local elapsedSeconds = math.floor(tick() - startTime)
        local hours = math.floor(elapsedSeconds / 3600)
        local minutes = math.floor((elapsedSeconds % 3600) / 60)
        local seconds = elapsedSeconds % 60
        local runTimeString = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        local realTimeString = os.date("%H:%M:%S")
        
        FloatFpsKey.Text = "🖥️ FPS: " .. fps .. " FPS"
        FloatPingKey.Text = "📶 Ping: " .. ping .. " ms"
        FloatPlayersKey.Text = "👥 ผู้เล่น: " .. totalPlayers .. " คน"
        FloatRealTimeKey.Text = "🕒 เวลาจริง: " .. realTimeString
        FloatRunTimeKey.Text = "⏱️ รันมาแล้ว: " .. runTimeString
    end
end)

local function switchTab(selectedTab)
    GeneralContainer.Visible = (selectedTab == 1)
    TeleportContainer.Visible = (selectedTab == 2)
    ExtraContainer.Visible = (selectedTab == 3)

    local tabs = {Tab1Button, Tab2Button, Tab3Button}
    for i, btn in ipairs(tabs) do
        if i == selectedTab then
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
            btn.TextColor3 = Color3.fromRGB(160, 160, 180)
        end
    end
end

Tab1Button.MouseButton1Click:Connect(function() switchTab(1) end)
Tab2Button.MouseButton1Click:Connect(function() switchTab(2) end)
Tab3Button.MouseButton1Click:Connect(function() switchTab(3) end)

PlaceButton.MouseButton1Click:Connect(function()
    isPlacing = not isPlacing
    if isPlacing then
        PlaceButton.Text = "🔥  กำลังปิ้งหมู...  [ เปิดใช้งาน ]"
        PlaceButton.BackgroundColor3 = COLOR_ON
        showNotification("เปิดใช้งาน", "เริ่มระบบปิ้งหมูอัตโนมัติแล้ว", "success")
        task.spawn(function()
            while isPlacing do
                local currentPlot = getMyPlot()
                if currentPlot and GrillActionEvent then
                    for i = 1, 10 do
                        if not isPlacing then break end
                        task.spawn(function()
                            pcall(function()
                                GrillActionEvent:FireServer(currentPlot, i, "place")
                            end)
                        end)
                        task.wait(0.03)
                    end
                end
                local timer = 0
                while isPlacing and timer < 0.8 do
                    task.wait(0.1)
                    timer = timer + 0.1
                end
            end
        end)
    else
        PlaceButton.Text = "🔥  เริ่มปิ้งหมู  [ ปิดอยู่ ]"
        PlaceButton.BackgroundColor3 = activeAccentColor3
        showNotification("ปิดใช้งาน", "หยุดระบบปิ้งหมูแล้ว", "error")
    end
end)

CollectButton.MouseButton1Click:Connect(function()
    isCollecting = not isCollecting
    if isCollecting then
        CollectButton.Text = "📦  กำลังเก็บหมู...  [ เปิดใช้งาน ]"
        CollectButton.BackgroundColor3 = COLOR_ON
        showNotification("เปิดใช้งาน", "เริ่มระบบเก็บหมูอัตโนมัติแล้ว", "success")
        task.spawn(function()
            while isCollecting do
                local currentPlot = getMyPlot()
                if currentPlot and GrillActionEvent then
                    for i = 1, 10 do
                        if not isCollecting then break end
                        task.spawn(function()
                            pcall(function()
                                GrillActionEvent:FireServer(currentPlot, i, "collect")
                            end)
                        end)
                        task.wait(0.03)
                    end
                end
                local timer = 0
                while isCollecting and timer < 0.8 do
                    task.wait(0.1)
                    timer = timer + 0.1
                end
            end
        end)
    else
        CollectButton.Text = "📦  เก็บหมูปิ้ง  [ ปิดอยู่ ]"
        CollectButton.BackgroundColor3 = COLOR_OFF_COLLECT
        showNotification("ปิดใช้งาน", "หยุดระบบเก็บหมูแล้ว", "error")
    end
end)

SpeedButton.MouseButton1Click:Connect(function()
    isSpeedEnabled = not isSpeedEnabled
    if isSpeedEnabled then
        SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ เปิดใช้งาน ]"
        SpeedButton.BackgroundColor3 = COLOR_ON
        showNotification("เปิดใช้งาน", "เปิดระบบวิ่งไวความเร็ว: " .. customSpeed, "success")
    else
        SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ ปิดอยู่ ]"
        SpeedButton.BackgroundColor3 = COLOR_OFF_SPEED
        showNotification("ปิดใช้งาน", "ปิดระบบวิ่งไวแล้ว", "error")
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if isSpeedEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = customSpeed end
        end)
    end
end)

TPButton.MouseButton1Click:Connect(function()
    isClickTPEnabled = not isClickTPEnabled
    if isClickTPEnabled then
        TPButton.Text = "📍  คลิกวาร์ป (Ctrl + คลิก)  [ เปิดใช้งาน ]"
        TPButton.BackgroundColor3 = COLOR_ON
        showNotification("เปิดใช้งาน", "เปิดระบบคลิกวาร์ปแล้ว", "success")
    else
        TPButton.Text = "📍  คลิกวาร์ป (Ctrl + คลิก)  [ ปิดอยู่ ]"
        TPButton.BackgroundColor3 = COLOR_OFF_TP
        showNotification("ปิดใช้งาน", "ปิดระบบคลิกวาร์ปแล้ว", "error")
    end
end)

Mouse.Button1Down:Connect(function()
    if isClickTPEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        pcall(function()
            local char = LocalPlayer.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            if rootPart and Mouse.Target then
                rootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
                showNotification("คลิกวาร์ป", "วาร์ปไปยังตำแหน่งที่คลิกแล้ว!", "info")
            end
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if isBindingUIKey then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                uiToggleKey = input.KeyCode
                ToggleKeyButton.Text = "⌨️  ปุ่มซ่อน UI: [" .. tostring(uiToggleKey.Name) .. "]"
                ToggleKeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
                showNotification("ตั้งค่าปุ่มลัด", "ตั้งค่าปุ่มเปิด/ปิด UI เป็น [" .. tostring(uiToggleKey.Name) .. "]", "success")
            else
                ToggleKeyButton.Text = "⌨️  ปุ่มซ่อน UI: [" .. tostring(uiToggleKey.Name) .. "]"
                ToggleKeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
            end
            isBindingUIKey = false
            return
        end

        if bindingIndex then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                checkpointHotkeys[bindingIndex] = input.KeyCode
                hotkeyButtons[bindingIndex].Text = tostring(input.KeyCode.Name)
                hotkeyButtons[bindingIndex].BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                showNotification("ตั้งค่าคีย์ลัด", "ตั้งค่าปุ่มจุดที่ " .. bindingIndex .. " เป็น [" .. tostring(input.KeyCode.Name) .. "]", "success")
            else
                hotkeyButtons[bindingIndex].Text = tostring(checkpointHotkeys[bindingIndex].Name)
                hotkeyButtons[bindingIndex].BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            end
            bindingIndex = nil
            return
        end

        if not gameProcessed and input.KeyCode == uiToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        elseif not gameProcessed then
            for i, keyCode in pairs(checkpointHotkeys) do
                if input.KeyCode == keyCode then
                    if savedCheckpoints[i] then
                        pcall(function()
                            local char = LocalPlayer.Character
                            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                            if rootPart then 
                                rootPart.CFrame = savedCheckpoints[i] 
                                showNotification("วาร์ปสำเร็จ", "วาร์ปไปยังจุดที่ " .. i .. " แล้ว!", "success")
                            end
                        end)
                    end
                end
            end
        end
    end
end)

print("โหลด UI Custom Edition สำเร็จ!")
