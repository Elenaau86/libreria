with source as (

    select * from {{ ref('stg__catalogo_productos') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['autor']) }}        as cod_autor,
        trim(autor)                                              as autor,
        count(*) over (partition by trim(autor))                 as num_titulos

    from source
    where autor is not null

)

select * from dim
order by autor