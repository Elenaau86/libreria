with source as (

    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

renamed as (

    select
        -- clave
        trim(isbn)                                                                       as isbn,

        -- datos bibliográficos (texto limpio — sin códigos FK, eso va en marts)
        trim(titulo)                                                                     as titulo,
        trim(autor)                                                                      as autor,
        trim(editorial)                                                                  as editorial,
        trim(categoria)                                                                  as categoria,
        try_cast(anio_publicacion as integer)                                            as anio_publicacion,
        trim(idioma)                                                                     as idioma,
        trim(formato)                                                                    as formato,
        try_cast(paginas as integer)                                                     as paginas,

        -- precios
        round(try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)), 2)         as precio_pvp,
        round(try_cast(replace(precio_coste,     ',', '.') as numeric(10,2)), 2)         as precio_coste,

        -- margen original del CSV conservado para auditoría
        round(try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)), 2)          as margen_bruto_pct_original,

        -- margen recalculado real desde precios actuales
        round(
            iff(
                try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) = 0,
                null,
                (try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) -
                 try_cast(replace(precio_coste,     ',', '.') as numeric(10,2))) /
                 try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) * 100
            ), 2
        )                                                                                as margen_bruto_pct,

        -- rangos derivados
        case
            when try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) < 12    then 'Bajo'
            when try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) <= 25   then 'Medio'
            else                                                                              'Alto'
        end                                                                             as rango_precio,

        case
            when try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)) < 30     then 'Margen bajo'
            when try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)) <= 45    then 'Margen medio'
            else                                                                              'Margen alto'
        end                                                                              as rango_margen,

        -- antigüedad (campo Bronze se llama anio_publicacion, sin tilde)
        year(current_date()) - try_cast(anio_publicacion as integer)                     as anios_desde_publicacion,

        -- disponibilidad (texto → boolean)
        iff(trim(disponible_online) = 'Sí', true, false)                                 as disponible_online,
        iff(trim(disponible_tienda) = 'Sí', true, false)                                 as disponible_tienda,
        iff(trim(activo)            = 'Sí', true, false)                                 as activo,

        try_cast(fecha_alta_catalogo as date)                                            as fecha_alta_catalogo,

        -- metadatos
        current_timestamp()                                                              as _loaded_at

    from source

)

select * from renamed