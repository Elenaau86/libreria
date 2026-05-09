with

source as (

    select * from {{ source('bronze', 'bookstore_empleados_raw') }}

),

renamed as (

    select
        -- claves
        empleado_id,
        tienda_id,

        -- datos personales
        trim(nombre)                                                     as nombre,
        nullif(trim(genero), '-')                                        as genero,
        try_cast(nullif(edad, '-') as integer)                           as edad,

        -- puesto
        trim(puesto)                                                     as puesto,
        case
            when trim(puesto) ilike '%director%'    then 'Dirección'
            when trim(puesto) ilike '%responsable%' then 'Mando intermedio'
            when trim(puesto) ilike '%senior%'      then 'Operativo senior'
            else                                         'Operativo'
        end                                                              as categoria_puesto,

        -- fechas y antigüedad
        try_cast(nullif(fecha_contratacion, '-') as date)                as fecha_contratacion,
        round(
            datediff('day',
                try_cast(nullif(fecha_contratacion, '-') as date),
                current_date()
            ) / 365.25, 1
        )                                                                as antiguedad_anios,

        -- salario — viene como '2.891,44 €', hay que limpiar
        round(
             try_cast(
                replace(
                    replace(
                        split_part(nullif(salario_mensual_bruto, '-'), ' ', 1),
                    '.', ''),
                ',', '.')
            as numeric(10,2)), 2
        )                                                                as salario_mensual_bruto,

        -- coste anual estimado
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