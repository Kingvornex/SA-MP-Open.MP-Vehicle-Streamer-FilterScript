
// Stream Vehicles from file

#include <open.mp>
#include <crashdetect>
#include <YSI-Includes\YSI_Data\y_iterate>

// Define constants for configuration.
#define MAX_STREAM_VEHICLES 3000  // Maximum number of streamable vehicles.
/*
// Declare the iterator for vehicles.
new Iterator:VehicleIter<MAX_STREAM_VEHICLES>;
*/
#define VEHICLE_STREAM_DISTANCE 100  // Distance at which vehicles are streamed to players.
#define RESPAWN_DELAY 20000  // Vehicle respawn delay in seconds (30 minutes).
#define VEHICLE_SEEKER_DELAY 100  // Delay between vehicle streaming checks (in milliseconds).
#define MAX_ALLOWED_MODS 12

// Macro to simplify creating loops.
#define Loop(%0,%1) for(new %0 = 0; %0 < %1; %0++)

// Debugging flag.
new bool:VSD = false; // Enable/disable debug logging.

// Enumeration for vehicle properties stored in the streamable vehicle array.
enum Stream_vehicle
{
	vModel,         // Vehicle model ID.
	vID,            // Vehicle ID (unique in-game ID).
	vColor1,        // Primary color of the vehicle.
	vColor2,        // Secondary color of the vehicle.
	Float:vSpawnX,  // Vehicle spawn X coordinate.
	Float:vSpawnY,  // Vehicle spawn Y coordinate.
	Float:vSpawnZ,  // Vehicle spawn Z coordinate.
	Float:vSpawnA,  // Vehicle spawn rotation angle.
	Float:vLastX,   // Vehicle's last X position.
	Float:vLastY,   // Vehicle's last Y position.
	Float:vLastZ,   // Vehicle's last Z position.
	Float:vLastA,   // Vehicle's last rotation angle.
	vPlate[32],     // Vehicle's license plate.
	vPaintJob,      // Vehicle's paint job.
	bool:FirstSpawn,// Indicates if the vehicle is being spawned for the first time.
	bool:IsSpawned, // Indicates if the vehicle is currently spawned in the game world.
	bool:IsActive,  // Indicates if the vehicle is active (in range of players).
	bool:IsPopulated, // Indicates if the vehicle is populated with data.
	bool:IsOcupied, // Indicates if the vehicle is Ocupied with data.
	vInterior,      // Interior ID for the vehicle.
	vWorld,         // Virtual world ID for the vehicle.
	vStream,        // Stream distance for the vehicle.
	vSiren,         // Indicates if the vehicle has a siren.
	vRespawn,		// Respawn delay for the vehicle.
	vMods[12], 		// Array to store Vehicle Mods associated with the vehicle.      
	vPlayerID[9],	// Array to store player IDs associated with the vehicle. Bus has 9 seats.
	Float:vHealth   // Vehicle health.
}
new vInfo[MAX_STREAM_VEHICLES][Stream_vehicle]; // Array to store vehicle properties.

new GetvMods[MAX_STREAM_VEHICLES][12];

// Variables to keep track of vehicle data.

new lastsvid = 0; // Last streamable vehicle ID.

new total_vehicles_from_files = 0; // Total vehicles loaded from file.

new Seekingid; // ID for the seeker timer.

//new ActiveVehicles[MAX_PLAYERS][MAX_STREAM_VEHICLES];

// Forward declaration for the VehicleSeeker function.
forward VehicleSeeker();

// Start the vehicle seeker, which streams vehicles near players.
stock StartVehicleSeeking()
{
	Seekingid = SetTimer("VehicleSeeker", VEHICLE_SEEKER_DELAY, true); // Set a repeating timer for the seeker.
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: Seekingid (%d) = SetTimer(VehicleSeeker, VEHICLE_SEEKER_DELAY (%d), true);", Seekingid, VEHICLE_SEEKER_DELAY); }
	return 1;
}

// Stop the vehicle seeker by killing the timer.
stock StopVehicleSeeking()
{
	KillTimer(Seekingid); // Kill the seeker timer.
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: KillTimer(Seekingid (%d));", Seekingid); }
	return 1;
}

new Respawnerid; // ID for the Respawner timer.

// Forward declaration for the VehicleRespawner function.
forward VehicleRespawner();

// Start the vehicle Respawner, which changes vehicles locations back to spawn locations.
stock StartVehicleRespawner()
{
	Respawnerid = SetTimer("VehicleRespawner", RESPAWN_DELAY, true); // Set a repeating timer for the Respanwer.
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: Respawnerid (%d) = SetTimer(VehicleRespawner, RESPAWN_DELAY (%d), true);", Respawnerid, RESPAWN_DELAY); }
	return 1;
}

// Stop the vehicle Respawner by killing the timer.
stock StopVehicleRespawner()
{
	KillTimer(Respawnerid); // Kill the Respawner timer.
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: KillTimer(VehicleRespawner: Respawnerid (%d));", Respawnerid); }
	return 1;
}

public VehicleRespawner()
{
	//foreach (new vehicleid : VehicleIter)
	Loop(vs, MAX_STREAM_VEHICLES)
	{
		if (vs < 0 || vs >= MAX_STREAM_VEHICLES) continue;
		if (vInfo[vs][IsPopulated] == false) continue;  // Skip unpopulated vehicles
		if (vInfo[vs][IsActive] == true) continue;
		vInfo[vs][vLastX] = vInfo[vs][vSpawnX];
		vInfo[vs][vLastY] = vInfo[vs][vSpawnY];
		vInfo[vs][vLastZ] = vInfo[vs][vSpawnZ];
		vInfo[vs][vLastA] = vInfo[vs][vSpawnA];
		vInfo[vs][FirstSpawn] = true;
	}
}

