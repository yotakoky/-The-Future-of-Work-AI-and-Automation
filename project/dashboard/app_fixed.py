"""
Week 4 — Interactive Dashboard (Python/Streamlit alternative to Tableau)
Run with:  streamlit run dashboard/app.py
"""
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from sklearn.linear_model import LinearRegression

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "processed" / "cleaned_job_postings.csv"

# ---------------------------------------------------------------------------
# Page config + design tokens (calm sage / dusty-teal palette)
# ---------------------------------------------------------------------------
st.set_page_config(page_title="AI Job Market Dashboard", layout="wide", page_icon="🌿")

COLORS = {
    "bg": "#0F172A",
    "card": "#1E293B",
    "primary": "#2563EB",
    "secondary": "#3B82F6",
    "accent": "#60A5FA",
    "text": "#F8FAFC",
    "muted": "#CBD5E1",
    "border": "#334155",
}

PALETTE = [
    "#2563EB",
    "#3B82F6",
    "#60A5FA",
    "#1D4ED8",
    "#93C5FD",
    "#2563EB",
    "#3B82F6",
    "#60A5FA"
]

SEQ_SCALE = [
    "#0F172A",
    "#1E3A8A",
    "#2563EB",
    "#3B82F6",
    "#93C5FD"
]

CUSTOM_CSS = f"""
<style>
@import url('https://fonts.googleapis.com/css2?family=Quicksand:wght@500;600;700&family=Inter:wght@400;500;600&display=swap');

html, body, [class*="css"] {{
    font-family: 'Inter', sans-serif;
}}
h1, h2, h3, .stTabs [data-baseweb="tab"] p {{
    font-family: 'Quicksand', sans-serif !important;
}}
.stApp {{
    background-color: {COLORS['bg']};
}}
h1 {{
    color: {COLORS['text']};
    font-weight: 700 !important;
}}
[data-testid="stSidebar"] {{
    background-color: #111827;
    border-right: 1px solid {COLORS['border']};
}}
div[data-testid="stMetric"] {{
    background-color: {COLORS['card']};
    border: 1px solid {COLORS['border']};
    border-top: 4px solid {COLORS['primary']};
    border-radius: 14px;
    padding: 14px 18px 10px 18px;
    box-shadow: 0 2px 10px rgba(46, 73, 69, 0.06);
}}
div[data-testid="stMetricLabel"] {{
    color: {COLORS['muted']};
}}
div[data-testid="stMetricValue"] {{
    color: {COLORS['text']};
}}
.stTabs [data-baseweb="tab-list"] {{
    gap: 6px;
}}
.stTabs [data-baseweb="tab"] {{
    background-color: {COLORS['card']};
    border-radius: 10px 10px 0 0;
    padding: 8px 16px;
    color: {COLORS['muted']};
}}
.stTabs [aria-selected="true"] {{
    background-color: {COLORS['primary']} !important;
    color: white !important;
}}
.insight-box {{
    background-color: #EAF1EE;
    border-left: 4px solid {COLORS['primary']};
    border-radius: 8px;
    padding: 12px 16px;
    color: {COLORS['text']};
    font-size: 0.95rem;
    margin: 6px 0 18px 0;
}}
hr {{
    border-color: {COLORS['border']};
}}
</style>
"""
st.markdown(CUSTOM_CSS, unsafe_allow_html=True)


def theme_fig(fig, height=380):
    fig.update_layout(
        font=dict(family="Inter, sans-serif", color=COLORS["text"], size=12),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        margin=dict(l=10, r=10, t=45, b=10),
        height=height,
        legend=dict(bgcolor="rgba(0,0,0,0)"),
        title_font=dict(family="Quicksand, sans-serif", size=16, color=COLORS["text"]),
    )
    fig.update_xaxes(showgrid=False, zeroline=False)
    fig.update_yaxes(showgrid=True, gridcolor=COLORS["border"], zeroline=False)
    return fig


@st.cache_data
def load_data():
    if CSV_PATH.exists():
        return pd.read_csv(CSV_PATH)
    raw = ROOT / "data" / "Excel_Final_Project_5.xlsx"
    df = pd.read_excel(raw, sheet_name="Raw Data ")
    df["ai_keywords"] = df["ai_keywords"].fillna("None")
    df["ai_skills"] = df["ai_skills"].fillna("None")
    return df


df = load_data()

