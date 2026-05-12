with

source as (

    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

autores as (

    select autor, cod_autor
    from {{ ref('stg_bronze__autores_raw') }}

),

editoriales as (

    select editorial, cod_editorial
    from {{ source('bronze', 'stg_bronze__editoriales_raw') }}

),

categorias as (

    select categoria, cod_categoria
    from {{ ref('stg_bronze__categorias_raw') }}

),

formatos as (

    select cod_formato, formato
    from {{ ref('stg_bronze__formatos_raw') }}

),

idiomas as (

    select cod_idioma, idioma
    from {{ ref('stg_bronze__idiomas_raw') }}

),

renamed as (

    select
        -- clave
        trim(isbn)                                                                 as isbn,

        -- datos bibliográficos
        trim(titulo)
                                                                       as titulo,
        trim(autor)                                                                as autor,
        trim(editorial)                                                            as editorial,
        trim(categoria)   
        trim(idioma)                                                               as idioma,
        trim(formato)                                                              as formato,
        
                                                                 as categoria,
        try_cast(replace(anio_publicacion, ',', '.') as integer)                    as anio_publicacion,
        try_cast(paginas as integer)                                               as paginas,

        -- precios
        round(try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)), 2)   as precio_pvp,
        round(try_cast(replace(precio_coste,     ',', '.') as numeric(10,2)), 2)   as precio_coste,

        -- margen — campo original (puede ser inconsistente con precios actuales)
        round(try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)),  2)   as margen_bruto_pct_original,

        -- margen recalculado desde precios actuales
        round(
            iff(try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) = 0, null,
                (try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) -
                    try_cast(replace(precio_coste,     ',', '.') as numeric(10,2))) /
                    try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) * 100
            ), 2
        )                                                                           as margen_bruto_pct,

        -- rangos derivados
        case
            when try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) < 12 then 'Bajo'
            when try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)) < 25 then 'Medio'
            else                                                                          'Alto'
        end                                                                         as rango_precio,

        case
            when try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)) < 30 then 'Margen bajo'
            when try_cast(replace(margen_bruto_pct, ',', '.') as numeric(6,2)) < 45 then 'Margen medio'
            else                                                                          'Margen alto'
        end                                                                         as rango_margen,

        -- antigüedad
        year(current_date()) -
            try_cast(replace(ano_publicacion, ',', '.') as integer)                 as anios_desde_publicacion,

        -- disponibilidad
        iff(trim(disponible_online) = 'Sí', true, false)                            as disponible_online,
        iff(trim(disponible_tienda) = 'Sí', true, false)                            as disponible_tienda,
        iff(trim(activo)            = 'Sí', true, false)                            as activo,

        -- fecha alta
        try_cast(fecha_alta_catalogo as date)                                       as fecha_alta_catalogo,

        -- metadatos
        current_timestamp()                                                         as _loaded_at

    from source

)

select * from renamed