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

spreadInt32ToInt64 :: Word32 -> Word64
spreadInt32ToInt64 v = 
    let v' = fromIntegral v
        v1 = (v' .|. (v' `shiftL` 16)) .&. 0x0000FFFF0000FFFF
        v2 = (v1 .|. (v1 `shiftL` 8)) .&. 0x00FF00FF00FF00FF
        v3 = (v2 .|. (v2 `shiftL` 4)) .&. 0x0F0F0F0F0F0F0F0F
        v4 = (v3 .|. (v3 `shiftL` 2)) .&. 0x3333333333333333
    in (v4 .|. (v4 `shiftL` 1)) .&. 0x5555555555555555

interleave :: Word32 -> Word32 -> Word64
interleave x y = 
    let xSpread = spreadInt32ToInt64 x
        ySpread = spreadInt32ToInt64 y
        yShifted = ySpread `shiftL` 1
    in xSpread .|. yShifted

encode :: Double -> Double -> Word64
encode latitude longitude = 
    let -- Normalize to the range 0-2^26
        normalizedLatitude = (2 ^ 26) * (latitude - minLatitude) / latitudeRange
        normalizedLongitude = (2 ^ 26) * (longitude - minLongitude) / longitudeRange
        
        -- Truncate to integers
        latInt = truncate normalizedLatitude :: Word32
        lonInt = truncate normalizedLongitude :: Word32
    in interleave latInt lonInt

data TestCase = TestCase 
    { name :: String
    , latitude :: Double
    , longitude :: Double
    , expectedScore :: Word64
    }

testCases :: [TestCase]
testCases = 
    [ TestCase "Bangkok" 13.7220 100.5252 3962257306574459
    , TestCase "Beijing" 39.9075 116.3972 4069885364908765
    , TestCase "Berlin" 52.5244 13.4105 3673983964876493
    , TestCase "Copenhagen" 55.6759 12.5655 3685973395504349
    , TestCase "New Delhi" 28.6667 77.2167 3631527070936756
    , TestCase "Kathmandu" 27.7017 85.3206 3639507404773204
    , TestCase "London" 51.5074 (-0.1278) 2163557714755072
    , TestCase "New York" 40.7128 (-74.0060) 1791873974549446
    , TestCase "Paris" 48.8534 2.3488 3663832752681684
    , TestCase "Sydney" (-33.8688) 151.2093 3252046221964352
    , TestCase "Tokyo" 35.6895 139.6917 4171231230197045
    , TestCase "Vienna" 48.2064 16.3707 3673109836391743
    ]

main :: IO ()
main = do
    mapM_ runTest testCases
  where
    runTest testCase = do
        let actualScore = encode (latitude testCase) (longitude testCase)
            success = actualScore == expectedScore testCase
            status = if success then "✅" else "❌"
        putStrLn $ name testCase ++ ": " ++ show actualScore ++ " (" ++ status ++ ")"
