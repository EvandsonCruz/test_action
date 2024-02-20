WITH RunningJobs AS (
    SELECT 
        rd.job_name,
        EXTRACT(SECOND FROM rd.run_duration) AS run_duration_seconds,
        rd.actual_start_date,
        ROW_NUMBER() OVER (PARTITION BY rd.job_name ORDER BY rd.actual_start_date DESC) AS rn
    FROM 
        dba_scheduler_job_run_details rd
    JOIN
        dba_scheduler_jobs j ON rd.job_name = j.job_name
    WHERE
        j.end_date IS NULL
        AND j.state = 'RUNNING'
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

