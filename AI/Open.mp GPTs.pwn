public VehicleSeeker()
{
	// Iterate through all vehicles
	Loop(v, MAX_STREAM_VEHICLES)
	{
		if (vInfo[v][IsPopulated] == false || v < 0 || v >= MAX_STREAM_VEHICLES) continue;  // Skip unpopulated or out-of-bounds vehicles

		// Cache vehicle properties and check if it's in range of any player
		new Float:tempposx, Float:tempposy, Float:tempposz, Float:radi = vInfo[v][vStream];
		new bool:isInRange = false;
		
		// Using player position caching to minimize GetPlayerPos() calls
		Loop(i, MAX_PLAYERS)
		{
			// If player is in range, skip further checks for this vehicle
			if (IsPlayerConnected(i) && !IsPlayerNPC(i)) 
			{
				GetPlayerPos(i, tempposx, tempposy, tempposz);
				// Check if the vehicle is in range of the player (distance check optimization)
				if (Abs(vInfo[v][vLastX] - tempposx) < radi && Abs(vInfo[v][vLastY] - tempposy) < radi && Abs(vInfo[v][vLastZ] - tempposz) < radi)
				{
					isInRange = true;
					break;  // Exit early if any player is in range
				}
			}
		}

		// Spawn or destroy vehicle based on its state and player proximity
		if (vInfo[v][IsSpawned] == false && isInRange)
		{
			CreateTheVehicle(v);
			vInfo[v][IsActive] = true;
		}
		else if (vInfo[v][IsSpawned] && !isInRange)
		{
			DestroyTheVehicle(v);
			vInfo[v][IsActive] = false;
		}
		else if (vInfo[v][IsSpawned] && isInRange)
		{
			// Update vehicle position, angle, and health
			GetVehiclePos(vInfo[v][vID], vInfo[v][vLastX], vInfo[v][vLastY], vInfo[v][vLastZ]);
			GetVehicleZAngle(vInfo[v][vID], vInfo[v][vLastA]);
			GetVehicleHealth(vInfo[v][vID], vInfo[v][vHealth]);

			vInfo[v][IsActive] = true;
		}
	}
	return 1;
}

stock SaveVehicleData(vehicleID)
{
    new file_ptr;
    new buffer[1024];  // Buffer for storing formatted vehicle data
    new vID = vInfo[vehicleID][vID];

    if (vID == INVALID_VEHICLE_ID) return 0;  // Don't save if vehicle ID is invalid

    // Format vehicle data as a CSV or custom format
    format(buffer, sizeof(buffer), "%d,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%f,%d,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
           vInfo[vehicleID][vModel],
           vInfo[vehicleID][vSpawnX], vInfo[vehicleID][vSpawnY], vInfo[vehicleID][vSpawnZ], vInfo[vehicleID][vSpawnA],
           vInfo[vehicleID][vLastX], vInfo[vehicleID][vLastY], vInfo[vehicleID][vLastZ], vInfo[vehicleID][vLastA],
           vInfo[vehicleID][vColor1], vInfo[vehicleID][vColor2],
           vInfo[vehicleID][vPaintJob], vInfo[vehicleID][FirstSpawn], vInfo[vehicleID][IsSpawned], vInfo[vehicleID][IsActive],
           vInfo[vehicleID][IsPopulated], vInfo[vehicleID][IsOccupied], vInfo[vehicleID][vInterior], vInfo[vehicleID][vWorld],
           vInfo[vehicleID][vStream], vInfo[vehicleID][vSiren], vInfo[vehicleID][vRespawn],
           vInfo[vehicleID][vHealth], vInfo[vehicleID][panels], vInfo[vehicleID][doors], vInfo[vehicleID][lights],
           vInfo[vehicleID][tyres], vInfo[vehicleID][TrailerID], vInfo[vehicleID][CabID],
           vInfo[vehicleID][DriverID], vInfo[vehicleID][LastDriver], vInfo[vehicleID][state],
           vInfo[vehicleID][rightX], vInfo[vehicleID][rightY], vInfo[vehicleID][rightZ],
           vInfo[vehicleID][upX], vInfo[vehicleID][upY], vInfo[vehicleID][upZ], vInfo[vehicleID][atX], 
           vInfo[vehicleID][atY], vInfo[vehicleID][atZ], vInfo[vehicleID][engine], vInfo[vehicleID][lights],
           vInfo[vehicleID][alarm], vInfo[vehicleID][doors], vInfo[vehicleID][bonnet], vInfo[vehicleID][boot],
           vInfo[vehicleID][objective], vInfo[vehicleID][seats], vInfo[vehicleID][w], 
           vInfo[vehicleID][x], vInfo[vehicleID][y], vInfo[vehicleID][z]);

    // Save to a file (append to avoid overwriting)
    file_ptr = fopen("vehicle_data.txt", filemode:io_append);
    if (file_ptr == INVALID_FILE) return 0;

    fwrite(file_ptr, buffer, strlen(buffer));
    fclose(file_ptr);
    return 1;
}

