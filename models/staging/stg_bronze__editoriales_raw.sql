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
        trim(editorial)                                          as editorial,
        count(*) over (partition by trim(editorial))             as num_titulos

    from source
    where editorial is not null

)

select * from dim
order by editorial
