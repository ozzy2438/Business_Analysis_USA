
-- =====================================================
-- 02_OPPORTUNITY_SCORING.SQL
-- County Business Readiness Analysis - Opportunity Scoring
-- Purpose: Core opportunity score calculations and tier assignments
-- Database: Business_Readiness_USA
-- =====================================================

-- Create opportunity scoring calculations
WITH opportunity_calculations AS (
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
        
        -- OPPORTUNITY SCORE CALCULATION
        -- Weighted average of growth, density, and diversity metrics
        (
            estab_growth_pct * 0.25 + 
            empl_growth_pct * 0.25 + 
            (estab_per_1k / MAX(estab_per_1k) OVER()) * 0.25 + 
            diversity * 0.25
        ) * 100 AS opportunity_score
        
    FROM county_business_readiness_2023
),

-- Add percentile rankings and tiers
opportunity_with_percentiles AS (
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
        END AS opportunity_tier
        
    FROM opportunity_calculations
)

-- Final opportunity scoring table
SELECT * 
INTO county_opportunity_scores
FROM opportunity_with_percentiles
ORDER BY opportunity_score DESC;

-- Validation queries for opportunity scoring

-- Check opportunity score distribution
SELECT 
    opportunity_tier,
    COUNT(*) as county_count,
    MIN(opportunity_score) as min_score,
    MAX(opportunity_score) as max_score,
    AVG(opportunity_score) as avg_score
FROM county_opportunity_scores
GROUP BY opportunity_tier
ORDER BY opportunity_tier;

-- Top 20 counties by opportunity score
SELECT TOP 20
    FIPS,
    STNAME,
    CTYNAME,
    opportunity_score,
    opportunity_tier,
    opportunity_pctile,
    estab_growth_pct,
    empl_growth_pct,
    diversity
FROM county_opportunity_scores
ORDER BY opportunity_score DESC;

-- State-level opportunity summary
SELECT 
    STNAME,
    COUNT(*) as total_counties,
    AVG(opportunity_score) as avg_opportunity_score,
    MAX(opportunity_score) as max_opportunity_score,
    SUM(CASE WHEN opportunity_tier = 'A' THEN 1 ELSE 0 END) as tier_a_counties,
    SUM(CASE WHEN opportunity_tier = 'B' THEN 1 ELSE 0 END) as tier_b_counties,
    SUM(CASE WHEN opportunity_tier = 'C' THEN 1 ELSE 0 END) as tier_c_counties,
    SUM(CASE WHEN opportunity_tier = 'D' THEN 1 ELSE 0 END) as tier_d_counties
FROM county_opportunity_scores
GROUP BY STNAME
ORDER BY avg_opportunity_score DESC;

-- Opportunity score component analysis
SELECT 
    'Establishment Growth' as component,
    CORR(estab_growth_pct, opportunity_score) as correlation_with_opportunity
FROM county_opportunity_scores
UNION ALL
SELECT 
    'Employment Growth',
    CORR(empl_growth_pct, opportunity_score)
FROM county_opportunity_scores
UNION ALL
SELECT 
    'Establishment Density',
    CORR(estab_per_1k, opportunity_score)
FROM county_opportunity_scores
UNION ALL
SELECT 
    'Diversity Score',
    CORR(diversity, opportunity_score)
FROM county_opportunity_scores;
