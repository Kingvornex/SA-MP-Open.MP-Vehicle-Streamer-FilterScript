# Forking and Extending OpenMP Streamer Plugin for Vehicle Streaming

I'll guide you through the process of forking the OpenMP streamer plugin and adding vehicle streaming functionality to it.

## 1. Setting Up the Development Environment

First, you'll need to prepare your development environment:

```bash
# Fork the official OpenMP streamer plugin repository
git clone https://github.com/openmultiplayer/plugin-streamer.git
cd plugin-streamer

# Create a new branch for your vehicle streaming feature
git checkout -b vehicle-streaming
```

## 2. Understanding the Existing Codebase

The streamer plugin likely has these key components:
- Core streaming logic
- Item management system (for objects, pickups, etc.)
- Distance calculation utilities
- Player visibility tracking
- Configuration system

Familiarize yourself with these areas in the codebase.

## 3. Adding Vehicle Streaming Functionality

### A. Define Vehicle Data Structure

In the appropriate header file (e.g., `common.hpp`), add a vehicle structure:

```cpp
struct VehicleData {
    int modelid;
    float x, y, z;
    float rotation;
    int color1, color2;
    int worldid;
    int interiorid;
    float streamDistance;
    int areaId;
    int priority;
    // Add any other vehicle-specific properties you need
};
```

### B. Extend the Streamer Class

Modify the main streamer class to include vehicle handling:

```cpp
class Streamer {
    // ... existing code ...
    
private:
    std::vector<VehicleData> vehicles;
    std::unordered_map<int, int> vehicleHandles; // Maps internal ID to SA-MP vehicle ID
    
    // Add vehicle-specific methods
    void processVehicles();
    bool isVehicleVisibleForPlayer(int playerId, const VehicleData& vehicle);
    void createVehicleForPlayer(int playerId, int vehicleId);
    void destroyVehicleForPlayer(int playerId, int vehicleId);
    
public:
    // Add vehicle-related public methods
    int createVehicle(int modelid, float x, float y, float z, float rotation, 
                     int color1, int color2, int worldid = -1, int interiorid = -1,
                     float streamDistance = 300.0, int areaId = -1, int priority = 0);
    bool destroyVehicle(int vehicleId);
    bool updateVehicleData(int vehicleId, const VehicleData& data);
};
```

### C. Implement Vehicle Streaming Logic

Add the implementation for vehicle streaming in the main streaming function:

```cpp
void Streamer::processVehicles() {
    for (auto& player : players) {
        if (!player.isConnected()) continue;
        
        for (size_t i = 0; i < vehicles.size(); i++) {
            auto& vehicle = vehicles[i];
            
            if (isVehicleVisibleForPlayer(player.getId(), vehicle)) {
                // Check if vehicle is already streamed for player
                if (player.vehicles.find(i) == player.vehicles.end()) {
                    createVehicleForPlayer(player.getId(), i);
                }
            } else {
                // Check if vehicle needs to be destroyed for player
                if (player.vehicles.find(i) != player.vehicles.end()) {
                    destroyVehicleForPlayer(player.getId(), i);
                }
            }
        }
    }
}
```

### D. Add Native Functions

In the plugin's Natives section, add vehicle-related functions:

```cpp
// Create a streamed vehicle
cell AMX_NATIVE_CALL CreateStreamedVehicle(AMX *amx, cell *params) {
    int modelid = params[1];
    float x = amx_ctof(params[2]);
    float y = amx_ctof(params[3]);
    float z = amx_ctof(params[4]);
    float rotation = amx_ctof(params[5]);
    int color1 = params[6];
    int color2 = params[7];
    int worldid = params[8];
    int interiorid = params[9];
    float streamDistance = amx_ctof(params[10]);
    int areaId = params[11];
    int priority = params[12];
    
    return streamer->createVehicle(modelid, x, y, z, rotation, color1, color2, 
                                  worldid, interiorid, streamDistance, areaId, priority);
}

// Destroy a streamed vehicle
cell AMX_NATIVE_CALL DestroyStreamedVehicle(AMX *amx, cell *params) {
    int vehicleid = params[1];
    return streamer->destroyVehicle(vehicleid);
}

// Add more vehicle-related natives as needed
```

### E. Update the Main Processing Loop

Ensure the main streaming loop includes vehicle processing:

```cpp
void Streamer::process() {
    // ... existing processing code ...
    
    // Process vehicle streaming
    processVehicles();
    
    // ... rest of processing code ...
}
```

## 4. Compiling and Testing

### A. Build the Plugin

```bash
mkdir build
cd build
cmake ..
make
```

### B. Create a Test Script

Create a simple PAWN script to test your vehicle streaming:

```pawn
#include <a_samp>
#include <streamer>

main() {
    // Create some test vehicles
    new vehicle1 = CreateStreamedVehicle(411, 0.0, 0.0, 5.0, 0.0, -1, -1, -1, -1, 300.0, -1, 0);
    new vehicle2 = CreateStreamedVehicle(522, 10.0, 10.0, 5.0, 90.0, -1, -1, -1, -1, 300.0, -1, 0);
    
    printf("Created test vehicles: %d, %d", vehicle1, vehicle2);
}

public OnPlayerConnect(playerid) {
    // Player-specific initialization if needed
    return 1;
}
```

## 5. Advanced Optimizations

Consider adding these optimizations for better performance:

### A. Spatial Partitioning

Implement a grid-based or quadtree system to reduce distance checks:

```cpp
class GridSystem {
    struct Cell {
        std::vector<int> vehicleIds;
    };
    
    std::vector<std::vector<Cell>> grid;
    float cellSize;
    
public:
    void addVehicle(int vehicleId, float x, float y);
    void removeVehicle(int vehicleId, float x, float y);
    void getVehiclesInRange(float x, float y, float range, std::vector<int>& result);
};
```

### B. Dynamic Streaming Distance

Adjust streaming distance based on server load:

```cpp
void Streamer::adjustStreamingDistances() {
    float serverLoad = calculateServerLoad();
    float multiplier = 1.0f;
    
    if (serverLoad > 0.8f) {
        multiplier = 0.7f; // Reduce distance by 30% under heavy load
    } else if (serverLoad > 0.6f) {
        multiplier = 0.85f; // Reduce distance by 15% under medium load
    }
    
    // Apply multiplier to all vehicles
    for (auto& vehicle : vehicles) {
        vehicle.effectiveStreamDistance = vehicle.streamDistance * multiplier;
    }
}
```

### C. Priority-Based Streaming

Implement a priority system to ensure important vehicles are streamed first:

```cpp
bool Streamer::isVehicleVisibleForPlayer(int playerId, const VehicleData& vehicle) {
    // First check basic distance and visibility conditions
    if (!checkBasicVisibility(playerId, vehicle)) {
        return false;
    }
    
    // Then check against player's vehicle streaming capacity
    auto& player = players[playerId];
    if (player.vehicles.size() >= MAX_STREAMED_VEHICLES_PER_PLAYER) {
        // If at capacity, only stream if higher priority than existing vehicles
        return hasHigherPriority(playerId, vehicle);
    }
    
    return true;
}
```

## 6. Final Steps

1. Test thoroughly with various scenarios:
   - Many vehicles in a small area
   - Many players with different vehicles
   - Edge cases (vehicle creation/destruction during streaming)
   - Performance under load

2. Document your new vehicle streaming functions and their parameters

3. Submit a pull request to the original repository if you want to contribute your changes

This approach should give you a much more efficient vehicle streaming system than the original filterscript, as it's integrated directly into the optimized streamer plugin.
