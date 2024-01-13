-- This script retrieves information about cases and CIs for reporting purposes.

-- Selecting columns from Configuration_Item (CI) table
SELECT 
    CI.id AS 'CI ID', 
    CI.description AS 'CI Title', 
    CITP.description AS 'Parent CI Group',
    CIT.description AS 'CI Type', 
    Item.description AS 'CI Model', 
    CI.Virtual_IPAddresses AS 'IP Address', 
    CASE
        WHEN CI.Virtual_DataSource = 0 THEN 'V-CENTER'
        WHEN CI.Virtual_DataSource = 1 THEN 'SOLARWINDS'
        WHEN CI.Virtual_DataSource = 2 THEN 'CISCO-PRIME'
        ELSE 'NO-SOURCE'
    END AS 'Identification Method', 
    (SELECT DBO.PersianDate(create_datetime) FROM History WHERE description = 'CI Configuration Created' AND History.root_pk = CI.ci_pk) AS 'Creation Date', -- Creation Date (Persian)
    DBO.PersianDate(CI.calibration_date) AS 'Calibration Date', -- Calibration Date (Persian)
    CASE
        WHEN CI.operation_status = 0 THEN 'Unknown'
        WHEN CI.operation_status = 1 THEN 'Normal'
        WHEN CI.operation_status = 2 THEN 'Warning'
        WHEN CI.operation_status = 3 THEN 'Critical'
    END AS 'Operational Status', 
    CI.optional_number AS 'MAC Address', 
    CASE
        WHEN CI.status = 0 THEN 'Out of Service'
        WHEN CI.status = 3 THEN 'Pending Investigation'
        WHEN CI.status = 4 THEN 'Operational'
    END AS 'Status', 
    Case_Table.id 'Case ID', 
    Case_Type.description 'Case Type', 
    C1.description 'Product', 
    C2.description 'Service', 
    CASE
        WHEN case_table.case_status = 0 THEN 'Created'
        WHEN case_table.case_status = 1 THEN 'In Progress'
        WHEN case_table.case_status = 2 THEN 'Resolved'
        WHEN case_table.case_status = 3 THEN 'Completed'
    END AS 'Case Status', 
    COUNT(Case_CI.ci_pk) OVER (PARTITION BY Case_CI.case_pk) 'Attached CI Count' -- This window function retrieves the count of each CI attached to a case
FROM Configuration_Item CI 	
    LEFT JOIN Case_CI ON Case_CI.ci_pk = CI.ci_pk
    LEFT JOIN Case_Table ON Case_CI.case_pk = Case_Table.case_pk
    LEFT JOIN Configuration_Item AS C1 ON Case_Table.ci_pk = C1.ci_pk
    LEFT JOIN Configuration_Item AS C2 ON Case_Table.ci2_pk = C2.ci_pk
    LEFT JOIN Case_Type ON Case_Table.case_type_pk = Case_Type.case_type_pk
    LEFT JOIN Configuration_Item_Type CIT ON CI.ci_type_pk = CIT.ci_type_pk
    LEFT JOIN Configuration_Item_Type CITP ON CITP.ci_type_pk = CIT.parent_ci_type_pk
    LEFT JOIN Item ON CI.item_pk = Item.item_pk
WHERE 
    CI.ci_type_pk NOT IN (83497927, 83501456, 83517507, 83513546)
