with clientes as (

    select * from {{ ref('stg__clientes') }}

),

canales as (

    select cod_canal, canal
    from {{ ref('stg__canales') }}

),

segmentos as (

    select cod_segmento_edad, segmento_edad
    from {{ ref('stg__segmentos_edad') }}

),

dim as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['seg.segmento_edad', 'can.canal']) }} as segmento_sk,
        seg.segmento_edad,
        can.canal                                                        as canal_preferido,
        current_timestamp()                                              as _loaded_at

    from clientes c
    left join segmentos seg
        on c.cod_segmento_edad = seg.cod_segmento_edad
    left join canales can
        on c.cod_canal_preferido = can.cod_canal
    where c.es_anonimo = false
      and c.cod_segmento_edad    is not null
      and c.cod_canal_preferido  is not null

)

select * from dim
order by segmento_edad, canal_preferido