stock LoadVehicleData(vehicleID)
{
    new file_ptr;
    new line[1024];
    new var_from_line[64];
    new index;

    file_ptr = fopen("vehicle_data.txt", filemode:io_read);
    if (file_ptr == INVALID_FILE) return 0;

    while (fread(file_ptr, line, sizeof(line)) > 0)
    {
        index = 0;

        // Parse the CSV formatted line
        index = token_by_delim(line, var_from_line, ',', index);
        if (index == -1) continue;  // Skip if line is malformed

        // Read and store vehicle data
        vInfo[vehicleID][vModel] = strval(var_from_line);
        vInfo[vehicleID][vSpawnX] = floatstr(var_from_line);
        vInfo[vehicleID][vSpawnY] = floatstr(var_from_line);
        vInfo[vehicleID][vSpawnZ] = floatstr(var_from_line);
        vInfo[vehicleID][vSpawnA] = floatstr(var_from_line);
        vInfo[vehicleID][vLastX] = floatstr(var_from_line);
        vInfo[vehicleID][vLastY] = floatstr(var_from_line);
        vInfo[vehicleID][vLastZ] = floatstr(var_from_line);
        vInfo[vehicleID][vLastA] = floatstr(var_from_line);
        vInfo[vehicleID][vColor1] = strval(var_from_line);
        vInfo[vehicleID][vColor2] = strval(var_from_line);
        vInfo[vehicleID][vPaintJob] = strval(var_from_line);
        vInfo[vehicleID][FirstSpawn] = strval(var_from_line);
        vInfo[vehicleID][IsSpawned] = strval(var_from_line);
        vInfo[vehicleID][IsActive] = strval(var_from_line);
        vInfo[vehicleID][IsPopulated] = strval(var_from_line);
        vInfo[vehicleID][IsOccupied] = strval(var_from_line);
        vInfo[vehicleID][vInterior] = strval(var_from_line);
        vInfo[vehicleID][vWorld] = strval(var_from_line);
        vInfo[vehicleID][vStream] = strval(var_from_line);
        vInfo[vehicleID][vSiren] = strval(var_from_line);
        vInfo[vehicleID][vRespawn] = strval(var_from_line);
        vInfo[vehicleID][vHealth] = floatstr(var_from_line);
        vInfo[vehicleID][panels] = strval(var_from_line);
        vInfo[vehicleID][doors] = strval(var_from_line);
        vInfo[vehicleID][lights] = strval(var_from_line);
        vInfo[vehicleID][tyres] = strval(var_from_line);
        vInfo[vehicleID][TrailerID] = strval(var_from_line);
        vInfo[vehicleID][CabID] = strval(var_from_line);
        vInfo[vehicleID][DriverID] = strval(var_from_line);
        vInfo[vehicleID][LastDriver] = strval(var_from_line);
        vInfo[vehicleID][state] = strval(var_from_line);
        vInfo[vehicleID][rightX] = floatstr(var_from_line);
        vInfo[vehicleID][rightY] = floatstr(var_from_line);
        vInfo[vehicleID][rightZ] = floatstr(var_from_line);
        vInfo[vehicleID][upX] = floatstr(var_from_line);
        vInfo[vehicleID][upY] = floatstr(var_from_line);
        vInfo[vehicleID][upZ] = floatstr(var_from_line);
        vInfo[vehicleID][atX] = floatstr(var_from_line);
        vInfo[vehicleID][atY] = floatstr(var_from_line);
        vInfo[vehicleID][atZ] = floatstr(var_from_line);
        vInfo[vehicleID][engine] = strval(var_from_line);
        vInfo[vehicleID][lights] = strval(var_from_line);
        vInfo[vehicleID][alarm] = strval(var_from_line);
        vInfo[vehicleID][doors] = strval(var_from_line);
        vInfo[vehicleID][bonnet] = strval(var_from_line);
        vInfo[vehicleID][boot] = strval(var_from_line);
        vInfo[vehicleID][objective] = strval(var_from_line);
        vInfo[vehicleID][seats] = strval(var_from_line);
        vInfo[vehicleID][w] = floatstr(var_from_line);
        vInfo[vehicleID][x] = floatstr(var_from_line);
        vInfo[vehicleID][y] = floatstr(var_from_line);
        vInfo[vehicleID][z] = floatstr(var_from_line);
    }

    fclose(file_ptr);
    return 1;
}


stock UpdateVehicleData(vehicleID)
{
    // Update the vehicle's position, angle, health, and other dynamic data
    GetVehiclePos(vInfo[vehicleID][vID], vInfo[vehicleID][vLastX], vInfo[vehicleID][vLastY], vInfo[vehicleID][vLastZ]);
    GetVehicleZAngle(vInfo[vehicleID][vID], vInfo[vehicleID][vLastA]);
    GetVehicleHealth(vInfo[vehicleID][vID], vInfo[vehicleID][vHealth]);

    // Optionally, save the updated data periodically or after significant changes
    SaveVehicleData(vehicleID);
}

