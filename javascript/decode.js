const MIN_LATITUDE = -85.05112878;
const MAX_LATITUDE = 85.05112878;
const MIN_LONGITUDE = -180.0;
const MAX_LONGITUDE = 180.0;

const LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE;
const LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE;

class Coordinates {
    constructor(latitude, longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }
}

function compactInt64ToInt32(v) {
    v = v & 0x5555555555555555n;
    v = (v | (v >> 1n)) & 0x3333333333333333n;
    v = (v | (v >> 2n)) & 0x0F0F0F0F0F0F0F0Fn;
    v = (v | (v >> 4n)) & 0x00FF00FF00FF00FFn;
    v = (v | (v >> 8n)) & 0x0000FFFF0000FFFFn;
    v = (v | (v >> 16n)) & 0x00000000FFFFFFFFn;
    return Number(v);
}

function convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber) {
    // Calculate the grid boundaries
    const gridLatitudeMin = MIN_LATITUDE + LATITUDE_RANGE * (gridLatitudeNumber / Math.pow(2, 26));
    const gridLatitudeMax = MIN_LATITUDE + LATITUDE_RANGE * ((gridLatitudeNumber + 1) / Math.pow(2, 26));
    const gridLongitudeMin = MIN_LONGITUDE + LONGITUDE_RANGE * (gridLongitudeNumber / Math.pow(2, 26));
    const gridLongitudeMax = MIN_LONGITUDE + LONGITUDE_RANGE * ((gridLongitudeNumber + 1) / Math.pow(2, 26));
    
    // Calculate the center point of the grid cell
    const latitude = (gridLatitudeMin + gridLatitudeMax) / 2;
    const longitude = (gridLongitudeMin + gridLongitudeMax) / 2;
    
    return new Coordinates(latitude, longitude);
}

function decode(geoCode) {
    // Align bits of both latitude and longitude to take even-numbered position
    const y = geoCode >> 1n;
    const x = geoCode;
    
    // Compact bits back to 32-bit ints
    const gridLatitudeNumber = compactInt64ToInt32(x);
    const gridLongitudeNumber = compactInt64ToInt32(y);
    
    return convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber);
}

const testCases = [
    { name: "Bangkok", expectedLatitude: 13.722000686932997, expectedLongitude: 100.52520006895065, score: 3962257306574459n },
    { name: "Beijing", expectedLatitude: 39.9075003315814, expectedLongitude: 116.39719873666763, score: 4069885364908765n },
    { name: "Berlin", expectedLatitude: 52.52439934649943, expectedLongitude: 13.410500586032867, score: 3673983964876493n },
    { name: "Copenhagen", expectedLatitude: 55.67589927498264, expectedLongitude: 12.56549745798111, score: 3685973395504349n },
    { name: "New Delhi", expectedLatitude: 28.666698899347338, expectedLongitude: 77.21670180559158, score: 3631527070936756n },
    { name: "Kathmandu", expectedLatitude: 27.701700137333084, expectedLongitude: 85.3205993771553, score: 3639507404773204n },
    { name: "London", expectedLatitude: 51.50740077990134, expectedLongitude: -0.12779921293258667, score: 2163557714755072n },
    { name: "New York", expectedLatitude: 40.712798986951505, expectedLongitude: -74.00600105524063, score: 1791873974549446n },
    { name: "Paris", expectedLatitude: 48.85340071224621, expectedLongitude: 2.348802387714386, score: 3663832752681684n },
    { name: "Sydney", expectedLatitude: -33.86880091934156, expectedLongitude: 151.2092998623848, score: 3252046221964352n },
    { name: "Tokyo", expectedLatitude: 35.68950126697936, expectedLongitude: 139.691701233387, score: 4171231230197045n },
    { name: "Vienna", expectedLatitude: 48.20640046271915, expectedLongitude: 16.370699107646942, score: 3673109836391743n }
];

for (const testCase of testCases) {
    const result = decode(testCase.score);
    
    // Check if decoded coordinates are close to original (within 10e-6 precision)
    const latDiff = Math.abs(result.latitude - testCase.expectedLatitude);
    const lonDiff = Math.abs(result.longitude - testCase.expectedLongitude);
    
    const success = latDiff < 1e-6 && lonDiff < 1e-6;
    console.log(`${testCase.name}: (lat=${result.latitude}, lon=${result.longitude}) (${success ? "✅" : "❌"})`);
    
    if (!success) {
        console.log(`  Expected: lat=${testCase.expectedLatitude}, lon=${testCase.expectedLongitude}`);
        console.log(`  Diff: lat=${latDiff}, lon=${lonDiff}`);
    }
}
