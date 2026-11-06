local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local activeCalls = {}
local roomParts = {}
local panelRows = {}
local pulseTweens = {}

local function make(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

-- Build the staff interface before waiting for server objects so setup failures stay visible.
local screenGui = make("ScreenGui", {
	Name = "HospitalCallInterface",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, playerGui)

local toggleButton = make("TextButton", {
	Name = "PanelToggle",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(150, 42),
	BackgroundColor3 = Color3.fromRGB(25, 104, 145),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Text = "HOSPITAL CALLS",
	ZIndex = 3,
}, screenGui)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, toggleButton)

local panel = make("Frame", {
	Name = "StaffPanel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 62),
	Size = UDim2.fromOffset(360, 430),
	BackgroundColor3 = Color3.fromRGB(20, 27, 36),
	BorderSizePixel = 0,
	Visible = true,
	ZIndex = 2,
}, screenGui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, panel)
make("UIStroke", {Color = Color3.fromRGB(79, 96, 113), Thickness = 1}, panel)

make("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(14, 10),
	Size = UDim2.new(1, -28, 0, 28),
	BackgroundTransparency = 1,
	Text = "CENTRAL STAFF PANEL",
	TextColor3 = Color3.fromRGB(240, 244, 248),
	Font = Enum.Font.GothamBold,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
}, panel)

local connectionStatus = make("TextLabel", {
	Name = "ConnectionStatus",
	Position = UDim2.fromOffset(14, 38),
	Size = UDim2.new(1, -28, 0, 22),
	BackgroundTransparency = 1,
	Text = "Starting hospital call system...",
	TextColor3 = Color3.fromRGB(180, 194, 207),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	ZIndex = 3,
}, panel)

local list = make("ScrollingFrame", {
	Name = "RoomList",
	Position = UDim2.fromOffset(10, 68),
	Size = UDim2.new(1, -20, 1, -78),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 3,
}, panel)
make("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, list)

local function fitPanel()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local width = math.max(220, math.min(360, viewport.X - 24))
	local height = math.max(260, math.min(430, viewport.Y - 86))
	panel.Size = UDim2.fromOffset(width, height)
	panel.Position = UDim2.new(1, -12, 0, 62)
end
fitPanel()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
end

toggleButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function showSetupError(message)
	connectionStatus.Text = message
	connectionStatus.TextColor3 = Color3.fromRGB(255, 173, 95)
	warn("Hospital call system: " .. message)
end

local configModule = ReplicatedStorage:WaitForChild("HospitalCallConfig", 10)
if not configModule or not configModule:IsA("ModuleScript") then
	showSetupError("Missing ModuleScript: ReplicatedStorage > HospitalCallConfig")
	return
end

local success, Config = pcall(require, configModule)
if not success or typeof(Config) ~= "table" then
	showSetupError("Could not load HospitalCallConfig. Check the Studio Output window.")
	return
end

local remotes = ReplicatedStorage:WaitForChild("HospitalCallRemotes", 15)
if not remotes then
	showSetupError("Server not running. Add HospitalCallServer to ServerScriptService.")
	return
end
local requestCall = remotes:WaitForChild("RequestCall", 10)
local updateCall = remotes:WaitForChild("UpdateCall", 10)
if not requestCall or not updateCall then
	showSetupError("Server remotes are missing. Check the server script in Output.")
	return
end

local roomsFolder = workspace:WaitForChild("HospitalRooms", 15)
if not roomsFolder then
	showSetupError("HospitalRooms was not created. Check the server script in Output.")
	return
end

local function isStaff()
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

local function makePanelRow(roomName, order)
	local row = make("Frame", {
		Name = roomName,
		Size = UDim2.new(1, -4, 0, 62),
		BackgroundColor3 = Color3.fromRGB(37, 47, 59),
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 3,
	}, list)
	make("UICorner", {CornerRadius = UDim.new(0, 5)}, row)
	local status = make("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(10, 5),
		Size = UDim2.new(1, -88, 1, -10),
		BackgroundTransparency = 1,
		Text = roomName .. "\nNo active call",
		TextColor3 = Color3.fromRGB(220, 226, 233),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		ZIndex = 4,
	}, row)
	local clearButton = make("TextButton", {
		Name = "Clear",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(64, 32),
		BackgroundColor3 = Color3.fromRGB(70, 82, 96),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = "CLEAR",
		Visible = isStaff(),
		ZIndex = 4,
	}, row)
	make("UICorner", {CornerRadius = UDim.new(0, 4)}, clearButton)
	clearButton.Activated:Connect(function()
		requestCall:FireServer("Clear", roomName)
	end)
	return {status = status}
end

for index, roomName in ipairs(Config.Rooms) do
	panelRows[roomName] = makePanelRow(roomName, index)
end

