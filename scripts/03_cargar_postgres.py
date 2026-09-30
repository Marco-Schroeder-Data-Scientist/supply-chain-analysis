# Carga el CSV limpio a PostgreSQL, en la tabla staging.pedidos
# "staging" = tabla de paso: copia exacta del CSV limpio, antes de armar el modelo estrella
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# 1. Rutas y credenciales (las claves están en .env, nunca dentro del código)
raiz = Path(__file__).resolve().parent.parent
load_dotenv(raiz / ".env")

usuario = os.getenv("PG_USER")
clave = os.getenv("PG_PASSWORD")
host = os.getenv("PG_HOST")
puerto = os.getenv("PG_PORT")
base = os.getenv("PG_DB")

# Si falta alguna variable, avisamos con un mensaje claro
if None in (usuario, clave, host, puerto, base):
    raise SystemExit("Falta alguna variable en el archivo .env (revisa las 5 líneas)")

# 2. Conexión a PostgreSQL
engine = create_engine(f"postgresql+psycopg2://{usuario}:{clave}@{host}:{puerto}/{base}")

# 3. Leer el CSV limpio (parse_dates: las columnas de fecha se leen como fecha y no como texto)
archivo = raiz / "data" / "processed" / "pedidos_limpios.csv"
df = pd.read_csv(archivo, parse_dates=["fecha_pedido", "fecha_envio", "mes_pedido"])
print("Filas en el CSV:", len(df))

# 4. Crear el esquema staging y cargar la tabla
with engine.begin() as conexion:
    conexion.execute(text("CREATE SCHEMA IF NOT EXISTS staging"))

# chunksize: envía los datos en bloques de 10.000 filas, para no saturar la memoria
df.to_sql("pedidos", engine, schema="staging", if_exists="replace",
          index=False, chunksize=10000)

# 5. Comprobar que llegaron todas las filas
with engine.connect() as conexion:
    total = conexion.execute(text("SELECT COUNT(*) FROM staging.pedidos")).scalar()
print("Filas en PostgreSQL:", total)