// Called when a player enters a vehicle.
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    // Update vehicle state to reflect that it is now occupied.
    vInfo[vehicleid][IsOccupied] = true;
    vInfo[vehicleid][DriverID] = playerid;

    printf("Player %d entered vehicle %d as %s.", playerid, vehicleid, ispassenger ? "passenger" : "driver");

    return 1;
}

// Called when a player exits a vehicle.
public OnPlayerExitVehicle(playerid, vehicleid)
{
    // Update vehicle state to reflect that it is now unoccupied.
    vInfo[vehicleid][IsOccupied] = false;
    vInfo[vehicleid][DriverID] = INVALID_PLAYER_ID;

    printf("Player %d exited vehicle %d.", playerid, vehicleid);

    return 1;
}

// Called when an unoccupied vehicle updates (such as movement or rotation changes).
public OnUnoccupiedVehicleUpdate(vehicleid, playerid, passenger_seat)
{
    // Update the last known position and rotation of the vehicle.
    GetVehiclePos(vehicleid, vInfo[vehicleid][vLastX], vInfo[vehicleid][vLastY], vInfo[vehicleid][vLastZ]);
    GetVehicleZAngle(vehicleid, vInfo[vehicleid][vLastA]);

    printf("Vehicle %d updated by player %d.", vehicleid, playerid);

    return 1;
}

// Called when a vehicle's damage status is updated.
public OnVehicleDamageStatusUpdate(vehicleid, panels, doors, lights, tyres)
{
    // Update damage status in the vehicle information array.
    vInfo[vehicleid][panels] = panels;
    vInfo[vehicleid][doors] = doors;
    vInfo[vehicleid][lights] = lights;
    vInfo[vehicleid][tyres] = tyres;

    printf("Vehicle %d damage updated: panels %d, doors %d, lights %d, tyres %d.", vehicleid, panels, doors, lights, tyres);

    return 1;
}

// Called when a vehicle is destroyed.
public OnVehicleDeath(vehicleid, killerid)
{
    // Mark the vehicle as not spawned.
    vInfo[vehicleid][IsSpawned] = false;

    printf("Vehicle %d was destroyed by player %d.", vehicleid, killerid);

    return 1;
}

// Called when a vehicle's mod is changed.
public OnVehicleMod(vehicleid, playerid, componentid)
{
    // Add or update the vehicle's mod in the vMods array.
    for (new i = 0; i < 12; i++)
    {
        if (vInfo[vehicleid][vMods][i] == 0)
        {
            vInfo[vehicleid][vMods][i] = componentid;
            break;
        }
    }

    printf("Vehicle %d modded by player %d with component %d.", vehicleid, playerid, componentid);

    return 1;
}

// Called when a vehicle's paintjob is changed.
public OnVehiclePaintjob(vehicleid, playerid, paintjobid)
{
    // Update the vehicle's paint job in the vehicle information array.
    vInfo[vehicleid][vPaintJob] = paintjobid;

    printf("Vehicle %d paintjob changed by player %d to %d.", vehicleid, playerid, paintjobid);

    return 1;
}

// Called when a vehicle is resprayed.
public OnVehicleRespray(vehicleid, playerid, color1, color2)
{
    // Update the vehicle's colors.
    vInfo[vehicleid][vColor1] = color1;
    vInfo[vehicleid][vColor2] = color2;

    printf("Vehicle %d resprayed by player %d to colors %d, %d.", vehicleid, playerid, color1, color2);

    return 1;
}

// Called when a vehicle's siren state is changed.
public OnVehicleSirenStateChange(vehicleid, playerid, newstate)
{
    // Update the siren state.
    vInfo[vehicleid][vSiren] = newstate;

    printf("Vehicle %d siren state changed by player %d to %d.", vehicleid, playerid, newstate);

    return 1;
}

// Called when a vehicle is spawned.
public OnVehicleSpawn(vehicleid)
{
    // Mark the vehicle as spawned and update its initial position.
    vInfo[vehicleid][IsSpawned] = true;
    GetVehiclePos(vehicleid, vInfo[vehicleid][vLastX], vInfo[vehicleid][vLastY], vInfo[vehicleid][vLastZ]);
    GetVehicleZAngle(vehicleid, vInfo[vehicleid][vLastA]);
    GetVehicleHealth(vehicleid, vInfo[vehicleid][vHealth]);

    printf("Vehicle %d spawned.", vehicleid);

    return 1;
}

// Called when a vehicle streams in for a player.
public OnVehicleStreamIn(vehicleid, forplayerid)
{
    printf("Vehicle %d streamed in for player %d.", vehicleid, forplayerid);

    return 1;
}

// Called when a vehicle streams out for a player.
public OnVehicleStreamOut(vehicleid, forplayerid)
{
    printf("Vehicle %d streamed out for player %d.", vehicleid, forplayerid);

    return 1;
}
