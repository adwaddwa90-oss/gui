--[[
    PotassiumGUI - Custom Drawing GUI Library
    Built for Potassium Executor API
    Peak Performance | Clean-Slate Implementation
]]

local PotassiumGUI = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Config
local Config = {
    Font = 2, -- Plex
    FontSize = 13,
    TitleSize = 16,
    AccentColor = Color3.fromRGB(138, 43, 226),
    Background = Color3.fromRGB(20, 20, 20),
    Secondary = Color3.fromRGB(30, 30, 30),
    Tertiary = Color3.fromRGB(40, 40, 40),
    Border = Color3.fromRGB(55, 55, 55),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(175, 175, 175),
    Disabled = Color3.fromRGB(100, 100, 100),
}

-- Globals
local Windows = {}
local ZIndexCounter = 1
local Dragging = nil
local DragOffset = Vector2.zero
local Connections = {}

-- Utility
local function Create(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpColor(c1, c2, t)
    return Color3.new(Lerp(c1.R, c2.R, t), Lerp(c1.G, c2.G, t), Lerp(c1.B, c2.B, t))
end

local function InBounds(pos, size, point)
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function GetMouse()
    return UserInputService:GetMouseLocation()
end

local function Round(n, d)
    local m = 10^(d or 0)
    return math.floor(n * m + 0.5) / m
end

local function DestroyObjects(tbl)
    for _, obj in pairs(tbl) do
        if typeof(obj) == "table" then
            DestroyObjects(obj)
        else
            pcall(function() obj:Remove() end)
        end
    end
end

local function NextZ()
    ZIndexCounter = ZIndexCounter + 1
    return ZIndexCounter
end

-- Window Class
local Window = {}
Window.__index = Window

function PotassiumGUI:CreateWindow(options)
    options = options or {}
    local self = setmetatable({}, Window)
    
    self.Title = options.Title or "PotassiumGUI"
    self.Size = options.Size or Vector2.new(550, 400)
    self.Position = options.Position or Vector2.new(100, 100)
    self.Visible = true
    self.Tabs = {}
    self.ActiveTab = nil
    self.Objects = {}
    self.BaseZ = NextZ() * 100
    
    -- Main Window Frame
    self.Objects.Background = Create("Square", {
        Position = self.Position,
        Size = self.Size,
        Color = Config.Background,
        Filled = true,
        Visible = true,
        ZIndex = self.BaseZ,
    })
    
    self.Objects.Border = Create("Square", {
        Position = self.Position,
        Size = self.Size,
        Color = Config.Border,
        Filled = false,
        Thickness = 1,
        Visible = true,
        ZIndex = self.BaseZ + 1,
    })
    
    -- Title Bar
    self.Objects.TitleBar = Create("Square", {
        Position = self.Position,
        Size = Vector2.new(self.Size.X, 32),
        Color = Config.Secondary,
        Filled = true,
        Visible = true,
        ZIndex = self.BaseZ + 2,
    })
    
    self.Objects.TitleAccent = Create("Square", {
        Position = self.Position,
        Size = Vector2.new(self.Size.X, 2),
        Color = Config.AccentColor,
        Filled = true,
        Visible = true,
        ZIndex = self.BaseZ + 3,
    })
    
    self.Objects.TitleText = Create("Text", {
        Position = self.Position + Vector2.new(12, 8),
        Text = self.Title,
        Size = Config.TitleSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = true,
        ZIndex = self.BaseZ + 4,
    })
    
    -- Close Button
    self.Objects.CloseBtn = Create("Text", {
        Position = self.Position + Vector2.new(self.Size.X - 22, 8),
        Text = "X",
        Size = Config.TitleSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = true,
        ZIndex = self.BaseZ + 4,
    })
    
    -- Minimize Button
    self.Objects.MinBtn = Create("Text", {
        Position = self.Position + Vector2.new(self.Size.X - 44, 8),
        Text = "-",
        Size = Config.TitleSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = true,
        ZIndex = self.BaseZ + 4,
    })
    
    -- Tab Container
    self.Objects.TabContainer = Create("Square", {
        Position = self.Position + Vector2.new(0, 32),
        Size = Vector2.new(130, self.Size.Y - 32),
        Color = Config.Secondary,
        Filled = true,
        Visible = true,
        ZIndex = self.BaseZ + 2,
    })
    
    self.Objects.TabDivider = Create("Line", {
        From = self.Position + Vector2.new(130, 32),
        To = self.Position + Vector2.new(130, self.Size.Y),
        Color = Config.Border,
        Thickness = 1,
        Visible = true,
        ZIndex = self.BaseZ + 3,
    })
    
    -- Content Area
    self.ContentPosition = self.Position + Vector2.new(140, 42)
    self.ContentSize = Vector2.new(self.Size.X - 150, self.Size.Y - 52)
    
    table.insert(Windows, self)
    self:SetupInputs()
    
    return self
end

function Window:SetupInputs()
    -- Dragging
    local dragConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = GetMouse()
            local titlePos = self.Position
            local titleSize = Vector2.new(self.Size.X - 50, 32)
            
            if InBounds(titlePos, titleSize, mouse) and self.Visible then
                Dragging = self
                DragOffset = mouse - self.Position
            end
            
            -- Close button
            if InBounds(self.Position + Vector2.new(self.Size.X - 26, 6), Vector2.new(20, 20), mouse) then
                self:Destroy()
            end
            
            -- Minimize button
            if InBounds(self.Position + Vector2.new(self.Size.X - 48, 6), Vector2.new(20, 20), mouse) then
                self:ToggleMinimize()
            end
        end
    end)
    
    local dragEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = nil
        end
    end)
    
    local moveConn = RunService.RenderStepped:Connect(function()
        if Dragging == self then
            local mouse = GetMouse()
            self:SetPosition(mouse - DragOffset)
        end
    end)
    
    table.insert(Connections, dragConn)
    table.insert(Connections, dragEndConn)
    table.insert(Connections, moveConn)
