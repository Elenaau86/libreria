with municipios as (

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

tiendas as (

    select distinct cod_municipio_ine
    from {{ ref('stg__tiendas') }}
    where cod_municipio_ine is not null

),

provincias as (

    select cod_provincia_ine, provincia, num_municipios as num_municipios_provincia
    from {{ ref('stg__provincias') }}

),

ccaa as (

    select cod_ccaa_ine, ccaa, num_municipios as num_municipios_ccaa, num_provincias
    from {{ ref('stg__ccaa') }}

),

tipos_zona as (

    select
        cod_tipo_zona,
        tipo_zona,
        num_municipios                                           as num_municipios_zona,
        renta_media_zona,
        poblacion_media_zona
    from {{ ref('stg__tipos_zona') }}

),

dim as (

    select
        -- clave natural
        m.cod_municipio_ine,
        m.municipio,

        -- provincia
        m.cod_provincia_ine,
        p.provincia,
        p.num_municipios_provincia,

        -- comunidad autónoma
        m.cod_ccaa_ine,
        c.ccaa,
        c.num_municipios_ccaa,
        c.num_provincias,

        -- tipo de zona
        m.cod_tipo_zona,
        tz.tipo_zona,
        tz.num_municipios_zona,
        tz.renta_media_zona,
        tz.poblacion_media_zona,

        -- datos propios del municipio
        m.renta_media,
        m.rango_renta,
        m.poblacion,
        m.rango_poblacion,

        -- flag tienda física
        iff(t.cod_municipio_ine is not null, true, false)        as tiene_tienda,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from municipios m
    left join tiendas t
        on m.cod_municipio_ine = t.cod_municipio_ine
    left join provincias p
        on m.cod_provincia_ine = p.cod_provincia_ine
    left join ccaa c
        on m.cod_ccaa_ine = c.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona

)

select * from dim