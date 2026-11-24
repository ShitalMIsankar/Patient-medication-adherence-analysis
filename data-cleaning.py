"""
DATA CLEANING PIPELINE
Patient Medication Usage — Persistence, Adherence & Compliance
"""
import pandas as pd
import numpy as np
import json
from datetime import datetime

# ── 1. LOAD ─────────────────────────────────────────────────────────────────
df = pd.read_csv('/home/claude/med_pipeline/raw_data.csv')
audit = {'original_rows': len(df), 'original_cols': len(df.columns), 'issues': []}

# ── 2. DUPLICATES ────────────────────────────────────────────────────────────
dups = df.duplicated(subset='patient_id').sum()
df = df.drop_duplicates(subset='patient_id')
audit['issues'].append({'step':'Duplicate removal', 'removed': int(dups)})

# ── 3. DATE PARSING ──────────────────────────────────────────────────────────
df['prescription_date']     = pd.to_datetime(df['prescription_date'], errors='coerce')
df['discontinuation_date']  = pd.to_datetime(df['discontinuation_date'], errors='coerce')
invalid_dates = df['prescription_date'].isna().sum()
df = df.dropna(subset=['prescription_date'])
audit['issues'].append({'step':'Invalid prescription dates removed', 'removed': int(invalid_dates)})

# ── 4. AGE ───────────────────────────────────────────────────────────────────
age_null = df['age'].isna().sum()
df['age'] = df['age'].fillna(df['age'].median())
df['age'] = df['age'].clip(18, 100).astype(int)
audit['issues'].append({'step':'Age nulls imputed with median', 'affected': int(age_null)})

# ── 5. GENDER ────────────────────────────────────────────────────────────────
gender_null = df['gender'].isna().sum()
df['gender'] = df['gender'].fillna('Unknown')
audit['issues'].append({'step':'Gender nulls set to Unknown', 'affected': int(gender_null)})

# ── 6. REGION ────────────────────────────────────────────────────────────────
region_null = df['region'].isna().sum()
mode_region = df['region'].mode()[0]
df['region'] = df['region'].fillna(mode_region)
audit['issues'].append({'step':'Region nulls imputed with mode', 'affected': int(region_null)})

# ── 7. INSURANCE ─────────────────────────────────────────────────────────────
ins_null = df['insurance_type'].isna().sum()
df['insurance_type'] = df['insurance_type'].fillna('Unknown')
audit['issues'].append({'step':'Insurance nulls set to Unknown', 'affected': int(ins_null)})

# ── 8. DOSES TAKEN OUTLIERS & NULLS ─────────────────────────────────────────
outliers = (df['doses_taken'] > df['doses_prescribed'] * 1.5).sum()
df.loc[df['doses_taken'] > df['doses_prescribed'] * 1.5, 'doses_taken'] = np.nan
nulls_doses = df['doses_taken'].isna().sum()
df['doses_taken'] = df['doses_taken'].fillna(df['doses_prescribed'] * df['pdc_raw'])
df['doses_taken'] = df['doses_taken'].clip(0, df['doses_prescribed']).round(0).astype(int)
audit['issues'].append({'step':'Doses_taken outliers capped & nulls imputed', 'outliers': int(outliers), 'nulls': int(nulls_doses)})

# ── 9. PERSISTENCE VALIDATION ────────────────────────────────────────────────
df['persistence_days'] = df['persistence_days'].clip(1, 365)
neg = (df['persistence_days'] <= 0).sum()
audit['issues'].append({'step':'Persistence days clipped to [1,365]', 'affected': int(neg)})

# ── 10. PDC BOUNDS CHECK ─────────────────────────────────────────────────────
df['pdc_raw'] = df['pdc_raw'].clip(0, 1)

# ── 11. AGE GROUPS ───────────────────────────────────────────────────────────
df['age_group'] = pd.cut(df['age'],
    bins=[17,34,49,64,79,100],
    labels=['18-34','35-49','50-64','65-79','80+'])

# ── 12. DISCONTINUED FLAG ────────────────────────────────────────────────────
df['discontinued'] = df['discontinuation_date'].notna().astype(int)

# ── 13. FINAL TYPES ──────────────────────────────────────────────────────────
df['dose_timing_correct']  = df['dose_timing_correct'].astype(bool)
df['extra_dose_event']     = df['extra_dose_event'].astype(bool)
df['physician_followup']   = df['physician_followup'].astype(bool)
df['side_effects_reported']= df['side_effects_reported'].astype(bool)

audit['cleaned_rows'] = len(df)
audit['total_issues_fixed'] = sum(v for d in audit['issues'] for k,v in d.items() if isinstance(v,int) and k!='removed')

df.to_csv('/home/claude/med_pipeline/cleaned_data.csv', index=False)
with open('/home/claude/med_pipeline/cleaning_audit.json','w') as f:
    json.dump(audit, f, indent=2)

print("=== CLEANING AUDIT ===")
print(json.dumps(audit, indent=2))
print(f"\nCleaned shape: {df.shape}")
print(f"Nulls remaining:\n{df.isnull().sum()[df.isnull().sum()>0]}")
