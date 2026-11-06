# Open Source Roblox Hospital Call System

MedCall Central Panel is an open source Roblox hospital call system for Roblox Studio, providing a central staff panel, room call consoles, hospital call codes, color-coded alerts, priority handling, and audible notifications for roleplay and simulation experiences.

## Install

1. Open your Roblox experience in Roblox Studio.
2. Create a `ModuleScript` in `ReplicatedStorage` named `HospitalCallConfig`.
3. Paste the contents of `ReplicatedStorage/HospitalCallConfig.lua` into the module.
4. Create a `Script` in `ServerScriptService` named `HospitalCallServer`.
5. Paste the contents of `ServerScriptService/HospitalCallServer.server.lua` into the script.
6. Create a `LocalScript` in `StarterPlayer > StarterPlayerScripts` named `HospitalCallClient`.
7. Paste the contents of `StarterPlayer/StarterPlayerScripts/HospitalCallClient.client.lua` into the LocalScript.
8. Test the system with Roblox Studio's `Play` button. Use `Play`, rather than `Run`, so the client interface and LocalScript are started.

The server automatically creates the `HospitalRooms` folder. If the configured room parts are not already present, it also creates a small demo layout with three rooms and wall-console parts.

To use an existing map, create `Workspace > HospitalRooms` and add one `BasePart` for every configured room name, such as `Room 101`, `Room 102`, and `Room 103`.

## Use

1. Start a play test.
2. Confirm that the `HOSPITAL CALLS` button and `CENTRAL STAFF PANEL` appear in the upper-right area of the screen.
3. Walk to a room's wall console.
4. Select a call button, such as `Code Blue`, `Code Red`, `Assistance`, or `Nurse Call`.
5. The room console displays the active code, changes color, pulses, and plays a beep.
6. The same room appears as an active call in the central staff panel.
7. Select `CLEAR` in the matching staff-panel row to remove the active call.
8. Use the `HOSPITAL CALLS` button to hide or show the central staff panel.

To customize the system, edit `HospitalCallConfig`:

- Change `Config.Rooms` to add or rename rooms. Each configured room must

---

More open source project projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/26b50aff-f1dc-477a-97a5-5122531f87fd?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=26b50aff-f1dc-477a-97a5-5122531f87fd
