
    
    

with all_values as (

    select
        price_tier as value_field,
        count(*) as n_records

    from "llm_tracker"."main_combined"."llm_value_scores"
    group by price_tier

)

select *
from all_values
where value_field not in (
    'free','budget','mid','premium','ultra'
)


