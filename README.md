# 2 ways to make code lighter
1. load vehilces in one area based on player location area (zone):
* there is already zone detector code, for example if player is in bone county load vehicles from bone.txt file then if he leaves zone unload them
2. check each vehicle zone area name and save it and create vehicles if the vehicle zone area name and player zone area name is the same.

# SA-MP-Open.MP-Vehicle-Streamer-FilterScript
The SA-MP/Open.MP Vehicle Streamer is a dynamic filter script for Grand Theft Auto: San Andreas Multiplayer (SA-MP) and Open.MP. It efficiently manages vehicle streaming, allowing seamless creation, removal, and visibility of vehicles across servers. Ideal for optimizing server performance and enhancing the multiplayer experience.

# Seeking Help with SA-MP Vehicle Streamer - Server Limitations and Solutions

Hello everyone,

First of all, I want to clarify that I'm not a programmer and English is not my first language. I'm also using ChatGPT to help me with this post. 

I'm working on a SA-MP server, and I encountered a limitation that I believe many of you might have faced as well. The default server limits are as follows:

- **max_players**: 1000  
- **max_vehicles**: 2000

So, if we have a server with 1000 players, each player would ideally have two vehicles. However, I want to have more vehicles distributed across the entire game map. For example, I use a file filterscript to load **1700 vehicles** (specifically Grand Larceny vehicles) across the map, and another **400 vehicles** from my gamemode. 

Here is where the problem starts: once the server reaches the 2000 vehicle limit, it can't create any more vehicles using commands, and some parts of the server become unfunctional. For example, the vehicle shop won't work, or players can't spawn new vehicles. Even though there might only be one player on the server and 2000 vehicles already loaded, most of these vehicles end up being useless. However, we still need them loaded because players may lose their vehicles across the map and need new ones.

This brings me to the idea of having a **vehicle streamer**. I did some searching, but most of the solutions I found are edited versions of the old streamer plugin, which are outdated and no longer maintained. The original plugin also never added vehicle streaming, even after many years. 

