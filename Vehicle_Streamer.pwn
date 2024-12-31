
// ACNR CARS from file

#include <open.mp>

#define MAX_STREAM_VEHICLES 3000

#define VEHICLE_STREAM_DISTANCE 500
#define RESPAWN_DELAY 1800
#define VEHICLE_SEEKER_DELAY 100

#define Loop(%0,%1) for(new %0 = 0; %0 < %1; %0++)

new bool:VSD = true; //debug

enum Stream_vehicle
{
	vModel,
	vID,
	vColor1,
	vColor2,
	Float:vSpawnX,
	Float:vSpawnY,
	Float:vSpawnZ,
	Float:vSpawnA,
	Float:vLastX,
	Float:vLastY,
	Float:vLastZ,
	Float:vLastA,
	vPlate[32],
	vPaintJob,
	bool:FirstSpawn,
	bool:IsSpawned,
	bool:IsActive,
	bool:IsPopulated,
	vInterior,
	vWorld,
	vStream,
	vSiren,
	vRespawn,
	Float:vHealth
}
new VehicleInfo[MAX_STREAM_VEHICLES][Stream_vehicle];

new lastsvid = 0;

new total_vehicles_from_files=0;

new Seekingid;

// new _p_VisibleVehicles[MAX_PLAYERS];

forward VehicleSeeker();

stock StartVehicleSeeking()
{
	Seekingid = SetTimer("VehicleSeeker", VEHICLE_SEEKER_DELAY, true);
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: Seekingid (%d) = SetTimer(VehicleSeeker, VEHICLE_SEEKER_DELAY (%d), true);", Seekingid, VEHICLE_SEEKER_DELAY); }
	return 1;
}

stock StopVehicleSeeking()
{
	KillTimer(Seekingid);
	if(VSD == true) { printf("[Vehicle Streamer] [DEBUG]: KillTimer(Seekingid (%d));", Seekingid); }
	return 1;
}

stock bool:IsInRangeOfAnyPlayer(vv)
{
	Loop(i, MAX_PLAYERS)
	{
		new Float:posx, Float:posy, Float:posz;
		GetPlayerPos(i, posx, posy, posz);
		new Float:tempposx, Float:tempposy, Float:tempposz;
		tempposx = (VehicleInfo[vv][vLastX] -posx);
        tempposy = (VehicleInfo[vv][vLastY] -posy);
        tempposz = (VehicleInfo[vv][vLastZ] -posz);
		new radi = VehicleInfo[vv][vStream];
        if( ((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)) )
        {
			if(VSD == true) { printf("IsInRangeOfAnyPlayer(PID: %d, SVID: %d, VID: %d) = true", i, vv, VehicleInfo[vv][vID]); }
            return true;
        }
    }
    return false;
}

/*
public VehicleSeeker()
{
	new Float:__posX, Float:__posY, Float:__posZ;
	new __interior;
	new __virtualWorld;
//	Loop(svid, MAX_STREAM_VEHICLES)
	Loop(i, MAX_PLAYERS)
	{
//		printf("%d", svid);
//		Loop(i, MAX_PLAYERS)
//		{
		if(!IsPlayerConnected(i)) continue;
		
		GetPlayerPos(i, Float:__posX, Float:__posY, Float:__posZ);
		// Is the player near any Vehicle?
		if(_p_VisibleVehicles[i] > -1)
		{
			// If the player is no longer near that point
			if(__posX < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnX] - VehicleInfo[_p_VisibleVehicles[i]][vStream])
			|| __posX > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnX] + VehicleInfo[_p_VisibleVehicles[i]][vStream])
			|| __posY < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnY] - VehicleInfo[_p_VisibleVehicles[i]][vStream])
			|| __posY > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnY] + VehicleInfo[_p_VisibleVehicles[i]][vStream])
			|| __posZ < (VehicleInfo[_p_VisibleVehicles[i]][vSpawnZ] - VehicleInfo[_p_VisibleVehicles[i]][vStream])
			|| __posZ > (VehicleInfo[_p_VisibleVehicles[i]][vSpawnZ] + VehicleInfo[_p_VisibleVehicles[i]][vStream]))
			{
				DestroyTheVehicle(i);
				_p_VisibleVehicles[i] = -1;
			}
		}
		else
		{
			// Getting the player Interior and virtual world
			__interior = GetPlayerInterior(i);
			__virtualWorld = GetPlayerVirtualWorld(i);
			
			// Looking for a new Vehicle
			Loop(j, MAX_STREAM_VEHICLES)
			{
				if(!VehicleInfo[j][IsPopulated]) continue;
				if(VehicleInfo[j][vInterior] != __interior) continue;
				if(VehicleInfo[j][vWorld] != __virtualWorld) continue;
				
				if(__posX > (VehicleInfo[j][vSpawnX] - VehicleInfo[j][vStream])
				&& __posX < (VehicleInfo[j][vSpawnX] + VehicleInfo[j][vStream])
				&& __posY > (VehicleInfo[j][vSpawnY] - VehicleInfo[j][vStream])
				&& __posY < (VehicleInfo[j][vSpawnY] + VehicleInfo[j][vStream])
				&& __posZ > (VehicleInfo[j][vSpawnZ] - VehicleInfo[j][vStream])
				&& __posZ < (VehicleInfo[j][vSpawnZ] + VehicleInfo[j][vStream]))
				{
					CreateVehicle(VehicleInfo[j][vModel], VehicleInfo[j][vSpawnX], VehicleInfo[j][vSpawnY], VehicleInfo[j][vSpawnZ], VehicleInfo[j][vSpawnA], VehicleInfo[j][vColor1], VehicleInfo[j][vColor2], VehicleInfo[j][vRespawn], bool:VehicleInfo[j][vSiren]);
					_p_VisibleVehicles[i] = j;
					break;
				}
			}
		}
	}
	return 1;
}
*/

