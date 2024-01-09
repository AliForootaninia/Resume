-- This script calculates and analyzes various metrics related to case handling, including OLA and SLA compliance.
-- It retrieves information about cases, users, groups, and time elapsed for reporting purposes.

;WITH
	ELAPS --Calculate the Time spent by the current user group to pick the ticket and send it to the next team
		AS
			(SELECT
				Custom_Entity09.Virtual_ResponsibleGroup,
				Custom_Entity09.Virtual_Case,
				SUM(CASE WHEN Custom_Entity09.Virtual_OlaLogType = 0 THEN Custom_Entity09.Virtual_ElapsedMinutes ELSE 0 END) 
				- SUM(CASE WHEN Custom_Entity09.Virtual_OlaLogType = 1 THEN Custom_Entity09.Virtual_ElapsedMinutes ELSE 0 END) 
				AS Custom_Entity09_Virtual_ElapsedMinutes_Result
			FROM Custom_Entity09
			GROUP BY Custom_Entity09.Virtual_ResponsibleGroup, Custom_Entity09.Virtual_Case
			HAVING SUM(CASE WHEN Custom_Entity09.Virtual_OlaLogType = 0 THEN Custom_Entity09.Virtual_ElapsedMinutes ELSE 0 END) 
				- SUM(CASE WHEN Custom_Entity09.Virtual_OlaLogType = 1 THEN Custom_Entity09.Virtual_ElapsedMinutes ELSE 0 END) > 0
			),
	ResponsibleELAPSE --Find the user who was responsible for the ticket
		AS
			(SELECT
				SUM(Custom_Entity08.Virtual_ElapsedMinutes) AS SUMELAPSEMINUTE,
				Custom_Entity08.Virtual_Case,
				Custom_Entity08.Virtual_ResponsibleGroup,
				User_Table.description AS Responsible
			FROM Custom_Entity08 LEFT JOIN User_Table ON Custom_Entity08.Virtual_Responsible = User_Table.user_pk
			GROUP BY
					Custom_Entity08.Virtual_Case, Custom_Entity08.Virtual_ResponsibleGroup, User_Table.description
			)
SELECT 
		Case_Table.id 'Case ID',
		Case_Type.description 'Case Type',
		Case_Table.description 'Title',
		Custom_Entity09.Virtual_StartDateTime AS N'Log Start Date and Time',
		Custom_Entity09.Virtual_EndDateTime AS N'Log End Date and Time',
		Case_Table.opened_date AS N'Case Open Date',
		Case_Category.description N'Case Category',
		Customer.description 'Customer',
		Organization.description 'Customer Organization',
		User_Group.description 'User Group(for each log)',
		ResponsibleELAPSE.Responsible 'Username',
		ResponsibleELAPSE.SUMELAPSEMINUTE 'Elapse Time',
		User_Group.Virtual_ITDepartment 'IT or Non IT',
		CASE 
			WHEN Priority.escalation_solve_units = 1  THEN Priority.escalation_solved * 60 
			WHEN Priority.escalation_solve_units = 2  THEN (Priority.escalation_solved * 24) * 60
			ELSE Priority.escalation_solved 
		END AS 'OLA Spent(Min)', --Calculate the OLA time in minute, depends on the escalation_solve_units field value
		Priority.escalation_solved AS 'Default OLA',
		P2.DESCRIPTION AS 'Default SLA',
		CASE
		WHEN ELAPS.Custom_Entity09_Virtual_ElapsedMinutes_Result IS NULL THEN 0
		ELSE ELAPS.Custom_Entity09_Virtual_ElapsedMinutes_Result 
		END AS 'Time Spent by each Group',
		Closure_Code.description AS 'Resolution',
		C1.description AS 'Product',
	    C2.description AS 'Service',
		CASE
			WHEN Case_Table.time_limit_exceeded IN (5,6) THEN 'SLA Breached'
			ELSE ''
		END AS 'SLA State',
		CASE
			WHEN Operation_Level_Agreement.Virtual_RelatedUserGroup IS NULL AND Case_Table.case_type_pk IN (83470347,91252218,91389913,89893423) THEN 'Out of Process'
			ELSE N'IN Process'
		END AS 'OLA Type',
		Service_Hours.description AS 'Service Hour',
		CASE
		WHEN Case_Table.case_type_pk IN (83470347,91252218,91389913,89893423) THEN (Priority.escalation_solved * 60) - ROUND((ELAPS.Custom_Entity09_Virtual_ElapsedMinutes_Result),2,1)
		WHEN Case_Table.case_type_pk IN (823571,83503108,91573786) THEN (Priority.escalation_solved) - ROUND((ELAPS.Custom_Entity09_Virtual_ElapsedMinutes_Result),2,1)
		WHEN ROUND((ELAPS.Custom_Entity09_Virtual_ElapsedMinutes_Result),2,1) IS NULL THEN 0
		END	AS 'OLA Breached',
		CASE
			WHEN case_table.case_status = 0 THEN 'New'
			WHEN case_table.case_status = 1 THEN 'In Progress'
			WHEN case_table.case_status = 2 THEN 'Solved'
			WHEN case_table.case_status = 3 THEN 'Closed'
		End AS 'Case status',
		dbo.GetCaseReopenCount(case_pk) As 'Reopen Count' --This function counts the tickets which are reopened by the customer or service desk team
FROM Custom_Entity09 
		FULL JOIN Case_Table ON	Case_Table.case_pk = Custom_Entity09.Virtual_Case
		LEFT JOIN User_Table ON	Custom_Entity09.Virtual_ResponsibleGroup = User_Table.user_pk
		LEFT JOIN User_Group ON	Custom_Entity09.Virtual_ResponsibleGroup = User_Group.user_group_pk
		LEFT JOIN Case_Category ON Case_Table.case_category_pk = Case_Category.case_category_pk
		LEFT JOIN Priority ON Custom_Entity09.Virtual_Priority = Priority.priority_pk
		LEFT JOIN Operation_Level_Agreement ON Operation_Level_Agreement.ola_pk = Custom_Entity09.Virtual_OperationLevelAgreement
		LEFT JOIN Case_Type ON Case_Type.case_type_pk = Case_Table.case_type_pk
		LEFT JOIN Closure_Code ON Case_Table.closure_code_pk = Closure_Code.closure_code_pk
		LEFT JOIN Configuration_Item AS C1 ON Case_Table.ci_pk = C1.ci_pk
		LEFT JOIN Configuration_Item AS C2 ON Case_Table.ci2_pk = C2.ci_pk
		LEFT JOIN PRIORITY P2 ON CASE_TABLE.priority_pk = P2.priority_pk	
		LEFT JOIN Customer ON Customer.customer_pk = Case_Table.customer_pk
		LEFT JOIN Organization ON Organization.organization_pk = Case_Table.organization_pk
		LEFT JOIN Service_Hours ON Custom_Entity09.Virtual_ServiceHours = Service_Hours.service_hours_pk
		LEFT JOIN ELAPS ON Custom_Entity09.Virtual_Case = ELAPS.Virtual_Case AND ELAPS.Virtual_ResponsibleGroup = Custom_Entity09.Virtual_ResponsibleGroup
		LEFT JOIN ResponsibleELAPSE ON ResponsibleELAPSE.Virtual_Case = Custom_Entity09.Virtual_Case AND ResponsibleELAPSE.Virtual_ResponsibleGroup = Custom_Entity09.Virtual_ResponsibleGroup
ORDER BY Case_Table.opened_date, Custom_Entity09.Virtual_StartDateTime
