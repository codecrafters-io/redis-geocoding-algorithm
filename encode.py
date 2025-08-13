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
        {"name": "London", "latitude": 51.5074, "longitude": -0.1278, "score": 1234567890},
        {"name": "New York", "latitude": 40.7128, "longitude": -74.0060, "score": 1234567890},
        {"name": "Tokyo", "latitude": 35.6895, "longitude": 139.6917, "score": 1234567890},
        {"name": "Sydney", "latitude": -33.8688, "longitude": 151.2093, "score": 1234567890},
    ]

    for test_case in test_cases:
        expected_score = test_case["score"]
        actual_score = encode(test_case["latitude"], test_case["longitude"])
        print(f"{test_case['name']}: {actual_score} ({"✅" if actual_score == expected_score else "❌"})")
