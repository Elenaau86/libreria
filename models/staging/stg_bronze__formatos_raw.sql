{{
    config(
        materialized = 'view',
        schema       = 'SILVER'
    )
}}

with source as (

    select * from {{ ref('stg_bronze__catalogo_productos_raw') }}

),

dim as (

    select distinct
        trim(formato)                                            as formato,
        count(*) over (partition by trim(formato))               as num_titulos,
        round(avg(precio_pvp) over (
            partition by trim(formato)), 2)                      as precio_pvp_medio

    from source
    where formato is not null

)

select * from dim
order by formato
