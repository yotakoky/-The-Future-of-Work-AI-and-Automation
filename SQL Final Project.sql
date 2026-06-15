SET GLOBAL local_infile = 1;

CREATE DATABASE IF NOT EXISTS SQL_Final_Project
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE SQL_Final_Project;

RENAME TABLE ai_impact_jobs_with_skill_columns TO raw_data;

SELECT * FROM raw_data;

-- 2.1 Dim_Year
CREATE TABLE Dim_Year (
  Year_Key     INT UNSIGNED NOT NULL,
  posting_year INT NOT NULL,
  AI_Period    VARCHAR(20) NOT NULL,
  PRIMARY KEY (Year_Key)
);

INSERT INTO Dim_Year (Year_Key, posting_year, AI_Period)
SELECT
  (posting_year - 2010),
  posting_year,
  CASE
    WHEN posting_year BETWEEN 2010 AND 2015 THEN 'Pre-AI'
    WHEN posting_year BETWEEN 2016 AND 2021 THEN 'Early AI'
    ELSE 'Modern AI'
  END
FROM (
  SELECT DISTINCT posting_year
  FROM raw_data
) AS y;

SELECT * FROM Dim_Year;

-- 2.2 Dim_Geography
CREATE TABLE Dim_Geography (
  Geo_Key  INT UNSIGNED NOT NULL,
  country  VARCHAR(100),
  region   VARCHAR(100),
  PRIMARY KEY (Geo_Key)
);

INSERT INTO Dim_Geography
SELECT
  ROW_NUMBER() OVER (ORDER BY country, region),
  country,
  region
FROM (SELECT DISTINCT country, region FROM raw_data) g;

SELECT * FROM Dim_Geography;

-- 2.3 Dim_Company
CREATE TABLE Dim_Company (
  Company_Key   INT UNSIGNED NOT NULL,
  company_name  VARCHAR(100),
  company_group VARCHAR(50),
  PRIMARY KEY (Company_Key)
);

INSERT INTO Dim_Company
SELECT
  ROW_NUMBER() OVER (ORDER BY company_name),
  company_name,
  SUBSTRING_INDEX(company_name, ' ', 1)
FROM (SELECT DISTINCT company_name FROM raw_data) c;

SELECT * FROM Dim_Company;

-- 2.4 Dim_Industry
CREATE TABLE Dim_Industry (
  Industry_Key INT UNSIGNED NOT NULL,
  industry     VARCHAR(100),
  PRIMARY KEY (Industry_Key)
);

INSERT INTO Dim_Industry
SELECT
  ROW_NUMBER() OVER (ORDER BY industry),
  industry
FROM (SELECT DISTINCT industry FROM raw_data) i;

SELECT * FROM Dim_Industry;


-- 2.5 Dim_IndustryAI
CREATE TABLE Dim_IndustryAI (
  IndustryAi_Key INT UNSIGNED NOT NULL,
  industry_ai_adoption_stage VARCHAR(20),
  PRIMARY KEY (IndustryAi_Key)
);

INSERT INTO Dim_IndustryAI VALUES
(1,'Emerging'),
(2,'Growing'),
(3,'Mature');

SELECT * FROM Dim_IndustryAI;

-- 2.6 Dim_JobTitle
CREATE TABLE Dim_JobTitle (
  JobTitle_Key INT UNSIGNED NOT NULL,
  job_title VARCHAR(100),
  PRIMARY KEY (JobTitle_Key)
);

INSERT INTO Dim_JobTitle
SELECT
  ROW_NUMBER() OVER (ORDER BY job_title),
  job_title
FROM (SELECT DISTINCT job_title FROM raw_data) j;

SELECT * FROM Dim_JobTitle;

-- 2.7 Dim_JobDisplacement
CREATE TABLE Dim_JobDisplacement (
  JobDisp_key INT UNSIGNED NOT NULL,
  ai_job_displacement_risk_level VARCHAR(20),
  PRIMARY KEY (JobDisp_key)
);

