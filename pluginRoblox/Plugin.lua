-- FLASH Sync Plugin
-- A Roblox Studio plugin to sync with an external server.

local HttpService = game:GetService("HttpService")

local modulesFolder = script:WaitForChild("modules")

local State = require(modulesFolder:WaitForChild("State"))
local UI = require(modulesFolder:WaitForChild("UI"))
local Network = require(modulesFolder:WaitForChild("Network"))
local Serializer = require(modulesFolder:WaitForChild("Serializer"))

local PostLoop = require(modulesFolder:WaitForChild("PostLoop"))
local GetLoop = require(modulesFolder:WaitForChild("GetLoop"))

local state = State.new()
local ui = UI.create(plugin, state)

local function startPermanentLoop()
	GetLoop.start(state, Network, Serializer, HttpService)
	PostLoop.start(state, Network, Serializer, HttpService)
	
end

ui.connectBtn.MouseButton1Click:Connect(function()
	if state.isConnected then
		Network.performDisconnect(state, ui)
	else
		Network.performConnect(state, ui, HttpService)
		task.spawn(startPermanentLoop)
	end
end)