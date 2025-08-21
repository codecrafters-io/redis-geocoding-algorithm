MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180
MAX_LONGITUDE = 180

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

def decode(geo_code: int) -> (float, float):
    """
    decode converts geo code(WGS84) to tuple of (latitude, longitude)
    """
    # Align bits of both latitude and longitude to take even-numbered position
    y = geo_code >> 1
    x = geo_code
    
    # Compact bits back to 32-bit ints
    grid_latitude_number = compact_int64_to_int32(x)
    grid_longitude_number = compact_int64_to_int32(y)
    
    # Calculate the grid boundaries
    grid_latitude_min = MIN_LATITUDE + LATITUDE_RANGE * (grid_latitude_number / (1 << 26))
    grid_latitude_max = MIN_LATITUDE + LATITUDE_RANGE * ((grid_latitude_number + 1) / (1 << 26))
    grid_longitude_min = MIN_LONGITUDE + LONGITUDE_RANGE * (grid_longitude_number / (1 << 26))
    grid_longitude_max = MIN_LONGITUDE + LONGITUDE_RANGE * ((grid_longitude_number + 1) / (1 << 26))
    
    # Calculate the center point of the grid cell
    latitude = (grid_latitude_min + grid_latitude_max) / 2
    longitude = (grid_longitude_min + grid_longitude_max) / 2
    
    return (latitude, longitude)


def compact_int64_to_int32(v: int) -> int:
    """
    Compact a 64-bit integer with interleaved bits back to a 32-bit integer.
    This is the reverse operation of spread_int32_to_int64.
    """
    v = v & 0x5555555555555555
    v = (v | (v >> 1)) & 0x3333333333333333
    v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0F
    v = (v | (v >> 4)) & 0x00FF00FF00FF00FF
    v = (v | (v >> 8)) & 0x0000FFFF0000FFFF
    v = (v | (v >> 16)) & 0x00000000FFFFFFFF
    return v


if __name__ == "__main__":
    # Test cases from encode.py to verify round-trip encoding/decoding
    test_cases = [
        {"name": "Bangkok", "latitude": 13.722000686932997, "longitude": 100.52520006895065, "score": 3962257306574459},
        {"name": "Beijing", "latitude": 39.9075003315814, "longitude": 116.39719873666763, "score": 4069885364908765},
        {"name": "Berlin", "latitude": 52.52439934649943, "longitude": 13.410500586032867, "score": 3673983964876493},
        {"name": "Copenhagen", "latitude": 55.67589927498264, "longitude": 12.56549745798111, "score": 3685973395504349},
        {"name": "New Delhi", "latitude": 28.666698899347338, "longitude": 77.21670180559158, "score": 3631527070936756},
        {"name": "Kathmandu", "latitude": 27.701700137333084, "longitude": 85.3205993771553, "score": 3639507404773204},
        {"name": "London", "latitude": 51.50740077990134, "longitude": -0.12779921293258667, "score": 2163557714755072},
        {"name": "New York", "latitude": 40.712798986951505, "longitude": -74.00600105524063, "score": 1791873974549446},
        {"name": "Paris", "latitude": 48.85340071224621, "longitude": 2.348802387714386, "score": 3663832752681684},
        {"name": "Sydney", "latitude": -33.86880091934156, "longitude": 151.2092998623848, "score": 3252046221964352},
        {"name": "Tokyo", "latitude": 35.68950126697936, "longitude": 139.691701233387, "score": 4171231230197045},
        {"name": "Vienna", "latitude": 48.20640046271915, "longitude": 16.370699107646942, "score": 3673109836391743},
    ]
    
    for test_case in test_cases:
        geo_code = test_case["score"]
        
        (decoded_latitude, decoded_longitude) = decode(geo_code)
        
        # Check if decoded coordinates are close to original (within 10e-6 precision)
        lat_diff = abs(decoded_latitude - test_case["latitude"])
        lon_diff = abs(decoded_longitude - test_case["longitude"])
        
        success = lat_diff < 10e-6 and lon_diff < 10e-6
        print(f"{test_case['name']}: (lat={decoded_latitude},lon={decoded_longitude}) {"✅" if (success) else "❌"}")
        if not success:
            print(f"  Expected: lat={test_case.latitude}, lon={test_case.longitude}")
            print(f"  Diff: lat={lat_diff:.6f}, lon={lon_diff:.6f}")
