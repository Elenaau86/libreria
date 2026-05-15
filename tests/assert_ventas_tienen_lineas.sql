-- tests/assert_ventas_tienen_lineas.sql
-- Falla si hay ventas sin ninguna línea de detalle. detecta desincronización entre tablas
select v.venta_id
from {{ ref('stg_bronze__ventas_raw') }} v
left join {{ ref('stg_bronze__lineas_venta_raw') }} l
    on v.venta_id = l.venta_id
where l.venta_id is null