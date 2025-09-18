
-- =====================================================
-- 04_RANKING_MATRICES.SQL
-- County Business Readiness Analysis - Ranking Matrices
-- Purpose: Top 20 county rankings and state summaries
-- Database: Business_Readiness_USA
-- =====================================================

-- Create the State & County Ranking Matrix table
-- Top 20 counties with all metrics from the dashboard
WITH RankedCounties AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY opportunity_score DESC) AS rank,
        FIPS,
        STNAME,
        CTYNAME,
        opportunity_score,
        opportunity_tier,
        estab_growth_pct,
        empl_growth_pct,
        diversity,
        total_specializations,
        expansion_readiness,
        risk_category,
        market_potential,
        competitive_intensity,
        opportunity_pctile,
        estab_per_1k,
        empl_per_1k,
        Retail_Services_specialized,
        Pro_Tech_specialized,
        Health_Edu_specialized,
        Manufacturing_specialized,
        Logistics_Trade_specialized
    FROM county_business_readiness_kpi_comprehensive
)
SELECT TOP 20 *
INTO state_county_ranking_matrix
FROM RankedCounties
ORDER BY rank;

-- Create state-level ranking summaries
WITH StateRankings AS (
    SELECT 
        STNAME,
        COUNT(*) as total_counties,
        AVG(opportunity_score) as avg_opportunity_score,
        MAX(opportunity_score) as max_opportunity_score,
        MIN(opportunity_score) as min_opportunity_score,
        SUM(CASE WHEN opportunity_tier = 'A' THEN 1 ELSE 0 END) as tier_a_counties,
        SUM(CASE WHEN opportunity_tier = 'B' THEN 1 ELSE 0 END) as tier_b_counties,
        SUM(CASE WHEN opportunity_tier = 'C' THEN 1 ELSE 0 END) as tier_c_counties,
        SUM(CASE WHEN opportunity_tier = 'D' THEN 1 ELSE 0 END) as tier_d_counties,
        AVG(expansion_readiness) as avg_expansion_readiness,
        AVG(market_potential) as avg_market_potential,
        SUM(CASE WHEN risk_category = 'High' THEN 1 ELSE 0 END) as high_risk_counties,
        SUM(CASE WHEN risk_category = 'Low' THEN 1 ELSE 0 END) as low_risk_counties,
        AVG(total_specializations) as avg_specializations,
        ROW_NUMBER() OVER (ORDER BY AVG(opportunity_score) DESC) as state_rank
    FROM county_business_readiness_kpi_comprehensive
    GROUP BY STNAME
)
SELECT *
INTO state_rank_summaries
FROM StateRankings
ORDER BY state_rank;

-- Create top 10 counties by state
WITH TopCountiesByState AS (
    SELECT 
        FIPS,
        STNAME,
        CTYNAME,
        opportunity_score,
        opportunity_tier,
        expansion_readiness,
        risk_category,
        total_specializations,
        ROW_NUMBER() OVER (PARTITION BY STNAME ORDER BY opportunity_score DESC) as state_county_rank
    FROM county_business_readiness_kpi_comprehensive
)
SELECT *
INTO top10_by_state
FROM TopCountiesByState
WHERE state_county_rank <= 10
ORDER BY STNAME, state_county_rank;

-- Create county rankings topline summary
WITH CountyRankings AS (
    SELECT 
        FIPS,
        STNAME,
        CTYNAME,
        opportunity_score,
        opportunity_tier,
        opportunity_pctile,
        expansion_readiness,
        market_potential,
        risk_category,
        total_specializations,
        estab_growth_pct,
        empl_growth_pct,
        diversity,
        competitive_intensity,
        ROW_NUMBER() OVER (ORDER BY opportunity_score DESC) as national_rank,
        ROW_NUMBER() OVER (PARTITION BY STNAME ORDER BY opportunity_score DESC) as state_rank,
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.95 THEN 'Top 5%'
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.90 THEN 'Top 10%'
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.75 THEN 'Top 25%'
            WHEN PERCENT_RANK() OVER (ORDER BY opportunity_score) >= 0.50 THEN 'Top 50%'
            ELSE 'Bottom 50%'
        END as performance_tier
    FROM county_business_readiness_kpi_comprehensive
)
SELECT *
INTO county_rankings_topline
FROM CountyRankings
ORDER BY national_rank;

-- Validation queries for ranking matrices

-- Verify top 20 ranking matrix
SELECT 
    'Top 20 Counties' as summary_type,
    COUNT(*) as record_count,
    MIN(opportunity_score) as min_score,
    MAX(opportunity_score) as max_score,
    AVG(opportunity_score) as avg_score
FROM state_county_ranking_matrix;

-- State ranking distribution
SELECT 
    'State Rankings' as summary_type,
    COUNT(*) as state_count,
    MIN(avg_opportunity_score) as min_avg_score,
    MAX(avg_opportunity_score) as max_avg_score,
    AVG(avg_opportunity_score) as overall_avg_score
FROM state_rank_summaries;

-- Performance tier distribution
SELECT 
    performance_tier,
    COUNT(*) as county_count,
    AVG(opportunity_score) as avg_score,
    MIN(opportunity_score) as min_score,
    MAX(opportunity_score) as max_score
FROM county_rankings_topline
GROUP BY performance_tier
ORDER BY avg_score DESC;

-- Top performing states (by average opportunity score)
SELECT TOP 10
    STNAME,
    total_counties,
    avg_opportunity_score,
    tier_a_counties,
    low_risk_counties,
    avg_specializations
FROM state_rank_summaries
ORDER BY avg_opportunity_score DESC;

-- Counties with highest expansion readiness by tier
SELECT 
    opportunity_tier,
    COUNT(*) as county_count,
    AVG(expansion_readiness) as avg_expansion_readiness,
    MAX(expansion_readiness) as max_expansion_readiness,
    AVG(market_potential) as avg_market_potential
FROM county_rankings_topline
GROUP BY opportunity_tier
ORDER BY avg_expansion_readiness DESC;