// Check if a vehicle is in range of any player.
stock bool:IsInRangeOfAnyPlayer(vv)
{
	foreach(new i : Player) // Iterate through all players.
	{
		// Validate the player ID and check if the player is connected
//        if (i < 0 || i >= MAX_PLAYERS || !IsPlayerConnected(i)) continue;

		new Float:posx, Float:posy, Float:posz; // Player position variables.
		GetPlayerPos(i, posx, posy, posz); // Get the player's position.
		
		new Float:tempposx, Float:tempposy, Float:tempposz; // Temporary variables for position differences.
		tempposx = (vInfo[vv][vLastX] - posx); // X difference.
        tempposy = (vInfo[vv][vLastY] - posy); // Y difference.
        tempposz = (vInfo[vv][vLastZ] - posz); // Z difference.

		new radi = vInfo[vv][vStream]; // Stream distance for the vehicle.
        if( ((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)) )
        {
			if(VSD == true) { printf("IsInRangeOfAnyPlayer(PID: %d, SVID: %d, VID: %d) = true", i, vv, vInfo[vv][vID]); }
            return true; // Vehicle is within range of a player.
        }
    }
    return false; // Vehicle is not in range of any player.
}

// Vehicle seeker function, which checks all vehicles and spawns or destroys them based on proximity to players
public VehicleSeeker()
{
	//foreach (new vehicleid : VehicleIter)
    Loop(v, MAX_STREAM_VEHICLES)  // Loop through all vehicles
    {
		if (v < 0 || v >= MAX_STREAM_VEHICLES) continue;
		if (vInfo[v][IsPopulated] == false) continue;  // Skip unpopulated vehicles
		
		// Cache the result of proximity check
        new bool:isInRange = IsInRangeOfAnyPlayer(v);

        // If vehicle is not spawned and a player is in range, create the vehicle
        if (vInfo[v][IsSpawned] == false && isInRange == true)
        {
            if(VSD == true) { printf("[DEBUG] Spawning vehicle: StreamID: %d, VehicleID: %d", v, vInfo[v][vID]); }
            CreateTheVehicle(v);
            vInfo[v][IsActive] = true;  // Mark vehicle as active
        }
		// If the vehicle is already spawned
        if (vInfo[v][IsSpawned] == true)
        {
            // If no player is in range, destroy the vehicle
            if (isInRange == false)
            {
                if(VSD == true) { printf("[DEBUG] Destroying vehicle: StreamID: %d, VehicleID: %d", v, vInfo[v][vID]); }
                DestroyTheVehicle(v);
                vInfo[v][IsActive] = false;  // Mark vehicle as inactive
            }
            else  // If a player is in range, update vehicle properties
            {
                if(VSD == true) { printf("[DEBUG] Updating vehicle: StreamID: %d, VehicleID: %d", v, vInfo[v][vID]); }

                // Update the vehicle's position, angle, and health
                GetVehiclePos(vInfo[v][vID], vInfo[v][vLastX], vInfo[v][vLastY], vInfo[v][vLastZ]);
                GetVehicleZAngle(vInfo[v][vID], vInfo[v][vLastA]);
                GetVehicleHealth(vInfo[v][vID], vInfo[v][vHealth]);

                vInfo[v][IsActive] = true;  // Mark vehicle as active again
            }
        }
    }
    return 1;
}

// Function to create a vehicle at a specific location
stock CreateStreamVehicle(modelid, Float:spawnX, Float:spawnY, Float:spawnZ, Float:angle, colour1, colour2, respawnDelay = RESPAWN_DELAY, bool:addSiren = true, Stream_Distance = VEHICLE_STREAM_DISTANCE)
{
	if(lastsvid > MAX_STREAM_VEHICLES) return printf("[Vehicle Streamer]: %d > %d", lastsvid, MAX_STREAM_VEHICLES);
	    
	// Assign vehicle data to the VehicleInfo array

	vInfo[lastsvid][vModel] = modelid;
	vInfo[lastsvid][vColor1] = colour1;
	vInfo[lastsvid][vColor2] = colour2;
	vInfo[lastsvid][vSpawnX] = spawnX;
	vInfo[lastsvid][vSpawnY] = spawnY;
	vInfo[lastsvid][vSpawnZ] = spawnZ;
	vInfo[lastsvid][vSpawnA] = angle;
	
	vInfo[lastsvid][vLastX] = spawnX;
	vInfo[lastsvid][vLastY] = spawnY;
	vInfo[lastsvid][vLastZ] = spawnZ;
	vInfo[lastsvid][vLastA] = angle;

	vInfo[lastsvid][FirstSpawn] = true;
	vInfo[lastsvid][IsSpawned] = false;
	vInfo[lastsvid][IsActive] = false;
	vInfo[lastsvid][vHealth] = 1000;
	vInfo[lastsvid][vID] = INVALID_VEHICLE_ID;
	vInfo[lastsvid][IsPopulated] = true;
	vInfo[lastsvid][vStream] = Stream_Distance;
	vInfo[lastsvid][vSiren] = addSiren;
	vInfo[lastsvid][vRespawn] = respawnDelay;

	if(VSD == true) { printf("CreateStreamVehicle(%d, %f, %f, %f, %f, %d, %d, %d, %d, bool:addSiren, lastsvid: %d)", 
       vInfo[lastsvid][vModel], 
       vInfo[lastsvid][vSpawnX], 
       vInfo[lastsvid][vSpawnY], 
       vInfo[lastsvid][vSpawnZ], 
       vInfo[lastsvid][vSpawnA], 
       vInfo[lastsvid][vColor1], 
       vInfo[lastsvid][vColor2], 
       vInfo[lastsvid][vRespawn], 
       vInfo[lastsvid][vStream], 
       lastsvid);
	}
	
	lastsvid++; // Increment the last stream vehicle ID.
	//Iter_Add(VehicleIter, i);
	return lastsvid;
}

