# Guia de ejecucion y evidencias

Responsable: Luciana Ruiz Cahuas. Actividad preparada el 22/10/2026.

## Estado real
- Repositorio y codigo SQL/Python preparados.
- Codigo no ejecutado en Databricks: la consola muestra "Automated browser control detected" y exige Genie One MCP.
- Git Folder, sincronizacion, conexion S3 y respuestas reales de Genie pendientes de ejecucion/verificacion.
- No se han inventado resultados ni se afirma que las consultas fueron generadas por Genie.

## Contenido
- notebooks/01_catalogo_consultas.sql: catalogo actividad_luciana, schemas silver/gold, tablas Delta de muestra y cinco consultas SQL.
- notebooks/02_s3.py: registro de tabla externa Delta Silver S3, validacion, tabla Gold y cinco consultas desde Python.

## Ejecutar dentro de Git Folder
1. En Workspace > Create > Git folder, usar https://github.com/LucianaRuizCahuas/databricks-s3-lakehouse.git y proveedor GitHub. Autenticar el proveedor con la cuenta LucianaRuizCahuas si se solicita.
2. Seleccionar main y hacer Pull. Abrir los notebooks desde ese Git Folder.
3. Ejecutar 01_catalogo_consultas.sql con compute habilitado para Unity Catalog. Si no hay privilegio CREATE CATALOG, el administrador debe crear actividad_luciana y conceder USE CATALOG, CREATE SCHEMA; no reemplazar tablas ajenas.
4. Guardar resultados y capturas del catalogo, schemas y consultas. Los datos demo proceden de samples.nyctaxi.trips; no acreditan una conexion S3 propia.
5. Para S3 real, obtener una ruta Delta Silver autorizada y compatible con las seis columnas documentadas en Python. Configurar widget s3_silver y ejecutar 02_s3.py. El codigo se detiene ante ausencia de ruta, columnas, datos o calidad valida.
6. Revisar DESCRIBE DETAIL de actividad_luciana.silver.viajes_s3: debe mostrar la ubicacion s3:// real. Conservar esa evidencia y las validaciones Silver/Gold.
7. Confirmar los cambios en Git Folder, hacer Push y verificar que el SHA coincide con GitHub. Git Folder no implica sincronizacion automatica continua: usar Pull/Push.

## Requisitos S3
Unity Catalog necesita storage credential IAM y external location que cubra el prefijo, configuradas por el administrador del workspace/AWS. No subir claves AWS, tokens, archivos .env ni credenciales al repositorio. Se requiere USE CATALOG/SCHEMA, CREATE TABLE y CREATE EXTERNAL TABLE sobre la external location, ademas de acceso de lectura segun el caso.

SQL orientativo para un administrador, solo con bucket y credencial reales ya autorizados:

~~~sql
CREATE EXTERNAL LOCATION IF NOT EXISTS viajes_silver_location
URL 's3://REEMPLAZAR_BUCKET/silver/viajes'
WITH (STORAGE CREDENTIAL REEMPLAZAR_CREDENCIAL);
-- El notebook Python registra la tabla usando esa ruta Delta.
~~~

No ejecutar los marcadores REEMPLAZAR. No se ha creado un bucket ni un rol IAM. Revisar disponibilidad de almacenamiento externo en el workspace Free Edition antes de dar por cumplido S3.

## Genie Agents: cinco preguntas para generar y validar consultas
Crear un espacio Genie con las tablas Silver/Gold correspondientes. Elegir datos demo o S3, sin mezclar ambas fuentes. Instrucciones: usar nombres completos, definir total_tarifas como SUM(fare_amount), excluir divisiones por cero, no interpretar tarifa como beneficio ni incluir propinas inexistentes.

1. Muestra viajes y total de tarifas por fecha de recogida, ordenados por fecha.
2. Cuales son las diez zonas de origen con mayor suma de tarifas? Incluye cantidad de viajes.
3. Cuantos viajes comienzan en cada hora del dia?
4. Cual es el promedio por viaje de tarifa dividida por distancia en millas, por zona de origen?
5. Cual es la duracion promedio del viaje en minutos por zona de origen?

Para cada pregunta guardar prompt, SQL devuelto por Genie, resultado, fecha, tabla utilizada y correcciones. Comparar conteos y agregados con las consultas del notebook. Para datos demo, los nombres son fecha_recogida, fecha_llegada, tarifa, distancia_millas y zona_origen; para S3 son los nombres originales NYC Taxi.

## Validacion durante dos clases
Clase 1: mostrar Git Folder y URL GitHub, catalog/schema creados con SQL, tabla Silver y ubicacion real S3 con lectura correcta. Capturar el SHA sincronizado.
Clase 2: mostrar Gold, cinco respuestas de Genie con su SQL y resultados, consultas Python/SQL y validaciones de calidad y conteos; comprobar acceso del docente juancondorijara.

## Documentacion oficial
- https://docs.databricks.com/aws/en/connect/unity-catalog/cloud-storage/s3
- https://docs.databricks.com/aws/en/getting-started/free-edition-limitations
