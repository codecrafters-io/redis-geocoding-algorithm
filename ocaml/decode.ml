let min_latitude = -85.05112878
let max_latitude = 85.05112878
let min_longitude = -180.0
let max_longitude = 180.0

let latitude_range = max_latitude -. min_latitude
let longitude_range = max_longitude -. min_longitude

type coordinates = {
  latitude : float;
  longitude : float;
}

let compact_int64_to_int32 v =
  let v = Int64.logand v 0x5555555555555555L in
  let v = Int64.logand (Int64.logor v (Int64.shift_right v 1)) 0x3333333333333333L in
  let v = Int64.logand (Int64.logor v (Int64.shift_right v 2)) 0x0F0F0F0F0F0F0F0FL in
  let v = Int64.logand (Int64.logor v (Int64.shift_right v 4)) 0x00FF00FF00FF00FFL in
  let v = Int64.logand (Int64.logor v (Int64.shift_right v 8)) 0x0000FFFF0000FFFFL in
  Int64.to_int32 (Int64.logand (Int64.logor v (Int64.shift_right v 16)) 0x00000000FFFFFFFFL)

let convert_grid_numbers_to_coordinates grid_latitude_number grid_longitude_number =
  (* Calculate the grid boundaries *)
  let grid_latitude_min = min_latitude +. latitude_range *. (Int32.to_float grid_latitude_number /. (2.0 ** 26.0)) in
  let grid_latitude_max = min_latitude +. latitude_range *. (Int32.to_float (Int32.add grid_latitude_number 1l) /. (2.0 ** 26.0)) in
  let grid_longitude_min = min_longitude +. longitude_range *. (Int32.to_float grid_longitude_number /. (2.0 ** 26.0)) in
  let grid_longitude_max = min_longitude +. longitude_range *. (Int32.to_float (Int32.add grid_longitude_number 1l) /. (2.0 ** 26.0)) in
  
  (* Calculate the center point of the grid cell *)
  let latitude = (grid_latitude_min +. grid_latitude_max) /. 2.0 in
  let longitude = (grid_longitude_min +. grid_longitude_max) /. 2.0 in
  
  {latitude; longitude}

let decode geo_code =
  (* Align bits of both latitude and longitude to take even-numbered position *)
  let y = Int64.shift_right geo_code 1 in
  let x = geo_code in
  
  (* Compact bits back to 32-bit ints *)
  let grid_latitude_number = compact_int64_to_int32 x in
  let grid_longitude_number = compact_int64_to_int32 y in
  
  convert_grid_numbers_to_coordinates grid_latitude_number grid_longitude_number

type test_case = {
  name : string;
  expected_latitude : float;
  expected_longitude : float;
  score : int64;
}

let test_cases = [
  {name = "Bangkok"; expected_latitude = 13.722000686932997; expected_longitude = 100.52520006895065; score = 3962257306574459L};
  {name = "Beijing"; expected_latitude = 39.9075003315814; expected_longitude = 116.39719873666763; score = 4069885364908765L};
  {name = "Berlin"; expected_latitude = 52.52439934649943; expected_longitude = 13.410500586032867; score = 3673983964876493L};
  {name = "Copenhagen"; expected_latitude = 55.67589927498264; expected_longitude = 12.56549745798111; score = 3685973395504349L};
  {name = "New Delhi"; expected_latitude = 28.666698899347338; expected_longitude = 77.21670180559158; score = 3631527070936756L};
  {name = "Kathmandu"; expected_latitude = 27.701700137333084; expected_longitude = 85.3205993771553; score = 3639507404773204L};
  {name = "London"; expected_latitude = 51.50740077990134; expected_longitude = -0.12779921293258667; score = 2163557714755072L};
  {name = "New York"; expected_latitude = 40.712798986951505; expected_longitude = -74.00600105524063; score = 1791873974549446L};
  {name = "Paris"; expected_latitude = 48.85340071224621; expected_longitude = 2.348802387714386; score = 3663832752681684L};
  {name = "Sydney"; expected_latitude = -33.86880091934156; expected_longitude = 151.2092998623848; score = 3252046221964352L};
  {name = "Tokyo"; expected_latitude = 35.68950126697936; expected_longitude = 139.691701233387; score = 4171231230197045L};
  {name = "Vienna"; expected_latitude = 48.20640046271915; expected_longitude = 16.370699107646942; score = 3673109836391743L};
]

let () =
  List.iter (fun test_case ->
    let result = decode test_case.score in
    
    (* Check if decoded coordinates are close to original (within 10e-6 precision) *)
    let lat_diff = abs_float (result.latitude -. test_case.expected_latitude) in
    let lon_diff = abs_float (result.longitude -. test_case.expected_longitude) in
    
    let success = lat_diff < 0.000001 && lon_diff < 0.000001 in
    Printf.printf "%s: (lat=%.15f, lon=%.15f) (%s)\n" test_case.name result.latitude result.longitude (if success then "✅" else "❌");
    
    if not success then begin
      Printf.printf "  Expected: lat=%.15f, lon=%.15f\n" test_case.expected_latitude test_case.expected_longitude;
      Printf.printf "  Diff: lat=%.6f, lon=%.6f\n" lat_diff lon_diff
    end
  ) test_cases
