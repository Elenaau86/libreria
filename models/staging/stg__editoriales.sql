with source as (

    select * from {{ ref('stg__catalogo_productos') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['editorial']) }}    as cod_editorial,
        trim(editorial)                                          as editorial,
        count(*) over (partition by trim(editorial))             as num_titulos

    from source
    where editorial is not null

)

select * from dim
order by editorial
