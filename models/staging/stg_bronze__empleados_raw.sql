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
        edad                                                             as edad,

        -- FKs hacia tablas normalizadas
        g.cod_genero,
        p.cod_puesto,

        -- fechas y antigüedad
        fecha_contratacion                                              as fecha_contratacion,
        round(
            datediff('day',
                fecha_contratacion,
                current_date()
            ) / 365.25, 1
        )                                                               as antiguedad_anios,

       salario_mensual_bruto                                        as salario_mensual_bruto,

        round(salario_mensual_bruto * 12, 2)                         as coste_anual_estimado,

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