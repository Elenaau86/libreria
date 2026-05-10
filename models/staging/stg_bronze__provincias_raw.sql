with source as (

    select * from {{ source('bronze', 'municipios_raw') }}

),

dim as (

    select distinct
        cod_provincia_ine,
        provincia,
        ccaa,
        count(*) over (partition by cod_provincia_ine)           as num_municipios

    from source
    where provincia is not null

)

select * from dim
order by provincia