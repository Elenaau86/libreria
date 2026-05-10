with

source as (

    select * from {{ source('bronze', 'tiendas_raw') }}

),

renamed as (

    select
        -- clave
        tienda_id,

        -- datos
        trim(nombre)                                                     as nombre,
        trim(municipio)                                                  as municipio,
        try_cast(m2       as integer)                                    as m2,
        try_cast(empleados as integer)                                   as num_empleados,

        -- derivado
        iff(tienda_id = 'ONLINE', 'Online', 'Tienda física')            as canal,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source

)

select * from renamed