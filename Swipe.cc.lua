-- Swipe.cc - Full Roblox Script
-- Современный Luau скрипт с модульной структурой
-- Автор: Swipe.cc Team
--
-- 🔒 БЕЗ РЕКЛАМЫ И ВИРУСОВ - 100% ЧИСТЫЙ КОД
-- Весь код открыт на GitHub: https://github.com/denisy2shtyrkin-ui/Swipe.cc
-- Никаких скрытых функций или вредоносного кода

-- Защита от повторной загрузки
if getgenv().SwipeCC then
    getgenv().SwipeCC:Unload()
end

-- Основное пространство имён
local SwipeCC = {}
getgenv().SwipeCC = SwipeCC

-- ============================================
-- СЕРВИСЫ
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- МОДУЛЬ CONFIG
-- ============================================
SwipeCC.Config = {
    -- GUI настройки
    Name = "Swipe.cc",
    Version = "1.0.0",
    
    -- Тема
    Theme = {
        Mode = "Dark", -- Dark, Light, Custom
        AccentColor = Color3.fromRGB(138, 43, 226), -- Фиолетовый
        Background = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(35, 35, 50),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(76, 175, 80),
        Error = Color3.fromRGB(244, 67, 54),
        Warning = Color3.fromRGB(255, 152, 0)
    },
    
    -- Клавиши
    ToggleKey = Enum.KeyCode.RightShift,
    
    -- Размеры GUI
    GUI = {
        Size = UDim2.new(0, 550, 0, 400),
        MinSize = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0.5, -275, 0.5, -200)
    },
    
    -- Сохранение
    AutoSave = true,
    ConfigName = "SwipeCC_Config.json"
}

-- ============================================
-- МОДУЛЬ UTILS
-- ============================================
SwipeCC.Utils = {}

-- Таблица для хранения всех connections
SwipeCC.Connections = {}

-- Оригинальные значения для восстановления
SwipeCC.OriginalValues = {}

function SwipeCC.Utils:AddConnection(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(SwipeCC.Connections, connection)
    return connection
end

function SwipeCC.Utils:CleanupConnections()
    for _, connection in ipairs(SwipeCC.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    SwipeCC.Connections = {}
end

function SwipeCC.Utils:Notify(title, message, duration)
    duration = duration or 3
    
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "SwipeCC_Notification"
    notificationGui.IgnoreGuiInset = true
    notificationGui.Parent = SwipeCC.GUI.ScreenGui
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, 20, 1, -100)
    notification.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = SwipeCC.Config.Theme.AccentColor
    stroke.Thickness = 2
    stroke.Parent = notification
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = SwipeCC.Config.Theme.AccentColor
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, 0, 1, -25)
    messageLabel.Position = UDim2.new(0, 0, 0, 25)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = SwipeCC.Config.Theme.Text
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Анимация появления
    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 1, -100)
    })
    tweenIn:Play()
    
    -- Удаление после duration
    task.delay(duration, function()
        local tweenOut = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 20, 1, -100)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notificationGui:Destroy()
    end)
end

function SwipeCC.Utils:SaveConfig()
    local success, err = pcall(function()
        local configData = {
            Theme = {
                Mode = SwipeCC.Config.Theme.Mode,
                AccentColor = {SwipeCC.Config.Theme.AccentColor:ToHSV()}
            },
            ToggleKey = SwipeCC.Config.ToggleKey.Name,
            Features = {}
        }
        
        -- Сохранение состояний фич
        for featureName, featureData in pairs(SwipeCC.Features) do
            if featureData.State ~= nil then
                configData.Features[featureName] = featureData.State
            end
        end
        
        if writefile then
            writefile(SwipeCC.Config.ConfigName, HttpService:JSONEncode(configData))
            SwipeCC.Utils:Notify("Success", "Конфигурация сохранена!", 2)
        else
            warn("Writefile не поддерживается")
        end
    end)
    
    if not success then
        warn("Ошибка сохранения: " .. tostring(err))
    end
end

