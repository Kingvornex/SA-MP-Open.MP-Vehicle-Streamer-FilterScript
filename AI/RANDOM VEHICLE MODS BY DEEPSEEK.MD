Here's an implementation of an open.mp include file that adds random modifications to vehicles:

```pawn
// random_vehicle_mods.inc
// Adds random modifications to vehicles using open.mp component functions

#if defined _random_vehicle_mods_included
    #endinput
#endif
#define _random_vehicle_mods_included

#include <openmp>

/**
 * <summary>Applies random modifications to a vehicle.</summary>
 * <param name="vehicleid">The ID of the vehicle to modify</param>
 * <returns>
 *  1 on success, 0 on failure
 * </returns>
 */
stock ApplyRandomVehicleMods(vehicleid) {
    if(!IsValidVehicle(vehicleid))
        return 0;

    new modelid = GetVehicleModel(vehicleid);
    
    // Validate vehicle model range (400-611)
    if(modelid < 400 || modelid > 611)
        return 0;

    // Iterate through all 14 modification slots
    for(new slot = 0; slot < 14; slot++) {
        // Get number of available components for this slot
        new component_count = GetVehicleModelComponentSlots(modelid, slot);
        
        if(component_count > 0) {
            // Select random component from available options
            new random_index = random(component_count);
            new componentid = GetVehicleModelComponent(modelid, slot, random_index);
            
            // Apply the component to the vehicle
            AddVehicleComponent(vehicleid, componentid);
        }
    }
    
    return 1;
}

// Optional auto-apply functionality when vehicles spawn
#if defined RANDOM_VEHICLE_MODS_AUTO_APPLY

forward RVMS_OnVehicleSpawn(vehicleid);

public OnVehicleSpawn(vehicleid) {
    ApplyRandomVehicleMods(vehicleid);
    #if defined RVMS_OnVehicleSpawn
        return RVMS_OnVehicleSpawn(vehicleid);
    #else
        return 1;
    #endif
}

// ALS hook setup
#if defined _ALS_OnVehicleSpawn
    #undef OnVehicleSpawn
#else
    #define _ALS_OnVehicleSpawn
#endif
#define OnVehicleSpawn RVMS_OnVehicleSpawn

#endif // RANDOM_VEHICLE_MODS_AUTO_APPLY
```

**Usage:**

1. Basic usage:
```pawn
#include <random_vehicle_mods>

public OnGameModeInit() {
    CreateVehicle(411, 0.0, 0.0, 5.0, 0.0, -1, -1, 3600); // Create an Infernus
    return 1;
}

public OnVehicleSpawn(vehicleid) {
    ApplyRandomVehicleMods(vehicleid); // Manually apply mods
    return 1;
}
```

2. Auto-apply on spawn:
```pawn
#define RANDOM_VEHICLE_MODS_AUTO_APPLY
#include <random_vehicle_mods>

public OnGameModeInit() {
    CreateVehicle(411, 0.0, 0.0, 5.0, 0.0, -1, -1, 3600); // Infernus will get random mods when spawned
    return 1;
}
```

**Features:**
- Automatically detects valid components for each vehicle model
- Applies one random component per modification slot
- Handles all 14 modification slots (including nitro and hydraulics)
- Optional auto-apply functionality via preprocessor definition
- Proper ALS hooking for compatibility with other scripts

**Notes:**
- The script uses open.mp's native component functions for maximum compatibility
- Will only apply components that are valid for the specific vehicle model
- Auto-apply functionality is disabled by default (enable with `#define RANDOM_VEHICLE_MODS_AUTO_APPLY`)
- Components are selected completely randomly from available options for each slot

This implementation efficiently uses open.mp's built-in vehicle component system to ensure compatibility and proper functionality across all vehicle models.