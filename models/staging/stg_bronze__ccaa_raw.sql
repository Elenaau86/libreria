with source as (

    select * from {{ source('bronze', 'municipios_raw') }}

),

dim as (

    select distinct
        cod_ccaa_ine,
        ccaa,
        count(*) over (partition by cod_ccaa_ine)                as num_municipios,
        count(distinct provincia) over (
            partition by cod_ccaa_ine)                           as num_provincias

    from source
    where ccaa is not null

)

select * from dim
order by ccaa