function SwipeCC.Utils:LoadConfig()
    local success, data = pcall(function()
        if readfile then
            local content = readfile(SwipeCC.Config.ConfigName)
            return HttpService:JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        -- Загрузка темы
        if data.Theme then
            SwipeCC.Config.Theme.Mode = data.Theme.Mode or "Dark"
            if data.Theme.AccentColor then
                SwipeCC.Config.Theme.AccentColor = Color3.fromHSV(unpack(data.Theme.AccentColor))
            end
        end
        
        -- Загрузка клавиши
        if data.ToggleKey then
            local key = Enum.KeyCode[data.ToggleKey]
            if key then
                SwipeCC.Config.ToggleKey = key
            end
        end
        
        -- Загрузка состояний фич
        if data.Features then
            for featureName, state in pairs(data.Features) do
                if SwipeCC.Features[featureName] then
                    SwipeCC.Features[featureName].State = state
                end
            end
        end
        
        SwipeCC.Utils:Notify("Success", "Конфигурация загружена!", 2)
    end
end

function SwipeCC.Utils:GetDistance(part1, part2)
    if not part1 or not part2 then return math.huge end
    return (part1.Position - part2.Position).Magnitude
end

function SwipeCC.Utils:IsTeammate(player)
    if not player or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

-- ============================================
-- МОДУЛЬ THEME
-- ============================================
SwipeCC.Theme = {}

function SwipeCC.Theme:ApplyTheme(mode)
    if mode == "Light" then
        SwipeCC.Config.Theme.Background = Color3.fromRGB(240, 240, 245)
        SwipeCC.Config.Theme.Secondary = Color3.fromRGB(255, 255, 255)
        SwipeCC.Config.Theme.Text = Color3.fromRGB(30, 30, 30)
        SwipeCC.Config.Theme.TextSecondary = Color3.fromRGB(100, 100, 100)
    elseif mode == "Dark" then
        SwipeCC.Config.Theme.Background = Color3.fromRGB(25, 25, 35)
        SwipeCC.Config.Theme.Secondary = Color3.fromRGB(35, 35, 50)
        SwipeCC.Config.Theme.Text = Color3.fromRGB(255, 255, 255)
        SwipeCC.Config.Theme.TextSecondary = Color3.fromRGB(180, 180, 180)
    end
end

-- ============================================
-- МОДУЛЬ UI
-- ============================================
SwipeCC.UI = {}

function SwipeCC.UI:CreateGUI()
    -- Удаление старого GUI если существует
    local oldGui = LocalPlayer.PlayerGui:FindFirstChild("SwipeCC_GUI")
    if oldGui then
        oldGui:Destroy()
    end
    
    -- Создание ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SwipeCC_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer.PlayerGui
    
    SwipeCC.GUI = {ScreenGui = screenGui}
    
    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = SwipeCC.Config.GUI.Size
    mainFrame.Position = SwipeCC.Config.GUI.Position
    mainFrame.BackgroundColor3 = SwipeCC.Config.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = SwipeCC.Config.Theme.AccentColor
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    local mainShadow = Instance.new("UIAspectRatioConstraint")
    mainShadow.AspectRatio = 0
    mainShadow.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingLeft = UDim.new(0, 15)
    titlePadding.PaddingRight = UDim.new(0, 10)
    titlePadding.PaddingTop = UDim.new(0, 5)
    titlePadding.PaddingBottom = UDim.new(0, 5)
    titlePadding.Parent = titleBar
    
    -- Маска для заголовка (чтобы углы были только сверху)
    local titleMask = Instance.new("Frame")
    titleMask.Size = UDim2.new(1, 0, 0, 20)
    titleMask.Position = UDim2.new(0, 0, 0.5, 0)
    titleMask.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    titleMask.BorderSizePixel = 0
    titleMask.Parent = titleBar
    
    local titleMaskCorner = Instance.new("UICorner")
    titleMaskCorner.CornerRadius = UDim.new(0, 12)
    titleMaskCorner.Parent = titleMask
    
    -- Название
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = SwipeCC.Config.Name .. " v" .. SwipeCC.Config.Version
    titleLabel.TextColor3 = SwipeCC.Config.Theme.AccentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Кнопка сворачивания
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
    minimizeBtn.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = SwipeCC.Config.Theme.Text
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeBtn.BackgroundColor3 = SwipeCC.Config.Theme.Error
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    -- Содержимое
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -40)
    contentFrame.Position = UDim2.new(0, 0, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Левая панель (вкладки)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(0, 140, 1, 0)
    tabFrame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = contentFrame
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabFrame
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingBottom = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.Parent = tabFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabFrame
    
    -- Поиск
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, 0, 0, 30)
    searchFrame.BackgroundColor3 = SwipeCC.Config.Theme.Background
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = tabFrame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchFrame
    
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 10)
    searchPadding.PaddingRight = UDim.new(0, 10)
    searchPadding.Parent = searchFrame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, 0, 1, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Поиск..."
    searchBox.PlaceholderColor3 = SwipeCC.Config.Theme.TextSecondary
    searchBox.Text = ""
    searchBox.TextColor3 = SwipeCC.Config.Theme.Text
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame
    
    -- Правая панель (контент вкладок)
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = "PageFrame"
    pageFrame.Size = UDim2.new(1, -150, 1, 0)
    pageFrame.Position = UDim2.new(0, 150, 0, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Parent = contentFrame
    
    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 15)
    pagePadding.PaddingBottom = UDim.new(0, 15)
    pagePadding.PaddingLeft = UDim.new(0, 15)
    pagePadding.PaddingRight = UDim.new(0, 15)
    pagePadding.Parent = pageFrame
    
    -- Список вкладок
    local tabs = {"Main", "Player", "Visuals", "World", "Misc", "Settings"}
    SwipeCC.UI.Tabs = {}
    SwipeCC.UI.Pages = {}
    
    -- Создание кнопок вкладок
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UDim2.new(1, 0, 0, 35)
        tabBtn.BackgroundColor3 = SwipeCC.Config.Theme.Background
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabName
        tabBtn.TextColor3 = SwipeCC.Config.Theme.Text
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.Parent = tabFrame
        
        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 6)
        tabBtnCorner.Parent = tabBtn
        
        local tabBtnPadding = Instance.new("UIPadding")
        tabBtnPadding.PaddingLeft = UDim.new(0, 10)
        tabBtnPadding.Parent = tabBtn
        
        SwipeCC.UI.Tabs[tabName] = tabBtn
        
        -- Создание страницы
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = SwipeCC.Config.Theme.AccentColor
        page.Parent = pageFrame
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = page
        
        SwipeCC.UI.Pages[tabName] = page
    end
    
    -- Dragging функционал
    local dragging = false
    local dragInput, dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    dragInput = input
                end
            end)
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    SwipeCC.Utils:AddConnection(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Кнопка сворачивания
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(contentFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            minimizeBtn.Text = "+"
        else
            TweenService:Create(contentFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
            minimizeBtn.Text = "-"
        end
    end)
    
    -- Кнопка закрытия
    closeBtn.MouseButton1Click:Connect(function()
        SwipeCC:Unload()
    end)
    
    -- Переключение вкладок
    local currentTab = "Main"
    
    local function SelectTab(tabName)
        -- Скрыть все страницы
        for name, page in pairs(SwipeCC.UI.Pages) do
            page.Visible = false
        end
        
        -- Сбросить стиль всех кнопок
        for name, btn in pairs(SwipeCC.UI.Tabs) do
            btn.BackgroundColor3 = SwipeCC.Config.Theme.Background
            btn.TextColor3 = SwipeCC.Config.Theme.Text
        end
        
        -- Показать выбранную страницу
        if SwipeCC.UI.Pages[tabName] then
            SwipeCC.UI.Pages[tabName].Visible = true
        end
        
        -- Подсветить выбранную кнопку
        if SwipeCC.UI.Tabs[tabName] then
            SwipeCC.UI.Tabs[tabName].BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
            SwipeCC.UI.Tabs[tabName].TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        currentTab = tabName
    end
    
    for tabName, btn in pairs(SwipeCC.UI.Tabs) do
        btn.MouseButton1Click:Connect(function()
            SelectTab(tabName)
        end)
    end
    
    -- Выбрать первую вкладку
    SelectTab("Main")
    
    -- Функция создания элементов
    SwipeCC.UI.CreateToggle = function(text, callback, default)
        default = default or false
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
        frame.BorderSizePixel = 0
        frame.Parent = SwipeCC.UI.Pages[currentTab]
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = SwipeCC.Config.Theme.Text
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 40, 0, 20)
        toggleBtn.Position = UDim2.new(1, -45, 0.5, -10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = ""
        toggleBtn.Parent = frame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 10)
        toggleCorner.Parent = toggleBtn
        
        local toggleIndicator = Instance.new("Frame")
        toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
        toggleIndicator.Position = UDim2.new(0, 2, 0.5, -8)
        toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleIndicator.BorderSizePixel = 0
        toggleIndicator.Parent = toggleBtn
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 8)
        indicatorCorner.Parent = toggleIndicator
        
        local state = default
        
        local function UpdateToggle()
            if state then
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
                }):Play()
                TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 22, 0.5, -8)
                }):Play()
            else
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                }):Play()
                TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 2, 0.5, -8)
                }):Play()
            end
        end
        
        UpdateToggle()
        
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            UpdateToggle()
            callback(state)
        end)
        
        return {SetState = function(new) state = new UpdateToggle() callback(state) end, GetState = function() return state end}
    end
    
    SwipeCC.UI.CreateSlider = function(text, min, max, default, callback)
        default = default or min
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
        frame.BorderSizePixel = 0
        frame.Parent = SwipeCC.UI.Pages[currentTab]
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(default)
        label.TextColor3 = SwipeCC.Config.Theme.Text
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, 0, 0, 8)
        sliderBg.Position = UDim2.new(0, 0, 1, -10)
        sliderBg.BackgroundColor3 = SwipeCC.Config.Theme.Background
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = frame
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 4)
        sliderCorner.Parent = sliderBg
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = sliderFill
        
        local dragging = false
        
        local function UpdateSlider(input)
            local scale = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * scale)
            sliderFill.Size = UDim2.new(scale, 0, 1, 0)
            label.Text = text .. ": " .. tostring(value)
            callback(value)
        end
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                UpdateSlider(input)
            end
        end)
        
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        SwipeCC.Utils:AddConnection(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(input)
            end
        end)
        
        return default
    end
    
    SwipeCC.UI.CreateButton = function(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.Parent = SwipeCC.UI.Pages[currentTab]
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            callback()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = SwipeCC.Config.Theme.Background
            }):Play()
            task.wait(0.1)
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
            }):Play()
        end)
        
        return btn
    end
    
    SwipeCC.UI.CreateDropdown = function(text, options, callback, default)
        default = default or options[1]
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
        frame.BorderSizePixel = 0
        frame.Parent = SwipeCC.UI.Pages[currentTab]
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 150, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = SwipeCC.Config.Theme.Text
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(1, -160, 1, -10)
        dropdownBtn.Position = UDim2.new(0, 155, 0, 5)
        dropdownBtn.BackgroundColor3 = SwipeCC.Config.Theme.Background
        dropdownBtn.BorderSizePixel = 0
        dropdownBtn.Text = default
        dropdownBtn.TextColor3 = SwipeCC.Config.Theme.Text
        dropdownBtn.TextSize = 12
        dropdownBtn.Font = Enum.Font.Gotham
        dropdownBtn.Parent = frame
        
        local dropCorner = Instance.new("UICorner")
        dropCorner.CornerRadius = UDim.new(0, 4)
        dropCorner.Parent = dropdownBtn
        
        local expanded = false
        local dropdownList
        
        dropdownBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            
            if expanded then
                dropdownList = Instance.new("Frame")
                dropdownList.Size = UDim2.new(1, 0, 0, #options * 30)
                dropdownList.Position = UDim2.new(0, 0, 1, 5)
                dropdownList.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
                dropdownList.BorderSizePixel = 0
                dropdownList.ZIndex = 10
                dropdownList.Parent = dropdownBtn
                
                local listCorner = Instance.new("UICorner")
                listCorner.CornerRadius = UDim.new(0, 4)
                listCorner.Parent = dropdownList
                
                local listLayout = Instance.new("UIListLayout")
                listLayout.Parent = dropdownList
                
                for i, option in ipairs(options) do
                    local optionBtn = Instance.new("TextButton")
                    optionBtn.Size = UDim2.new(1, 0, 0, 30)
                    optionBtn.BackgroundColor3 = SwipeCC.Config.Theme.Background
                    optionBtn.BorderSizePixel = 0
                    optionBtn.Text = option
                    optionBtn.TextColor3 = SwipeCC.Config.Theme.Text
                    optionBtn.TextSize = 12
                    optionBtn.Font = Enum.Font.Gotham
                    optionBtn.Parent = dropdownList
                    
                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optionBtn
                    
                    optionBtn.MouseButton1Click:Connect(function()
                        dropdownBtn.Text = option
                        callback(option)
                        dropdownList:Destroy()
                        expanded = false
                    end)
                end
            else
                if dropdownList then
                    dropdownList:Destroy()
                end
            end
        end)
    end
    
    SwipeCC.UI.CreateKeybind = function(text, callback, default)
        default = default or Enum.KeyCode.RightShift
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
        frame.BorderSizePixel = 0
        frame.Parent = SwipeCC.UI.Pages[currentTab]
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = SwipeCC.Config.Theme.Text
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(0, 80, 0, 25)
        keybindBtn.Position = UDim2.new(1, -90, 0.5, -12)
        keybindBtn.BackgroundColor3 = SwipeCC.Config.Theme.Background
        keybindBtn.BorderSizePixel = 0
        keybindBtn.Text = default.Name
        keybindBtn.TextColor3 = SwipeCC.Config.Theme.AccentColor
        keybindBtn.TextSize = 12
        keybindBtn.Font = Enum.Font.Gotham
        keybindBtn.Parent = frame
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 4)
        keyCorner.Parent = keybindBtn
        
        local binding = false
        
        keybindBtn.MouseButton1Click:Connect(function()
            binding = true
            keybindBtn.Text = "..."
            keybindBtn.TextColor3 = SwipeCC.Config.Theme.Warning
        end)
        
        SwipeCC.Utils:AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
            if binding and not gameProcessed then
                if input.KeyCode then
                    default = input.KeyCode
                    keybindBtn.Text = default.Name
                    keybindBtn.TextColor3 = SwipeCC.Config.Theme.AccentColor
                    binding = false
                    callback(default)
                end
            end
        end)
        
        return default
    end
    
    -- Переключатель GUI по клавише
    SwipeCC.Utils:AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
        if input.KeyCode == SwipeCC.Config.ToggleKey and not gameProcessed then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
    
    return screenGui
