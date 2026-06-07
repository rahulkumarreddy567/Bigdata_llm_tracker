select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select provider
from "llm_tracker"."main_formatted"."openrouter_formatted"
where provider is null



      
    ) dbt_internal_test