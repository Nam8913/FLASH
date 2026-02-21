local GetLoop = {}

local pollIntervalSeconds = 0.5
local syncIntervalSeconds = 5
local running = false
local cursor = 0

local ScriptSync = require(script.Parent:WaitForChild("ScriptSync"))

function GetLoop.start(state, network, serializer, httpService)
	if running then
		return
	end

	running = true

	task.spawn(function()
		local lastSyncAt = 0
		while running and state.isConnected do
			local ok, res = network.postRequest(state, httpService, {
				type = "poll",
				path = "",
				content = tostring(cursor),
			})

			if ok and res and res.Success and res.Body and #res.Body > 0 then
				local decodedOk, payload = pcall(function()
					return httpService:JSONDecode(res.Body)
				end)

				if decodedOk and payload then
					local messages = payload.messages
					if typeof(messages) == "table" then
						for _, msg in ipairs(messages) do
							if typeof(msg) == "table" then
								if msg.id ~= nil then
									cursor = msg.id
								end
								print("FLASH GetLoop: message", msg.type, msg.path)
							end
						end
					end
				end
			end

			local now = os.clock()
			if now - lastSyncAt >= syncIntervalSeconds then
				lastSyncAt = now
				print("FLASH GetLoop: syncing lua")
				ScriptSync.syncDefaultRoots(state, network, httpService)
				print("FLASH GetLoop: syncing lua done")
			end

			task.wait(pollIntervalSeconds)
		end

		running = false
		print("End Get Loop")
	end)
end

function GetLoop.stop()
	running = false
end

return GetLoop
