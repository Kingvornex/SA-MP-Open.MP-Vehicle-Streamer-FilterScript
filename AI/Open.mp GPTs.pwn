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

