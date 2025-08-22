public class Decode {
    private static final double MIN_LATITUDE = -85.05112878;
    private static final double MAX_LATITUDE = 85.05112878;
    private static final double MIN_LONGITUDE = -180.0;
    private static final double MAX_LONGITUDE = 180.0;

    private static final double LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
    private static final double LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

    static class Coordinates {
        double latitude;
        double longitude;

        Coordinates(double latitude, double longitude) {
            this.latitude = latitude;
            this.longitude = longitude;
        }
    }

    private static int compactInt64ToInt32(long v) {
        v = v & 0x5555555555555555L;
        v = (v | (v >> 1)) & 0x3333333333333333L;
        v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0FL;
        v = (v | (v >> 4)) & 0x00FF00FF00FF00FFL;
        v = (v | (v >> 8)) & 0x0000FFFF0000FFFFL;
        v = (v | (v >> 16)) & 0x00000000FFFFFFFFL;
        return (int) v;
    }

    private static Coordinates convertGridNumbersToCoordinates(int gridLatitudeNumber, int gridLongitudeNumber) {
        // Calculate the grid boundaries
        double gridLatitudeMin = MIN_LATITUDE + LATITUDE_RANGE * (gridLatitudeNumber / Math.pow(2, 26));
        double gridLatitudeMax = MIN_LATITUDE + LATITUDE_RANGE * ((gridLatitudeNumber + 1) / Math.pow(2, 26));
        double gridLongitudeMin = MIN_LONGITUDE + LONGITUDE_RANGE * (gridLongitudeNumber / Math.pow(2, 26));
        double gridLongitudeMax = MIN_LONGITUDE + LONGITUDE_RANGE * ((gridLongitudeNumber + 1) / Math.pow(2, 26));
        
        // Calculate the center point of the grid cell
        double latitude = (gridLatitudeMin + gridLatitudeMax) / 2;
        double longitude = (gridLongitudeMin + gridLongitudeMax) / 2;
        
        return new Coordinates(latitude, longitude);
    }

    public static Coordinates decode(long geoCode) {
        // Align bits of both latitude and longitude to take even-numbered position
        long y = geoCode >> 1;
        long x = geoCode;
        
        // Compact bits back to 32-bit ints
        int gridLatitudeNumber = compactInt64ToInt32(x);
        int gridLongitudeNumber = compactInt64ToInt32(y);
        
        return convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber);
    }

    static class TestCase {
        String name;
        double expectedLatitude;
        double expectedLongitude;
        long score;

        TestCase(String name, double expectedLatitude, double expectedLongitude, long score) {
            this.name = name;
            this.expectedLatitude = expectedLatitude;
            this.expectedLongitude = expectedLongitude;
            this.score = score;
        }
    }

    public static void main(String[] args) {
        TestCase[] testCases = {
            new TestCase("Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459L),
            new TestCase("Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765L),
            new TestCase("Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493L),
            new TestCase("Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349L),
            new TestCase("New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756L),
            new TestCase("Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204L),
            new TestCase("London", 51.50740077990134, -0.12779921293258667, 2163557714755072L),
            new TestCase("New York", 40.712798986951505, -74.00600105524063, 1791873974549446L),
            new TestCase("Paris", 48.85340071224621, 2.348802387714386, 3663832752681684L),
            new TestCase("Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352L),
            new TestCase("Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045L),
            new TestCase("Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743L)
        };

        for (TestCase testCase : testCases) {
            Coordinates result = decode(testCase.score);
            
            // Check if decoded coordinates are close to original (within 10e-6 precision)
            double latDiff = Math.abs(result.latitude - testCase.expectedLatitude);
            double lonDiff = Math.abs(result.longitude - testCase.expectedLongitude);
            
            boolean success = latDiff < 1e-6 && lonDiff < 1e-6;
            System.out.printf("%s: (lat=%.15f, lon=%.15f) (%s)%n", 
                testCase.name, result.latitude, result.longitude, success ? "✅" : "❌");
            
            if (!success) {
                System.out.printf("  Expected: lat=%.15f, lon=%.15f%n", 
                    testCase.expectedLatitude, testCase.expectedLongitude);
                System.out.printf("  Diff: lat=%.6f, lon=%.6f%n", latDiff, lonDiff);
            }
        }
    }
}
