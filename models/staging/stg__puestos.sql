with source as (

    select * from {{ source('bronze', 'empleados_raw') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['trim(puesto)']) }}  as cod_puesto,
        trim(puesto)                                              as puesto,
        case
            when trim(puesto) ilike '%director%'    then 'Dirección'
            when trim(puesto) ilike '%responsable%' then 'Mando intermedio'
            when trim(puesto) ilike '%senior%'      then 'Operativo senior'
            else                                         'Operativo'
        end                                                       as categoria_puesto,
        count(*) over (partition by trim(puesto))                 as num_empleados,
        round(avg(try_cast(
            replace(replace(split_part(salario_mensual_bruto,' ',1),'.',''),',','.') 
            as numeric(10,2))) over (partition by trim(puesto)), 2) as salario_medio,
        round(min(try_cast(
            replace(replace(split_part(salario_mensual_bruto,' ',1),'.',''),',','.') 
            as numeric(10,2))) over (partition by trim(puesto)), 2) as salario_minimo,
        round(max(try_cast(
            replace(replace(split_part(salario_mensual_bruto,' ',1),'.',''),',','.') 
            as numeric(10,2))) over (partition by trim(puesto)), 2) as salario_maximo

    from source
    where puesto is not null
      and trim(puesto) != '-'
      and trim(salario_mensual_bruto) != '-'

)

select * from dim
order by categoria_puesto, puesto