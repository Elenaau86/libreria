with clientes as (

    select * from {{ ref('stg_bronze__bookstore_clientes_raw') }}

),

segmentos as (

    select distinct
        segmento_edad,
        canal_preferido
    from clientes
    where es_anonimo = false
      and segmento_edad    is not null
      and canal_preferido  is not null

),

dim as (

    select
        -- clave surrogada — necesaria porque la clave es compuesta
        {{ dbt_utils.generate_surrogate_key(['segmento_edad', 'canal_preferido']) }}  as segmento_sk,

        -- atributos
        segmento_edad,
        canal_preferido,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from segmentos

)

select * from dim
order by segmento_edad, canal_preferido