#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define MIN_LATITUDE -85.05112878
#define MAX_LATITUDE 85.05112878
#define MIN_LONGITUDE -180.0
#define MAX_LONGITUDE 180.0

#define LATITUDE_RANGE (MAX_LATITUDE - MIN_LATITUDE)
#define LONGITUDE_RANGE (MAX_LONGITUDE - MIN_LONGITUDE)

uint64_t spread_int32_to_int64(uint32_t v) {
    uint64_t result = v;
    result = (result | (result << 16)) & 0x0000FFFF0000FFFFULL;
    result = (result | (result << 8)) & 0x00FF00FF00FF00FFULL;
    result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0FULL;
    result = (result | (result << 2)) & 0x3333333333333333ULL;
    result = (result | (result << 1)) & 0x5555555555555555ULL;
    return result;
}

uint64_t interleave(uint32_t x, uint32_t y) {
    uint64_t x_spread = spread_int32_to_int64(x);
    uint64_t y_spread = spread_int32_to_int64(y);
    uint64_t y_shifted = y_spread << 1;
    return x_spread | y_shifted;
}

uint64_t encode(double latitude, double longitude) {
    // Normalize to the range 0-2^26
    double normalized_latitude = pow(2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
    double normalized_longitude = pow(2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

    // Truncate to integers
    uint32_t lat_int = (uint32_t)normalized_latitude;
    uint32_t lon_int = (uint32_t)normalized_longitude;

    return interleave(lat_int, lon_int);
}

int main() {
    struct test_case {
        const char* name;
        double latitude;
        double longitude;
        uint64_t expected_score;
    };

    struct test_case test_cases[] = {
        {"Bangkok", 13.7220, 100.5252, 3962257306574459ULL},
        {"Beijing", 39.9075, 116.3972, 4069885364908765ULL},
        {"Berlin", 52.5244, 13.4105, 3673983964876493ULL},
        {"Copenhagen", 55.6759, 12.5655, 3685973395504349ULL},
        {"New Delhi", 28.6667, 77.2167, 3631527070936756ULL},
        {"Kathmandu", 27.7017, 85.3206, 3639507404773204ULL},
        {"London", 51.5074, -0.1278, 2163557714755072ULL},
        {"New York", 40.7128, -74.0060, 1791873974549446ULL},
        {"Paris", 48.8534, 2.3488, 3663832752681684ULL},
        {"Sydney", -33.8688, 151.2093, 3252046221964352ULL},
        {"Tokyo", 35.6895, 139.6917, 4171231230197045ULL},
        {"Vienna", 48.2064, 16.3707, 3673109836391743ULL}
    };

    int num_tests = sizeof(test_cases) / sizeof(test_cases[0]);
    
    for (int i = 0; i < num_tests; i++) {
        uint64_t actual_score = encode(test_cases[i].latitude, test_cases[i].longitude);
        int success = (actual_score == test_cases[i].expected_score);
        printf("%s: %llu (%s)\n", test_cases[i].name, actual_score, success ? "✅" : "❌");
    }

    return 0;
}
