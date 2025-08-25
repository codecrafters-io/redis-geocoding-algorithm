<?php

define('MIN_LATITUDE', -85.05112878);
define('MAX_LATITUDE', 85.05112878);
define('MIN_LONGITUDE', -180.0);
define('MAX_LONGITUDE', 180.0);

define('LATITUDE_RANGE', MAX_LATITUDE - MIN_LATITUDE);
define('LONGITUDE_RANGE', MAX_LONGITUDE - MIN_LONGITUDE);

function spreadInt32ToInt64($v) {
    $result = $v & 0xFFFFFFFF;
    $result = ($result | ($result << 16)) & 0x0000FFFF0000FFFF;
    $result = ($result | ($result << 8)) & 0x00FF00FF00FF00FF;
    $result = ($result | ($result << 4)) & 0x0F0F0F0F0F0F0F0F;
    $result = ($result | ($result << 2)) & 0x3333333333333333;
    $result = ($result | ($result << 1)) & 0x5555555555555555;
    return $result;
}

function interleave($x, $y) {
    $xSpread = spreadInt32ToInt64($x);
    $ySpread = spreadInt32ToInt64($y);
    $yShifted = $ySpread << 1;
    return $xSpread | $yShifted;
}

function encode($latitude, $longitude) {
    // Normalize to the range 0-2^26
    $normalizedLatitude = pow(2, 26) * ($latitude - MIN_LATITUDE) / LATITUDE_RANGE;
    $normalizedLongitude = pow(2, 26) * ($longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

    // Truncate to integers
    $latInt = (int)$normalizedLatitude;
    $lonInt = (int)$normalizedLongitude;

    return interleave($latInt, $lonInt);
}

$testCases = [
    ['name' => 'Bangkok', 'latitude' => 13.7220, 'longitude' => 100.5252, 'expectedScore' => 3962257306574459],
    ['name' => 'Beijing', 'latitude' => 39.9075, 'longitude' => 116.3972, 'expectedScore' => 4069885364908765],
    ['name' => 'Berlin', 'latitude' => 52.5244, 'longitude' => 13.4105, 'expectedScore' => 3673983964876493],
    ['name' => 'Copenhagen', 'latitude' => 55.6759, 'longitude' => 12.5655, 'expectedScore' => 3685973395504349],
    ['name' => 'New Delhi', 'latitude' => 28.6667, 'longitude' => 77.2167, 'expectedScore' => 3631527070936756],
    ['name' => 'Kathmandu', 'latitude' => 27.7017, 'longitude' => 85.3206, 'expectedScore' => 3639507404773204],
    ['name' => 'London', 'latitude' => 51.5074, 'longitude' => -0.1278, 'expectedScore' => 2163557714755072],
    ['name' => 'New York', 'latitude' => 40.7128, 'longitude' => -74.0060, 'expectedScore' => 1791873974549446],
    ['name' => 'Paris', 'latitude' => 48.8534, 'longitude' => 2.3488, 'expectedScore' => 3663832752681684],
    ['name' => 'Sydney', 'latitude' => -33.8688, 'longitude' => 151.2093, 'expectedScore' => 3252046221964352],
    ['name' => 'Tokyo', 'latitude' => 35.6895, 'longitude' => 139.6917, 'expectedScore' => 4171231230197045],
    ['name' => 'Vienna', 'latitude' => 48.2064, 'longitude' => 16.3707, 'expectedScore' => 3673109836391743]
];

foreach ($testCases as $testCase) {
    $actualScore = encode($testCase['latitude'], $testCase['longitude']);
    $success = $actualScore == $testCase['expectedScore'];
    $status = $success ? "✅" : "❌";
    echo "{$testCase['name']}: $actualScore ($status)\n";
}

?>
