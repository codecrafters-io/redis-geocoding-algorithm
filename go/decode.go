package main

import (
	"fmt"
	"math"
)

const (
	MIN_LATITUDE  = -85.05112878
	MAX_LATITUDE  = 85.05112878
	MIN_LONGITUDE = -180.0
	MAX_LONGITUDE = 180.0

	LATITUDE_RANGE  = MAX_LATITUDE - MIN_LATITUDE
	LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE
)

type Coordinates struct {
	Latitude  float64
	Longitude float64
}

func compactInt64ToInt32(v uint64) uint32 {
	result := v & 0x5555555555555555
	result = (result | (result >> 1)) & 0x3333333333333333
	result = (result | (result >> 2)) & 0x0F0F0F0F0F0F0F0F
	result = (result | (result >> 4)) & 0x00FF00FF00FF00FF
	result = (result | (result >> 8)) & 0x0000FFFF0000FFFF
	result = (result | (result >> 16)) & 0x00000000FFFFFFFF
	return uint32(result)
}

func convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber uint32) Coordinates {
	// Calculate the grid boundaries
	gridLatitudeMin := MIN_LATITUDE + LATITUDE_RANGE*(float64(gridLatitudeNumber)/math.Pow(2, 26))
	gridLatitudeMax := MIN_LATITUDE + LATITUDE_RANGE*(float64(gridLatitudeNumber+1)/math.Pow(2, 26))
	gridLongitudeMin := MIN_LONGITUDE + LONGITUDE_RANGE*(float64(gridLongitudeNumber)/math.Pow(2, 26))
	gridLongitudeMax := MIN_LONGITUDE + LONGITUDE_RANGE*(float64(gridLongitudeNumber+1)/math.Pow(2, 26))

	// Calculate the center point of the grid cell
	latitude := (gridLatitudeMin + gridLatitudeMax) / 2
	longitude := (gridLongitudeMin + gridLongitudeMax) / 2

	return Coordinates{Latitude: latitude, Longitude: longitude}
}

func decode(geoCode uint64) Coordinates {
	// Align bits of both latitude and longitude to take even-numbered position
	y := geoCode >> 1
	x := geoCode

	// Compact bits back to 32-bit ints
	gridLatitudeNumber := compactInt64ToInt32(x)
	gridLongitudeNumber := compactInt64ToInt32(y)

	return convertGridNumbersToCoordinates(gridLatitudeNumber, gridLongitudeNumber)
}

type TestCase struct {
	name              string
	expectedLatitude  float64
	expectedLongitude float64
	score             uint64
}

func main() {
	testCases := []TestCase{
		{"Bangkok", 13.722000686932997, 100.52520006895065, 3962257306574459},
		{"Beijing", 39.9075003315814, 116.39719873666763, 4069885364908765},
		{"Berlin", 52.52439934649943, 13.410500586032867, 3673983964876493},
		{"Copenhagen", 55.67589927498264, 12.56549745798111, 3685973395504349},
		{"New Delhi", 28.666698899347338, 77.21670180559158, 3631527070936756},
		{"Kathmandu", 27.701700137333084, 85.3205993771553, 3639507404773204},
		{"London", 51.50740077990134, -0.12779921293258667, 2163557714755072},
		{"New York", 40.712798986951505, -74.00600105524063, 1791873974549446},
		{"Paris", 48.85340071224621, 2.348802387714386, 3663832752681684},
		{"Sydney", -33.86880091934156, 151.2092998623848, 3252046221964352},
		{"Tokyo", 35.68950126697936, 139.691701233387, 4171231230197045},
		{"Vienna", 48.20640046271915, 16.370699107646942, 3673109836391743},
	}

	for _, testCase := range testCases {
		result := decode(testCase.score)

		// Check if decoded coordinates are close to original (within 10e-6 precision)
		latDiff := math.Abs(result.Latitude - testCase.expectedLatitude)
		lonDiff := math.Abs(result.Longitude - testCase.expectedLongitude)

		success := latDiff < 0.000001 && lonDiff < 0.000001
		status := "❌"
		if success {
			status = "✅"
		}
		fmt.Printf("%s: (lat=%.15f, lon=%.15f) (%s)\n", testCase.name, result.Latitude, result.Longitude, status)

		if !success {
			fmt.Printf("  Expected: lat=%.15f, lon=%.15f\n", testCase.expectedLatitude, testCase.expectedLongitude)
			fmt.Printf("  Diff: lat=%.6f, lon=%.6f\n", latDiff, lonDiff)
		}
	}
}