public VehicleSeeker()
{
	Loop(v, MAX_STREAM_VEHICLES)
	{
		if(VehicleInfo[v][IsPopulated] == true)
		{
			if(VehicleInfo[v][IsSpawned] == false)
			{
				if(IsInRangeOfAnyPlayer(v) == true)
				{
					CreateTheVehicle(v);
					VehicleInfo[v][IsActive] = true;
					// also more actions 
				}
			}
			if(VehicleInfo[v][IsSpawned] == true)
			{				
				if(IsInRangeOfAnyPlayer(v) == false)
				{
					DestroyTheVehicle(v);
					VehicleInfo[v][IsActive] = false; 
					// also more actions 
				}
				if(IsInRangeOfAnyPlayer(v) == true)
				{
					GetVehiclePos(VehicleInfo[v][vID], VehicleInfo[v][vLastX], VehicleInfo[v][vLastY], VehicleInfo[v][vLastZ]);
					GetVehicleZAngle(VehicleInfo[v][vID], VehicleInfo[v][vLastA]);
					VehicleInfo[v][IsActive] = true; 
				}
			}
		}
	}
	return 1;
}

stock CreateStreamVehicle(modelid, Float:spawnX, Float:spawnY, Float:spawnZ, Float:angle, colour1, colour2, respawnDelay = RESPAWN_DELAY, bool:addSiren = true, Stream_Distance = VEHICLE_STREAM_DISTANCE)
{
	if(lastsvid > MAX_STREAM_VEHICLES) return printf("[Vehicle Streamer]: %d > %d", lastsvid, MAX_STREAM_VEHICLES);
	
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
	
	lastsvid++;

	return lastsvid;
}

stock CreateTheVehicle(vv)
{
	VehicleInfo[vv][vID] = CreateVehicle(VehicleInfo[vv][vModel], VehicleInfo[vv][vLastX], VehicleInfo[vv][vLastY], VehicleInfo[vv][vLastZ], VehicleInfo[vv][vLastA], VehicleInfo[vv][vColor1], VehicleInfo[vv][vColor2], VehicleInfo[vv][vRespawn], bool:VehicleInfo[vv][vSiren]);
	VehicleInfo[vv][FirstSpawn] = false;
	VehicleInfo[vv][IsSpawned] = true;
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

forward ProxDetector(Float:radi, playerid, svid);
public ProxDetector(Float:radi, playerid, svid)
{
    if(IsPlayerConnected(playerid))
    {
        new Float:posx, Float:posy, Float:posz;
        new Float:oldposx, Float:oldposy, Float:oldposz;
        new Float:tempposx, Float:tempposy, Float:tempposz;
        GetPlayerPos(playerid, oldposx, oldposy, oldposz);
        tempposx = (oldposx -posx);
        tempposy = (oldposy -posy);
        tempposz = (oldposz -posz);
        if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
        {
            return 1;
        }
    }
    return 0;
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
/*	Loop(svidd, MAX_STREAM_VEHICLES)
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
	}*/
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

