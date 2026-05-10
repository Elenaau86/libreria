with source as (

    select * from {{ source('bronze', 'tiendas_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

renamed as (

    select
        -- clave
        s.tienda_id,

        -- datos
        trim(s.nombre)                                                   as nombre,
        trim(s.municipio)                                                as municipio,
        try_cast(s.m2       as integer)                                  as m2,
        try_cast(s.empleados as integer)                                 as num_empleados,

        -- canal como FK
        c.cod_canal,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source s
    left join canales c
        on iff(s.tienda_id = 'ONLINE', 'Online', 'Tienda física') = c.canal

)

select * from renamed