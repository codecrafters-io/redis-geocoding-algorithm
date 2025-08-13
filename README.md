Redis converts Geospatial data (latitude and longitude) into a single "score" value so that it can be stored in a [Sorted Set](https://redis.io/docs/latest/develop/data-types/sorted-sets/).

This repository explains the algorithm used for this conversion.

# Encoding

Encoding is a 3-step process.

1. Latitude and longitude are normalized to the [0, 2^26) range
2. The normalized values are truncated to integers (i.e. the decimal part is dropped)
3. The bits of the normalized latitude and longitude values are interleaved to get a 52-bit integer value

## Step 1: Normalization

The values of latitude and longitude are normalized to values in the [0, 2^26) range.

The official Redis source code implements this in [geohash.c](https://github.com/redis/redis/blob/ff2f0b092c24d5cc590ff1eb596fc0865e0fb721/src/geohash.c#L141-L148).

Here's some pseudocode illustrating how this is done:

```python
MIN_LATITUDE = -85.05112878
MAX_LATITUDE = 85.05112878
MIN_LONGITUDE = -180
MAX_LONGITUDE = 180

LATITUDE_RANGE = MAX_LATITUDE - MIN_LATITUDE
LONGITUDE_RANGE = MAX_LONGITUDE - MIN_LONGITUDE

normalized_latitude = 2^26 * (latitude - MIN_LATITUDE) / LATITUDE_RANGE
normalized_longitude = 2^26 * (longitude - MIN_LONGITUDE) / LONGITUDE_RANGE
```

> [!NOTE]
> The latitude range Redis accepts is +/-85.05° and not +/-90°. This is because of the [Web Mercator projection](https://en.wikipedia.org/wiki/Web_Mercator_projection) used to project the Earth onto a 2D plane.

These intermediate values are combined in the next steps to calculate a "score".

## Step 2: Truncation

The normalized values (floats) are truncated to integers (i.e. the decimal part is dropped).

In the Redis source code, this conversion happens implicitly when the `double` values are casted to `uint32_t` [here](https://github.com/redis/redis/blob/ff2f0b092c24d5cc590ff1eb596fc0865e0fb721/src/geohash.c#L149).

In Python, this conversion can be done explicitly using the `int()` function:

```python
normalized_latitude = int(normalized_latitude)
normalized_longitude = int(normalized_longitude)
```

## Step 3: Interleaving

The bits of the normalized latitude and longitude values are then interleaved to get a 64-bit integer value.

In the Redis source code, this is done in the [`interleave64` function](https://github.com/redis/redis/blob/eac48279ad21b8612038953fefa0dcf926773efc/src/geohash.c#L52-L77).

Here's some pseudocode illustrating how this is done:

```python
def interleave(x: int, y: int) -> int:
    # First, the values are spread from 32-bit to 64-bit integers.
    # This is done by inserting 32 zero bits in-between.
    #
    # Before spread: x1  x2  ...  x31  x32
    # After spread:  0   x1  ...   0   x16  ... 0  x31  0  x32
    x = spread_int32_to_int64(x)
    y = spread_int32_to_int64(y)

    # The y value is then shifted 1 bit to the left.
    # Before shift: 0   y1   0   y2 ... 0   y31   0   y32
    # After shift:  y1   0   y2 ... 0   y31   0   y32   0
    y_shifted = y << 1

    # Next, x and y_shifted are combined using a bitwise OR.
    #
    # Before bitwise OR (x): 0   x1   0   x2   ...  0   x31    0   x32
    # Before bitwise OR (y): y1  0    y2  0    ...  y31  0    y32   0
    # After bitwise OR     : y1  x2   y2  x2   ...  y31  x31  y32  x32
    return x | y_shifted

# Spreads a 32-bit integer to a 64-bit integer by inserting
# 32 zero bits in-between.
#
# Before spread: x1  x2  ...  x31  x32
# After spread:  0   x1  ...   0   x16  ... 0  x31  0  x32
def spread_int32_to_int64(v: int) -> int:
    # Ensure only lower 32 bits are non-zero.
    v = v & 0xFFFFFFFF

    # Bitwise operations to spread 32 bits into 64 bits with zeros in-between
    v = (v | (v << 16)) & 0x0000FFFF0000FFFF
    v = (v | (v << 8))  & 0x00FF00FF00FF00FF
    v = (v | (v << 4))  & 0x0F0F0F0F0F0F0F0F
    v = (v | (v << 2))  & 0x3333333333333333
    v = (v | (v << 1))  & 0x5555555555555555

    return v

score = interleave(normalized_latitude, normalized_longitude)
```

# Decoding

Decoding essentially does the reverse of encoding.

**TODO**: Add decoding pseudocode

# FAQ

#### Why is the latitude range from -85.05112878 to 85.05112878 and not -90 to 90?

This is because of the [Web Mercator projection](https://en.wikipedia.org/wiki/Web_Mercator_projection) used to project the Earth onto a 2D plane.

#### Why are the latitude and longitude normalized to 26-bit integers instead of 32-bit integers?

In [sorted sets](https://redis.io/docs/latest/data-types/sorted-sets/), scores are stored as [float64](https://en.wikipedia.org/wiki/Double-precision_floating-point_format) numbers. Float64 values have limits on integer precision. They [can represent integers upto 2^53 accurately](https://en.wikipedia.org/wiki/Double-precision_floating-point_format#Precision_limitations_on_integer_values) but start to lose precision after that. Using 26-bit integers ensures that the final score is under 2^52 and thus within the integer precision limits of float64.

#### How do I test my implementation?

Here are some example values to test your implementation against:

| Place    | Latitude | Longitude | Score      |
| -------- | -------- | --------- | ---------- |
| New York | 40.7128  | -74.0060  | 1234567890 |
| London   | 51.5074  | -0.1278   | 1234567890 |
| Tokyo    | 35.6895  | 139.6917  | 1234567890 |
| Sydney   | -33.8688 | 151.2093  | 1234567890 |

(**TODO**: Fill in the values)
