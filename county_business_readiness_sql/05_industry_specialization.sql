
-- =====================================================
-- 05_INDUSTRY_SPECIALIZATION.SQL
-- County Business Readiness Analysis - Industry Specialization
-- Purpose: Industry cluster analysis and specialization patterns
-- Database: Business_Readiness_USA
-- =====================================================

-- Create industry specialization analysis
WITH industry_metrics AS (
    SELECT 
        FIPS,
        STNAME,
        CTYNAME,
        total_specializations,
        diversity,
        Retail_Services_specialized,
        Pro_Tech_specialized,
        Health_Edu_specialized,
        Manufacturing_specialized,
        Logistics_Trade_specialized,
        Retail_Services_mean_share,
        Pro_Tech_mean_share,
        Health_Edu_mean_share,
        Manufacturing_mean_share,
        Logistics_Trade_mean_share,
        top1_naics, top1_LQ,
        top2_naics, top2_LQ,
        top3_naics, top3_LQ,
        top4_naics, top4_LQ,
        top5_naics, top5_LQ,
        (Retail_Services_specialized + Pro_Tech_specialized 
         + Health_Edu_specialized + Manufacturing_specialized 
         + Logistics_Trade_specialized) AS specialization_count,
        CASE 
            WHEN Retail_Services_mean_share = GREATEST(Retail_Services_mean_share, Pro_Tech_mean_share, Health_Edu_mean_share, Manufacturing_mean_share, Logistics_Trade_mean_share) THEN 'Retail/Services'
            WHEN Pro_Tech_mean_share = GREATEST(Retail_Services_mean_share, Pro_Tech_mean_share, Health_Edu_mean_share, Manufacturing_mean_share, Logistics_Trade_mean_share) THEN 'Pro/Tech'
            WHEN Health_Edu_mean_share = GREATEST(Retail_Services_mean_share, Pro_Tech_mean_share, Health_Edu_mean_share, Manufacturing_mean_share, Logistics_Trade_mean_share) THEN 'Health/Education'
            WHEN Manufacturing_mean_share = GREATEST(Retail_Services_mean_share, Pro_Tech_mean_share, Health_Edu_mean_share, Manufacturing_mean_share, Logistics_Trade_mean_share) THEN 'Manufacturing'
            ELSE 'Logistics/Trade'
        END AS dominant_industry
    FROM county_business_readiness_2023
)
SELECT *
INTO county_industry_specialization_analysis
FROM industry_metrics
ORDER BY total_specializations DESC, diversity DESC;

-- Industry specialization summary by cluster
SELECT 'Retail/Services' AS industry_cluster, SUM(Retail_Services_specialized) AS specialized_counties, AVG(Retail_Services_mean_share) AS avg_market_share, COUNT(*) AS total_counties, CAST(SUM(Retail_Services_specialized) AS FLOAT) / COUNT(*) * 100 AS specialization_rate FROM county_business_readiness_2023
UNION ALL
SELECT 'Pro/Tech', SUM(Pro_Tech_specialized), AVG(Pro_Tech_mean_share), COUNT(*), CAST(SUM(Pro_Tech_specialized) AS FLOAT) / COUNT(*) * 100 FROM county_business_readiness_2023
UNION ALL
SELECT 'Health/Education', SUM(Health_Edu_specialized), AVG(Health_Edu_mean_share), COUNT(*), CAST(SUM(Health_Edu_specialized) AS FLOAT) / COUNT(*) * 100 FROM county_business_readiness_2023
UNION ALL
SELECT 'Manufacturing', SUM(Manufacturing_specialized), AVG(Manufacturing_mean_share), COUNT(*), CAST(SUM(Manufacturing_specialized) AS FLOAT) / COUNT(*) * 100 FROM county_business_readiness_2023
UNION ALL
SELECT 'Logistics/Trade', SUM(Logistics_Trade_specialized), AVG(Logistics_Trade_mean_share), COUNT(*), CAST(SUM(Logistics_Trade_specialized) AS FLOAT) / COUNT(*) * 100 FROM county_business_readiness_2023;

-- Top specialized counties by industry cluster
SELECT 'Retail/Services' as industry, FIPS, STNAME, CTYNAME, Retail_Services_mean_share as market_share, total_specializations FROM county_business_readiness_2023 WHERE Retail_Services_specialized = 1 ORDER BY Retail_Services_mean_share DESC;

-- Multi-industry specialization analysis
SELECT total_specializations, COUNT(*) as county_count, AVG(diversity) as avg_diversity, AVG(estab_growth_pct) as avg_estab_growth, AVG(empl_growth_pct) as avg_empl_growth FROM county_business_readiness_2023 GROUP BY total_specializations ORDER BY total_specializations;

-- NAICS concentration analysis
WITH naics_analysis AS (
    SELECT top1_naics as naics_code, COUNT(*) as county_count, AVG(top1_LQ) as avg_location_quotient, MAX(top1_LQ) as max_location_quotient FROM county_business_readiness_2023 WHERE top1_naics > 0 GROUP BY top1_naics
    UNION ALL
    SELECT top2_naics, COUNT(*), AVG(top2_LQ), MAX(top2_LQ) FROM county_business_readiness_2023 WHERE top2_naics > 0 GROUP BY top2_naics
    UNION ALL
    SELECT top3_naics, COUNT(*), AVG(top3_LQ), MAX(top3_LQ) FROM county_business_readiness_2023 WHERE top3_naics > 0 GROUP BY top3_naics
)
SELECT TOP 20 naics_code, SUM(county_count) as total_appearances, AVG(avg_location_quotient) as overall_avg_lq, MAX(max_location_quotient) as highest_lq FROM naics_analysis GROUP BY naics_code ORDER BY SUM(county_count) DESC;

-- State-level industry specialization patterns
SELECT STNAME, COUNT(*) as total_counties, SUM(Retail_Services_specialized) as retail_specialized, SUM(Pro_Tech_specialized) as tech_specialized, SUM(Health_Edu_specialized) as health_specialized, SUM(Manufacturing_specialized) as manufacturing_specialized, SUM(Logistics_Trade_specialized) as logistics_specialized, AVG(total_specializations) as avg_specializations_per_county FROM county_business_readiness_2023 GROUP BY STNAME ORDER BY avg_specializations_per_county DESC;