end

-- ============================================
-- МОДУЛЬ FEATURES
-- ============================================
SwipeCC.Features = {}

-- Main Tab Features
SwipeCC.Features.Rejoin = {
    State = false,
    Execute = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
}

SwipeCC.Features.ServerHop = {
    State = false,
    Execute = function()
        local function FindServer()
            local servers = {}
            local request = function()
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local success, data = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)
                if success and data then
                    for _, server in ipairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            table.insert(servers, server.id)
                        end
                    end
                end
            end
            request()
            return servers[1]
        end
        
        local serverId = FindServer()
        if serverId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        else
            SwipeCC.Utils:Notify("Error", "Сервер не найден", 3)
        end
    end
}

-- FPS Counter
SwipeCC.Features.FPSCounter = {
    State = true,
    Connection = nil,
    Execute = function(state)
        if state then
            local fpsGui = Instance.new("ScreenGui")
            fpsGui.Name = "FPS_Counter"
            fpsGui.ResetOnSpawn = false
            fpsGui.Parent = LocalPlayer.PlayerGui
            
            local fpsLabel = Instance.new("TextLabel")
            fpsLabel.Name = "FPSLabel"
            fpsLabel.Size = UDim2.new(0, 100, 0, 30)
            fpsLabel.Position = UDim2.new(1, -110, 0, 10)
            fpsLabel.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
            fpsLabel.BorderSizePixel = 0
            fpsLabel.Text = "FPS: 60"
            fpsLabel.TextColor3 = SwipeCC.Config.Theme.Text
            fpsLabel.TextSize = 14
            fpsLabel.Font = Enum.Font.GothamBold
            fpsLabel.Parent = fpsGui
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = fpsLabel
            
            local lastTime = tick()
            local frameCount = 0
            
            SwipeCC.Features.FPSCounter.Connection = RunService.RenderStepped:Connect(function()
                frameCount = frameCount + 1
                if tick() - lastTime >= 1 then
                    fpsLabel.Text = "FPS: " .. frameCount
                    frameCount = 0
                    lastTime = tick()
                end
            end)
            
            SwipeCC.Features.FPSCounter.Gui = fpsGui
        else
            if SwipeCC.Features.FPSCounter.Connection then
                SwipeCC.Features.FPSCounter.Connection:Disconnect()
            end
            if SwipeCC.Features.FPSCounter.Gui then
                SwipeCC.Features.FPSCounter.Gui:Destroy()
            end
        end
    end
}

