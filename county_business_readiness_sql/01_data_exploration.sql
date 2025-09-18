
-- =====================================================
-- 01_DATA_EXPLORATION.SQL
-- County Business Readiness Analysis - Data Exploration
-- Purpose: Initial data validation and exploration queries
-- Database: Business_Readiness_USA
-- =====================================================

-- Check table structure and record counts
SELECT 'county_business_readiness_2023' as table_name, COUNT(*) as record_count
FROM county_business_readiness_2023
UNION ALL
SELECT 'county_growth_2020_2023_with_industry', COUNT(*)
FROM county_growth_2020_2023_with_industry
UNION ALL
SELECT 'county_industry_clusters_2023', COUNT(*)
FROM county_industry_clusters_2023;

-- Data quality checks
SELECT 
    'Missing FIPS codes' as check_type,
    COUNT(*) as issue_count
FROM county_business_readiness_2023
WHERE FIPS IS NULL OR FIPS = ''
UNION ALL
SELECT 
    'Missing State Names',
    COUNT(*)
FROM county_business_readiness_2023
WHERE STNAME IS NULL OR STNAME = ''
UNION ALL
SELECT 
    'Missing County Names',
    COUNT(*)
FROM county_business_readiness_2023
WHERE CTYNAME IS NULL OR CTYNAME = ''
UNION ALL
SELECT 
    'Negative Growth Rates',
    COUNT(*)
FROM county_business_readiness_2023
WHERE estab_growth_pct < -1 OR empl_growth_pct < -1;

-- Basic statistics for key metrics
SELECT 
    'Establishment Growth' as metric,
    MIN(estab_growth_pct) as min_value,
    MAX(estab_growth_pct) as max_value,
    AVG(estab_growth_pct) as avg_value,
    STDEV(estab_growth_pct) as std_dev
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Employment Growth',
    MIN(empl_growth_pct),
    MAX(empl_growth_pct),
    AVG(empl_growth_pct),
    STDEV(empl_growth_pct)
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Diversity Score',
    MIN(diversity),
    MAX(diversity),
    AVG(diversity),
    STDEV(diversity)
FROM county_business_readiness_2023;

-- State-level summary for validation
SELECT 
    STNAME,
    COUNT(*) as county_count,
    AVG(estab_growth_pct) as avg_estab_growth,
    AVG(empl_growth_pct) as avg_empl_growth,
    AVG(diversity) as avg_diversity
FROM county_business_readiness_2023
GROUP BY STNAME
ORDER BY county_count DESC;

-- Industry specialization overview
SELECT 
    'Retail/Services' as industry,
    SUM(Retail_Services_specialized) as specialized_counties,
    AVG(Retail_Services_mean_share) as avg_market_share
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Pro/Tech',
    SUM(Pro_Tech_specialized),
    AVG(Pro_Tech_mean_share)
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Health/Education',
    SUM(Health_Edu_specialized),
    AVG(Health_Edu_mean_share)
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Manufacturing',
    SUM(Manufacturing_specialized),
    AVG(Manufacturing_mean_share)
FROM county_business_readiness_2023
UNION ALL
SELECT 
    'Logistics/Trade',
    SUM(Logistics_Trade_specialized),
    AVG(Logistics_Trade_mean_share)
FROM county_business_readiness_2023;

-- Outlier detection
SELECT 
    FIPS,
    STNAME,
    CTYNAME,
    estab_growth_pct,
    empl_growth_pct,
    'Extreme Growth' as outlier_type
FROM county_business_readiness_2023
WHERE estab_growth_pct > 1.0 OR empl_growth_pct > 1.0
ORDER BY estab_growth_pct DESC;

-- Data completeness check
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN estab_growth_pct IS NOT NULL THEN 1 ELSE 0 END) as estab_growth_complete,
    SUM(CASE WHEN empl_growth_pct IS NOT NULL THEN 1 ELSE 0 END) as empl_growth_complete,
    SUM(CASE WHEN diversity IS NOT NULL THEN 1 ELSE 0 END) as diversity_complete,
    SUM(CASE WHEN total_specializations IS NOT NULL THEN 1 ELSE 0 END) as specializations_complete
FROM county_business_readiness_2023;
