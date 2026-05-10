renamed as (

    select
        s.tienda_id,
        trim(s.nombre)                                                   as nombre,
        try_cast(s.m2       as integer)                                  as m2,
        m.cod_municipio_ine,
        c.cod_canal,
        current_timestamp()                                              as _loaded_at

    from source s
    left join municipios m
        on trim(s.municipio) = trim(m.municipio)
    left join canales c
        on iff(s.tienda_id = 'ONLINE', 'Online', 'Tienda física') = c.canal
    where s.tienda_id != 'ONLINE'    -- ← añadir este filtro

    union all

    -- Registro virtual ONLINE
    select
        'ONLINE'                                                         as tienda_id,
        'Canal Online'                                                   as nombre,
        null                                                             as m2,
        null                                                             as cod_municipio_ine,
        (select cod_canal from canales where canal = 'Online')           as cod_canal,
        current_timestamp()                                              as _loaded_at

)