-- Player Tab Features
SwipeCC.Features.WalkSpeed = {
    State = 16,
    Connection = nil,
    Execute = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
        
        if SwipeCC.Features.WalkSpeed.Connection then
            SwipeCC.Features.WalkSpeed.Connection:Disconnect()
        end
        
        SwipeCC.Features.WalkSpeed.Connection = LocalPlayer.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            humanoid.WalkSpeed = value
        end)
    end
}

SwipeCC.Features.JumpPower = {
    State = 50,
    Connection = nil,
    Execute = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = value
        end
        
        if SwipeCC.Features.JumpPower.Connection then
            SwipeCC.Features.JumpPower.Connection:Disconnect()
        end
        
        SwipeCC.Features.JumpPower.Connection = LocalPlayer.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            humanoid.JumpPower = value
        end)
    end
}

SwipeCC.Features.InfiniteJump = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.InfiniteJump.Connection = SwipeCC.Utils:AddConnection(UserInputService.JumpRequest, function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                end
            end)
        else
            if SwipeCC.Features.InfiniteJump.Connection then
                SwipeCC.Features.InfiniteJump.Connection:Disconnect()
            end
        end
    end
}

SwipeCC.Features.Noclip = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.Noclip.Connection = RunService.RenderStepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if SwipeCC.Features.Noclip.Connection then
                SwipeCC.Features.Noclip.Connection:Disconnect()
            end
            -- Восстановление
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
}

