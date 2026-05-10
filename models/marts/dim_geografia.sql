with municipios as (

    select * from {{ ref('stg_bronze__municipios_raw') }}

),

tiendas as (

    select distinct municipio
    from {{ ref('stg_bronze__tiendas_raw') }}

),

dim as (

    select
        -- clave natural — ahora sí es única
        m.cod_municipio_ine,

        -- municipio
        m.municipio,

        -- provincia
        m.cod_provincia_ine,
        m.provincia,

        -- comunidad autónoma
        m.cod_ccaa_ine,
        m.ccaa,

        -- clasificación socioeconómica
        m.tipo_zona,
        m.renta_media,
        m.rango_renta,

        -- población
        m.poblacion,
        m.rango_poblacion,

        -- flag — tiene tienda física en este municipio
        iff(t.municipio is not null, true, false)                 as tiene_tienda,

        -- metadatos
        current_timestamp()                                       as _loaded_at

    from municipios m
    left join tiendas t
        on m.municipio = t.municipio

)

select * from dim