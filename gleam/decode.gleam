import gleam/io
import gleam/int
import gleam/float
import gleam/list

const min_latitude = -85.05112878
const max_latitude = 85.05112878
const min_longitude = -180.0
const max_longitude = 180.0

pub type Coordinates {
  Coordinates(latitude: Float, longitude: Float)
}

type TestCase {
  TestCase(name: String, expected_latitude: Float, expected_longitude: Float, score: Int)
}

// Compacts spread bits back to a 32-bit integer
fn compact_int64_to_int32(v: Int) -> Int {
  let result = int.bitwise_and(v, 0x5555555555555555)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_right(result, 1)), 0x3333333333333333)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_right(result, 2)), 0x0F0F0F0F0F0F0F0F)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_right(result, 4)), 0x00FF00FF00FF00FF)
  let result = int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_right(result, 8)), 0x0000FFFF0000FFFF)
  int.bitwise_and(int.bitwise_or(result, int.bitwise_shift_right(result, 16)), 0x00000000FFFFFFFF)
}

// Converts grid cell numbers back to geographic coordinates
fn convert_grid_numbers_to_coordinates(grid_latitude_number: Int, grid_longitude_number: Int) -> Coordinates {
  // Calculate ranges
  let latitude_range = max_latitude -. min_latitude
  let longitude_range = max_longitude -. min_longitude
  
  // Calculate the grid boundaries
  let divisor = int.bitwise_shift_left(1, 26) |> int.to_float
  let grid_latitude_min = min_latitude +. latitude_range *. { int.to_float(grid_latitude_number) /. divisor }
  let grid_latitude_max = min_latitude +. latitude_range *. { int.to_float(grid_latitude_number + 1) /. divisor }
  let grid_longitude_min = min_longitude +. longitude_range *. { int.to_float(grid_longitude_number) /. divisor }
  let grid_longitude_max = min_longitude +. longitude_range *. { int.to_float(grid_longitude_number + 1) /. divisor }
  
  // Calculate the center point of the grid cell
  let latitude = { grid_latitude_min +. grid_latitude_max } /. 2.0
  let longitude = { grid_longitude_min +. grid_longitude_max } /. 2.0
  
  Coordinates(latitude, longitude)
}

// Decodes an encoded geohash value back to latitude and longitude coordinates
pub fn decode(geo_code: Int) -> Coordinates {
  // Align bits of both latitude and longitude to take even-numbered position
  let y = int.bitwise_shift_right(geo_code, 1)
  let x = geo_code
  
  // Compact bits back to 32-bit ints
  let grid_latitude_number = compact_int64_to_int32(x)
  let grid_longitude_number = compact_int64_to_int32(y)
  
  convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
}

fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

pub fn main() {
  let test_cases = [
    TestCase("Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459),
    TestCase("Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765),
    TestCase("Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493),
    TestCase("Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349),
    TestCase("New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756),
    TestCase("Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204),
    TestCase("London", 51.50740077990134, -0.12779921293258667, 2163557714755072),
    TestCase("New York", 40.712798986951505, -74.00600105524063, 1791873974549446),
    TestCase("Paris", 48.85340071224621, 2.348802387714386, 3663832752681684),
    TestCase("Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352),
    TestCase("Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045),
    TestCase("Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743),
  ]

  io.println("=== Decode Test Cases ===")
  
  list.each(test_cases, fn(test_case) {
    let result = decode(test_case.score)
    
    // Check if decoded coordinates are close to original (within 1e-6 precision)
    let lat_diff = float_abs(result.latitude -. test_case.expected_latitude)
    let lon_diff = float_abs(result.longitude -. test_case.expected_longitude)
    
    let success = lat_diff <. 0.000001 && lon_diff <. 0.000001
    let status = case success {
      True -> "✅"
      False -> "❌"
    }
    let lat_str = float.to_string(result.latitude)
    let lon_str = float.to_string(result.longitude)
    let message = test_case.name <> ": (lat=" <> lat_str <> ", lon=" <> lon_str <> ") (" <> status <> ")"
    io.println(message)
    
    case success {
      False -> {
        let exp_lat_str = float.to_string(test_case.expected_latitude)
        let exp_lon_str = float.to_string(test_case.expected_longitude)
        let lat_diff_str = float.to_string(lat_diff)
        let lon_diff_str = float.to_string(lon_diff)
        io.println("  Expected: lat=" <> exp_lat_str <> ", lon=" <> exp_lon_str)
        io.println("  Diff: lat=" <> lat_diff_str <> ", lon=" <> lon_diff_str)
      }
      True -> Nil
    }
  })
}