INSERT INTO Dim_JobDisplacement VALUES
(1,'High Risk'),
(2,'Medium Risk'),
(3,'Low Risk');

SELECT * FROM Dim_JobDisplacement;

-- 2.8 Dim_SeniorityLevel
CREATE TABLE Dim_SeniorityLevel (
  SeniorityLevel_Key INT UNSIGNED NOT NULL,
  seniority_level VARCHAR(30),
  PRIMARY KEY (SeniorityLevel_Key)
);

INSERT INTO Dim_SeniorityLevel
SELECT
  ROW_NUMBER() OVER (ORDER BY seniority_level),
  seniority_level
FROM (SELECT DISTINCT seniority_level FROM raw_data) s;

SELECT * FROM Dim_SeniorityLevel;

-- 2.9 Dim_Skill
CREATE TABLE Dim_Skill (
  Skill_Key INT UNSIGNED NOT NULL,
  Skill_Name VARCHAR(100),
  Skill_Type VARCHAR(10),
  PRIMARY KEY (Skill_Key)
);

INSERT INTO Dim_Skill VALUES
(1,'Business Analysis','Core'),
(2,'Cloud Computing','Core'),
(3,'Communication','Core'),
(4,'Data Analysis','Core'),
(5,'Project Management','Core'),
(6,'Python','Core'),
(7,'Research','Core'),
(8,'SQL','Core'),
(9,'Software Engineering','Core'),
(10,'Statistics','Core'),
(11,'LLMs','AI'),
(12,'MLOps','AI'),
(13,'NLP','AI'),
(14,'Computer Vision','AI'),
(15,'Deep Learning','AI'),
(16,'Generative AI','AI'),
(17,'Machine Learning','AI'),
(18,'Reinforcement Learning','AI');

SELECT * FROM Dim_Skill;

-- 2.10 Dim_AI_Level
CREATE TABLE Dim_AI_Level (
  AI_Level_Key INT UNSIGNED NOT NULL,
  ai_intensity_level VARCHAR(10),
  PRIMARY KEY (AI_Level_Key)
);

INSERT INTO Dim_AI_Level VALUES
(1,'Low'),
(2,'High'),
(3,'Medium');

SELECT * FROM Dim_AI_Level;

-- FACT TABLE
CREATE TABLE Fact_JobPosting (
  Job_Key INT UNSIGNED NOT NULL AUTO_INCREMENT,
  JobDisp_key INT UNSIGNED,
  AI_Level_Key INT UNSIGNED,
  IndustryAi_Key INT UNSIGNED,
  SeniorityLevel_Key INT UNSIGNED,
  JobTitle_Key INT UNSIGNED,
  Industry_Key INT UNSIGNED,
  Company_Key INT UNSIGNED,
  Geo_Key INT UNSIGNED,
  Year_Key INT UNSIGNED,
  job_id VARCHAR(36),
  posting_year INT,
  ai_mentioned INT(1),
  ai_intensity_score DECIMAL(10,2),
  salary_usd INT,
  salary_change_vs_prev_year_percent DECIMAL(10,4),
  ai_job_displacement_risk_score DECIMAL(10,4),
  PRIMARY KEY (Job_Key),
  UNIQUE KEY (job_id)
);

INSERT INTO Fact_JobPosting (
  JobDisp_key,
  AI_Level_Key,
  IndustryAi_Key,
  SeniorityLevel_Key,
  JobTitle_Key,
  Industry_Key,
  Company_Key,
  Geo_Key,
  Year_Key,
  job_id,
  posting_year,
  ai_mentioned,
  ai_intensity_score,
  salary_usd,
  salary_change_vs_prev_year_percent,
  ai_job_displacement_risk_score
)

