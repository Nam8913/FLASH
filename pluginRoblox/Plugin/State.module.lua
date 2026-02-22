-- FLASH Sync Plugin - State module

local State = {}

function State.new()
	return {
		isConnected = false,
		currentHost = "localhost",
		currentPort = "3000",
		timeBetweenSync = 2,
	}
end

return State