// Function to actually create the vehicle in the game world
stock CreateTheVehicle(vv)
{
    // Check if the vehicle is already spawned
    if(vInfo[vv][IsSpawned] == true) 
        return printf("[DEBUG] [Vehicle Streamer] Vehicle already Spawed!!! (VehicleID: %d)", vInfo[vv][vID]); 

    // Create the vehicle and store its ID
    vInfo[vv][vID] = CreateVehicle(
        vInfo[vv][vModel],      // Vehicle model
        vInfo[vv][vLastX],      // Last known X position
        vInfo[vv][vLastY],      // Last known Y position
        vInfo[vv][vLastZ],      // Last known Z position
        vInfo[vv][vLastA],      // Last known angle/rotation
        vInfo[vv][vColor1],     // Primary color
        vInfo[vv][vColor2],     // Secondary color
        vInfo[vv][vRespawn],    // Respawn state
        bool:vInfo[vv][vSiren]  // Siren enabled/disabled
    );

    // Update vehicle metadata
    vInfo[vv][FirstSpawn] = false;  // Mark vehicle as not being spawned for the first time
    vInfo[vv][IsSpawned] = true;    // Mark vehicle as spawned

    // Set the health of the vehicle
    SetVehicleHealth(vInfo[vv][vID], vInfo[vv][vHealth]);

	for(new m = 0; m < 12; m++)
	{
		if(GetvMods[vv][m] > 0)
		{
			AddVehicleComponent(vv, GetvMods[vv][m]);
		}
	}

    // Debug logging if VSD is enabled
    if(VSD == true)
    { 
        // Log vehicle creation details
        printf("CreateTheVehicle(VehicleID: %d, %d, %.0f, %.0f, %.0f, %.0f, %d, %d, %d, %d, %d)", 
            vInfo[vv][vID],         // Vehicle ID
            vInfo[vv][vModel],      // Vehicle model
            vInfo[vv][vLastX],      // Last X position
            vInfo[vv][vLastY],      // Last Y position
            vInfo[vv][vLastZ],      // Last Z position
            vInfo[vv][vLastA],      // Last angle/rotation
            vInfo[vv][vColor1],     // Primary color
            vInfo[vv][vColor2],     // Secondary color
            vInfo[vv][vRespawn],    // Respawn state
            vInfo[vv][vStream],     // Streaming state
            lastsvid                      // Last server-side ID (custom field)
        ); 
    }

    // Return the newly created vehicle's ID
    return vInfo[vv][vID];
}

stock DestroyTheVehicle(vv)
{
    // Check if the VSD flag is enabled
    if(VSD == true) 
    { 
        // Log the details of the vehicle being destroyed
        // Format specifiers:
        // %d - Integer values (Vehicle ID, Model, Color1, Color2, Respawn, Stream, Lastsvid)
        // %.0f - Floating-point values rounded to 0 decimal places (LastX, LastY, LastZ, LastA)
        printf("DestroyVehicle(VehicleID: %d, %d, %.0f, %.0f, %.0f, %.0f, %d, %d, %d, %d, %d)", 
            vInfo[vv][vID],         // Vehicle ID
            vInfo[vv][vModel],      // Vehicle Model
            vInfo[vv][vLastX],      // Last X position of the vehicle
            vInfo[vv][vLastY],      // Last Y position of the vehicle
            vInfo[vv][vLastZ],      // Last Z position of the vehicle
            vInfo[vv][vLastA],      // Last A (angle/rotation) of the vehicle
            vInfo[vv][vColor1],     // Primary color of the vehicle
            vInfo[vv][vColor2],     // Secondary color of the vehicle
            vInfo[vv][vRespawn],    // Respawn state of the vehicle
            vInfo[vv][vStream],     // Streaming state of the vehicle
            lastsvid                      // Last server-side ID (custom field)
        ); 
    }
    
    // Destroy the vehicle with the given Vehicle ID
    DestroyVehicle(vInfo[vv][vID]);
    
    // Update vehicle information to reflect its destruction
    vInfo[vv][FirstSpawn] = false;  // Mark the vehicle as no longer first spawned
    vInfo[vv][IsSpawned] = false;   // Mark the vehicle as not spawned
    vInfo[vv][vID] = INVALID_VEHICLE_ID;  // Set the vehicle ID to invalid
    vInfo[vv][IsActive] = false;    // Mark the vehicle as inactive
}


stock RespawnTheVehicle(vv)
{
	vInfo[vv][vLastX] = vInfo[vv][vSpawnX];
	vInfo[vv][vLastY] = vInfo[vv][vSpawnY];
	vInfo[vv][vLastZ] = vInfo[vv][vSpawnZ];
	vInfo[vv][vLastA] = vInfo[vv][vSpawnA];
}

/*
stock RandomVehicleMods(vehicleid)
{
    // Define possible mods (example mod IDs, replace with actual mod IDs).
    new possibleMods[] = {1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011};
    new numPossibleMods = sizeof(possibleMods);

    // Assign random mods to the vehicle.
    for (new i = 0; i < MAX_ALLOWED_MODS; i++)
    {
        new randomMod = possibleMods[random(numPossibleMods)];
        AddVehicleComponent(vehicleid, randomMod);
    }
}
*/

stock RandomColor(svid)
{
	new randnum1 = 0 + random(10);
	new randnum2 = 0 + random(10);
	switch (randnum1)
	{
		case 0:
		{
			vInfo[svid][vColor1] = 1;
		}
		case 1:
		{
			vInfo[svid][vColor1] = 130;
		}
		case 2:
		{
			vInfo[svid][vColor1] = 131;
		}
		case 3:
		{
			vInfo[svid][vColor1] = 132;
		}
		case 4:
		{
			vInfo[svid][vColor1] = 146;
		}
		case 5:
		{
			vInfo[svid][vColor1] = 147;
		}
		case 6:
		{
			vInfo[svid][vColor1] = 148;
		}
		case 7:
		{
			vInfo[svid][vColor1] = 151;
		}
		case 8:
		{
			vInfo[svid][vColor1] = 6;
		}
		case 9:
		{
			vInfo[svid][vColor1] = 128;
		}
		case 10:
		{
			vInfo[svid][vColor1] = 0;
		}
	}
	switch (randnum2)
	{
		case 0:
		{
			vInfo[svid][vColor2] = 1;
		}
		case 1:
		{
			vInfo[svid][vColor2] = 130;
		}
		case 2:
		{
			vInfo[svid][vColor2] = 131;
		}
		case 3:
		{
			vInfo[svid][vColor2] = 132;
		}
		case 4:
		{
			vInfo[svid][vColor2] = 146;
		}
		case 5:
		{
			vInfo[svid][vColor2] = 147;
		}
		case 6:
		{
			vInfo[svid][vColor2] = 148;
		}
		case 7:
		{
			vInfo[svid][vColor2] = 151;
		}
		case 8:
		{
			vInfo[svid][vColor2] = 6;
		}
		case 9:
		{
			vInfo[svid][vColor2] = 128;
		}
		case 10:
		{
			vInfo[svid][vColor2] = 0;
		}
	}
}

