-- fct_ventas_linea.sql
-- INCREMENTAL con estrategia MERGE.
-- Filtra por _src_loaded_at propagado desde stg_bronze__lineas_venta_raw.
-- El filtro va en el CTE de lineas porque la granularidad es linea_id.
-- El merge actualiza filas existentes si llegan correcciones.
--
-- _src_loaded_at se incluye en el SELECT para que {{ this }} lo tenga
-- disponible en la siguiente ejecución incremental.
 
{{
    config(
        materialized         = 'incremental',
        unique_key           = 'linea_id',
        on_schema_change     = 'sync_all_columns',
        incremental_strategy = 'merge'
    )
}}
 
with lineas as (
 
    select * from {{ ref('stg_bronze__lineas_venta_raw') }}
 
    {% if is_incremental() %}
        where _src_loaded_at > (select max(_src_loaded_at) from {{ this }})
    {% endif %}
 
),

ventas as (

    select venta_id, fecha, cod_canal, tienda_id
    from {{ ref('stg_bronze__ventas_raw') }}

),

dim_tiempo as (

    select tiempo_sk, fecha
    from {{ ref('dim_tiempo') }}

),

dim_canal as (

    select canal_sk, canal_nombre as canal, es_digital
    from {{ ref('dim_canal') }}

),

fct as (

    select
        -- clave natural
        l.linea_id,

        -- FKs dimensiones
        t.tiempo_sk,
        c.canal_sk,
        v.tienda_id,
        l.isbn,

        -- referencia a fct_ventas
        l.venta_id,

        -- atributos de línea
        l.num_linea,
        l.categoria,

        -- métricas
        l.unidades,
        l.precio_unitario,
        l.importe_bruto,
        l.descuento_pct,
        l.descuento_importe,
        l.importe_neto,

        -- métricas derivadas con precio de coste desde dim_producto
        p.precio_coste,
        round(l.unidades * p.precio_coste, 2)                    as coste_total,
        round(l.importe_neto - (l.unidades * p.precio_coste), 2) as margen_bruto_importe,
        round(
            iff(l.importe_neto = 0, null,
                (l.importe_neto - (l.unidades * p.precio_coste)) /
                 l.importe_neto * 100
            ), 2
        )                                                        as margen_bruto_pct_real,
        round(
            iff(p.precio_pvp = 0, null,
                l.precio_unitario / p.precio_pvp
            ), 4
        )                                                        as precio_vs_pvp_ratio,

        -- metadatos
        l._src_loaded_at,
        current_timestamp()                                      as _loaded_at

    from lineas l
    inner join ventas v
        on l.venta_id = v.venta_id
    left join dim_tiempo t
        on v.fecha = t.fecha
    left join dim_canal c
        on v.cod_canal = c.canal_sk
    left join {{ ref('dim_producto') }} p
        on l.isbn = p.isbn

)

select * from fct