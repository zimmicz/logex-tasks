/*
 * Task:3
 * Write a query that will return cost per patient grouped by a year.
 * Columns returned: Patient_id, cost, year
 */

DROP VIEW IF EXISTS logex.task3;
GO
CREATE VIEW logex.task3 AS
SELECT
    p.patientid,
    SUM(prices.price) cost,
    year(d.date_performed) year
FROM logex.test_patients p
JOIN logex.test_medical_trajectory t ON (p.patientid = t.patient_id)
JOIN logex.test_trajectory_detail d ON (t.traject_id = d.traject_id)
JOIN logex.test_prices prices ON (d.activity_id = prices.activity_id)
GROUP BY
    p.patientid,
    year(d.date_performed);
GO
