with source as (

    select * from {{ ref('stg__catalogo_productos') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['formato']) }}      as cod_formato,
        trim(formato)                                            as formato,
        count(*) over (partition by trim(formato))               as num_titulos,
        round(avg(precio_pvp) over (
            partition by trim(formato)), 2)                      as precio_pvp_medio

    from source
    where formato is not null

)

select * from dim
order by formato