end

function Window:SetPosition(pos)
    local delta = pos - self.Position
    self.Position = pos
    
    self.Objects.Background.Position = pos
    self.Objects.Border.Position = pos
    self.Objects.TitleBar.Position = pos
    self.Objects.TitleAccent.Position = pos
    self.Objects.TitleText.Position = pos + Vector2.new(12, 8)
    self.Objects.CloseBtn.Position = pos + Vector2.new(self.Size.X - 22, 8)
    self.Objects.MinBtn.Position = pos + Vector2.new(self.Size.X - 44, 8)
    self.Objects.TabContainer.Position = pos + Vector2.new(0, 32)
    self.Objects.TabDivider.From = pos + Vector2.new(130, 32)
    self.Objects.TabDivider.To = pos + Vector2.new(130, self.Size.Y)
    
    self.ContentPosition = pos + Vector2.new(140, 42)
    
    -- Update tabs
    for i, tab in ipairs(self.Tabs) do
        tab:UpdatePosition(pos, i)
    end
end

function Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    local show = not self.Minimized
    
    self.Objects.Background.Visible = show
    self.Objects.Border.Visible = show
    self.Objects.TabContainer.Visible = show
    self.Objects.TabDivider.Visible = show
    
    for _, tab in ipairs(self.Tabs) do
        tab:SetVisible(show and tab == self.ActiveTab)
        tab.Objects.Button.Visible = show
        tab.Objects.ButtonText.Visible = show
    end
end

function Window:SetVisible(visible)
    self.Visible = visible
    for _, obj in pairs(self.Objects) do
        if typeof(obj) ~= "table" then
            obj.Visible = visible
        end
    end
    for _, tab in ipairs(self.Tabs) do
        tab:SetVisible(visible and tab == self.ActiveTab)
        tab.Objects.Button.Visible = visible
        tab.Objects.ButtonText.Visible = visible
    end
end

function Window:Destroy()
    DestroyObjects(self.Objects)
    for _, tab in ipairs(self.Tabs) do
        tab:Destroy()
    end
    for i, win in ipairs(Windows) do
        if win == self then
            table.remove(Windows, i)
            break
        end
    end
