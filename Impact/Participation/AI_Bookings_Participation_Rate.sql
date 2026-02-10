-- 1. Get the list of ALL reps (Base Population)
WITH all_reps AS (
    SELECT DISTINCT 
        salesforce_user_bcv.ID AS owner_id, 
        salesforce_user_bcv.NAME AS rep_name
    FROM FUNCTIONAL.GTM_SALES_OPS.GTMSI_CONSOLIDATED_PIPELINE_BOOKINGS b
    JOIN CLEANSED.SALESFORCE.SALESFORCE_OPPORTUNITY_BCV o ON b.CRM_OPPORTUNITY_ID = o.ID
    JOIN CLEANSED.SALESFORCE.SALESFORCE_USER_BCV salesforce_user_bcv ON o.OWNER_ID = salesforce_user_bcv.ID
    WHERE 
        o.IS_WON = TRUE 
        AND b.DATE_LABEL = 'today'
        -- CRITICAL FILTERS ADDED HERE
        AND b.PRODUCT_ARR_USD > 0 
        AND b.OPPORTUNITY_IS_COMMISSIONABLE = TRUE
),

-- 2. CTE for COPILOT Wins
copilot_wins AS (
    SELECT 
        o.OWNER_ID, 
        COUNT(DISTINCT o.ID) AS copilot_count
    FROM FUNCTIONAL.GTM_SALES_OPS.GTMSI_CONSOLIDATED_PIPELINE_BOOKINGS b
    JOIN CLEANSED.SALESFORCE.SALESFORCE_OPPORTUNITY_BCV o ON b.CRM_OPPORTUNITY_ID = o.ID
    WHERE 
        b.PRODUCT = 'Copilot'
        AND o.IS_WON = TRUE
        AND b.DATE_LABEL = 'today'
        -- CRITICAL FILTERS ADDED HERE
        AND b.PRODUCT_ARR_USD > 0 
        AND b.OPPORTUNITY_IS_COMMISSIONABLE = TRUE
    GROUP BY 1
),

-- 3. CTE for AI AGENTS Wins
ai_agents_wins AS (
    SELECT 
        o.OWNER_ID, 
        COUNT(DISTINCT o.ID) AS agents_count
    FROM FUNCTIONAL.GTM_SALES_OPS.GTMSI_CONSOLIDATED_PIPELINE_BOOKINGS b
    JOIN CLEANSED.SALESFORCE.SALESFORCE_OPPORTUNITY_BCV o ON b.CRM_OPPORTUNITY_ID = o.ID
    WHERE 
        b.PRODUCT IN ('Ultimate', 'Ultimate_AR', 'Zendesk_AR')
        AND o.IS_WON = TRUE
        AND b.DATE_LABEL = 'today'
        -- CRITICAL FILTERS ADDED HERE
        AND b.PRODUCT_ARR_USD > 0 
        AND b.OPPORTUNITY_IS_COMMISSIONABLE = TRUE
    GROUP BY 1
),

-- 4. CTE for QA Wins
qa_wins AS (
    SELECT 
        o.OWNER_ID, 
        COUNT(DISTINCT o.ID) AS qa_count
    FROM FUNCTIONAL.GTM_SALES_OPS.GTMSI_CONSOLIDATED_PIPELINE_BOOKINGS b
    JOIN CLEANSED.SALESFORCE.SALESFORCE_OPPORTUNITY_BCV o ON b.CRM_OPPORTUNITY_ID = o.ID
    WHERE 
        b.PRODUCT = 'QA'
        AND o.IS_WON = TRUE
        AND b.DATE_LABEL = 'today'
        -- CRITICAL FILTERS ADDED HERE
        AND b.PRODUCT_ARR_USD > 0 
        AND b.OPPORTUNITY_IS_COMMISSIONABLE = TRUE
    GROUP BY 1
)

-- 5. FINAL JOIN: The "Human Readable" Output
SELECT 
    r.rep_name,
    r.owner_id,
    
    -- Show the counts per bucket
    COALESCE(c.copilot_count, 0) AS count_copilot,
    COALESCE(a.agents_count, 0) AS count_ai_agents,
    COALESCE(q.qa_count, 0) AS count_qa,
    
    -- The Logic: Did they sell at least 1 of EACH?
    CASE 
        WHEN COALESCE(c.copilot_count, 0) > 0 
             AND COALESCE(a.agents_count, 0) > 0 
             AND COALESCE(q.qa_count, 0) > 0 
        THEN 1 
        ELSE 0 
    END AS is_triple_crown_winner

FROM all_reps r
LEFT JOIN copilot_wins c ON r.owner_id = c.OWNER_ID
LEFT JOIN ai_agents_wins a ON r.owner_id = a.OWNER_ID
LEFT JOIN qa_wins q ON r.owner_id = q.OWNER_ID

ORDER BY is_triple_crown_winner DESC, r.rep_name;
