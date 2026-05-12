-- stg_bronze__lineas_venta_raw.sql
-- INCREMENTAL: solo procesa filas de LINEAS_VENTA_RAW con _loaded_at
-- posterior al máximo ya presente en el modelo materializado.
-- unique_key = linea_id → merge seguro ante reprocesos.
--
-- Convención:
--   _src_loaded_at  → timestamp de ingesta a Bronze (metadato del COPY INTO)
--   _loaded_at      → timestamp de transformación dbt (este modelo)

{{
    config(
        materialized = 'incremental',
        unique_key   = 'linea_id',
        on_schema_change = 'sync_all_columns'
    )
}}

with source as (

    select * from {{ source('bronze', 'lineas_venta_raw') }}

    {% if is_incremental() %}
        where _loaded_at > (select max(_src_loaded_at) from {{ this }})
    {% endif %}

),

renamed as (

    select
        linea_id,
        venta_id,
        isbn,
        try_cast(num_linea as integer)                                                     as num_linea,
        trim(categoria)                                                                    as categoria,
        try_cast(unidades as integer)                                                      as unidades,
        round(try_cast(replace(precio_unitario, ',', '.') as numeric(10,2)), 2)            as precio_unitario,
        round(try_cast(replace(importe_bruto,   ',', '.') as numeric(12,2)), 2)            as importe_bruto,
        round(try_cast(replace(descuento_pct,   ',', '.') as numeric(6,2)),  2)            as descuento_pct,
        round(try_cast(replace(importe_neto,    ',', '.') as numeric(12,2)), 2)            as importe_neto,
        round(try_cast(replace(importe_bruto, ',', '.') as numeric(12,2)) -
                try_cast(replace(importe_neto,  ',', '.') as numeric(12,2)), 2)            as descuento_importe,
        _loaded_at                                                                         as _src_loaded_at,
        current_timestamp()                                                                as _loaded_at

    from source

)

select * from renamed