end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Window:CreateTab(name)
    local tab = setmetatable({}, Tab)
    tab.Name = name or "Tab"
    tab.Window = self
    tab.Elements = {}
    tab.Objects = {}
    tab.ScrollOffset = 0
    tab.ContentHeight = 0
    tab.Index = #self.Tabs + 1
    
    local yPos = self.Position.Y + 40 + ((tab.Index - 1) * 32)
    
    tab.Objects.Button = Create("Square", {
        Position = Vector2.new(self.Position.X + 5, yPos),
        Size = Vector2.new(120, 28),
        Color = Config.Tertiary,
        Filled = true,
        Visible = true,
        ZIndex = self.BaseZ + 5,
    })
    
    tab.Objects.ButtonText = Create("Text", {
        Position = Vector2.new(self.Position.X + 15, yPos + 6),
        Text = tab.Name,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = true,
        ZIndex = self.BaseZ + 6,
    })
    
    -- Tab click handler
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = GetMouse()
            if InBounds(tab.Objects.Button.Position, tab.Objects.Button.Size, mouse) and self.Visible then
                self:SelectTab(tab)
            end
        end
    end)
    table.insert(Connections, clickConn)
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    else
        tab:SetVisible(false)
    end
    
    return tab
end

function Window:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        t:SetVisible(t == tab)
        t.Objects.Button.Color = t == tab and Config.AccentColor or Config.Tertiary
        t.Objects.ButtonText.Color = t == tab and Config.Text or Config.SubText
    end
    self.ActiveTab = tab
end

function Tab:UpdatePosition(windowPos, index)
    local yPos = windowPos.Y + 40 + ((index - 1) * 32)
    self.Objects.Button.Position = Vector2.new(windowPos.X + 5, yPos)
    self.Objects.ButtonText.Position = Vector2.new(windowPos.X + 15, yPos + 6)
    
    for _, element in ipairs(self.Elements) do
        element:UpdatePosition()
    end
end

function Tab:SetVisible(visible)
    for _, element in ipairs(self.Elements) do
        element:SetVisible(visible)
    end
end

function Tab:Destroy()
    DestroyObjects(self.Objects)
    for _, element in ipairs(self.Elements) do
        element:Destroy()
    end
end

function Tab:GetNextY()
    return self.Window.ContentPosition.Y + self.ContentHeight - self.ScrollOffset
end

function Tab:AddHeight(h)
    self.ContentHeight = self.ContentHeight + h + 8
end

-- Element Base
local function CreateElement(tab)
    return {
        Tab = tab,
        Window = tab.Window,
        Objects = {},
        Visible = true,
        YOffset = tab.ContentHeight,
    }
end

-- Label Element
function Tab:CreateLabel(text)
    local elem = CreateElement(self)
    elem.Text = text or "Label"
    
    elem.Objects.Text = Create("Text", {
        Position = Vector2.new(self.Window.ContentPosition.X, self:GetNextY()),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        self.Objects.Text.Visible = v
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        self.Objects.Text.Position = Vector2.new(self.Tab.Window.ContentPosition.X, y)
    end
    
    elem.SetText = function(self, t)
        self.Text = t
        self.Objects.Text.Text = t
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(20)
    table.insert(self.Elements, elem)
    return elem
end

-- Button Element
function Tab:CreateButton(text, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Button"
    elem.Callback = callback or function() end
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Border = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Border,
        Filled = false,
        Thickness = 1,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 11,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 7),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    -- Hover & Click
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            if InBounds(elem.Objects.Background.Position, elem.Objects.Background.Size, mouse) then
                elem.Objects.Background.Color = Config.AccentColor
                task.delay(0.1, function()
                    if elem.Objects.Background then
                        elem.Objects.Background.Color = Config.Tertiary
                    end
                end)
                elem.Callback()
            end
        end
    end)
    table.insert(Connections, clickConn)
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Border.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 7)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(30)
    table.insert(self.Elements, elem)
    return elem
end

