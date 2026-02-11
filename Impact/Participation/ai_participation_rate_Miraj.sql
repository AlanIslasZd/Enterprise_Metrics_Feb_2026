-- 1. Roster (Denominator)
WITH roster AS (
    SELECT DISTINCT
        usr.id AS AE_ID,
        usr.name AS AE_NAME,
        usr.vp_team_c AS VP_TEAM
    FROM CLEANSED.SALESFORCE.SALESFORCE_USER_SCD2 AS usr
    INNER JOIN CLEANSED.SALESFORCE.SALESFORCE_USER_TERRITORY_2_ASSOCIATION_SCD2 AS assoc
        ON usr.id = assoc.user_id AND assoc.valid_to_timestamp = '9999-12-31'
        AND assoc.role_in_territory_2 IN ('Account Executive', 'Account Executive - Coverage')
    WHERE usr.valid_to_timestamp = '9999-12-31'
      AND usr.is_active = TRUE
      AND usr.vp_team_c ='AMER'
      AND usr.market_segment_c NOT IN ('SMB', 'Digital') 
),

-- 2. Opportunities (Source)
created_opps AS (
    SELECT
        o.OWNERID,
        o.CRM_OPPORTUNITY_ID,
        o.PRODUCT,
        o.product_arr_usd,
        o.stage_name,
        o.OPPORTUNITY_STATUS
    FROM FUNCTIONAL.GTM_SALES_OPS.GTMSI_CONSOLIDATED_PIPELINE_BOOKINGS o
    WHERE o.DATE_LABEL = 'today'
      AND o.stage_2_plus_date_c >= '2025-01-01'
      AND o.stage_2_plus_date_c <=  {{AS_OF_DATE}}
      AND (product_arr_usd > 0 or product_booking_arr_usd > 0)
      AND opportunity_is_commissionable = 'TRUE'
      AND region = 'NA'
      AND pro_forma_market_segment not in ('Digital', 'SMB') 
),

-- 3. AI Stats (AGGREGATED BY AE ONLY - NO QUARTER)
ae_ai_stats AS (
    SELECT
        OWNERID,
        
        -- Raw Counts for Diagnostics
        COUNT(DISTINCT CASE WHEN PRODUCT = 'Copilot' AND product_arr_usd > 0 
            AND opportunity_status='Open' 
            AND left(stage_name, 2) in ('02','03','04','05','06','07','08') 
            THEN CRM_OPPORTUNITY_ID END) AS raw_copilot_count,
            
        COUNT(DISTINCT CASE WHEN PRODUCT IN ('Ultimate_AR','Zendesk_AR','Ultimate','AR') AND product_arr_usd > 0 
            AND opportunity_status='Open' 
            AND left(stage_name, 2) in ('02','03','04','05','06','07','08') 
            THEN CRM_OPPORTUNITY_ID END) AS raw_agent_count,

        -- The Flag Logic
        CASE WHEN 
            COUNT(DISTINCT CASE WHEN PRODUCT = 'Copilot' AND product_arr_usd > 0 
                AND opportunity_status='Open' 
                AND left(stage_name, 2) in ('02','03','04','05','06','07','08') 
                THEN CRM_OPPORTUNITY_ID END) > 1 
            AND 
            COUNT(DISTINCT CASE WHEN PRODUCT IN ('Ultimate_AR','Zendesk_AR','Ultimate','AR') AND product_arr_usd > 0 
                AND opportunity_status='Open' 
                AND left(stage_name, 2) in ('02','03','04','05','06','07','08') 
                THEN CRM_OPPORTUNITY_ID END) > 1
        THEN 1 ELSE 0 END AS AI_S2_Combined_Flag

    FROM created_opps
    GROUP BY OWNERID
)

-- 4. Final Output (AE Level Detail)
SELECT 
    {{AS_OF_DATE}} as as_of_date,
    r.AE_NAME,
    COALESCE(s.raw_copilot_count, 0) as "Copilot Deals (S2+)",
    COALESCE(s.raw_agent_count, 0) as "Agent Deals (S2+)",
    COALESCE(s.AI_S2_Combined_Flag, 0) as "Hit AI Flag?"
FROM roster r
LEFT JOIN ae_ai_stats s ON r.AE_ID = s.OWNERID
ORDER BY 4 DESC, 2 DESC;
