// ... (existing file header and includes)
#define MAX_STREAM_VEHICLES 2000
#define STREAM_DISTANCE 150.0
#define VSD true // Vehicle Streamer Debug

enum Stream_vehicle
{
    modelid,
    Float:x, Float:y, Float:z,
    Float:angle,
    color1, color2,
    respawn_delay,
    plate[32],
    health,
    mods[14],
    paintjob,
    interior,
    world,
    // ... (rest of the fields)
    spawned, // 1 = spawned, 0 = not spawned
    vehid,
    ownerid,
    spawn_tick
}

new vInfo[MAX_STREAM_VEHICLES][Stream_vehicle];
new VehicleCount = 0;

// Debug logging macro
#define VS_LOG(%1) if(VSD) printf("[VS-DEBUG] " # %1), print(%1);

// Error log macro
#define VS_ERROR(%1) printf("[VS-ERROR] %s", %1);

// Helper function for file existence check
stock bool:FileExists(const filename[])
{
    new File:f = fopen(filename, io_read);
    if (f)
    {
        fclose(f);
        return true;
    }
    return false;
}

// Improved vehicle loading with error checking
stock LoadStaticVehiclesFromFile(const filename[])
{
    if (!FileExists(filename))
    {
        VS_ERROR("Could not open vehicle data file (missing):");
        VS_ERROR(filename);
        return 0;
    }
    new File:fh = fopen(filename, io_read);
    new line[256], fields[8][32];
    new count = 0;
    while (fread(fh, line))
    {
        if (sscanf(line, "p<,>s[8]", fields)) continue; // skip malformed
        if (VehicleCount >= MAX_STREAM_VEHICLES)
        {
            VS_ERROR("VehicleCount exceeds MAX_STREAM_VEHICLES, skipping entry.");
            break;
        }
        // ... (parse fields into vInfo[VehicleCount])
        VehicleCount++;
        count++;
    }
    fclose(fh);
    VS_LOG("Vehicles loaded:");
    printf("%d", count);
    return count;
}

// Improved proximity check (simple optimization: early return)
stock bool:IsInRangeOfAnyPlayer(Float:vx, Float:vy, Float:vz, Float:distance)
{
    for (new i = 0, j = GetMaxPlayers(); i < j; i++)
    {
        if (IsPlayerConnected(i))
        {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(i, px, py, pz);
            if (VectorSize(px - vx, py - vy, pz - vz) < distance)
                return true;
        }
    }
    return false;
}

// Improved vehicle respawn/cleanup logic
public OnVehicleDeath(vehicleid, killerid)
{
    for (new i = 0; i < VehicleCount; i++)
    {
        if (vInfo[i][vehid] == vehicleid)
        {
            vInfo[i][spawned] = 0;
            VS_LOG("Vehicle destroyed, marked for respawn:");
            printf("Vehicle ID: %d", vehicleid);
            SetTimerEx("RespawnStreamVehicle", 5000, false, "i", i);
            break;
        }
    }
    return 1;
}

forward RespawnStreamVehicle(index);
public RespawnStreamVehicle(index)
{
    if (index < 0 || index >= VehicleCount) return 0;
    if (vInfo[index][spawned] == 0)
    {
        vInfo[index][vehid] = CreateVehicle(
            vInfo[index][modelid],
            vInfo[index][x], vInfo[index][y], vInfo[index][z],
            vInfo[index][angle],
            vInfo[index][color1], vInfo[index][color2],
            vInfo[index][respawn_delay],
            vInfo[index][paintjob]
        );
        vInfo[index][spawned] = 1;
        VS_LOG("Vehicle respawned:");
        printf("Index: %d VehID: %d", index, vInfo[index][vehid]);
    }
    return 1;
}

// Add bounds checking when incrementing VehicleCount
stock CreateStreamVehicle(...)
{
    if (VehicleCount >= MAX_STREAM_VEHICLES)
    {
        VS_ERROR("Cannot create vehicle: limit reached.");
        return -1;
    }
    // ... (rest of vehicle creation logic)
    VehicleCount++;
    return vInfo[VehicleCount - 1][vehid];
}

// Add debug log for missing OnGameModeInit or OnFilterScriptInit
public OnGameModeInit()
{
    VS_LOG("Initializing Vehicle Streamer...");
    LoadStaticVehiclesFromFile("vehicles.txt");
    return 1;
}

public OnFilterScriptInit()
{
    VS_LOG("Initializing Vehicle Streamer (FS)...");
    LoadStaticVehiclesFromFile("vehicles.txt");
    return 1;
}

// Clean up vehicles properly on script exit
public OnGameModeExit()
{
    for (new i = 0; i < VehicleCount; i++)
    {
        if (vInfo[i][spawned] == 1)
        {
            DestroyVehicle(vInfo[i][vehid]);
            vInfo[i][spawned] = 0;
        }
    }
    VS_LOG("Cleaned up all streamed vehicles.");
    return 1;
}

public OnFilterScriptExit()
{
    OnGameModeExit();
    return 1;
}

// ... (rest of the script)
