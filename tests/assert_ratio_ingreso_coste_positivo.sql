-- Falla si hay empleados con ratio ingreso/coste negativo
select empleado_id, tiempo_sk, ratio_ingreso_coste
from {{ ref('fct_rendimiento_empleado') }}
where ratio_ingreso_coste < 0
  and empleado_id != 'ONLINE'