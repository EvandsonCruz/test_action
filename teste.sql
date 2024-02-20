WITH RankedJobs AS (
    SELECT 
        job_name,
        run_duration,
        actual_start_date,
        ROW_NUMBER() OVER (PARTITION BY job_name ORDER BY actual_start_date DESC) AS rn
    FROM 
        dba_scheduler_job_run_details
)
SELECT
    job_name,
    AVG(run_duration) AS avg_run_duration
FROM
    RankedJobs
WHERE
    rn <= 3
GROUP BY
    job_name;
