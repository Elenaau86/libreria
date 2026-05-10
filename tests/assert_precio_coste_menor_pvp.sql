-- Falla si el precio de coste supera al PVP en algún producto
select isbn, precio_pvp, precio_coste
from {{ ref('dim_producto') }}
where precio_coste >= precio_pvp