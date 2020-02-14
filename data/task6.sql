alter table logex.test_activities add constraint test_activities_pk primary key (id);
alter table logex.test_patients add constraint test_patients_pk primary key (patientid);
alter table logex.test_treatment_categories add constraint test_treatment_categories_pk primary key (category_id);
alter table logex.test_treatment_subcategories add constraint test_treatment_subcategories_pk primary key (category_id);

create index test_trajectory_detail_traject_id_idx ON logex.test_trajectory_detail (traject_id);
create index test_prices_activity_id_idx ON logex.test_prices (activity_id);
create index test_medical_trajectory_patient_id_idx ON logex.test_medical_trajectory (patient_id);
create index test_medical_trajectory_traject_id_idx ON logex.test_medical_trajectory (traject_id);
create index test_treatment_subcategories_treatment_category_id_idx ON logex.test_treatment_subcategories (treatment_category_id);
