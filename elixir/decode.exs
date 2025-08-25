defmodule GeohashDecoder do
  @moduledoc """
  Geohash decoder module that converts encoded integers back to latitude/longitude coordinates.
  Uses Morton decoding (reverse Z-order curve) for spatial indexing.
  """

  use Bitwise

  @min_latitude -85.05112878
  @max_latitude 85.05112878
  @min_longitude -180.0
  @max_longitude 180.0
  @latitude_range @max_latitude - @min_latitude
  @longitude_range @max_longitude - @min_longitude

  defmodule Coordinates do
    defstruct [:latitude, :longitude]
  end

  @doc """
  Decodes an encoded geohash value back to latitude and longitude coordinates.
  
  ## Parameters
    - geo_code: integer encoded geohash value
  
  ## Returns
    - %Coordinates{}: struct containing latitude and longitude
  """
  def decode(geo_code) do
    # Align bits of both latitude and longitude to take even-numbered position
    y = geo_code >>> 1
    x = geo_code
    
    # Compact bits back to 32-bit ints
    grid_latitude_number = compact_int64_to_int32(x)
    grid_longitude_number = compact_int64_to_int32(y)
    
    convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
  end

  # Compacts spread bits back to a 32-bit integer
  defp compact_int64_to_int32(v) do
    v = v &&& 0x5555555555555555
    v = (v ||| (v >>> 1)) &&& 0x3333333333333333
    v = (v ||| (v >>> 2)) &&& 0x0F0F0F0F0F0F0F0F
    v = (v ||| (v >>> 4)) &&& 0x00FF00FF00FF00FF
    v = (v ||| (v >>> 8)) &&& 0x0000FFFF0000FFFF
    (v ||| (v >>> 16)) &&& 0x00000000FFFFFFFF
  end

  # Converts grid cell numbers back to geographic coordinates
  defp convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number) do
    # Calculate the grid boundaries
    grid_latitude_min = @min_latitude + @latitude_range * (grid_latitude_number / :math.pow(2, 26))
    grid_latitude_max = @min_latitude + @latitude_range * ((grid_latitude_number + 1) / :math.pow(2, 26))
    grid_longitude_min = @min_longitude + @longitude_range * (grid_longitude_number / :math.pow(2, 26))
    grid_longitude_max = @min_longitude + @longitude_range * ((grid_longitude_number + 1) / :math.pow(2, 26))
    
    # Calculate the center point of the grid cell
    latitude = (grid_latitude_min + grid_latitude_max) / 2
    longitude = (grid_longitude_min + grid_longitude_max) / 2
    
    %Coordinates{latitude: latitude, longitude: longitude}
  end

  @doc """
  Runs test cases to verify decoding functionality.
  """
  def run_tests do
    test_cases = [
      %{name: "Bangkok", expected_latitude: 13.722000686932997, expected_longitude: 100.52520006895065, score: 3962257306574459},
      %{name: "Beijing", expected_latitude: 39.9075003315814, expected_longitude: 116.39719873666763, score: 4069885364908765},
      %{name: "Berlin", expected_latitude: 52.52439934649943, expected_longitude: 13.410500586032867, score: 3673983964876493},
      %{name: "Copenhagen", expected_latitude: 55.67589927498264, expected_longitude: 12.56549745798111, score: 3685973395504349},
      %{name: "New Delhi", expected_latitude: 28.666698899347338, expected_longitude: 77.21670180559158, score: 3631527070936756},
      %{name: "Kathmandu", expected_latitude: 27.701700137333084, expected_longitude: 85.3205993771553, score: 3639507404773204},
      %{name: "London", expected_latitude: 51.50740077990134, expected_longitude: -0.12779921293258667, score: 2163557714755072},
      %{name: "New York", expected_latitude: 40.712798986951505, expected_longitude: -74.00600105524063, score: 1791873974549446},
      %{name: "Paris", expected_latitude: 48.85340071224621, expected_longitude: 2.348802387714386, score: 3663832752681684},
      %{name: "Sydney", expected_latitude: -33.86880091934156, expected_longitude: 151.2092998623848, score: 3252046221964352},
      %{name: "Tokyo", expected_latitude: 35.68950126697936, expected_longitude: 139.691701233387, score: 4171231230197045},
      %{name: "Vienna", expected_latitude: 48.20640046271915, expected_longitude: 16.370699107646942, score: 3673109836391743}
    ]

    IO.puts("=== Decode Test Cases ===")
    
    Enum.each(test_cases, fn test_case ->
      result = decode(test_case.score)
      
      # Check if decoded coordinates are close to original (within 1e-6 precision)
      lat_diff = abs(result.latitude - test_case.expected_latitude)
      lon_diff = abs(result.longitude - test_case.expected_longitude)
      
      success = lat_diff < 1.0e-6 and lon_diff < 1.0e-6
      status = if success, do: "Success", else: "Failure"
      IO.puts("#{test_case.name}: (lat=#{result.latitude}, lon=#{result.longitude}) (#{status})")
      
      unless success do
        IO.puts("  Expected: lat=#{test_case.expected_latitude}, lon=#{test_case.expected_longitude}")
        IO.puts("  Diff: lat=#{lat_diff}, lon=#{lon_diff}")
      end
    end)
  end
end

# Run tests if this file is executed directly
GeohashDecoder.run_tests()
