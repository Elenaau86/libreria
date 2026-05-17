with clientes as (

    select * from {{ ref('stg__clientes') }}

),

municipios as (

    select
        cod_municipio_ine,
        municipio,
        cod_provincia_ine,
        cod_ccaa_ine,
        cod_tipo_zona,
        renta_media,
        rango_renta,
        poblacion,
        rango_poblacion
    from {{ ref('stg__municipios') }}

),

provincias as (

    select cod_provincia_ine, provincia
    from {{ ref('stg__provincias') }}

),

ccaa as (

    select cod_ccaa_ine, ccaa
    from {{ ref('stg__ccaa') }}

),

tipos_zona as (

    select cod_tipo_zona, tipo_zona
    from {{ ref('stg__tipos_zona') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg__canales') }}

),

segmentos as (

    select cod_segmento_edad, segmento_edad
    from {{ ref('stg__segmentos_edad') }}

),

dim as (

    select
        -- clave natural
        c.cliente_id,

        -- datos personales
        c.nombre,
        c.edad,
        seg.segmento_edad,

        -- geografía denormalizada
        m.cod_municipio_ine,
        m.municipio,
        p.provincia,
        ca.ccaa,
        tz.tipo_zona,
        m.renta_media,
        m.rango_renta,
        m.poblacion,
        m.rango_poblacion,

        -- canal preferido
        can.canal                                                        as canal_preferido,

        -- comportamiento
        c.fecha_alta,
        c.newsletter,

        -- flag
        c.es_anonimo,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from clientes c
    left join municipios m
        on c.cod_municipio_ine = m.cod_municipio_ine
    left join provincias p
        on m.cod_provincia_ine = p.cod_provincia_ine
    left join ccaa ca
        on m.cod_ccaa_ine = ca.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona
    left join canales can
        on c.cod_canal_preferido = can.cod_canal
    left join segmentos seg
        on c.cod_segmento_edad = seg.cod_segmento_edad

)

select * from dim