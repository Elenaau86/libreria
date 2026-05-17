with source as (

    select * from {{ source('bronze', 'municipios_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['tipo_zona']) }}     as cod_tipo_zona,
        trim(tipo_zona)                                           as tipo_zona,
        count(*) over (partition by trim(tipo_zona))              as num_municipios,
        round(avg(try_cast(renta_media as integer)) over (
            partition by trim(tipo_zona)), 0)                     as renta_media_zona,
        round(avg(try_cast(poblacion as integer)) over (
            partition by trim(tipo_zona)), 0)                     as poblacion_media_zona

    from source
    where tipo_zona is not null

)

select * from dim
order by tipo_zona