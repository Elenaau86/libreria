with source as (

    select * from {{ source('bronze', 'clientes_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['segmento_edad']) }}  as cod_segmento_edad,
        trim(segmento_edad)                                        as segmento_edad

    from source
    where segmento_edad is not null
      and trim(segmento_edad) != '-'

)

select * from dim
order by segmento_edad