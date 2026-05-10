with canales as (

    select 'ONLINE'         as canal_id,
           'Online'         as canal_nombre,
           true             as es_digital

    union all

    select 'FISICA'         as canal_id,
           'Tienda física'  as canal_nombre,
           false            as es_digital

)

select
    {{ dbt_utils.generate_surrogate_key(['canal_id']) }}         as canal_sk,
    canal_id,
    canal_nombre,
    es_digital,
    current_timestamp()                                          as _loaded_at

from canales