stock RandomPlate(svid)
{
	new randnumb = 1 + random(9);
	new strrr[32];
    format(strrr, sizeof(strrr), "OPEN MP %d", randnumb);
	vInfo[svid][vPlate] = strrr;
    SetVehicleNumberPlate(svid, vInfo[svid][vPlate]);
//	SetVehicleToRespawn(svid);
}

stock LoadStaticVehiclesFromFile(const filename[])
{
	new File:file_ptr;
	new line[256];
	new var_from_line[64];
	new vehicletype;
	new Float:SpawnX;
	new Float:SpawnY;
	new Float:SpawnZ;
	new Float:SpawnRot;
    new Color1, Color2;
	new index;
	new vehicles_loaded;

	file_ptr = fopen(filename,filemode:io_read);
	if(!file_ptr) return 0;

	vehicles_loaded = 0;

	while(fread(file_ptr,line,256) > 0)
	{
	    index = 0;

	    // Read type
  		index = token_by_delim(line,var_from_line,',',index);
  		if(index == (-1)) continue;
  		vehicletype = strval(var_from_line);
   		if(vehicletype < 400 || vehicletype > 611) continue;

  		// Read X, Y, Z, Rotation
  		index = token_by_delim(line,var_from_line,',',index+1);
  		if(index == (-1)) continue;
  		SpawnX = floatstr(var_from_line);

  		index = token_by_delim(line,var_from_line,',',index+1);
  		if(index == (-1)) continue;
  		SpawnY = floatstr(var_from_line);

  		index = token_by_delim(line,var_from_line,',',index+1);
  		if(index == (-1)) continue;
  		SpawnZ = floatstr(var_from_line);

  		index = token_by_delim(line,var_from_line,',',index+1);
  		if(index == (-1)) continue;
  		SpawnRot = floatstr(var_from_line);

  		// Read Color1, Color2
  		index = token_by_delim(line,var_from_line,',',index+1);
  		if(index == (-1)) continue;
  		Color1 = strval(var_from_line);

  		index = token_by_delim(line,var_from_line,';',index+1);
  		Color2 = strval(var_from_line);
  		
  		//printf("%d,%.2f,%.2f,%.2f,%.4f,%d,%d",vehicletype,SpawnX,SpawnY,SpawnZ,SpawnRot,Color1,Color2);
  		
  		CreateStreamVehicle(
    	vehicletype,  // The model ID of the vehicle
    	SpawnX,       // X coordinate for the spawn location
    	SpawnY,       // Y coordinate for the spawn location
    	SpawnZ,       // Z coordinate for the spawn location
    	SpawnRot,     // Rotation angle for the vehicle
    	Color1,       // Primary color ID
    	Color2,       // Secondary color ID
    	(30*60),      // Respawn delay in seconds (30 minutes)
    	true          // Add siren to the vehicle
		);

//		printf("AddStaticVehicleEX(%d, %f, %f, %f, %f, %d, %d, %d)", vehicletype,SpawnX,SpawnY,SpawnZ,SpawnRot,Color1,Color2,(30*60));
		
		/*new numplate_test[32+1];
		format(numplate_test,32,"GRLC{44AA33}%d",vid);
		SetVehicleNumberPlate(vid, numplate_test);*/
		
		vehicles_loaded++;
	}

	fclose(file_ptr);
	printf("Loaded %d vehicles from: %s", vehicles_loaded, filename);
	return vehicles_loaded;
}

stock token_by_delim(const string[], return_str[], delim, start_index)
{
	new x=0;
	while(string[start_index] != EOS && string[start_index] != delim) {
	    return_str[x] = string[start_index];
	    x++;
	    start_index++;
	}
	return_str[x] = EOS;
	if(string[start_index] == EOS) start_index = (-1);
	return start_index;
}

public OnFilterScriptInit()
{    
	// Initialize the iterator.
    //Iter_Init(VehicleIter);
	//foreach (new vehicleid : VehicleIter)
	Loop(svidd, MAX_STREAM_VEHICLES)
	{	
		vInfo[svidd][vModel] = 400;
		vInfo[svidd][vColor1] = 0;
		vInfo[svidd][vColor2] = 0;
		vInfo[svidd][vSpawnX] = 0.0;
		vInfo[svidd][vSpawnY] = 0.0;
		vInfo[svidd][vSpawnZ] = 0.0;
		vInfo[svidd][vSpawnA] = 0.0;
		vInfo[svidd][FirstSpawn] = false;
		vInfo[svidd][IsSpawned] = false;
		vInfo[svidd][IsActive] = false;
		vInfo[svidd][vHealth] = 0;
		vInfo[svidd][vID] = INVALID_VEHICLE_ID;
	}
//	gl_common vehicles (grand larceny)
	// SPECIAL
//	total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/trains.txt");
//	total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/pilots.txt");

   	// LAS VENTURAS
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_gen.txt");


    // SAN FIERRO
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_gen.txt");
//    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_train.txt");

    // LOS SANTOS
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_gen_inner.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_gen_outer.txt");


    // OTHER AREAS
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/whetstone.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/bone.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/flint.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/tierra.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/red_county.txt");

	// CUSTOM
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/custom.txt");

	// TEST
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_heavytraffic.txt");

    
//    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/trains_platform.txt");

    printf("Total vehicles from files: %d", total_vehicles_from_files);
    
	StartVehicleSeeking();
	StartVehicleRespawner();
	return 1;
}

