with tiendas as (

    select * from {{ ref('stg__tiendas') }}

),

municipios as (

    select * from {{ ref('stg__municipios') }}

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

    select cod_tipo_zona, tipo_zona, renta_media_zona
    from {{ ref('stg__tipos_zona') }}

),

canales as (

    select cod_canal, canal, es_digital
    from {{ ref('stg__canales') }}

),

dim as (

    select
        -- clave natural
        t.tienda_id,

        -- datos de la tienda
        t.nombre,
        t.m2,

        -- canal
        c.canal,
        c.es_digital,

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

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from tiendas t
    left join municipios m
        on t.cod_municipio_ine = m.cod_municipio_ine
    left join provincias p
        on m.cod_provincia_ine = p.cod_provincia_ine
    left join ccaa ca
        on m.cod_ccaa_ine = ca.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona
    left join canales c
        on t.cod_canal = c.cod_canal

)

select * from dim