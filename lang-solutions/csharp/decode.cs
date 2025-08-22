using System;

public class GeohashDecoder
{
    private const double MIN_LATITUDE = -85.05112878;
    private const double MAX_LATITUDE = 85.05112878;
    private const double MIN_LONGITUDE = -180;
    private const double MAX_LONGITUDE = 180;
    private const double LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
    private const double LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

    /// <summary>
    /// Decode converts geo code (WGS84) to tuple of (latitude, longitude)
    /// </summary>
    /// <param name="geoCode">The encoded geographic code</param>
    /// <returns>Tuple containing (latitude, longitude)</returns>
    public static (double latitude, double longitude) Decode(long geoCode)
    {
        // Align bits of both latitude and longitude to take even-numbered position
        long y = geoCode >> 1;
        long x = geoCode;

        // Compact bits back to 32-bit ints
        int gridLatitudeNumber = CompactInt64ToInt32(x);
        int gridLongitudeNumber = CompactInt64ToInt32(y);

        return ConvertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber);
    }

    /// <summary>
    /// Compact a 64-bit integer with interleaved bits back to a 32-bit integer.
    /// This is the reverse operation of spread_int32_to_int64.
    /// </summary>
    /// <param name="v">The 64-bit integer with interleaved bits</param>
    /// <returns>Compacted 32-bit integer</returns>
    private static int CompactInt64ToInt32(long v)
    {
        v = v & 0x5555555555555555;
        v = (v | (v >> 1)) & 0x3333333333333333;
        v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0F;
        v = (v | (v >> 4)) & 0x00FF00FF00FF00FF;
        v = (v | (v >> 8)) & 0x0000FFFF0000FFFF;
        v = (v | (v >> 16)) & 0x00000000FFFFFFFF;
        return (int)v;
    }

    /// <summary>
    /// Convert grid numbers back to geographic coordinates
    /// </summary>
    /// <param name="gridLatitudeNumber">Grid latitude number</param>
    /// <param name="gridLongitudeNumber">Grid longitude number</param>
    /// <returns>Tuple containing (latitude, longitude)</returns>
    private static (double latitude, double longitude) ConvertGridNumbersToCoordinates(int gridLatitudeNumber, int gridLongitudeNumber)
    {
        // Calculate the grid boundaries
        double gridLatitudeMin = MIN_LATITUDE + LATITUDE_RANGE * (gridLatitudeNumber / Math.Pow(2, 26));
        double gridLatitudeMax = MIN_LATITUDE + LATITUDE_RANGE * ((gridLatitudeNumber + 1) / Math.Pow(2, 26));
        double gridLongitudeMin = MIN_LONGITUDE + LONGITUDE_RANGE * (gridLongitudeNumber / Math.Pow(2, 26));
        double gridLongitudeMax = MIN_LONGITUDE + LONGITUDE_RANGE * ((gridLongitudeNumber + 1) / Math.Pow(2, 26));

        // Calculate the center point of the grid cell
        double latitude = (gridLatitudeMin + gridLatitudeMax) / 2;
        double longitude = (gridLongitudeMin + gridLongitudeMax) / 2;
        
        return (latitude, longitude);
    }

    public static void Main(string[] args)
    {
        // Test cases from encode.py to verify decoding
        // The latitude and longitude in test cases are the actual responses from redis server
        var testCases = new[]
        {
            new { Name = "Bangkok", Latitude = 13.722000686932997, Longitude = 100.52520006895065, Score = 3962257306574459L },
            new { Name = "Beijing", Latitude = 39.9075003315814, Longitude = 116.39719873666763, Score = 4069885364908765L },
            new { Name = "Berlin", Latitude = 52.52439934649943, Longitude = 13.410500586032867, Score = 3673983964876493L },
            new { Name = "Copenhagen", Latitude = 55.67589927498264, Longitude = 12.56549745798111, Score = 3685973395504349L },
            new { Name = "New Delhi", Latitude = 28.666698899347338, Longitude = 77.21670180559158, Score = 3631527070936756L },
            new { Name = "Kathmandu", Latitude = 27.701700137333084, Longitude = 85.3205993771553, Score = 3639507404773204L },
            new { Name = "London", Latitude = 51.50740077990134, Longitude = -0.12779921293258667, Score = 2163557714755072L },
            new { Name = "New York", Latitude = 40.712798986951505, Longitude = -74.00600105524063, Score = 1791873974549446L },
            new { Name = "Paris", Latitude = 48.85340071224621, Longitude = 2.348802387714386, Score = 3663832752681684L },
            new { Name = "Sydney", Latitude = -33.86880091934156, Longitude = 151.2092998623848, Score = 3252046221964352L },
            new { Name = "Tokyo", Latitude = 35.68950126697936, Longitude = 139.691701233387, Score = 4171231230197045L },
            new { Name = "Vienna", Latitude = 48.20640046271915, Longitude = 16.370699107646942, Score = 3673109836391743L }
        };

        foreach (var testCase in testCases)
        {
            long geoCode = testCase.Score;
            
            var (decodedLatitude, decodedLongitude) = Decode(geoCode);
            
            // Check if decoded coordinates are close to original (within 10e-6 precision)
            double latDiff = Math.Abs(decodedLatitude - testCase.Latitude);
            double lonDiff = Math.Abs(decodedLongitude - testCase.Longitude);
            
            bool success = latDiff < 1e-6 && lonDiff < 1e-6;
            string result = success ? "✅" : "❌";
            
            Console.WriteLine($"{testCase.Name}: (lat={decodedLatitude},lon={decodedLongitude}) {result}");
            
            if (!success)
            {
                Console.WriteLine($"  Expected: lat={testCase.Latitude}, lon={testCase.Longitude}");
                Console.WriteLine($"  Actual: lat={decodedLatitude}, lon={decodedLongitude}");
                Console.WriteLine($"  Diff: lat={latDiff:F6}, lon={lonDiff:F6}");
            }
        }
    }
}