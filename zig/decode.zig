const std = @import("std");
const print = std.debug.print;
const math = std.math;

const MIN_LATITUDE: f64 = -85.05112878;
const MAX_LATITUDE: f64 = 85.05112878;
const MIN_LONGITUDE: f64 = -180;
const MAX_LONGITUDE: f64 = 180;
const LATITUDE_RANGE: f64 = MAX_LATITUDE - MIN_LATITUDE;
const LONGITUDE_RANGE: f64 = MAX_LONGITUDE - MIN_LONGITUDE;

const TestCase = struct {
    name: []const u8,
    latitude: f64,
    longitude: f64,
    score: u64,
};

const Coordinates = struct {
    latitude: f64,
    longitude: f64,
};

fn compactInt64ToInt32(v: u64) u32 {
    var result = v & 0x5555555555555555;
    result = (result | (result >> 1)) & 0x3333333333333333;
    result = (result | (result >> 2)) & 0x0F0F0F0F0F0F0F0F;
    result = (result | (result >> 4)) & 0x00FF00FF00FF00FF;
    result = (result | (result >> 8)) & 0x0000FFFF0000FFFF;
    result = (result | (result >> 16)) & 0x00000000FFFFFFFF;
    return @intCast(result);
}

fn convertGridNumbersToCoordinates(grid_latitude_number: u32, grid_longitude_number: u32) Coordinates {
    // Calculate the grid boundaries
    const grid_latitude_number_f64: f64 = @floatFromInt(grid_latitude_number);
    const grid_longitude_number_f64: f64 = @floatFromInt(grid_longitude_number);
    const power_26 = math.pow(f64, 2, 26);
    
    const grid_latitude_min = MIN_LATITUDE + LATITUDE_RANGE * (grid_latitude_number_f64 / power_26);
    const grid_latitude_max = MIN_LATITUDE + LATITUDE_RANGE * ((grid_latitude_number_f64 + 1) / power_26);
    const grid_longitude_min = MIN_LONGITUDE + LONGITUDE_RANGE * (grid_longitude_number_f64 / power_26);
    const grid_longitude_max = MIN_LONGITUDE + LONGITUDE_RANGE * ((grid_longitude_number_f64 + 1) / power_26);
    
    // Calculate the center point of the grid cell
    const latitude = (grid_latitude_min + grid_latitude_max) / 2;
    const longitude = (grid_longitude_min + grid_longitude_max) / 2;
    
    return Coordinates{
        .latitude = latitude,
        .longitude = longitude,
    };
}

/// Decode converts geo code (WGS84) to coordinates (latitude, longitude)
pub fn decode(geo_code: u64) Coordinates {
    // Align bits of both latitude and longitude to take even-numbered position
    const y = geo_code >> 1;
    const x = geo_code;
    
    // Compact bits back to 32-bit ints
    const grid_latitude_number = compactInt64ToInt32(x);
    const grid_longitude_number = compactInt64ToInt32(y);
    
    return convertGridNumbersToCoordinates(grid_latitude_number, grid_longitude_number);
}

pub fn main() void {
    // Test cases from encode.zig to verify decoding
    // The latitude and longitude in test cases are the actual responses from redis server
    const test_cases = [_]TestCase{
        .{ .name = "Bangkok", .latitude = 13.722000686932997, .longitude = 100.52520006895065, .score = 3962257306574459 },
        .{ .name = "Beijing", .latitude = 39.9075003315814, .longitude = 116.39719873666763, .score = 4069885364908765 },
        .{ .name = "Berlin", .latitude = 52.52439934649943, .longitude = 13.410500586032867, .score = 3673983964876493 },
        .{ .name = "Copenhagen", .latitude = 55.67589927498264, .longitude = 12.56549745798111, .score = 3685973395504349 },
        .{ .name = "New Delhi", .latitude = 28.666698899347338, .longitude = 77.21670180559158, .score = 3631527070936756 },
        .{ .name = "Kathmandu", .latitude = 27.701700137333084, .longitude = 85.3205993771553, .score = 3639507404773204 },
        .{ .name = "London", .latitude = 51.50740077990134, .longitude = -0.12779921293258667, .score = 2163557714755072 },
        .{ .name = "New York", .latitude = 40.712798986951505, .longitude = -74.00600105524063, .score = 1791873974549446 },
        .{ .name = "Paris", .latitude = 48.85340071224621, .longitude = 2.348802387714386, .score = 3663832752681684 },
        .{ .name = "Sydney", .latitude = -33.86880091934156, .longitude = 151.2092998623848, .score = 3252046221964352 },
        .{ .name = "Tokyo", .latitude = 35.68950126697936, .longitude = 139.691701233387, .score = 4171231230197045 },
        .{ .name = "Vienna", .latitude = 48.20640046271915, .longitude = 16.370699107646942, .score = 3673109836391743 },
    };
    
    for (test_cases) |test_case| {
        const geo_code = test_case.score;
        const decoded = decode(geo_code);
        
        // Check if decoded coordinates are close to original (within 10e-6 precision)
        const lat_diff = @abs(decoded.latitude - test_case.latitude);
        const lon_diff = @abs(decoded.longitude - test_case.longitude);
        
        const success = lat_diff < 1e-6 and lon_diff < 1e-6;
        const result = if (success) "✅" else "❌";
        
        print("{s}: (lat={d:.12},lon={d:.12}) {s}\n", .{ test_case.name, decoded.latitude, decoded.longitude, result });
        
        if (!success) {
            print("  Expected: lat={d:.12}, lon={d:.12}\n", .{ test_case.latitude, test_case.longitude });
            print("  Actual: lat={d:.12}, lon={d:.12}\n", .{ decoded.latitude, decoded.longitude });
            print("  Diff: lat={d:.6}, lon={d:.6}\n", .{ lat_diff, lon_diff });
        }
    }
}