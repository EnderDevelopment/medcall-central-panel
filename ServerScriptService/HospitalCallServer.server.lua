local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("HospitalCallConfig"))

local remotes = ReplicatedStorage:FindFirstChild("HospitalCallRemotes") or Instance.new("Folder")
remotes.Name = "HospitalCallRemotes"
remotes.Parent = ReplicatedStorage

local requestCall = remotes:FindFirstChild("RequestCall") or Instance.new("RemoteEvent")
requestCall.Name = "RequestCall"
requestCall.Parent = remotes

local updateCall = remotes:FindFirstChild("UpdateCall") or Instance.new("RemoteEvent")
updateCall.Name = "UpdateCall"
updateCall.Parent = remotes

local roomsFolder = Workspace:FindFirstChild("HospitalRooms")
if not roomsFolder then
	roomsFolder = Instance.new("Folder")
	roomsFolder.Name = "HospitalRooms"
	roomsFolder.Parent = Workspace
end

local demo = Workspace:FindFirstChild("HospitalCallDemo")
local hasConfiguredRooms = true
for _, roomName in ipairs(Config.Rooms) do
	local part = roomsFolder:FindFirstChild(roomName)
	if not part or not part:IsA("BasePart") then
		hasConfiguredRooms = false
		break
	end
end

if not hasConfiguredRooms and not demo then
	demo = Instance.new("Folder")
	demo.Name = "HospitalCallDemo"
	demo.Parent = Workspace
	local roomWidth, roomDepth, wallHeight = 18, 18, 13
	local totalWidth = #Config.Rooms * roomWidth
	local startX = -totalWidth / 2 + roomWidth / 2

	local function makePart(name, size, cframe, color, parent)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cframe
		part.Anchored = true
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = parent
		return part
	end

	for index, roomName in ipairs(Config.Rooms) do
		local centerX = startX + (index - 1) * roomWidth
		makePart(roomName .. " Floor", Vector3.new(roomWidth, 1, roomDepth), CFrame.new(centerX, -0.5, 0), Color3.fromRGB(220, 225, 228), demo)
		makePart(roomName .. " Back Wall", Vector3.new(roomWidth, wallHeight, 1), CFrame.new(centerX, wallHeight / 2, -roomDepth / 2), Color3.fromRGB(235, 238, 240), demo)
		if index == 1 then
			makePart(roomName .. " Left Wall", Vector3.new(1, wallHeight, roomDepth), CFrame.new(centerX - roomWidth / 2, wallHeight / 2, 0), Color3.fromRGB(235, 238, 240), demo)
		end
		makePart(roomName .. " Divider", Vector3.new(1, wallHeight, roomDepth), CFrame.new(centerX + roomWidth / 2, wallHeight / 2, 0), Color3.fromRGB(235, 238, 240), demo)
		if not roomsFolder:FindFirstChild(roomName) then
			local console = makePart(roomName, Vector3.new(5, 3.4, 0.45), CFrame.new(centerX, 5.2, -roomDepth / 2 + 0.8) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(35, 41, 48), roomsFolder)
			console.Material = Enum.Material.Metal
		end
	end
end

local callDefinitions = {}
for _, definition in ipairs(Config.Calls) do
	callDefinitions[definition.Name] = definition
end

local activeCalls = {}
local lastRequestAt = {}
local REQUEST_COOLDOWN = 1.25

local function isStaff(player)
	if #Config.StaffUserIds == 0 then
		return true
	end
	for _, userId in ipairs(Config.StaffUserIds) do
		if player.UserId == userId then
			return true
		end
	end
	return false
end

local function isValidRoom(roomName)
	for _, configuredRoom in ipairs(Config.Rooms) do
		if configuredRoom == roomName then
			return true
		end
	end
	return false
end

local function makeSnapshot()
	local snapshot = {}
	for roomName, call in pairs(activeCalls) do
		snapshot[roomName] = {code = call.code, requestedBy = call.requestedBy, requestedAt = call.requestedAt}
	end
	return snapshot
end

local function broadcast()
	updateCall:FireAllClients(makeSnapshot())
end

requestCall.OnServerEvent:Connect(function(player, action, roomName, callName)
	if action == "Sync" then
		updateCall:FireClient(player, makeSnapshot())
		return
	end
	if typeof(action) ~= "string" or typeof(roomName) ~= "string" or not isValidRoom(roomName) then
		return
	end
	local now = os.clock()
	if now - (lastRequestAt[player.UserId] or 0) < REQUEST_COOLDOWN then
		return
	end
	lastRequestAt[player.UserId] = now

	if action == "Call" then
		local definition = callDefinitions[callName]
		if not definition then
			return
		end
		local existing = activeCalls[roomName]
		if existing and callDefinitions[existing.code].Priority > definition.Priority then
			return
		end
		activeCalls[roomName] = {code = callName, requestedBy = player.Name, requestedAt = os.time()}
	elseif action == "Clear" then
		if not isStaff(player) then
			return
		end
		activeCalls[roomName] = nil
	else
		return
	end
	broadcast()
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequestAt[player.UserId] = nil
end)
