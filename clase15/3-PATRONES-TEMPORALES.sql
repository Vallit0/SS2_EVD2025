-- Deteccion de Patrones Temporales  
-- MES 
SELECT 
 EXTRACT(MONTH FROM pickup_datetime) AS mes, 
 COUNT(*) AS total_viajes 
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
GROUP BY mes 
ORDER BY mes; 

-- DIA 
SELECT 
 EXTRACT(DAYOFWEEK FROM pickup_datetime) AS dia_semana, 
 COUNT(*) AS total_viajes 
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
GROUP BY dia_semana 
ORDER BY dia_semana;

-- DIA 
SELECT 
 EXTRACT(HOUR FROM pickup_datetime) AS horita, 
 COUNT(*) AS total_viajes 
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
GROUP BY horita 
ORDER BY horita;

