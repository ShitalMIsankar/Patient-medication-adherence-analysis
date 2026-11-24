-- ============================================================
-- OVERALL EXECUTIVE KPIs
-- ============================================================

-- Q1: Top-level medication adherence KPI dashboard
SELECT
    COUNT(*)                                                    AS total_patients,
    ROUND(AVG(persistence_days), 1)                             AS avg_persistence_days,
    ROUND(SUM(CASE WHEN discontinued=0 THEN 1 END)*100.0/COUNT(*), 1) AS persistence_rate_pct,
    ROUND(AVG(pdc)*100, 1)                                     AS avg_pdc_pct,
    ROUND(SUM(adherent)*100.0/COUNT(*), 1)                     AS adherent_patients_pct,
    ROUND(AVG(mpr)*100, 1)                                     AS avg_mpr_pct,
    ROUND(AVG(compliance_score)*100, 1)                        AS avg_compliance_pct,
    ROUND(SUM(discontinued)*100.0/COUNT(*), 1)                 AS discontinuation_rate_pct,
    ROUND(AVG(risk_score), 1)                                  AS avg_risk_score,
    COUNT(CASE WHEN side_effects_reported=TRUE THEN 1 END)     AS patients_with_side_effects
FROM patient_medication;


-- ============================================================
-- PERSISTENCE ANALYSIS
-- ============================================================

-- Q2: Persistence survival by drug class (Kaplan-Meier style buckets)
SELECT
    drug_class,
    COUNT(*)                                                            AS total_patients,
    ROUND(AVG(persistence_days), 1)                                     AS avg_days_on_therapy,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY persistence_days),0) AS median_persistence,
    SUM(CASE WHEN persistence_days >= 90  THEN 1 ELSE 0 END)*100/COUNT(*) AS pct_90d,
    SUM(CASE WHEN persistence_days >= 180 THEN 1 ELSE 0 END)*100/COUNT(*) AS pct_180d,
    SUM(CASE WHEN persistence_days >= 270 THEN 1 ELSE 0 END)*100/COUNT(*) AS pct_270d,
    SUM(CASE WHEN persistence_days >= 365 THEN 1 ELSE 0 END)*100/COUNT(*) AS pct_365d,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)                           AS discontinuation_pct
FROM patient_medication
GROUP BY drug_class
ORDER BY avg_days_on_therapy DESC;


-- Q3: Discontinuation drivers — side effects vs physician follow-up
SELECT
    drug_class,
    side_effects_reported,
    physician_followup,
    COUNT(*)                                        AS patients,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)       AS disc_rate_pct,
    ROUND(AVG(persistence_days),1)                  AS avg_persist_days
FROM patient_medication
GROUP BY drug_class, side_effects_reported, physician_followup
ORDER BY drug_class, disc_rate_pct DESC;


-- Q4: Patients who discontinued within 90 days (early leavers)
SELECT
    drug_class,
    age_group,
    insurance_type,
    COUNT(*)                                       AS early_discontinuers,
    ROUND(AVG(risk_score),1)                       AS avg_risk,
    ROUND(AVG(pdc)*100,1)                          AS avg_pdc_before_disc
FROM patient_medication
WHERE discontinued = 1
  AND persistence_days <= 90
GROUP BY drug_class, age_group, insurance_type
ORDER BY early_discontinuers DESC
LIMIT 20;


-- ============================================================
--  ADHERENCE (PDC / MPR) ANALYSIS
-- ============================================================

-- Q5: PDC distribution by drug class
SELECT
    drug_class,
    COUNT(*)                                                        AS patients,
    ROUND(AVG(pdc)*100,1)                                           AS avg_pdc,
    ROUND(SUM(CASE WHEN pdc>=0.80 THEN 1 END)*100.0/COUNT(*),1)   AS high_adherent_pct,
    ROUND(SUM(CASE WHEN pdc>=0.50 AND pdc<0.80 THEN 1 END)*100.0/COUNT(*),1) AS partial_adherent_pct,
    ROUND(SUM(CASE WHEN pdc<0.50 THEN 1 END)*100.0/COUNT(*),1)    AS non_adherent_pct,
    ROUND(AVG(mpr)*100,1)                                           AS avg_mpr,
    ROUND(AVG(pdc)*100,1) - ROUND(AVG(mpr)*100,1)                  AS pdc_mpr_gap
FROM patient_medication
GROUP BY drug_class
ORDER BY avg_pdc DESC;


