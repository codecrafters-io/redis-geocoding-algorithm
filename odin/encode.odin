package main

import "core:fmt"
import "core:math"

MIN_LATITUDE :: -85.05112878
MAX_LATITUDE :: 85.05112878
MIN_LONGITUDE :: -180.0
MAX_LONGITUDE :: 180.0

LATITUDE_RANGE :: MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE :: MAX_LONGITUDE - MIN_LONGITUDE

// Spreads bits of a 32-bit integer to occupy even positions in a 64-bit integer
spread_int32_to_int64 :: proc(v: u32) -> u64 {
    result := u64(v) & 0xFFFFFFFF
    result = (result | (result << 16)) & 0x0000FFFF0000FFFF
    result = (result | (result << 8)) & 0x00FF00FF00FF00FF
    result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F
    result = (result | (result << 2)) & 0x3333333333333333
    result = (result | (result << 1)) & 0x5555555555555555
    return result
}

// Interleaves bits of two 32-bit integers to create a single 64-bit Morton code
interleave :: proc(x: u32, y: u32) -> u64 {
    x_spread := spread_int32_to_int64(x)
    y_spread := spread_int32_to_int64(y)
    y_shifted := y_spread << 1
    return x_spread | y_shifted
}

// Encodes latitude and longitude coordinates into a single integer using Morton encoding
encode :: proc(latitude: f64, longitude: f64) -> u64 {
    // Normalize to the range 0-2^26
    normalized_latitude := (1 << 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
    normalized_longitude := (1 << 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

    // Truncate to integers
    lat_int := u32(normalized_latitude)
    lon_int := u32(normalized_longitude)

    return interleave(lat_int, lon_int)
}

TestCase :: struct {
    name: string,
    latitude: f64,
    longitude: f64,
    expected_score: u64,
}

main :: proc() {
    test_cases := []TestCase{
        {"Bangkok", 13.7220, 100.5252, 3962257306574459},
        {"Beijing", 39.9075, 116.3972, 4069885364908765},
        {"Berlin", 52.5244, 13.4105, 3673983964876493},
        {"Copenhagen", 55.6759, 12.5655, 3685973395504349},
        {"New Delhi", 28.6667, 77.2167, 3631527070936756},
        {"Kathmandu", 27.7017, 85.3206, 3639507404773204},
        {"London", 51.5074, -0.1278, 2163557714755072},
        {"New York", 40.7128, -74.0060, 1791873974549446},
        {"Paris", 48.8534, 2.3488, 3663832752681684},
        {"Sydney", -33.8688, 151.2093, 3252046221964352},
        {"Tokyo", 35.6895, 139.6917, 4171231230197045},
        {"Vienna", 48.2064, 16.3707, 3673109836391743},
    }

    fmt.println("=== Encode Test Cases ===")
    
    for test_case in test_cases {
        actual_score := encode(test_case.latitude, test_case.longitude)
        success := actual_score == test_case.expected_score
        status := success ? "✅" : "❌"
        fmt.printf("%s: %d (%s)\n", test_case.name, actual_score, status)
    }
}
