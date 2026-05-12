with source as (

    select * from {{ ref('snp_empleados') }}

),

generos as (

    select cod_genero, genero
    from {{ ref('stg_bronze__generos_raw') }}

),

puestos as (

    select cod_puesto, puesto
    from {{ ref('stg_bronze__puestos_raw') }}

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
        g.cod_genero,
        p.cod_puesto,

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
        current_timestamp()                                              as _loaded_at,

        -- Columnas de control del snapshot (SCD2)
        dbt_scd_id,
        dbt_valid_from,
        dbt_valid_to

    from source s
    left join generos g
        on nullif(trim(s.genero), '-') = g.genero
    left join puestos p
        on nullif(trim(s.puesto), '-') = p.puesto

)

select * from renamed