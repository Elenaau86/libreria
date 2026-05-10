with

source as (

    select * from {{ source('bronze', 'bookstore_municipios_raw') }}

),

renamed as (

    select
        -- clave surrogada — necesaria porque cod_municipio_ine no es único
        {{ dbt_utils.generate_surrogate_key(['municipio']) }}            as geografia_sk,

        -- clave natural (no única)
        try_cast(cod_municipio_ine  as integer)                          as cod_municipio_ine,

        -- claves
        trim(municipio)                                                  as municipio,
        try_cast(cod_provincia_ine  as integer)                          as cod_provincia_ine,
        try_cast(cod_ccaa_ine       as integer)                          as cod_ccaa_ine,

        -- nombres
        trim(provincia)                                                  as provincia,
        trim(ccaa)                                                       as ccaa,
        trim(tipo_zona)                                                  as tipo_zona,

        -- datos socioeconómicos
        try_cast(renta_media as integer)                                 as renta_media,
        try_cast(poblacion   as integer)                                 as poblacion,

        -- rangos derivados
        case
            when try_cast(renta_media as integer) < 25000 then 'Renta baja'
            when try_cast(renta_media as integer) < 45000 then 'Renta media'
            else                                               'Renta alta'
        end                                                              as rango_renta,

        case
            when try_cast(poblacion as integer) < 100000  then 'Pequeña'
            when try_cast(poblacion as integer) < 500000  then 'Mediana'
            else                                               'Grande'
        end                                                              as rango_poblacion,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source

)

select * from renamed