-- Toggle Element
function Tab:CreateToggle(text, default, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Toggle"
    elem.Value = default or false
    elem.Callback = callback or function() end
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 7),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.ToggleOuter = Create("Square", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 50, 5),
        Size = Vector2.new(40, 20),
        Color = Config.Border,
        Filled = false,
        Thickness = 1,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 11,
    })
    
    elem.Objects.ToggleInner = Create("Square", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 48, 7),
        Size = Vector2.new(16, 16),
        Color = elem.Value and Config.AccentColor or Config.Disabled,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    local function UpdateToggle()
        elem.Objects.ToggleInner.Color = elem.Value and Config.AccentColor or Config.Disabled
        local baseX = elem.Objects.ToggleOuter.Position.X + 2
        elem.Objects.ToggleInner.Position = Vector2.new(
            elem.Value and baseX + 20 or baseX,
            elem.Objects.ToggleInner.Position.Y
        )
    end
    
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            if InBounds(elem.Objects.Background.Position, elem.Objects.Background.Size, mouse) then
                elem.Value = not elem.Value
                UpdateToggle()
                elem.Callback(elem.Value)
            end
        end
    end)
    table.insert(Connections, clickConn)
    
    elem.SetValue = function(self, v)
        self.Value = v
        UpdateToggle()
    end
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 7)
        self.Objects.ToggleOuter.Position = pos + Vector2.new(self.Tab.Window.ContentSize.X - 50, 5)
        self.Objects.ToggleInner.Position = pos + Vector2.new(
            self.Tab.Window.ContentSize.X - 48 + (self.Value and 20 or 0), 7
        )
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(30)
    table.insert(self.Elements, elem)
    return elem
end

