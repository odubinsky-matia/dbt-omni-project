{% macro drop_old_relations(dry_run=true) %}
    {%- set old_relation_query %}
        select
            table_schema,
            table_name,
            table_type
        from information_schema.tables
        where table_schema ilike 'dbt_%'
          and table_name not in (
              select upper(alias) from {{ ref('__dbt_manifest') }}
          )
    {%- endset %}

    {% if execute %}
        {% set results = run_query(old_relation_query) %}
        {% for row in results %}
            {% set drop_query %}
                drop {{ row.TABLE_TYPE }} if exists
                {{ row.TABLE_SCHEMA }}.{{ row.TABLE_NAME }}
            {% endset %}
            {% if dry_run %}
                {{ log("Would drop: " ~ row.TABLE_SCHEMA ~ "." ~ row.TABLE_NAME, info=true) }}
            {% else %}
                {{ log("Dropping: " ~ row.TABLE_SCHEMA ~ "." ~ row.TABLE_NAME, info=true) }}
                {% do run_query(drop_query) %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}
