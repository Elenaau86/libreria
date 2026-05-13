{% snapshot snp_empleados %}

{{
    config(
        target_database = target.name | upper ~ '_BRONZE_DB',
        target_schema   = 'SNAPSHOTS',
        unique_key      = 'empleado_id',
        strategy        = 'check',
        check_cols      = ['puesto', 'tienda_id', 'salario_mensual_bruto']
    )
}}

select
    empleado_id,
    nombre,
    genero,
    try_cast(nullif(edad, '-') as integer)                       as edad,
    puesto,
    tienda_id,
    round(
        try_cast(
            replace(
                replace(
                    split_part(salario_mensual_bruto, ' ', 1),
                '.', ''),
            ',', '.')
        as numeric(10,2)), 2
    )                                                            as salario_mensual_bruto,
    try_cast(nullif(fecha_contratacion, '-') as date)            as fecha_contratacion
from {{ source('bronze', 'empleados_raw') }}

{% endsnapshot %}