with source as (

    select * from {{ source('bronze', 'empleados_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['genero']) }}        as cod_genero,
        trim(genero)                                              as genero,
        count(*) over (partition by trim(genero))                 as num_empleados

    from source
    where genero is not null
      and trim(genero) != '-'

)

select * from dim
order by genero