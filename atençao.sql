WITH Last3RunDurations AS (
    SELECT 
        job_name,
        run_duration,
        ROW_NUMBER() OVER (PARTITION BY job_name ORDER BY actual_start_date DESC) AS rn
    FROM 
        dba_scheduler_job_run_details
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
    j.job_name,
    j.run_duration AS current_run_duration,
    ard.avg_run_duration_seconds,
    CASE WHEN EXTRACT(DAY FROM j.run_duration) * 86400 + EXTRACT(HOUR FROM j.run_duration) * 3600 + EXTRACT(MINUTE FROM j.run_duration) * 60 + EXTRACT(SECOND FROM j.run_duration) > ard.avg_run_duration_seconds THEN 'Above Average' ELSE 'Below or Equal Average' END AS run_duration_status
FROM
    dba_scheduler_job_run_details j
JOIN
    AvgRunDuration ard ON j.job_name = ard.job_name
WHERE
    j.actual_start_date = (SELECT MAX(actual_start_date) FROM Last3RunDurations WHERE job_name = j.job_name AND rn = 1);    
 