SwipeCC.Features.Fly = {
    State = false,
    Speed = 50,
    Connection = nil,
    BodyVelocity = nil,
    Execute = function(state)
        if state then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = LocalPlayer.Character.HumanoidRootPart
                SwipeCC.Features.Fly.BodyVelocity = bv
            end
            
            SwipeCC.Features.Fly.Connection = RunService.RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local camera = workspace.CurrentCamera
                    local move = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        move = move + camera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        move = move - camera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        move = move - camera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        move = move + camera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        move = move + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        move = move - Vector3.new(0, 1, 0)
                    end
                    
                    if SwipeCC.Features.Fly.BodyVelocity then
                        SwipeCC.Features.Fly.BodyVelocity.Velocity = move.Unit * SwipeCC.Features.Fly.Speed
                    end
                end
            end)
        else
            if SwipeCC.Features.Fly.Connection then
                SwipeCC.Features.Fly.Connection:Disconnect()
            end
            if SwipeCC.Features.Fly.BodyVelocity then
                SwipeCC.Features.Fly.BodyVelocity:Destroy()
            end
        end
    end
}

SwipeCC.Features.ClickTP = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.ClickTP.Connection = SwipeCC.Utils:AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    local mouse = LocalPlayer:GetMouse()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local target = mouse.Hit
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target.Position)
                    end
                end
            end)
            SwipeCC.Utils:Notify("Info", "Нажмите Ctrl + ЛКМ для телепорта", 3)
        else
            if SwipeCC.Features.ClickTP.Connection then
                SwipeCC.Features.ClickTP.Connection:Disconnect()
            end
        end
    end
}

SwipeCC.Features.AntiAFK = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.AntiAFK.Connection = SwipeCC.Utils:AddConnection(game:GetService("Players").Idled, function(time)
                game:GetService("VirtualInputManager"):Button1Down(Vector2.new(0, 0))
                task.wait()
                game:GetService("VirtualInputManager"):Button1Up(Vector2.new(0, 0))
            end)
        else
            if SwipeCC.Features.AntiAFK.Connection then
                SwipeCC.Features.AntiAFK.Connection:Disconnect()
            end
        end
    end
}

SwipeCC.Features.GodMode = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                SwipeCC.OriginalValues.Health = LocalPlayer.Character.Humanoid.Health
                SwipeCC.Features.GodMode.Connection = RunService.Heartbeat:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.Health = math.huge
                    end
                end)
            end
        else
            if SwipeCC.Features.GodMode.Connection then
                SwipeCC.Features.GodMode.Connection:Disconnect()
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = SwipeCC.OriginalValues.Health or 100
            end
        end
    end
}

SwipeCC.Features.ResetCharacter = {
    State = false,
    Execute = function()
        local character = LocalPlayer.Character
        if character then
            character:BreakJoints()
        end
    end
}

