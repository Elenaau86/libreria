with ventas as (

    select * from {{ ref('stg_bronze__bookstore_ventas_raw') }}

),

dim_tiempo as (

    select tiempo_sk, fecha, anio, mes
    from {{ ref('dim_tiempo') }}

),

empleados as (

    select empleado_id, salario_mensual_bruto
    from {{ ref('stg_bronze__bookstore_empleados_raw') }}

),

-- agrupamos ventas por empleado y mes
ventas_agrupadas as (

    select
        v.empleado_id,
        t.tiempo_sk,
        t.anio,
        t.mes,
        v.tienda_id,

        -- métricas agregadas
        count(v.venta_id)                                        as num_ventas,
        sum(v.importe_neto)                                      as importe_neto_total,
        round(avg(v.ticket_medio), 2)                            as ticket_medio,
        sum(v.total_unidades)                                    as unidades_vendidas,
        round(avg(v.descuento_pct), 2)                           as descuento_medio_pct,
        -- días hábiles aproximados en un mes
        round(count(v.venta_id) / 22.0, 2)                      as ventas_por_dia

    from ventas v
    left join dim_tiempo t
        on v.fecha = t.fecha
    group by
        v.empleado_id,
        t.tiempo_sk,
        t.anio,
        t.mes,
        v.tienda_id

),

fct as (

    select
        -- claves
        va.empleado_id,
        va.tiempo_sk,
        va.tienda_id,

        -- métricas de ventas
        va.num_ventas,
        va.importe_neto_total,
        va.ticket_medio,
        va.unidades_vendidas,
        va.descuento_medio_pct,
        va.ventas_por_dia,

        -- coste laboral del mes
        e.salario_mensual_bruto                                  as coste_laboral_mes,

        -- ratio ingreso / coste
        round(
            iff(e.salario_mensual_bruto = 0, null,
                va.importe_neto_total / e.salario_mensual_bruto
            ), 4
        )                                                        as ratio_ingreso_coste,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from ventas_agrupadas va
    left join empleados e
        on va.empleado_id = e.empleado_id

)

select * from fct