SELECT
  column_name,
  data_type,
  description
FROM `bigquery-public-data.new_york_taxi_trips.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'tlc_yellow_trips_2022'
  AND column_name = 'payment_type';