-- Visuals Tab Features
SwipeCC.Features.ESP = {
    State = false,
    Connection = nil,
    Boxes = {},
    Execute = function(state)
        if state then
            SwipeCC.Features.ESP.Connection = RunService.RenderStepped:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = player.Character.HumanoidRootPart
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        
                        if onScreen then
                            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
                            
                            -- Создаём или обновляем ESP
                            if not SwipeCC.Features.ESP.Boxes[player.Name] then
                                local billboard = Instance.new("BillboardGui")
                                billboard.Name = "ESP_" .. player.Name
                                billboard.Size = UDim2.new(0, 100, 0, 100)
                                billboard.StudsOffset = Vector3.new(0, 3, 0)
                                billboard.AlwaysOnTop = true
                                billboard.Parent = LocalPlayer.PlayerGui
                                
                                local box = Instance.new("Frame")
                                box.Size = UDim2.new(0, 4, 0, 4)
                                box.Position = UDim2.new(0.5, -2, 0.5, -2)
                                box.BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
                                box.BorderSizePixel = 0
                                box.Parent = billboard
                                
                                local nameLabel = Instance.new("TextLabel")
                                nameLabel.Size = UDim2.new(1, 0, 0, 20)
                                nameLabel.Position = UDim2.new(0, 0, 1, 5)
                                nameLabel.BackgroundTransparency = 1
                                nameLabel.Text = player.Name
                                nameLabel.TextColor3 = SwipeCC.Config.Theme.Text
                                nameLabel.TextSize = 14
                                nameLabel.Font = Enum.Font.GothamBold
                                nameLabel.TextStrokeTransparency = 0.5
                                nameLabel.Parent = billboard
                                
                                local distLabel = Instance.new("TextLabel")
                                distLabel.Size = UDim2.new(1, 0, 0, 15)
                                distLabel.Position = UDim2.new(0, 0, 1, 25)
                                distLabel.BackgroundTransparency = 1
                                distLabel.Text = tostring(math.floor(distance)) .. " studs"
                                distLabel.TextColor3 = SwipeCC.Config.Theme.TextSecondary
                                distLabel.TextSize = 12
                                distLabel.Font = Enum.Font.Gotham
                                distLabel.TextStrokeTransparency = 0.5
                                distLabel.Parent = billboard
                                
                                SwipeCC.Features.ESP.Boxes[player.Name] = billboard
                            end
                        else
                            if SwipeCC.Features.ESP.Boxes[player.Name] then
                                SwipeCC.Features.ESP.Boxes[player.Name]:Destroy()
                                SwipeCC.Features.ESP.Boxes[player.Name] = nil
                            end
                        end
                    end
                end
                
                -- Удаляем ESP для покинувших игроков
                for playerName, billboard in pairs(SwipeCC.Features.ESP.Boxes) do
                    local player = Players:FindFirstChild(playerName)
                    if not player then
                        billboard:Destroy()
                        SwipeCC.Features.ESP.Boxes[playerName] = nil
                    end
                end
            end)
        else
            if SwipeCC.Features.ESP.Connection then
                SwipeCC.Features.ESP.Connection:Disconnect()
            end
            for _, billboard in pairs(SwipeCC.Features.ESP.Boxes) do
                billboard:Destroy()
            end
            SwipeCC.Features.ESP.Boxes = {}
        end
    end
}

SwipeCC.Features.Fullbright = {
    State = false,
    OriginalBrightness = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.Fullbright.OriginalBrightness = Lighting.Brightness
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.FogEnd = math.huge
        else
            Lighting.Brightness = SwipeCC.Features.Fullbright.OriginalBrightness or 1
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
        end
    end
}

SwipeCC.Features.RemoveFog = {
    State = false,
    OriginalFogEnd = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.RemoveFog.OriginalFogEnd = Lighting.FogEnd
            Lighting.FogEnd = math.huge
        else
            Lighting.FogEnd = SwipeCC.Features.RemoveFog.OriginalFogEnd or 1000
        end
    end
}

SwipeCC.Features.FOVChanger = {
    State = 70,
    Execute = function(value)
        Camera.FieldOfView = value
    end
}

SwipeCC.Features.Crosshair = {
    State = false,
    CrosshairGui = nil,
    Execute = function(state)
        if state then
            local crosshairGui = Instance.new("ScreenGui")
            crosshairGui.Name = "Crosshair"
            crosshairGui.ResetOnSpawn = false
            crosshairGui.Parent = LocalPlayer.PlayerGui
            
            -- Горизонтальная линия
            local hLine = Instance.new("Frame")
            hLine.Size = UDim2.new(0, 20, 0, 2)
            hLine.Position = UDim2.new(0.5, -10, 0.5, -1)
            hLine.BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
            hLine.BorderSizePixel = 0
            hLine.Parent = crosshairGui
            
            -- Вертикальная линия
            local vLine = Instance.new("Frame")
            vLine.Size = UDim2.new(0, 2, 0, 20)
            vLine.Position = UDim2.new(0.5, -1, 0.5, -10)
            vLine.BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
            vLine.BorderSizePixel = 0
            vLine.Parent = crosshairGui
            
            -- Центральная точка
            local center = Instance.new("Frame")
            center.Size = UDim2.new(0, 4, 0, 4)
            center.Position = UDim2.new(0.5, -2, 0.5, -2)
            center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            center.BorderSizePixel = 0
            center.Parent = crosshairGui
            
            local centerCorner = Instance.new("UICorner")
            centerCorner.CornerRadius = UDim.new(0, 2)
            centerCorner.Parent = center
            
            SwipeCC.Features.Crosshair.CrosshairGui = crosshairGui
        else
            if SwipeCC.Features.Crosshair.CrosshairGui then
                SwipeCC.Features.Crosshair.CrosshairGui:Destroy()
            end
        end
    end
}

SwipeCC.Features.Chams = {
    State = false,
    Highlights = {},
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.Chams.Connection = Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function(char)
                    if char:FindFirstChild("HumanoidRootPart") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ChamHighlight"
                        highlight.FillColor = SwipeCC.Config.Theme.AccentColor
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = SwipeCC.Config.Theme.AccentColor
                        highlight.OutlineTransparency = 0
                        highlight.Parent = char
                        SwipeCC.Features.Chams.Highlights[player.Name] = highlight
                    end
                end)
            end)
            
            -- Для существующих игроков
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if player.Character:FindFirstChild("HumanoidRootPart") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ChamHighlight"
                        highlight.FillColor = SwipeCC.Config.Theme.AccentColor
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = SwipeCC.Config.Theme.AccentColor
                        highlight.OutlineTransparency = 0
                        highlight.Parent = player.Character
                        SwipeCC.Features.Chams.Highlights[player.Name] = highlight
                    end
                end
            end
        else
            if SwipeCC.Features.Chams.Connection then
                SwipeCC.Features.Chams.Connection:Disconnect()
            end
            for _, highlight in pairs(SwipeCC.Features.Chams.Highlights) do
                highlight:Destroy()
            end
            SwipeCC.Features.Chams.Highlights = {}
        end
    end
}

