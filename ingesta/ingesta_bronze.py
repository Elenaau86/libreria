"""
ingesta_bronze.py
Script de ingesta COMPLETA (carga inicial) desde CSV a la capa Bronze de Snowflake.
Hace TRUNCATE + COPY INTO en todas las tablas.

VENTAS_RAW y LINEAS_VENTA_RAW incluyen _loaded_at como metadato
inyectado en la proyección del COPY INTO (current_timestamp()).

Autenticación mediante clave privada (private key).

Entorno:
- Database : DEV_BRONZE_DB
- Schema   : BOOKSTORE
- Stage    : RAW_FILES (stage único para todos los ficheros)
"""

import snowflake.connector
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.serialization import (
    Encoding, PrivateFormat, NoEncryption
)
import os

# ── CONFIGURACIÓN ──────────────────────────────────────────────────────────────
SNOWFLAKE_CONFIG = {
    "account"  : "FVZBGJT-UL49821",
    "user"     : "ELENAAU",
    "warehouse": "COMPUTE_WH",
    "database" : "DEV_BRONZE_DB",
    "schema"   : "BOOKSTORE",
    "role"     : "ACCOUNTADMIN",
}

PRIVATE_KEY_PATH = "private_key.p8"
STAGE            = "RAW_FILES"
CSV_DIR          = "data"

