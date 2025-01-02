#include <a_samp>

#define MAX_VEHICLES 1000
#define DATA_FILE "vehicles.txt"

new VehicleData[MAX_VEHICLES][4]; // ModelID, PosX, PosY, PosZ
new ActiveVehicles[MAX_PLAYERS][MAX_VEHICLES];

// Load vehicle data from the file
public LoadVehicleData()
{
    new File:file = fopen(DATA_FILE, io_read);
    if (file)
    {
        new line[128];
        for (new i = 0; i < MAX_VEHICLES && !feof(file); i++)
        {
            if (fgets(file, line, sizeof(line)))
            {
                sscanf(line, "dfff", VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]);
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
        for (new i = 0; i < MAX_VEHICLES; i++)
        {
            format(line, sizeof(line), "%d %f %f %f\n", VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]);
            fputs(file, line);
        }
        fclose(file);
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
            ActiveVehicles[playerid][i] = CreateVehicle(VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 0.0, -1, -1, 100);
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
                ActiveVehicles[playerid][i] = CreateVehicle(VehicleData[i][0], VehicleData[i][1], VehicleData[i][2], VehicleData[i][3], 0.0, -1, -1, 100);
            }
        }
        else
        {
            if (ActiveVehicles[playerid][i] != INVALID_VEHICLE_ID)
            {
                new vehid = ActiveVehicles[playerid][i];
                GetVehiclePos(vehid, VehicleData[i][1], VehicleData[i][2], VehicleData[i][3]);
                DestroyVehicle(vehid);
                ActiveVehicles[playerid][i] = INVALID_VEHICLE_ID;
            }
        }
    }
    return 1;
}

public OnGameModeExit()
{
    SaveVehicleData();
    return 1;
}
