with clientes as (

    select * from {{ ref('stg_bronze__bookstore_clientes_raw') }}

),

municipios as (

    select * from {{ ref('stg_bronze__bookstore_municipios_raw') }}

),

dim as (

    select
        -- clave natural
        c.cliente_id,

        -- datos personales
        c.nombre,
        c.edad,
        c.segmento_edad,

        -- geografía denormalizada directamente
        c.municipio,
        m.cod_municipio_ine,
        m.provincia,
        m.ccaa,
        m.tipo_zona,
        m.renta_media,
        m.rango_renta,
        m.poblacion,
        m.rango_poblacion,

        -- comportamiento
        c.canal_preferido,
        c.fecha_alta,
        c.newsletter,

        -- flag
        c.es_anonimo,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from clientes c
    left join municipios m
        on c.municipio = m.municipio

)

select * from dim