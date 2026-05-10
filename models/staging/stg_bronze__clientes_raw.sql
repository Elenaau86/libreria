with source as (

    select * from {{ source('bronze', 'clientes_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

renamed as (

    select
        -- clave
        s.cliente_id,

        -- datos personales
        trim(s.nombre)                                                   as nombre,
        try_cast(nullif(s.edad, '-') as integer)                         as edad,
        nullif(trim(s.segmento_edad), '-')                               as segmento_edad,

        -- geografía
        nullif(trim(s.municipio),  '-')                                  as municipio,
        nullif(trim(s.provincia),  '-')                                  as provincia,
        nullif(trim(s.ccaa),       '-')                                  as ccaa,

        -- canal preferido como FK
        c.cod_canal                                                      as cod_canal_preferido,

        -- comportamiento
        try_cast(nullif(s.fecha_alta, '-') as date)                      as fecha_alta,
        case
            when trim(s.newsletter) = 'Sí' then true
            when trim(s.newsletter) = 'No' then false
            else null
        end                                                              as newsletter,

        -- flag
        iff(s.cliente_id = 'SIN_REGISTRO', true, false)                 as es_anonimo,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source s
    left join canales c
        on nullif(trim(s.canal_preferido), '-') = c.canal

)

select * from renamed
