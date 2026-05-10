with source as (

    select * from {{ source('bronze', 'ventas_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['canal']) }}         as cod_canal,
        trim(canal)                                               as canal,
        iff(trim(canal) = 'Online', true, false)                  as es_digital

    from source
    where canal is not null

)

select * from dim
order by canal