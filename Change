-- Common Table Expression (CTE) to create a temporary table 'TaskTemp'
;WITH TaskTemp AS
(
    -- Selecting relevant columns for tasks
    SELECT
        Task.root_pk,
        Task.id,
        Task.description,
        -- Retrieving task group description from User_Group
        (SELECT description FROM User_Group WHERE Task.responsible_user_group_pk = User_Group.user_group_pk) AS TASKGROUP,
        -- Retrieving task user description from User_Table
        (SELECT description FROM User_Table WHERE Task.responsible_user_pk = User_Table.user_pk) AS TASKUSER,
        -- Mapping task status to Persian descriptions
        CASE
            WHEN Task.status = 0 THEN N'Not Started'
            WHEN Task.status = 1 THEN N'In Progress'
            WHEN Task.status = 2 THEN N'Completed'
            WHEN Task.status = 3 THEN N'Waiting for Another Person'
            WHEN Task.status = 4 THEN N'Rejected'
        END AS TASKSTATUS,
        Task.due_date,
        Task.start_date,
        TASK.end_date,
        Task.Virtual_PersonHour,
        -- Calculating delay time in days
        DATEDIFF(DAY, Task.end_date, Task.due_date) AS DelayTime
    FROM Task
)

-- Main SELECT statement to retrieve information for reporting
SELECT 
    DISTINCT Change_Order.id AS 'Change ID',
    Change_Order.description AS 'Change Title',
    Activity_Plan.description AS 'Change Type',
    -- Categorizing changes based on activity plan description
    CASE 
        WHEN activity_plan.description IN ('Normal Change', 'New Product', 'Major Change', 'Change Request/New Feature in Service') THEN 'Business Change'
        WHEN activity_plan.description = 'Emergency Change' THEN 'Emergency Change'
        WHEN activity_plan.description IN ('Internal Change', 'Technical Change') THEN 'Technical Change'
        WHEN activity_plan.description = 'Unauthorized Change' THEN 'Out of Process'
    END AS 'Change Category',
    DBO.PersianDate(Change_Order.create_time) AS 'Change Registration Time',
    -- Calling a custom function to get the current activity
    (dbo.GetCurrentActivity(Change_Order.change_order_pk)) AS 'Current Activity',
    -- Handling cases where current activity is NULL or an empty string
    CASE	
        WHEN dbo.GetCurrentActivity(Change_Order.change_order_pk) = '' THEN Custom_Entity18.description
        WHEN dbo.GetCurrentActivity(Change_Order.change_order_pk) IS NULL THEN Custom_Entity18.description
        ELSE dbo.GetCurrentActivity(Change_Order.change_order_pk)
    END AS 'Current Stage',
    customer.description AS 'Requester',
    organization.name AS 'Registering Organization',
    -- Categorizing IT status based on the current activity
    CASE
        WHEN (dbo.GetCurrentActivity(Change_Order.change_order_pk)) IN ('Technical Analysis', 'Implementation and Deployment', 'Review Request in CCB Committee', 'Update CMDB', 'Implementation', 'Decision Making in CAB Committee', 'Finalizing Cost and Time Presentation') THEN 'Information Technology'
        ELSE 'Business'
    END AS 'IT Status',
    -- Mapping change order status to Persian descriptions
    CASE
        WHEN Change_Order.status = 0 THEN 'None'
        WHEN Change_Order.status = 1 THEN 'New'
        WHEN Change_Order.status = 2 THEN 'Scheduled'
        WHEN Change_Order.status = 3 THEN 'Assigned'
        WHEN Change_Order.status = 4 THEN 'In Progress'
        WHEN Change_Order.status = 5 THEN 'Completed'
    END AS 'Change Status',
    -- Concatenating related changes in one record
    ISNULL(STUFF((SELECT '-' + CAST(RelatedChanges.RelatedID AS nvarchar(MAX))
                  FROM CHANGE_ORDER CO
                  LEFT JOIN (SELECT
                    C1.change_order_pk,
                    C1.id AS ID,
                    C2.id AS RelatedID 
                    FROM Change_Order C1
                    JOIN Entity_Relation ON C1.change_order_pk = lead_pk
                    JOIN Change_Order C2 ON C2.change_order_pk = Entity_Relation.trail_pk
                    WHERE relation_name = 'DynRelChangeOrderList' AND C1.change_order_pk = Change_Order.change_order_pk) AS
                  RelatedChanges ON CO.change_order_pk = RelatedChanges.change_order_pk
                  FOR XML PATH('')), 1, 1, ''), '') AS 'Related Changes',
    -- Columns related to activities
    Activity.id AS 'Activity ID',
    Activity.description AS 'Activity Type',
    DBO.PersianDate(Activity.actual_start_time) AS 'Activity Start Date',
    DBO.PersianDate(Activity.actual_end_time) AS 'Activity End Date',
    DBO.PersianDate(Activity.Virtual_RelatedReleaseDate) AS 'Estimated Release Date',
    DBO.PersianDate(Activity.Virtual_ChangeDeliveryDate) AS 'Actual Change Delivery Time',
    -- Retrieving responsible users for activity
    (SELECT User_Table.description FROM User_Table WHERE User_Table.user_pk = Activity.Virtual_ResponsibleUser2) AS 'Deployment Manager',
    (SELECT User_Table.description FROM User_Table WHERE User_Table.user_pk = Activity.Virtual_ResponsibleUser) AS 'Change Assessment Responsible',
    Activity.Virtual_PersonHour AS 'Person Hours',
    -- Columns related to tasks from the TaskTemp CTE
    TaskTemp.id AS 'Task ID',
    TaskTemp.description AS 'Task Title',
    TaskTemp.TASKGROUP AS 'Task User Group',
    TaskTemp.TASKUSER AS 'Task User',
    TaskTemp.TASKSTATUS AS 'Task Status',
    DBO.PersianDate(TaskTemp.due_date) AS 'Due Date',
    DBO.PersianDate(TaskTemp.start_date) AS 'Start Date',
    DBO.PersianDate(TaskTemp.end_date) AS 'End Date',
    TaskTemp.Virtual_PersonHour AS 'Task Person Hours',
    TaskTemp.DelayTime AS 'Delay Time (Hours)'
FROM Change_Order 
    -- Joining tables related to Change_Order
    LEFT JOIN Activity ON Activity.change_order_pk = Change_Order.change_order_pk
    LEFT JOIN Activity_Plan ON Change_Order.activity_plan_pk = Activity_Plan.activity_plan_pk
    LEFT JOIN Custom_Entity18 ON Custom_Entity18.custom_entity18_pk = Change_Order.Virtual_ChangeOrderStage
    LEFT JOIN Customer ON Customer.customer_pk = Change_Order.customer_pk
    LEFT JOIN Organization ON Organization.organization_pk = Change_Order.organization_pk
    -- Joining with the TaskTemp CTE based on activity_pk
    FULL JOIN TaskTemp ON Activity.activity_pk = TaskTemp.root_pk
-- Filtering the results based on conditions
WHERE Change_Order.id IS NOT NULL 
    AND Activity.description IN ('Technical Analysis', 'Implementation and Deployment', 'Review Request in CCB Committee', 'Approval by Requester', 'Decision Making in CAB Committee')
