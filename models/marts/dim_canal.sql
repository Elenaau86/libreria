with canales as (

    select * from {{ ref('stg_bronze__canales_raw') }}

)

select
    cod_canal                                                    as canal_sk,
    canal                                                        as canal_id,
    canal                                                        as canal_nombre,
    es_digital,
    current_timestamp()                                          as _loaded_at

from canales