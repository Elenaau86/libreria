with 

source as (

    select * from {{ source('bronze', 'bookstore_ventas_raw') }}

),

renamed as (

    select
        -- claves
        venta_id,
        tienda_id,
        empleado_id,
        cliente_id,

        -- fecha
        try_cast(fecha as date)                                          as fecha,

        -- canal
        trim(canal)                                                      as canal,

        -- geografía
        try_cast(cod_municipio_venta_ine as integer)                     as cod_municipio_venta_ine,

        -- volumen
        total_lineas,
        total_unidades,

        -- importes
        round(try_cast(replace(importe_bruto_total, ',', '.') as numeric(12,2)), 2)  as importe_bruto,
        round(try_cast(replace(importe_neto_total,  ',', '.') as numeric(12,2)), 2)  as importe_neto,

        -- derivados
        round(
            try_cast(replace(importe_bruto_total, ',', '.') as numeric(12,2)) -
            try_cast(replace(importe_neto_total,  ',', '.') as numeric(12,2)), 2
        )                                                                as descuento_total,

        round(
            iff(try_cast(replace(importe_bruto_total, ',', '.') as numeric(12,2)) = 0, null,
                (try_cast(replace(importe_bruto_total, ',', '.') as numeric(12,2)) -
                 try_cast(replace(importe_neto_total,  ',', '.') as numeric(12,2))) /
                 try_cast(replace(importe_bruto_total, ',', '.') as numeric(12,2)) * 100
            ), 2
        )                                                                as descuento_pct,

        round(
            iff(total_unidades = 0, null,
                try_cast(replace(importe_neto_total, ',', '.') as numeric(12,2)) / total_unidades
            ), 2
        )                                                                as ticket_medio,

        -- flags
        iff(trim(cliente_id) = 'SIN_REGISTRO', true, false)             as es_venta_anonima,
        iff(cod_municipio_venta_ine is not null, true, false)            as tiene_municipio,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source

)

select * from renamed