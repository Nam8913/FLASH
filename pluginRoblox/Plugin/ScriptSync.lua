-- FLASH Sync Plugin - ScriptSync module
-- Reads Script/LocalScript/ModuleScript source from Studio and sends to server.

local ScriptSync = {}

local DEFAULT_ROOTS = {
	"ServerScriptService",
	"ReplicatedStorage",
	"StarterGui",
	"StarterPlayer",
	"ServerStorage",
}

local lastSourceByPath = {}

local function getRobloxPath(inst)
	local parts = {}
	local current = inst
	while current and current ~= game do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, "/")
end

local function tryGetSource(inst)
	if not inst:IsA("LuaSourceContainer") then
		return nil
	end

	local ok, src = pcall(function()
		return inst.Source
	end)

	if ok then
		return src
	end
	return nil
end

local function getServiceSafe(name)
	local ok, svc = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return svc
	end
	return nil
end

local function syncInstance(state, network, httpService, inst)
	local src = tryGetSource(inst)
	if src == nil then
		return false
	end

	local path = getRobloxPath(inst)
	if lastSourceByPath[path] == src then
		return false
	end

	lastSourceByPath[path] = src
	network.postRequest(state, httpService, {
		type = "sync_lua",
		path = path,
		content = src,
	})
	return true
end

function ScriptSync.syncTree(state, network, httpService, root)
	if root == nil then
		return 0, 0
	end

	local sentCount = 0
	local scannedCount = 0

	local stack = { root }
	while #stack > 0 do
		local inst = stack[#stack]
		stack[#stack] = nil

		scannedCount += 1
		if syncInstance(state, network, httpService, inst) then
			sentCount += 1
		end

		local children = inst:GetChildren()
		for i = 1, #children do
			stack[#stack + 1] = children[i]
		end

		if scannedCount % 300 == 0 then
			task.wait()
		end
	end

	return sentCount, scannedCount
end

function ScriptSync.syncDefaultRoots(state, network, httpService)
	local totalSent = 0
	local totalScanned = 0

	for _, rootName in ipairs(DEFAULT_ROOTS) do
		local root = getServiceSafe(rootName)
		local sent, scanned = ScriptSync.syncTree(state, network, httpService, root)
		totalSent += sent
		totalScanned += scanned
	end

	return totalSent, totalScanned
end

return ScriptSync
