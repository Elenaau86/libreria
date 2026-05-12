{% snapshot snp_empleados %}

{{
    config(
        target_database = 'DEV_BRONZE_DB',
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
    edad,                  
    puesto,
    tienda_id,
    salario_mensual_bruto,
    fecha_contratacion
from {{ source('bronze', 'empleados_raw') }}

{% endsnapshot %}