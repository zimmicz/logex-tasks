/*
 * Task:1
 * Create a script that will populate test_patients, test_prices, test_medical_category and test_trajectory_detail tables with random data.
 * Requirements:
 * test_trajectory_detail: Should be populated by 5 000 000 lines. Activity_id has to be taken from test_activities table and activities should be randomly distributed, each traject must be mapped to at least 3 activities.
 * Traject can contain the same activity multiple times.
 * date_performed for all activities should be randomly distributed 2 years to the past. Date performed for activities within the same traject cannot be more than 3 months apart
 * test_Patients: Should contain data for 300 000 unique patients. For gender use M for male and F for female.
 * test_medical_trajectory: Map trajects to patients at random. Each of the patients must be mapped to at least 1 traject.
 * test_prices: generate a random price for each activity. Prices should be in a range from 10 to 200 (use just whole numbers)
 */

/* Randomize test_prices */
TRUNCATE TABLE logex.test_prices;
INSERT INTO logex.test_prices (
    activity_id,
    price,
    valid_from,
    valid_to
)
SELECT
    id,
    cast(1 + (abs(checksum(newid())) % 1000) as int),
    dateadd(year, -2, getdate()),
    getdate()
FROM logex.test_activities;

/* Randomize test_patients */
TRUNCATE TABLE logex.test_patients;
WITH tmp(n) AS
(
    select 1 from (values (1),(2),(3),(4),(5),(6),(7),(8),(9),(0)) tmp(n)
),
t as (
    SELECT ROW_NUMBER() OVER (ORDER BY n10.n) AS n
    FROM
    tmp n10
    CROSS JOIN tmp n100
    CROSS JOIN tmp n1000
    CROSS JOIN tmp n10000
    CROSS JOIN tmp n100000
    CROSS JOIN tmp n1000000
)
INSERT INTO logex.test_patients (
    firstname,
    lastname,
    address1,
    address2,
    city,
    zip,
    date_of_birth,
    gender
)
SELECT
    substring(logex.generate_random_string(50), 1, 1 + abs(rv.random) % 50) firstname, /* should use random_view selects to randomize properly */
    substring(logex.generate_random_string(50), 1, 1 + abs(rv.random) % 50) lastname,
    substring(logex.generate_random_string(50), 1, 1 + abs(rv.random) % 50) address1,
    substring(logex.generate_random_string(50), 1, 1 + abs(rv.random) % 50) address2,
    substring(logex.generate_random_string(50), 1, 1 + abs(rv.random) % 50) city,
    substring(logex.generate_random_string(9), 1, 1 + abs(rv.random) % 9) zip,
    cast(dateadd(day, -1 * abs(checksum(newid())) % (99 * 365), getdate()) as date) date_of_birth,
    CASE WHEN checksum(newid()) > 0 THEN 'M' ELSE 'F' END gender
FROM t
CROSS JOIN logex.random_view rv
WHERE t.n <= 300000
ORDER BY n
OPTION (maxrecursion 0);

/* Randomize test_medical_trajectory */
TRUNCATE TABLE logex.test_medical_trajectory;
INSERT INTO logex.test_medical_trajectory (patient_id)
SELECT
    patientid
FROM (
    SELECT
        patientid,
        replicate(cast(patientid as varchar) + ',', rand) repl
    FROM (
        SELECT
            patientid,
            1 + abs(rv.random) % 5 rand
        FROM logex.test_patients p
        CROSS JOIN logex.random_view rv
    ) tmp
) tmp
CROSS APPLY string_split(repl, ',')
WHERE len(value) > 0;

