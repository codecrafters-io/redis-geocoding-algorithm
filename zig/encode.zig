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

fn spreadInt32ToInt64(v: u32) u64 {
    var result: u64 = @intCast(v & 0xFFFFFFFF);
    result = (result | (result << 16)) & 0x0000FFFF0000FFFF;
    result = (result | (result << 8)) & 0x00FF00FF00FF00FF;
    result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F;
    result = (result | (result << 2)) & 0x3333333333333333;
    result = (result | (result << 1)) & 0x5555555555555555;
    return result;
}

fn interleave(x: u32, y: u32) u64 {
    const spread_x = spreadInt32ToInt64(x);
    const spread_y = spreadInt32ToInt64(y);
    const y_shifted = spread_y << 1;
    return spread_x | y_shifted;
}

pub fn encode(latitude: f64, longitude: f64) u64 {
    // Normalize to the range 0-2^26
    const normalized_latitude = math.pow(f64, 2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
    const normalized_longitude = math.pow(f64, 2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;
    
    // Truncate to integers
    const normalized_latitude_int: u32 = @intFromFloat(normalized_latitude);
    const normalized_longitude_int: u32 = @intFromFloat(normalized_longitude);
    
    return interleave(normalized_latitude_int, normalized_longitude_int);
}

pub fn main() void {
    const test_cases = [_]TestCase{
        .{ .name = "Bangkok", .latitude = 13.7220, .longitude = 100.5252, .score = 3962257306574459 },
        .{ .name = "Beijing", .latitude = 39.9075, .longitude = 116.3972, .score = 4069885364908765 },
        .{ .name = "Berlin", .latitude = 52.5244, .longitude = 13.4105, .score = 3673983964876493 },
        .{ .name = "Copenhagen", .latitude = 55.6759, .longitude = 12.5655, .score = 3685973395504349 },
        .{ .name = "New Delhi", .latitude = 28.6667, .longitude = 77.2167, .score = 3631527070936756 },
        .{ .name = "Kathmandu", .latitude = 27.7017, .longitude = 85.3206, .score = 3639507404773204 },
        .{ .name = "London", .latitude = 51.5074, .longitude = -0.1278, .score = 2163557714755072 },
        .{ .name = "New York", .latitude = 40.7128, .longitude = -74.0060, .score = 1791873974549446 },
        .{ .name = "Paris", .latitude = 48.8534, .longitude = 2.3488, .score = 3663832752681684 },
        .{ .name = "Sydney", .latitude = -33.8688, .longitude = 151.2093, .score = 3252046221964352 },
        .{ .name = "Tokyo", .latitude = 35.6895, .longitude = 139.6917, .score = 4171231230197045 },
        .{ .name = "Vienna", .latitude = 48.2064, .longitude = 16.3707, .score = 3673109836391743 },
    };
    
    for (test_cases) |test_case| {
        const expected_score = test_case.score;
        const actual_score = encode(test_case.latitude, test_case.longitude);
        const success = actual_score == expected_score;
        const result = if (success) "✅" else "❌";
        print("{s}: {d} ({s})\n", .{ test_case.name, actual_score, result });
    }
}