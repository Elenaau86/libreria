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
        trim(idioma)                                             as idioma,
        count(*) over (partition by trim(idioma))                as num_titulos

    from source
    where idioma is not null

)

select * from dim
order by idioma
