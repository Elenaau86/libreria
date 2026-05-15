with source as (

    select * from {{ source('bronze', 'municipios_raw') }}

),

dim as (

    select distinct
        try_cast(cod_provincia_ine as integer)                    as cod_provincia_ine,
        trim(provincia)                                           as provincia,
        try_cast(cod_ccaa_ine as integer)                         as cod_ccaa_ine,
        count(*) over (partition by trim(provincia))              as num_municipios

    from source
    where provincia is not null

)

select * from dim
order by provincia