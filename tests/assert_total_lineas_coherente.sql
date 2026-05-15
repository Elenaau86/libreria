-- tests/assert_total_lineas_coherente.sql
-- Falla si total_lineas declarado no coincide con las líneas reales. detecta inconsistencias en cabeceras
select v.venta_id
from {{ ref('stg_bronze__ventas_raw') }} v
inner join (
    select venta_id, count(*) as lineas_reales
    from {{ ref('stg_bronze__lineas_venta_raw') }}
    group by venta_id
) l on v.venta_id = l.venta_id
where v.total_lineas != l.lineas_reales