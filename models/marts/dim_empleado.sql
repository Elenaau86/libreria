with empleados as (

    select * from {{ ref('stg_bronze__empleados_raw') }}

),

tiendas as (

    select * from {{ ref('stg_bronze__tiendas_raw') }}

),

municipios as (

    select * from {{ ref('stg_bronze__municipios_raw') }}

),

dim as (

    select
        -- clave natural
        e.empleado_id,

        -- tienda
        e.tienda_id,
        t.nombre                                                 as nombre_tienda,

        -- datos personales
        e.nombre,
        e.genero,
        e.edad,

        -- puesto
        e.puesto,
        e.categoria_puesto,

        -- antigüedad y fechas
        e.fecha_contratacion,
        e.antiguedad_anios,

        -- salario y coste
        e.salario_mensual_bruto,
        e.coste_anual_estimado,

        -- geografía de la tienda denormalizada
        t.municipio,
        m.provincia,
        m.ccaa,
        m.tipo_zona,

        -- flag
        e.es_virtual,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from empleados e
    left join tiendas t
        on e.tienda_id = t.tienda_id
    left join municipios m
        on t.municipio = m.municipio

)

select * from dim