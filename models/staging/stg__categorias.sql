with source as (

    {#select * from {{ ref('stg__catalogo_productos') }}#}
    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['trim(categoria)']) }}         as cod_categoria,
        trim(categoria)                                                     as categoria,
        count(*) over (partition by trim(categoria))                        as num_titulos,
        round(avg(round(try_cast(replace(precio_venta_pvp, ',', '.') as numeric(10,2)), 2)) over (
            partition by trim(categoria)), 2)                               as precio_pvp_medio,
        round(avg(margen_bruto_pct) over (
            partition by trim(categoria)), 2)                               as margen_medio_pct

    from source
    where categoria is not null

)

select * from dim
order by categoria
