defmodule GeohashEncoder do
  @moduledoc """
  Geohash encoder module that converts latitude/longitude coordinates to encoded integers.
  Uses Morton encoding (Z-order curve) for spatial indexing.
  """

  use Bitwise

  @min_latitude -85.05112878
  @max_latitude 85.05112878
  @min_longitude -180.0
  @max_longitude 180.0
  @latitude_range @max_latitude - @min_latitude
  @longitude_range @max_longitude - @min_longitude

  @doc """
  Encodes latitude and longitude coordinates into a single integer using Morton encoding.
  
  ## Parameters
    - latitude: float latitude coordinate
    - longitude: float longitude coordinate
  
  ## Returns
    - integer: encoded geohash value
  """
  def encode(latitude, longitude) do
    # Normalize to the range 0-2^26
    normalized_latitude = :math.pow(2, 26) * (latitude - @min_latitude) / @latitude_range
    normalized_longitude = :math.pow(2, 26) * (longitude - @min_longitude) / @longitude_range
    
    # Truncate to integers
    normalized_latitude_int = trunc(normalized_latitude)
    normalized_longitude_int = trunc(normalized_longitude)
    
    interleave(normalized_latitude_int, normalized_longitude_int)
  end

  # Spreads bits of a 32-bit integer to occupy even positions in a 64-bit integer.
  defp spread_int32_to_int64(v) do
    result = v &&& 0xFFFFFFFF
    result = (result ||| (result <<< 16)) &&& 0x0000FFFF0000FFFF
    result = (result ||| (result <<< 8)) &&& 0x00FF00FF00FF00FF
    result = (result ||| (result <<< 4)) &&& 0x0F0F0F0F0F0F0F0F
    result = (result ||| (result <<< 2)) &&& 0x3333333333333333
    result = (result ||| (result <<< 1)) &&& 0x5555555555555555
    result
  end

  # Interleaves bits of two 32-bit integers to create a single 64-bit Morton code.
  defp interleave(x, y) do
    spread_x = spread_int32_to_int64(x)
    spread_y = spread_int32_to_int64(y)
    y_shifted = spread_y <<< 1
    spread_x ||| y_shifted
  end

  @doc """
  Runs test cases to verify encoding functionality.
  """
  def run_tests do
    test_cases = [
      %{name: "Bangkok", latitude: 13.7220, longitude: 100.5252, score: 3962257306574459},
      %{name: "Beijing", latitude: 39.9075, longitude: 116.3972, score: 4069885364908765},
      %{name: "Berlin", latitude: 52.5244, longitude: 13.4105, score: 3673983964876493},
      %{name: "Copenhagen", latitude: 55.6759, longitude: 12.5655, score: 3685973395504349},
      %{name: "New Delhi", latitude: 28.6667, longitude: 77.2167, score: 3631527070936756},
      %{name: "Kathmandu", latitude: 27.7017, longitude: 85.3206, score: 3639507404773204},
      %{name: "London", latitude: 51.5074, longitude: -0.1278, score: 2163557714755072},
      %{name: "New York", latitude: 40.7128, longitude: -74.0060, score: 1791873974549446},
      %{name: "Paris", latitude: 48.8534, longitude: 2.3488, score: 3663832752681684},
      %{name: "Sydney", latitude: -33.8688, longitude: 151.2093, score: 3252046221964352},
      %{name: "Tokyo", latitude: 35.6895, longitude: 139.6917, score: 4171231230197045},
      %{name: "Vienna", latitude: 48.2064, longitude: 16.3707, score: 3673109836391743}
    ]

    IO.puts("=== Encode Test Cases ===")
    
    Enum.each(test_cases, fn test_case ->
      expected_score = test_case.score
      actual_score = encode(test_case.latitude, test_case.longitude)
      success = actual_score == expected_score
      result = if success, do: "Success", else: "Failure"
      IO.puts("#{test_case.name}: #{actual_score} (#{result})")
    end)
  end
end

# Run tests if this file is executed directly
GeohashEncoder.run_tests()
