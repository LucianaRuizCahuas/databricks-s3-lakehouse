# Databricks: SQL, Python y Genie

Actividad ejecutada: catalogo, esquemas Silver/Gold, tablas Delta, cinco consultas SQL, cinco consultas PySpark y cinco consultas generadas y ejecutadas con Genie.

- `notebooks/01_catalogo_consultas.sql`: estructura y consultas SQL.
- `notebooks/02_s3.py`: alternativa opcional para una tabla externa S3 existente; no ejecutada.
- `notebooks/03_consultas_genie.sql`: SQL generado realmente por Genie.
- `notebooks/04_python_consultas.py`: consultas PySpark y validaciones; ejecucion SUCCESS.

Las tablas de la actividad usan almacenamiento S3 administrado por Databricks/Unity Catalog. No se configuro un bucket externo propio. Si el docente exige especificamente una tabla EXTERNAL sobre un bucket propio, se necesita un bucket y rol IAM autorizados.

Las evidencias completas y el informe actualizado se entregan por separado a la alumna, fuera del repositorio publico. `GUIA_ENTREGA.md` conserva el plan inicial; el estado final es el indicado en este README y en el informe de evidencias.

Para reproducir, abrir el Git Folder, ejecutar primero 01 y luego 03/04. Fuente: muestra NYC Taxi de Databricks. No publicar credenciales ni archivos de evidencias internos.