-- Q6: Adherence by insurance type (access barrier analysis)
SELECT
    insurance_type,
    COUNT(*)                                                       AS patients,
    ROUND(AVG(pdc)*100,1)                                          AS avg_pdc,
    ROUND(SUM(adherent)*100.0/COUNT(*),1)                          AS adherent_pct,
    ROUND(AVG(compliance_score)*100,1)                             AS avg_compliance,
    ROUND(AVG(persistence_days),0)                                 AS avg_persist_days,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)                      AS disc_rate
FROM patient_medication
GROUP BY insurance_type
ORDER BY avg_pdc DESC;


-- Q7: Adherence by age group and gender
SELECT
    age_group,
    gender,
    COUNT(*)                                       AS patients,
    ROUND(AVG(pdc)*100,1)                          AS avg_pdc,
    ROUND(SUM(adherent)*100.0/COUNT(*),1)          AS adherent_pct,
    ROUND(AVG(compliance_score)*100,1)             AS avg_compliance
FROM patient_medication
GROUP BY age_group, gender
ORDER BY age_group, gender;


-- Q8: Regional adherence heatmap
SELECT
    region,
    drug_class,
    COUNT(*)                               AS patients,
    ROUND(AVG(pdc)*100,1)                  AS avg_pdc,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1) AS disc_rate
FROM patient_medication
GROUP BY region, drug_class
ORDER BY region, avg_pdc DESC;


-- ============================================================
-- COMPLIANCE ANALYSIS
-- ============================================================

-- Q9: Compliance category breakdown
SELECT
    compliance_category,
    COUNT(*)                                        AS patients,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM patient_medication),1) AS pct_total,
    ROUND(AVG(pdc)*100,1)                           AS avg_pdc,
    ROUND(AVG(persistence_days),0)                  AS avg_persist,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)       AS disc_rate,
    ROUND(AVG(risk_score),1)                        AS avg_risk
FROM patient_medication
GROUP BY compliance_category
ORDER BY avg_pdc DESC;


-- Q10: Compliance issues breakdown
SELECT
    'Correct Dose & Timing'  AS behavior,
    SUM(CASE WHEN dose_timing_correct=TRUE AND extra_dose_event=FALSE
             AND doses_taken >= doses_prescribed*0.8 THEN 1 END) AS patient_count,
    ROUND(SUM(CASE WHEN dose_timing_correct=TRUE AND extra_dose_event=FALSE
             AND doses_taken >= doses_prescribed*0.8 THEN 1 END)*100.0/COUNT(*),1) AS pct
FROM patient_medication
UNION ALL
SELECT 'Missed Doses', SUM(CASE WHEN doses_taken < doses_prescribed*0.80 THEN 1 END),
    ROUND(SUM(CASE WHEN doses_taken < doses_prescribed*0.80 THEN 1 END)*100.0/COUNT(*),1) FROM patient_medication
UNION ALL
SELECT 'Wrong Timing', SUM(CASE WHEN dose_timing_correct=FALSE THEN 1 END),
    ROUND(SUM(CASE WHEN dose_timing_correct=FALSE THEN 1 END)*100.0/COUNT(*),1) FROM patient_medication
UNION ALL
SELECT 'Extra/Double Dose', SUM(CASE WHEN extra_dose_event=TRUE THEN 1 END),
    ROUND(SUM(CASE WHEN extra_dose_event=TRUE THEN 1 END)*100.0/COUNT(*),1) FROM patient_medication;


-- ============================================================
-- RISK STRATIFICATION
-- ============================================================

-- Q11: Risk category summary
SELECT
    risk_category,
    COUNT(*)                                   AS patients,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM patient_medication),1) AS pct,
    ROUND(AVG(pdc)*100,1)                      AS avg_pdc,
    ROUND(AVG(compliance_score)*100,1)         AS avg_compliance,
    ROUND(AVG(persistence_days),0)             AS avg_persistence,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)  AS disc_rate,
    STRING_AGG(DISTINCT drug_class, ', ')      AS top_drug_classes
FROM patient_medication
GROUP BY risk_category
ORDER BY avg_pdc;


-- Q12: Identify high-risk patients for intervention
SELECT
    patient_id,
    age,
    gender,
    drug_class,
    drug_name,
    region,
    insurance_type,
    ROUND(pdc*100,1)              AS pdc_pct,
    ROUND(compliance_score*100,1) AS compliance_pct,
    persistence_days,
    risk_score,
    risk_category,
    side_effects_reported,
    physician_followup,
    CASE
        WHEN pdc < 0.50 AND discontinued=1 THEN 'URGENT: Re-engage'
        WHEN pdc < 0.50 THEN 'HIGH: Adherence support needed'
        WHEN compliance_score < 0.60 THEN 'MODERATE: Education needed'
        WHEN side_effects_reported=TRUE THEN 'MONITOR: Side effect review'
        ELSE 'STANDARD: Routine follow-up'
    END AS recommended_action
