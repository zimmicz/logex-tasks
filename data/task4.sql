/*
 * Task:4
 * Write a query that will calculate the overall cost per treatment category by month for the year 2017.
 * Columns returned: Treatment category Id, Cost, Month
 */

DROP VIEW IF EXISTS logex.task4;
GO
CREATE VIEW logex.task4 AS
SELECT
    c.category_id,
    SUM(p.price) cost,
    month(d.date_performed) month
FROM logex.test_treatment_categories c
JOIN logex.test_treatment_subcategories sc ON (c.category_id = sc.treatment_category_id)
JOIN logex.test_activities a ON (sc.category_id = a.treatment_subcategory_id)
JOIN logex.test_prices p ON (a.id = p.activity_id)
JOIN logex.test_trajectory_detail d ON (a.id = d.activity_id)
WHERE year(d.date_performed) = 2017
GROUP BY
    c.category_id,
    month(d.date_performed);
GO

