with clientes as (

    select * from {{ ref('stg_bronze__clientes_raw') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg_bronze__canales_raw') }}

),

segmentos as (

    select distinct
        cl.segmento_edad,
        ca.canal                                                 as canal_preferido
    from clientes cl
    left join canales ca
        on cl.cod_canal_preferido = ca.cod_canal
    where cl.es_anonimo = false
      and cl.segmento_edad        is not null
      and cl.cod_canal_preferido  is not null

),

dim as (

    select
        {{ dbt_utils.generate_surrogate_key(['segmento_edad', 'canal_preferido']) }} as segmento_sk,
        segmento_edad,
        canal_preferido,
        current_timestamp()                                      as _loaded_at

    from segmentos

)

select * from dim
order by segmento_edad, canal_preferido