SELECT
  djd.JobDisp_key,
  dal.AI_Level_Key,
  dia.IndustryAi_Key,
  dsl.SeniorityLevel_Key,
  djt.JobTitle_Key,
  di.Industry_Key,
  dc.Company_Key,
  dg.Geo_Key,
  dy.Year_Key,
  r.job_id,
  r.posting_year,

  CASE
    WHEN r.ai_mentioned IN ('TRUE','true','1',1) THEN 1
    ELSE 0
  END AS ai_mentioned,

  ROUND(r.ai_intensity_score, 2) AS ai_intensity_score,
  r.salary_usd,
  r.salary_change_vs_prev_year_percent,
  r.automation_risk_score AS ai_job_displacement_risk_score

FROM raw_data r
JOIN Dim_Year dy
  ON dy.posting_year = r.posting_year
JOIN Dim_Geography dg
  ON dg.country = r.country AND dg.region = r.region
JOIN Dim_Company dc
  ON dc.company_name = r.company_name
JOIN Dim_Industry di
  ON di.industry = r.industry
JOIN Dim_JobTitle djt
  ON djt.job_title = r.job_title
JOIN Dim_SeniorityLevel dsl
  ON dsl.seniority_level = r.seniority_level
JOIN Dim_IndustryAI dia
  ON dia.industry_ai_adoption_stage = r.industry_ai_adoption_stage
JOIN Dim_AI_Level dal
  ON dal.ai_intensity_level =
    CASE
      WHEN ROUND(r.ai_intensity_score,2) <= 0.20 THEN 'Low'
      WHEN ROUND(r.ai_intensity_score,2) <= 0.65 THEN 'Medium'
      ELSE 'High'
    END
JOIN Dim_JobDisplacement djd
  ON djd.ai_job_displacement_risk_level =
    CASE
      WHEN r.automation_risk_score >= 0.70 THEN 'High Risk'
      WHEN r.automation_risk_score >= 0.40 THEN 'Medium Risk'
      ELSE 'Low Risk'
    END;

SELECT * FROM Fact_JobPosting;

-- BRIDGE TABLE
CREATE TABLE Bridge_Skill_JobPosting (
  Job_Key INT UNSIGNED,
  Skill_Key INT UNSIGNED,
  PRIMARY KEY(Job_Key, Skill_Key)
);

SET GLOBAL local_infile = 1;

CREATE DATABASE IF NOT EXISTS SQL_Final_Project
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE SQL_Final_Project;

RENAME TABLE ai_impact_jobs_with_skill_columns TO raw_data;

SELECT * FROM raw_data;

-- 2.1 Dim_Year
CREATE TABLE Dim_Year (
  Year_Key     INT UNSIGNED NOT NULL,
  posting_year INT NOT NULL,
  AI_Period    VARCHAR(20) NOT NULL,
  PRIMARY KEY (Year_Key)
);

INSERT INTO Dim_Year (Year_Key, posting_year, AI_Period)
SELECT
  (posting_year - 2010),
  posting_year,
  CASE
    WHEN posting_year BETWEEN 2010 AND 2015 THEN 'Pre-AI'
    WHEN posting_year BETWEEN 2016 AND 2021 THEN 'Early AI'
    ELSE 'Modern AI'
  END
FROM (
  SELECT DISTINCT posting_year
  FROM raw_data
) AS y;

SELECT * FROM Dim_Year;

-- 2.2 Dim_Geography
CREATE TABLE Dim_Geography (
  Geo_Key  INT UNSIGNED NOT NULL,
  country  VARCHAR(100),
  region   VARCHAR(100),
  PRIMARY KEY (Geo_Key)
);

INSERT INTO Dim_Geography
SELECT
  ROW_NUMBER() OVER (ORDER BY country, region),
  country,
  region
FROM (SELECT DISTINCT country, region FROM raw_data) g;

SELECT * FROM Dim_Geography;

-- 2.3 Dim_Company
CREATE TABLE Dim_Company (
  Company_Key   INT UNSIGNED NOT NULL,
  company_name  VARCHAR(100),
  company_group VARCHAR(50),
  PRIMARY KEY (Company_Key)
);

