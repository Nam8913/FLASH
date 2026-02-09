-- FLASH Sync Plugin
-- A Roblox Studio plugin to sync with an external server.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
-- 1. PLUGIN SETUP & STATE
--------------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("FLASH Sync Tools")
local toggleButton = toolbar:CreateButton(
	"Toggle Window",
	"Open/Close the FLASH Sync window",
	"rbxassetid://4458901886" -- Generic icon, replaced if needed
)
toggleButton.ClickableWhenViewportHidden = true

-- Internal State
local isConnected = false
local currentHost = "localhost"
local currentPort = "3000"

-- Setting
local timeBetweenSync = 2 -- Default sync interval in seconds

--------------------------------------------------------------------------------
-- 2. UI CREATION
--------------------------------------------------------------------------------

-- Create the DockWidgetPluginGui
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be floating initially
	false,   -- Initial enabled state
	false,   -- Don't override previous enabled state
	200,     -- Default width
	300,     -- Default height
	150,     -- Min width
	150      -- Min height
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("FlashSyncWidget", widgetInfo)
widget.Title = "FLASH Sync"

-- Main Background
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(46, 46, 46) -- Dark theme style
background.BorderSizePixel = 0
background.Parent = widget

-- Layout
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = background

-- Padding
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = background

-- Helper function to create styled inputs
local function createInput(placeholder, defaultText, layoutOrder)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.LayoutOrder = layoutOrder
	container.Parent = background

	local label = Instance.new("TextLabel")
	label.Text = placeholder
	label.Size = UDim2.new(1, 0, 0, 15)
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSans
	label.TextSize = 14
	label.Parent = container

	local textBox = Instance.new("TextBox")
	textBox.Text = defaultText
	textBox.Size = UDim2.new(1, 0, 0, 25)
	textBox.Position = UDim2.new(0, 0, 0, 15)
	textBox.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
	textBox.BorderColor3 = Color3.fromRGB(20, 20, 20)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.SourceSans
	textBox.TextSize = 16
	textBox.ClearTextOnFocus = false
	textBox.Parent = container

	return textBox
end

-- Host Input
local hostInput = createInput("Host:", "localhost", 1)
hostInput.FocusLost:Connect(function()
	currentHost = hostInput.Text
end)

-- Port Input
local portInput = createInput("Port:", "3000", 2)
portInput.FocusLost:Connect(function()
	currentPort = portInput.Text
end)

-- Connect Button
local connectBtn = Instance.new("TextButton")
connectBtn.Size = UDim2.new(1, 0, 0, 35)
connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Blue
connectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
connectBtn.Text = "Connect"
connectBtn.Font = Enum.Font.SourceSansBold
connectBtn.TextSize = 18
connectBtn.LayoutOrder = 3
connectBtn.Parent = background
-- Rounded corners for button
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 5)
uiCorner.Parent = connectBtn

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "DISCONNECTED"
statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60) -- Red
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.LayoutOrder = 4
statusLabel.Parent = background

--------------------------------------------------------------------------------
-- 3. NETWORK LOGIC
--------------------------------------------------------------------------------

local function updateStatusUI(status)
	if status == "CONNECTED" then
		statusLabel.Text = "CONNECTED"
		statusLabel.TextColor3 = Color3.fromRGB(60, 200, 60) -- Green
		connectBtn.Text = "Disconnect"
		connectBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red

		hostInput.TextEditable = false
		portInput.TextEditable = false

	elseif status == "CONNECTING" then
		statusLabel.Text = "CONNECTING..."
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Yellow
		connectBtn.Text = "..."

		hostInput.TextEditable = false
		portInput.TextEditable = false

	elseif status == "DISCONNECTED" then
		statusLabel.Text = "DISCONNECTED"
		statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60) -- Red
		connectBtn.Text = "Connect"
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Blue

		hostInput.TextEditable = true
		portInput.TextEditable = true

	elseif status == "FAILED" then
		statusLabel.Text = "FAILED TO CONNECT"
		statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Bright Red
		connectBtn.Text = "Connect"
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Blue

		hostInput.TextEditable = true
		portInput.TextEditable = true
	end
end

local function performConnect()
	updateStatusUI("CONNECTING")

	-- Construct URL
	-- Note: Removing trailing slash if present to avoid double slashes
	local cleanHost = currentHost:gsub("/$", "")
	local url = string.format("http://%s:%s", cleanHost, currentPort)

	-- Perform Request safely
	local success, response = pcall(function()
		
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode({
				type = "ping",
				path = "ServerScriptService/Main",
				content = "ping from roblox plugin"
			})
		})
	end)

	if success then
		isConnected = true
		updateStatusUI("CONNECTED")
		print("FLASH Sync: Successfully connected to " .. url)
	else
		isConnected = false
		updateStatusUI("FAILED")
		warn("FLASH Sync: Connection failed. " .. tostring(response))
	end
