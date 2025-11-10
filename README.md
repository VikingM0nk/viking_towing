[readme.md](https://github.com/user-attachments/files/23451491/readme.md)
🚛 QBCore Tow Script
A modular, ox_target-powered towing system for FiveM with support for:
- ✅ Rollback flatbeds with winch and tilt
- ✅ Boom arm wreckers with raise/lower
- ✅ Trailer attach/detach
- ✅ ox_lib UI menu
- ✅ Job whitelist (optional)
- ✅ ox_target integration

📦 Features
|  |  | 
|  |  | 
|  |  | 
|  |  | 
|  |  | 
|  |  | 
|  |  | 
|  |  | 



🧰 Requirements
- QBCore Framework
- ox_target
- ox_lib

📁 Installation
- Download or clone this resource into your [qb] folder:
cd resources/[qb]
https://github.com/VikingM0nk/viking_towing


- Ensure dependencies are started before this resource in your server.cfg:
ensure ox_lib
ensure ox_target
ensure qb-core
ensure viking_tow


- Configure vehicles and jobs in config.lua:
Config.AllowedJobs = {
    mechanic = true,
    tow = true,
    police = true
}

Config.TowVehicles = {
    rollback = { 'flatbed' },
    boom = { 'wrecker' },
    trailers = { 'trailersmall', 'trailer', 'cartrailer' }
}



🎮 Usage
🚚 Towing
- Walk up to a rollback or boom truck
- Use ox_target to open the Tow Controls menu
- Choose:
- Winch Vehicle
- Tilt Rollback
- Attach to Rollback
- Attach to Boom
- Raise/Lower Boom
- Select Tow Target
- Detach Vehicle
🔗 Trailer Control
- Walk up to a trailer:
- Attach Trailer (if not attached)
- Detach Trailer (if attached)
- These options are available to all players, no job required

🧪 Commands
|  |  | 
| /tow_detach |  | 
| /detach_trailer |  | 



🧩 Customization
- Add more vehicle models in config.lua
- Adjust attach offsets per vehicle type
- Add job checks or distance limits in client/main.lua
- Add animations or progress bars in client/ui.lua

📜 License
MIT License. Use freely, modify responsibly, and credit when possible.

thank you to glitchdetector for the original script for the flatbed to work
https://github.com/glitchdetector/fivem-functional-flatbed
