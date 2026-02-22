-- FLASH Sync Plugin
-- A Roblox Studio plugin to sync with an external server.

local HttpService = game:GetService("HttpService")

local modulesFolder = script

local State = require(modulesFolder:WaitForChild("State"))
local UI = require(modulesFolder:WaitForChild("UI"))
local Network = require(modulesFolder:WaitForChild("Network"))
local Serializer = require(modulesFolder:WaitForChild("Serializer"))
local ScriptSync = require(modulesFolder:WaitForChild("ScriptSync"))

local PostLoop = require(modulesFolder:WaitForChild("PostLoop"))
local GetLoop = require(modulesFolder:WaitForChild("GetLoop"))

local state = State.new()
local ui = UI.create(plugin, state)

local function startPermanentLoop()
	GetLoop.start(state, Network, Serializer, HttpService)
	PostLoop.start(state, Network, Serializer, HttpService)
	
end

local function safePost(data)
	if not state.isConnected then
		warn("FLASH: Not connected")
		return
	end
	Network.postRequest(state, HttpService, data)
end

ui.connectBtn.MouseButton1Click:Connect(function()
	if state.isConnected then
		Network.performDisconnect(state, ui)
	else
		Network.performConnect(state, ui, HttpService)
		task.spawn(startPermanentLoop)
	end
end)

if ui.pullBtn then
	ui.pullBtn.MouseButton1Click:Connect(function()
		safePost({
			type = "pull_code",
			path = "",
			content = "",
		})
	end)
end

if ui.pushBtn then
	ui.pushBtn.MouseButton1Click:Connect(function()
		safePost({
			type = "push_code",
			path = "",
			content = "",
		})
		ScriptSync.syncDefaultRoots(state, Network, HttpService)
	end)
end

if ui.syncExplorerBtn then
	ui.syncExplorerBtn.MouseButton1Click:Connect(function()
		local builtOk, snapshot = pcall(function()
			return Serializer.buildSnapshot()
		end)
		if not builtOk or not snapshot then
			warn("FLASH: Failed to build explorer snapshot")
			return
		end
		local encodedOk, json = pcall(function()
			return HttpService:JSONEncode(snapshot)
		end)
		if not encodedOk or not json then
			warn("FLASH: Failed to encode explorer snapshot")
			return
		end
		safePost({
			type = "sync_explorer",
			path = "",
			content = json,
		})
	end)
end