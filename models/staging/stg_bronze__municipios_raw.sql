with source as (

    select * from {{ source('bronze', 'municipios_raw') }}

),

renamed as (

    select
        trim(municipio)                                          as municipio,
        try_cast(cod_municipio_ine  as integer)                  as cod_municipio_ine,
        try_cast(cod_provincia_ine  as integer)                  as cod_provincia_ine,
        try_cast(cod_ccaa_ine       as integer)                  as cod_ccaa_ine,

        -- FK hacia stg_bronze__tipos_zona_raw usando el mismo hash
        {{ dbt_utils.generate_surrogate_key(['tipo_zona']) }}     as cod_tipo_zona,

        try_cast(renta_media as integer)                         as renta_media,
        try_cast(poblacion   as integer)                         as poblacion,
        case
            when try_cast(renta_media as integer) < 25000 then 'Renta baja'
            when try_cast(renta_media as integer) < 45000 then 'Renta media'
            else                                               'Renta alta'
        end                                                      as rango_renta,
        case
            when try_cast(poblacion as integer) < 100000  then 'Pequeña'
            when try_cast(poblacion as integer) < 500000  then 'Mediana'
            else                                               'Grande'
        end                                                      as rango_poblacion,
        current_timestamp()                                      as _loaded_at

    from source

)

select * from renamed