# Mapeo: csv → tabla → columnas
# VENTAS_RAW y LINEAS_VENTA_RAW incluyen _loaded_at inyectado con current_timestamp()
TABLAS = [
    {
        "csv"   : "VENTAS.csv",
        "tabla" : "VENTAS_RAW",
        "cols"  : """venta_id, fecha, canal, tienda_id, empleado_id,
                     cod_municipio_venta_ine, cliente_id, total_lineas,
                     total_unidades, importe_bruto_total, importe_neto_total,
                     _loaded_at""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,current_timestamp()",
    },
    {
        "csv"   : "LINEAS_VENTA.csv",
        "tabla" : "LINEAS_VENTA_RAW",
        "cols"  : """linea_id, venta_id, num_linea, isbn, categoria,
                     precio_unitario, unidades, importe_bruto,
                     descuento_pct, importe_neto,
                     _loaded_at""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,current_timestamp()",
    },
    {
        "csv"   : "CLIENTES.csv",
        "tabla" : "CLIENTES_RAW",
        "cols"  : """cliente_id, nombre, edad, segmento_edad, municipio,
                     provincia, ccaa, canal_preferido, fecha_alta, newsletter""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10",
    },
    {
        "csv"   : "TIENDAS.csv",
        "tabla" : "TIENDAS_RAW",
        "cols"  : "tienda_id, nombre, municipio, m2",
        "campos": "$1,$2,$3,$4",
    },
    {
        "csv"   : "EMPLEADOS.csv",
        "tabla" : "EMPLEADOS_RAW",
        "cols"  : """empleado_id, tienda_id, nombre, genero, edad,
                     puesto, fecha_contratacion, salario_mensual_bruto""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8",
    },
    {
        "csv"   : "MUNICIPIOS.csv",
        "tabla" : "MUNICIPIOS_RAW",
        "cols"  : """municipio, cod_municipio_ine, cod_provincia_ine,
                     cod_ccaa_ine, provincia, ccaa,
                     renta_media, poblacion, tipo_zona""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8,$9",
    },
    {
        "csv"   : "CATALOGO_PRODUCTOS.csv",
        "tabla" : "CATALOGO_PRODUCTOS_RAW",
        "cols"  : """isbn, titulo, autor, editorial, categoria,
                     anio_publicacion, idioma, formato, paginas,
                     precio_venta_pvp, precio_coste, margen_bruto_pct,
                     disponible_online, disponible_tienda, activo,
                     fecha_alta_catalogo, resena_texto""",
        "campos": "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17",
    },
]

FILE_FORMAT = "(FORMAT_NAME = 'DEV_BRONZE_DB.BOOKSTORE.CSV_FORMAT')"

# DDL de todas las tablas Bronze.
# _loaded_at incluido en VENTAS_RAW y LINEAS_VENTA_RAW para soporte incremental.
# Todas las columnas de datos son VARCHAR — Bronze es capa raw sin tipado.
CREATE_TABLES = [
    """
    CREATE TABLE IF NOT EXISTS VENTAS_RAW (
        venta_id                VARCHAR,
        fecha                   VARCHAR,
        canal                   VARCHAR,
        tienda_id               VARCHAR,
        empleado_id             VARCHAR,
        cod_municipio_venta_ine VARCHAR,
        cliente_id              VARCHAR,
        total_lineas            VARCHAR,
        total_unidades          VARCHAR,
        importe_bruto_total     VARCHAR,
        importe_neto_total      VARCHAR,
        _loaded_at              TIMESTAMP_NTZ
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS LINEAS_VENTA_RAW (
        linea_id        VARCHAR,
        venta_id        VARCHAR,
        num_linea       VARCHAR,
        isbn            VARCHAR,
        categoria       VARCHAR,
        precio_unitario VARCHAR,
        unidades        VARCHAR,
        importe_bruto   VARCHAR,
        descuento_pct   VARCHAR,
        importe_neto    VARCHAR,
        _loaded_at      TIMESTAMP_NTZ
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS CLIENTES_RAW (
        cliente_id      VARCHAR,
        nombre          VARCHAR,
        edad            VARCHAR,
        segmento_edad   VARCHAR,
        municipio       VARCHAR,
        provincia       VARCHAR,
        ccaa            VARCHAR,
        canal_preferido VARCHAR,
        fecha_alta      VARCHAR,
        newsletter      VARCHAR
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS TIENDAS_RAW (
        tienda_id VARCHAR,
        nombre    VARCHAR,
        municipio VARCHAR,
        m2        VARCHAR
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS EMPLEADOS_RAW (
        empleado_id           VARCHAR,
        tienda_id             VARCHAR,
        nombre                VARCHAR,
        genero                VARCHAR,
        edad                  VARCHAR,
        puesto                VARCHAR,
        fecha_contratacion    VARCHAR,
        salario_mensual_bruto VARCHAR
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS MUNICIPIOS_RAW (
        municipio         VARCHAR,
        cod_municipio_ine VARCHAR,
        cod_provincia_ine VARCHAR,
        cod_ccaa_ine      VARCHAR,
        provincia         VARCHAR,
        ccaa              VARCHAR,
        renta_media       VARCHAR,
        poblacion         VARCHAR,
        tipo_zona         VARCHAR
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS CATALOGO_PRODUCTOS_RAW (
        isbn                VARCHAR,
        titulo              VARCHAR,
        autor               VARCHAR,
        editorial           VARCHAR,
        categoria           VARCHAR,
        anio_publicacion    VARCHAR,
        idioma              VARCHAR,
        formato             VARCHAR,
        paginas             VARCHAR,
        precio_venta_pvp    VARCHAR,
        precio_coste        VARCHAR,
        margen_bruto_pct    VARCHAR,
        disponible_online   VARCHAR,
        disponible_tienda   VARCHAR,
        activo              VARCHAR,
        fecha_alta_catalogo VARCHAR,
        resena_texto        VARCHAR
    )
    """,
]


def cargar_clave_privada(ruta: str) -> bytes:
    with open(ruta, "rb") as f:
        private_key = load_pem_private_key(
            f.read(),
            password=None,
            backend=default_backend()
        )
    return private_key.private_bytes(
        encoding=Encoding.DER,
        format=PrivateFormat.PKCS8,
        encryption_algorithm=NoEncryption()
    )

def reparar_encoding(ruta: str) -> None:
    """Repara ficheros con doble encoding UTF-8 interpretado como latin-1."""
    with open(ruta, 'r', encoding='utf-8', errors='replace') as f:
        contenido = f.read()
    # Intenta reparar doble encoding
    try:
        reparado = contenido.encode('latin-1').decode('utf-8')
        with open(ruta, 'w', encoding='utf-8') as f:
            f.write(reparado)
    except (UnicodeDecodeError, UnicodeEncodeError):
        pass  # Si no se puede reparar, deja el fichero como está

def conectar() -> snowflake.connector.SnowflakeConnection:
    print("Conectando a Snowflake...")
    conn = snowflake.connector.connect(
        **SNOWFLAKE_CONFIG,
        private_key=cargar_clave_privada(PRIVATE_KEY_PATH),
    )
    print("Conexión establecida correctamente.\n")
    return conn


def crear_tablas(cursor) -> None:
    """Crea las tablas Bronze si no existen. Seguro de ejecutar siempre."""
    print(f"{'─'*60}")
    print("Verificando / creando tablas Bronze...")
    for ddl in CREATE_TABLES:
        cursor.execute(ddl)
    print("  ✓ Tablas listas.\n")


def cargar_tabla(cursor, tabla_config: dict) -> None:
    csv_file = tabla_config["csv"]
    tabla    = tabla_config["tabla"]
    cols     = tabla_config["cols"]
    campos   = tabla_config["campos"]
    csv_path = os.path.abspath(os.path.join(CSV_DIR, csv_file)).replace("\\", "/")

    print(f"{'─'*60}")
    print(f"Tabla  : {tabla}")
    print(f"Fichero: {csv_file}")

    # 1. Subir CSV al stage
    put_sql = (
        f"PUT 'file://{csv_path}' @{STAGE} "
        f"AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
    )
    print(f"  → PUT al stage {STAGE}...")
    cursor.execute(put_sql)

    # 2. Truncar tabla (carga completa)
    print(f"  → TRUNCATE {tabla}...")
    cursor.execute(f"TRUNCATE TABLE {tabla}")

    # 3. COPY INTO — current_timestamp() inyectado como metadato
    #    en VENTAS_RAW y LINEAS_VENTA_RAW
    copy_sql = f"""
        COPY INTO {tabla} ({cols})
        FROM (
            SELECT {campos}
            FROM @{STAGE}/{csv_file}
        )
        FILE_FORMAT = {FILE_FORMAT}
        ON_ERROR   = 'CONTINUE'
    """
    print(f"  → COPY INTO {tabla}...")
    result = cursor.execute(copy_sql).fetchall()

    filas   = sum(r[3] for r in result) if result else 0
    errores = sum(r[5] for r in result) if result else 0
    print(f"  ✓ {filas} filas cargadas | {errores} errores")


def verificar_carga(cursor) -> None:
    print(f"\n{'─'*60}")
    print("VERIFICACIÓN FINAL:")
    print(f"{'─'*60}")
    total = 0
    for t in TABLAS:
        cursor.execute(f"SELECT COUNT(*) FROM {t['tabla']}")
        count = cursor.fetchone()[0]
        total += count
        print(f"  {t['tabla']:<35} {count:>6} filas")
    print(f"{'─'*60}")
    print(f"  {'TOTAL':<35} {total:>6} filas")


def main():
    conn   = conectar()
    cursor = conn.cursor()
    try:
        crear_tablas(cursor)
         # Reparar encoding antes de cargar
        for tabla_config in TABLAS:
            csv_path = os.path.join(CSV_DIR, tabla_config["csv"])
            reparar_encoding(csv_path)
        for tabla_config in TABLAS:
            cargar_tabla(cursor, tabla_config)
        verificar_carga(cursor)
        print(f"\n{'─'*60}")
        print("Ingesta completa finalizada correctamente.")
    except Exception as e:
        print(f"\nERROR durante la ingesta: {e}")
        raise
    finally:
        cursor.close()
        conn.close()
        print("Conexión cerrada.")


if __name__ == "__main__":
    main()