# ---------------------------------------------------------------------------
# Sidebar — filters (with reset + CSV export for the filtered slice)
# ---------------------------------------------------------------------------
YEAR_MIN, YEAR_MAX = int(df["posting_year"].min()), int(df["posting_year"].max())
DEFAULTS = {
    "year_range": (YEAR_MIN, YEAR_MAX),
    "industries": sorted(df["industry"].unique().tolist()),
    "regions": sorted(df["region"].unique().tolist()),
    "seniority": sorted(df["seniority_level"].unique().tolist()),
}
for k, v in DEFAULTS.items():
    if k not in st.session_state:
        st.session_state[k] = v
st.sidebar.markdown("### 🔎 Filters")

st.sidebar.slider("Posting Year", YEAR_MIN, YEAR_MAX, key="year_range")

st.sidebar.multiselect(
    "Industry",
    sorted(df["industry"].unique()),
    key="industries"
)

st.sidebar.multiselect(
    "Region",
    sorted(df["region"].unique()),
    key="regions"
)

st.sidebar.multiselect(
    "Seniority Level",
    sorted(df["seniority_level"].unique()),
    key="seniority"
)

if st.sidebar.button("↺ Reset Filters", width='stretch'):
    for k, v in DEFAULTS.items():
        st.session_state[k] = v
    st.rerun()

f = df[
    df["posting_year"].between(*st.session_state["year_range"])
    & df["industry"].isin(st.session_state["industries"])
    & df["region"].isin(st.session_state["regions"])
    & df["seniority_level"].isin(st.session_state["seniority"])
]

st.sidebar.markdown("---")
st.sidebar.download_button(
    "⬇️ Download Filtered Data (CSV)",
    data=f.to_csv(index=False).encode("utf-8"),
    file_name="filtered_job_postings.csv",
    width='stretch',
)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.markdown(f"""
<h1>🚀 Global AI Job Market Intelligence Dashboard</h1>
<p style="color:{COLORS['muted']}; margin-top:-10px;">
Interactive Analytics Dashboard for AI Impact on the Global Job Market (2010–2025)
</p>
""", unsafe_allow_html=True)

if f.empty:
    st.warning("No data matches the selected filters. Try expanding your selection.")
    st.stop()

# ---------------------------------------------------------------------------
# KPI cards
# ---------------------------------------------------------------------------
base_avg_salary = df["salary_usd"].mean()
c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("📄 Total Job Posts", f"{len(f):,}")
c2.metric(
    "💰 Average Salary",
    f"${f['salary_usd'].mean():,.0f}",
    delta=f"{f['salary_usd'].mean() - base_avg_salary:,.0f}$ vs Overall Average",
)
c3.metric("🤖 AI Intensity", f"{f['ai_intensity_score'].mean():.2f}")
c4.metric("⚠️ Average Automation Risk", f"{f['automation_risk_score'].mean():.2f}")
c5.metric("📢 % Job Posts Mentioning AI", f"{f['ai_mentioned'].mean()*100:.1f}%")

st.write("")

# ---------------------------------------------------------------------------
# Tabs
# ---------------------------------------------------------------------------
tab_overview, tab_salary, tab_ai, tab_skills, tab_forecast, tab_data = st.tabs(
    [
"🏠 Overview",
"💰 Salaries",
"🤖 AI & Risk",
"🧠 Skills",
"🔮 Forecast",
"📋 Data"
]
)

# ----- Overview: animated salary race + dynamic insight -----
with tab_overview:
    st.subheader("Salary Trends Over Time")
    race = f.groupby(["posting_year", "industry"])["salary_usd"].mean().reset_index()
    if race["posting_year"].nunique() > 1:
        max_val = race["salary_usd"].max() * 1.1
        fig = px.bar(
            race.sort_values(["posting_year", "salary_usd"]),
            x="salary_usd", y="industry", color="industry", orientation="h",
            animation_frame="posting_year", range_x=[0, max_val],
            color_discrete_sequence=PALETTE,
        )
        fig.update_layout(showlegend=False,
                           title="Press ▶ to watch salary trends year by year")
        theme_fig(fig, height=460)
        st.plotly_chart(fig, width='stretch')
    else:
        snap = race.sort_values("salary_usd", ascending=False)
        fig = px.bar(snap, x="salary_usd", y="industry", orientation="h",
                     color="industry", color_discrete_sequence=PALETTE)
        fig.update_layout(showlegend=False)
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')

    by_ind = f.groupby("industry")["salary_usd"].mean()
    top_ind, top_ind_val = by_ind.idxmax(), by_ind.max()
    top_region = f.groupby("region")["salary_usd"].mean().idxmax()
    by_ai = f.groupby("ai_mentioned")["salary_usd"].mean()
    premium_pct = ((by_ai.get(True, 0) / by_ai.get(False, 1)) - 1) * 100 if False in by_ai.index and True in by_ai.index else None

    premium_line = (f" والوظائف اللي بتذكر الذكاء الاصطناعي بتاخد راتب أعلى بنسبة "
                     f"<b>{premium_pct:.1f}%</b> تقريبًا." if premium_pct else "")
    st.markdown(f"""
    <div class="insight-box">
    📌 أعلى صناعة من حيث متوسط الراتب في الاختيار الحالي هي <b>{top_ind}</b>
    (≈ ${top_ind_val:,.0f})، وأعلى منطقة جغرافية أجرًا هي <b>{top_region}</b>.{premium_line}
    </div>
    """, unsafe_allow_html=True)

