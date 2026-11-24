# Patient-medication-adherence-analysis-
End-to-end healthcare analytics pipeline measuring medication persistence, adherence (PDC/MPR) and compliance across 4,820 patients and 32 drugs, with SQL analysis, risk stratification and a 12-month intervention roadmap.
# Patient Medication Usage Analytics: Persistence, Adherence & Compliance

End-to-end healthcare analytics project that measures how patients stay on therapy (persistence), how consistently they have medication available (adherence, PDC/MPR) and how correctly they take it (compliance), then turns the findings into risk stratification, root cause analysis and a 12-month intervention roadmap.

> **Data note:** The dataset is synthetic. It was generated with Python (seeded, so reproducible) and calibrated to realistic adherence ranges per drug class, with nulls and outliers added deliberately to practise cleaning. No real patient data is used. The value of the project is the pipeline and analytical method.

---

## Business problem

Medication non-adherence drives relapse, avoidable hospitalisation and lost therapeutic and commercial value. A health system or pharma team needs to know:

1. Which drug classes and patient segments drop off fastest?
2. Who is at highest risk right now?
3. What is causing it (cost, side effects, regimen complexity, follow-up gaps)?
4. What should be done first, and what should success look like?

## Scope

| Item | Detail |
|---|---|
| Patients | 4,820 |
| Drug classes | 8 (antihypertensives, statins, antidiabetics, insulin, antidepressants, antipsychotics, anticoagulants, bronchodilators) |
| Medications | 32 (4 per class) |
| Observation window | Jan to Dec 2024 |
| Segments | Region, insurance type, age group, gender, comorbidity |

## Pipeline

```
Raw data  ->  Cleaning  ->  Feature engineering & KPIs  ->  SQL analysis  ->  Excel dashboard  ->  Business report
```

1. **Raw data generation:** 4,820 patient records, 20 columns, with injected nulls (age, gender, region, insurance, doses taken) and dose outliers.
2. **Cleaning:** duplicate and date checks, median imputation for age, mode for region, "Unknown" for gender and insurance, outlier capping for doses taken (>1.5x prescribed), persistence clipped to 1 to 365 days. Each step is documented in the cleaning script.
3. **Processing and KPIs:** PDC, MPR, compliance score, risk score, adherence tiers, persistence bands, age groups.
4. **SQL analysis:** 16 analytical queries and 3 reporting views.
5. **Excel dashboard:** 9 sheets with RAG-coloured KPI cards, drug class, regional and segment analysis, monthly trend chart and an insights sheet.
6. **PDF report:** executive summary, findings, root causes, recommendations and implementation roadmap.

## Metric definitions

| Metric | Definition | Threshold |
|---|---|---|
| Persistence | Days on therapy before discontinuation (1 to 365) | Target >= 240 days |
| PDC (Proportion of Days Covered) | Days with medication available / observation days | >= 80% = adherent |
| MPR (Medication Possession Ratio) | Days supply dispensed / observation days (capped at 1) | >= 80% |
| Compliance score | 0.50 x dose quantity + 0.35 x correct timing + 0.15 x no extra dose | >= 70% |
| Risk score | (1 - PDC) x 40 + (1 - compliance) x 30 + discontinued x 20 + side effects x 10 | Low / Moderate / High / Critical |

## Key findings


<img width="1037" height="562" alt="Screenshot 2026-11-24 153533" src="https://github.com/user-attachments/assets/e8c6dbf1-135f-44c6-9f27-31a8869df703" />

- Average PDC is **72.8%**, below the 80% clinical adherence threshold; discontinuation is **22.7%**, above a 20% target.
- **Antipsychotics are the highest-risk class** (about 35% discontinuation, PDC about 58.5%), consistent with the side-effect and stigma pattern common to CNS medications.


<img width="1051" height="752" alt="Screenshot 2026-11-24 153553" src="https://github.com/user-attachments/assets/eac7805f-965c-45ce-af12-5875f282c83f" />

- **Antihypertensives perform best** (about 85.6% persistence, PDC about 82.6%) and serve as the internal benchmark.
- Self-pay and Medicaid patients show weaker adherence, pointing to financial access as a structural root cause.
- Physician follow-up and side-effect reporting are meaningful drivers of discontinuation.

Root causes examined: financial access, psychiatric medication burden, asymptomatic conditions, regimen complexity, missing follow-up, timing errors.

## Recommendations and roadmap

Eight initiatives across three phases:

| Phase | Timing | Initiatives | Target |
|---|---|---|---|
| 1. Quick wins | Months 1 to 3 | Smart refill reminders, high-risk outreach, prescriber dashboard | PDC 72.8% to 75% |
| 2. Programme build | Months 4 to 9 | Adherence support programme, psychiatric monitoring protocol, financial assistance, side-effect response pathway | PDC to 78%, discontinuation to 19% |
| 3. Scale and optimise | Months 10 to 12 | Young adult digital programme, regimen simplification clinic, full evaluation | PDC >= 80%, discontinuation <= 18% |

## Limitations

- Synthetic data: patterns reflect the assumptions used to generate it, not real-world observation.
- Cross-sectional design with a single observation window; no causal claims.
- Monthly trend values are illustrative, not derived from patient-level monthly records.
- Intervention targets are planning goals, not measured outcomes.

