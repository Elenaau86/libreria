with ventas as (

    select * from {{ ref('stg_bronze__ventas_raw') }}

),

dim_tiempo as (

    select tiempo_sk, fecha
    from {{ ref('dim_tiempo') }}

),

dim_canal as (

    select canal_sk, canal_nombre as canal, es_digital
    from {{ ref('dim_canal') }}

),

dim_geografia as (

    select cod_municipio_ine, municipio
    from {{ ref('dim_geografia') }}

),

clientes as (

    select
        cliente_id,
        segmento_edad,
        cod_canal_preferido,
        municipio
    from {{ ref('stg_bronze__clientes_raw') }}

),

municipios as (

    select municipio, cod_municipio_ine
    from {{ ref('stg_bronze__municipios_raw') }}

),

dim_segmento as (

    select segmento_sk, segmento_edad, canal_preferido
    from {{ ref('dim_segmento_cliente') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

fct as (

    select
        -- clave natural
        v.venta_id,

        -- FKs dimensiones
        t.tiempo_sk,
        c.canal_sk,
        v.tienda_id,
        v.empleado_id,
        v.cliente_id,
        g.cod_municipio_ine                                      as cod_municipio_venta,
        seg.segmento_sk,

        -- métricas
        v.importe_bruto,
        v.importe_neto,
        v.descuento_total,
        v.descuento_pct,
        v.total_lineas,
        v.total_unidades,
        v.ticket_medio,

        -- flags
        v.es_venta_anonima,
        v.tiene_municipio,

        -- misma_zona
        iff(
            v.cod_municipio_venta_ine = m.cod_municipio_ine,
            true, false
        )                                                        as misma_zona,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from ventas v
    left join dim_tiempo t
        on v.fecha = t.fecha
    left join dim_canal c
        on v.cod_canal = c.canal_sk
    left join dim_geografia g
        on v.cod_municipio_venta_ine = g.cod_municipio_ine
    left join clientes cl
        on v.cliente_id = cl.cliente_id
    left join municipios m
        on cl.municipio = m.municipio
    left join canales ca
        on cl.cod_canal_preferido = ca.cod_canal
    left join dim_segmento seg
        on cl.segmento_edad = seg.segmento_edad
        and ca.canal        = seg.canal_preferido

)

select * from fct