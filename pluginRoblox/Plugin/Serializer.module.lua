-- FLASH Sync Plugin - Serializer module

local Serializer = {}

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
	for _, v in ipairs(a) do
		table.insert(result, v)
	end
	for _, v in ipairs(b) do
		table.insert(result, v)
	end
	return result
end

local BASEPART = {
	"Anchored",
	"Size",
	"Position",
	"Orientation",
}
local BASESCRIPT = {
	"Enabled",
	"RunContext",
}

local PROPERTY_MAP = {
	BasePart = BASEPART,
	ModuleScript = BASESCRIPT,
	LocalScript = BASESCRIPT,
	Script = BASESCRIPT,
	Part = merge(BASEPART, {
		"CanCollide",
		"CanTouch",
		"Color",
		"Material",
		"MaterialVariant",
		"Reflectance",
		"Transparency",
		"Locked",
		"Shape",
		"Massless",
		"RootPriority"
	}),
}

local function serializeValue(v)
	local t = typeof(v)
	local rs = v;

	if t == "Vector3" then
		rs = { v.X, v.Y, v.Z }
		--elseif t == "CFrame" then
		--	return { v:GetComponents() }
	elseif t == "Color3" then
		rs = { v.R, v.G, v.B }
	elseif t == "EnumItem" then
		rs = tostring(v.Name)
	end

	--print("serializeValue", v, rs, t, typeof(rs), typeof(rs) == "table")
	return rs;
end

local PROPERTY_CACHE = {}

local function getPropertiesFor(className)
	if PROPERTY_CACHE[className] then
		return PROPERTY_CACHE[className]
	end

	local props = PROPERTY_MAP[className]
	if not props then
		return nil
	end

	PROPERTY_CACHE[className] = props
	return props
end

local function serializeInstance(inst, level)
	local data = {
		ClassName = inst.ClassName,
		Name = inst.Name,
		Properties = {},
		Tags = {},
		Attributes = {},
		Children = {},
	}
	for _, tag in ipairs(inst:GetTags()) do
		table.insert(data.Tags, tag)
	end

	for k, v in pairs(inst:GetAttributes()) do
		data.Attributes[k] = v
	end

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
			table.insert(data.Children, serializeInstance(child, level + 1))
		end
	end

	return data
end

function Serializer.buildSnapshot()
	return serializeInstance(game, 0)
end

return Serializer
