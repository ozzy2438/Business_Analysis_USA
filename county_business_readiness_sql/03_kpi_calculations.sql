
-- =====================================================
-- 03_KPI_CALCULATIONS.SQL
-- County Business Readiness Analysis - KPI Calculations
-- Purpose: Market potential, expansion readiness, risk categories
-- Database: Business_Readiness_USA
-- =====================================================

-- Create comprehensive KPI calculations
WITH base_kpis AS (
    SELECT 
        FIPS,
        STNAME,
        CTYNAME,
        estab_growth_pct,
        empl_growth_pct,
        estab_per_1k,
        empl_per_1k,
        diversity,
        total_specializations,
        Retail_Services_specialized,
        Pro_Tech_specialized,
        Health_Edu_specialized,
        Manufacturing_specialized,
        Logistics_Trade_specialized,
        
        -- OPPORTUNITY SCORE (from previous step)
        (
            estab_growth_pct * 0.25 + 
            empl_growth_pct * 0.25 + 
            (estab_per_1k / MAX(estab_per_1k) OVER()) * 0.25 + 
            diversity * 0.25
        ) * 100 AS opportunity_score,
        
        -- MARKET POTENTIAL CALCULATION
        -- Employment density multiplied by establishment growth
        empl_per_1k * estab_growth_pct AS market_potential,
        
        -- COMPETITIVE INTENSITY CALCULATION
        -- Establishments per 1k relative to median
        estab_per_1k / PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estab_per_1k) 
            OVER() AS competitive_intensity
        
    FROM county_business_readiness_2023
),

-- Add advanced KPI calculations
advanced_kpis AS (
    SELECT 
        *,
        
        -- OPPORTUNITY PERCENTILE
        PERCENT_RANK() OVER (ORDER BY opportunity_score) * 100 AS opportunity_pctile,
        
        -- OPPORTUNITY TIER (A, B, C, D based on quartiles)
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.75 THEN 'A'
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.50 THEN 'B'
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.25 THEN 'C'
            ELSE 'D'
        END AS opportunity_tier,
        
        -- EXPANSION READINESS INDEX
        -- Combines opportunity score with specializations and diversity
        opportunity_score * 
        (1 + CAST(total_specializations AS FLOAT) / 5) * 
        (1 + diversity) AS expansion_readiness,
        
        -- RISK CATEGORY
        -- Based on growth volatility and diversity
        CASE 
            WHEN estab_growth_pct < -0.05 OR diversity < 0.7 THEN 'High'
            WHEN estab_growth_pct > 0.15 AND diversity > 0.9 THEN 'Low'
            ELSE 'Medium'
        END AS risk_category
        
    FROM base_kpis
),

-- Add Power BI helper flags
final_kpis AS (
    SELECT 
        *,
        
        -- Tier flags for easy filtering in Power BI
        CASE WHEN opportunity_tier = 'A' THEN 1 ELSE 0 END AS is_tier_a,
        CASE WHEN opportunity_tier = 'B' THEN 1 ELSE 0 END AS is_tier_b,
        CASE WHEN opportunity_tier = 'C' THEN 1 ELSE 0 END AS is_tier_c,
        CASE WHEN opportunity_tier = 'D' THEN 1 ELSE 0 END AS is_tier_d,
        
        -- Risk flags
        CASE WHEN risk_category = 'High' THEN 1 ELSE 0 END AS is_high_risk,
        CASE WHEN risk_category = 'Low' THEN 1 ELSE 0 END AS is_low_risk,
        
        -- Specialization flag
        CASE WHEN total_specializations >= 3 THEN 1 ELSE 0 END AS is_multi_specialized,
        
        -- Expansion readiness flag (top 10%)
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY expansion_readiness) >= 0.9 
            THEN 1 ELSE 0 
        END AS is_expansion_ready,
        
        -- Opportunity rank
        RANK() OVER (ORDER BY opportunity_score DESC) AS opportunity_rank,
        
        -- State rank
        RANK() OVER (PARTITION BY STNAME ORDER BY opportunity_score DESC) AS state_rank
        
    FROM advanced_kpis
)

-- Create the comprehensive KPI table
SELECT * 
INTO county_business_readiness_kpi_comprehensive
FROM final_kpis
ORDER BY opportunity_score DESC;

-- Validation queries for KPI calculations

-- KPI distribution summary
SELECT 
    'Market Potential' as kpi_name,
    MIN(market_potential) as min_value,
    MAX(market_potential) as max_value,
    AVG(market_potential) as avg_value,
    STDEV(market_potential) as std_dev
FROM county_business_readiness_kpi_comprehensive
UNION ALL
SELECT 
    'Expansion Readiness',
    MIN(expansion_readiness),
    MAX(expansion_readiness),
    AVG(expansion_readiness),
    STDEV(expansion_readiness)
FROM county_business_readiness_kpi_comprehensive
UNION ALL
SELECT 
    'Competitive Intensity',
    MIN(competitive_intensity),
    MAX(competitive_intensity),
    AVG(competitive_intensity),
    STDEV(competitive_intensity)
FROM county_business_readiness_kpi_comprehensive;

-- Risk category analysis
SELECT 
    risk_category,
    COUNT(*) as county_count,
    AVG(opportunity_score) as avg_opportunity_score,
    AVG(expansion_readiness) as avg_expansion_readiness,
    AVG(market_potential) as avg_market_potential
FROM county_business_readiness_kpi_comprehensive
GROUP BY risk_category
ORDER BY avg_opportunity_score DESC;

-- Top expansion opportunities
SELECT TOP 25
    FIPS,
    STNAME,
    CTYNAME,
    opportunity_score,
    expansion_readiness,
    market_potential,
    risk_category,
    total_specializations,
    opportunity_tier
FROM county_business_readiness_kpi_comprehensive
WHERE risk_category != 'High'
ORDER BY expansion_readiness DESC;

-- Correlation analysis between KPIs
SELECT 
    'Opportunity vs Market Potential' as correlation_pair,
    CORR(opportunity_score, market_potential) as correlation_coefficient
FROM county_business_readiness_kpi_comprehensive
UNION ALL
SELECT 
    'Opportunity vs Expansion Readiness',
    CORR(opportunity_score, expansion_readiness)
FROM county_business_readiness_kpi_comprehensive
UNION ALL
SELECT 
    'Market Potential vs Expansion Readiness',
    CORR(market_potential, expansion_readiness)
FROM county_business_readiness_kpi_comprehensive;
