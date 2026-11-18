-- MooPing Hub | Clean Orange Edition
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

local THEME_COLOR = Color3.fromRGB(220, 105, 30) -- สีส้มหมูปิ้งสวยๆ

local function cframeToTable(cf)
    local components = {cf:GetComponents()}
    return components
end

local function tableToCFrame(tbl)
    if not tbl or #tbl < 12 then return nil end
    return CFrame.new(unpack(tbl))
end

if readfile and pcall(readfile, CONFIG_FILE) then
    pcall(function()
        local content = readfile(CONFIG_FILE)
        local data = HttpService:JSONDecode(content)
        if data then
            if data.speed then customSpeed = data.speed end
            if data.fpsCap then targetFpsCap = data.fpsCap end
            if data.speedState ~= nil then savedSpeedState = data.speedState end
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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 560)
MainFrame.Position = UDim2.new(0.5, -170, 0.4, -280)
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
Title.Text = "🍖 MooPing Hub | Clean Edition"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0.88, 0, 0, 35)
TabBar.Position = UDim2.new(0.06, 0, 0.10, 0)
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
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local Tab1Button = createTabButton(0.00, 0.23, "🔥 ฟาร์ม")
local Tab2Button = createTabButton(0.25, 0.23, "📍 วาร์ป")
local Tab3Button = createTabButton(0.50, 0.23, "⚡ ผู้เล่น")
local Tab4Button = createTabButton(0.75, 0.23, "🛠️ ตั้งค่า")

Tab1Button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
Tab1Button.TextColor3 = Color3.fromRGB(255, 255, 255)

local FarmContainer = Instance.new("Frame")
FarmContainer.Size = UDim2.new(1, 0, 0.82, 0)
FarmContainer.Position = UDim2.new(0, 0, 0.17, 0)
FarmContainer.BackgroundTransparency = 1
FarmContainer.Visible = true
FarmContainer.Parent = MainFrame

local TeleportContainer = Instance.new("Frame")
TeleportContainer.Size = UDim2.new(1, 0, 0.82, 0)
TeleportContainer.Position = UDim2.new(0, 0, 0.17, 0)
TeleportContainer.BackgroundTransparency = 1
TeleportContainer.Visible = false
TeleportContainer.Parent = MainFrame

local PlayerContainer = Instance.new("Frame")
PlayerContainer.Size = UDim2.new(1, 0, 0.82, 0)
PlayerContainer.Position = UDim2.new(0, 0, 0.17, 0)
PlayerContainer.BackgroundTransparency = 1
PlayerContainer.Visible = false
PlayerContainer.Parent = MainFrame

-- [ แท็บตั้งค่า ทำเป็น ScrollingFrame ขยาย CanvasSize เป็น 460 ให้เลื่อนพ้นปุ่ม END ]
local SettingsContainer = Instance.new("ScrollingFrame")
SettingsContainer.Size = UDim2.new(1, 0, 0.82, 0)
SettingsContainer.Position = UDim2.new(0, 0, 0.17, 0)
SettingsContainer.BackgroundTransparency = 1
SettingsContainer.Visible = false
SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, 460)
SettingsContainer.ScrollBarThickness = 4
SettingsContainer.Parent = MainFrame

local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0.88, 0, 0, 26)
StatusBadge.Position = UDim2.new(0.06, 0, 0.01, 0)
StatusBadge.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
StatusBadge.BorderSizePixel = 0
StatusBadge.Parent = FarmContainer

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

local COLOR_ON = Color3.fromRGB(40, 180, 90)

-- [ แท็บ 1: ฟาร์ม ]
local PlaceButton = Instance.new("TextButton")
PlaceButton.Size = UDim2.new(0.88, 0, 0, 42)
PlaceButton.Position = UDim2.new(0.06, 0, 0.15, 0)
PlaceButton.BackgroundColor3 = THEME_COLOR
PlaceButton.Text = "🔥  เริ่มปิ้งหมูอัตโนมัติ  [ ปิดอยู่ ]"
PlaceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlaceButton.TextSize = 13
PlaceButton.Font = Enum.Font.GothamBold
PlaceButton.Parent = FarmContainer

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 10)
BtnCorner1.Parent = PlaceButton

local CollectButton = Instance.new("TextButton")
CollectButton.Size = UDim2.new(0.88, 0, 0, 42)
CollectButton.Position = UDim2.new(0.06, 0, 0.35, 0)
CollectButton.BackgroundColor3 = THEME_COLOR -- ใช้สีส้มหมูปิ้งเช่นเดียวกับปุ่มเริ่มปิ้งตอนปิดอยู่
CollectButton.Text = "📦  เก็บหมูปิ้งอัตโนมัติ  [ ปิดอยู่ ]"
CollectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CollectButton.TextSize = 13
CollectButton.Font = Enum.Font.GothamBold
CollectButton.Parent = FarmContainer

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 10)
BtnCorner2.Parent = CollectButton

