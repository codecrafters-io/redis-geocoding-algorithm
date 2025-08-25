(def min-latitude -85.05112878)
(def max-latitude 85.05112878)
(def min-longitude -180.0)
(def max-longitude 180.0)

(def latitude-range (- max-latitude min-latitude))
(def longitude-range (- max-longitude min-longitude))

(defn spread-int32-to-int64 [v]
  (let [result (bit-and v 0xFFFFFFFF)
        result (bit-and (bit-or result (bit-shift-left result 16)) 0x0000FFFF0000FFFF)
        result (bit-and (bit-or result (bit-shift-left result 8)) 0x00FF00FF00FF00FF)
        result (bit-and (bit-or result (bit-shift-left result 4)) 0x0F0F0F0F0F0F0F0F)
        result (bit-and (bit-or result (bit-shift-left result 2)) 0x3333333333333333)]
    (bit-and (bit-or result (bit-shift-left result 1)) 0x5555555555555555)))

(defn interleave [x y]
  (let [x-spread (spread-int32-to-int64 x)
        y-spread (spread-int32-to-int64 y)
        y-shifted (bit-shift-left y-spread 1)]
    (bit-or x-spread y-shifted)))

(defn encode [latitude longitude]
  ;; Normalize to the range 0-2^26
  (let [normalized-latitude (* (Math/pow 2 26) (/ (- latitude min-latitude) latitude-range))
        normalized-longitude (* (Math/pow 2 26) (/ (- longitude min-longitude) longitude-range))
        
        ;; Truncate to integers
        lat-int (int normalized-latitude)
        lon-int (int normalized-longitude)]
    (interleave lat-int lon-int)))

(def test-cases
  [{:name "Bangkok" :latitude 13.7220 :longitude 100.5252 :expected-score 3962257306574459}
   {:name "Beijing" :latitude 39.9075 :longitude 116.3972 :expected-score 4069885364908765}
   {:name "Berlin" :latitude 52.5244 :longitude 13.4105 :expected-score 3673983964876493}
   {:name "Copenhagen" :latitude 55.6759 :longitude 12.5655 :expected-score 3685973395504349}
   {:name "New Delhi" :latitude 28.6667 :longitude 77.2167 :expected-score 3631527070936756}
   {:name "Kathmandu" :latitude 27.7017 :longitude 85.3206 :expected-score 3639507404773204}
   {:name "London" :latitude 51.5074 :longitude -0.1278 :expected-score 2163557714755072}
   {:name "New York" :latitude 40.7128 :longitude -74.0060 :expected-score 1791873974549446}
   {:name "Paris" :latitude 48.8534 :longitude 2.3488 :expected-score 3663832752681684}
   {:name "Sydney" :latitude -33.8688 :longitude 151.2093 :expected-score 3252046221964352}
   {:name "Tokyo" :latitude 35.6895 :longitude 139.6917 :expected-score 4171231230197045}
   {:name "Vienna" :latitude 48.2064 :longitude 16.3707 :expected-score 3673109836391743}])

(doseq [test-case test-cases]
  (let [actual-score (encode (:latitude test-case) (:longitude test-case))
        success (= actual-score (:expected-score test-case))
        status (if success "Success" "Failure")]
    (println (format "%s: %d (%s)" (:name test-case) actual-score status))))
