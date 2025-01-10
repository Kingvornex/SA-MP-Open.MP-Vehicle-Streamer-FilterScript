#include <open.mp>
#include <YSI-Includes\YSI_Data\y_iterate>

// Constants for configuration
#define MAX_STREAM_VEHICLES 3000
#define VEHICLE_STREAM_DISTANCE 100
#define RESPAWN_DELAY 20000
#define VEHICLE_SEEKER_DELAY 100
#define MAX_ALLOWED_MODS 12

// Macro for loop simplification
#define Loop(index, limit) for (new index = 0; index < limit; index++)

// Debugging flag
new bool:VSD = false;

// Enumeration for vehicle properties
enum Stream_vehicle {
    vModel, vID, vColor1, vColor2,
    Float:vSpawnX, Float:vSpawnY, Float:vSpawnZ, Float:vSpawnA,
    Float:vLastX, Float:vLastY, Float:vLastZ, Float:vLastA,
    vPlate[32], vPaintJob,
    bool:FirstSpawn, bool:IsSpawned, bool:IsActive, bool:IsPopulated,
    vInterior, vWorld, vStream, vSiren, vRespawn,
    Float:vHealth
}
new VehicleInfo[MAX_STREAM_VEHICLES][Stream_vehicle];
new GetVehicleMods[MAX_STREAM_VEHICLES][MAX_ALLOWED_MODS];

// Variables
new lastsvid = 0;
new total_vehicles_from_files = 0;
new Seekingid, Respawnerid;

// Forward declarations
forward VehicleSeeker();
forward VehicleRespawner();

// Timer control functions
stock StartTimer(stock function, &timerId, delay, bool:repeat) {
    timerId = SetTimer(function, delay, repeat);
    if (VSD) printf("[DEBUG]: Timer %d started for function %s", timerId, function);
    return 1;
}

stock StopTimer(&timerId) {
    KillTimer(timerId);
    if (VSD) printf("[DEBUG]: Timer %d stopped", timerId);
    return 1;
}

// Vehicle respawner
public VehicleRespawner() {
    Loop(vs, MAX_STREAM_VEHICLES) {
        if (!VehicleInfo[vs][IsPopulated] || VehicleInfo[vs][IsActive]) continue;
        VehicleInfo[vs][vLastX] = VehicleInfo[vs][vSpawnX];
        VehicleInfo[vs][vLastY] = VehicleInfo[vs][vSpawnY];
        VehicleInfo[vs][vLastZ] = VehicleInfo[vs][vSpawnZ];
        VehicleInfo[vs][vLastA] = VehicleInfo[vs][vSpawnA];
        VehicleInfo[vs][FirstSpawn] = true;
    }
}

// Check if a vehicle is in range of any player
stock bool:IsInRangeOfAnyPlayer(vv) {
    foreach (new i : Player) {
        new Float:posx, Float:posy, Float:posz;
        GetPlayerPos(i, posx, posy, posz);

        new Float:dx = VehicleInfo[vv][vLastX] - posx;
        new Float:dy = VehicleInfo[vv][vLastY] - posy;
        new Float:dz = VehicleInfo[vv][vLastZ] - posz;

        if (dx * dx + dy * dy + dz * dz <= VehicleInfo[vv][vStream] * VehicleInfo[vv][vStream]) {
            if (VSD) printf("Vehicle %d is in range of player %d", vv, i);
            return true;
        }
    }
    return false;
}

// Vehicle seeker
public VehicleSeeker() {
    Loop(v, MAX_STREAM_VEHICLES) {
        if (!VehicleInfo[v][IsPopulated]) continue;

        bool isInRange = IsInRangeOfAnyPlayer(v);

        if (!VehicleInfo[v][IsSpawned] && isInRange) {
            CreateTheVehicle(v);
            VehicleInfo[v][IsActive] = true;
        } else if (VehicleInfo[v][IsSpawned]) {
            if (!isInRange) {
                DestroyTheVehicle(v);
                VehicleInfo[v][IsActive] = false;
            } else {
                UpdateVehicleProperties(v);
                VehicleInfo[v][IsActive] = true;
            }
        }
    }
    return 1;
}