-- World Tab Features
SwipeCC.Features.TimeOfDay = {
    State = 12,
    Execute = function(value)
        Lighting.ClockTime = value
    end
}

SwipeCC.Features.RemoveShadows = {
    State = false,
    OriginalShadows = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.RemoveShadows.OriginalShadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
        else
            Lighting.GlobalShadows = SwipeCC.Features.RemoveShadows.OriginalShadows or true
        end
    end
}

SwipeCC.Features.AmbientChanger = {
    State = Color3.fromRGB(127, 127, 127),
    Execute = function(color)
        Lighting.Ambient = color
    end
}

SwipeCC.Features.RemoveTextures = {
    State = false,
    OriginalTextures = {},
    Execute = function(state)
        if state then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    SwipeCC.Features.RemoveTextures.OriginalTextures[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        else
            for obj, material in pairs(SwipeCC.Features.RemoveTextures.OriginalTextures) do
                if obj and obj.Parent then
                    obj.Material = material
                end
            end
            SwipeCC.Features.RemoveTextures.OriginalTextures = {}
        end
    end
}

SwipeCC.Features.Gravity = {
    State = 196.2,
    Execute = function(value)
        workspace.Gravity = value
    end
}

-- Misc Tab Features
SwipeCC.Features.ChatSpy = {
    State = false,
    Connection = nil,
    Execute = function(state)
        if state then
            SwipeCC.Features.ChatSpy.Connection = Players.PlayerAdded:Connect(function(player)
                player.Chatted:Connect(function(message)
                    if player ~= LocalPlayer then
                        SwipeCC.Utils:Notify("Chat Spy", player.Name .. ": " .. message, 5)
                    end
                end)
            end)
            
            -- Для существующих игроков
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    player.Chatted:Connect(function(message)
                        SwipeCC.Utils:Notify("Chat Spy", player.Name .. ": " .. message, 5)
                    end)
                end
            end
        else
            if SwipeCC.Features.ChatSpy.Connection then
                SwipeCC.Features.ChatSpy.Connection:Disconnect()
            end
        end
    end
}

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ GUI ЭЛЕМЕНТОВ
-- ============================================
function SwipeCC:PopulateGUI()
    -- Main Tab
    SwipeCC.UI.SelectTab = function(tab) 
        for name, btn in pairs(SwipeCC.UI.Tabs) do
            btn.BackgroundColor3 = SwipeCC.Config.Theme.Background
            btn.TextColor3 = SwipeCC.Config.Theme.Text
            if SwipeCC.UI.Pages[name] then
                SwipeCC.UI.Pages[name].Visible = false
            end
        end
        if SwipeCC.UI.Tabs[tab] then
            SwipeCC.UI.Tabs[tab].BackgroundColor3 = SwipeCC.Config.Theme.AccentColor
            SwipeCC.UI.Tabs[tab].TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SwipeCC.UI.Pages[tab] then
            SwipeCC.UI.Pages[tab].Visible = true
        end
    end
    
    -- Main
    SwipeCC.UI.SelectTab("Main")
    SwipeCC.UI.CreateButton("Rejoin", function() SwipeCC.Features.Rejoin.Execute() end)
    SwipeCC.UI.CreateButton("Server Hop", function() SwipeCC.Features.ServerHop.Execute() end)
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, 0, 0, 60)
    infoFrame.BackgroundColor3 = SwipeCC.Config.Theme.Secondary
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = SwipeCC.UI.Pages["Main"]
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 6)
    infoCorner.Parent = infoFrame
    
    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingLeft = UDim.new(0, 12)
    infoPadding.Parent = infoFrame
    
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Size = UDim2.new(1, 0, 1, 0)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "\nPlayers: " .. #Players:GetPlayers() .. "\nPing: " .. tostring(math.floor(LocalPlayer:GetNetworkPing())) .. "ms"
    gameInfo.TextColor3 = SwipeCC.Config.Theme.Text
    gameInfo.TextSize = 13
    gameInfo.Font = Enum.Font.Gotham
    gameInfo.TextXAlignment = Enum.TextXAlignment.Left
    gameInfo.TextYAlignment = Enum.TextYAlignment.Top
    gameInfo.Parent = infoFrame
    
    SwipeCC.UI.CreateToggle("FPS Counter", function(state) SwipeCC.Features.FPSCounter.Execute(state) end, true)
    
    -- Player
    SwipeCC.UI.SelectTab("Player")
    SwipeCC.UI.CreateSlider("WalkSpeed", 16, 500, 16, function(value) SwipeCC.Features.WalkSpeed.Execute(value) end)
    SwipeCC.UI.CreateSlider("JumpPower", 50, 500, 50, function(value) SwipeCC.Features.JumpPower.Execute(value) end)
    SwipeCC.UI.CreateToggle("Infinite Jump", function(state) SwipeCC.Features.InfiniteJump.Execute(state) end)
    SwipeCC.UI.CreateToggle("Noclip", function(state) SwipeCC.Features.Noclip.Execute(state) end)
    SwipeCC.UI.CreateToggle("Fly", function(state) SwipeCC.Features.Fly.Execute(state) end)
    SwipeCC.UI.CreateSlider("Fly Speed", 10, 200, 50, function(value) SwipeCC.Features.Fly.Speed = value end)
    SwipeCC.UI.CreateToggle("Click TP (Ctrl+Click)", function(state) SwipeCC.Features.ClickTP.Execute(state) end)
    SwipeCC.UI.CreateToggle("Anti-AFK", function(state) SwipeCC.Features.AntiAFK.Execute(state) end)
    SwipeCC.UI.CreateToggle("God Mode", function(state) SwipeCC.Features.GodMode.Execute(state) end)
    SwipeCC.UI.CreateButton("Reset Character", function() SwipeCC.Features.ResetCharacter.Execute() end)
    
    -- Visuals
    SwipeCC.UI.SelectTab("Visuals")
    SwipeCC.UI.CreateToggle("ESP", function(state) SwipeCC.Features.ESP.Execute(state) end)
    SwipeCC.UI.CreateToggle("Fullbright", function(state) SwipeCC.Features.Fullbright.Execute(state) end)
    SwipeCC.UI.CreateToggle("Remove Fog", function(state) SwipeCC.Features.RemoveFog.Execute(state) end)
    SwipeCC.UI.CreateSlider("FOV", 60, 120, 70, function(value) SwipeCC.Features.FOVChanger.Execute(value) end)
    SwipeCC.UI.CreateToggle("Crosshair", function(state) SwipeCC.Features.Crosshair.Execute(state) end)
    SwipeCC.UI.CreateToggle("Chams", function(state) SwipeCC.Features.Chams.Execute(state) end)
    
    -- World
    SwipeCC.UI.SelectTab("World")
    SwipeCC.UI.CreateSlider("Time of Day", 0, 24, 12, function(value) SwipeCC.Features.TimeOfDay.Execute(value) end)
    SwipeCC.UI.CreateToggle("Remove Shadows", function(state) SwipeCC.Features.RemoveShadows.Execute(state) end)
    SwipeCC.UI.CreateButton("Set Ambient to White", function() SwipeCC.Features.AmbientChanger.Execute(Color3.fromRGB(255, 255, 255)) end)
    SwipeCC.UI.CreateButton("Set Ambient to Default", function() SwipeCC.Features.AmbientChanger.Execute(Color3.fromRGB(127, 127, 127)) end)
    SwipeCC.UI.CreateToggle("Remove Textures", function(state) SwipeCC.Features.RemoveTextures.Execute(state) end)
    SwipeCC.UI.CreateSlider("Gravity", 0, 500, 196.2, function(value) SwipeCC.Features.Gravity.Execute(value) end)
    
    -- Misc
    SwipeCC.UI.SelectTab("Misc")
    SwipeCC.UI.CreateToggle("Chat Spy", function(state) SwipeCC.Features.ChatSpy.Execute(state) end)
    SwipeCC.UI.CreateButton("Rejoin Low Player Server", function() SwipeCC.Features.ServerHop.Execute() end)
    
    -- Settings
    SwipeCC.UI.SelectTab("Settings")
    SwipeCC.UI.CreateDropdown("Theme", {"Dark", "Light"}, function(value) SwipeCC.Theme:ApplyTheme(value) end, "Dark")
    SwipeCC.UI.CreateButton("Save Config", function() SwipeCC.Utils:SaveConfig() end)
    SwipeCC.UI.CreateButton("Load Config", function() SwipeCC.Utils:LoadConfig() end)
    SwipeCC.UI.CreateKeybind("Toggle GUI Key", function(key) SwipeCC.Config.ToggleKey = key end, SwipeCC.Config.ToggleKey)
    SwipeCC.UI.CreateButton("Unload Script", function() SwipeCC:Unload() end)
    
    -- Вернуться на Main
    SwipeCC.UI.SelectTab("Main")
