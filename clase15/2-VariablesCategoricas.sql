-- VARIABLES CATEGORICAS 

SELECT
  payment_type,
  COUNT(*) AS total_viajes 
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` 
GROUP BY payment_type
ORDER BY total_viajes DESC;

SELECT
  passenger_count,
  COUNT(*) AS total_viajes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
GROUP BY passenger_count
ORDER BY passenger_count;

SELECT
  AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)) AS avg_duration_min,
  MIN(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)) AS min_duration_min,
  MAX(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)) AS max_duration_min
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE dropoff_datetime IS NOT NULL
  AND pickup_datetime IS NOT NULL;
