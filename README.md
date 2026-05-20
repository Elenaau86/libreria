# 📚 Data Warehouse Librería — Snowflake + dbt + Python

Proyecto de ingeniería de datos que implementa un Data Warehouse completo para una cadena de librerías con tiendas físicas y canal online.

---

## 🏗️ Arquitectura

El pipeline sigue una arquitectura en tres capas:

| Capa | Base de datos | Descripción |
|------|--------------|-------------|
| **Bronze** | `DEV/PRO_BRONZE_DB` | Datos raw en VARCHAR. Ingesta desde CSV vía Python. |
| **Silver (Staging)** | `DEV/PRO_SILVER_DB` | Datos limpios y tipados. 31 modelos dbt (vistas y tablas). |
| **Gold (Marts)** | `DEV/PRO_GOLD_DB` | Dimensiones y hechos listos para análisis. Modelo estrella. |

---

## 🛠️ Stack Tecnológico

- **Snowflake** — Data Warehouse en la nube
- **dbt Cloud** — Transformación y modelado de datos
- **Python** — Ingesta de datos desde CSV a Bronze
- **GitHub** — Control de versiones y CI/CD

---

## 📊 Dataset

Dataset diseñado y construido desde cero con datos ficticios pero coherentes entre sí.

| Tabla | Filas | Descripción |
|-------|-------|-------------|
| Ventas | 8.000 | Transacciones con canal, empleado y cliente |
| Líneas de Venta | 18.056 | Detalle de productos por venta |
| Clientes | 801 | 800 clientes + 1 registro SIN_REGISTRO |
| Tiendas | 12 | Tiendas físicas T001–T012 |
| Empleados | 66 | 65 empleados + 1 registro virtual ONLINE |
| Municipios | 18 | Catálogo geográfico y socioeconómico |
| Catálogo Productos | 500 | Libros con precios, márgenes y disponibilidad |
| **TOTAL** | **27.453** | |

---

## 📁 Estructura del Repositorio

```
libreria/
├── ingesta/                          # Scripts Python de ingesta
│   ├── ingesta_bronze.py             # Carga completa de todas las tablas Bronze
│   ├── ingesta_ventas_incremental.py # Carga incremental de VENTAS_RAW
│   ├── ingesta_lineas_incremental.py # Carga incremental de LINEAS_VENTA_RAW
│   └── data/                         # CSVs fuente
│       ├── VENTAS.csv
│       ├── LINEAS_VENTA.csv
│       ├── CLIENTES.csv
│       ├── TIENDAS.csv
│       ├── EMPLEADOS.csv
│       ├── MUNICIPIOS.csv
│       └── CATALOGO_PRODUCTOS.csv
├── models/
│   ├── staging/                      # 19 modelos Silver (vistas)
│   └── marts/                        # 12 modelos Gold (tablas)
├── snapshots/                        # SCD2 de empleados
├── tests/                            # 10 tests singulares de negocio
├── macros/                           # Macros de entorno DEV/PRO
├── dbt_project.yml
└── packages.yml
```

---

## ⚙️ Requisitos Previos

- Cuenta de **Snowflake** activa
- **Python 3.8+** instalado con las librerías:
  ```bash
  pip install snowflake-connector-python cryptography
  ```
- **dbt Cloud** con este repositorio conectado
- Archivo `private_key.p8` (autenticación RSA con Snowflake) — **no incluido por seguridad**

---

## 🚀 Pasos para Ejecutar el Proyecto

### Paso 1 — Setup de Snowflake (solo la primera vez)

Abre Snowflake → Worksheets y ejecuta el fichero `setup_snowflake.sql`. Esto crea:

- 6 bases de datos (`DEV/PRO × BRONZE/SILVER/GOLD`)
- Warehouse `COMPUTE_WH`
- Schema `BOOKSTORE` en cada Bronze
- Stage `RAW_FILES` y file format `CSV_FORMAT`
- Usuario con autenticación por clave privada

