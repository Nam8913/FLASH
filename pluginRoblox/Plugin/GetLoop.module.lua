local GetLoop = {}

local pollIntervalSeconds = 0.5
local syncIntervalSeconds = 5
local running = false
local cursor = 0

local ScriptSync = require(script.Parent:WaitForChild("ScriptSync"))

local function splitPath(path)
	local parts = {}
	for part in string.gmatch(path or "", "[^/]+") do
		table.insert(parts, part)
	end
	return parts
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

local function objectTypeToClassName(objectType)
	local t = tostring(objectType or ""):lower()
	if t == "server.lua" then
		return "Script"
	elseif t == "client.lua" then
		return "LocalScript"
	elseif t == "module.lua" then
		return "ModuleScript"
	end
	return "ModuleScript"
end

local function ensureFolder(parent, name)
	local child = parent:FindFirstChild(name)
	if child then
		return child
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function applyLuaMessage(msg)
	local path = msg.path
	if typeof(path) ~= "string" or path == "" then
		return
	end

	local parts = splitPath(path)
	if #parts < 2 then
		warn("FLASH apply_lua: invalid path", path)
		return
	end

	local root = getServiceSafe(parts[1])
	if not root then
		warn("FLASH apply_lua: unknown service", parts[1])
		return
	end

	local parent = root
	for i = 2, #parts - 1 do
		parent = ensureFolder(parent, parts[i])
	end

	local leafName = parts[#parts]
	local inst = parent:FindFirstChild(leafName)
	if not inst then
		local className = objectTypeToClassName(msg.objectType)
		inst = Instance.new(className)
		inst.Name = leafName
		inst.Parent = parent
	end

	if not inst:IsA("LuaSourceContainer") then
		warn("FLASH apply_lua: target is not LuaSourceContainer", inst.ClassName, path)
		return
	end

	local ok, err = pcall(function()
		inst.Source = msg.content or ""
	end)
	if not ok then
		warn("FLASH apply_lua: failed to set Source", path, err)
	end
end

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
								if msg.type == "apply_lua" then
									applyLuaMessage(msg)
								else
									print("FLASH GetLoop: message", msg.type, msg.path)
								end
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
