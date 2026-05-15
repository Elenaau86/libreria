{% macro generate_database_name(custom_database_name, node) -%}

    {#
        Macro que resuelve el nombre de la database según el entorno activo.
        target.name debe ser 'dev' o 'pro' (configurado en dbt Cloud).

        Ejemplos:
            target.name = 'dev'  →  DEV_SILVER_DB, DEV_GOLD_DB
            target.name = 'pro'  →  PRO_SILVER_DB, PRO_GOLD_DB
    #}

    {%- set env_prefix = target.name | upper -%}  {# DEV o PRO #}

    {%- if custom_database_name is not none -%}

        {# Elimina cualquier prefijo de entorno existente y sustituye por el activo #}
        {%- set db_suffix = custom_database_name
                            | replace('DEV_', '')
                            | replace('PRO_', '') -%}

        {{ env_prefix }}_{{ db_suffix | trim }}

    {%- else -%}

        {{ target.database | trim }}

    {%- endif -%}

{%- endmacro %}
