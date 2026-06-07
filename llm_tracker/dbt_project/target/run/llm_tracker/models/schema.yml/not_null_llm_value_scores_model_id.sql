select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select model_id
from "llm_tracker"."main_combined"."llm_value_scores"
where model_id is null



      
    ) dbt_internal_test