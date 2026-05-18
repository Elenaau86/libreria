with source as (

    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['trim(autor)']) }}  as cod_autor,
        trim(autor)                                              as autor,
        count(*) over (partition by trim(autor))                 as num_titulos

    from source
    where autor is not null

)

select * from dim
order by autor