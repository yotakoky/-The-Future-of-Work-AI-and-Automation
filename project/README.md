# AI Job Market — Data Analyst Specialist Final Project
### (Project Idea 3: Human Resources Dataset Analysis — مطبّق على بيانات Global AI Job Market)

## 📁 محتويات المشروع

```
project/
├── data/
│   ├── Excel_Final_Project_5.xlsx        ← الملف الأصلي (شيت "Raw Data")
│   └── processed/
│       ├── cleaned_job_postings.csv      ← الداتا النظيفة (Week 1 deliverable)
│       └── job_market_model.db           ← قاعدة بيانات SQLite (Data Model / Star Schema)
├── outputs/figures/                      ← كل الرسومات (PNG) الناتجة من التحليل
├── HR_AI_Job_Market_Analysis.ipynb       ← النوتبوك الرئيسي (Week 1 + 2 + 3)
├── dashboard/app.py                      ← الداشبورد التفاعلي (Week 4 — Streamlit)
└── requirements.txt
```

## ✅ مطابقة المتطلبات مع البي دي اف

| الأسبوع | المطلوب في البي دي اف | فين في المشروع |
|---|---|---|
| Week 1 | Data Model + تنظيف البيانات (SQL, pandas) | داخل النوتبوك، قسم "Week 1" — بيبني star schema (Fact + Dim tables) في SQLite |
| Week 2 | أسئلة تحليلية يجاوب عليها SQL/pandas | داخل النوتبوك، قسم "Week 2" — 8 أسئلة، كل سؤال باستعلام SQL + رسم |
| Week 3 | أسئلة تنبؤية (scikit-learn) | داخل النوتبوك، قسم "Week 3" — توقع رواتب/AI intensity/نسبة المخاطر + موديل تصنيف |
| Week 4 | Dashboard (Tableau في الأصل) | `dashboard/app.py` — بديل بايثون تفاعلي (Streamlit + Plotly) بفلاتر حقيقية |

## 🚀 التشغيل في VS Code

### 1) تجهيز البيئة (مرة واحدة بس)
افتح Terminal في VS Code جوه فولدر المشروع:
```bash
python -m venv .venv
.venv\Scripts\activate        # على Windows
# source .venv/bin/activate   # على Mac/Linux

pip install -r requirements.txt
```

### 2) تشغيل النوتبوك (Week 1, 2, 3)
- لازم يكون عندك إضافة **Jupyter** و **Python** في VS Code (من Extensions).
- افتح `HR_AI_Job_Market_Analysis.ipynb`.
- اختار الـ Kernel بتاع الـ `.venv` اللي عملته.
- اضغط **Run All**. النتائج والرسومات هتتولد تلقائي.

### 3) تشغيل الداشبورد (Week 4)
من نفس الـ Terminal:
```bash
streamlit run dashboard/app.py
```
هيفتح المتصفح تلقائي على `http://localhost:8501` وفيه فلاتر (سنة، صناعة، منطقة، أقدمية)
وKPIs ورسومات تفاعلية + قسم توقعات.

## 📝 ملاحظة عن Tableau
البي دي اف بيطلب Tableau في Week 4، وبما إنك طلبت تنفيذ كل حاجة بايثون، استبدلناه بـ
Streamlit + Plotly اللي بيدوا نفس فكرة الـ Interactive Dashboard. لو محتاج فعلاً ملف Tableau
(.twbx) كمان، قولّي وأظبطلك الداتا الجاهزة (`cleaned_job_postings.csv`) تتوصل بيه مباشرة.
