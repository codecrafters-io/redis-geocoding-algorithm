MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

struct Coordinates
  property latitude : Float64
  property longitude : Float64

  def initialize(@latitude, @longitude)
  end
end

def compact_int64_to_int32(v : UInt64) : UInt32
  result = v & 0x5555555555555555_u64
  result = (result | (result >> 1)) & 0x3333333333333333_u64
  result = (result | (result >> 2)) & 0x0F0F0F0F0F0F0F0F_u64
  result = (result | (result >> 4)) & 0x00FF00FF00FF00FF_u64
  result = (result | (result >> 8)) & 0x0000FFFF0000FFFF_u64
  result = (result | (result >> 16))
  return (result & 0xFFFFFFFF_u32).to_u32
end

def convert_grid_numbers_to_coordinates(grid_latitude_number : UInt32, grid_longitude_number : UInt32) : Coordinates
  # Calculate the grid boundaries
  grid_latitude_min = MIN_LATITUDE + LATITUDE_RANGE * (grid_latitude_number.to_f64 / (2.0 ** 26))
  grid_latitude_max = MIN_LATITUDE + LATITUDE_RANGE * ((grid_latitude_number + 1).to_f64 / (2.0 ** 26))
  grid_longitude_min = MIN_LONGITUDE + LONGITUDE_RANGE * (grid_longitude_number.to_f64 / (2.0 ** 26))
  grid_longitude_max = MIN_LONGITUDE + LONGITUDE_RANGE * ((grid_longitude_number + 1).to_f64 / (2.0 ** 26))
  
  # Calculate the center point of the grid cell
  latitude = (grid_latitude_min + grid_latitude_max) / 2.0
  longitude = (grid_longitude_min + grid_longitude_max) / 2.0
  
  Coordinates.new(latitude, longitude)
end

def decode(geo_code : UInt64) : Coordinates
  # Align bits of both latitude and longitude to take even-numbered position
  y = geo_code >> 1
  x = geo_code
  
  # Compact bits back to 32-bit ints
  grid_latitude_number = compact_int64_to_int32(x)
  grid_longitude_number = compact_int64_to_int32(y)
  
  convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
end

struct TestCase
  property name : String
  property expected_latitude : Float64
  property expected_longitude : Float64
  property score : UInt64

  def initialize(@name, @expected_latitude, @expected_longitude, @score)
  end
end

test_cases = [
  TestCase.new("Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459_u64),
  TestCase.new("Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765_u64),
  TestCase.new("Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493_u64),
  TestCase.new("Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349_u64),
  TestCase.new("New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756_u64),
  TestCase.new("Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204_u64),
  TestCase.new("London", 51.50740077990134, -0.12779921293258667, 2163557714755072_u64),
  TestCase.new("New York", 40.712798986951505, -74.00600105524063, 1791873974549446_u64),
  TestCase.new("Paris", 48.85340071224621, 2.348802387714386, 3663832752681684_u64),
  TestCase.new("Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352_u64),
  TestCase.new("Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045_u64),
  TestCase.new("Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743_u64)
]

test_cases.each do |test_case|
  result = decode(test_case.score)
  
  # Check if decoded coordinates are close to original (within 10e-6 precision)
  lat_diff = (result.latitude - test_case.expected_latitude).abs
  lon_diff = (result.longitude - test_case.expected_longitude).abs
  
  success = lat_diff < 0.000001 && lon_diff < 0.000001
  status = success ? "✅" : "❌"
  puts "#{test_case.name}: (lat=#{result.latitude}, lon=#{result.longitude}) (#{status})"
  
  unless success
    puts "  Expected: lat=#{test_case.expected_latitude}, lon=#{test_case.expected_longitude}"
    puts "  Diff: lat=#{lat_diff}, lon=#{lon_diff}"
  end
end
