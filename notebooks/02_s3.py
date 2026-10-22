# Databricks notebook source
# S3 real: requiere external location y credencial IAM ya autorizadas en Unity Catalog.
# Datos esperados: Delta con esquema de samples.nyctaxi.trips.
# No se ha ejecutado ni verificado una conexion S3 desde este repositorio.
import re
from pyspark.sql import functions as F

dbutils.widgets.text('catalogo', 'actividad_luciana')
dbutils.widgets.text('s3_silver', '')
catalogo = dbutils.widgets.get('catalogo')
ruta = dbutils.widgets.get('s3_silver').strip()
if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', catalogo):
    raise ValueError('Catalogo invalido')
if not ruta.startswith('s3://') or len(ruta.split('/')) < 4 or "'" in ruta or '\n' in ruta:
    raise ValueError('Configura s3_silver con una ruta Delta S3 autorizada; no se simula la conexion.')

# COMMAND ----------
spark.sql(f'CREATE CATALOG IF NOT EXISTS {catalogo}')
spark.sql(f'CREATE SCHEMA IF NOT EXISTS {catalogo}.silver')
spark.sql(f'CREATE SCHEMA IF NOT EXISTS {catalogo}.gold')
# Leer antes de registrar; si no hay acceso o Delta valido se detiene.
fuente = spark.read.format('delta').load(ruta)
requeridas = {'tpep_pickup_datetime', 'tpep_dropoff_datetime', 'trip_distance',
              'fare_amount', 'pickup_zip', 'dropoff_zip'}
if not requeridas.issubset(set(fuente.columns)):
    raise ValueError(f'Columnas faltantes: {requeridas - set(fuente.columns)}')
if fuente.limit(1).count() == 0:
    raise ValueError('La fuente S3 esta vacia')
# Registrar tabla externa Silver existente: no modificar ni borrar datos S3.
spark.sql(f"CREATE TABLE IF NOT EXISTS {catalogo}.silver.viajes_s3 USING DELTA LOCATION '{ruta}'")
detalle = spark.sql(f'DESCRIBE DETAIL {catalogo}.silver.viajes_s3').first().asDict()
if detalle['location'].rstrip('/') != ruta.rstrip('/'):
    raise ValueError('La tabla ya existe con otra ubicacion. Revisar antes de continuar.')
display(spark.sql(f'DESCRIBE DETAIL {catalogo}.silver.viajes_s3'))

# COMMAND ----------
# Gold administrada por Unity Catalog, derivada de la tabla Silver S3.
# El registro Silver no garantiza por si solo calidad: validar las filas.
datos = spark.table(f'{catalogo}.silver.viajes_s3')
invalidos = datos.filter(
    F.col('fare_amount').isNull() | (F.col('fare_amount') < 0)
    | F.col('trip_distance').isNull() | (F.col('trip_distance') <= 0)
    | F.col('tpep_pickup_datetime').isNull()
    | F.col('tpep_dropoff_datetime').isNull()
    | (F.col('tpep_dropoff_datetime') < F.col('tpep_pickup_datetime'))
).count()
if invalidos:
    raise ValueError(f'Silver contiene {invalidos} filas invalidas; limpiar en origen antes de publicar Gold.')
spark.sql(f"""CREATE OR REPLACE TABLE {catalogo}.gold.resumen_diario_s3
USING DELTA AS SELECT CAST(tpep_pickup_datetime AS DATE) AS fecha,
COUNT(*) AS viajes, SUM(fare_amount) AS total_tarifas,
AVG(fare_amount) AS tarifa_promedio
FROM {catalogo}.silver.viajes_s3 GROUP BY 1""")

# COMMAND ----------
# Cinco consultas equivalentes a preguntas para Genie; autoria de este codigo: Codex.
# No atribuirlas a Genie hasta ejecutar y conservar su respuesta real.
consultas = {
    '1 Tarifas diarias': f'SELECT * FROM {catalogo}.gold.resumen_diario_s3 ORDER BY fecha',
    '2 Top zonas': f'''SELECT pickup_zip, COUNT(*) viajes, SUM(fare_amount) total_tarifas
        FROM {catalogo}.silver.viajes_s3 GROUP BY pickup_zip ORDER BY total_tarifas DESC LIMIT 10''',
    '3 Demanda por hora': f'''SELECT HOUR(tpep_pickup_datetime) hora, COUNT(*) viajes
        FROM {catalogo}.silver.viajes_s3 GROUP BY 1 ORDER BY 1''',
    '4 Tarifa por milla': f'''SELECT pickup_zip, AVG(fare_amount / trip_distance) tarifa_por_milla
        FROM {catalogo}.silver.viajes_s3 GROUP BY pickup_zip ORDER BY tarifa_por_milla DESC''',
    '5 Duracion por zona': f'''SELECT pickup_zip,
        AVG(timestampdiff(SECOND, tpep_pickup_datetime, tpep_dropoff_datetime)/60.0) minutos
        FROM {catalogo}.silver.viajes_s3 GROUP BY pickup_zip ORDER BY minutos DESC'''
}
for titulo, consulta in consultas.items():
    print(titulo)
    display(spark.sql(consulta))

# COMMAND ----------
assert spark.table(f'{catalogo}.gold.resumen_diario_s3').count() > 0
assert datos.count() == spark.table(f'{catalogo}.gold.resumen_diario_s3').agg(F.sum('viajes')).first()[0]
print('Validacion de conteos Silver/Gold completada. Guardar evidencia del resultado.')