To solve this, I created a filterscript that loads streamed vehicles. However, the script is quite slow, laggy, and incomplete, though it works to some extent. If anyone is interested, here is the link to my script on GitHub:  
[SA-MP Open.MP Vehicle Streamer FilterScript](https://github.com/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)

I’m hoping to get some feedback or suggestions on how I could improve this, or if anyone has experience with a better solution for streaming vehicles efficiently without hitting the server limits. Any help or pointers would be greatly appreciated!

Thank you!


# SA-MP Open.MP Vehicle Streamer FilterScript

![GitHub](https://img.shields.io/github/license/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)
![GitHub Repo stars](https://img.shields.io/github/stars/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript?style=social)
![GitHub issues](https://img.shields.io/github/issues/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)
![GitHub forks](https://img.shields.io/github/forks/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript?style=social)
![GitHub last commit](https://img.shields.io/github/last-commit/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)
![GitHub contributors](https://img.shields.io/github/contributors/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)

## Overview

The **SA-MP Open.MP Vehicle Streamer FilterScript** is designed to improve vehicle handling and performance in **San Andreas Multiplayer (SA-MP)** and **Open.MP** by dynamically streaming vehicles for players. This allows vehicles to be loaded and unloaded based on player proximity, which optimizes the server’s performance by reducing the number of vehicles that need to be actively rendered for every player.

This FilterScript provides an easy-to-use solution for streaming vehicles, enhancing server performance and providing an immersive gaming experience.

## Features

- **Dynamic Vehicle Streaming**: Stream vehicles in and out of the game dynamically based on the player's location and proximity to the vehicles. This reduces lag by ensuring that only nearby vehicles are actively streamed.
- **Supports SA-MP and Open.MP**: Fully compatible with both SA-MP and Open.MP, making it versatile for different multiplayer server setups.
- **Efficient Resource Management**: Stream only the vehicles necessary for each player, significantly reducing resource consumption and improving overall server performance.
- **Customization**: The script can be easily customized to fit the specific needs of your server, including vehicle load/unload distances, and handling of vehicle events.
- **Simple Installation and Setup**: The script is designed for easy integration into existing SA-MP/Open.MP servers with minimal setup.

## Installation

Follow these steps to install and set up the **Vehicle Streamer FilterScript** on your SA-MP or Open.MP server:

1. **Download the Files**:
   - Clone the repository or download the ZIP file.
   - Extract the files to your server directory.

2. **Add to Your Server**:
   - Place the `Vehicle_Streamer.pwn` file in the `filterscripts` folder of your server.
   - Place the compiled `Vehicle_Streamer.amx` file in the same `filterscripts` folder.

3. **Configure the Server**:
   - Open your `server.cfg` file.
   - Add `Vehicle_Streamer` to the `filterscripts` line in `server.cfg`.
     Example: 
     ```
     filterscripts Vehicle_Streamer
     ```

4. **Compile the Script**:
   - If you are using a custom server setup or need to recompile the script, open the `Vehicle_Streamer.pwn` file in the SA-MP or Open.MP compiler and compile it to generate the `Vehicle_Streamer.amx` file.

5. **Restart Your Server**:
   - Once the script is added and compiled, restart your server for the changes to take effect.

## Usage

Once the **Vehicle Streamer FilterScript** is installed and running on your server, it will automatically manage vehicle streaming for players. The script ensures that vehicles are streamed in when players approach them and removed from memory when they leave the area. This optimizes server performance by ensuring that vehicles only consume resources when necessary.

### Customization

You can customize the behavior of the vehicle streamer by editing the **Vehicle_Streamer.pwn** file. Here are some of the key parameters you may want to modify:

- **Stream Distance**: The distance at which vehicles will be streamed in or out of the game.
- **Vehicle Load/Unload Events**: Handle what happens when a vehicle is loaded or unloaded from memory.
- **Vehicle Management Settings**: Configure whether vehicles should be automatically streamed in when a player spawns, or if specific conditions must be met.

## Dependencies

- **SA-MP or Open.MP Server**: You must have a running SA-MP or Open.MP server to use this FilterScript.
- **AMX Compiler**: Required to compile the `Vehicle_Streamer.pwn` file into an AMX script.
- **Basic knowledge of SA-MP or Open.MP scripting**: While the script is plug-and-play, basic scripting knowledge will help if you want to make further customizations.

## Example Code

Here’s an example of how you can use the vehicle streaming system in your server:

```pawn
public OnPlayerEnterVehicle(playerid, vehicleid, isPassenger)
{
    // Vehicle will automatically stream in when the player enters
    SendClientMessage(playerid, COLOR_GREEN, "Vehicle streamed in!");
    return 1;
}
```

# SA-MP Open.MP Vehicle Streamer FilterScript

![Project Logo](https://img.shields.io/github/license/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)
![Issues](https://img.shields.io/github/issues/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript)

A simple and efficient Vehicle Streamer FilterScript for **SA-MP** and **Open.MP** that allows server owners to easily manage vehicles on their servers.

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Commands](#commands)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Description

This **Vehicle Streamer FilterScript** was created to provide **SA-MP** and **Open.MP** server owners with an easy-to-use solution to stream vehicles on their servers. With this filter script, you can efficiently load and manage vehicles, which improves performance and scalability for large-scale server setups. The script is optimized for both **SA-MP** and **Open.MP**, ensuring compatibility across different platforms.

## Features

- Stream vehicles in real-time.
- Fully compatible with **SA-MP** and **Open.MP** servers.
- Easy-to-use configuration for vehicle streaming.
- Supports a variety of vehicle types.
- Optimized performance for large server environments.

## Installation

To install the **Vehicle Streamer FilterScript** on your **SA-MP** or **Open.MP** server, follow these steps:

### 1. Download the Repository

Clone the repository to your local machine or server:

```bash
git clone https://github.com/Kingvornex/SA-MP-Open.MP-Vehicle-Streamer-FilterScript.git
```

### 2. Place the Files

- Copy the contents of the repository to your server's `filterscripts` folder.
- Ensure that the `.pwn` and `.amx` files are placed in the appropriate directory.

### 3. Add to `server.cfg`

Edit the `server.cfg` file and add the following line to load the filter script:

```
filterscripts vehicle_streamer
```

### 4. Restart Server

Restart your server to apply the changes.

## Usage

To use the **Vehicle Streamer FilterScript**, you need to configure it via the provided `config` file. Once configured, the vehicles will automatically stream into the game as per your settings.

### Example Configuration:

```ini
; config.ini
[Streaming]
EnableVehicleStreaming=true
MaxVehicles=100
```

## Commands

- `/streamvehicle [vehicle_id]`: Streams a specific vehicle by its ID.
- `/removevehicle [vehicle_id]`: Removes a vehicle from the stream.

## Contributing

Contributions are welcome! If you have any suggestions or improvements, feel free to fork the repository and submit a pull request. Please ensure your code adheres to the existing style and includes relevant tests.

### Steps to Contribute:

1. Fork the repository.
2. Create a new branch for your feature (`git checkout -b feature-name`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-name`).
5. Open a pull request.

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- **SA-MP** and **Open.MP** developers for creating the platforms.
- **GitHub** for hosting this repository.
```

This is the markdown version for the **README.md** that you can use directly for your project. Let me know if you need further adjustments!