### Paso 2 — Ingesta Bronze (Python)

Coloca tu archivo `private_key.p8` dentro de la carpeta `ingesta/` y ejecuta:

```bash
cd ingesta/
python ingesta_bronze.py
```

El script realiza automáticamente:
- Reparación de encoding de los CSVs
- Subida de ficheros al stage `RAW_FILES`
- `TRUNCATE + COPY INTO` en las 7 tablas Bronze
- Verificación final con conteo de filas

**Resultado esperado: 27.453 filas totales cargadas.**

### Paso 3 — dbt Build (desde dbt Cloud IDE)

```bash
# Primero: actualizar snapshot SCD2 de empleados
dbt snapshot

# Segundo: construir todos los modelos desde cero
dbt build --full-refresh
```

> ⚠️ Usar siempre `--full-refresh` tras una recarga completa de Bronze.

---

## 📈 Ingesta Incremental

Para cargar ficheros de ventas nuevos sin truncar las tablas:

```bash
python ingesta_ventas_incremental.py --fichero VENTAS_20250512.csv
python ingesta_lineas_incremental.py --fichero LINEAS_VENTA_20250512.csv

# Para un entorno específico:
python ingesta_ventas_incremental.py --fichero VENTAS_20250512.csv --entorno PRO
```

Snowflake usa `LOAD_HISTORY` para evitar duplicados: si el fichero ya fue cargado, lo omite automáticamente.

---

## 🧪 Calidad de Datos

| Tipo | Cantidad | Descripción |
|------|----------|-------------|
| Tests genéricos | 339 | `not_null`, `unique`, `accepted_values`, `relationships` |
| Tests singulares | 10 | Lógica de negocio cruzando varias tablas |
| **Total** | **349** | |

> ⚠️ El test `assert_margen_positivo` devuelve **WARN** de forma esperada y documentada. Hay 999 líneas vendidas por debajo del coste de adquisición (descuentos/promociones legítimas). Se mantiene como WARN para visibilidad sin bloquear el pipeline.

---

## 🏢 Modelo Dimensional (Gold)

Esquema en estrella con 4 tablas de hechos y 8 dimensiones:

**Tablas de hechos:**
- `FCT_VENTAS` — Cabeceras de venta (8.000 filas)
- `FCT_VENTAS_LINEA` — Líneas de detalle (18.056 filas)
- `FCT_RENDIMIENTO_EMPLEADO` — Métricas por empleado
- `FCT_PENETRACION_GEO` — Penetración geográfica

**Dimensiones:**
`DIM_TIEMPO` · `DIM_CLIENTE` · `DIM_EMPLEADO` · `DIM_TIENDA` · `DIM_PRODUCTO` · `DIM_GEOGRAFIA` · `DIM_CANAL` · `DIM_SEGMENTO_CLIENTE`

---

## 🔄 CI/CD — Jobs de dbt Cloud

| Job | Trigger | Entorno | Comando |
|-----|---------|---------|---------|
| CI: Verificación de Cambios | Automático en PR | Production | `dbt build --select state:modified+ --defer` |
| Producción: Carga Diaria | Automático, 6:00 diario | PRO | `dbt snapshot + dbt build` |
| Producción: Full Refresh | Manual | PRO | `dbt build --full-refresh` |

---

## 🔐 Seguridad

El archivo `private_key.p8` **nunca se sube al repositorio** (protegido por `.gitignore`). Cada usuario debe generar su propio par de claves RSA y configurar el usuario en Snowflake.

---

## 🤖 Caso de Uso de IA

Se han generado 500 reseñas literarias (una por libro) incluidas en `CATALOGO_PRODUCTOS.csv`. El modelo `dim_producto` en Gold incluye análisis de sentimiento usando **Snowflake Cortex**:

```sql
snowflake.cortex.sentiment(resena_texto) as sentimiento_resena
```

Devuelve un score entre -1 (negativo) y +1 (positivo) para cada reseña.