# ----- Salary tab -----
with tab_salary:
    col1, col2 = st.columns(2)
    with col1:
        trend = f.groupby("posting_year")["salary_usd"].mean().reset_index()
        fig = px.area(trend, x="posting_year", y="salary_usd",
                       color_discrete_sequence=[COLORS["primary"]])
        fig.update_traces(line=dict(width=3), fillcolor="rgba(94,139,126,0.15)")
        fig.update_layout(title="اتجاه متوسط الراتب عبر السنين",
                           yaxis_title="متوسط الراتب ($)", xaxis_title="السنة")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')
    with col2:
        pivot = f.pivot_table(index="industry", columns="region", values="salary_usd", aggfunc="mean")
        fig = px.imshow(pivot, text_auto=".0f", aspect="auto", color_continuous_scale=SEQ_SCALE)
        fig.update_layout(title="متوسط الراتب حسب الصناعة والمنطقة")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')

    col3, col4 = st.columns(2)
    with col3:
        premium = f.groupby("ai_mentioned")["salary_usd"].mean().reset_index()
        premium["ai_mentioned"] = premium["ai_mentioned"].map({True: "بيذكر AI", False: "مفيش ذكر لـ AI"})
        fig = px.bar(premium, x="ai_mentioned", y="salary_usd", color="ai_mentioned",
                     text_auto=".0f", color_discrete_sequence=[COLORS["secondary"], COLORS["primary"]])
        fig.update_layout(showlegend=False, title="فرق الراتب حسب ذكر الذكاء الاصطناعي",
                           yaxis_title="متوسط الراتب ($)", xaxis_title="")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')
    with col4:
        resk = (f.groupby("seniority_level")["reskilling_required"].mean() * 100).reset_index()
        fig = px.bar(resk, x="seniority_level", y="reskilling_required", text_auto=".1f",
                     color="seniority_level", color_discrete_sequence=PALETTE)
        fig.update_layout(showlegend=False, title="نسبة الحاجة لإعادة التأهيل حسب الأقدمية",
                           yaxis_title="%", xaxis_title="")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')

# ----- AI & Risk tab -----
with tab_ai:
    col5, col6 = st.columns(2)
    with col5:
        risk_ind = (f.groupby("industry")["automation_risk_score"].mean()
                    .sort_values(ascending=False).reset_index())
        fig = px.bar(risk_ind, x="automation_risk_score", y="industry", orientation="h",
                     color="automation_risk_score", color_continuous_scale=SEQ_SCALE)
        fig.update_layout(title="متوسط مخاطر الأتمتة حسب الصناعة", xaxis_title="Automation Risk Score")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')
    with col6:
        risk_dist = f["ai_job_displacement_risk"].value_counts(normalize=True).mul(100).reset_index()
        risk_dist.columns = ["risk_level", "pct"]
        fig = px.pie(risk_dist, names="risk_level", values="pct", hole=0.5,
                     color_discrete_sequence=PALETTE)
        fig.update_layout(title="توزيع مستوى مخاطر الإحلال الوظيفي")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')

    adopt = (f.groupby("industry_ai_adoption_stage")[["automation_risk_score", "ai_intensity_score"]]
             .mean().reset_index())
    adopt_m = adopt.melt(id_vars="industry_ai_adoption_stage", var_name="metric", value_name="value")
    fig = px.bar(adopt_m, x="industry_ai_adoption_stage", y="value", color="metric", barmode="group",
                 color_discrete_sequence=[COLORS["primary"], COLORS["accent"]])
    fig.update_layout(title="مرحلة تبني الذكاء الاصطناعي مقابل المخاطر والـ Intensity",
                       xaxis_title="", yaxis_title="القيمة (0-1)")
    theme_fig(fig)
    st.plotly_chart(fig, width='stretch')

