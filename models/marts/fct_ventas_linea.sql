with lineas as (

    select * from {{ ref('stg_bronze__lineas_venta_raw') }}

),

ventas as (

    select venta_id, fecha, canal, tienda_id
    from {{ ref('stg_bronze__ventas_raw') }}

),

dim_tiempo as (

    select tiempo_sk, fecha
    from {{ ref('dim_tiempo') }}

),

dim_canal as (

    select canal_sk, canal_id
    from {{ ref('dim_canal') }}

),

fct as (

    select
        -- clave natural
        l.linea_id,

        -- FKs dimensiones
        t.tiempo_sk,
        c.canal_sk,
        v.tienda_id,
        l.isbn,

        -- referencia a fct_ventas
        l.venta_id,

        -- atributos de línea
        l.num_linea,
        l.categoria,

        -- métricas
        l.unidades,
        l.precio_unitario,
        l.importe_bruto,
        l.descuento_pct,
        l.descuento_importe,
        l.importe_neto,

        -- métricas derivadas con precio de coste desde dim_producto
        p.precio_coste,
        round(l.unidades * p.precio_coste, 2)                    as coste_total,
        round(l.importe_neto - (l.unidades * p.precio_coste), 2) as margen_bruto_importe,
        round(
            iff(l.importe_neto = 0, null,
                (l.importe_neto - (l.unidades * p.precio_coste)) /
                 l.importe_neto * 100
            ), 2
        )                                                        as margen_bruto_pct_real,
        round(
            iff(p.precio_pvp = 0, null,
                l.precio_unitario / p.precio_pvp
            ), 4
        )                                                        as precio_vs_pvp_ratio,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from lineas l
    inner join ventas v
        on l.venta_id = v.venta_id
    left join dim_tiempo t
        on v.fecha = t.fecha
    left join dim_canal c
        on iff(v.canal = 'Online', 'ONLINE', 'FISICA') = c.canal_id
    left join {{ ref('dim_producto') }} p
        on l.isbn = p.isbn

)

select * from fct