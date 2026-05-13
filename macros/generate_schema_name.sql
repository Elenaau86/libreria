{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {# Capturamos la variable de entorno que acabamos de crear #}
    {%- set env = env_var('DBT_ENVIRONMENTS', 'DEV') -%}

    {# Si estamos en PRO y hay un esquema personalizado (como 'silver' o 'gold') #}
    {%- if env == 'PRO' and custom_schema_name is not none -%}
        
        {{ custom_schema_name | trim }}

    {%- elif custom_schema_name is not none -%}
        
        {# En DEV, si quieres que se vea ordenado, puedes dejarlo igual o añadirle un prefijo #}
        {{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}


