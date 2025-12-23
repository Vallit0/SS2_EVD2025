CREATE OR REPLACE TABLE `seminario-sistemas-2-481502.nyc_taxi.yellow_2022_subset` AS
SELECT
  pickup_datetime,
  dropoff_datetime,
  pickup_location_id,
  dropoff_location_id,
  passenger_count,
  trip_distance,
  fare_amount,
  tip_amount,
  total_amount,
  payment_type
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE pickup_datetime IS NOT NULL
  AND dropoff_datetime IS NOT NULL;



-- Tabla derivada limpia partida de fechas
CREATE OR REPLACE TABLE `seminario-sistemas-2-481502.nyc_taxi.yellow_2022_clean` AS
SELECT
  pickup_datetime,
  dropoff_datetime,
  DATE(pickup_datetime) AS pickup_date,
  EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,
  EXTRACT(DAYOFWEEK FROM pickup_datetime) AS pickup_dow,
  EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,

  pickup_location_id,
  dropoff_location_id,

  passenger_count,
  trip_distance,
  fare_amount,
  tip_amount,
  total_amount,
  payment_type,

  TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS duration_min,

FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE pickup_datetime IS NOT NULL
  AND dropoff_datetime IS NOT NULL;

-- Clustering y Particiones
CREATE OR REPLACE TABLE `seminario-sistemas-2-481502.nyc_taxi.yellow_2022_opt`
PARTITION BY DATE(pickup_datetime)
CLUSTER BY pickup_location_id, dropoff_location_id AS
SELECT
  pickup_datetime,
  dropoff_datetime,

  pickup_location_id,
  dropoff_location_id,

  passenger_count,
  trip_distance,
  fare_amount,
  tip_amount,
  total_amount,
  payment_type,

  TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS duration_min
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE pickup_datetime IS NOT NULL
  AND dropoff_datetime IS NOT NULL;


-- SIN PARTICIONES 
SELECT
  AVG(total_amount) AS avg_total
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE pickup_location_id = "161"
  AND DATE(pickup_datetime) BETWEEN '2022-06-01' AND '2022-06-30';

-- OPTIMIZADO (PARTICIONES)
SELECT
  AVG(total_amount) AS avg_total
FROM `seminario-sistemas-2-481502.nyc_taxi.yellow_2022_opt`
WHERE pickup_location_id = "161"
  AND pickup_datetime BETWEEN '2022-06-01' AND '2022-06-30';


-- O(1)
SELECT
  pickup_location_id,
  COUNT(*) AS viajes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE pickup_location_id = "1"
GROUP BY pickup_location_id;









