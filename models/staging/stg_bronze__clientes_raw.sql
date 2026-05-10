with

source as (

    select * from {{ source('bronze', 'clientes_raw') }}

),

renamed as (

    select
        -- clave
        cliente_id,

        -- datos personales
        trim(nombre)                                                     as nombre,
        try_cast(nullif(edad, '-') as integer)                           as edad,
        nullif(trim(segmento_edad), '-')                                 as segmento_edad,

        -- geografía
        nullif(trim(municipio),       '-')                               as municipio,
        nullif(trim(provincia),       '-')                               as provincia,
        nullif(trim(ccaa),            '-')                               as ccaa,

        -- comportamiento
        nullif(trim(canal_preferido), '-')                               as canal_preferido,
        try_cast(nullif(fecha_alta,   '-') as date)                      as fecha_alta,
        case
            when trim(newsletter) = 'Sí'  then true
            when trim(newsletter) = 'No'  then false
            else null
        end                                                             as newsletter,

        -- flag
        iff(cliente_id = 'SIN_REGISTRO', true, false)                   as es_anonimo,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source

)

select * from renamed