-- Slider Element
function Tab:CreateSlider(text, min, max, default, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Slider"
    elem.Min = min or 0
    elem.Max = max or 100
    elem.Value = default or min
    elem.Callback = callback or function() end
    elem.Dragging = false
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    local sliderWidth = self.Window.ContentSize.X - 20
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 45),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 5),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.ValueText = Create("Text", {
        Position = pos + Vector2.new(sliderWidth - 20, 5),
        Text = tostring(elem.Value),
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.SliderBg = Create("Square", {
        Position = pos + Vector2.new(10, 28),
        Size = Vector2.new(sliderWidth, 8),
        Color = Config.Background,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 11,
    })
    
    local fillWidth = ((elem.Value - elem.Min) / (elem.Max - elem.Min)) * sliderWidth
    elem.Objects.SliderFill = Create("Square", {
        Position = pos + Vector2.new(10, 28),
        Size = Vector2.new(fillWidth, 8),
        Color = Config.AccentColor,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    local function UpdateSlider()
        local fillWidth = ((elem.Value - elem.Min) / (elem.Max - elem.Min)) * sliderWidth
        elem.Objects.SliderFill.Size = Vector2.new(math.max(0, fillWidth), 8)
        elem.Objects.ValueText.Text = tostring(Round(elem.Value, 1))
    end
    
    local dragConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            if InBounds(elem.Objects.SliderBg.Position, elem.Objects.SliderBg.Size, mouse) then
                elem.Dragging = true
            end
        end
    end)
    
    local dragEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if elem.Dragging then
                elem.Callback(elem.Value)
            end
            elem.Dragging = false
        end
    end)
    
    local moveConn = RunService.RenderStepped:Connect(function()
        if elem.Dragging and elem.Visible then
            local mouse = GetMouse()
            local sliderPos = elem.Objects.SliderBg.Position
            local percent = math.clamp((mouse.X - sliderPos.X) / sliderWidth, 0, 1)
            elem.Value = elem.Min + (elem.Max - elem.Min) * percent
            UpdateSlider()
        end
    end)
    
    table.insert(Connections, dragConn)
    table.insert(Connections, dragEndConn)
    table.insert(Connections, moveConn)
    
    elem.SetValue = function(self, v)
        self.Value = math.clamp(v, self.Min, self.Max)
        UpdateSlider()
    end
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 5)
        self.Objects.ValueText.Position = pos + Vector2.new(sliderWidth - 20, 5)
        self.Objects.SliderBg.Position = pos + Vector2.new(10, 28)
        self.Objects.SliderFill.Position = pos + Vector2.new(10, 28)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(45)
    table.insert(self.Elements, elem)
    return elem
end

-- Dropdown Element
function Tab:CreateDropdown(text, options, default, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Dropdown"
    elem.Options = options or {}
    elem.Value = default or (options[1] or "")
    elem.Callback = callback or function() end
    elem.Open = false
    elem.OptionObjects = {}
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 7),
        Text = elem.Text .. ": " .. tostring(elem.Value),
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.Arrow = Create("Text", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 20, 7),
        Text = "v",
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.SubText,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.DropBg = Create("Square", {
        Position = pos + Vector2.new(0, 32),
        Size = Vector2.new(self.Window.ContentSize.X, #elem.Options * 25),
        Color = Config.Secondary,
        Filled = true,
        Visible = false,
        ZIndex = self.Window.BaseZ + 50,
    })
    
    -- Create option items
    for i, opt in ipairs(elem.Options) do
        local optObj = {}
        optObj.Background = Create("Square", {
            Position = pos + Vector2.new(0, 32 + (i-1) * 25),
            Size = Vector2.new(self.Window.ContentSize.X, 25),
            Color = Config.Secondary,
            Filled = true,
            Visible = false,
            ZIndex = self.Window.BaseZ + 51,
        })
        optObj.Text = Create("Text", {
            Position = pos + Vector2.new(10, 36 + (i-1) * 25),
            Text = opt,
            Size = Config.FontSize,
            Font = Config.Font,
            Color = Config.SubText,
            Visible = false,
            ZIndex = self.Window.BaseZ + 52,
        })
        elem.OptionObjects[i] = optObj
    end
    
    local function ToggleDropdown()
        elem.Open = not elem.Open
        elem.Objects.DropBg.Visible = elem.Open and elem.Visible
        elem.Objects.Arrow.Text = elem.Open and "^" or "v"
        for _, optObj in ipairs(elem.OptionObjects) do
            optObj.Background.Visible = elem.Open and elem.Visible
            optObj.Text.Visible = elem.Open and elem.Visible
        end
    end
    
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            
            -- Main dropdown click
            if InBounds(elem.Objects.Background.Position, elem.Objects.Background.Size, mouse) then
                ToggleDropdown()
                return
            end
            
            -- Option selection
            if elem.Open then
                for i, optObj in ipairs(elem.OptionObjects) do
                    if InBounds(optObj.Background.Position, optObj.Background.Size, mouse) then
                        elem.Value = elem.Options[i]
                        elem.Objects.Text.Text = elem.Text .. ": " .. tostring(elem.Value)
                        ToggleDropdown()
                        elem.Callback(elem.Value)
                        return
                    end
                end
                -- Click outside closes
                ToggleDropdown()
            end
        end
    end)
    table.insert(Connections, clickConn)
    
    elem.SetValue = function(self, v)
        self.Value = v
        self.Objects.Text.Text = self.Text .. ": " .. tostring(v)
    end
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        self.Objects.Background.Visible = v
        self.Objects.Text.Visible = v
        self.Objects.Arrow.Visible = v
        if not v then
            self.Open = false
            self.Objects.DropBg.Visible = false
            for _, optObj in ipairs(self.OptionObjects) do
                optObj.Background.Visible = false
                optObj.Text.Visible = false
            end
        end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 7)
        self.Objects.Arrow.Position = pos + Vector2.new(self.Tab.Window.ContentSize.X - 20, 7)
        self.Objects.DropBg.Position = pos + Vector2.new(0, 32)
        for i, optObj in ipairs(self.OptionObjects) do
            optObj.Background.Position = pos + Vector2.new(0, 32 + (i-1) * 25)
            optObj.Text.Position = pos + Vector2.new(10, 36 + (i-1) * 25)
        end
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
        for _, optObj in ipairs(self.OptionObjects) do
            DestroyObjects(optObj)
        end
    end
    
    self:AddHeight(30)
    table.insert(self.Elements, elem)
    return elem
end

