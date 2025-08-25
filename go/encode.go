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

func spreadInt32ToInt64(v uint32) uint64 {
	result := uint64(v)
	result = (result | (result << 16)) & 0x0000FFFF0000FFFF
	result = (result | (result << 8)) & 0x00FF00FF00FF00FF
	result = (result | (result << 4)) & 0x0F0F0F0F0F0F0F0F
	result = (result | (result << 2)) & 0x3333333333333333
	result = (result | (result << 1)) & 0x5555555555555555
	return result
}

func interleave(x, y uint32) uint64 {
	xSpread := spreadInt32ToInt64(x)
	ySpread := spreadInt32ToInt64(y)
	yShifted := ySpread << 1
	return xSpread | yShifted
}

func encode(latitude, longitude float64) uint64 {
	// Normalize to the range 0-2^26
	normalizedLatitude := math.Pow(2, 26) * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
	normalizedLongitude := math.Pow(2, 26) * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE

	// Truncate to integers
	latInt := uint32(normalizedLatitude)
	lonInt := uint32(normalizedLongitude)

	return interleave(latInt, lonInt)
}

type TestCase struct {
	name          string
	latitude      float64
	longitude     float64
	expectedScore uint64
}

func main() {
	testCases := []TestCase{
		{"Bangkok", 13.7220, 100.5252, 3962257306574459},
		{"Beijing", 39.9075, 116.3972, 4069885364908765},
		{"Berlin", 52.5244, 13.4105, 3673983964876493},
		{"Copenhagen", 55.6759, 12.5655, 3685973395504349},
		{"New Delhi", 28.6667, 77.2167, 3631527070936756},
		{"Kathmandu", 27.7017, 85.3206, 3639507404773204},
		{"London", 51.5074, -0.1278, 2163557714755072},
		{"New York", 40.7128, -74.0060, 1791873974549446},
		{"Paris", 48.8534, 2.3488, 3663832752681684},
		{"Sydney", -33.8688, 151.2093, 3252046221964352},
		{"Tokyo", 35.6895, 139.6917, 4171231230197045},
		{"Vienna", 48.2064, 16.3707, 3673109836391743},
	}

	for _, testCase := range testCases {
		actualScore := encode(testCase.latitude, testCase.longitude)
		success := actualScore == testCase.expectedScore
		status := "❌"
		if success {
			status = "✅"
		}
		fmt.Printf("%s: %d (%s)\n", testCase.name, actualScore, status)
	}
}