INSERT INTO Dim_Company
SELECT
  ROW_NUMBER() OVER (ORDER BY company_name),
  company_name,
  SUBSTRING_INDEX(company_name, ' ', 1)
FROM (SELECT DISTINCT company_name FROM raw_data) c;

SELECT * FROM Dim_Company;

-- 2.4 Dim_Industry
CREATE TABLE Dim_Industry (
  Industry_Key INT UNSIGNED NOT NULL,
  industry     VARCHAR(100),
  PRIMARY KEY (Industry_Key)
);

INSERT INTO Dim_Industry
SELECT
  ROW_NUMBER() OVER (ORDER BY industry),
  industry
FROM (SELECT DISTINCT industry FROM raw_data) i;

SELECT * FROM Dim_Industry;


-- 2.5 Dim_IndustryAI
CREATE TABLE Dim_IndustryAI (
  IndustryAi_Key INT UNSIGNED NOT NULL,
  industry_ai_adoption_stage VARCHAR(20),
  PRIMARY KEY (IndustryAi_Key)
);

INSERT INTO Dim_IndustryAI VALUES
(1,'Emerging'),
(2,'Growing'),
(3,'Mature');

SELECT * FROM Dim_IndustryAI;

-- 2.6 Dim_JobTitle
CREATE TABLE Dim_JobTitle (
  JobTitle_Key INT UNSIGNED NOT NULL,
  job_title VARCHAR(100),
  PRIMARY KEY (JobTitle_Key)
);

INSERT INTO Dim_JobTitle
SELECT
  ROW_NUMBER() OVER (ORDER BY job_title),
  job_title
FROM (SELECT DISTINCT job_title FROM raw_data) j;

SELECT * FROM Dim_JobTitle;

-- 2.7 Dim_JobDisplacement
CREATE TABLE Dim_JobDisplacement (
  JobDisp_key INT UNSIGNED NOT NULL,
  ai_job_displacement_risk_level VARCHAR(20),
  PRIMARY KEY (JobDisp_key)
);

INSERT INTO Dim_JobDisplacement VALUES
(1,'High Risk'),
(2,'Medium Risk'),
(3,'Low Risk');

SELECT * FROM Dim_JobDisplacement;

-- 2.8 Dim_SeniorityLevel
CREATE TABLE Dim_SeniorityLevel (
  SeniorityLevel_Key INT UNSIGNED NOT NULL,
  seniority_level VARCHAR(30),
  PRIMARY KEY (SeniorityLevel_Key)
);

INSERT INTO Dim_SeniorityLevel
SELECT
  ROW_NUMBER() OVER (ORDER BY seniority_level),
  seniority_level
FROM (SELECT DISTINCT seniority_level FROM raw_data) s;

SELECT * FROM Dim_SeniorityLevel;

-- 2.9 Dim_Skill
CREATE TABLE Dim_Skill (
  Skill_Key INT UNSIGNED NOT NULL,
  Skill_Name VARCHAR(100),
  Skill_Type VARCHAR(10),
  PRIMARY KEY (Skill_Key)
);

INSERT INTO Dim_Skill VALUES
(1,'Business Analysis','Core'),
(2,'Cloud Computing','Core'),
(3,'Communication','Core'),
(4,'Data Analysis','Core'),
(5,'Project Management','Core'),
(6,'Python','Core'),
(7,'Research','Core'),
(8,'SQL','Core'),
(9,'Software Engineering','Core'),
(10,'Statistics','Core'),
(11,'LLMs','AI'),
(12,'MLOps','AI'),
(13,'NLP','AI'),
(14,'Computer Vision','AI'),
(15,'Deep Learning','AI'),
(16,'Generative AI','AI'),
(17,'Machine Learning','AI'),
(18,'Reinforcement Learning','AI');

SELECT * FROM Dim_Skill;

