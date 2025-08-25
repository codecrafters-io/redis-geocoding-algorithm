import gleam/io
import gleam/int
import gleam/float
import gleam/list
import gleam/string

const min_latitude = -85.05112878
const max_latitude = 85.05112878
const min_longitude = -180.0
const max_longitude = 180.0

type TestCase {
  TestCase(name: String, latitude: Float, longitude: Float, expected_score: Int)
}

// Spreads bits of a 32-bit integer to occupy even positions in a 64-bit integer
fn spread_int32_to_int64(v: Int) -> Int {
  let result = int.bitwise_and(v, 0xFFFFFFFF)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_left(result, 16)), 0x0000FFFF0000FFFF)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_left(result, 8)), 0x00FF00FF00FF00FF)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_left(result, 4)), 0x0F0F0F0F0F0F0F0F)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_left(result, 2)), 0x3333333333333333)
  int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_left(result, 1)), 0x5555555555555555)
}

// Interleaves bits of two 32-bit integers to create a single 64-bit Morton code
fn interleave(x: Int, y: Int) -> Int {
  let x_spread = spread_int32_to_int64(x)
  let y_spread = spread_int32_to_int64(y)
  let y_shifted = int.bitwise_shift_left(y_spread, 1)
  int.bitwise_or(x_spread, y_shifted)
}

// Encodes latitude and longitude coordinates into a single integer using Morton encoding
pub fn encode(latitude: Float, longitude: Float) -> Int {
  // Calculate ranges
  let latitude_range = max_latitude -. min_latitude
  let longitude_range = max_longitude -. min_longitude
  
  // Normalize to the range 0-2^26
  let normalized_latitude = int.bitwise_shift_left(1, 26) |> int.to_float |> float.multiply(latitude -. min_latitude) |> float.divide(latitude_range)
  let normalized_longitude = int.bitwise_shift_left(1, 26) |> int.to_float |> float.multiply(longitude -. min_longitude) |> float.divide(longitude_range)

  // Truncate to integers
  let lat_int = case normalized_latitude {
    Ok(val) -> float.truncate(val)
    Error(_) -> 0
  }
  let lon_int = case normalized_longitude {
    Ok(val) -> float.truncate(val)
    Error(_) -> 0
  }

  interleave(lat_int, lon_int)
}

pub fn main() {
  let test_cases = [
    TestCase("Bangkok", 13.7220, 100.5252, 3962257306574459),
    TestCase("Beijing", 39.9075, 116.3972, 4069885364908765),
    TestCase("Berlin", 52.5244, 13.4105, 3673983964876493),
    TestCase("Copenhagen", 55.6759, 12.5655, 3685973395504349),
    TestCase("New Delhi", 28.6667, 77.2167, 3631527070936756),
    TestCase("Kathmandu", 27.7017, 85.3206, 3639507404773204),
    TestCase("London", 51.5074, -0.1278, 2163557714755072),
    TestCase("New York", 40.7128, -74.0060, 1791873974549446),
    TestCase("Paris", 48.8534, 2.3488, 3663832752681684),
    TestCase("Sydney", -33.8688, 151.2093, 3252046221964352),
    TestCase("Tokyo", 35.6895, 139.6917, 4171231230197045),
    TestCase("Vienna", 48.2064, 16.3707, 3673109836391743),
  ]

  io.println("=== Encode Test Cases ===")
  
  list.each(test_cases, fn(test_case) {
    let actual_score = encode(test_case.latitude, test_case.longitude)
    let success = actual_score == test_case.expected_score
    let status = case success {
      True -> "✅"
      False -> "❌"
    }
    let score_str = int.to_string(actual_score)
    let message = string.concat([test_case.name, ": ", score_str, " (", status, ")"])
    io.println(message)
  })
}