-- [ แท็บ 2: วาร์ป ]
local SaveTPButton = Instance.new("TextButton")
SaveTPButton.Size = UDim2.new(0.88, 0, 0, 36)
SaveTPButton.Position = UDim2.new(0.06, 0, 0.02, 0)
SaveTPButton.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
SaveTPButton.Text = "💾  เซฟจุดพอยต์ปัจจุบัน (ถัดไป)"
SaveTPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveTPButton.TextSize = 12
SaveTPButton.Font = Enum.Font.GothamBold
SaveTPButton.Parent = TeleportContainer

local STPCorner = Instance.new("UICorner")
STPCorner.CornerRadius = UDim.new(0, 8)
STPCorner.Parent = SaveTPButton

local function createCheckpointRow(posY, index, defaultKeyName)
    local hotkeyBtn = Instance.new("TextButton")
    hotkeyBtn.Size = UDim2.new(0.22, 0, 0, 36)
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
    btn.Size = UDim2.new(0.64, 0, 0, 36)
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

local bindingIndex = nil
local TP1Button, HB1 = createCheckpointRow(0.18, 1, "Q")
local TP2Button, HB2 = createCheckpointRow(0.34, 2, "Two")
local TP3Button, HB3 = createCheckpointRow(0.50, 3, "Three")
local TP4Button, HB4 = createCheckpointRow(0.66, 4, "Four")
local hotkeyButtons = {HB1, HB2, HB3, HB4}

local ClearTPButton = Instance.new("TextButton")
ClearTPButton.Size = UDim2.new(0.88, 0, 0, 36)
ClearTPButton.Position = UDim2.new(0.06, 0, 0.83, 0)
ClearTPButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ClearTPButton.Text = "🗑️  ลบบันทึกจุดวาร์ปทั้งหมด"
ClearTPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearTPButton.TextSize = 12
ClearTPButton.Font = Enum.Font.GothamBold
ClearTPButton.Parent = TeleportContainer

local CTPCorner = Instance.new("UICorner")
CTPCorner.CornerRadius = UDim.new(0, 8)
CTPCorner.Parent = ClearTPButton

SaveTPButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        currentSaveIndex = (currentSaveIndex or 0) + 1
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

-- [ แท็บ 3: ผู้เล่น ]
local SpeedButton = Instance.new("TextButton")
SpeedButton.Size = UDim2.new(0.88, 0, 0, 36)
SpeedButton.Position = UDim2.new(0.06, 0, 0.05, 0)
SpeedButton.BackgroundColor3 = isSpeedEnabled and COLOR_ON or Color3.fromRGB(70, 90, 180)
SpeedButton.Text = "⚡  วิ่งไว: " .. customSpeed .. "  [ " .. (isSpeedEnabled and "เปิดใช้งาน" or "ปิดอยู่") .. " ]"
SpeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedButton.TextSize = 12
SpeedButton.Font = Enum.Font.GothamBold
SpeedButton.Parent = PlayerContainer

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 8)
BtnCorner3.Parent = SpeedButton

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.88, 0, 0, 30)
SpeedBox.Position = UDim2.new(0.06, 0, 0.20, 0)
SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderText = "ใส่ความเร็ว (เช่น 35, 50)"
SpeedBox.Text = tostring(customSpeed)
SpeedBox.TextSize = 11
SpeedBox.Font = Enum.Font.GothamMedium
SpeedBox.Parent = PlayerContainer

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
TPButton.Size = UDim2.new(0.88, 0, 0, 36)
TPButton.Position = UDim2.new(0.06, 0, 0.35, 0)
TPButton.BackgroundColor3 = Color3.fromRGB(140, 50, 160)
TPButton.Text = "📍  คลิกวาร์ป (Ctrl + คลิก)  [ ปิดอยู่ ]"
TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TPButton.TextSize = 12
TPButton.Font = Enum.Font.GothamBold
TPButton.Parent = PlayerContainer

local BtnCorner4 = Instance.new("UICorner")
BtnCorner4.CornerRadius = UDim.new(0, 8)
BtnCorner4.Parent = TPButton

local NoclipButton = Instance.new("TextButton")
NoclipButton.Size = UDim2.new(0.88, 0, 0, 36)
NoclipButton.Position = UDim2.new(0.06, 0, 0.50, 0)
NoclipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
NoclipButton.Text = "🧱  ระบบทะลุกำแพง (Noclip) [ ปิดอยู่ ]"
NoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipButton.TextSize = 12
NoclipButton.Font = Enum.Font.GothamBold
NoclipButton.Parent = PlayerContainer

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
        NoclipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
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

-- [ แท็บ 4: ตั้งค่า ]
local isAntiAFKEnabled = true
local isFloatingStatsVisible = true

local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0.92, 0, 0, 70)
ProfileCard.Position = UDim2.new(0.04, 0, 0, 10)
ProfileCard.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = SettingsContainer

