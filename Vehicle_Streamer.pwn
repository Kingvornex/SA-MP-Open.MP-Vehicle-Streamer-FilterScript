
// ACNR CARS from file

#include <open.mp>

// Define constants for configuration.
#define MAX_STREAM_VEHICLES 3000  // Maximum number of streamable vehicles.

#define VEHICLE_STREAM_DISTANCE 500  // Distance at which vehicles are streamed to players.
#define RESPAWN_DELAY 1800  // Vehicle respawn delay in seconds (30 minutes).
#define VEHICLE_SEEKER_DELAY 100  // Delay between vehicle streaming checks (in milliseconds).

// Macro to simplify creating loops.
#define Loop(%0,%1) for(new %0 = 0; %0 < %1; %0++)

// Debugging flag.
new bool:VSD = true; // Enable/disable debug logging.

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
	vInterior,      // Interior ID for the vehicle.
	vWorld,         // Virtual world ID for the vehicle.
	vStream,        // Stream distance for the vehicle.
	vSiren,         // Indicates if the vehicle has a siren.
	vRespawn,       // Respawn delay for the vehicle.
	Float:vHealth   // Vehicle health.
}
new VehicleInfo[MAX_STREAM_VEHICLES][Stream_vehicle]; // Array to store vehicle properties.

// Variables to keep track of vehicle data.
new lastsvid = 0; // Last streamable vehicle ID.
new total_vehicles_from_files = 0; // Total vehicles loaded from file.
new Seekingid; // ID for the seeker timer.

// new _p_VisibleVehicles[MAX_PLAYERS];

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

// Check if a vehicle is in range of any player.
stock bool:IsInRangeOfAnyPlayer(vv)
{
	Loop(i, MAX_PLAYERS) // Iterate through all players.
	{
		new Float:posx, Float:posy, Float:posz; // Player position variables.
		GetPlayerPos(i, posx, posy, posz); // Get the player's position.
		new Float:tempposx, Float:tempposy, Float:tempposz; // Temporary variables for position differences.
		tempposx = (VehicleInfo[vv][vLastX] - posx); // X difference.
        tempposy = (VehicleInfo[vv][vLastY] - posy); // Y difference.
        tempposz = (VehicleInfo[vv][vLastZ] - posz); // Z difference.
		new radi = VehicleInfo[vv][vStream]; // Stream distance for the vehicle.
        if( ((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)) )
        {
			if(VSD == true) { printf("IsInRangeOfAnyPlayer(PID: %d, SVID: %d, VID: %d) = true", i, vv, VehicleInfo[vv][vID]); }
            return true; // Vehicle is within range of a player.
        }
    }
    return false; // Vehicle is not in range of any player.
}