-- 2.10 Dim_AI_Level
CREATE TABLE Dim_AI_Level (
  AI_Level_Key INT UNSIGNED NOT NULL,
  ai_intensity_level VARCHAR(10),
  PRIMARY KEY (AI_Level_Key)
);

INSERT INTO Dim_AI_Level VALUES
(1,'Low'),
(2,'High'),
(3,'Medium');

SELECT * FROM Dim_AI_Level;

-- FACT TABLE
CREATE TABLE Fact_JobPosting (
  Job_Key INT UNSIGNED NOT NULL AUTO_INCREMENT,
  JobDisp_key INT UNSIGNED,
  AI_Level_Key INT UNSIGNED,
  IndustryAi_Key INT UNSIGNED,
  SeniorityLevel_Key INT UNSIGNED,
  JobTitle_Key INT UNSIGNED,
  Industry_Key INT UNSIGNED,
  Company_Key INT UNSIGNED,
  Geo_Key INT UNSIGNED,
  Year_Key INT UNSIGNED,
  job_id VARCHAR(36),
  posting_year INT,
  ai_mentioned INT(1),
  ai_intensity_score DECIMAL(10,2),
  salary_usd INT,
  salary_change_vs_prev_year_percent DECIMAL(10,4),
  ai_job_displacement_risk_score DECIMAL(10,4),
  PRIMARY KEY (Job_Key),
  UNIQUE KEY (job_id)
);

INSERT INTO Fact_JobPosting (
  JobDisp_key,
  AI_Level_Key,
  IndustryAi_Key,
  SeniorityLevel_Key,
  JobTitle_Key,
  Industry_Key,
  Company_Key,
  Geo_Key,
  Year_Key,
  job_id,
  posting_year,
  ai_mentioned,
  ai_intensity_score,
  salary_usd,
  salary_change_vs_prev_year_percent,
  ai_job_displacement_risk_score
)

SELECT
  djd.JobDisp_key,
  dal.AI_Level_Key,
  dia.IndustryAi_Key,
  dsl.SeniorityLevel_Key,
  djt.JobTitle_Key,
  di.Industry_Key,
  dc.Company_Key,
  dg.Geo_Key,
  dy.Year_Key,
  r.job_id,
  r.posting_year,

  CASE
    WHEN r.ai_mentioned IN ('TRUE','true','1',1) THEN 1
    ELSE 0
  END AS ai_mentioned,

  ROUND(r.ai_intensity_score, 2) AS ai_intensity_score,
  r.salary_usd,
  r.salary_change_vs_prev_year_percent,
  r.automation_risk_score AS ai_job_displacement_risk_score

FROM raw_data r
JOIN Dim_Year dy
  ON dy.posting_year = r.posting_year
JOIN Dim_Geography dg
  ON dg.country = r.country AND dg.region = r.region
JOIN Dim_Company dc
  ON dc.company_name = r.company_name
JOIN Dim_Industry di
  ON di.industry = r.industry
JOIN Dim_JobTitle djt
  ON djt.job_title = r.job_title
JOIN Dim_SeniorityLevel dsl
  ON dsl.seniority_level = r.seniority_level
JOIN Dim_IndustryAI dia
  ON dia.industry_ai_adoption_stage = r.industry_ai_adoption_stage
JOIN Dim_AI_Level dal
  ON dal.ai_intensity_level =
    CASE
      WHEN ROUND(r.ai_intensity_score,2) <= 0.20 THEN 'Low'
      WHEN ROUND(r.ai_intensity_score,2) <= 0.65 THEN 'Medium'
      ELSE 'High'
    END
JOIN Dim_JobDisplacement djd
  ON djd.ai_job_displacement_risk_level =
    CASE
      WHEN r.automation_risk_score >= 0.70 THEN 'High Risk'
      WHEN r.automation_risk_score >= 0.40 THEN 'Medium Risk'
      ELSE 'Low Risk'
    END;

SELECT * FROM Fact_JobPosting;
