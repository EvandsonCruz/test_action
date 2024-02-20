WITH RankedJobs AS (
    SELECT 
        job_name,
        elapsed_time,
        ROW_NUMBER() OVER (PARTITION BY job_name ORDER BY start_date DESC) AS rn
    FROM 
        dba_scheduler_run_job_details
)
SELECT
    job_name,
    AVG(elapsed_time) AS avg_elapsed_time
FROM
    RankedJobs
WHERE
    rn <= 3
GROUP BY
    job_name;
