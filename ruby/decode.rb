include Math

MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0
LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

class Coordinates
  attr_accessor :latitude, :longitude
  
  def initialize(latitude, longitude)
    @latitude = latitude
    @longitude = longitude
  end
end

def compact_int64_to_int32(v)
  v = v & 0x5555555555555555
  v = (v | (v >> 1)) & 0x3333333333333333
  v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0F
  v = (v | (v >> 4)) & 0x00FF00FF00FF00FF
  v = (v | (v >> 8)) & 0x0000FFFF0000FFFF
  return (v | (v >> 16)) & 0x00000000FFFFFFFF  # Added return statement
end

def convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
  # Calculate the grid boundaries
  grid_latitude_min = MIN_LATITUDE + LATITUDE_RANGE * (grid_latitude_number.to_f / (2**26))
  grid_latitude_max = MIN_LATITUDE + LATITUDE_RANGE * ((grid_latitude_number + 1).to_f / (2**26))
  grid_longitude_min = MIN_LONGITUDE + LONGITUDE_RANGE * (grid_longitude_number.to_f / (2**26))
  grid_longitude_max = MIN_LONGITUDE + LONGITUDE_RANGE * ((grid_longitude_number.to_f + 1) / (2**26))
  
  # Calculate the center point of the grid cell
  latitude = (grid_latitude_min + grid_latitude_max) / 2
  longitude = (grid_longitude_min + grid_longitude_max) / 2
  
  return Coordinates.new(latitude, longitude)
end

def decode(geo_code)
  # Align bits of both latitude and longitude to take even-numbered position
  y = geo_code >> 1
  x = geo_code
  
  # Compact bits back to 32-bit ints
  grid_latitude_number = compact_int64_to_int32(x)
  grid_longitude_number = compact_int64_to_int32(y)
  
  return convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)  # Added return statement
end

# Test cases
test_cases = [
  { name: "Bangkok", expected_latitude: 13.722000686932997, expected_longitude: 100.52520006895065, score: 3962257306574459 },
  { name: "Beijing", expected_latitude: 39.9075003315814, expected_longitude: 116.39719873666763, score: 4069885364908765 },
  { name: "Berlin", expected_latitude: 52.52439934649943, expected_longitude: 13.410500586032867, score: 3673983964876493 },
  { name: "Copenhagen", expected_latitude: 55.67589927498264, expected_longitude: 12.56549745798111, score: 3685973395504349 },
  { name: "New Delhi", expected_latitude: 28.666698899347338, expected_longitude: 77.21670180559158, score: 3631527070936756 },
  { name: "Kathmandu", expected_latitude: 27.701700137333084, expected_longitude: 85.3205993771553, score: 3639507404773204 },
  { name: "London", expected_latitude: 51.50740077990134, expected_longitude: -0.12779921293258667, score: 2163557714755072 },
  { name: "New York", expected_latitude: 40.712798986951505, expected_longitude: -74.00600105524063, score: 1791873974549446 },
  { name: "Paris", expected_latitude: 48.85340071224621, expected_longitude: 2.348802387714386, score: 3663832752681684 },
  { name: "Sydney", expected_latitude: -33.86880091934156, expected_longitude: 151.2092998623848, score: 3252046221964352 },
  { name: "Tokyo", expected_latitude: 35.68950126697936, expected_longitude: 139.691701233387, score: 4171231230197045 },
  { name: "Vienna", expected_latitude: 48.20640046271915, expected_longitude: 16.370699107646942, score: 3673109836391743 }
]

test_cases.each do |test_case|
  result = decode(test_case[:score])
  
  # Check if decoded coordinates are close to original (within 10e-6 precision)
  lat_diff = (result.latitude - test_case[:expected_latitude]).abs
  lon_diff = (result.longitude - test_case[:expected_longitude]).abs
  
  success = lat_diff < 1e-6 && lon_diff < 1e-6  # Using same precision as Python
  status = success ? "✅" : "❌"
  
  printf("%s: (lat=%.15f, lon=%.15f) (%s)\n", test_case[:name], result.latitude, result.longitude, status)
  
  unless success
    printf("  Expected: lat=%.15f, lon=%.15f\n", test_case[:expected_latitude], test_case[:expected_longitude])
    printf("  Diff: lat=%.6f, lon=%.6f\n", lat_diff, lon_diff)
  end
end