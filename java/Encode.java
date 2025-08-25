public class Encode {
    private static final double MIN_LATITUDE = -85.05112878;
    private static final double MAX_LATITUDE = 85.05112878;
    private static final double MIN_LONGITUDE = -180.0;
    private static final double MAX_LONGITUDE = 180.0;

    private static final double LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
    private static final double LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

    private static long spreadInt32ToInt64(int v) {
        long result = v & 0xFFFFFFFFL;
        result = (result | (result << 16)) & 0x0000FFFF0000FFFFL;
        result = (result | (result << 8)) & 0x00FF00FF00FF00FFL;
        result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0FL;
        result = (result | (result << 2)) & 0x3333333333333333L;
        result = (result | (result << 1)) & 0x5555555555555555L;
        return result;
    }

    private static long interleave(int x, int y) {
        long xSpread = spreadInt32ToInt64(x);
        long ySpread = spreadInt32ToInt64(y);
        long yShifted = ySpread << 1;
        return xSpread | yShifted;
    }

    public static long encode(double latitude, double longitude) {
        // Normalize to the range 0-2^26
        double normalizedLatitude = Math.pow(2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
        double normalizedLongitude = Math.pow(2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

        // Truncate to integers
        int latInt = (int) normalizedLatitude;
        int lonInt = (int) normalizedLongitude;

        return interleave(latInt, lonInt);
    }

    static class TestCase {
        String name;
        double latitude;
        double longitude;
        long expectedScore;

        TestCase(String name, double latitude, double longitude, long expectedScore) {
            this.name = name;
            this.latitude = latitude;
            this.longitude = longitude;
            this.expectedScore = expectedScore;
        }
    }

    public static void main(String[] args) {
        TestCase[] testCases = {
            new TestCase("Bangkok", 13.7220, 100.5252, 3962257306574459L),
            new TestCase("Beijing", 39.9075, 116.3972, 4069885364908765L),
            new TestCase("Berlin", 52.5244, 13.4105, 3673983964876493L),
            new TestCase("Copenhagen", 55.6759, 12.5655, 3685973395504349L),
            new TestCase("New Delhi", 28.6667, 77.2167, 3631527070936756L),
            new TestCase("Kathmandu", 27.7017, 85.3206, 3639507404773204L),
            new TestCase("London", 51.5074, -0.1278, 2163557714755072L),
            new TestCase("New York", 40.7128, -74.0060, 1791873974549446L),
            new TestCase("Paris", 48.8534, 2.3488, 3663832752681684L),
            new TestCase("Sydney", -33.8688, 151.2093, 3252046221964352L),
            new TestCase("Tokyo", 35.6895, 139.6917, 4171231230197045L),
            new TestCase("Vienna", 48.2064, 16.3707, 3673109836391743L)
        };

        for (TestCase testCase : testCases) {
            long actualScore = encode(testCase.latitude, testCase.longitude);
            boolean success = actualScore == testCase.expectedScore;
            System.out.println(testCase.name + ": " + actualScore + " (" + (success ? "✅" : "❌") + ")");
        }
    }
}