-- Keybind Element
function Tab:CreateKeybind(text, default, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Keybind"
    elem.Value = default or Enum.KeyCode.None
    elem.Callback = callback or function() end
    elem.Listening = false
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 7),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.KeyText = Create("Text", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 60, 7),
        Text = "[" .. tostring(elem.Value.Name) .. "]",
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.AccentColor,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if elem.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                elem.Value = input.KeyCode
                elem.Objects.KeyText.Text = "[" .. tostring(input.KeyCode.Name) .. "]"
                elem.Listening = false
                elem.Objects.KeyText.Color = Config.AccentColor
            end
            return
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            if InBounds(elem.Objects.Background.Position, elem.Objects.Background.Size, mouse) then
                elem.Listening = true
                elem.Objects.KeyText.Text = "[...]"
                elem.Objects.KeyText.Color = Color3.fromRGB(255, 200, 0)
            end
        end
        
        -- Fire callback when key pressed
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == elem.Value then
            elem.Callback(elem.Value)
        end
    end)
    table.insert(Connections, clickConn)
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 7)
        self.Objects.KeyText.Position = pos + Vector2.new(self.Tab.Window.ContentSize.X - 60, 7)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(30)
    table.insert(self.Elements, elem)
    return elem
end

-- TextBox Element
function Tab:CreateTextBox(text, placeholder, callback)
    local elem = CreateElement(self)
    elem.Text = text or "TextBox"
    elem.Placeholder = placeholder or "Enter text..."
    elem.Value = ""
    elem.Callback = callback or function() end
    elem.Focused = false
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 50),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Label = Create("Text", {
        Position = pos + Vector2.new(10, 5),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.InputBg = Create("Square", {
        Position = pos + Vector2.new(10, 24),
        Size = Vector2.new(self.Window.ContentSize.X - 20, 22),
        Color = Config.Background,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 11,
    })
    
    elem.Objects.InputText = Create("Text", {
        Position = pos + Vector2.new(14, 27),
        Text = elem.Placeholder,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Disabled,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            if InBounds(elem.Objects.InputBg.Position, elem.Objects.InputBg.Size, mouse) then
                elem.Focused = true
                elem.Objects.InputBg.Color = Config.Tertiary
            else
                if elem.Focused then
                    elem.Focused = false
                    elem.Objects.InputBg.Color = Config.Background
                    elem.Callback(elem.Value)
                end
            end
        end
        
        if elem.Focused and input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key == Enum.KeyCode.Return then
                elem.Focused = false
                elem.Objects.InputBg.Color = Config.Background
                elem.Callback(elem.Value)
            elseif key == Enum.KeyCode.Backspace then
                elem.Value = elem.Value:sub(1, -2)
            else
                local char = UserInputService:GetStringForKeyCode(key)
                if char and #char == 1 then
                    elem.Value = elem.Value .. char
                end
            end
            elem.Objects.InputText.Text = #elem.Value > 0 and elem.Value or elem.Placeholder
            elem.Objects.InputText.Color = #elem.Value > 0 and Config.Text or Config.Disabled
        end
    end)
    table.insert(Connections, clickConn)
    
    elem.SetValue = function(self, v)
        self.Value = v
        self.Objects.InputText.Text = #v > 0 and v or self.Placeholder
        self.Objects.InputText.Color = #v > 0 and Config.Text or Config.Disabled
    end
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Label.Position = pos + Vector2.new(10, 5)
        self.Objects.InputBg.Position = pos + Vector2.new(10, 24)
        self.Objects.InputText.Position = pos + Vector2.new(14, 27)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(50)
    table.insert(self.Elements, elem)
    return elem
end

-- Color Picker Element
function Tab:CreateColorPicker(text, default, callback)
    local elem = CreateElement(self)
    elem.Text = text or "Color"
    elem.Value = default or Color3.fromRGB(255, 255, 255)
    elem.Callback = callback or function() end
    elem.Open = false
    elem.Hue = 0
    elem.Sat = 1
    elem.Val = 1
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    
    elem.Objects.Background = Create("Square", {
        Position = pos,
        Size = Vector2.new(self.Window.ContentSize.X, 30),
        Color = Config.Tertiary,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(10, 7),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.Text,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.Preview = Create("Square", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 40, 5),
        Size = Vector2.new(30, 20),
        Color = elem.Value,
        Filled = true,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 12,
    })
    
    elem.Objects.PreviewBorder = Create("Square", {
        Position = pos + Vector2.new(self.Window.ContentSize.X - 40, 5),
        Size = Vector2.new(30, 20),
        Color = Config.Border,
        Filled = false,
        Thickness = 1,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 13,
    })
    
    -- Picker popup
    elem.Objects.PickerBg = Create("Square", {
        Position = pos + Vector2.new(0, 32),
        Size = Vector2.new(180, 180),
        Color = Config.Secondary,
        Filled = true,
        Visible = false,
        ZIndex = self.Window.BaseZ + 60,
    })
    
    -- Saturation/Value square
    elem.Objects.SVSquare = Create("Square", {
        Position = pos + Vector2.new(10, 42),
        Size = Vector2.new(130, 130),
        Color = Color3.fromHSV(elem.Hue, 1, 1),
        Filled = true,
        Visible = false,
        ZIndex = self.Window.BaseZ + 61,
    })
    
    -- Hue bar
    elem.Objects.HueBar = Create("Square", {
        Position = pos + Vector2.new(150, 42),
        Size = Vector2.new(20, 130),
        Color = Config.Background,
        Filled = true,
        Visible = false,
        ZIndex = self.Window.BaseZ + 61,
    })
    
    elem.Objects.HueIndicator = Create("Square", {
        Position = pos + Vector2.new(150, 42),
        Size = Vector2.new(20, 4),
        Color = Config.Text,
        Filled = true,
        Visible = false,
        ZIndex = self.Window.BaseZ + 62,
    })
    
    elem.Objects.SVIndicator = Create("Circle", {
        Position = pos + Vector2.new(140, 42),
        Radius = 5,
        Color = Config.Text,
        Filled = false,
        Thickness = 2,
        Visible = false,
        ZIndex = self.Window.BaseZ + 62,
    })
    
    local function UpdateColor()
        elem.Value = Color3.fromHSV(elem.Hue, elem.Sat, elem.Val)
        elem.Objects.Preview.Color = elem.Value
        elem.Objects.SVSquare.Color = Color3.fromHSV(elem.Hue, 1, 1)
        elem.Callback(elem.Value)
    end
    
    local svDrag, hueDrag = false, false
    
    local clickConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and elem.Visible then
            local mouse = GetMouse()
            
            if InBounds(elem.Objects.Preview.Position, elem.Objects.Preview.Size, mouse) then
                elem.Open = not elem.Open
                elem.Objects.PickerBg.Visible = elem.Open
                elem.Objects.SVSquare.Visible = elem.Open
                elem.Objects.HueBar.Visible = elem.Open
                elem.Objects.HueIndicator.Visible = elem.Open
                elem.Objects.SVIndicator.Visible = elem.Open
                return
            end
            
            if elem.Open then
                if InBounds(elem.Objects.SVSquare.Position, elem.Objects.SVSquare.Size, mouse) then
                    svDrag = true
                elseif InBounds(elem.Objects.HueBar.Position, elem.Objects.HueBar.Size, mouse) then
                    hueDrag = true
                end
            end
        end
    end)
    
    local releaseConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag, hueDrag = false, false
        end
    end)
    
    local moveConn = RunService.RenderStepped:Connect(function()
        if not elem.Visible or not elem.Open then return end
        local mouse = GetMouse()
        
        if svDrag then
            local svPos = elem.Objects.SVSquare.Position
            local svSize = elem.Objects.SVSquare.Size
            elem.Sat = math.clamp((mouse.X - svPos.X) / svSize.X, 0, 1)
            elem.Val = 1 - math.clamp((mouse.Y - svPos.Y) / svSize.Y, 0, 1)
            elem.Objects.SVIndicator.Position = Vector2.new(
                svPos.X + elem.Sat * svSize.X,
                svPos.Y + (1 - elem.Val) * svSize.Y
            )
            UpdateColor()
        end
        
        if hueDrag then
            local huePos = elem.Objects.HueBar.Position
            local hueSize = elem.Objects.HueBar.Size
            elem.Hue = math.clamp((mouse.Y - huePos.Y) / hueSize.Y, 0, 1)
            elem.Objects.HueIndicator.Position = Vector2.new(huePos.X, huePos.Y + elem.Hue * hueSize.Y - 2)
            UpdateColor()
        end
    end)
    
    table.insert(Connections, clickConn)
    table.insert(Connections, releaseConn)
    table.insert(Connections, moveConn)
    
    elem.SetValue = function(self, color)
        self.Value = color
        self.Objects.Preview.Color = color
        local h, s, v = Color3.toHSV(color)
        self.Hue, self.Sat, self.Val = h, s, v
    end
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        self.Objects.Background.Visible = v
        self.Objects.Text.Visible = v
        self.Objects.Preview.Visible = v
        self.Objects.PreviewBorder.Visible = v
        if not v then
            self.Open = false
            self.Objects.PickerBg.Visible = false
            self.Objects.SVSquare.Visible = false
            self.Objects.HueBar.Visible = false
            self.Objects.HueIndicator.Visible = false
            self.Objects.SVIndicator.Visible = false
        end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        self.Objects.Background.Position = pos
        self.Objects.Text.Position = pos + Vector2.new(10, 7)
        self.Objects.Preview.Position = pos + Vector2.new(self.Tab.Window.ContentSize.X - 40, 5)
        self.Objects.PreviewBorder.Position = pos + Vector2.new(self.Tab.Window.ContentSize.X - 40, 5)
        self.Objects.PickerBg.Position = pos + Vector2.new(0, 32)
        self.Objects.SVSquare.Position = pos + Vector2.new(10, 42)
        self.Objects.HueBar.Position = pos + Vector2.new(150, 42)
        self.Objects.HueIndicator.Position = pos + Vector2.new(150, 42 + self.Hue * 130 - 2)
        self.Objects.SVIndicator.Position = pos + Vector2.new(10 + self.Sat * 130, 42 + (1 - self.Val) * 130)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(30)
    table.insert(self.Elements, elem)
    return elem
end

-- Section/Separator Element
function Tab:CreateSection(text)
    local elem = CreateElement(self)
    elem.Text = text or "Section"
    
    local pos = Vector2.new(self.Window.ContentPosition.X, self:GetNextY())
    local width = self.Window.ContentSize.X
    
    elem.Objects.LineLeft = Create("Line", {
        From = pos + Vector2.new(0, 8),
        To = pos + Vector2.new(40, 8),
        Color = Config.Border,
        Thickness = 1,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.Text = Create("Text", {
        Position = pos + Vector2.new(45, 0),
        Text = elem.Text,
        Size = Config.FontSize,
        Font = Config.Font,
        Color = Config.AccentColor,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.Objects.LineRight = Create("Line", {
        From = pos + Vector2.new(55 + elem.Objects.Text.TextBounds.X, 8),
        To = pos + Vector2.new(width, 8),
        Color = Config.Border,
        Thickness = 1,
        Visible = self.Window.ActiveTab == self,
        ZIndex = self.Window.BaseZ + 10,
    })
    
    elem.SetVisible = function(self, v)
        self.Visible = v
        for _, obj in pairs(self.Objects) do obj.Visible = v end
    end
    
    elem.UpdatePosition = function(self)
        local y = self.Tab.Window.ContentPosition.Y + self.YOffset - self.Tab.ScrollOffset
        local pos = Vector2.new(self.Tab.Window.ContentPosition.X, y)
        local width = self.Tab.Window.ContentSize.X
        self.Objects.LineLeft.From = pos + Vector2.new(0, 8)
        self.Objects.LineLeft.To = pos + Vector2.new(40, 8)
        self.Objects.Text.Position = pos + Vector2.new(45, 0)
        self.Objects.LineRight.From = pos + Vector2.new(55 + self.Objects.Text.TextBounds.X, 8)
        self.Objects.LineRight.To = pos + Vector2.new(width, 8)
    end
    
    elem.Destroy = function(self)
        DestroyObjects(self.Objects)
    end
    
    self:AddHeight(16)
    table.insert(self.Elements, elem)
    return elem
end

-- Global Config Methods
function PotassiumGUI:SetAccentColor(color)
    Config.AccentColor = color
end

function PotassiumGUI:SetFont(fontId)
    Config.Font = fontId
end

function PotassiumGUI:DestroyAll()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    
    for _, win in ipairs(Windows) do
        win:Destroy()
    end
    Windows = {}
    
    pcall(cleardrawcache)
end

return PotassiumGUI
