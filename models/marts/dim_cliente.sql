with clientes as (

    select * from {{ ref('stg_bronze__clientes_raw') }}

),

municipios as (

    select * from {{ ref('stg_bronze__municipios_raw') }}

),

provincias as (

    select cod_provincia_ine, provincia
    from {{ ref('stg_bronze__provincias_raw') }}

),

ccaa as (

    select cod_ccaa_ine, ccaa
    from {{ ref('stg_bronze__ccaa_raw') }}

),

tipos_zona as (

    select cod_tipo_zona, tipo_zona
    from {{ ref('stg_bronze__tipos_zona_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

dim as (

    select
        -- clave natural
        c.cliente_id,

        -- datos personales
        c.nombre,
        c.edad,
        c.segmento_edad,

        -- geografía denormalizada
        c.municipio,
        m.cod_municipio_ine,
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
        on c.municipio = m.municipio
    left join provincias p
        on m.cod_provincia_ine = p.cod_provincia_ine
    left join ccaa ca
        on m.cod_ccaa_ine = ca.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona
    left join canales can
        on c.cod_canal_preferido = can.cod_canal

)

select * from dim