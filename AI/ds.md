Here's an example of a basic vehicle streamer for open.mp (SA-MP compatible) in Pawn:

```pawn
#include <open.mp>

#define MAX_STREAMED_VEHICLES    1000
#define STREAM_DISTANCE          300.0
#define STREAMER_UPDATE_INTERVAL 1000

enum E_VEHICLE_INFO
{
    vehModel,
    Float:vehX,
    Float:vehY,
    Float:vehZ,
    Float:vehRot,
    vehColor1,
    vehColor2,
    vehRespawn,
    vehSiren,
    vehID,
    bool:vehOccupied
};
new VehInfo[MAX_STREAMED_VEHICLES][E_VEHICLE_INFO];

new Iterator:StreamedVehicles<MAX_STREAMED_VEHICLES>;

public OnGameModeInit()
{
    // Initialize your vehicles here using AddVehicleToStreamer
    SetTimer("Streamer_Update", STREAMER_UPDATE_INTERVAL, true);
    return 1;
}

stock AddVehicleToStreamer(modelid, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay, addsiren = 0)
{
    new index = Iter_Free(StreamedVehicles);
    if(index == -1) return INVALID_VEHICLE_ID;

    VehInfo[index][vehModel] = modelid;
    VehInfo[index][vehX] = x;
    VehInfo[index][vehY] = y;
    VehInfo[index][vehZ] = z;
    VehInfo[index][vehRot] = rotation;
    VehInfo[index][vehColor1] = color1;
    VehInfo[index][vehColor2] = color2;
    VehInfo[index][vehRespawn] = respawn_delay;
    VehInfo[index][vehSiren] = addsiren;
    VehInfo[index][vehID] = INVALID_VEHICLE_ID;
    VehInfo[index][vehOccupied] = false;

    Iter_Add(StreamedVehicles, index);
    return index;
}

forward Streamer_Update();
public Streamer_Update()
{
    foreach(new i : StreamedVehicles)
    {
        if(VehInfo[i][vehID] != INVALID_VEHICLE_ID)
        {
            // Check if vehicle should be destroyed
            if(!VehInfo[i][vehOccupied])
            {
                new bool:inRange = false;
                foreach(new playerid : Player)
                {
                    if(IsPlayerInRangeOfPoint(playerid, STREAM_DISTANCE, VehInfo[i][vehX], VehInfo[i][vehY], VehInfo[i][vehZ]))
                    {
                        inRange = true;
                        break;
                    }
                }
                
                if(!inRange)
                {
                    DestroyVehicle(VehInfo[i][vehID]);
                    VehInfo[i][vehID] = INVALID_VEHICLE_ID;
                }
            }
        }
        else
        {
            // Check if vehicle should be created
            foreach(new playerid : Player)
            {
                if(IsPlayerInRangeOfPoint(playerid, STREAM_DISTANCE, VehInfo[i][vehX], VehInfo[i][vehY], VehInfo[i][vehZ]))
                {
                    VehInfo[i][vehID] = CreateVehicle(VehInfo[i][vehModel], VehInfo[i][vehX], VehInfo[i][vehY], VehInfo[i][vehZ], VehInfo[i][vehRot],
                        VehInfo[i][vehColor1], VehInfo[i][vehColor2], VehInfo[i][vehRespawn], VehInfo[i][vehSiren]);
                    break;
                }
            }
        }
    }
    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    foreach(new i : StreamedVehicles)
    {
        if(VehInfo[i][vehID] == vehicleid)
        {
            VehInfo[i][vehOccupied] = true;
            break;
        }
    }
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
    foreach(new i : StreamedVehicles)
    {
        if(VehInfo[i][vehID] == vehicleid)
        {
            VehInfo[i][vehOccupied] = false;
            break;
        }
    }
    return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    foreach(new i : StreamedVehicles)
    {
        if(VehInfo[i][vehID] == vehicleid)
        {
            VehInfo[i][vehID] = INVALID_VEHICLE_ID;
            break;
        }
    }
    return 1;
}
```

This implementation includes:

1. Vehicle tracking with position, model, colors, and other parameters
2. Distance-based streaming (vehicles are created when players are nearby)
3. Vehicle destruction when no players are nearby and vehicle is unoccupied
4. Basic occupancy checking to prevent destroying vehicles in use
5. Regular updates through a timer
6. Automatic respawn handling

Key features:
- Uses a iterator for efficient looping
- Maintains vehicle states (occupied/unoccupied)
- Handles vehicle destruction and recreation
- Configurable stream distance and update interval
- Tracks vehicle usage to prevent destruction while in use

To use this streamer:
1. Add vehicles using `AddVehicleToStreamer()` in your gamemode initialization
2. Adjust `STREAM_DISTANCE` and `STREAMER_UPDATE_INTERVAL` as needed
3. Compile with open.mp server

Remember to:
- Handle vehicle properties that might change during gameplay
- Add error checking for maximum vehicle limits
- Consider adding additional features like virtual worlds/interiors
- Optimize distance checks for large numbers of vehicles/players

This provides a basic framework that can be extended with additional features like:
- Dynamic vehicle position updates
- Per-player streaming
- 3D distance checks
- Priority streaming
- Area-based streaming
- Vehicle property caching