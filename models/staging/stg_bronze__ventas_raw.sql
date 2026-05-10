with source as (

    select * from {{ source('bronze', 'ventas_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

renamed as (

    select
        -- claves
        s.venta_id,
        s.tienda_id,
        s.empleado_id,
        s.cliente_id,

        -- fecha
        try_cast(s.fecha as date)                                        as fecha,

        -- canal como FK
        c.cod_canal,

        -- geografía
        try_cast(s.cod_municipio_venta_ine as integer)                   as cod_municipio_venta_ine,

        -- volumen
        try_cast(s.total_lineas   as integer)                            as total_lineas,
        try_cast(s.total_unidades as integer)                            as total_unidades,

        -- importes
        round(try_cast(replace(s.importe_bruto_total, ',', '.') as numeric(12,2)), 2) as importe_bruto,
        round(try_cast(replace(s.importe_neto_total,  ',', '.') as numeric(12,2)), 2) as importe_neto,

        -- derivados
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

        -- flags
        iff(s.cliente_id = 'SIN_REGISTRO', true, false)                 as es_venta_anonima,
        iff(s.cod_municipio_venta_ine is not null, true, false)          as tiene_municipio,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source s
    left join canales c
        on trim(s.canal) = c.canal

)

select * from renamed