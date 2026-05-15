-- Falla si hay ventas donde el importe neto supera al bruto
select venta_id, importe_bruto, importe_neto
from {{ ref('fct_ventas') }}
where importe_neto > importe_bruto