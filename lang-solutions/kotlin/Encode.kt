import kotlin.math.pow

object Encode {
    const val MIN_LATITUDE = -85.05112878
    const val MAX_LATITUDE = 85.05112878
    const val MIN_LONGITUDE = -180.0
    const val MAX_LONGITUDE = 180.0

    const val LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
    const val LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

    fun spreadInt32ToInt64(v: Long): Long {
        var result = v and 0xFFFFFFFFL
        result = (result or (result shl 16)) and 0x0000FFFF0000FFFFL
        result = (result or (result shl 8)) and 0x00FF00FF00FF00FFL
        result = (result or (result shl 4)) and 0x0F0F0F0F0F0F0F0FL
        result = (result or (result shl 2)) and 0x3333333333333333L
        return (result or (result shl 1)) and 0x5555555555555555L
    }

    fun interleave(x: Long, y: Long): Long {
        val xSpread = spreadInt32ToInt64(x)
        val ySpread = spreadInt32ToInt64(y)
        val yShifted = ySpread shl 1
        return xSpread or yShifted
    }

    fun encode(latitude: Double, longitude: Double): Long {
        // Normalize to the range 0-2^26
        val normalizedLatitude = 2.0.pow(26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
        val normalizedLongitude = 2.0.pow(26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

        // Truncate to integers
        val latInt = normalizedLatitude.toLong()
        val lonInt = normalizedLongitude.toLong()

        return interleave(latInt, lonInt)
    }

    data class TestCase(
        val name: String,
        val latitude: Double,
        val longitude: Double,
        val expectedScore: Long
    )

    @JvmStatic
    fun main(args: Array<String>) {
        val testCases = listOf(
            TestCase("Bangkok", 13.7220, 100.5252, 3962257306574459L),
            TestCase("Beijing", 39.9075, 116.3972, 4069885364908765L),
            TestCase("Berlin", 52.5244, 13.4105, 3673983964876493L),
            TestCase("Copenhagen", 55.6759, 12.5655, 3685973395504349L),
            TestCase("New Delhi", 28.6667, 77.2167, 3631527070936756L),
            TestCase("Kathmandu", 27.7017, 85.3206, 3639507404773204L),
            TestCase("London", 51.5074, -0.1278, 2163557714755072L),
            TestCase("New York", 40.7128, -74.0060, 1791873974549446L),
            TestCase("Paris", 48.8534, 2.3488, 3663832752681684L),
            TestCase("Sydney", -33.8688, 151.2093, 3252046221964352L),
            TestCase("Tokyo", 35.6895, 139.6917, 4171231230197045L),
            TestCase("Vienna", 48.2064, 16.3707, 3673109836391743L)
        )

        testCases.forEach { testCase ->
            val actualScore = encode(testCase.latitude, testCase.longitude)
            val success = actualScore == testCase.expectedScore
            println("${testCase.name}: $actualScore (${if (success) "✅" else "❌"})")
        }
    }
}
