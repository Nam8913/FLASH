-- FLASH Sync Plugin - Network module

local Network = {}

function Network.performConnect(state, ui, httpService)
	ui:updateStatus("CONNECTING")

	local cleanHost = (state.currentHost or ""):gsub("/$", "")
	local url = string.format("http://%s:%s", cleanHost, state.currentPort)

	local success, response = pcall(function()
		return httpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = httpService:JSONEncode({
				type = "ping",
				path = "ServerScriptService/Main",
				content = "ping from roblox plugin",
			}),
		})
	end)

	if success then
		state.isConnected = true
		ui:updateStatus("CONNECTED")
		print("FLASH Sync: Successfully connected to " .. url)
	else
		state.isConnected = false
		ui:updateStatus("FAILED")
		warn("FLASH Sync: Connection failed. " .. tostring(response))
	end

	return success, response, url
end

function Network.performDisconnect(state, ui)
	state.isConnected = false
	ui:updateStatus("DISCONNECTED")
	print("FLASH Sync: Disconnected")
end

function Network.postRequest(state, httpService, data)
	local ok, res = pcall(function()
		return httpService:RequestAsync({
			Url = string.format("http://%s:%s", (state.currentHost or ""):gsub("/$", ""), state.currentPort),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = httpService:JSONEncode(data),
		})
	end)

	if not ok then
		warn("FLASH error:", res)
	end

	return ok, res
end

return Network
