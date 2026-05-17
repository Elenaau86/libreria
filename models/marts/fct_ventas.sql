-- fct_ventas.sql
-- INCREMENTAL con estrategia MERGE.
-- Filtra por _src_loaded_at propagado desde stg__ventas,
-- de modo que solo se procesan las ventas nuevas o corregidas en cada carga.
-- El merge actualiza filas existentes si llegan correcciones.
--
-- _src_loaded_at se incluye en el SELECT para que {{ this }} lo tenga
-- disponible en la siguiente ejecución incremental.
 
{{
    config(
        materialized         = 'incremental',
        unique_key           = 'venta_id',
        on_schema_change     = 'append_new_columns',
        incremental_strategy = 'merge'
    )
}}
 
with ventas as (
 
    select * from {{ ref('stg__ventas') }}
 
    {% if is_incremental() %}
        where _src_loaded_at > (select max(_src_loaded_at) from {{ this }})
    {% endif %}
 
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
        cod_segmento_edad,       
        cod_canal_preferido,
        cod_municipio_ine
    from {{ ref('stg__clientes') }}

),

segmentos as (

    select cod_segmento_edad, segmento_edad
    from {{ ref('stg__segmentos_edad') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg__canales') }}

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
            v.cod_municipio_venta_ine = cl.cod_municipio_ine,
            true, false
        )                                                        as misma_zona,

        -- metadatos
        v._src_loaded_at,
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
    left join segmentos s_edad
        on cl.cod_segmento_edad = s_edad.cod_segmento_edad
    left join canales ca
        on cl.cod_canal_preferido = ca.cod_canal
    left join dim_segmento seg
        on s_edad.segmento_edad = seg.segmento_edad  
        and ca.canal            = seg.canal_preferido

)

select * from fct