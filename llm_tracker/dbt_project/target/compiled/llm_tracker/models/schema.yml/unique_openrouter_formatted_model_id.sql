
    
    

select
    model_id as unique_field,
    count(*) as n_records

from "llm_tracker"."main_formatted"."openrouter_formatted"
where model_id is not null
group by model_id
having count(*) > 1