// This function is called when the filter script is about to exit.
public OnFilterScriptExit()
{
    // Check if the VehicleSeeker timer is active and stop it to prevent it from running after the script exits.
    if (IsValidTimer(Seekingid)) // Verify that the timer ID is valid.
    {
        StopVehicleSeeking(); // Stop the vehicle seeking timer.
    }
	if (IsValidTimer(Respawnerid)) // Verify that the timer ID is valid.
    {
        StopVehicleRespawner(); // Stop the vehicle seeking timer.
    }

    // Loop through all vehicles in the VehicleInfo array.
	//foreach (new vehicleid : VehicleIter)
    Loop(i, MAX_STREAM_VEHICLES)
    {
        // Check if the vehicle is marked as spawned in the VehicleInfo array.
        if (vInfo[i][IsSpawned] == true)
        {
            DestroyTheVehicle(i); // Destroy the vehicle to free resources.
        }
    }

    // Log a message to the console to indicate that the filter script is exiting.
    // This helps with debugging and ensures that resources were properly cleaned up.
    printf("[Vehicle Streamer] FilterScript is exiting, all vehicles destroyed and timers stopped.");

    return 1; // Returning 1 indicates that the script handled the exit process successfully.
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
		new modcount = 0;
		for(new m = 0; m < MAX_ALLOWED_MODS; m++)
		{
	    	if(GetvMods[vehicleid][m] == 0)
	    	{
	        	GetvMods[vehicleid][m] = componentid;
//	        	SaveVehicleStats(vehicleid);
				modcount++;
	        	break;
			}
		}
		if(modcount == 0)
		{
	    	for(new m = 0; m < 12; m++)
			{
				GetvMods[vehicleid][m] = 0;
			}
//			SaveVehicleStats(vehicleid);
		}
		return 1;
}