local PCarCorner = Instance.new("UICorner")
PCarCorner.CornerRadius = UDim.new(0, 10)
PCarCorner.Parent = ProfileCard

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 52, 0, 52)
AvatarImg.Position = UDim2.new(0, 10, 0.5, -26)
AvatarImg.BackgroundTransparency = 1
pcall(function()
    local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    AvatarImg.Image = content
end)
AvatarImg.Parent = ProfileCard

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImg

local NameLabel = Instance.new("TextLabel")
NameLabel.Size = UDim2.new(1, -70, 0, 22)
NameLabel.Position = UDim2.new(0, 70, 0, 14)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = LocalPlayer.Name
NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NameLabel.TextSize = 13
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Parent = ProfileCard

local SubNameLabel = Instance.new("TextLabel")
SubNameLabel.Size = UDim2.new(1, -70, 0, 18)
SubNameLabel.Position = UDim2.new(0, 70, 0, 36)
SubNameLabel.BackgroundTransparency = 1
SubNameLabel.Text = "✨ สถานะ: ออนไลน์"
SubNameLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
SubNameLabel.TextSize = 11
SubNameLabel.Font = Enum.Font.Gotham
SubNameLabel.TextXAlignment = Enum.TextXAlignment.Left
SubNameLabel.Parent = ProfileCard

local function createSettingsButton(posY, text, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 38)
    btn.Position = UDim2.new(0.04, 0, 0, posY)
    btn.BackgroundColor3 = defaultColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = SettingsContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local AntiAFKButton = createSettingsButton(90, "🛡️  Anti-AFK [ เปิดใช้งาน ]", Color3.fromRGB(40, 180, 90))
local ToggleStatsButton = createSettingsButton(134, "👁️  แสดงหน้าต่างสถิติ [ เปิดอยู่ ]", Color3.fromRGB(40, 150, 90))

local InfiniteYieldButton = createSettingsButton(185, "🚀  รันสคริปต์ Infinite Yield", Color3.fromRGB(200, 80, 50))
local ServerHopButton = createSettingsButton(229, "🌐  เปลี่ยนเซิร์ฟเวอร์ (Server Hop)", Color3.fromRGB(180, 120, 30))
local RejoinButton = createSettingsButton(273, "🔄  เข้าเซิร์ฟเดิมใหม่ (Rejoin)", Color3.fromRGB(140, 50, 160))
local SaveConfigButton = createSettingsButton(317, "💾  บันทึกคอนฟิค (Manual Save)", Color3.fromRGB(40, 120, 200))

-- 🛑 ปุ่ม Kill Switch / Clear Script (END)
local ClearScriptButton = createSettingsButton(361, "🛑  เคลียร์และปิดสคริปต์ทั้งหมด (END)", Color3.fromRGB(220, 40, 40))

ClearScriptButton.MouseButton1Click:Connect(function()
    isPlacing = false
    isCollecting = false
    isSpeedEnabled = false
    isClickTPEnabled = false
    isNoclipEnabled = false
    isAntiAFKEnabled = false
    
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)

    showNotification("ปิดสคริปต์", "ยุติการทำงานทั้งหมดและทำลาย GUI แล้ว", "error")
    task.wait(0.3)
    pcall(function()
        ScreenGui:Destroy()
        FloatingStats:Destroy()
    end)
end)

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
                toggleKey = tostring(uiToggleKey.Name),
                checkpoints = {}
            }
            for i, cf in pairs(savedCheckpoints) do
                saveData.checkpoints[tostring(i)] = cframeToTable(cf)
            end
            
            local jsonString = HttpService:JSONEncode(saveData)
            writefile(CONFIG_FILE, jsonString)
            showNotification("บันทึกสำเร็จ", "บันทึกจุดวาร์ปและคอนฟิคเรียบร้อย!", "success")
        else
            showNotification("ข้อผิดพลาด", "Executor ของคุณไม่รองรับคำสั่ง writefile", "error")
        end
    end)
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
    FarmContainer.Visible = (selectedTab == 1)
    TeleportContainer.Visible = (selectedTab == 2)
    PlayerContainer.Visible = (selectedTab == 3)
    SettingsContainer.Visible = (selectedTab == 4)

    local tabs = {Tab1Button, Tab2Button, Tab3Button, Tab4Button}
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
Tab4Button.MouseButton1Click:Connect(function() switchTab(4) end)

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
        PlaceButton.Text = "🔥  เริ่มปิ้งหมูอัตโนมัติ  [ ปิดอยู่ ]"
        PlaceButton.BackgroundColor3 = THEME_COLOR
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
        CollectButton.Text = "📦  เก็บหมูปิ้งอัตโนมัติ  [ ปิดอยู่ ]"
        CollectButton.BackgroundColor3 = THEME_COLOR
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
        SpeedButton.BackgroundColor3 = Color3.fromRGB(70, 90, 180)
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
        TPButton.BackgroundColor3 = Color3.fromRGB(140, 50, 160)
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

print("โหลด UI Clean Edition สำเร็จ!")
