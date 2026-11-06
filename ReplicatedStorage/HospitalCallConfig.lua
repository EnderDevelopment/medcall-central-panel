local Config = {}

-- Each name must match a BasePart inside Workspace.HospitalRooms.
Config.Rooms = {
	"Room 101",
	"Room 102",
	"Room 103",
}

-- Add Roblox user IDs here to restrict staff actions. An empty list allows all players.
Config.StaffUserIds = {}

-- Replace with an approved audio asset if this built-in ping is unavailable in your experience.
Config.BeepSoundId = "rbxasset://sounds/electronicpingshort.wav"
Config.BeepVolume = 0.55
Config.BeepMaxDistance = 45

Config.Calls = {
	{
		Name = "Code Blue",
		Color = Color3.fromRGB(35, 115, 255),
		Priority = 100,
	},
	{
		Name = "Code Red",
		Color = Color3.fromRGB(235, 55, 55),
		Priority = 90,
	},
	{
		Name = "Assistance",
		Color = Color3.fromRGB(255, 160, 35),
		Priority = 60,
	},
	{
		Name = "Nurse Call",
		Color = Color3.fromRGB(45, 190, 105),
		Priority = 30,
	},
}

return Config
