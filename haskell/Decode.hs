module Main where

import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import Data.Word (Word32, Word64)

minLatitude :: Double
minLatitude = -85.05112878

maxLatitude :: Double
maxLatitude = 85.05112878

minLongitude :: Double
minLongitude = -180.0

maxLongitude :: Double
maxLongitude = 180.0

latitudeRange :: Double
latitudeRange = maxLatitude - minLatitude

longitudeRange :: Double
longitudeRange = maxLongitude - minLongitude

data Coordinates = Coordinates 
    { latitude :: Double
    , longitude :: Double
    }

compactInt64ToInt32 :: Word64 -> Word32
compactInt64ToInt32 v = 
    let v1 = v .&. 0x5555555555555555
        v2 = (v1 .|. (v1 `shiftR` 1)) .&. 0x3333333333333333
        v3 = (v2 .|. (v2 `shiftR` 2)) .&. 0x0F0F0F0F0F0F0F0F
        v4 = (v3 .|. (v3 `shiftR` 4)) .&. 0x00FF00FF00FF00FF
        v5 = (v4 .|. (v4 `shiftR` 8)) .&. 0x0000FFFF0000FFFF
    in fromIntegral $ (v5 .|. (v5 `shiftR` 16)) .&. 0x00000000FFFFFFFF

convertGridNumbersToCoordinates :: Word32 -> Word32 -> Coordinates
convertGridNumbersToCoordinates gridLatitudeNumber gridLongitudeNumber = 
    let -- Calculate the grid boundaries
        gridLatitudeMin = minLatitude + latitudeRange * (fromIntegral gridLatitudeNumber / (2 ^ 26))
        gridLatitudeMax = minLatitude + latitudeRange * (fromIntegral (gridLatitudeNumber + 1) / (2 ^ 26))
        gridLongitudeMin = minLongitude + longitudeRange * (fromIntegral gridLongitudeNumber / (2 ^ 26))
        gridLongitudeMax = minLongitude + longitudeRange * (fromIntegral (gridLongitudeNumber + 1) / (2 ^ 26))
        
        -- Calculate the center point of the grid cell
        lat = (gridLatitudeMin + gridLatitudeMax) / 2
        lon = (gridLongitudeMin + gridLongitudeMax) / 2
    in Coordinates lat lon

decode :: Word64 -> Coordinates
decode geoCode = 
    let -- Align bits of both latitude and longitude to take even-numbered position
        y = geoCode `shiftR` 1
        x = geoCode
        
        -- Compact bits back to 32-bit ints
        gridLatitudeNumber = compactInt64ToInt32 x
        gridLongitudeNumber = compactInt64ToInt32 y
    in convertGridNumbersToCoordinates gridLatitudeNumber gridLongitudeNumber

data TestCase = TestCase 
    { name :: String
    , expectedLatitude :: Double
    , expectedLongitude :: Double
    , score :: Word64
    }

testCases :: [TestCase]
testCases = 
    [ TestCase "Bangkok" 13.722000686932997 100.52520006895065 3962257306574459
    , TestCase "Beijing" 39.9075003315814 116.39719873666763 4069885364908765
    , TestCase "Berlin" 52.52439934649943 13.410500586032867 3673983964876493
    , TestCase "Copenhagen" 55.67589927498264 12.56549745798111 3685973395504349
    , TestCase "New Delhi" 28.666698899347338 77.21670180559158 3631527070936756
    , TestCase "Kathmandu" 27.701700137333084 85.3205993771553 3639507404773204
    , TestCase "London" 51.50740077990134 (-0.12779921293258667) 2163557714755072
    , TestCase "New York" 40.712798986951505 (-74.00600105524063) 1791873974549446
    , TestCase "Paris" 48.85340071224621 2.348802387714386 3663832752681684
    , TestCase "Sydney" (-33.86880091934156) 151.2092998623848 3252046221964352
    , TestCase "Tokyo" 35.68950126697936 139.691701233387 4171231230197045
    , TestCase "Vienna" 48.20640046271915 16.370699107646942 3673109836391743
    ]

main :: IO ()
main = do
    mapM_ runTest testCases
  where
    runTest testCase = do
        let result = decode (score testCase)
            -- Check if decoded coordinates are close to original (within 10e-6 precision)
            latDiff = abs (latitude result - expectedLatitude testCase)
            lonDiff = abs (longitude result - expectedLongitude testCase)
            success = latDiff < 0.000001 && lonDiff < 0.000001
            status = if success then "✅" else "❌"
        putStrLn $ name testCase ++ ": (lat=" ++ show (latitude result) ++ ", lon=" ++ show (longitude result) ++ ") (" ++ status ++ ")"
        
        if not success
            then do
                putStrLn $ "  Expected: lat=" ++ show (expectedLatitude testCase) ++ ", lon=" ++ show (expectedLongitude testCase)
                putStrLn $ "  Diff: lat=" ++ show latDiff ++ ", lon=" ++ show lonDiff
            else return ()
