# Creating a Staggered Vehicle Creation Timer for FilterScript

To prevent lag when creating multiple vehicles at once, I'll create a timer system that creates vehicles with a one-second delay between each creation. This approach will distribute the load on the server and prevent performance issues.

## Implementation Solution

```pawn
#include <a_samp>

// Maximum number of vehicles to create
#define MAX_VEHICLES_TO_CREATE 100

// Vehicle data structure
enum E_VEHICLE_DATA {
    modelid,
    Float:x,
    Float:y,
    Float:z,
    Float:rotation,
    color1,
    color2,
    worldid,
    interiorid
}

// Array to store vehicles waiting to be created
new VehicleData[MAX_VEHICLES_TO_CREATE][E_VEHICLE_DATA];
new TotalVehiclesToCreate = 0;
new CurrentVehicleIndex = 0;
new VehicleCreationTimer;

// Initialize the filter script
public OnFilterScriptInit() {
    // Add vehicles to the creation queue
    AddVehicleToQueue(411, 0.0, 0.0, 5.0, 0.0, 6, 1, -1, -1); // Infernus
    AddVehicleToQueue(522, 5.0, 5.0, 5.0, 90.0, 3, 8, -1, -1); // NRG-500
    AddVehicleToQueue(415, 10.0, 0.0, 5.0, 180.0, 25, 1, -1, -1); // Cheetah
    // Add more vehicles as needed
    
    // Start the vehicle creation timer
    if (TotalVehiclesToCreate > 0) {
        VehicleCreationTimer = SetTimer("CreateNextVehicle", 1000, true);
        printf("Vehicle creation timer started. %d vehicles to create.", TotalVehiclesToCreate);
    }
    
    return 1;
}

// Clean up when filter script exits
public OnFilterScriptExit() {
    if (VehicleCreationTimer) {
        KillTimer(VehicleCreationTimer);
    }
    return 1;
}

// Function to add a vehicle to the creation queue
stock AddVehicleToQueue(modelid, Float:x, Float:y, Float:z, Float:rotation, color1, color2, worldid = -1, interiorid = -1) {
    if (TotalVehiclesToCreate >= MAX_VEHICLES_TO_CREATE) {
        printf("Error: Maximum vehicles to create reached. Cannot add more.");
        return 0;
    }
    
    VehicleData[TotalVehiclesToCreate][modelid] = modelid;
    VehicleData[TotalVehiclesToCreate][x] = x;
    VehicleData[TotalVehiclesToCreate][y] = y;
    VehicleData[TotalVehiclesToCreate][z] = z;
    VehicleData[TotalVehiclesToCreate][rotation] = rotation;
    VehicleData[TotalVehiclesToCreate][color1] = color1;
    VehicleData[TotalVehiclesToCreate][color2] = color2;
    VehicleData[TotalVehiclesToCreate][worldid] = worldid;
    VehicleData[TotalVehiclesToCreate][interiorid] = interiorid;
    
    TotalVehiclesToCreate++;
    return 1;
}

// Timer function to create vehicles one by one
forward CreateNextVehicle();
public CreateNextVehicle() {
    // Check if we've created all vehicles
    if (CurrentVehicleIndex >= TotalVehiclesToCreate) {
        KillTimer(VehicleCreationTimer);
        VehicleCreationTimer = 0;
        printf("All vehicles created successfully.");
        return 1;
    }
    
    // Get vehicle data
    new modelid = VehicleData[CurrentVehicleIndex][modelid];
    new Float:x = VehicleData[CurrentVehicleIndex][x];
    new Float:y = VehicleData[CurrentVehicleIndex][y];
    new Float:z = VehicleData[CurrentVehicleIndex][z];
    new Float:rotation = VehicleData[CurrentVehicleIndex][rotation];
    new color1 = VehicleData[CurrentVehicleIndex][color1];
    new color2 = VehicleData[CurrentVehicleIndex][color2];
    new worldid = VehicleData[CurrentVehicleIndex][worldid];
    new interiorid = VehicleData[CurrentVehicleIndex][interiorid];
    
    // Create the vehicle
    new vehicleid = CreateVehicle(modelid, x, y, z, rotation, color1, color2, -1);
    
    // Set vehicle world and interior if specified
    if (worldid != -1) {
        SetVehicleVirtualWorld(vehicleid, worldid);
    }
    if (interiorid != -1) {
        LinkVehicleToInterior(vehicleid, interiorid);
    }
    
    printf("Created vehicle %d (Model: %d) at position (%.2f, %.2f, %.2f)", 
           vehicleid, modelid, x, y, z);
    
    // Move to the next vehicle
    CurrentVehicleIndex++;
    
    return 1;
}
```

## How This Solution Works

1. **Vehicle Queue System**: 
   - We maintain an array `VehicleData` that stores all vehicles waiting to be created
   - Each vehicle entry includes model ID, position, rotation, colors, world ID, and interior ID

2. **Staggered Creation**:
   - The timer runs every second (1000ms) and creates just one vehicle
   - After creating a vehicle, it increments the index to prepare for the next one
   - This prevents the server from creating all vehicles simultaneously

3. **Automatic Cleanup**:
   - Once all vehicles are created, the timer automatically stops itself
   - The timer is also properly killed when the filter script unloads

4. **Flexible Configuration**:
   - You can easily add more vehicles using the `AddVehicleToQueue` function
   - The system supports different virtual worlds and interiors for vehicles

## Usage Instructions

1. Add this code to your filter script
2. Use `AddVehicleToQueue()` to add vehicles you want to create
3. The system will automatically start creating vehicles one per second when the filter script loads

## Benefits of This Approach

1. **Reduced Server Load**: By spreading vehicle creation over time, you prevent sudden spikes in resource usage
2. **Improved Stability**: Avoids the lag that occurs when many vehicles are created simultaneously
3. **Better Player Experience**: Players won't experience freezes or stuttering during vehicle creation
4. **Scalability**: Works well even with large numbers of vehicles

You can adjust the timer interval (currently 1000ms) to make the creation faster or slower depending on your server's performance capabilities.