/*
public OnPlayerConnect(playerid)
{
	StartVehicleSeeking();
	return 1;
}
*/
/*
public OnVehicleDestroy(vehicleid)
{
    // Loop through all streamable vehicles to find the matching vehicle ID
    for (new vv = 0; vv < MAX_STREAM_VEHICLES; vv++)
    {
        // Check if the vehicle ID matches the destroyed vehicle
        if (vInfo[vv][vID] == vehicleid)
        {
            if (VSD == true)
            {
                printf("[DEBUG] OnVehicleDestroy: VehicleID: %d, StreamID: %d", vehicleid, vv);
            }
            // Mark the vehicle as no longer spawned and update its status
            vInfo[vv][IsSpawned] = false;
            vInfo[vv][IsActive] = false;
            vInfo[vv][vID] = INVALID_VEHICLE_ID;
            return 1; // Exit after handling the matching vehicle
        }
    }
    return 1; // Return for vehicles not tracked in the streamer
}
*/
/*
public OnVehicleDeath(vehicleid, killerid)
{
    // Debug message for vehicle destruction
    if (VSD == true)
    {
        printf("[DEBUG] OnVehicleDeath: VehicleID: %d, KillerID: %d", vehicleid, killerid);
    }

    // Inform all players about the vehicle destruction
    new message[128];
    format(message, sizeof(message), "Vehicle %d was destroyed. Reported by player %d.", vehicleid, killerid);
    SendClientMessageToAll(0xFFFFFFFF, message);

    // Handle the vehicle's destruction in the streamer
    for (new vv = 0; vv < MAX_STREAM_VEHICLES; vv++)
    {
        if (vInfo[vv][vID] == vehicleid)
        {
            vInfo[vv][IsSpawned] = false;
            vInfo[vv][IsActive] = false;
            vInfo[vv][vID] = INVALID_VEHICLE_ID;
            break; // Exit loop once the matching vehicle is found
        }
    }
    return 1; // Indicate successful handling
}
*/
/*
public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
    if (newstate == PLAYER_STATE_DRIVER) // Player entered a vehicle as a driver
    {
		// Loop through all vehicles in the VehicleInfo array.
		//foreach (new vehicleid : VehicleIter)
    	Loop(vv, MAX_STREAM_VEHICLES)
    	{
     		// Check if the vehicle is marked as spawned in the VehicleInfo array.
        	if (vInfo[vv][IsSpawned] == true)
        	{
            	new vehicleid = GetPlayerVehicleID(playerid);
				if(vehicleid == vInfo[vv][vID])
				{
					new pcount = 0;
					for(new m = 0; m < 9; m++)
					{
	    				if(vInfo[vv][vPlayerID[m]] == INVALID_PLAYER_ID)
	    				{		
	        				vInfo[vv][vPlayerID[m]] = playerid;
							//SaveVehicleStats(vehicleid);
							pcount++;
	        				break;
						}
					}
					if(pcount == 0)
					{
	    				for(new m = 0; m < 9; m++)
						{
							vInfo[vv][vPlayerID[m]] = INVALID_PLAYER_ID;
						}
						//SaveVehicleStats(vehicleid);
					}
					//AddVehicleComponent(vehicleid, 1010); // Add NOS to the vehicle
				}
        	}
    	}

        
    }
    return 1;
}
*/
/*
public OnPlayerUpdate(playerid)
{
	if (IsPlayerInAnyVehicle(playerid))
	{
		// Loop through all vehicles in the VehicleInfo array.
		//foreach (new vehicleid : VehicleIter)
    	Loop(vv, MAX_STREAM_VEHICLES)
    	{
     		// Check if the vehicle is marked as spawned in the VehicleInfo array.
        	if (vInfo[vv][IsSpawned] == true)
        	{
            	new vehicleid = GetPlayerVehicleID(playerid);
				if(vehicleid == vInfo[vv][vID])
				{
					vInfo[vv][IsActive] = true;
				}
			}
		}
	}
	return 1;
}
*/
/*
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    new string[128];
    format(string, sizeof(string), "You are entering vehicle %i", vehicleid);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    return 1;
}
*/
/*
public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    // Get the damage status of all the components
    new 
        VEHICLE_PANEL_STATUS:panels,
        VEHICLE_DOOR_STATUS:doors,
        VEHICLE_LIGHT_STATUS:lights,
        VEHICLE_TYRE_STATUS:tyres;

    GetVehicleDamageStatus(vehicleid, panels, doors, lights, tyres);

    // Set the tyres to 0, which means none are popped
    tyres = VEHICLE_TYRE_STATUS_NONE;

    // Update the vehicle's damage status with unpopped tyres
    UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tyres);
    return 1;
}
*/
/*
public OnVehicleDeath(vehicleid, killerid)
{
    new string[64];
    format(string, sizeof(string), "Vehicle %i was destroyed. Reported by player %i.", vehicleid, killerid);
    SendClientMessageToAll(0xFFFFFFFF, string);
    return 1;
}
*/
/*
public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
    new string[128];
    format(string, sizeof(string), "You have changed your vehicle's paintjob to %d!", paintjobid);
    SendClientMessage(playerid, 0x33AA33AA, string);
    return 1;
}
*/
/*
public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
    new string[48];
    format(string, sizeof(string), "You resprayed vehicle %d to colors %d and %d!", vehicleid, color1, color2);
    SendClientMessage(playerid, COLOR_GREEN, string);
    return 1;
}
*/
/*
public OnVehicleSirenStateChange(playerid, vehicleid, newstate)
{
    if (newstate)
    {
        GameTextForPlayer(playerid, "~W~Siren ~G~on", 1000, 3);
    }
    else
    {
        GameTextForPlayer(playerid, "~W~Siren ~r~off", 1000, 3);
    }
    return 1;
}
*/
/*
public OnVehicleSpawn(vehicleid)
{
    printf("Vehicle %i spawned!",vehicleid);
    return 1;
}
*/
/*
public OnVehicleStreamIn(vehicleid, forplayerid)
{
    new string[32];
    format(string, sizeof(string), "You can now see vehicle %d.", vehicleid);
    SendClientMessage(forplayerid, 0xFFFFFFFF, string);
    return 1;
}
*/
/*
public OnVehicleStreamOut(vehicleid, forplayerid)
{
    new string[48];
    format(string, sizeof(string), "Your client is no longer streaming vehicle %d", vehicleid);
    SendClientMessage(forplayerid, 0xFFFFFFFF, string);
    return 1;
}
*/
/*
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
*/
/*
#include <open.mp>
#include <izcmd>

//enum E_AIRPLANE_NAMES { AIRPLANE_NAME[24] }; 
enum E_AIRPLANE_IDS { AIRPLANE_ID }; 
//new const AirplaneNames[][E_AIRPLANE_NAMES] = { {"Andromada"}, {"AT-400"}, {"Beagle"}, {"Cropduster"}, {"Dodo"}, {"Hydra"}, {"Nevada"}, {"Rustler"}, {"Shamal"}, {"Skimmer"}, {"Stuntplane"} }; 
new const AirplaneIDs[][E_AIRPLANE_IDS] = { {592}, {577}, {511}, {512}, {593}, {520}, {553}, {476}, {519}, {460}, {513} };

//enum E_HELICOPTER_NAMES { HELICOPTER_NAME[24] }; 
enum E_HELICOPTER_IDS { HELICOPTER_ID }; 
//new const HelicopterNames[][E_HELICOPTER_NAMES] = { {"Cargobob"}, {"Hunter"}, {"Leviathan"}, {"Maverick"}, {"News Chopper"}, {"Police Maverick"}, {"Raindance"}, {"Seasparrow"}, {"Sparrow"} }; 
new const HelicopterIDs[][E_HELICOPTER_IDS] = { {548}, {425}, {417}, {487}, {488}, {497}, {563}, {447}, {469} };

//enum E_BOAT_NAMES { BOAT_NAME[24] }; 
enum E_BOAT_IDS { BOAT_ID }; 
//new const BoatNames[][E_BOAT_NAMES] = { {"Coastguard"}, {"Dinghy"}, {"Jetmax"}, {"Launch"}, {"Marquis"}, {"Predator"}, {"Reefer"}, {"Speeder"}, {"Squalo"}, {"Tropic"} }; 
new const BoatIDs[][E_BOAT_IDS] = { {472}, {473}, {493}, {595}, {484}, {430}, {453}, {452}, {446}, {454} };

//enum E_BIKE_NAMES { BIKE_NAME[24] }; 
enum E_BIKE_IDS { BIKE_ID }; 
//new const BikeNames[][E_BIKE_NAMES] = { {"BF-400"}, {"Bike"}, {"BMX"}, {"Faggio"}, {"FCR-900"}, {"Freeway"}, {"Mountain Bike"}, {"NRG-500"}, {"PCJ-600"}, {"Pizzaboy"}, {"Sanchez"}, {"Wayfarer"} }; 
new const BikeIDs[][E_BIKE_IDS] = { {581}, {509}, {481}, {462}, {521}, {463}, {510}, {522}, {461}, {448}, {468}, {586} };

//enum E_2DOOR_COMPACT_NAMES { CAR_NAME[24] }; 
enum E_2DOOR_COMPACT_IDS { CAR_ID }; 
//new const CompactCarNames[][E_2DOOR_COMPACT_NAMES] = { {"Alpha"}, {"Blista Compact"}, {"Bravura"}, {"Buccaneer"}, {"Cadrona"}, {"Club"}, {"Esperanto"}, {"Euros"}, {"Feltzer"}, {"Fortune"}, {"Hermes"}, {"Hustler"}, {"Majestic"}, {"Manana"}, {"Picador"}, {"Previon"}, {"Stallion"}, {"Tampa"}, {"Virgo"} }; 
new const CompactCarIDs[][E_2DOOR_COMPACT_IDS] = { {602}, {496}, {401}, {518}, {527}, {589}, {419}, {587}, {533}, {526}, {474}, {545}, {517}, {410}, {600}, {436}, {439}, {549}, {491} };

//enum E_4DOOR_LUXURY_NAMES { CAR_NAME[24] }; 
enum E_4DOOR_LUXURY_IDS { CAR_ID }; 
//new const LuxuryCarNames[][E_4DOOR_LUXURY_NAMES] = { {"Admiral"}, {"Damaged Glendale"}, {"Elegant"}, {"Emperor"}, {"Glendale"}, {"Greenwood"}, {"Intruder"}, {"Merit"}, {"Nebula"}, {"Oceanic"}, {"Premier"}, {"Primo"}, {"Sentinel"}, {"Stafford"}, {"Stretch"}, {"Sunrise"}, {"Tahoma"}, {"Vincent"}, {"Washington"}, {"Willard"} }; 
new const LuxuryCarIDs[][E_4DOOR_LUXURY_IDS] = { {445}, {604}, {507}, {585}, {466}, {492}, {546}, {551}, {516}, {467}, {426}, {547}, {405}, {580}, {409}, {550}, {566}, {540}, {421}, {529} };

//enum E_CIVIL_SERVICE_NAMES { VEHICLE_NAME[24] }; 
enum E_CIVIL_SERVICE_IDS { VEHICLE_ID }; 
//new const CivilServiceNames[][E_CIVIL_SERVICE_NAMES] = { {"Baggage"}, {"Bus"}, {"Cabbie"}, {"Coach"}, {"Sweeper"}, {"Taxi"}, {"Towtruck"}, {"Trashmaster"}, {"Utility Van"} }; 
new const CivilServiceIDs[][E_CIVIL_SERVICE_IDS] = { {485}, {431}, {438}, {437}, {574}, {420}, {525}, {408}, {552} };

//enum E_GOV_VEHICLE_NAMES { VEHICLE_NAME[24] }; 
enum E_GOV_VEHICLE_IDS { VEHICLE_ID }; 
//new const GovVehicleNames[][E_GOV_VEHICLE_NAMES] = { {"Ambulance"}, {"Barracks"}, {"Enforcer"}, {"FBI Rancher"}, {"FBI Truck"}, {"Fire Truck"}, {"Fire Truck"}, {"HPV1000"}, {"Patriot"}, {"Police LS"}, {"Police LV"}, {"Police Ranger"}, {"Police SF"}, {"Rhino"}, {"S.W.A.T."}, {"Securicar"} }; 
new const GovVehicleIDs[][E_GOV_VEHICLE_IDS] = { {416}, {433}, {427}, {490}, {528}, {407}, {544}, {523}, {470}, {596}, {598}, {599}, {597}, {432}, {601}, {428} };

//enum E_HEAVY_UTILITY_NAMES { VEHICLE_NAME[24] }; 
enum E_HEAVY_UTILITY_IDS { VEHICLE_ID }; 
//new const HeavyUtilityNames[][E_HEAVY_UTILITY_NAMES] = { {"Benson"}, {"Boxville Mission"}, {"Boxville"}, {"Cement Truck"}, {"Combine Harvester"}, {"DFT-30"}, {"Dozer"}, {"Dumper"}, {"Dune"}, {"Flatbed"}, {"Hotdog"}, {"Linerunner"}, {"Mr. Whoopee"}, {"Mule"}, {"Packer"}, {"Roadtrain"}, {"Tanker"}, {"Tractor"}, {"Yankee"} }; 
new const HeavyUtilityIDs[][E_HEAVY_UTILITY_IDS] = { {499}, {609}, {498}, {524}, {532}, {578}, {486}, {406}, {573}, {455}, {588}, {403}, {423}, {414}, {443}, {515}, {514}, {531}, {456} };

//enum E_LIGHT_TRUCKS_VANS_NAMES { VEHICLE_NAME[24] }; 
enum E_LIGHT_TRUCKS_VANS_IDS { VEHICLE_ID }; 
//new const LightTruckVanNames[][E_LIGHT_TRUCKS_VANS_NAMES] = { {"Berkley's RC Van"}, {"Bobcat"}, {"Burrito"}, {"Damaged Sadler"}, {"Forklift"}, {"Moonbeam"}, {"Mower"}, {"News Van"}, {"Pony"}, {"Rumpo"}, {"Sadler"}, {"Tug"}, {"Walton"}, {"Yosemite"} }; 
new const LightTruckVanIDs[][E_LIGHT_TRUCKS_VANS_IDS] = { {459}, {422}, {482}, {605}, {530}, {418}, {572}, {582}, {413}, {440}, {543}, {583}, {478}, {554} };

//enum E_SUVS_WAGONS_NAMES { VEHICLE_NAME[24] }; 
enum E_SUVS_WAGONS_IDS { VEHICLE_ID }; 
//new const SUVWagonNames[][E_SUVS_WAGONS_NAMES] = { {"Huntley"}, {"Landstalker"}, {"Perennial"}, {"Rancher"}, {"Rancher Lure"}, {"Regina"}, {"Romero"}, {"Solair"} }; 
new const SUVWagonIDs[][E_SUVS_WAGONS_IDS] = { {579}, {400}, {404}, {489}, {505}, {479}, {442}, {458} };

//enum E_LOWRIDER_NAMES { VEHICLE_NAME[24] }; 
enum E_LOWRIDER_IDS { VEHICLE_ID }; 
//new const LowriderNames[][E_LOWRIDER_NAMES] = { {"Blade"}, {"Broadway"}, {"Remington"}, {"Savanna"}, {"Slamvan"}, {"Tornado"}, {"Voodoo"} }; 
new const LowriderIDs[][E_LOWRIDER_IDS] = { {536}, {575}, {534}, {567}, {535}, {576}, {412} };

//enum E_MUSCLE_CAR_NAMES { VEHICLE_NAME[24] }; 
enum E_MUSCLE_CAR_IDS { VEHICLE_ID }; 
//new const MuscleCarNames[][E_MUSCLE_CAR_NAMES] = { {"Buffalo"}, {"Clover"}, {"Phoenix"}, {"Sabre"} }; 
new const MuscleCarIDs[][E_MUSCLE_CAR_IDS] = { {402}, {542}, {603}, {475} };

//enum E_STREET_RACER_NAMES { VEHICLE_NAME[24] }; 
enum E_STREET_RACER_IDS { VEHICLE_ID }; 
//new const StreetRacerNames[][E_STREET_RACER_NAMES] = { {"Banshee"}, {"Bullet"}, {"Cheetah"}, {"Comet"}, {"Elegy"}, {"Flash"}, {"Hotknife"}, {"Hotring Racer"}, {"Hotring Racer 2"}, {"Hotring Racer 3"}, {"Infernus"}, {"Jester"}, {"Stratum"}, {"Sultan"}, {"Super GT"}, {"Turismo"}, {"Uranus"}, {"Windsor"}, {"ZR-350"} }; 
new const StreetRacerIDs[][E_STREET_RACER_IDS] = { {429}, {541}, {415}, {480}, {562}, {565}, {434}, {494}, {502}, {503}, {411}, {559}, {561}, {560}, {506}, {451}, {558}, {555}, {477} };

//enum E_RC_VEHICLE_NAMES { VEHICLE_NAME[24] }; 
enum E_RC_VEHICLE_IDS { VEHICLE_ID }; 
//new const RCVehicleNames[][E_RC_VEHICLE_NAMES] = { {"RC Bandit"}, {"RC Baron"}, {"RC Cam"}, {"RC Goblin"}, {"RC Raider"}, {"RC Tiger"} }; 
new const RCVehicleIDs[][E_RC_VEHICLE_IDS] = { {441}, {464}, {594}, {501}, {465}, {564} };

//enum E_TRAILER_NAMES { VEHICLE_NAME[24] }; 
enum E_TRAILER_IDS { VEHICLE_ID }; 
//new const TrailerNames[][E_TRAILER_NAMES] = { {"Baggage Trailer"}, {"Baggage Trailer"}, {"Farm Trailer"}, {"Petrol Trailer"}, {"Trailer"}, {"Trailer"}, {"Trailer 1"}, {"Trailer 2"}, {"Trailer 3"} }; 
new const TrailerIDs[][E_TRAILER_IDS] = { {606}, {607}, {610}, {584}, {611}, {608}, {435}, {450}, {591} };

//enum E_TRAIN_NAMES { VEHICLE_NAME[24] }; 
enum E_TRAIN_IDS { VEHICLE_ID }; 
//new const TrainNames[][E_TRAIN_NAMES] = { {"Box Freight"}, {"Brown Streak"}, {"Brown Streak Carriage"}, {"Flat Freight"}, {"Freight"}, {"Tram"} }; 
new const TrainIDs[][E_TRAIN_IDS] = { {590}, {538}, {570}, {569}, {537}, {449} };

//enum E_RECREATIONAL_NAMES { VEHICLE_NAME[24] }; 
enum E_RECREATIONAL_IDS { VEHICLE_ID }; 
//new const RecreationalNames[][E_RECREATIONAL_NAMES] = { {"Bandito"}, {"BF Injection"}, {"Bloodring Banger"}, {"Caddy"}, {"Camper"}, {"Journey"}, {"Kart"}, {"Mesa"}, {"Monster"}, {"Monster 2"}, {"Monster 3"}, {"Quadbike"}, {"Sandking"}, {"Vortex"} }; 
new const RecreationalIDs[][E_RECREATIONAL_IDS] = { {568}, {424}, {504}, {457}, {483}, {508}, {571}, {500}, {444}, {556}, {557}, {471}, {495}, {539} };

public OnFilterScriptInit()
{
    print("FilterScript initialized.");
    print("This FilterScript allows players to spawn random vehicles from various categories.");
    print("Use the /randomvehicle or /rv command to create a random vehicle.");
    return 1;
}

// Function to create a random vehicle from a given category
stock CreateRandomVehicle(playerid, category)
{
    new vehicleID;
    new Float:x, Float:y, Float:z;

    switch (category)
    {
        case 1: // Airplanes
        {
            vehicleID = AirplaneIDs[random(sizeof(AirplaneIDs))][AIRPLANE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z + 3, random(360), -1, -1, 100);
            
        }
        case 2: // Helicopters
        {
            vehicleID = HelicopterIDs[random(sizeof(HelicopterIDs))][HELICOPTER_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z + 3, random(360), -1, -1, 100);
            
        }
        case 3: // Boats
        {
            vehicleID = BoatIDs[random(sizeof(BoatIDs))][BOAT_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 4: // Bikes
        {
            vehicleID = BikeIDs[random(sizeof(BikeIDs))][BIKE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 5: // 2-Door & Compact cars
        {
            vehicleID = CompactCarIDs[random(sizeof(CompactCarIDs))][CAR_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 6: // 4-Door & Luxury cars
        {
            vehicleID = LuxuryCarIDs[random(sizeof(LuxuryCarIDs))][CAR_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 7: // Civil service vehicles
        {
            vehicleID = CivilServiceIDs[random(sizeof(CivilServiceIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 8: // Government vehicles
        {
            vehicleID = GovVehicleIDs[random(sizeof(GovVehicleIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 9: // Heavy & Utility trucks
        {
            vehicleID = HeavyUtilityIDs[random(sizeof(HeavyUtilityIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 10: // Light trucks & Vans
        {
            vehicleID = LightTruckVanIDs[random(sizeof(LightTruckVanIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 11: // SUVs & Wagons
        {
            vehicleID = SUVWagonIDs[random(sizeof(SUVWagonIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 12: // Lowriders
        {
            vehicleID = LowriderIDs[random(sizeof(LowriderIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 13: // Muscle cars
        {
            vehicleID = MuscleCarIDs[random(sizeof(MuscleCarIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 14: // Street racers
        {
            vehicleID = StreetRacerIDs[random(sizeof(StreetRacerIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 15: // RC Vehicles
        {
            vehicleID = RCVehicleIDs[random(sizeof(RCVehicleIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 16: // Trailers
        {
            vehicleID = TrailerIDs[random(sizeof(TrailerIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 17: // Trains & Railroad cars
        {
            vehicleID = TrainIDs[random(sizeof(TrainIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
        case 18: // Recreational
        {
            vehicleID = RecreationalIDs[random(sizeof(RecreationalIDs))][VEHICLE_ID];
            GetPlayerPos(playerid, x, y, z);
            CreateVehicle(vehicleID, x + random(10), y + random(10), z, random(360), -1, -1, 100);
            
        }
    }
    return vehicleID;
}

// Command to create a random vehicle
CMD:randomvehicle(playerid, params[])
{
    new category = random(18) + 1; // Random category between 1 and 18
    CreateRandomVehicle(playerid, category);
    return 1;
}

// Short form command to create a random vehicle
CMD:rv(playerid, params[])
{
    return cmd_randomvehicle(playerid, params);
}
*/
/*

*/
