-- Falla si las unidades totales son menores que el número de líneas
select venta_id, total_lineas, total_unidades
from {{ ref('fct_ventas') }}
where total_unidades < total_lineas