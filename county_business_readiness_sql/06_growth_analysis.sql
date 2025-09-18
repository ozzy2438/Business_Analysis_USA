
-- =====================================================
-- 06_GROWTH_ANALYSIS.SQL
-- County Business Readiness Analysis - Growth Analysis
-- Purpose: 2020-2023 growth calculations and categorization
-- Database: Business_Readiness_USA
-- =====================================================

-- Create comprehensive growth analysis
WITH growth_metrics AS (
    SELECT 
        FIPS,
        est_2020,
        est_2023,
        emp_2020,
        emp_2023,
        estab_growth_pct,
        empl_growth_pct,
        pop_2022,
        estab_per_1k,
        empl_per_1k,
        diversity,
        total_specializations,
        Retail_Services_specialized,
        Pro_Tech_specialized,
        Health_Edu_specialized,
        Manufacturing_specialized,
        Logistics_Trade_specialized,
        estab_growth_pct + empl_growth_pct AS total_growth,
        CASE 
            WHEN (estab_growth_pct + empl_growth_pct) < -0.05 THEN 'Declining'
            WHEN (estab_growth_pct + empl_growth_pct) BETWEEN -0.05 AND 0.05 THEN 'Stable'
            WHEN (estab_growth_pct + empl_growth_pct) BETWEEN 0.05 AND 0.15 THEN 'Growing'
            ELSE 'High Growth'
        END AS growth_category,
        LEFT(FIPS, 2) AS state_code
    FROM county_growth_2020_2023_with_industry
),
growth_with_rankings AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_growth DESC) AS total_growth_rank,
        RANK() OVER (ORDER BY diversity DESC) AS diversity_rank,
        RANK() OVER (ORDER BY total_specializations DESC) AS specialization_rank,
        PERCENT_RANK() OVER (ORDER BY total_growth) * 100 AS total_growth_percentile,
        PERCENT_RANK() OVER (ORDER BY diversity) * 100 AS diversity_percentile,
        CASE WHEN RANK() OVER (ORDER BY total_growth DESC) <= 20 THEN 1 ELSE 0 END AS is_top20_growth,
        CASE WHEN RANK() OVER (ORDER BY diversity DESC) <= 20 THEN 1 ELSE 0 END AS is_top20_diverse,
        CASE WHEN (estab_growth_pct + empl_growth_pct) > 0.15 THEN 1 ELSE 0 END AS is_high_growth,
        CASE WHEN total_specializations >= 3 THEN 1 ELSE 0 END AS is_multi_specialized
    FROM growth_metrics
)
SELECT *
INTO county_growth_analysis_2020_2023
FROM growth_with_rankings
ORDER BY total_growth DESC;

-- Growth category distribution analysis
SELECT 
    growth_category,
    COUNT(*) as county_count,
    CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM county_growth_analysis_2020_2023) * 100 AS percentage,
    AVG(total_growth) as avg_total_growth,
    AVG(estab_growth_pct) as avg_estab_growth,
    AVG(empl_growth_pct) as avg_empl_growth,
    AVG(diversity) as avg_diversity,
    AVG(total_specializations) as avg_specializations
FROM county_growth_analysis_2020_2023
GROUP BY growth_category
ORDER BY avg_total_growth DESC;

-- Top 20 growth performers
SELECT TOP 20
    FIPS,
    state_code,
    total_growth,
    growth_category,
    estab_growth_pct,
    empl_growth_pct,
    diversity,
    total_specializations,
    total_growth_rank
FROM county_growth_analysis_2020_2023
ORDER BY total_growth DESC;

-- State-level growth summary
SELECT 
    state_code,
    COUNT(*) as county_count,
    AVG(total_growth) as avg_total_growth,
    MAX(total_growth) as max_total_growth,
    MIN(total_growth) as min_total_growth,
    SUM(CASE WHEN growth_category = 'High Growth' THEN 1 ELSE 0 END) as high_growth_counties,
    SUM(CASE WHEN growth_category = 'Growing' THEN 1 ELSE 0 END) as growing_counties,
    SUM(CASE WHEN growth_category = 'Stable' THEN 1 ELSE 0 END) as stable_counties,
    SUM(CASE WHEN growth_category = 'Declining' THEN 1 ELSE 0 END) as declining_counties,
    AVG(diversity) as avg_diversity,
    AVG(total_specializations) as avg_specializations
FROM county_growth_analysis_2020_2023
GROUP BY state_code
ORDER BY avg_total_growth DESC;

-- Industry specialization impact on growth
SELECT 
    'Retail/Services' as industry_cluster,
    AVG(CASE WHEN Retail_Services_specialized = 1 THEN total_growth END) as avg_growth_specialized,
    AVG(CASE WHEN Retail_Services_specialized = 0 THEN total_growth END) as avg_growth_not_specialized,
    COUNT(CASE WHEN Retail_Services_specialized = 1 THEN 1 END) as specialized_count
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Pro/Tech',
    AVG(CASE WHEN Pro_Tech_specialized = 1 THEN total_growth END),
    AVG(CASE WHEN Pro_Tech_specialized = 0 THEN total_growth END),
    COUNT(CASE WHEN Pro_Tech_specialized = 1 THEN 1 END)
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Health/Education',
    AVG(CASE WHEN Health_Edu_specialized = 1 THEN total_growth END),
    AVG(CASE WHEN Health_Edu_specialized = 0 THEN total_growth END),
    COUNT(CASE WHEN Health_Edu_specialized = 1 THEN 1 END)
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Manufacturing',
    AVG(CASE WHEN Manufacturing_specialized = 1 THEN total_growth END),
    AVG(CASE WHEN Manufacturing_specialized = 0 THEN total_growth END),
    COUNT(CASE WHEN Manufacturing_specialized = 1 THEN 1 END)
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Logistics/Trade',
    AVG(CASE WHEN Logistics_Trade_specialized = 1 THEN total_growth END),
    AVG(CASE WHEN Logistics_Trade_specialized = 0 THEN total_growth END),
    COUNT(CASE WHEN Logistics_Trade_specialized = 1 THEN 1 END)
FROM county_growth_analysis_2020_2023;

-- Growth correlation analysis
SELECT 
    'Establishment vs Employment Growth' as correlation_pair,
    CORR(estab_growth_pct, empl_growth_pct) as correlation_coefficient
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Total Growth vs Diversity',
    CORR(total_growth, diversity)
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Total Growth vs Specializations',
    CORR(total_growth, total_specializations)
FROM county_growth_analysis_2020_2023
UNION ALL
SELECT 
    'Diversity vs Specializations',
    CORR(diversity, total_specializations)
FROM county_growth_analysis_2020_2023;

-- Multi-specialization growth analysis
SELECT 
    total_specializations,
    COUNT(*) as county_count,
    AVG(total_growth) as avg_total_growth,
    AVG(estab_growth_pct) as avg_estab_growth,
    AVG(empl_growth_pct) as avg_empl_growth,
    AVG(diversity) as avg_diversity,
    SUM(CASE WHEN growth_category = 'High Growth' THEN 1 ELSE 0 END) as high_growth_count
FROM county_growth_analysis_2020_2023
GROUP BY total_specializations
ORDER BY total_specializations;

-- Growth outliers analysis
SELECT 
    FIPS,
    state_code,
    total_growth,
    estab_growth_pct,
    empl_growth_pct,
    'Extreme Growth' as outlier_type
FROM county_growth_analysis_2020_2023
WHERE total_growth > 1.0 OR total_growth < -0.5
ORDER BY total_growth DESC;
