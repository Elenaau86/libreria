"""
ingesta_ventas_incremental.py
Script de ingesta INCREMENTAL de VENTAS_RAW desde CSV a Bronze.

Diferencias respecto a ingesta_bronze.py:
- NO hace TRUNCATE. Append puro.
- Espera ficheros con nombre VENTAS_YYYYMMDD.csv (o cualquier patrón
  distinto al fichero base VENTAS.csv).
- Snowflake rastrea qué ficheros ya se cargaron desde el stage
  (LOAD_HISTORY): si el fichero ya fue procesado, el COPY INTO
  lo ignora automáticamente sin duplicar filas.
- _loaded_at se inyecta como current_timestamp() en la proyección,
  igual que en la carga completa. Cada fichero nuevo tendrá su
  propio timestamp de ingesta.

Uso:
    python ingesta_ventas_incremental.py --fichero VENTAS_20250512.csv
    python ingesta_ventas_incremental.py --fichero VENTAS_20250512.csv --entorno PRE

Entorno por defecto: DEV
"""

import argparse
import os
import snowflake.connector
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.serialization import (
    Encoding, PrivateFormat, NoEncryption
)

# ── CONFIGURACIÓN ──────────────────────────────────────────────────────────────
SNOWFLAKE_BASE = {
    "user"     : "ELENAAU",
    "warehouse": "COMPUTE_WH",
    "role"     : "ACCOUNTADMIN",
}

ENTORNOS = {
    "DEV": {"account": "FVZBGJT-UL49821", "database": "DEV_BRONZE_DB"},
    "PRE": {"account": "FVZBGJT-UL49821", "database": "PRE_BRONZE_DB"},
    "PRO": {"account": "FVZBGJT-UL49821", "database": "PRO_BRONZE_DB"},
}

SCHEMA           = "BOOKSTORE"
STAGE            = "RAW_FILES"
TABLA            = "VENTAS_RAW"
PRIVATE_KEY_PATH = "private_key.p8"
CSV_DIR          = "data"

COLS = """venta_id, fecha, canal, tienda_id, empleado_id,
          cod_municipio_venta_ine, cliente_id, total_lineas,
          total_unidades, importe_bruto_total, importe_neto_total,
          _loaded_at"""

CAMPOS = "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,current_timestamp()"

FILE_FORMAT_TPL = "(FORMAT_NAME = '{database}.{schema}.CSV_FORMAT')"


# ── AUTENTICACIÓN ──────────────────────────────────────────────────────────────
def cargar_clave_privada(ruta: str) -> bytes:
    with open(ruta, "rb") as f:
        private_key = load_pem_private_key(
            f.read(), password=None, backend=default_backend()
        )
    return private_key.private_bytes(
        encoding=Encoding.DER,
        format=PrivateFormat.PKCS8,
        encryption_algorithm=NoEncryption()
    )


def conectar(entorno: str) -> snowflake.connector.SnowflakeConnection:
    cfg = {**SNOWFLAKE_BASE, **ENTORNOS[entorno], "schema": SCHEMA}
    print(f"Conectando a Snowflake [{entorno}]...")
    conn = snowflake.connector.connect(
        **cfg,
        private_key=cargar_clave_privada(PRIVATE_KEY_PATH),
    )
    print("Conexión establecida.\n")
    return conn


# ── INGESTA ────────────────────────────────────────────────────────────────────
def subir_stage(cursor, csv_path: str) -> None:
    """Sube el CSV al stage. OVERWRITE=TRUE para no pisar ficheros ya cargados."""
    put_sql = (
        f"PUT 'file://{csv_path}' @{STAGE} "
        f"AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
    )
    print(f"  → PUT al stage {STAGE}  (OVERWRITE=TRUE)...")
    result = cursor.execute(put_sql).fetchall()
    for row in result:
        # row[6] = status: UPLOADED / SKIPPED
        print(f"     {row[0]}  →  {row[6]}")


def copy_incremental(cursor, csv_file: str, database: str) -> int:
    """
    COPY INTO en modo append. Snowflake no reprocesa ficheros ya cargados
    desde el mismo stage (LOAD_HISTORY por nombre de fichero).
    Devuelve el número de filas insertadas.
    """
    file_format = FILE_FORMAT_TPL.format(database=database, schema=SCHEMA)

    copy_sql = f"""
        COPY INTO {TABLA} ({COLS})
        FROM (
            SELECT {CAMPOS}
            FROM @{STAGE}/{csv_file}
        )
        FILE_FORMAT = {file_format}
        ON_ERROR    = 'CONTINUE'
    """
    print(f"  → COPY INTO {TABLA}  (append, sin TRUNCATE)...")
    result = cursor.execute(copy_sql).fetchall()

    if not result:
        print("  ℹ  Fichero ya cargado previamente — Snowflake lo omitió (LOAD_HISTORY).")
        return 0

    filas   = sum(r[3] for r in result)
    errores = sum(r[5] for r in result)
    print(f"  ✓ {filas} filas insertadas | {errores} errores")
    return filas


def verificar(cursor) -> None:
    cursor.execute(f"SELECT COUNT(*), MAX(_loaded_at) FROM {TABLA}")
    total, ultimo = cursor.fetchone()
    print(f"\n  {TABLA}: {total} filas totales | última carga: {ultimo}")


# ── MAIN ───────────────────────────────────────────────────────────────────────
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ingesta incremental de VENTAS_RAW en Bronze."
    )
    parser.add_argument(
        "--fichero",
        required=True,
        help="Nombre del CSV a cargar, p.ej. VENTAS_20250512.csv",
    )
    parser.add_argument(
        "--entorno",
        choices=["DEV", "PRE", "PRO"],
        default="DEV",
        help="Entorno Snowflake destino (default: DEV)",
    )
    return parser.parse_args()


def main() -> None:
    args     = parse_args()
    csv_file = args.fichero
    entorno  = args.entorno
    database = ENTORNOS[entorno]["database"]

    csv_path = os.path.abspath(os.path.join(CSV_DIR, csv_file)).replace("\\", "/")

    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"No se encuentra el fichero: {csv_path}")

    print(f"{'─'*60}")
    print(f"Ingesta incremental VENTAS")
    print(f"Fichero : {csv_file}")
    print(f"Entorno : {entorno}  ({database})")
    print(f"{'─'*60}")

    conn   = conectar(entorno)
    cursor = conn.cursor()

    try:
        subir_stage(cursor, csv_path)
        copy_incremental(cursor, csv_file, database)
        verificar(cursor)
        print(f"\n{'─'*60}")
        print("Ingesta incremental de ventas completada.")
    except Exception as e:
        print(f"\nERROR: {e}")
        raise
    finally:
        cursor.close()
        conn.close()
        print("Conexión cerrada.")


if __name__ == "__main__":
    main()
