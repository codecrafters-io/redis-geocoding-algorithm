const MIN_LATITUDE = -85.05112878;
const MAX_LATITUDE = 85.05112878;
const MIN_LONGITUDE = -180.0;
const MAX_LONGITUDE = 180.0;

const LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
const LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

function spreadInt32ToInt64(v) {
    let result = BigInt(v) & 0xFFFFFFFFn;
    result = (result | (result << 16n)) & 0x0000FFFF0000FFFFn;
    result = (result | (result << 8n)) & 0x00FF00FF00FF00FFn;
    result = (result | (result << 4n)) & 0x0F0F0F0F0F0F0F0Fn;
    result = (result | (result << 2n)) & 0x3333333333333333n;
    result = (result | (result << 1n)) & 0x5555555555555555n;
    return result;
}

function interleave(x, y) {
    const xSpread = spreadInt32ToInt64(x);
    const ySpread = spreadInt32ToInt64(y);
    const yShifted = ySpread << 1n;
    return xSpread | yShifted;
}

function encode(latitude, longitude) {
    // Normalize to the range 0-2^26
    const normalizedLatitude = Math.pow(2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE;
    const normalizedLongitude = Math.pow(2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE;

    // Truncate to integers
    const latInt = Math.floor(normalizedLatitude);
    const lonInt = Math.floor(normalizedLongitude);

    return interleave(latInt, lonInt);
}

const testCases = [
    { name: "Bangkok", latitude: 13.7220, longitude: 100.5252, expectedScore: 3962257306574459n },
    { name: "Beijing", latitude: 39.9075, longitude: 116.3972, expectedScore: 4069885364908765n },
    { name: "Berlin", latitude: 52.5244, longitude: 13.4105, expectedScore: 3673983964876493n },
    { name: "Copenhagen", latitude: 55.6759, longitude: 12.5655, expectedScore: 3685973395504349n },
    { name: "New Delhi", latitude: 28.6667, longitude: 77.2167, expectedScore: 3631527070936756n },
    { name: "Kathmandu", latitude: 27.7017, longitude: 85.3206, expectedScore: 3639507404773204n },
    { name: "London", latitude: 51.5074, longitude: -0.1278, expectedScore: 2163557714755072n },
    { name: "New York", latitude: 40.7128, longitude: -74.0060, expectedScore: 1791873974549446n },
    { name: "Paris", latitude: 48.8534, longitude: 2.3488, expectedScore: 3663832752681684n },
    { name: "Sydney", latitude: -33.8688, longitude: 151.2093, expectedScore: 3252046221964352n },
    { name: "Tokyo", latitude: 35.6895, longitude: 139.6917, expectedScore: 4171231230197045n },
    { name: "Vienna", latitude: 48.2064, longitude: 16.3707, expectedScore: 3673109836391743n }
];

for (const testCase of testCases) {
    const actualScore = encode(testCase.latitude, testCase.longitude);
    const success = actualScore === testCase.expectedScore;
    console.log(`${testCase.name}: ${actualScore} (${success ? "✅" : "❌"})`);
}
