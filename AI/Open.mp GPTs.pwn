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
