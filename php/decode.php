<?php

define('MIN_LATITUDE', -85.05112878);
define('MAX_LATITUDE', 85.05112878);
define('MIN_LONGITUDE', -180.0);
define('MAX_LONGITUDE', 180.0);

define('LATITUDE_RANGE', MAX_LATITUDE - MIN_LATITUDE);
define('LONGITUDE_RANGE', MAX_LONGITUDE - MIN_LONGITUDE);

class Coordinates {
    public $latitude;
    public $longitude;
    
    public function __construct($latitude, $longitude) {
        $this->latitude = $latitude;
        $this->longitude = $longitude;
    }
}

function compactInt64ToInt32($v) {
    $v = $v & 0x5555555555555555;
    $v = ($v | ($v >> 1)) & 0x3333333333333333;
    $v = ($v | ($v >> 2)) & 0x0F0F0F0F0F0F0F0F;
    $v = ($v | ($v >> 4)) & 0x00FF00FF00FF00FF;
    $v = ($v | ($v >> 8)) & 0x0000FFFF0000FFFF;
    $v = ($v | ($v >> 16)) & 0x00000000FFFFFFFF;
    return (int)$v;
}

function convertGridNumbersToCoordinates($gridLatitudeNumber, $gridLongitudeNumber) {
    // Calculate the grid boundaries
    $gridLatitudeMin = MIN_LATITUDE + LATITUDE_RANGE * ($gridLatitudeNumber / pow(2, 26));
    $gridLatitudeMax = MIN_LATITUDE + LATITUDE_RANGE * (($gridLatitudeNumber + 1) / pow(2, 26));
    $gridLongitudeMin = MIN_LONGITUDE + LONGITUDE_RANGE * ($gridLongitudeNumber / pow(2, 26));
    $gridLongitudeMax = MIN_LONGITUDE + LONGITUDE_RANGE * (($gridLongitudeNumber + 1) / pow(2, 26));
    
    // Calculate the center point of the grid cell
    $latitude = ($gridLatitudeMin + $gridLatitudeMax) / 2;
    $longitude = ($gridLongitudeMin + $gridLongitudeMax) / 2;
    
    return new Coordinates($latitude, $longitude);
}

function decode($geoCode) {
    // Align bits of both latitude and longitude to take even-numbered position
    $y = $geoCode >> 1;
    $x = $geoCode;
    
    // Compact bits back to 32-bit ints
    $gridLatitudeNumber = compactInt64ToInt32($x);
    $gridLongitudeNumber = compactInt64ToInt32($y);
    
    return convertGridNumbersToCoordinates($gridLatitudeNumber, $gridLongitudeNumber);
}

$testCases = [
    ['name' => 'Bangkok', 'expectedLatitude' => 13.722000686932997, 'expectedLongitude' => 100.52520006895065, 'score' => 3962257306574459],
    ['name' => 'Beijing', 'expectedLatitude' => 39.9075003315814, 'expectedLongitude' => 116.39719873666763, 'score' => 4069885364908765],
    ['name' => 'Berlin', 'expectedLatitude' => 52.52439934649943, 'expectedLongitude' => 13.410500586032867, 'score' => 3673983964876493],
    ['name' => 'Copenhagen', 'expectedLatitude' => 55.67589927498264, 'expectedLongitude' => 12.56549745798111, 'score' => 3685973395504349],
    ['name' => 'New Delhi', 'expectedLatitude' => 28.666698899347338, 'expectedLongitude' => 77.21670180559158, 'score' => 3631527070936756],
    ['name' => 'Kathmandu', 'expectedLatitude' => 27.701700137333084, 'expectedLongitude' => 85.3205993771553, 'score' => 3639507404773204],
    ['name' => 'London', 'expectedLatitude' => 51.50740077990134, 'expectedLongitude' => -0.12779921293258667, 'score' => 2163557714755072],
    ['name' => 'New York', 'expectedLatitude' => 40.712798986951505, 'expectedLongitude' => -74.00600105524063, 'score' => 1791873974549446],
    ['name' => 'Paris', 'expectedLatitude' => 48.85340071224621, 'expectedLongitude' => 2.348802387714386, 'score' => 3663832752681684],
    ['name' => 'Sydney', 'expectedLatitude' => -33.86880091934156, 'expectedLongitude' => 151.2092998623848, 'score' => 3252046221964352],
    ['name' => 'Tokyo', 'expectedLatitude' => 35.68950126697936, 'expectedLongitude' => 139.691701233387, 'score' => 4171231230197045],
    ['name' => 'Vienna', 'expectedLatitude' => 48.20640046271915, 'expectedLongitude' => 16.370699107646942, 'score' => 3673109836391743]
];

foreach ($testCases as $testCase) {
    $result = decode($testCase['score']);
    
    // Check if decoded coordinates are close to original (within 10e-6 precision)
    $latDiff = abs($result->latitude - $testCase['expectedLatitude']);
    $lonDiff = abs($result->longitude - $testCase['expectedLongitude']);
    
    $success = $latDiff < 0.000001 && $lonDiff < 0.000001;
    $status = $success ? "✅" : "❌";
    printf("%s: (lat=%.15f, lon=%.15f) (%s)\n", $testCase['name'], $result->latitude, $result->longitude, $status);
    
    if (!$success) {
        printf("  Expected: lat=%.15f, lon=%.15f\n", $testCase['expectedLatitude'], $testCase['expectedLongitude']);
        printf("  Diff: lat=%.6f, lon=%.6f\n", $latDiff, $lonDiff);
    }
}

?>
