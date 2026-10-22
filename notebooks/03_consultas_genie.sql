-- Databricks notebook source

-- Consultas generadas por Databricks Genie; evidencia en evidencias/genie_*.json.

-- COMMAND ----------

-- Pregunta 1: Muestra cantidad de viajes y suma de tarifas por fecha de recogida, ordenados por fecha.

SELECT DATE_TRUNC('DAY', `fecha_recogida`) AS fecha_recogida, COUNT(*) AS cantidad_viajes, SUM(`tarifa`) AS suma_tarifas
FROM `actividad_luciana`.`silver`.`viajes_demo`
WHERE `fecha_recogida` IS NOT NULL AND `tarifa` IS NOT NULL
GROUP BY DATE_TRUNC('DAY', `fecha_recogida`)
ORDER BY fecha_recogida ASC;

-- COMMAND ----------

-- Pregunta 2: Cuales son las diez zonas de origen con mayor suma de tarifas? Incluye cantidad de viajes.

WITH zonas_rank AS (
  SELECT 
    `zona_origen`,
    SUM(`tarifa`) AS suma_tarifas,
    COUNT(*) AS cantidad_viajes,
    RANK() OVER (ORDER BY SUM(`tarifa`) DESC) AS rank
  FROM `actividad_luciana`.`silver`.`viajes_demo`
  WHERE `zona_origen` IS NOT NULL AND `tarifa` IS NOT NULL
  GROUP BY `zona_origen`
)
SELECT 
  `zona_origen`,
  suma_tarifas,
  cantidad_viajes
FROM zonas_rank
WHERE rank <= 10
ORDER BY suma_tarifas DESC;

-- COMMAND ----------

-- Pregunta 3: Cuantos viajes comienzan en cada hora del dia? Ordena por hora.

SELECT HOUR(viajes_demo.fecha_recogida) AS hora, COUNT(*) AS cantidad_viajes
FROM actividad_luciana.silver.viajes_demo
WHERE viajes_demo.fecha_recogida IS NOT NULL
GROUP BY hora
ORDER BY hora ASC;

-- COMMAND ----------

-- Pregunta 4: Cual es el promedio por viaje de tarifa dividida por distancia en millas, por zona de origen?

SELECT viajes_demo.zona_origen, AVG(try_divide(viajes_demo.tarifa, viajes_demo.distancia_millas)) AS promedio_tarifa_por_milla
FROM actividad_luciana.silver.viajes_demo
WHERE viajes_demo.zona_origen IS NOT NULL AND viajes_demo.tarifa IS NOT NULL AND viajes_demo.distancia_millas IS NOT NULL AND viajes_demo.distancia_millas > 0
GROUP BY viajes_demo.zona_origen
ORDER BY promedio_tarifa_por_milla DESC;

-- COMMAND ----------

-- Pregunta 5: Cual es la duracion promedio del viaje en minutos por zona de origen?

SELECT viajes_demo.zona_origen, AVG(try_divide((unix_timestamp(viajes_demo.fecha_llegada) - unix_timestamp(viajes_demo.fecha_recogida)),60)) AS duracion_promedio_minutos
FROM actividad_luciana.silver.viajes_demo
WHERE viajes_demo.zona_origen IS NOT NULL
  AND viajes_demo.fecha_recogida IS NOT NULL
  AND viajes_demo.fecha_llegada IS NOT NULL
  AND (unix_timestamp(viajes_demo.fecha_llegada) - unix_timestamp(viajes_demo.fecha_recogida)) > 0
GROUP BY viajes_demo.zona_origen;
