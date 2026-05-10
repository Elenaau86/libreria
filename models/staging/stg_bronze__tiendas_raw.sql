with source as (

    select * from {{ source('bronze', 'tiendas_raw') }}

),

municipios as (

    select municipio, cod_municipio_ine
    from {{ source('bronze', 'municipios_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

renamed as (

    select
        s.tienda_id,
        trim(s.nombre)                                                   as nombre,
        try_cast(s.m2       as integer)                                  as m2,
        m.cod_municipio_ine,
        c.cod_canal,
        current_timestamp()                                              as _loaded_at

    from source s
    left join municipios m
        on trim(s.municipio) = trim(m.municipio)
    left join canales c
        on iff(s.tienda_id = 'ONLINE', 'Online', 'Tienda física') = c.canal

    union all

    -- Registro virtual ONLINE
    select
        'ONLINE'                                                         as tienda_id,
        'Canal Online'                                                   as nombre,
        null                                                             as m2,
        null                                                             as num_empleados,
        null                                                             as cod_municipio_ine,
        (select cod_canal from canales where canal = 'Online')           as cod_canal,
        current_timestamp()                                              as _loaded_at

)

select * from renamed