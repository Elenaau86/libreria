with source as (

    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['trim(formato)']) }}           as cod_formato,
        trim(formato)                                                       as formato,
        count(*) over (partition by trim(formato))                          as num_titulos,
        
        round(avg(round(try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)), 2))
            over (
                partition by trim(formato)), 2)                             as precio_pvp_medio

    from source
    where formato is not null

)

select * from dim
order by formato