/* Randomize trajectory_detail first step. */
DECLARE @min_activity_id int = (SELECT MIN(id) FROM logex.test_activities);
DECLARE @max_activity_id int = (SELECT MAX(id) FROM logex.test_activities);
DECLARE @min_trajectory_id int = (SELECT MIN(traject_id) FROM logex.test_medical_trajectory);
DECLARE @max_trajectory_id int = (SELECT MAX(traject_id) FROM logex.test_medical_trajectory);
DECLARE @l_end_date date = getdate();
DECLARE @l_start_date date = dateadd(year, -2, @l_end_date);
DROP TABLE IF EXISTS #tmp_trajectory_activity;
CREATE TABLE #tmp_trajectory_activity (
    id int,
    trajectory_id int,
    activity_id int,
    row_number int,
    activity_date date
);
WITH tmp(n) AS
(
    select 1 from (values (1),(2),(3),(4),(5),(6),(7),(8),(9),(0)) tmp(n)
),
t as (
    SELECT row_number() OVER (ORDER BY n10.n) n
    FROM
    tmp n10
    CROSS JOIN tmp n100
    CROSS JOIN tmp n1000
    CROSS JOIN tmp n10000
    CROSS JOIN tmp n100000
    CROSS JOIN tmp n1000000
    CROSS JOIN tmp n10000000
)
INSERT INTO #tmp_trajectory_activity (id, trajectory_id, activity_id)
SELECT
    id,
    trajectory_id,
    activity_id
FROM (
    SELECT
        *,
        row_number() OVER (PARTITION BY trajectory_id ORDER BY id) as row_number
    FROM (
        SELECT
            t.n id, /* invalid column name wtf */
            cast(@min_trajectory_id + (abs(checksum(newid())) % @max_trajectory_id) as int) trajectory_id,
            cast(@min_activity_id + (abs(checksum(newid())) % @max_activity_id) as int) activity_id
        FROM t
        WHERE t.n <= 5000000
    ) a
) b;

CREATE INDEX i1 ON #tmp_trajectory_activity (trajectory_id);

/* Do we have any trajectories missing? If so, we'll sacrifice some of the most frequent trajectories to get them back. */
DROP TABLE IF EXISTS #missing_trajectories;
CREATE TABLE #missing_trajectories (
    id int identity(1,1) PRIMARY KEY,
    trajectory_id int
);
INSERT INTO #missing_trajectories (trajectory_id)
SELECT traject_id FROM logex.test_medical_trajectory EXCEPT SELECT trajectory_id FROM #tmp_trajectory_activity;

DECLARE @l_start int = 0;
DECLARE @l_end int = (SELECT COUNT(1) FROM #missing_trajectories);

DROP TABLE IF EXISTS #top_trajectories;
CREATE TABLE #top_trajectories (
    id int identity(1,1) PRIMARY KEY,
    traject_min_id int,
    trajectory_id int
);

INSERT INTO #top_trajectories (traject_min_id, trajectory_id)
SELECT TOP (@l_end) MIN(id), trajectory_id FROM #tmp_trajectory_activity GROUP BY trajectory_id HAVING COUNT(1) > 3 ORDER BY COUNT(1) DESC;

/* Switch most frequent trajectories for the missing ones. */
UPDATE #tmp_trajectory_activity
SET trajectory_id = tmp.missing_trajectory_id
FROM (
    SELECT
        tp.id,
        tp.trajectory_id,
        tp.traject_min_id,
        mt.trajectory_id missing_trajectory_id
    FROM #top_trajectories tp
    JOIN #missing_trajectories mt ON (tp.id = mt.id)
) tmp
WHERE #tmp_trajectory_activity.id = tmp.traject_min_id
    AND #tmp_trajectory_activity.trajectory_id = tmp.trajectory_id;

