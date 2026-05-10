with municipios as (

    select * from {{ ref('stg_bronze__bookstore_municipios_raw') }}

),

tiendas as (

    select distinct municipio
    from {{ ref('stg_bronze__bookstore_tiendas_raw') }}

),

dim as (

    select
        -- clave surrogada — viene de staging
        m.geografia_sk,

        -- resto de campos igual...
        m.cod_municipio_ine,
        m.municipio,
        m.cod_provincia_ine,
        m.provincia,
        m.cod_ccaa_ine,
        m.ccaa,
        m.tipo_zona,
        m.renta_media,
        m.rango_renta,
        m.poblacion,
        m.rango_poblacion,
        iff(t.municipio is not null, true, false)                 as tiene_tienda,
        current_timestamp()                                       as _loaded_at

    from municipios m
    left join tiendas t
        on m.municipio = t.municipio

)

select * from dim