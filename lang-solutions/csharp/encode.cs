using System;

public class GeohashEncoder
{
    private const double MIN_LATITUDE = -85.05112878;
    private const double MAX_LATITUDE = 85.05112878;
    private const double MIN_LONGITUDE = -180;
    private const double MAX_LONGITUDE = 180;
    private const double LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
    private const double LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

    public static long Encode(double latitude, double longitude)
    {
        // Normalize to the range 0-2^26
        double normalizedLatitude = Math.Pow(2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
        double normalizedLongitude = Math.Pow(2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

        // Truncate to integers
        int normalizedLatitudeInt = (int)normalizedLatitude;
        int normalizedLongitudeInt = (int)normalizedLongitude;

        return Interleave(normalizedLatitudeInt, normalizedLongitudeInt);
    }

    private static long Interleave(int x, int y)
    {
        long spreadX = SpreadInt32ToInt64(x);
        long spreadY = SpreadInt32ToInt64(y);
        long yShifted = spreadY << 1;
        return spreadX | yShifted;
    }

    private static long SpreadInt32ToInt64(int v)
    {
        long result = v & 0xFFFFFFFF;
        result = (result | (result << 16)) & 0x0000FFFF0000FFFF;
        result = (result | (result << 8)) & 0x00FF00FF00FF00FF;
        result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F;
        result = (result | (result << 2)) & 0x3333333333333333;
        result = (result | (result << 1)) & 0x5555555555555555;
        return result;
    }

    public static void Main(string[] args)
    {
        var testCases = new[]
        {
            new { Name = "Bangkok", Latitude = 13.7220, Longitude = 100.5252, Score = 3962257306574459L },
            new { Name = "Beijing", Latitude = 39.9075, Longitude = 116.3972, Score = 4069885364908765L },
            new { Name = "Berlin", Latitude = 52.5244, Longitude = 13.4105, Score = 3673983964876493L },
            new { Name = "Copenhagen", Latitude = 55.6759, Longitude = 12.5655, Score = 3685973395504349L },
            new { Name = "New Delhi", Latitude = 28.6667, Longitude = 77.2167, Score = 3631527070936756L },
            new { Name = "Kathmandu", Latitude = 27.7017, Longitude = 85.3206, Score = 3639507404773204L },
            new { Name = "London", Latitude = 51.5074, Longitude = -0.1278, Score = 2163557714755072L },
            new { Name = "New York", Latitude = 40.7128, Longitude = -74.0060, Score = 1791873974549446L },
            new { Name = "Paris", Latitude = 48.8534, Longitude = 2.3488, Score = 3663832752681684L },
            new { Name = "Sydney", Latitude = -33.8688, Longitude = 151.2093, Score = 3252046221964352L },
            new { Name = "Tokyo", Latitude = 35.6895, Longitude = 139.6917, Score = 4171231230197045L },
            new { Name = "Vienna", Latitude = 48.2064, Longitude = 16.3707, Score = 3673109836391743L }
        };

        foreach (var testCase in testCases)
        {
            long expectedScore = testCase.Score;
            long actualScore = Encode(testCase.Latitude, testCase.Longitude);
            string result = actualScore == expectedScore ? "✅" : "❌";
            Console.WriteLine($"{testCase.Name}: {actualScore} ({result})");
        }
    }
}