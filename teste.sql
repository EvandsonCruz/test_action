WITH RunningJobs AS (
    SELECT 
        job_name,
        EXTRACT(SECOND FROM run_duration) AS run_duration_seconds,
        actual_start_date,
        ROW_NUMBER() OVER (PARTITION BY job_name ORDER BY actual_start_date DESC) AS rn
    FROM 
        dba_scheduler_job_run_details
    WHERE
        end_date IS NULL  -- Adicione esta condição para incluir apenas jobs em execução
)
SELECT
    job_name,
    AVG(run_duration_seconds) AS avg_run_duration_seconds
FROM
    RunningJobs
WHERE
    rn <= 3
GROUP BY
    job_name;
