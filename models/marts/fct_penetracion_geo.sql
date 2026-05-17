with ventas as (

    select * from {{ ref('stg__ventas') }}

),

dim_tiempo as (

    select tiempo_sk, fecha, anio, mes
    from {{ ref('dim_tiempo') }}

),

dim_canal as (

    select canal_sk, canal_nombre as canal, es_digital
    from {{ ref('dim_canal') }}

),

dim_geografia as (

    select cod_municipio_ine, municipio, poblacion, tiene_tienda
    from {{ ref('dim_geografia') }}

),

ventas_agrupadas as (

    select
        g.cod_municipio_ine,
        t.tiempo_sk,
        t.anio,
        t.mes,
        c.canal_sk,
        c.es_digital,
        count(v.venta_id)                                        as num_ventas,
        count(distinct v.cliente_id)                             as num_clientes_distintos,
        round(sum(v.importe_neto), 2)                            as importe_neto_total,
        round(avg(v.ticket_medio), 2)                            as ticket_medio,
        round(
            sum(iff(c.es_digital = true, 1, 0)) /
            nullif(count(v.venta_id), 0) * 100
        , 2)                                                     as pct_ventas_online

    from ventas v
    left join dim_tiempo t
        on v.fecha = t.fecha
    left join dim_canal c
        on v.cod_canal = c.canal_sk
    left join dim_geografia g
        on v.cod_municipio_venta_ine = g.cod_municipio_ine
    where v.cod_municipio_venta_ine is not null
    group by
        g.cod_municipio_ine,
        t.tiempo_sk,
        t.anio,
        t.mes,
        c.canal_sk,
        c.es_digital

),

fct as (

    select
        -- claves
        va.cod_municipio_ine,
        va.tiempo_sk,
        va.canal_sk,

        -- métricas de ventas
        va.num_ventas,
        va.num_clientes_distintos,
        va.importe_neto_total,
        va.ticket_medio,
        va.pct_ventas_online,

        -- métricas por habitante
        round(
            va.num_ventas / nullif(g.poblacion, 0) * 1000
        , 4)                                                     as ventas_por_habitante,
        round(
            va.importe_neto_total / nullif(g.poblacion, 0)
        , 4)                                                     as ingreso_por_habitante,

        -- flag tienda física
        g.tiene_tienda                                           as tiene_tienda_fisica,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from ventas_agrupadas va
    left join dim_geografia g
        on va.cod_municipio_ine = g.cod_municipio_ine

)

select * from fct