/* 
// copy from CheckpointManager2.inc
public VehicleSeeker()
{
    // Declaring temporary variables for player position, interior, and virtual world
    new Float:__posX, Float:__posY, Float:__posZ;
    new __interior;
    new __virtualWorld;

    // Loop through all players
    Loop(i, MAX_PLAYERS)
    {
        // Skip the iteration if the player is not connected
        if (!IsPlayerConnected(i)) continue;
        
        // Get the position of the player
        GetPlayerPos(i, Float:__posX, Float:__posY, Float:__posZ);

        // Check if the player is near any vehicle (i.e., if the player has any vehicle assigned to them in the _p_VisibleVehicles array)
        if (_p_VisibleVehicles[i] > -1)
        {
            // If the player is no longer near the vehicle (out of streaming range)
            if (__posX < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnX] - VehicleInfo[_p_VisibleVehicles[i]][vStream])   // Player's X is too far left
                || __posX > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnX] + VehicleInfo[_p_VisibleVehicles[i]][vStream])   // Player's X is too far right
                || __posY < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnY] - VehicleInfo[_p_VisibleVehicles[i]][vStream])   // Player's Y is too far behind
                || __posY > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnY] + VehicleInfo[_p_VisibleVehicles[i]][vStream])   // Player's Y is too far ahead
                || __posZ < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnZ] - VehicleInfo[_p_VisibleVehicles[i]][vStream])   // Player's Z is too far below
                || __posZ > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnZ] + VehicleInfo[_p_VisibleVehicles[i]][vStream]))   // Player's Z is too far above
            {
                // If the player is out of range, destroy the vehicle
                DestroyTheVehicle(i);
                // Reset the vehicle index for this player
                _p_VisibleVehicles[i] = -1;
            }
        }
        else
        {
            // Get the player's interior and virtual world (this ensures that the vehicle search is within the same environment)
            __interior = GetPlayerInterior(i);
            __virtualWorld = GetPlayerVirtualWorld(i);

            // Look for a new vehicle for the player
            Loop(j, MAX_STREAM_VEHICLES)
            {
                // Skip vehicles that are not populated (i.e., haven't been created yet)
                if (!VehicleInfo[j][IsPopulated]) continue;

                // Skip vehicles that are in a different interior or virtual world than the player
                if (VehicleInfo[j][vInterior] != __interior) continue;
                if (VehicleInfo[j][vWorld] != __virtualWorld) continue;

                // Check if the player is within the streaming range of this vehicle (using the same range logic as before)
                if (__posX > (VehicleInfo[j][vSpawnX] - VehicleInfo[j][vStream])
                    && __posX < (VehicleInfo[j][vSpawnX] + VehicleInfo[j][vStream])
                    && __posY > (VehicleInfo[j][vSpawnY] - VehicleInfo[j][vStream])
                    && __posY < (VehicleInfo[j][vSpawnY] + VehicleInfo[j][vStream])
                    && __posZ > (VehicleInfo[j][vSpawnZ] - VehicleInfo[j][vStream])
                    && __posZ < (VehicleInfo[j][vSpawnZ] + VehicleInfo[j][vStream]))
                {
                    // If the player is within the vehicle's range, create the vehicle for them
                    CreateVehicle(VehicleInfo[j][vModel], VehicleInfo[j][vSpawnX], VehicleInfo[j][vSpawnY], VehicleInfo[j][vSpawnZ], VehicleInfo[j][vSpawnA], VehicleInfo[j][vColor1], VehicleInfo[j][vColor2], VehicleInfo[j][vRespawn], bool:VehicleInfo[j][vSiren]);
                    // Assign this vehicle to the player in the _p_VisibleVehicles array
                    _p_VisibleVehicles[i] = j;
                    // Stop looking for other vehicles once one is found
                    break;
                }
            }
        }
    }
    return 1;  // Return 1 to indicate the function finished successfully
}

*/