/* Find trajectories having less than 3 activities and raise their occurences. */
WHILE EXISTS (SELECT 1 FROM #tmp_trajectory_activity GROUP BY trajectory_id HAVING COUNT(1) < 3)
BEGIN
    PRINT 'Making all trajectories have enough activities';
    UPDATE #tmp_trajectory_activity
    SET trajectory_id = tmp.trajectory_id
    FROM (
        SELECT
            not_enough.trajectory_id,
            enough.min_id
        FROM (
            SELECT
                trajectory_id,
                min_id,
                row_number() OVER (order by min_id) row_number
            FROM (
                SELECT
                    trajectory_id,
                    MIN(id) min_id
                FROM #tmp_trajectory_activity
                GROUP BY trajectory_id
                HAVING COUNT(1) < 3
            ) tmp
        ) not_enough JOIN (
            SELECT
                min_id,
                row_number() OVER (order by min_id) row_number
            FROM (
                SELECT
                    MIN(id) min_id
                FROM #tmp_trajectory_activity
                GROUP BY trajectory_id
                HAVING COUNT(1) > 4
            ) tmp
        ) enough ON (not_enough.row_number = enough.row_number)
    ) tmp
    WHERE id = tmp.min_id;
END;

/* Randomize dates, start with the date between start_date and getdate(). */
UPDATE #tmp_trajectory_activity
SET
    row_number = tmp.row_number,
    activity_date = tmp.activity_date
FROM (
    SELECT
        id,
        row_number,
        CASE WHEN row_number = 1 THEN
            cast(
                dateadd(
                    day,
                    -1 * abs(checksum(newid())) % (datediff(day, @l_start_date, @l_end_date)),
                    @l_end_date
                )
            as date)
        END activity_date
    FROM (
    SELECT
        id,
        row_number() OVER (PARTITION BY trajectory_id ORDER BY id) row_number
    FROM #tmp_trajectory_activity
    ) a
) tmp
WHERE #tmp_trajectory_activity.id = tmp.id;

CREATE INDEX i2 ON #tmp_trajectory_activity (row_number);

/* Randomize dates for each row_number. */
DECLARE @l_max_row_number int = (SELECT max(row_number) FROM #tmp_trajectory_activity);
DECLARE @l_current_row_number int = 2;
WHILE @l_current_row_number <= @l_max_row_number
BEGIN
    PRINT 'Randomizing dates';
    UPDATE #tmp_trajectory_activity
    SET activity_date = tmp.next_date
    FROM (
        SELECT
            trajectory_id,
            dateadd(
                day,
                CASE
                    WHEN checksum(newid()) > 0
                        THEN -1 * checksum(newid()) % IIF (months_3_to_start > max_delta_to_start, CASE WHEN max_delta_to_start = 0 THEN 1 ELSE max_delta_to_start END, months_3_to_start)
                    ELSE abs(checksum(newid()) % IIF (months_3_to_end > max_delta_to_end, CASE WHEN max_delta_to_end = 0 THEN 1 ELSE max_delta_to_end END, months_3_to_end))
                END,
                activity_date
            ) next_date
        FROM (
            SELECT
                trajectory_id,
                activity_date,
                abs(datediff(day, activity_date, dateadd(month, -3, activity_date))) months_3_to_start,
                abs(datediff(day, activity_date, dateadd(month, 3, activity_date))) months_3_to_end,
                abs(datediff(day, activity_date, @l_start_date)) max_delta_to_start,
                abs(datediff(day, activity_date, @l_end_date)) max_delta_to_end
            FROM #tmp_trajectory_activity
            WHERE row_number = @l_current_row_number - 1
        ) a
    ) tmp
    WHERE #tmp_trajectory_activity.trajectory_id = tmp.trajectory_id
        AND row_number = @l_current_row_number;
    SET @l_current_row_number = @l_current_row_number + 1;
END;

INSERT INTO logex.test_trajectory_detail(
    traject_id,
    activity_id,
    date_performed
)
SELECT
    trajectory_id,
    activity_id,
    activity_date
FROM #tmp_trajectory_activity;

SELECT traject_id FROM logex.test_medical_trajectory EXCEPT SELECT traject_id FROM logex.test_trajectory_detail;
SELECT traject_id FROM logex.test_trajectory_detail EXCEPT SELECT traject_id FROM logex.test_medical_trajectory;
SELECT traject_id, count(1) from logex.test_trajectory_detail group by traject_id having count(1) < 3;
