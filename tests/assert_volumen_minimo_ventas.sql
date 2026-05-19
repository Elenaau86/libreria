-- Falla si hay menos de 100 ventas en Bronze (ingesta rota). detecta si la ingesta cargó datos incompletos
select 1
from (select count(*) as total from {{ ref('stg__ventas') }})
where total < 100