// Vehicle seeker function, which checks all vehicles and spawns or destroys them based on proximity to players
public VehicleSeeker()
{
    Loop(v, MAX_STREAM_VEHICLES)  // Loop through all vehicles
    {
        if (VehicleInfo[v][IsPopulated] == true)  // Check if the vehicle is populated (has data)
        {
            if (VehicleInfo[v][IsSpawned] == false)  // If vehicle is not spawned
            {
                if (IsInRangeOfAnyPlayer(v) == true)  // Check if any player is in range
                {
                    CreateTheVehicle(v);  // Create the vehicle if in range
                    VehicleInfo[v][IsActive] = true;  // Mark vehicle as active
                }
            }
            if (VehicleInfo[v][IsSpawned] == true)  // If the vehicle is already spawned
            {
                if (IsInRangeOfAnyPlayer(v) == false)  // If no player is in range
                {
                    DestroyTheVehicle(v);  // Destroy the vehicle if out of range
                    VehicleInfo[v][IsActive] = false;  // Mark vehicle as inactive
                }
                if (IsInRangeOfAnyPlayer(v) == true)  // If a player is in range again
                {
                    GetVehiclePos(VehicleInfo[v][vID], VehicleInfo[v][vLastX], VehicleInfo[v][vLastY], VehicleInfo[v][vLastZ]);  // Update vehicle position
                    GetVehicleZAngle(VehicleInfo[v][vID], VehicleInfo[v][vLastA]);  // Update vehicle angle
                    VehicleInfo[v][IsActive] = true;  // Mark vehicle as active again
					GetVehicleHealth(VehicleInfo[v][vID], VehicleInfo[v][vHealth]); // Retrieve and store the current vehicle health
                }
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

	VehicleInfo[lastsvid][vModel] = modelid;
	VehicleInfo[lastsvid][vColor1] = colour1;
	VehicleInfo[lastsvid][vColor2] = colour2;
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
	VehicleInfo[lastsvid][vStream] = Stream_Distance;
	VehicleInfo[lastsvid][vSiren] = addSiren;
	VehicleInfo[lastsvid][vRespawn] = respawnDelay;

	if(VSD == true) { printf("CreateStreamVehicle(%d, %f, %f, %f, %f, %d, %d, %d, %d, bool:addSiren, lastsvid: %d)", 
       VehicleInfo[lastsvid][vModel], 
       VehicleInfo[lastsvid][vSpawnX], 
       VehicleInfo[lastsvid][vSpawnY], 
       VehicleInfo[lastsvid][vSpawnZ], 
       VehicleInfo[lastsvid][vSpawnA], 
       VehicleInfo[lastsvid][vColor1], 
       VehicleInfo[lastsvid][vColor2], 
       VehicleInfo[lastsvid][vRespawn], 
       VehicleInfo[lastsvid][vStream], 
       lastsvid);
	}
	
	lastsvid++; // Increment the last stream vehicle ID.

	return lastsvid;
}

// Function to actually create the vehicle in the game world
stock CreateTheVehicle(vv)
{
	if(VehicleInfo[vv][IsSpawned] == true) return printf("[DEBUG] [Vehicle Streamer] Vehicle already Spawed!!! (VehicleID: %d)", VehicleInfo[vv][vID]);   // If the vehicle is not already spawned
	
	VehicleInfo[vv][vID] = CreateVehicle(VehicleInfo[vv][vModel], VehicleInfo[vv][vLastX], VehicleInfo[vv][vLastY], VehicleInfo[vv][vLastZ], VehicleInfo[vv][vLastA], VehicleInfo[vv][vColor1], VehicleInfo[vv][vColor2], VehicleInfo[vv][vRespawn], bool:VehicleInfo[vv][vSiren]);
	VehicleInfo[vv][FirstSpawn] = false;
	VehicleInfo[vv][IsSpawned] = true;
	SetVehicleHealth(VehicleInfo[vv][vID], VehicleInfo[vv][vHealth]);  // Set the vehicle's health
	if(VSD == true)
	{ 
    printf("CreateTheVehicle(VehicleID: %d, %d, %.0f, %.0f, %.0f, %.0f, %d, %d, %d, bool:addSiren, lastsvid: %d)", 
           VehicleInfo[vv][vID], 
           VehicleInfo[vv][vModel], 
           VehicleInfo[vv][vLastX], 
           VehicleInfo[vv][vLastY], 
           VehicleInfo[vv][vLastZ], 
           VehicleInfo[vv][vLastA], 
           VehicleInfo[vv][vColor1], 
           VehicleInfo[vv][vColor2], 
           VehicleInfo[vv][vRespawn], 
           VehicleInfo[vv][vStream],
           lastsvid); 
	}
	return VehicleInfo[vv][vID];
}

stock DestroyTheVehicle(vv)
{
	if(VSD == true) { printf("DestroyVehicle(VehicleID: %d, %d, %.0f, %.0f, %.0f, %.0f, %d, %d, %d, bool:addSiren, lastsvid: %d)", VehicleInfo[vv][vID], VehicleInfo[vv][vModel], VehicleInfo[vv][vLastX], VehicleInfo[vv][vLastY], VehicleInfo[vv][vLastZ], VehicleInfo[vv][vLastA], VehicleInfo[vv][vColor1], VehicleInfo[vv][vColor2], VehicleInfo[vv][vRespawn], VehicleInfo[vv][vStream], lastsvid); }
	
	DestroyVehicle(VehicleInfo[vv][vID]);
	VehicleInfo[vv][FirstSpawn] = false;
	VehicleInfo[vv][IsSpawned] = false;
	VehicleInfo[vv][vID] = INVALID_VEHICLE_ID;
	VehicleInfo[vv][IsActive] = false;
}

stock RespawnTheVehicle(vv)
{
	VehicleInfo[vv][vLastX] = VehicleInfo[vv][vSpawnX];
	VehicleInfo[vv][vLastY] = VehicleInfo[vv][vSpawnY];
	VehicleInfo[vv][vLastZ] = VehicleInfo[vv][vSpawnZ];
	VehicleInfo[vv][vLastA] = VehicleInfo[vv][vSpawnA];
}

stock RandomColor(svid)
{
	new randnum1 = 0 + random(10);
	new randnum2 = 0 + random(10);
	switch (randnum1)
	{
		case 0:
		{
			VehicleInfo[svid][vColor1] = 1;
		}
		case 1:
		{
			VehicleInfo[svid][vColor1] = 130;
		}
		case 2:
		{
			VehicleInfo[svid][vColor1] = 131;
		}
		case 3:
		{
			VehicleInfo[svid][vColor1] = 132;
		}
		case 4:
		{
			VehicleInfo[svid][vColor1] = 146;
		}
		case 5:
		{
			VehicleInfo[svid][vColor1] = 147;
		}
		case 6:
		{
			VehicleInfo[svid][vColor1] = 148;
		}
		case 7:
		{
			VehicleInfo[svid][vColor1] = 151;
		}
		case 8:
		{
			VehicleInfo[svid][vColor1] = 6;
		}
		case 9:
		{
			VehicleInfo[svid][vColor1] = 128;
		}
		case 10:
		{
			VehicleInfo[svid][vColor1] = 0;
		}
	}
	switch (randnum2)
	{
		case 0:
		{
			VehicleInfo[svid][vColor2] = 1;
		}
		case 1:
		{
			VehicleInfo[svid][vColor2] = 130;
		}
		case 2:
		{
			VehicleInfo[svid][vColor2] = 131;
		}
		case 3:
		{
			VehicleInfo[svid][vColor2] = 132;
		}
		case 4:
		{
			VehicleInfo[svid][vColor2] = 146;
		}
		case 5:
		{
			VehicleInfo[svid][vColor2] = 147;
		}
		case 6:
		{
			VehicleInfo[svid][vColor2] = 148;
		}
		case 7:
		{
			VehicleInfo[svid][vColor2] = 151;
		}
		case 8:
		{
			VehicleInfo[svid][vColor2] = 6;
		}
		case 9:
		{
			VehicleInfo[svid][vColor2] = 128;
		}
		case 10:
		{
			VehicleInfo[svid][vColor2] = 0;
		}
	}
}

stock RandomPlate(svid)
{
	new randnumb = 1 + random(9);
	new strrr[32];
    format(strrr, sizeof(strrr), "OPEN MP %d", randnumb);
	VehicleInfo[svid][vPlate] = strrr;
    SetVehicleNumberPlate(svid, VehicleInfo[svid][vPlate]);
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
	Loop(svidd, MAX_STREAM_VEHICLES)
	{	
		VehicleInfo[svidd][vModel] = 400;
		VehicleInfo[svidd][vColor1] = 0;
		VehicleInfo[svidd][vColor2] = 0;
		VehicleInfo[svidd][vSpawnX] = 0.0;
		VehicleInfo[svidd][vSpawnY] = 0.0;
		VehicleInfo[svidd][vSpawnZ] = 0.0;
		VehicleInfo[svidd][vSpawnA] = 0.0;
		VehicleInfo[svidd][FirstSpawn] = false;
		VehicleInfo[svidd][IsSpawned] = false;
		VehicleInfo[svidd][IsActive] = false;
		VehicleInfo[svidd][vHealth] = 0;
		VehicleInfo[svidd][vID] = INVALID_VEHICLE_ID;
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
    
//    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/trains_platform.txt");

    printf("Total vehicles from files: %d", total_vehicles_from_files);
    
	StartVehicleSeeking();
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

    // Loop through all vehicles in the VehicleInfo array.
    Loop(i, MAX_STREAM_VEHICLES)
    {
        // Check if the vehicle is marked as spawned in the VehicleInfo array.
        if (VehicleInfo[i][IsSpawned] == true)
        {
            DestroyTheVehicle(i); // Destroy the vehicle to free resources.
        }
    }

    // Log a message to the console to indicate that the filter script is exiting.
    // This helps with debugging and ensures that resources were properly cleaned up.
    printf("[Vehicle Streamer] FilterScript is exiting, all vehicles destroyed and timers stopped.");

    return 1; // Returning 1 indicates that the script handled the exit process successfully.
}