FROM patient_medication
WHERE risk_score > 40
ORDER BY risk_score DESC
LIMIT 50;


-- ============================================================
-- COMPARATIVE & TREND ANALYSIS
-- ============================================================

-- Q13: Drug class performance scorecard
SELECT
    drug_class,
    COUNT(*)                                          AS n,
    ROUND(AVG(pdc)*100,1)                            AS pdc_pct,
    ROUND(AVG(mpr)*100,1)                            AS mpr_pct,
    ROUND(AVG(compliance_score)*100,1)               AS compliance_pct,
    ROUND(AVG(persistence_days),0)                   AS avg_persist_d,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)        AS disc_pct,
    ROUND(AVG(risk_score),1)                         AS avg_risk,
    RANK() OVER (ORDER BY AVG(pdc) DESC)             AS pdc_rank,
    RANK() OVER (ORDER BY AVG(persistence_days) DESC) AS persistence_rank,
    RANK() OVER (ORDER BY SUM(discontinued)*1.0/COUNT(*)) AS disc_rank
FROM patient_medication
GROUP BY drug_class;


-- Q14: Physician follow-up impact on adherence
SELECT
    drug_class,
    physician_followup,
    COUNT(*)                             AS patients,
    ROUND(AVG(pdc)*100,1)               AS avg_pdc,
    ROUND(AVG(compliance_score)*100,1)  AS avg_compliance,
    ROUND(AVG(persistence_days),0)      AS avg_persistence,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1) AS disc_rate
FROM patient_medication
GROUP BY drug_class, physician_followup
ORDER BY drug_class, physician_followup;


-- Q15: Comorbidity impact on medication adherence
SELECT
    comorbidity,
    COUNT(*)                              AS patients,
    ROUND(AVG(pdc)*100,1)                AS avg_pdc,
    ROUND(AVG(compliance_score)*100,1)   AS avg_compliance,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1) AS disc_rate,
    ROUND(AVG(risk_score),1)             AS avg_risk
FROM patient_medication
GROUP BY comorbidity
ORDER BY avg_pdc DESC;


-- Q16: Cross-metric correlation (adherence vs compliance vs persistence)
SELECT
    CASE
        WHEN pdc >= 0.80 AND compliance_score >= 0.75 THEN 'High Adh + High Comp'
        WHEN pdc >= 0.80 AND compliance_score <  0.75 THEN 'High Adh + Low Comp'
        WHEN pdc <  0.80 AND compliance_score >= 0.75 THEN 'Low Adh + High Comp'
        ELSE                                               'Low Adh + Low Comp'
    END AS patient_segment,
    COUNT(*)                                        AS patients,
    ROUND(AVG(persistence_days),0)                  AS avg_persistence,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)       AS disc_rate,
    ROUND(AVG(risk_score),1)                        AS avg_risk
FROM patient_medication
GROUP BY patient_segment
ORDER BY avg_persistence DESC;


-- ============================================================
-- VIEWS FOR REPORTING
-- ============================================================

CREATE VIEW v_medication_summary AS
SELECT
    drug_class,
    COUNT(*)                                    AS patients,
    ROUND(AVG(pdc)*100,1)                       AS avg_pdc,
    ROUND(AVG(compliance_score)*100,1)          AS avg_compliance,
    ROUND(AVG(persistence_days),0)              AS avg_persistence,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1)   AS disc_rate,
    ROUND(AVG(risk_score),1)                    AS avg_risk_score,
    CASE
        WHEN AVG(pdc) >= 0.80 AND SUM(discontinued)*1.0/COUNT(*) <= 0.15 THEN 'On Track'
        WHEN AVG(pdc) >= 0.65 OR SUM(discontinued)*1.0/COUNT(*) <= 0.25 THEN 'Monitor'
        ELSE 'At Risk'
    END AS performance_status
FROM patient_medication
GROUP BY drug_class;


CREATE VIEW v_high_risk_patients AS
SELECT patient_id, age, drug_class, region, risk_category, pdc, compliance_score, persistence_days
FROM patient_medication
WHERE risk_category IN ('High','Critical')
   OR (pdc < 0.50 AND discontinued = 1);


CREATE VIEW v_monthly_adherence_trend AS
SELECT
    DATE_TRUNC('month', prescription_date)  AS month,
    COUNT(*)                                AS patients,
    ROUND(AVG(pdc)*100,1)                   AS avg_pdc,
    ROUND(SUM(adherent)*100.0/COUNT(*),1)   AS adherent_pct,
    ROUND(SUM(discontinued)*100.0/COUNT(*),1) AS disc_rate
FROM patient_medication
GROUP BY DATE_TRUNC('month', prescription_date)
ORDER BY month;