// Update vehicle properties
stock UpdateVehicleProperties(vv) {
    GetVehiclePos(VehicleInfo[vv][vID], VehicleInfo[vv][vLastX], VehicleInfo[vv][vLastY], VehicleInfo[vv][vLastZ]);
    GetVehicleZAngle(VehicleInfo[vv][vID], VehicleInfo[vv][vLastA]);
    GetVehicleHealth(VehicleInfo[vv][vID], VehicleInfo[vv][vHealth]);
}

// Vehicle creation and destruction
stock CreateTheVehicle(vv) {
    if (VehicleInfo[vv][IsSpawned]) {
        if (VSD) printf("[DEBUG] Vehicle %d already spawned", vv);
        return;
    }

    VehicleInfo[vv][vID] = CreateVehicle(
        VehicleInfo[vv][vModel], VehicleInfo[vv][vLastX], VehicleInfo[vv][vLastY], VehicleInfo[vv][vLastZ],
        VehicleInfo[vv][vLastA], VehicleInfo[vv][vColor1], VehicleInfo[vv][vColor2],
        VehicleInfo[vv][vRespawn], VehicleInfo[vv][vSiren]
    );

    VehicleInfo[vv][FirstSpawn] = false;
    VehicleInfo[vv][IsSpawned] = true;
    SetVehicleHealth(VehicleInfo[vv][vID], VehicleInfo[vv][vHealth]);

    Loop(m, MAX_ALLOWED_MODS) {
        if (GetVehicleMods[vv][m] > 0) AddVehicleComponent(VehicleInfo[vv][vID], GetVehicleMods[vv][m]);
    }
}

stock DestroyTheVehicle(vv) {
    if (!VehicleInfo[vv][IsSpawned]) return;

    DestroyVehicle(VehicleInfo[vv][vID]);
    VehicleInfo[vv][IsSpawned] = false;
    VehicleInfo[vv][vID] = INVALID_VEHICLE_ID;
    VehicleInfo[vv][IsActive] = false;
}

// Create streamable vehicle
stock CreateStreamVehicle(modelid, Float:spawnX, Float:spawnY, Float:spawnZ, Float:angle, color1, color2, respawnDelay = RESPAWN_DELAY, bool:addSiren = true, StreamDistance = VEHICLE_STREAM_DISTANCE) {
    if (lastsvid >= MAX_STREAM_VEHICLES) return -1;

    VehicleInfo[lastsvid][vModel] = modelid;
    VehicleInfo[lastsvid][vColor1] = color1;
    VehicleInfo[lastsvid][vColor2] = color2;
    VehicleInfo[lastsvid][vSpawnX] = spawnX;
    VehicleInfo[lastsvid][vSpawnY] = spawnY;
    VehicleInfo[lastsvid][vSpawnZ] = spawnZ;
    VehicleInfo[lastsvid][vSpawnA] = angle;

    VehicleInfo[lastsvid][vLastX] = spawnX;
    VehicleInfo[lastsvid][vLastY] = spawnY;
    VehicleInfo[lastsvid][vLastZ] = spawnZ;
    VehicleInfo[lastsvid][vLastA] = angle;

    VehicleInfo[lastsvid][FirstSpawn] = true;
    VehicleInfo[lastsvid][IsSpawned] = false;
    VehicleInfo[lastsvid][IsActive] = false;
    VehicleInfo[lastsvid][vHealth] = 1000;
    VehicleInfo[lastsvid][vID] = INVALID_VEHICLE_ID;
    VehicleInfo[lastsvid][IsPopulated] = true;
    VehicleInfo[lastsvid][vStream] = StreamDistance;
    VehicleInfo[lastsvid][vSiren] = addSiren;
    VehicleInfo[lastsvid][vRespawn] = respawnDelay;

    return lastsvid++;
}
