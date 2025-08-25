const MIN_LATITUDE: f64 = -85.05112878;
const MAX_LATITUDE: f64 = 85.05112878;
const MIN_LONGITUDE: f64 = -180.0;
const MAX_LONGITUDE: f64 = 180.0;

const LATITUDE_RANGE: f64 = MAX_LATITUDE - MIN_LATITUDE;
const LONGITUDE_RANGE: f64 = MAX_LONGITUDE - MIN_LONGITUDE;

fn spread_int32_to_int64(v: u32) -> u64 {
    let mut result = v as u64;
    result = (result | (result << 16)) & 0x0000FFFF0000FFFF;
    result = (result | (result << 8)) & 0x00FF00FF00FF00FF;
    result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F;
    result = (result | (result << 2)) & 0x3333333333333333;
    (result | (result << 1)) & 0x5555555555555555
}

fn interleave(x: u32, y: u32) -> u64 {
    let x_spread = spread_int32_to_int64(x);
    let y_spread = spread_int32_to_int64(y);
    let y_shifted = y_spread << 1;
    x_spread | y_shifted
}

fn encode(latitude: f64, longitude: f64) -> u64 {
    // Normalize to the range 0-2^26
    let normalized_latitude = 2.0_f64.powi(26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
    let normalized_longitude = 2.0_f64.powi(26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

    // Truncate to integers
    let lat_int = normalized_latitude as u32;
    let lon_int = normalized_longitude as u32;

    interleave(lat_int, lon_int)
}

struct TestCase {
    name: &'static str,
    latitude: f64,
    longitude: f64,
    expected_score: u64,
}

fn main() {
    let test_cases = vec![
        TestCase { name: "Bangkok", latitude: 13.7220, longitude: 100.5252, expected_score: 3962257306574459 },
        TestCase { name: "Beijing", latitude: 39.9075, longitude: 116.3972, expected_score: 4069885364908765 },
        TestCase { name: "Berlin", latitude: 52.5244, longitude: 13.4105, expected_score: 3673983964876493 },
        TestCase { name: "Copenhagen", latitude: 55.6759, longitude: 12.5655, expected_score: 3685973395504349 },
        TestCase { name: "New Delhi", latitude: 28.6667, longitude: 77.2167, expected_score: 3631527070936756 },
        TestCase { name: "Kathmandu", latitude: 27.7017, longitude: 85.3206, expected_score: 3639507404773204 },
        TestCase { name: "London", latitude: 51.5074, longitude: -0.1278, expected_score: 2163557714755072 },
        TestCase { name: "New York", latitude: 40.7128, longitude: -74.0060, expected_score: 1791873974549446 },
        TestCase { name: "Paris", latitude: 48.8534, longitude: 2.3488, expected_score: 3663832752681684 },
        TestCase { name: "Sydney", latitude: -33.8688, longitude: 151.2093, expected_score: 3252046221964352 },
        TestCase { name: "Tokyo", latitude: 35.6895, longitude: 139.6917, expected_score: 4171231230197045 },
        TestCase { name: "Vienna", latitude: 48.2064, longitude: 16.3707, expected_score: 3673109836391743 },
    ];

    for test_case in test_cases {
        let actual_score = encode(test_case.latitude, test_case.longitude);
        let success = actual_score == test_case.expected_score;
        let status = if success { "✅" } else { "❌" };
        println!("{}: {} ({})", test_case.name, actual_score, status);
    }
}
