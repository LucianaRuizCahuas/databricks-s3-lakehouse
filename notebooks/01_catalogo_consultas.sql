-- Databricks notebook source
-- Actividad: catalog.schema.tabla, capas Silver y Gold.
-- Estado: codigo preparado; ejecutar en el workspace y guardar resultados.
-- Este notebook usa datos de muestra. La conexion real S3 esta en 02_s3.py.
CREATE CATALOG IF NOT EXISTS actividad_luciana;
CREATE SCHEMA IF NOT EXISTS actividad_luciana.silver;
CREATE SCHEMA IF NOT EXISTS actividad_luciana.gold;

-- COMMAND ----------
-- Tabla de demostracion: NO es una conexion S3 propia.
CREATE TABLE IF NOT EXISTS actividad_luciana.silver.viajes_demo
USING DELTA
COMMENT 'Muestra NYC Taxi; limpiar y tipar para analisis Silver'
AS SELECT DISTINCT
  CAST(tpep_pickup_datetime AS TIMESTAMP) AS fecha_recogida,
  CAST(tpep_dropoff_datetime AS TIMESTAMP) AS fecha_llegada,
  CAST(trip_distance AS DOUBLE) AS distancia_millas,
  CAST(fare_amount AS DECIMAL(18,2)) AS tarifa,
  CAST(pickup_zip AS STRING) AS zona_origen,
  CAST(dropoff_zip AS STRING) AS zona_destino
FROM samples.nyctaxi.trips
WHERE fare_amount >= 0 AND trip_distance > 0
  AND tpep_pickup_datetime IS NOT NULL
  AND tpep_dropoff_datetime >= tpep_pickup_datetime;

-- COMMAND ----------
CREATE OR REPLACE TABLE actividad_luciana.gold.resumen_diario_demo
USING DELTA
COMMENT 'Gold: cantidad de viajes, tarifas e indicadores diarios'
AS SELECT CAST(fecha_recogida AS DATE) AS fecha,
  COUNT(*) AS viajes, SUM(tarifa) AS total_tarifas,
  AVG(tarifa) AS tarifa_promedio,
  AVG(distancia_millas) AS distancia_promedio
FROM actividad_luciana.silver.viajes_demo GROUP BY 1;

-- COMMAND ----------
-- Consulta 1: volumen y tarifas por dia.
SELECT * FROM actividad_luciana.gold.resumen_diario_demo ORDER BY fecha;

-- COMMAND ----------
-- Consulta 2: las 10 zonas con mayor total de tarifas.
SELECT zona_origen, COUNT(*) AS viajes, SUM(tarifa) AS total_tarifas
FROM actividad_luciana.silver.viajes_demo
GROUP BY zona_origen ORDER BY total_tarifas DESC, zona_origen LIMIT 10;

-- COMMAND ----------
-- Consulta 3: demanda por hora de recogida.
SELECT HOUR(fecha_recogida) AS hora, COUNT(*) AS viajes
FROM actividad_luciana.silver.viajes_demo GROUP BY 1 ORDER BY 1;

-- COMMAND ----------
-- Consulta 4: tarifa media por milla por zona (promedio por viaje).
SELECT zona_origen, AVG(tarifa / distancia_millas) AS tarifa_media_por_milla
FROM actividad_luciana.silver.viajes_demo GROUP BY zona_origen
ORDER BY tarifa_media_por_milla DESC;

-- COMMAND ----------
-- Consulta 5: variacion diaria de tarifas; primer dia sin comparacion.
WITH dias AS (
  SELECT fecha, total_tarifas,
    LAG(total_tarifas) OVER (ORDER BY fecha) AS total_anterior,
    LAG(fecha) OVER (ORDER BY fecha) AS fecha_anterior
  FROM actividad_luciana.gold.resumen_diario_demo
)
SELECT fecha, total_tarifas,
  CASE WHEN DATEDIFF(fecha, fecha_anterior) = 1 AND total_anterior <> 0
    THEN ROUND(100.0 * (total_tarifas - total_anterior) / total_anterior, 2)
  END AS variacion_diaria_pct
FROM dias ORDER BY fecha;

-- COMMAND ----------
-- Validaciones para la defensa: deben retornar cero errores y filas > 0.
SELECT COUNT(*) AS filas,
  COUNT_IF(tarifa < 0 OR distancia_millas <= 0 OR fecha_recogida IS NULL
    OR fecha_llegada < fecha_recogida) AS errores
FROM actividad_luciana.silver.viajes_demo;
SHOW TABLES IN actividad_luciana.silver;
SHOW TABLES IN actividad_luciana.gold;
