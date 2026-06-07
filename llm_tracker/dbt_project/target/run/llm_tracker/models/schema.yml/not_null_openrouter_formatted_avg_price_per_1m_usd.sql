select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select avg_price_per_1m_usd
from "llm_tracker"."main_formatted"."openrouter_formatted"
where avg_price_per_1m_usd is null



      
    ) dbt_internal_test