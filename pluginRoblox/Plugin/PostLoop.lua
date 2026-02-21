-- FLASH Sync Plugin - Sync loop module

local PostLoop = {}

function PostLoop.start(state, network, serializer, httpService)
	local timeSync = 0
	while state.isConnected do
		timeSync = timeSync + state.timeBetweenSync

		if timeSync > 5 then
			timeSync = 0
			local snapshot = serializer.buildSnapshot()
			local json = httpService:JSONEncode(snapshot)
			network.postRequest(state, httpService, {
				type = "sync_script",
				path = "ServerScriptService/Main",
				content = json,
			})
		else
			network.postRequest(state, httpService, {
				type = "ping",
			})
		end

		task.wait(state.timeBetweenSync)
	end
end

return PostLoop
