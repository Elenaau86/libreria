with fechas as (

    select distinct cast(fecha as date) as fecha
    from {{ ref('stg__ventas') }}
    where fecha is not null

),

dim as (

    select
        -- clave surrogada
        {{ dbt_utils.generate_surrogate_key(['fecha']) }}        as tiempo_sk,

        -- clave natural
        cast(to_char(fecha, 'YYYYMMDD') as integer)              as tiempo_id,

        -- fecha
        fecha,

        -- año
        year(fecha)                                              as anio,

        -- trimestre
        quarter(fecha)                                           as trimestre,

        -- mes
        month(fecha)                                             as mes,

        -- nombre del mes
        case month(fecha)
            when 1  then 'Enero'
            when 2  then 'Febrero'
            when 3  then 'Marzo'
            when 4  then 'Abril'
            when 5  then 'Mayo'
            when 6  then 'Junio'
            when 7  then 'Julio'
            when 8  then 'Agosto'
            when 9  then 'Septiembre'
            when 10 then 'Octubre'
            when 11 then 'Noviembre'
            when 12 then 'Diciembre'
        end                                                      as mes_nombre,

        -- semana ISO
        weekiso(fecha)                                           as semana,

        -- día de la semana
        case dayofweekiso(fecha)
            when 1 then 'Lunes'
            when 2 then 'Martes'
            when 3 then 'Miércoles'
            when 4 then 'Jueves'
            when 5 then 'Viernes'
            when 6 then 'Sábado'
            when 7 then 'Domingo'
        end                                                      as dia_semana,

        -- flag fin de semana
        iff(dayofweekiso(fecha) in (6, 7), true, false)          as es_fin_semana,

        -- metadatos
        current_timestamp()                                      as _loaded_at

    from fechas

)

select * from dim
order by tiempo_id