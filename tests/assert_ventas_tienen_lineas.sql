-- tests/assert_ventas_tienen_lineas.sql
-- Falla si hay ventas sin ninguna línea de detalle. detecta desincronización entre tablas
select v.venta_id
from {{ ref('stg__ventas') }} v
left join {{ ref('stg__lineas_venta') }} l
    on v.venta_id = l.venta_id
where l.venta_id is null