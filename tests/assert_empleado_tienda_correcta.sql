-- Falla si un empleado tiene ventas en una tienda distinta a la suya
select
    v.venta_id,
    v.empleado_id,
    v.tienda_id        as tienda_venta,
    e.tienda_id        as tienda_empleado
from {{ ref('fct_ventas') }} v
left join {{ ref('dim_empleado') }} e
    on v.empleado_id = e.empleado_id
where v.tienda_id != e.tienda_id
  and v.tienda_id  != 'ONLINE'
  and e.es_virtual  = false