package main

import "core:fmt"
import "core:math"

MIN_LATITUDE :: -85.05112878
MAX_LATITUDE :: 85.05112878
MIN_LONGITUDE :: -180.0
MAX_LONGITUDE :: 180.0

LATITUDE_RANGE :: MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE :: MAX_LONGITUDE - MIN_LONGITUDE

Coordinates :: struct {
    latitude: f64,
    longitude: f64,
}

// Compacts spread bits back to a 32-bit integer
compact_int64_to_int32 :: proc(v: u64) -> u32 {
    result := v & 0x5555555555555555
    result = (result | (result >> 1)) & 0x3333333333333333
    result = (result | (result >> 2)) & 0x0F0F0F0F0F0F0F0F
    result = (result | (result >> 4)) & 0x00FF00FF00FF00FF
    result = (result | (result >> 8)) & 0x0000FFFF0000FFFF
    result = (result | (result >> 16)) & 0x00000000FFFFFFFF
    return u32(result)
}

// Converts grid cell numbers back to geographic coordinates
convert_grid_numbers_to_coordinates :: proc(grid_latitude_number: u32, grid_longitude_number: u32) -> Coordinates {
    // Calculate the grid boundaries
    grid_latitude_min := MIN_LATITUDE + LATITUDE_RANGE * (f64(grid_latitude_number) / (1 << 26))
    grid_latitude_max := MIN_LATITUDE + LATITUDE_RANGE * (f64(grid_latitude_number + 1) / (1 << 26))
    grid_longitude_min := MIN_LONGITUDE + LONGITUDE_RANGE * (f64(grid_longitude_number) / (1 << 26))
    grid_longitude_max := MIN_LONGITUDE + LONGITUDE_RANGE * (f64(grid_longitude_number + 1) / (1 << 26))
    
    // Calculate the center point of the grid cell
    latitude := (grid_latitude_min + grid_latitude_max) / 2.0
    longitude := (grid_longitude_min + grid_longitude_max) / 2.0
    
    return Coordinates{latitude, longitude}
}

// Decodes an encoded geohash value back to latitude and longitude coordinates
decode :: proc(geo_code: u64) -> Coordinates {
    // Align bits of both latitude and longitude to take even-numbered position
    y := geo_code >> 1
    x := geo_code
    
    // Compact bits back to 32-bit ints
    grid_latitude_number := compact_int64_to_int32(x)
    grid_longitude_number := compact_int64_to_int32(y)
    
    return convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
}

TestCase :: struct {
    name: string,
    expected_latitude: f64,
    expected_longitude: f64,
    score: u64,
}

main :: proc() {
    test_cases := []TestCase{
        {"Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459},
        {"Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765},
        {"Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493},
        {"Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349},
        {"New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756},
        {"Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204},
        {"London", 51.50740077990134, -0.12779921293258667, 2163557714755072},
        {"New York", 40.712798986951505, -74.00600105524063, 1791873974549446},
        {"Paris", 48.85340071224621, 2.348802387714386, 3663832752681684},
        {"Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352},
        {"Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045},
        {"Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743},
    }

    fmt.println("=== Decode Test Cases ===")
    
    for test_case in test_cases {
        result := decode(test_case.score)
        
        // Check if decoded coordinates are close to original (within 1e-6 precision)
        lat_diff := math.abs(result.latitude - test_case.expected_latitude)
        lon_diff := math.abs(result.longitude - test_case.expected_longitude)
        
        success := lat_diff < 1.0e-6 && lon_diff < 1.0e-6
        status := success ? "✅" : "❌"
        fmt.printf("%s: (lat=%.15f, lon=%.15f) (%s)\n", test_case.name, result.latitude, result.longitude, status)
        
        if !success {
            fmt.printf("  Expected: lat=%.15f, lon=%.15f\n", test_case.expected_latitude, test_case.expected_longitude)
            fmt.printf("  Diff: lat=%.6f, lon=%.6f\n", lat_diff, lon_diff)
        }
    }
}
