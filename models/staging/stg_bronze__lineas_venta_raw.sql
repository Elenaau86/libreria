with

source as (

    select * from {{ source('bronze', 'lineas_venta_raw') }}

),

renamed as (

    select
        -- claves
        linea_id,
        venta_id,
        isbn,
        try_cast(num_linea as integer)         as num_linea,

        -- categoría
        trim(categoria)                                                            as categoria,

        -- cantidades
        try_cast(unidades as integer)                                              as unidades,

        -- precios
        round(try_cast(replace(precio_unitario, ',', '.') as numeric(10,2)), 2)    as precio_unitario,

        -- importes
        round(try_cast(replace(importe_bruto,   ',', '.') as numeric(12,2)), 2)    as importe_bruto,
        round(try_cast(replace(descuento_pct,   ',', '.') as numeric(6,2)),  2)    as descuento_pct,
        round(try_cast(replace(importe_neto,    ',', '.') as numeric(12,2)), 2)    as importe_neto,

        -- derivados
        round(try_cast(replace(importe_bruto, ',', '.') as numeric(12,2)) -
                try_cast(replace(importe_neto,  ',', '.') as numeric(12,2)), 2)    as descuento_importe,

        -- metadatos
        current_timestamp()                                                        as _loaded_at

    from source

)

select * from renamed