local function setRoomAppearance(roomName, call)
	local part = roomParts[roomName]
	if not part then
		return
	end
	local surface = part:FindFirstChild("HospitalWallConsole")
	local body = surface and surface:FindFirstChild("Body")
	local status = body and body:FindFirstChild("Status")
	if not body or not status then
		return
	end

	local previousTween = pulseTweens[roomName]
	if previousTween then
		previousTween:Cancel()
		pulseTweens[roomName] = nil
	end

	if call then
		local definition
		for _, item in ipairs(Config.Calls) do
			if item.Name == call.code then
				definition = item
				break
			end
		end
		if not definition then
			return
		end
		status.Text = string.upper(call.code)
		status.BackgroundColor3 = definition.Color
		local tween = TweenService:Create(status, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			BackgroundColor3 = definition.Color:Lerp(Color3.new(1, 1, 1), 0.38),
		})
		pulseTweens[roomName] = tween
		tween:Play()
	else
		status.Text = "NO CALL"
		status.BackgroundColor3 = Color3.fromRGB(67, 77, 88)
	end
end

local function createRoomConsole(roomName, part)
	roomParts[roomName] = part
	local oldGui = part:FindFirstChild("HospitalWallConsole")
	if oldGui then
		oldGui:Destroy()
	end

	local surface = make("SurfaceGui", {
		Name = "HospitalWallConsole",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 55,
		LightInfluence = 0,
		AlwaysOnTop = true,
		Active = true,
		Adornee = part,
	}, part)
	local body = make("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(29, 34, 42),
		BorderSizePixel = 0,
	}, surface)
	make("UICorner", {CornerRadius = UDim.new(0.06, 0)}, body)
	make("TextLabel", {
		Name = "RoomName",
		Position = UDim2.new(0.05, 0, 0.03, 0),
		Size = UDim2.new(0.9, 0, 0.13, 0),
		BackgroundTransparency = 1,
		Text = string.upper(roomName),
		TextColor3 = Color3.fromRGB(230, 235, 240),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		ZIndex = 2,
	}, body)
	local status = make("TextLabel", {
		Name = "Status",
		Position = UDim2.new(0.05, 0, 0.18, 0),
		Size = UDim2.new(0.9, 0, 0.2, 0),
		BackgroundColor3 = Color3.fromRGB(67, 77, 88),
		Text = "NO CALL",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		ZIndex = 2,
	}, body)
	make("UICorner", {CornerRadius = UDim.new(0.08, 0)}, status)

	local buttonHolder = make("Frame", {
		Name = "Buttons",
		Position = UDim2.new(0.05, 0, 0.42, 0),
		Size = UDim2.new(0.9, 0, 0.54, 0),
		BackgroundTransparency = 1,
	}, body)
	make("UIGridLayout", {
		CellPadding = UDim2.new(0.025, 0, 0.035, 0),
		CellSize = UDim2.new(0.475, 0, 0.22, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, buttonHolder)

	for index, definition in ipairs(Config.Calls) do
		local button = make("TextButton", {
			Name = "Call" .. index,
			BackgroundColor3 = definition.Color,
			Text = definition.Name,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextWrapped = true,
			LayoutOrder = index,
			Active = true,
			Selectable = true,
		}, buttonHolder)
		make("UICorner", {CornerRadius = UDim.new(0.08, 0)}, button)
		button.Activated:Connect(function()
			requestCall:FireServer("Call", roomName, definition.Name)
		end)
	end

	local sound = make("Sound", {
		Name = "HospitalCallBeep",
		SoundId = Config.BeepSoundId,
		Volume = Config.BeepVolume,
		RollOffMaxDistance = Config.BeepMaxDistance,
	}, part)
	setRoomAppearance(roomName, activeCalls[roomName])
end

local missingRooms = {}
for _, roomName in ipairs(Config.Rooms) do
	local part = roomsFolder:FindFirstChild(roomName)
	if part and part:IsA("BasePart") then
		createRoomConsole(roomName, part)
	else
		table.insert(missingRooms, roomName)
		warn("Hospital call room is missing a BasePart named " .. roomName)
	end
end

if #missingRooms > 0 then
	connectionStatus.Text = "Missing room parts: " .. table.concat(missingRooms, ", ")
	connectionStatus.TextColor3 = Color3.fromRGB(255, 173, 95)
else
	connectionStatus.Text = "Connected  |  " .. tostring(#Config.Rooms) .. " rooms"
	connectionStatus.TextColor3 = Color3.fromRGB(115, 220, 155)
end

updateCall.OnClientEvent:Connect(function(snapshot)
	if typeof(snapshot) ~= "table" then
		return
	end
	for roomName, row in pairs(panelRows) do
		local previous = activeCalls[roomName]
		local current = snapshot[roomName]
		activeCalls[roomName] = current
		if current then
			local detail = current.requestedBy and ("Called by " .. current.requestedBy) or "Active"
			row.status.Text = roomName .. "\n" .. current.code .. "  |  " .. detail
		else
			row.status.Text = roomName .. "\nNo active call"
		end
		setRoomAppearance(roomName, current)
		if current and (not previous or previous.code ~= current.code) then
			local part = roomParts[roomName]
			local sound = part and part:FindFirstChild("HospitalCallBeep")
			if sound then
				sound:Play()
			end
		end
	end
end)

requestCall:FireServer("Sync")
