# SA-MP Open.MP Vehicle Streamer FilterScript

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
