-- This script retrieves information about OLA logs which are duplicated for reporting purposes.

-- Selecting relevant columns for reporting
SELECT 
    Case_Table.id AS 'Case ID',
    CONCAT(User_Group.id, Case_Category.id) AS 'Classification and User Group ID',
    Case_Category.description AS 'Service Classification',
    User_Group.description AS 'User Group',
    DBO.PersianDate(Case_Table.opened_date) AS 'Persian Opened Date',
    COUNT(CONCAT(User_Group.id, Case_Category.id, C09.Virtual_StartDateTime)) AS 'Number of OLA Log Duplicates'
FROM Custom_Entity09 C09
    -- Joining tables to get the necessary information
    LEFT JOIN User_Group ON User_Group.user_group_pk = C09.Virtual_ResponsibleGroup
    LEFT JOIN Case_Table ON Case_Table.case_pk = C09.Virtual_Case
    LEFT JOIN Case_Category ON Case_Table.case_category_pk = Case_Category.case_category_pk
-- Grouping by relevant columns to identify duplicates
GROUP BY
    Case_Table.id,
    Case_Category.description,
    User_Group.description,
    Case_Category.id,
    User_Group.id,
    Virtual_ElapsedMinutes,
    C09.Virtual_StartDateTime,
    Case_Table.opened_date
-- Filtering duplicates based on counts
HAVING COUNT(CONCAT(Case_Category.id, User_Group.id)) > 1 
    AND COUNT(C09.Virtual_ElapsedMinutes) > 1
    AND COUNT(C09.Virtual_StartDateTime) > 1
-- Sorting the results by opened_date in descending order
ORDER BY 
    Case_Table.opened_date DESC
