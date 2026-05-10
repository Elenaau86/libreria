with municipios as (

    select * from {{ ref('stg_bronze__municipios_raw') }}

),

tiendas as (

    select distinct municipio
    from {{ ref('stg_bronze__tiendas_raw') }}

),

provincias as (

    select cod_provincia_ine, provincia, num_municipios as num_municipios_provincia
    from {{ ref('stg_bronze__provincias_raw') }}

),

ccaa as (

    select cod_ccaa_ine, ccaa, num_municipios as num_municipios_ccaa, num_provincias
    from {{ ref('stg_bronze__ccaa_raw') }}

),

tipos_zona as (

    select
        cod_tipo_zona,
        tipo_zona,
        num_municipios                                           as num_municipios_zona,
        renta_media_zona,
        poblacion_media_zona
    from {{ ref('stg_bronze__tipos_zona_raw') }}

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
        iff(t.municipio is not null, true, false)                as tiene_tienda,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from municipios m
    left join tiendas t
        on m.municipio = t.municipio
    left join provincias p
        on m.cod_provincia_ine = p.cod_provincia_ine
    left join ccaa c
        on m.cod_ccaa_ine = c.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona

)

select * from dim