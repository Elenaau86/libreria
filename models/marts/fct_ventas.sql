with ventas as (

    select * from {{ ref('stg_bronze__bookstore_ventas_raw') }}

),

dim_tiempo as (

    select tiempo_sk, fecha
    from {{ ref('dim_tiempo') }}

),

dim_canal as (

    select canal_sk, canal_id
    from {{ ref('dim_canal') }}

),

dim_geografia as (

    select
        geografia_sk,
        municipio,
        cod_municipio_ine
    from {{ ref('dim_geografia') }}
    qualify row_number() over (
        partition by cod_municipio_ine
        order by municipio
    ) = 1

),

clientes as (

    select
        cliente_id,
        segmento_edad,
        canal_preferido,
        municipio
    from {{ ref('stg_bronze__bookstore_clientes_raw') }}

),

municipios as (

    select municipio, cod_municipio_ine
    from {{ ref('stg_bronze__bookstore_municipios_raw') }}

),

dim_segmento as (

    select segmento_sk, segmento_edad, canal_preferido
    from {{ ref('dim_segmento_cliente') }}

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
        g.geografia_sk                                           as geo_sk_venta,
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

        -- misma_zona — comparando cod_municipio_ine de venta vs cliente
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
        on iff(v.canal = 'Online', 'ONLINE', 'FISICA') = c.canal_id
    left join dim_geografia g
        on v.cod_municipio_venta_ine = g.cod_municipio_ine
    left join clientes cl
        on v.cliente_id = cl.cliente_id
    left join municipios m
        on cl.municipio = m.municipio
    left join dim_segmento seg
        on cl.segmento_edad    = seg.segmento_edad
        and cl.canal_preferido = seg.canal_preferido

)

select * from fct