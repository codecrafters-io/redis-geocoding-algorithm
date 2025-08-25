let min_latitude = -85.05112878
let max_latitude = 85.05112878
let min_longitude = -180.0
let max_longitude = 180.0

let latitude_range = max_latitude -. min_latitude
let longitude_range = max_longitude -. min_longitude

let spread_int32_to_int64 v =
  let v = Int64.logand v 0xFFFFFFFFL in
  let v = Int64.logand (Int64.logor v (Int64.shift_left v 16)) 0x0000FFFF0000FFFFL in
  let v = Int64.logand (Int64.logor v (Int64.shift_left v 8)) 0x00FF00FF00FF00FFL in
  let v = Int64.logand (Int64.logor v (Int64.shift_left v 4)) 0x0F0F0F0F0F0F0F0FL in
  let v = Int64.logand (Int64.logor v (Int64.shift_left v 2)) 0x3333333333333333L in
  Int64.logand (Int64.logor v (Int64.shift_left v 1)) 0x5555555555555555L

let interleave x y =
  let x_spread = spread_int32_to_int64 (Int64.of_int32 x) in
  let y_spread = spread_int32_to_int64 (Int64.of_int32 y) in
  let y_shifted = Int64.shift_left y_spread 1 in
  Int64.logor x_spread y_shifted

let encode latitude longitude =
  (* Normalize to the range 0-2^26 *)
  let normalized_latitude = (2.0 ** 26.0) *. (latitude -. min_latitude) /. latitude_range in
  let normalized_longitude = (2.0 ** 26.0) *. (longitude -. min_longitude) /. longitude_range in

  (* Truncate to integers *)
  let lat_int = Int32.of_float normalized_latitude in
  let lon_int = Int32.of_float normalized_longitude in

  interleave lat_int lon_int

type test_case = {
  name : string;
  latitude : float;
  longitude : float;
  expected_score : int64;
}

let test_cases = [
  {name = "Bangkok"; latitude = 13.7220; longitude = 100.5252; expected_score = 3962257306574459L};
  {name = "Beijing"; latitude = 39.9075; longitude = 116.3972; expected_score = 4069885364908765L};
  {name = "Berlin"; latitude = 52.5244; longitude = 13.4105; expected_score = 3673983964876493L};
  {name = "Copenhagen"; latitude = 55.6759; longitude = 12.5655; expected_score = 3685973395504349L};
  {name = "New Delhi"; latitude = 28.6667; longitude = 77.2167; expected_score = 3631527070936756L};
  {name = "Kathmandu"; latitude = 27.7017; longitude = 85.3206; expected_score = 3639507404773204L};
  {name = "London"; latitude = 51.5074; longitude = -0.1278; expected_score = 2163557714755072L};
  {name = "New York"; latitude = 40.7128; longitude = -74.0060; expected_score = 1791873974549446L};
  {name = "Paris"; latitude = 48.8534; longitude = 2.3488; expected_score = 3663832752681684L};
  {name = "Sydney"; latitude = -33.8688; longitude = 151.2093; expected_score = 3252046221964352L};
  {name = "Tokyo"; latitude = 35.6895; longitude = 139.6917; expected_score = 4171231230197045L};
  {name = "Vienna"; latitude = 48.2064; longitude = 16.3707; expected_score = 3673109836391743L};
]

let () =
  List.iter (fun test_case ->
    let actual_score = encode test_case.latitude test_case.longitude in
    let success = Int64.equal actual_score test_case.expected_score in
    Printf.printf "%s: %Ld (%s)\n" test_case.name actual_score (if success then "✅" else "❌")
  ) test_cases
