with catalogo as (

    select * from {{ ref('stg_bronze__catalogo_productos_raw') }}

),

autores as (

    select autor, num_titulos as num_titulos_autor
    from {{ ref('stg__autores') }}

),

editoriales as (

    select editorial, num_titulos as num_titulos_editorial
    from {{ ref('stg_bronze__editoriales_raw') }}

),

categorias as (

    select
        categoria,
        num_titulos        as num_titulos_categoria,
        precio_pvp_medio   as precio_pvp_medio_categoria,
        margen_medio_pct   as margen_medio_categoria
    from {{ ref('stg_bronze__categorias_raw') }}

),

idiomas as (

    select idioma, num_titulos as num_titulos_idioma
    from {{ ref('stg_bronze__idiomas_raw') }}

),

formatos as (

    select formato, num_titulos as num_titulos_formato, precio_pvp_medio as precio_pvp_medio_formato
    from {{ ref('stg_bronze__formatos_raw') }}

),

dim as (

    select
        -- clave natural
        c.isbn,

        -- datos bibliográficos
        c.titulo,
        c.autor,
        c.editorial,
        c.categoria,
        c.anio_publicacion,
        c.idioma,
        c.formato,
        c.paginas,

        -- precios y margen
        c.precio_pvp,
        c.precio_coste,
        c.margen_bruto_pct_original,
        c.margen_bruto_pct,

        -- rangos derivados
        c.rango_precio,
        c.rango_margen,
        c.anios_desde_publicacion,

        -- disponibilidad
        c.disponible_online,
        c.disponible_tienda,
        c.activo,
        c.fecha_alta_catalogo,

        -- reseña e IA
        c.resena_texto,
        snowflake.cortex.sentiment(c.resena_texto)               as sentimiento_resena,

        -- enriquecimiento desde catálogos Silver
        a.num_titulos_autor,
        e.num_titulos_editorial,
        cat.num_titulos_categoria,
        cat.precio_pvp_medio_categoria,
        cat.margen_medio_categoria,
        i.num_titulos_idioma,
        f.num_titulos_formato,
        f.precio_pvp_medio_formato,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from catalogo c
    left join autores a
        on c.autor = a.autor
    left join editoriales e
        on c.editorial = e.editorial
    left join categorias cat
        on c.categoria = cat.categoria
    left join idiomas i
        on c.idioma = i.idioma
    left join formatos f
        on c.formato = f.formato

)

select * from dim