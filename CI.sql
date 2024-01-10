-- This script retrieves information about cases and CIs for reporting purposes.

-- Selecting columns from Configuration_Item (CI) table
SELECT 
    CI.id AS N'شناسه قلم', -- CI ID
    CI.description AS N'عنوان قلم', -- CI Title
    CITP.description AS N'گروه قلم', -- Parent CI Group
    CIT.description AS N'نوع قلم', -- CI Type
    Item.description AS N'مدل قلم', -- CI Model
    CI.Virtual_IPAddresses AS N'آدرس IP', -- Virtual IP Address
    CASE
        WHEN CI.Virtual_DataSource = 0 THEN 'V-CENTER'
        WHEN CI.Virtual_DataSource = 1 THEN 'SOLARWINDS'
        WHEN CI.Virtual_DataSource = 2 THEN 'CISCO-PRIME'
        ELSE 'NO-SOURCE'
    END AS N'روش شناسایی', -- Virtual Data Source Identification Method
    (SELECT DBO.PersianDate(create_datetime) FROM History WHERE description = N'قلم پیکربندی ایجاد شد' AND History.root_pk = CI.ci_pk) AS N'تاریخ ایجاد', -- Creation Date (Persian)
    DBO.PersianDate(CI.calibration_date) AS N'تاریخ بروز رسانی', -- Calibration Date (Persian)
    CASE
        WHEN CI.operation_status = 0 THEN N'ناشناخته'
        WHEN CI.operation_status = 1 THEN N'عادی'
        WHEN CI.operation_status = 2 THEN N'اخطار'
        WHEN CI.operation_status = 3 THEN N'حیاتی'
    END AS N'وضعیت عملیاتی', -- Operational Status
    CI.optional_number AS N'آدرس MAC', -- MAC Address
    CASE
        WHEN CI.status = 0 THEN N'از رده خارج'
        WHEN CI.status = 3 THEN N'در انتظار بررسی'
        WHEN CI.status = 4 THEN N'عملیاتی'
    END AS N'وضعیت', -- Status
    Case_Table.id N'شناسه مورد', -- Case ID
    Case_Type.description N'نوع مورد', -- Case Type
    C1.description AS N'محصول', -- Product
    C2.description AS N'سرویس', -- Service
    CASE
        WHEN case_table.case_status = 0 THEN N'ایجاد شده'
        WHEN case_table.case_status = 1 THEN N'در جریان'
        WHEN case_table.case_status = 2 THEN N'حل شده'
        WHEN case_table.case_status = 3 THEN N'خاتمه یافته'
    END AS 'وضعیت مورد', -- Case Status
    COUNT(Case_CI.ci_pk) OVER (PARTITION BY Case_CI.case_pk) -- This window function retrieves the count of each CI attached to a case
FROM Configuration_Item CI 	
    LEFT JOIN Case_CI ON
        Case_CI.ci_pk = CI.ci_pk
    LEFT JOIN Case_Table ON
        Case_CI.case_pk = Case_Table.case_pk
    LEFT JOIN Configuration_Item AS C1 ON
        Case_Table.ci_pk = C1.ci_pk
    LEFT JOIN Configuration_Item AS C2 ON
        Case_Table.ci2_pk = C2.ci_pk
    LEFT JOIN Case_Type ON
        Case_Table.case_type_pk = Case_Type.case_type_pk
    LEFT JOIN Configuration_Item_Type CIT ON
        CI.ci_type_pk = CIT.ci_type_pk
    LEFT JOIN Configuration_Item_Type CITP ON
        CITP.ci_type_pk = CIT.parent_ci_type_pk
    LEFT JOIN Item ON
        CI.item_pk = Item.item_pk
WHERE 
    CI.ci_type_pk NOT IN (83497927,83501456,83517507,83513546)
