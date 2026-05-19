-- Falla si fct_ventas en Gold está vacía. detecta si el pipeline completo llegó hasta Gold
select 1
from (select count(*) as total from {{ ref('fct_ventas') }})
where total < 100