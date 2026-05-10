{{ config(severity = 'warn') }}

-- Alerta de negocio: líneas vendidas por debajo del coste
-- Ocurre cuando el descuento aplicado supera el margen del producto
select linea_id, importe_neto, coste_total, margen_bruto_importe
from {{ ref('fct_ventas_linea') }}
where margen_bruto_importe < 0