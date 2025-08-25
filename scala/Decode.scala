object Decode {
  val MIN_LATITUDE = -85.05112878
  val MAX_LATITUDE = 85.05112878
  val MIN_LONGITUDE = -180.0
  val MAX_LONGITUDE = 180.0

  val LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
  val LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

  case class Coordinates(latitude: Double, longitude: Double)

  def compactInt64ToInt32(v: Long): Long = {
    var result = v & 0x5555555555555555L
    result = (result | (result >> 1)) & 0x3333333333333333L
    result = (result | (result >> 2)) & 0x0F0F0F0F0F0F0F0FL
    result = (result | (result >> 4)) & 0x00FF00FF00FF00FFL
    result = (result | (result >> 8)) & 0x0000FFFF0000FFFFL
    (result | (result >> 16)) & 0x00000000FFFFFFFFL
  }

  def convertGridNumbersToCoordinates(gridLatitudeNumber: Long, gridLongitudeNumber: Long): Coordinates = {
    // Calculate the grid boundaries
    val gridLatitudeMin = MIN_LATITUDE + LATITUDE_RANGE * (gridLatitudeNumber / math.pow(2, 26))
    val gridLatitudeMax = MIN_LATITUDE + LATITUDE_RANGE * ((gridLatitudeNumber + 1) / math.pow(2, 26))
    val gridLongitudeMin = MIN_LONGITUDE + LONGITUDE_RANGE * (gridLongitudeNumber / math.pow(2, 26))
    val gridLongitudeMax = MIN_LONGITUDE + LONGITUDE_RANGE * ((gridLongitudeNumber + 1) / math.pow(2, 26))
    
    // Calculate the center point of the grid cell
    val latitude = (gridLatitudeMin + gridLatitudeMax) / 2
    val longitude = (gridLongitudeMin + gridLongitudeMax) / 2
    
    Coordinates(latitude, longitude)
  }

  def decode(geoCode: Long): Coordinates = {
    // Align bits of both latitude and longitude to take even-numbered position
    val y = geoCode >> 1
    val x = geoCode
    
    // Compact bits back to 32-bit ints
    val gridLatitudeNumber = compactInt64ToInt32(x)
    val gridLongitudeNumber = compactInt64ToInt32(y)
    
    convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber)
  }

  case class TestCase(name: String, expectedLatitude: Double, expectedLongitude: Double, score: Long)

  def main(args: Array[String]): Unit = {
    val testCases = List(
      TestCase("Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459L),
      TestCase("Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765L),
      TestCase("Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493L),
      TestCase("Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349L),
      TestCase("New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756L),
      TestCase("Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204L),
      TestCase("London", 51.50740077990134, -0.12779921293258667, 2163557714755072L),
      TestCase("New York", 40.712798986951505, -74.00600105524063, 1791873974549446L),
      TestCase("Paris", 48.85340071224621, 2.348802387714386, 3663832752681684L),
      TestCase("Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352L),
      TestCase("Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045L),
      TestCase("Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743L)
    )

    testCases.foreach { testCase =>
      val result = decode(testCase.score)
      
      // Check if decoded coordinates are close to original (within 10e-6 precision)
      val latDiff = math.abs(result.latitude - testCase.expectedLatitude)
      val lonDiff = math.abs(result.longitude - testCase.expectedLongitude)
      
      val success = latDiff < 1e-6 && lonDiff < 1e-6
      println(s"${testCase.name}: (lat=${result.latitude}, lon=${result.longitude}) (${if (success) "✅" else "❌"})")
      
      if (!success) {
        println(s"  Expected: lat=${testCase.expectedLatitude}, lon=${testCase.expectedLongitude}")
        println(s"  Diff: lat=$latDiff, lon=$lonDiff")
      }
    }
  }
}
