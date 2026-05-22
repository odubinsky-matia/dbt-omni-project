{% macro cast_float(expr) -%}
  {%- if target.type == 'bigquery' -%}
    CAST({{ expr }} AS FLOAT64)
  {%- else -%}
    {{ expr }}::float
  {%- endif -%}
{%- endmacro %}

{% macro cast_varchar(expr) -%}
  {%- if target.type == 'bigquery' -%}
    CAST({{ expr }} AS STRING)
  {%- else -%}
    {{ expr }}::varchar
  {%- endif -%}
{%- endmacro %}

{% macro datediff_days(start_date, end_date) -%}
  {%- if target.type == 'bigquery' -%}
    DATE_DIFF(CAST({{ end_date }} AS DATE), CAST({{ start_date }} AS DATE), DAY)
  {%- else -%}
    DATEDIFF('day', {{ start_date }}, {{ end_date }})
  {%- endif -%}
{%- endmacro %}

{% macro try_parse_date(date_str) -%}
  {%- if target.type == 'bigquery' -%}
    SAFE.PARSE_DATE('%Y-%m-%d', {{ date_str }})
  {%- else -%}
    TRY_TO_DATE({{ date_str }}, 'YYYY-MM-DD')
  {%- endif -%}
{%- endmacro %}

{% macro format_date_yyyymm(date_col) -%}
  {%- if target.type == 'bigquery' -%}
    FORMAT_DATE('%Y-%m', CAST({{ date_col }} AS DATE))
  {%- else -%}
    TO_VARCHAR({{ date_col }}, 'YYYY-MM')
  {%- endif -%}
{%- endmacro %}

{% macro logical_or(expr) -%}
  {%- if target.type == 'bigquery' -%}
    LOGICAL_OR({{ expr }})
  {%- else -%}
    BOOL_OR({{ expr }})
  {%- endif -%}
{%- endmacro %}

{% macro median_agg(expr) -%}
  {%- if target.type == 'bigquery' -%}
    APPROX_QUANTILES({{ expr }}, 100)[OFFSET(50)]
  {%- else -%}
    MEDIAN({{ expr }})
  {%- endif -%}
{%- endmacro %}
