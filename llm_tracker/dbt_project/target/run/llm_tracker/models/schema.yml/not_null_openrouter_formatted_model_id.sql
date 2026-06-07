select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select model_id
from "llm_tracker"."main_formatted"."openrouter_formatted"
where model_id is null



      
    ) dbt_internal_test