# ----- Skills tab -----
with tab_skills:
    core_cols = [c for c in f.columns if c.startswith("Core_")]
    ai_cols = [c for c in f.columns if c.startswith("AI_")]
    rows = []
    for c in core_cols + ai_cols:
        sub = f[f[c] == True]
        if len(sub) >= 10:
            name = c.replace("Core_", "").replace("AI_", "")
            rows.append({"المهارة": name, "النوع": "Core" if c.startswith("Core_") else "AI",
                         "متوسط الراتب": sub["salary_usd"].mean(), "عدد الإعلانات": len(sub)})
    skills_df = pd.DataFrame(rows).sort_values("متوسط الراتب", ascending=False).head(12)
    fig = px.bar(skills_df, x="متوسط الراتب", y="المهارة", color="النوع", orientation="h",
                 color_discrete_sequence=[COLORS["secondary"], COLORS["primary"]])
    fig.update_layout(title="أعلى 12 مهارة من حيث متوسط الراتب")
    theme_fig(fig, height=440)
    st.plotly_chart(fig, width='stretch')

# ----- Forecast tab -----
with tab_forecast:
    forecast_year = int(df["posting_year"].max()) + 1
    rows = []
    for ind in sorted(f["industry"].unique()):
        sub = df[df["industry"] == ind].groupby("posting_year")["salary_usd"].mean().reset_index()
        if len(sub) < 2:
            continue
        model = LinearRegression().fit(sub[["posting_year"]], sub["salary_usd"])
        pred = model.predict([[forecast_year]])[0]
        rows.append({"industry": ind, "forecast": pred})
    fc = pd.DataFrame(rows).sort_values("forecast", ascending=False)
    fig = px.bar(fc, x="forecast", y="industry", orientation="h", text_auto=".0f",
                 color="forecast", color_continuous_scale=SEQ_SCALE)
    fig.update_layout(title=f"توقع متوسط الراتب لسنة {forecast_year} حسب الصناعة",
                       xaxis_title="الراتب المتوقع ($)")
    theme_fig(fig, height=420)
    st.plotly_chart(fig, width='stretch')

    col7, col8 = st.columns(2)
    future_years = list(range(forecast_year, forecast_year + 3))
    with col7:
        ai_trend = df.groupby("posting_year")["ai_intensity_score"].mean().reset_index()
        m = LinearRegression().fit(ai_trend[["posting_year"]], ai_trend["ai_intensity_score"])
        future_pred = m.predict([[y] for y in future_years])
        fig = go.Figure()
        fig.add_trace(go.Scatter(x=ai_trend["posting_year"], y=ai_trend["ai_intensity_score"],
                                  mode="lines+markers", name="فعلي",
                                  line=dict(color=COLORS["primary"], width=3)))
        fig.add_trace(go.Scatter(x=future_years, y=future_pred, mode="lines+markers", name="توقع",
                                  line=dict(color=COLORS["accent"], width=3, dash="dash")))
        fig.update_layout(title="توقع AI Intensity Score")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')
    with col8:
        risk_trend = (df.assign(is_high=df["ai_job_displacement_risk"].eq("High"))
                      .groupby("posting_year")["is_high"].mean().mul(100).reset_index(name="high_risk_pct"))
        m2 = LinearRegression().fit(risk_trend[["posting_year"]], risk_trend["high_risk_pct"])
        future_pred2 = m2.predict([[y] for y in future_years])
        fig = go.Figure()
        fig.add_trace(go.Scatter(x=risk_trend["posting_year"], y=risk_trend["high_risk_pct"],
                                  mode="lines+markers", name="فعلي",
                                  line=dict(color=COLORS["secondary"], width=3)))
        fig.add_trace(go.Scatter(x=future_years, y=future_pred2, mode="lines+markers", name="توقع",
                                  line=dict(color=COLORS["accent"], width=3, dash="dash")))
        fig.update_layout(title="توقع % الوظائف عالية الخطورة")
        theme_fig(fig)
        st.plotly_chart(fig, width='stretch')

# ----- Data tab -----
with tab_data:
    st.caption(f"عدد الصفوف المعروضة بعد الفلترة: {len(f):,}")
    st.dataframe(f, width='stretch', height=480)

st.markdown("---")
st.caption("Data: Global AI Job Market dataset (2010–2025) · التوقعات بتستخدم Linear Regression بسيط.")