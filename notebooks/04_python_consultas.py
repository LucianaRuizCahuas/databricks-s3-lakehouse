# Databricks notebook source
# Ejecutar en el Git Folder. Las tablas se crean con 01_catalogo_consultas.sql.
from pyspark.sql import functions as F

silver = spark.table('actividad_luciana.silver.viajes_demo')
gold = spark.table('actividad_luciana.gold.resumen_diario_demo')
assert silver.count() > 0
assert silver.filter('tarifa < 0 OR distancia_millas <= 0 OR fecha_recogida IS NULL').count() == 0
assert silver.count() == gold.agg(F.sum('viajes')).first()[0]

# COMMAND ----------
display(gold.orderBy('fecha'))

# COMMAND ----------
display(silver.groupBy('zona_origen').agg(F.count('*').alias('viajes'),
    F.sum('tarifa').alias('total_tarifas')).orderBy(F.desc('total_tarifas')).limit(10))

# COMMAND ----------
display(silver.groupBy(F.hour('fecha_recogida').alias('hora')).count().orderBy('hora'))

# COMMAND ----------
display(silver.groupBy('zona_origen').agg(
    F.avg(F.col('tarifa') / F.col('distancia_millas')).alias('tarifa_por_milla')))

# COMMAND ----------
display(silver.groupBy('zona_origen').agg(F.avg(
    (F.col('fecha_llegada').cast('long') - F.col('fecha_recogida').cast('long')) / 60.0
).alias('duracion_media_minutos')))
print('Cinco consultas Python y validaciones completadas')
