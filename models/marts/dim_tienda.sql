with tiendas as (

    select * from {{ ref('stg_bronze__tiendas_raw') }}

),

municipios as (

    select * from {{ ref('stg_bronze__municipios_raw') }}

),

dim as (

    select
        -- clave natural
        t.tienda_id,

        -- datos de la tienda
        t.nombre,
        t.m2,
        t.num_empleados,
        t.canal,

        -- geografía denormalizada directamente
        t.municipio,
        m.cod_municipio_ine,
        m.provincia,
        m.ccaa,
        m.tipo_zona,
        m.renta_media,
        m.rango_renta,
        m.poblacion,
        m.rango_poblacion,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from tiendas t
    left join municipios m
        on t.municipio = m.municipio

)

select * from dim