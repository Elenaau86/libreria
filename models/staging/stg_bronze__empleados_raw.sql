with source as (

    select * from {{ snapshot('snp_empleados') }}
    
),

renamed as (

    select
        -- claves
        empleado_id,
        tienda_id,

        -- datos personales
        trim(nombre)                                                     as nombre,
        try_cast(nullif(edad, '-') as integer)                           as edad,

        -- FKs hacia tablas normalizadas
        {{ dbt_utils.generate_surrogate_key(['genero']) }}               as cod_genero,
        {{ dbt_utils.generate_surrogate_key(['puesto']) }}               as cod_puesto,

        -- fechas y antigüedad
        try_cast(nullif(fecha_contratacion, '-') as date)                as fecha_contratacion,
        round(
            datediff('day',
                try_cast(nullif(fecha_contratacion, '-') as date),
                current_date()
            ) / 365.25, 1
        )                                                                as antiguedad_anios,

        -- salario
        round(
            try_cast(
                replace(
                    replace(
                        split_part(salario_mensual_bruto, ' ', 1),
                    '.', ''),
                ',', '.')
            as numeric(10,2)), 2
        )                                                                as salario_mensual_bruto,

        round(
            try_cast(
                replace(
                    replace(
                        split_part(salario_mensual_bruto, ' ', 1),
                    '.', ''),
                ',', '.')
            as numeric(10,2)) * 12, 2
        )                                                                as coste_anual_estimado,

        -- flag
        iff(empleado_id = 'ONLINE', true, false)                        as es_virtual,

        -- metadatos
        current_timestamp()                                              as _loaded_at

    from source

)

select * from renamed