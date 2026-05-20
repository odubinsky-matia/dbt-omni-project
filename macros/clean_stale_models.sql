{% macro drop_old_relations(dry_run=true) %}
    {%- set schema_filter %}
        {%- if target.type == 'bigquery' -%}
            LOWER(table_schema) LIKE 'dbt_%'
        {%- else -%}
            table_schema ILIKE 'dbt_%'
        {%- endif -%}
    {%- endset %}

    {%- set old_relation_query %}
        select
            table_schema,
            table_name,
            table_type
        from information_schema.tables
        where {{ schema_filter }}
          and table_name not in (
              select upper(alias) from {{ ref('__dbt_manifest') }}
          )
    {%- endset %}

    {% if execute %}
        {% set results = run_query(old_relation_query) %}
        {% for row in results %}
            {%- set schema_col = 'table_schema' if target.type == 'bigquery' else 'TABLE_SCHEMA' -%}
            {%- set name_col   = 'table_name'   if target.type == 'bigquery' else 'TABLE_NAME'   -%}
            {%- set type_col   = 'table_type'   if target.type == 'bigquery' else 'TABLE_TYPE'   -%}
            {% set drop_query %}
                drop {{ row[type_col] }} if exists
                {{ row[schema_col] }}.{{ row[name_col] }}
            {% endset %}
            {% if dry_run %}
                {{ log("Would drop: " ~ row[schema_col] ~ "." ~ row[name_col], info=true) }}
            {% else %}
                {{ log("Dropping: " ~ row[schema_col] ~ "." ~ row[name_col], info=true) }}
                {% do run_query(drop_query) %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}
