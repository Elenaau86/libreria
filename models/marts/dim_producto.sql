with catalogo as (

    select * from {{ ref('stg_bronze__catalogo_productos_raw') }}

),

dim as (

    select
        -- clave natural
        isbn,

        -- datos bibliográficos
        titulo,
        autor,
        editorial,
        categoria,
        anio_publicacion,
        idioma,
        formato,
        paginas,

        -- precios y margen
        precio_pvp,
        precio_coste,
        margen_bruto_pct_original,
        margen_bruto_pct,

        -- rangos derivados
        rango_precio,
        rango_margen,

        -- antigüedad
        anios_desde_publicacion,

        -- disponibilidad
        disponible_online,
        disponible_tienda,
        activo,

        -- fecha alta
        fecha_alta_catalogo,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from catalogo

)

select * from dim