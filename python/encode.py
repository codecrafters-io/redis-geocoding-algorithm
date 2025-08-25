MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180
MAX_LONGITUDE = 180

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE


def encode(latitude: float, longitude: float) -> int:
    # Normalize to the range 0-2^26
    normalized_latitude = 2**26 * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
    normalized_longitude = 2**26 * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

    # Truncate to integers
    normalized_latitude = int(normalized_latitude)
    normalized_longitude = int(normalized_longitude)

    return interleave(normalized_latitude, normalized_longitude)


def interleave(x: int, y: int) -> int:
    x = spread_int32_to_int64(x)
    y = spread_int32_to_int64(y)

    y_shifted = y << 1
    return x | y_shifted


def spread_int32_to_int64(v: int) -> int:
    v = v & 0xFFFFFFFF

    v = (v | (v << 16)) & 0x0000FFFF0000FFFF
    v = (v | (v << 8)) & 0x00FF00FF00FF00FF
    v = (v | (v << 4)) & 0x0F0F0F0F0F0F0F0F
    v = (v | (v << 2)) & 0x3333333333333333
    v = (v | (v << 1)) & 0x5555555555555555

    return v


if __name__ == "__main__":
    test_cases = [
        {"name": "Bangkok", "latitude": 13.7220, "longitude": 100.5252, "score": 3962257306574459.0},
        {"name": "Beijing", "latitude": 39.9075, "longitude": 116.3972, "score": 4069885364908765.0},
        {"name": "Berlin", "latitude": 52.5244, "longitude": 13.4105, "score": 3673983964876493.0},
        {"name": "Copenhagen", "latitude": 55.6759, "longitude": 12.5655, "score": 3685973395504349.0},
        {"name": "New Delhi", "latitude": 28.6667, "longitude": 77.2167, "score": 3631527070936756.0},
        {"name": "Kathmandu", "latitude": 27.7017, "longitude": 85.3206, "score": 3639507404773204.0},
        {"name": "London", "latitude": 51.5074, "longitude": -0.1278, "score":  2163557714755072.0},
        {"name": "New York", "latitude": 40.7128, "longitude": -74.0060, "score": 1791873974549446.0},
        {"name": "Paris", "latitude": 48.8534, "longitude": 2.3488, "score": 3663832752681684.0},
        {"name": "Sydney", "latitude": -33.8688, "longitude": 151.2093, "score": 3252046221964352.0},
        {"name": "Tokyo", "latitude": 35.6895, "longitude": 139.6917, "score": 4171231230197045.0},
        {"name": "Vienna", "latitude": 48.2064, "longitude": 16.3707, "score": 3673109836391743.0},
    ]

    for test_case in test_cases:
        expected_score = test_case["score"]
        actual_score = encode(test_case["latitude"], test_case["longitude"])
        print(f"{test_case['name']}: {actual_score} ({"✅" if actual_score == expected_score else "❌"})")
