#include <a_samp>

#define MAX_VEHICLES 1000
#define DATA_FILE "vehicles.txt"
#define MAX_VEHICLE_MODS 14

new VehicleData[MAX_VEHICLES][12]; // ModelID, PosX, PosY, PosZ, RotZ, Color1, Color2, PaintJob, Health, Mods[5]
new ActiveVehicles[MAX_PLAYERS][MAX_VEHICLES];
new VehicleMods[MAX_VEHICLE_MODS] = {1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013};

// Load vehicle data from the file
public LoadVehicleData()
{
    new File:file = fopen(DATA_FILE, io_read);
    if (file)
    {
        new line[256];
        for (new i = 0; i < MAX_VEHICLES && !feof(file); i++)
        {
            if (fgets(file, line, sizeof(line)))
            {
                sscanf(line, "dffffffiifii", 
                       VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 
                       VehicleData[i][4], VehicleData[i][5], VehicleData[i][6], VehicleData[i][7], 
                       VehicleData[i][8], VehicleData[i][9], VehicleData[i][10], VehicleData[i][11]);
            }
        }
        fclose(file);
    }
}

// Save vehicle data to the file
public SaveVehicleData()
{
    new File:file = fopen(DATA_FILE, io_write);
    if (file)
    {
        new line[256];
        for (new i = 0; i < MAX_VEHICLES; i++)
        {
            format(line, sizeof(line), "%d %f %f %f %f %d %d %d %f %d %d %d %d %d\n", 
                   VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 
                   VehicleData[i][4], VehicleData[i][5], VehicleData[i][6], VehicleData[i][7], 
                   VehicleData[i][8], VehicleData[i][9], VehicleData[i][10], VehicleData[i][11]);
            fputs(file, line);
        }
        fclose(file);
    }
}

// Function to add random mods to vehicles
public AddRandomMods(vehicleid)
{
    new modCount = random(5) + 1;
    for (new i = 0; i < modCount; i++)
    {
        new mod = VehicleMods[random(MAX_VEHICLE_MODS)];
        AddVehicleComponent(vehicleid, mod);
    }
}

public OnGameModeInit()
{
    LoadVehicleData();
    return 1;
}

public OnPlayerConnect(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (IsInRangeOfPoint(x, y, z, VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]))
        {
            ActiveVehicles[playerid][i] = CreateVehicle(VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 
                                                        VehicleData[i][4], VehicleData[i][5], VehicleData[i][6], 100);
            SetVehicleHealth(ActiveVehicles[playerid][i], VehicleData[i][8]);
            ChangeVehiclePaintjob(ActiveVehicles[playerid][i], VehicleData[i][7]);
            AddRandomMods(ActiveVehicles[playerid][i]);
        }
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (ActiveVehicles[playerid][i] != INVALID_VEHICLE_ID)
        {
            DestroyVehicle(ActiveVehicles[playerid][i]);
            ActiveVehicles[playerid][i] = INVALID_VEHICLE_ID;
        }
    }
    return 1;
}

public OnPlayerUpdate(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (IsInRangeOfPoint(x, y, z, VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]))
        {
            if (ActiveVehicles[playerid][i] == INVALID_VEHICLE_ID)
            {
                ActiveVehicles[playerid][i] = CreateVehicle(VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 
                                                            VehicleData[i][4], VehicleData[i][5], VehicleData[i][6], 100);
                SetVehicleHealth(ActiveVehicles[playerid][i], VehicleData[i][8]);
                ChangeVehiclePaintjob(ActiveVehicles[playerid][i], VehicleData[i][7]);
                AddRandomMods(ActiveVehicles[playerid][i]);
            }
        }
        else
        {
            new vehid = ActiveVehicles[playerid][i];
            GetVehiclePos(vehid, VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]);
            GetVehicleZAngle(vehid, VehicleData[i][4]);
            GetVehicleColor(vehid, VehicleData[i][5], VehicleData[i][6]);
            GetVehicleHealth(vehid, VehicleData[i][8]);
            DestroyVehicle(vehid);
            ActiveVehicles[playerid][i] = INVALID_VEHICLE_ID;
        }
    }
    return 1;
}

public OnGameModeExit()
{
    SaveVehicleData();
    return 1;
}
