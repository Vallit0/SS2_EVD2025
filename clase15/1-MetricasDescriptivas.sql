-- Analisis Descriptivo

SELECT
  AVG(trip_distance) AS distancia_promedio,
  AVG(fare_amount) AS tarifa_promedio,
  AVG(tip_amount) AS propina_promedio,
  AVG(total_amount) AS total_promedio
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;


SELECT
  AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, HOUR)) AS duracion_min_promedio
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE dropoff_datetime IS NOT NULL;
