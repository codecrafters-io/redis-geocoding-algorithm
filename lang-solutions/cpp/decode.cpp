#include <iostream>
#include <cstdint>
#include <cmath>
#include <vector>
#include <string>

constexpr double MIN_LATITUDE = -85.05112878;
constexpr double MAX_LATITUDE = 85.05112878;
constexpr double MIN_LONGITUDE = -180.0;
constexpr double MAX_LONGITUDE = 180.0;

constexpr double LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
constexpr double LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

struct Coordinates {
    double latitude;
    double longitude;
};

uint32_t compact_int64_to_int32(uint64_t v) {
    v = v & 0x5555555555555555ULL;
    v = (v | (v >> 1)) & 0x3333333333333333ULL;
    v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0FULL;
    v = (v | (v >> 4)) & 0x00FF00FF00FF00FFULL;
    v = (v | (v >> 8)) & 0x0000FFFF0000FFFFULL;
    v = (v | (v >> 16)) & 0x00000000FFFFFFFFULL;
    return static_cast<uint32_t>(v);
}

Coordinates convert_grid_numbers_to_coordinates(uint32_t grid_latitude_number, uint32_t grid_longitude_number) {
    // Calculate the grid boundaries
    double grid_latitude_min = MIN_LATITUDE + LATITUDE_RANGE * (grid_latitude_number / pow(2, 26));
    double grid_latitude_max = MIN_LATITUDE + LATITUDE_RANGE * ((grid_latitude_number + 1) / pow(2, 26));
    double grid_longitude_min = MIN_LONGITUDE + LONGITUDE_RANGE * (grid_longitude_number / pow(2, 26));
    double grid_longitude_max = MIN_LONGITUDE + LONGITUDE_RANGE * ((grid_longitude_number + 1) / pow(2, 26));
    
    // Calculate the center point of the grid cell
    Coordinates result;
    result.latitude = (grid_latitude_min + grid_latitude_max) / 2;
    result.longitude = (grid_longitude_min + grid_longitude_max) / 2;
    
    return result;
}

Coordinates decode(uint64_t geo_code) {
    // Align bits of both latitude and longitude to take even-numbered position
    uint64_t y = geo_code >> 1;
    uint64_t x = geo_code;
    
    // Compact bits back to 32-bit ints
    uint32_t grid_latitude_number = compact_int64_to_int32(x);
    uint32_t grid_longitude_number = compact_int64_to_int32(y);
    
    return convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number);
}

struct TestCase {
    std::string name;
    double expected_latitude;
    double expected_longitude;
    uint64_t score;
};

int main() {
    std::vector<TestCase> test_cases = {
        {"Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459ULL},
        {"Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765ULL},
        {"Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493ULL},
        {"Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349ULL},
        {"New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756ULL},
        {"Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204ULL},
        {"London", 51.50740077990134, -0.12779921293258667, 2163557714755072ULL},
        {"New York", 40.712798986951505, -74.00600105524063, 1791873974549446ULL},
        {"Paris", 48.85340071224621, 2.348802387714386, 3663832752681684ULL},
        {"Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352ULL},
        {"Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045ULL},
        {"Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743ULL}
    };
    
    for (const auto& test_case : test_cases) {
        Coordinates result = decode(test_case.score);
        
        // Check if decoded coordinates are close to original (within 10e-6 precision)
        double lat_diff = std::abs(result.latitude - test_case.expected_latitude);
        double lon_diff = std::abs(result.longitude - test_case.expected_longitude);
        
        bool success = (lat_diff < 1e-6 && lon_diff < 1e-6);
        std::cout << test_case.name << ": (lat=" << result.latitude << ", lon=" << result.longitude << ") (" << (success ? "✅" : "❌") << ")" << std::endl;
        
        if (!success) {
            std::cout << "  Expected: lat=" << test_case.expected_latitude << ", lon=" << test_case.expected_longitude << std::endl;
            std::cout << "  Diff: lat=" << lat_diff << ", lon=" << lon_diff << std::endl;
        }
    }

    return 0;
}
