/*
 * Task:2
 * Write a query that will return the total cost of the most expensive patient in 2017 along with patient details.
 * Columns returned: Patient_id, First_name, Second_name, gender, date_of_birth, cost
 */

DROP VIEW IF EXISTS logex.task2;
GO
CREATE VIEW logex.task2 AS
SELECT TOP 1
    p.patientid,
    p.firstname,
    p.lastname,
    p.gender,
    p.date_of_birth,
    SUM(prices.price) cost
FROM logex.test_patients p
JOIN logex.test_medical_trajectory t ON (p.patientid = t.patient_id)
JOIN logex.test_trajectory_detail d ON (t.traject_id = d.traject_id)
JOIN logex.test_prices prices ON (d.activity_id = prices.activity_id)
WHERE year(d.date_performed) = 2017
GROUP BY
    p.patientid,
    p.firstname,
    p.lastname,
    p.gender,
    p.date_of_birth
ORDER BY SUM(prices.price) DESC;
GO
