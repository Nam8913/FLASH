-- FLASH Sync Plugin - UI module

local UI = {}

function UI.create(plugin, state)
	-- 1. PLUGIN SETUP
	local toolbar = plugin:CreateToolbar("FLASH Sync Tools")
	local toggleButton = toolbar:CreateButton(
		"Toggle Window",
		"Open/Close the FLASH Sync window",
		"rbxassetid://4458901886"
	)
	toggleButton.ClickableWhenViewportHidden = true

	-- 2. UI CREATION
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		200,
		300,
		150,
		150
	)

	local widget = plugin:CreateDockWidgetPluginGuiAsync("FlashSyncWidget", widgetInfo)
	widget.Title = "FLASH Sync"

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	background.BorderSizePixel = 0
	background.Parent = widget

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = background

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = background

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

	local hostInput = createInput("Host:", state.currentHost or "localhost", 1)
	hostInput.FocusLost:Connect(function()
		state.currentHost = hostInput.Text
	end)

	local portInput = createInput("Port:", state.currentPort or "3000", 2)
	portInput.FocusLost:Connect(function()
		state.currentPort = portInput.Text
	end)

	local connectBtn = Instance.new("TextButton")
	connectBtn.Size = UDim2.new(1, 0, 0, 35)
	connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	connectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	connectBtn.Text = "Connect"
	connectBtn.Font = Enum.Font.SourceSansBold
	connectBtn.TextSize = 18
	connectBtn.LayoutOrder = 3
	connectBtn.Parent = background

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 5)
	uiCorner.Parent = connectBtn

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 30)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "DISCONNECTED"
	statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
	statusLabel.Font = Enum.Font.SourceSansBold
	statusLabel.TextSize = 16
	statusLabel.LayoutOrder = 4
	statusLabel.Parent = background

	local ui = {
		toolbar = toolbar,
		toggleButton = toggleButton,
		widget = widget,
		background = background,
		hostInput = hostInput,
		portInput = portInput,
		connectBtn = connectBtn,
		statusLabel = statusLabel,
	}

	function ui:updateStatus(status)
		if status == "CONNECTED" then
			self.statusLabel.Text = "CONNECTED"
			self.statusLabel.TextColor3 = Color3.fromRGB(60, 200, 60)
			self.connectBtn.Text = "Disconnect"
			self.connectBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)

			self.hostInput.TextEditable = false
			self.portInput.TextEditable = false

		elseif status == "CONNECTING" then
			self.statusLabel.Text = "CONNECTING..."
			self.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
			self.connectBtn.Text = "..."

			self.hostInput.TextEditable = false
			self.portInput.TextEditable = false

		elseif status == "DISCONNECTED" then
			self.statusLabel.Text = "DISCONNECTED"
			self.statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
			self.connectBtn.Text = "Connect"
			self.connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)

			self.hostInput.TextEditable = true
			self.portInput.TextEditable = true

		elseif status == "FAILED" then
			self.statusLabel.Text = "FAILED TO CONNECT"
			self.statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			self.connectBtn.Text = "Connect"
			self.connectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)

			self.hostInput.TextEditable = true
			self.portInput.TextEditable = true
		end
	end

	toggleButton.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)

	ui:updateStatus("DISCONNECTED")
	return ui
end

return UI
