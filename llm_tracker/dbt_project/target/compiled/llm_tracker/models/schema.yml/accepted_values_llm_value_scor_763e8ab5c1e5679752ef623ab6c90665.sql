
    
    

with all_values as (

    select
        quality_tier as value_field,
        count(*) as n_records

    from "llm_tracker"."main_combined"."llm_value_scores"
    group by quality_tier

)

select *
from all_values
where value_field not in (
    'elite','high','medium','low','unranked'
)


