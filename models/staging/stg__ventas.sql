-- stg__ventas.sql
-- INCREMENTAL: solo procesa filas de VENTAS_RAW con _loaded_at
-- posterior al máximo ya presente en el modelo materializado.
-- unique_key = venta_id → merge seguro si el mismo fichero se
-- reprocesa accidentalmente.
--
-- Convención de columnas _loaded_at:
--   _src_loaded_at  → timestamp de ingesta a Bronze (metadato del COPY INTO)
--   _loaded_at      → timestamp de transformación dbt (este modelo)

{{
    config(
        materialized = 'incremental',
        unique_key   = 'venta_id',
        on_schema_change = 'append_new_columns',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select * from {{ source('bronze', 'ventas_raw') }}

    {% if is_incremental() %}
        where _loaded_at > (select max(_src_loaded_at) from {{ this }})
    {% endif %}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg__canales') }}

),

renamed as (

    select
        s.venta_id,
        s.tienda_id,
        s.empleado_id,
        s.cliente_id,
        try_cast(s.fecha as date)                                        as fecha,
        c.cod_canal,
        try_cast(s.cod_municipio_venta_ine as integer)                   as cod_municipio_venta_ine,
        try_cast(s.total_lineas   as integer)                            as total_lineas,
        try_cast(s.total_unidades as integer)                            as total_unidades,
        round(try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)), 2) as importe_bruto,
        round(try_cast(replace(s.importe_neto_total,  ',', '.') as numeric(12,2)), 2) as importe_neto,
        round(
            try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)) -
            try_cast(replace(s.importe_neto_total,  ',', '.') as numeric(12,2)), 2
        )                                                                as descuento_total,
        round(
            iff(try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)) = 0, null,
                (try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)) -
                 try_cast(replace(s.importe_neto_total,  ',', '.') as numeric(12,2))) /
                 try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)) * 100
            ), 2
        )                                                                as descuento_pct,
        round(
            iff(try_cast(s.total_unidades as integer) = 0, null,
                try_cast(replace(s.importe_neto_total, ',', '.') as numeric(12,2)) /
                try_cast(s.total_unidades as integer)
            ), 2
        )                                                                as ticket_medio,
        iff(s.cliente_id = 'SIN_REGISTRO', true, false)                 as es_venta_anonima,
        iff(s.cod_municipio_venta_ine is not null, true, false)          as tiene_municipio,
        s._loaded_at                                                     as _src_loaded_at,
        current_timestamp()                                              as _loaded_at

    from source s
    left join canales c
        on trim(s.canal) = c.canal

)

select * from renamed
