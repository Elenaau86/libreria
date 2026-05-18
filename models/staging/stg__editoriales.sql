with source as (

    select * from {{ source('bronze', 'catalogo_productos_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['trim(editorial)']) }}     as cod_editorial,
        trim(editorial)                                                 as editorial,
        count(*) over (partition by trim(editorial))                    as num_titulos

    from source
    where editorial is not null

)

select * from dim
order by editorial