end

-- ============================================
-- ФУНКЦИЯ ВЫГРУЗКИ
-- ============================================
function SwipeCC:Unload()
    SwipeCC.Utils:Notify("Info", "Выгрузка скрипта...", 2)
    
    -- Очистка всех connections
    SwipeCC.Utils:CleanupConnections()
    
    -- Отключение всех активных фич
    for featureName, featureData in pairs(SwipeCC.Features) do
        if featureData.State and featureData.Execute then
            if type(featureData.State) == "boolean" then
                pcall(function() featureData.Execute(false) end)
            end
        end
        if featureData.Connection then
            featureData.Connection:Disconnect()
        end
    end
    
    -- Удаление GUI
    if SwipeCC.GUI and SwipeCC.GUI.ScreenGui then
        SwipeCC.GUI.ScreenGui:Destroy()
    end
    
    -- Удаление из глобального пространства
    getgenv().SwipeCC = nil
    
    SwipeCC.Utils:Notify("Success", "Скрипт выгружен!", 2)
end

-- ============================================
-- ЗАПУСК
-- ============================================
SwipeCC.UI:CreateGUI()
SwipeCC:PopulateGUI()
SwipeCC.Utils:LoadConfig()
SwipeCC.Features.FPSCounter.Execute(true)
SwipeCC.Utils:Notify("Success", "Swipe.cc загружен! Нажмите RightShift для открытия GUI", 4)

return SwipeCC
