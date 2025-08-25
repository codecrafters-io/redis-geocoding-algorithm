MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

def spread_int32_to_int64(v)
  result = v & 0xFFFFFFFF
  result = (result | (result << 16)) & 0x0000FFFF0000FFFF
  result = (result | (result << 8)) & 0x00FF00FF00FF00FF
  result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F
  result = (result | (result << 2)) & 0x3333333333333333
  (result | (result << 1)) & 0x5555555555555555
end

def interleave(x, y)
  x_spread = spread_int32_to_int64(x)
  y_spread = spread_int32_to_int64(y)
  y_shifted = y_spread << 1
  x_spread | y_shifted
end

def encode(latitude, longitude)
  # Normalize to the range 0-2^26
  normalized_latitude = (2 ** 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
  normalized_longitude = (2 ** 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

  # Truncate to integers
  lat_int = normalized_latitude.to_i
  lon_int = normalized_longitude.to_i

  interleave(lat_int, lon_int)
end

test_cases = [
  { name: "Bangkok", latitude: 13.7220, longitude: 100.5252, expected_score: 3962257306574459 },
  { name: "Beijing", latitude: 39.9075, longitude: 116.3972, expected_score: 4069885364908765 },
  { name: "Berlin", latitude: 52.5244, longitude: 13.4105, expected_score: 3673983964876493 },
  { name: "Copenhagen", latitude: 55.6759, longitude: 12.5655, expected_score: 3685973395504349 },
  { name: "New Delhi", latitude: 28.6667, longitude: 77.2167, expected_score: 3631527070936756 },
  { name: "Kathmandu", latitude: 27.7017, longitude: 85.3206, expected_score: 3639507404773204 },
  { name: "London", latitude: 51.5074, longitude: -0.1278, expected_score: 2163557714755072 },
  { name: "New York", latitude: 40.7128, longitude: -74.0060, expected_score: 1791873974549446 },
  { name: "Paris", latitude: 48.8534, longitude: 2.3488, expected_score: 3663832752681684 },
  { name: "Sydney", latitude: -33.8688, longitude: 151.2093, expected_score: 3252046221964352 },
  { name: "Tokyo", latitude: 35.6895, longitude: 139.6917, expected_score: 4171231230197045 },
  { name: "Vienna", latitude: 48.2064, longitude: 16.3707, expected_score: 3673109836391743 }
]

test_cases.each do |test_case|
  actual_score = encode(test_case[:latitude], test_case[:longitude])
  success = actual_score == test_case[:expected_score]
  status = success ? "✅" : "❌"
  puts "#{test_case[:name]}: #{actual_score} (#{status})"
end