end

local function performDisconnect()
	isConnected = false
	updateStatusUI("DISCONNECTED")
	print("FLASH Sync: Disconnected")
end

local function PostRequest(data)

	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = string.format("http://%s:%s", currentHost:gsub("/$", ""), currentPort),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(data)
		})
	end)

	if not ok then
		warn("FLASH error:", res)
	end
end
--------------------------------------------------------------------------------
-- 4. INTERACTION HANDLERS
--------------------------------------------------------------------------------
local EXPLORER_ROOTS = {
	Workspace = true,
	Players = true,
	Lighting = true,
	ReplicatedStorage = true,
	ServerScriptService = true,
	ServerStorage = true,
	StarterGui = true,
	StarterPack = true,
	StarterPlayer = true,
	SoundService = true,
	Chat = true,
	TextChatService = true,
}
local function merge(a, b)
	local result = {}
	for _, v in ipairs(a) do table.insert(result, v) end
	for _, v in ipairs(b) do table.insert(result, v) end
	return result
end
local BASEPART = 
	{
		"Anchored",
		"Size",
		"CFrame",
		"Orientation"
	}
local PROPERTY_MAP = 
	{
		BasePart = BASEPART,
		Part = merge(BASEPART,
			{
				"CanCollide",
				"CanTouch"
			}
		)
	}
function serializeValue(v)
	local t = typeof(v)

	if t == "Vector3" then
		return { v.X, v.Y, v.Z }

	elseif t == "CFrame" then
		return { v:GetComponents() }

	elseif t == "Color3" then
		return { v.R, v.G, v.B }

	elseif t == "BrickColor" then
		return v.Name

	else
		return v
	end
end
local PROPERTY_CACHE = {}

local function getPropertiesFor(className)
	if PROPERTY_CACHE[className] then
		return PROPERTY_CACHE[className]
	end

	local props = PROPERTY_MAP[className]
	if not props then return nil end

	PROPERTY_CACHE[className] = props
	return props
end
local function serializeInstance(inst,level)
	local data = {
		ClassName = inst.ClassName,
		Name = inst.Name,
		Properties = {},
		Attributes = {},
		Children = {}
	}

	-- Attributes
	for k, v in pairs(inst:GetAttributes()) do
		data.Attributes[k] = v
	end

	---- Script source (PLUGIN ONLY)
	--if inst:IsA("LuaSourceContainer") then
	--	local ok, src = pcall(function()
	--		return inst.Source
	--	end)
	--	if ok then
	--		data.Properties.Source = src
	--	end
	--end

	---- BasePart demo
	--if inst:IsA("BasePart") then
	--	data.Properties.Anchored = inst.Anchored
	--	data.Properties.Size = {
	--		inst.Size.X,
	--		inst.Size.Y,
	--		inst.Size.Z
	--	}
	--end

	local props = getPropertiesFor(inst.ClassName)
	if props then
		for _, prop in ipairs(props) do
			local ok, value = pcall(function()
				return inst[prop]
			end)
			if ok then
				data.Properties[prop] = serializeValue(value)
			end
		end
	end

	for _, child in ipairs(inst:GetChildren()) do
		if EXPLORER_ROOTS[child.Name] or level > 0 then
			table.insert(data.Children, serializeInstance(child,level + 1))
		end
	end

	return data
end



local function buildSnapshot()
	return serializeInstance(game,0)
end
-- MAIN LOOP
local function startPermanentLoop()
	local timeSync = 0
	while isConnected do
		timeSync = timeSync + timeBetweenSync

		if timeSync > 5 then
			timeSync = 0
			local snapshot = buildSnapshot()
			local json = HttpService:JSONEncode(snapshot)
			PostRequest({
				type = "sync_script",
				path = "ServerScriptService/Main",
				content = json
			})
		else
			PostRequest({
				type = "ping"
			})
		end


		task.wait(timeBetweenSync)
	end
end
connectBtn.MouseButton1Click:Connect(function()
	if isConnected then
		performDisconnect()
	else
		performConnect()
		task.spawn(startPermanentLoop)
	end
end)

-- Toggle Widget Visibility
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)


-- Initialize UI state
updateStatusUI("DISCONNECTED")