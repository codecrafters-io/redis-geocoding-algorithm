(def min-latitude -85.05112878)
(def max-latitude 85.05112878)
(def min-longitude -180.0)
(def max-longitude 180.0)

(def latitude-range (- max-latitude min-latitude))
(def longitude-range (- max-longitude min-longitude))

(defrecord Coordinates [latitude longitude])

(defn compact-int64-to-int32 [v]
  (let [result (bit-and v 0x5555555555555555)
        result (bit-and (bit-or result (bit-shift-right result 1)) 0x3333333333333333)
        result (bit-and (bit-or result (bit-shift-right result 2)) 0x0F0F0F0F0F0F0F0F)
        result (bit-and (bit-or result (bit-shift-right result 4)) 0x00FF00FF00FF00FF)
        result (bit-and (bit-or result (bit-shift-right result 8)) 0x0000FFFF0000FFFF)]
    (int (bit-and (bit-or result (bit-shift-right result 16)) 0x00000000FFFFFFFF))))

(defn convert-grid-numbers-to-coordinates [grid-latitude-number grid-longitude-number]
  ;; Calculate the grid boundaries
  (let [grid-latitude-min (+ min-latitude (* latitude-range (/ grid-latitude-number (Math/pow 2 26))))
        grid-latitude-max (+ min-latitude (* latitude-range (/ (inc grid-latitude-number) (Math/pow 2 26))))
        grid-longitude-min (+ min-longitude (* longitude-range (/ grid-longitude-number (Math/pow 2 26))))
        grid-longitude-max (+ min-longitude (* longitude-range (/ (inc grid-longitude-number) (Math/pow 2 26))))
        
        ;; Calculate the center point of the grid cell
        latitude (/ (+ grid-latitude-min grid-latitude-max) 2)
        longitude (/ (+ grid-longitude-min grid-longitude-max) 2)]
    (->Coordinates latitude longitude)))

(defn decode [geo-code]
  ;; Align bits of both latitude and longitude to take even-numbered position
  (let [y (bit-shift-right geo-code 1)
        x geo-code
        
        ;; Compact bits back to 32-bit ints
        grid-latitude-number (compact-int64-to-int32 x)
        grid-longitude-number (compact-int64-to-int32 y)]
    (convert-grid-numbers-to-coordinates grid-latitude-number grid-longitude-number)))

(def test-cases
  [{:name "Bangkok" :expected-latitude 13.722000686932997 :expected-longitude 100.52520006895065 :score 3962257306574459}
   {:name "Beijing" :expected-latitude 39.9075003315814 :expected-longitude 116.39719873666763 :score 4069885364908765}
   {:name "Berlin" :expected-latitude 52.52439934649943 :expected-longitude 13.410500586032867 :score 3673983964876493}
   {:name "Copenhagen" :expected-latitude 55.67589927498264 :expected-longitude 12.56549745798111 :score 3685973395504349}
   {:name "New Delhi" :expected-latitude 28.666698899347338 :expected-longitude 77.21670180559158 :score 3631527070936756}
   {:name "Kathmandu" :expected-latitude 27.701700137333084 :expected-longitude 85.3205993771553 :score 3639507404773204}
   {:name "London" :expected-latitude 51.50740077990134 :expected-longitude -0.12779921293258667 :score 2163557714755072}
   {:name "New York" :expected-latitude 40.712798986951505 :expected-longitude -74.00600105524063 :score 1791873974549446}
   {:name "Paris" :expected-latitude 48.85340071224621 :expected-longitude 2.348802387714386 :score 3663832752681684}
   {:name "Sydney" :expected-latitude -33.86880091934156 :expected-longitude 151.2092998623848 :score 3252046221964352}
   {:name "Tokyo" :expected-latitude 35.68950126697936 :expected-longitude 139.691701233387 :score 4171231230197045}
   {:name "Vienna" :expected-latitude 48.20640046271915 :expected-longitude 16.370699107646942 :score 3673109836391743}])

(doseq [test-case test-cases]
  (let [result (decode (:score test-case))
        
        ;; Check if decoded coordinates are close to original (within 10e-6 precision)
        lat-diff (Math/abs (- (:latitude result) (:expected-latitude test-case)))
        lon-diff (Math/abs (- (:longitude result) (:expected-longitude test-case)))
        
        success (and (< lat-diff 0.000001) (< lon-diff 0.000001))
        status (if success "Success" "Failure")]
    (println (format "%s: (lat=%.15f, lon=%.15f) (%s)" (:name test-case) (:latitude result) (:longitude result) status))
    
    (when-not success
      (println (format "  Expected: lat=%.15f, lon=%.15f" (:expected-latitude test-case) (:expected-longitude test-case)))
      (println (format "  Diff: lat=%.6f, lon=%.6f" lat-diff lon-diff)))))
