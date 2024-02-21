WITH Last3RunDurations AS (
    SELECT 
        rd.job_name,
        rd.run_duration,
        ROW_NUMBER() OVER (PARTITION BY rd.job_name ORDER BY rd.actual_start_date DESC) AS rn
    FROM 
        dba_scheduler_job_run_details rd
    WHERE
        rn <= 3
)
, AvgRunDuration AS (
    SELECT
        job_name,
        AVG(EXTRACT(DAY FROM run_duration) * 86400 + EXTRACT(HOUR FROM run_duration) * 3600 + EXTRACT(MINUTE FROM run_duration) * 60 + EXTRACT(SECOND FROM run_duration)) AS avg_run_duration_seconds
    FROM
        Last3RunDurations
    GROUP BY
        job_name
)
SELECT
    r.job_name,
    r.run_duration AS current_run_duration,
    ard.avg_run_duration_seconds,
    CASE WHEN EXTRACT(DAY FROM r.run_duration) * 86400 + EXTRACT(HOUR FROM r.run_duration) * 3600 + EXTRACT(MINUTE FROM r.run_duration) * 60 + EXTRACT(SECOND FROM r.run_duration) > ard.avg_run_duration_seconds THEN 'Above Average' ELSE 'Below or Equal Average' END AS run_duration_status
FROM
    dba_scheduler_running_jobs r
JOIN
    AvgRunDuration ard ON r.job_name = ard.job_name;
