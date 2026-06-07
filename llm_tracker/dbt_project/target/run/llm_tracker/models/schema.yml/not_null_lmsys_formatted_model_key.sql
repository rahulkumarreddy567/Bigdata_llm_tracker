select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select model_key
from "llm_tracker"."main_formatted"."lmsys_formatted"
where model_key is null



      
    ) dbt_internal_test