with empleados as (

    select * from {{ ref('stg_bronze__empleados_raw') }}

),

tiendas as (

    select tienda_id, nombre as nombre_tienda, cod_municipio_ine, cod_canal
    from {{ ref('stg_bronze__tiendas_raw') }}

),

municipios as (

    select cod_municipio_ine, municipio
    from {{ ref('stg_bronze__municipios_raw') }}

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

generos as (

    select cod_genero, genero
    from {{ ref('stg_bronze__generos_raw') }}

),

puestos as (

    select
        cod_puesto,
        puesto,
        categoria_puesto,
        salario_medio,
        salario_minimo,
        salario_maximo
    from {{ ref('stg_bronze__puestos_raw') }}

),

dim as (

    select
        -- clave natural
        e.empleado_id,

        -- tienda
        e.tienda_id,
        t.nombre_tienda,

        -- datos personales
        e.nombre,
        g.genero,
        e.edad,

        -- puesto
        p.puesto,
        p.categoria_puesto,

        -- enriquecimiento desde catálogo de puestos
        p.salario_medio                                          as salario_medio_puesto,
        p.salario_minimo                                         as salario_minimo_puesto,
        p.salario_maximo                                         as salario_maximo_puesto,

        -- antigüedad y fechas
        e.fecha_contratacion,
        e.antiguedad_anios,

        -- salario y coste propios
        e.salario_mensual_bruto,
        e.coste_anual_estimado,

        -- geografía de la tienda denormalizada
        m.municipio,
        pr.provincia,
        c.ccaa,
        tz.tipo_zona,

        -- flag
        e.es_virtual,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from empleados e
    left join tiendas t
        on e.tienda_id = t.tienda_id
    left join municipios m
        on t.cod_municipio_ine = m.cod_municipio_ine
    left join provincias pr
        on m.cod_provincia_ine = pr.cod_provincia_ine
    left join ccaa c
        on m.cod_ccaa_ine = c.cod_ccaa_ine
    left join tipos_zona tz
        on m.cod_tipo_zona = tz.cod_tipo_zona
    left join generos g
        on e.cod_genero = g.cod_genero
    left join puestos p
        on e.cod_puesto = p.cod_puesto

)

select * from dim