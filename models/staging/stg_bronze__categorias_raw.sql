with source as (

    select * from {{ ref('stg_bronze__catalogo_productos_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['categoria']) }}    as cod_categoria,
        trim(categoria)                                          as categoria,
        count(*) over (partition by trim(categoria))             as num_titulos,
        round(avg(precio_pvp) over (
            partition by trim(categoria)), 2)                    as precio_pvp_medio,
        round(avg(margen_bruto_pct) over (
            partition by trim(categoria)), 2)                    as margen_medio_pct

    from source
    where categoria is not null

)

select * from dim
order by categoria
