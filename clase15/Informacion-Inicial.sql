SELECT COUNT(*) AS total_viajes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;

-- Nos preguntamos, estan limpios los datos? 
SELECT
COUNTIF(passenger_count IS NULL) AS nulos_pasajeros,
COUNTIF(trip_distance IS NULL) AS nulos_distancia,
COUNTIF(total_amount IS NULL) AS nulos_total
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;

-- Fechas que tengo a la mano
SELECT
MIN(pickup_datetime) AS fecha_min,
MAX(pickup_datetime) AS fecha_max
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;