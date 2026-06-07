select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select ingestion_date
from "llm_tracker"."main_formatted"."lmsys_formatted"
where ingestion_date is null



      
    ) dbt_internal_test