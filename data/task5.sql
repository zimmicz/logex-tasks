/*
 * Task:5
 * Create a query that will return all patients labelled by a treatment category.
 * Rules for labelling:
 * The patient should be marked by the treatment category corresponding to the subcategory mapped to an activity with the highest cost sum performed within a traject (remember single activity can be performed multiple times in a traject and in this case cost is a sum of instances). For example, Patient 1 has 3 trajects and corresponding activities mapped to a traject.
 * Example 1:
 * PatientId,TrajectId, Activity_code, Price
 * 1, 1, 1, 180
 * 1, 1, 1, 180
 * 1, 1, 3, 200
 * 1, 2, 4, 300
 * 1, 3, 4, 300
 * In this case, the patient should be labelled by treatment category mapped to activity 1 as overall cost within traject 1 for this activity is 360 which is more than the cost for activities 3,4. In case of prices are the same for certain activities use a rank field on treatment subcategory. SubCategory with higher rank will be used.
 * Columns returned: Treatment category Id, patient_id
 */

DROP VIEW IF EXISTS logex.task5;
GO
CREATE VIEW logex.task5 AS
SELECT
    tmp.category_id,
    tmp.patient_id
FROM (
    SELECT
        tmp.*,
        row_number() OVER (PARTITION BY tmp.patient_id ORDER BY tmp.price DESC, tmp.rank DESC) row_number
    FROM (
        SELECT
            t.traject_id,
            t.patient_id,
            a.id activity_id,
            c.category_id,
            a.treatment_subcategory_id,
            sc.rank,
            SUM(p.price) price
        FROM logex.test_medical_trajectory t
        JOIN logex.test_trajectory_detail d ON (t.traject_id = d.traject_id)
        JOIN logex.test_activities a ON (d.activity_id = a.id)
        JOIN logex.test_treatment_subcategories sc ON (a.treatment_subcategory_id = sc.category_id)
        JOIN logex.test_treatment_categories c ON (sc.treatment_category_id = c.category_id)
        JOIN logex.test_prices p ON (a.id = p.activity_id)
        GROUP BY
            t.traject_id,
            t.patient_id,
            a.id,
            c.category_id,
            a.treatment_subcategory_id,
            sc.rank
    ) tmp
) tmp
WHERE row_number = 1;
GO
