MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

def spread_int32_to_int64(v : UInt32) : UInt64
  result = v.to_u64
  result = (result | (result << 16)) & 0x0000FFFF0000FFFF_u64
  result = (result | (result << 8)) & 0x00FF00FF00FF00FF_u64
  result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F_u64
  result = (result | (result << 2)) & 0x3333333333333333_u64
  (result | (result << 1)) & 0x5555555555555555_u64
end

def interleave(x : UInt32, y : UInt32) : UInt64
  x_spread = spread_int32_to_int64(x)
  y_spread = spread_int32_to_int64(y)
  y_shifted = y_spread << 1
  x_spread | y_shifted
end

def encode(latitude : Float64, longitude : Float64) : UInt64
  # Normalize to the range 0-2^26
  normalized_latitude = (2.0 ** 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
  normalized_longitude = (2.0 ** 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

  # Truncate to integers
  lat_int = normalized_latitude.to_u32
  lon_int = normalized_longitude.to_u32

  interleave(lat_int, lon_int)
end

struct TestCase
  property name : String
  property latitude : Float64
  property longitude : Float64
  property expected_score : UInt64

  def initialize(@name, @latitude, @longitude, @expected_score)
  end
end

test_cases = [
  TestCase.new("Bangkok", 13.7220, 100.5252, 3962257306574459_u64),
  TestCase.new("Beijing", 39.9075, 116.3972, 4069885364908765_u64),
  TestCase.new("Berlin", 52.5244, 13.4105, 3673983964876493_u64),
  TestCase.new("Copenhagen", 55.6759, 12.5655, 3685973395504349_u64),
  TestCase.new("New Delhi", 28.6667, 77.2167, 3631527070936756_u64),
  TestCase.new("Kathmandu", 27.7017, 85.3206, 3639507404773204_u64),
  TestCase.new("London", 51.5074, -0.1278, 2163557714755072_u64),
  TestCase.new("New York", 40.7128, -74.0060, 1791873974549446_u64),
  TestCase.new("Paris", 48.8534, 2.3488, 3663832752681684_u64),
  TestCase.new("Sydney", -33.8688, 151.2093, 3252046221964352_u64),
  TestCase.new("Tokyo", 35.6895, 139.6917, 4171231230197045_u64),
  TestCase.new("Vienna", 48.2064, 16.3707, 3673109836391743_u64)
]

test_cases.each do |test_case|
  actual_score = encode(test_case.latitude, test_case.longitude)
  success = actual_score == test_case.expected_score
  status = success ? "✅" : "❌"
  puts "#{test_case.name}: #{actual_score} (#{status})"
end
