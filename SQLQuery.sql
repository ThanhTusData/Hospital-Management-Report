--Tạo database
CREATE DATABASE Hospital_Management;
--Xem dữ liệu
SELECT * FROM [dbo].[hospitals];
--Lấy ra tên và kiểu dữ liệu của các cột
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'hospitals' AND TABLE_CATALOG = 'Hospital_Management';
--Cleaning data
--Tạo bảng tạm thời để lưu dữ liệu đã làm sạch
SELECT 
    TRIM(Facility_Name) AS Facility_Name,
    TRIM(Facility_City) AS Facility_City,
    TRIM(Facility_State) AS Facility_State,
    TRIM(Facility_Type) AS Facility_Type,
    CASE 
        WHEN Rating_Overall IS NULL OR Rating_Overall < 0 THEN 0
        ELSE Rating_Overall 
    END AS Rating_Overall,
    NULLIF(TRIM(Rating_Mortality), '') AS Rating_Mortality,
    NULLIF(TRIM(Rating_Safety), '') AS Rating_Safety,
    NULLIF(TRIM(Rating_Readmission), '') AS Rating_Readmission,
    NULLIF(TRIM(Rating_Experience), '') AS Rating_Experience,
    NULLIF(TRIM(Rating_Effectiveness), '') AS Rating_Effectiveness,
    NULLIF(TRIM(Rating_Timeliness), '') AS Rating_Timeliness,
    NULLIF(TRIM(Rating_Imaging), '') AS Rating_Imaging,
    CASE 
        WHEN Procedure_Heart_Attack_Cost IS NULL OR Procedure_Heart_Attack_Cost < 0 THEN 0
        ELSE Procedure_Heart_Attack_Cost 
    END AS Procedure_Heart_Attack_Cost,
    NULLIF(TRIM(Procedure_Heart_Attack_Quality), '') AS Procedure_Heart_Attack_Quality,
    NULLIF(TRIM(Procedure_Heart_Attack_Value), '') AS Procedure_Heart_Attack_Value,
    CASE 
        WHEN Procedure_Heart_Failure_Cost IS NULL OR Procedure_Heart_Failure_Cost < 0 THEN 0
        ELSE Procedure_Heart_Failure_Cost 
    END AS Procedure_Heart_Failure_Cost,
    NULLIF(TRIM(Procedure_Heart_Failure_Quality), '') AS Procedure_Heart_Failure_Quality,
    NULLIF(TRIM(Procedure_Heart_Failure_Value), '') AS Procedure_Heart_Failure_Value,
    CASE 
        WHEN Procedure_Pneumonia_Cost IS NULL OR Procedure_Pneumonia_Cost < 0 THEN 0
        ELSE Procedure_Pneumonia_Cost 
    END AS Procedure_Pneumonia_Cost,
    NULLIF(TRIM(Procedure_Pneumonia_Quality), '') AS Procedure_Pneumonia_Quality,
    NULLIF(TRIM(Procedure_Pneumonia_Value), '') AS Procedure_Pneumonia_Value,
    CASE 
        WHEN Procedure_Hip_Knee_Cost IS NULL OR Procedure_Hip_Knee_Cost < 0 THEN 0
        ELSE Procedure_Hip_Knee_Cost 
    END AS Procedure_Hip_Knee_Cost,
    NULLIF(TRIM(Procedure_Hip_Knee_Quality), '') AS Procedure_Hip_Knee_Quality,
    NULLIF(TRIM(Procedure_Hip_Knee_Value), '') AS Procedure_Hip_Knee_Value
INTO 
    Cleaned_Facility_Data
FROM 
    hospitals;

--Sử dụng CTE để xác định và xóa dữ liệu trùng lặp
WITH CTE_Duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY 
               Facility_Name, 
               Facility_City, 
               Facility_State, 
               Facility_Type, 
               Rating_Overall,
               Rating_Mortality,
               Rating_Safety,
               Rating_Readmission,
               Rating_Experience,
               Rating_Effectiveness,
               Rating_Timeliness,
               Rating_Imaging,
               Procedure_Heart_Attack_Cost,
               Procedure_Heart_Attack_Quality,
               Procedure_Heart_Attack_Value,
               Procedure_Heart_Failure_Cost,
               Procedure_Heart_Failure_Quality,
               Procedure_Heart_Failure_Value,
               Procedure_Pneumonia_Cost,
               Procedure_Pneumonia_Quality,
               Procedure_Pneumonia_Value,
               Procedure_Hip_Knee_Cost,
               Procedure_Hip_Knee_Quality,
               Procedure_Hip_Knee_Value
           ORDER BY Facility_Name) AS RowNum
    FROM 
        Cleaned_Facility_Data
)
DELETE FROM CTE_Duplicates
WHERE RowNum > 1;

--Xóa bảng cũ
DROP TABLE IF EXISTS Facility_Data;

--Đổi tên bảng tạm thời thành bảng hiện tại
EXEC sp_rename 'Cleaned_Facility_Data', 'Facility_Data';
--Kiểm tra lại dữ liệu
SELECT * FROM [dbo].[Facility_Data];












--Phân tích các chỉ số chăm sóc sức khỏe tổng thể
SELECT 
    AVG(Rating_Overall) AS Avg_Overall_Rating,
    AVG(CAST(Procedure_Heart_Attack_Cost AS DECIMAL)) AS Avg_Heart_Attack_Cost,
    AVG(CAST(Procedure_Heart_Failure_Cost AS DECIMAL)) AS Avg_Heart_Failure_Cost,
    AVG(CAST(Procedure_Pneumonia_Cost AS DECIMAL)) AS Avg_Pneumonia_Cost,
    AVG(CAST(Procedure_Hip_Knee_Cost AS DECIMAL)) AS Avg_Hip_Knee_Cost
FROM Facility_Data;

--Đánh giá thời gian chờ đợi
SELECT 
    Facility_Name, 
    Facility_City, 
    Facility_State,
    Rating_Timeliness
FROM 
    Facility_Data
WHERE 
    Rating_Timeliness = 'Below';


--Phân tích chi phí điều trị
SELECT 
    Facility_Name, 
    Facility_City, 
    Facility_State,
    Procedure_Heart_Attack_Cost,
    Procedure_Heart_Failure_Cost,
    Procedure_Pneumonia_Cost,
    Procedure_Hip_Knee_Cost
FROM 
    Facility_Data
ORDER BY 
    Procedure_Hip_Knee_Cost DESC;  -- Xem các cơ sở có chi phí phẫu thuật hông và gối cao nhất

--Phân tích chất lượng chăm sóc
SELECT 
    Facility_Name, 
    Facility_City, 
    Facility_State,
    Procedure_Hip_Knee_Quality
FROM 
    Facility_Data
WHERE 
    Procedure_Hip_Knee_Quality = 'Worse'

--Tối ưu hóa phân bổ tài nguyên dựa trên số liệu về chi phí và chất lượng
SELECT 
    Facility_Name, 
    Facility_City, 
    Facility_State,
    Procedure_Hip_Knee_Cost,
    Procedure_Hip_Knee_Quality
FROM 
    Facility_Data
WHERE 
    Procedure_Hip_Knee_Cost < (SELECT AVG(Procedure_Hip_Knee_Cost) FROM Facility_Data) 
    AND Procedure_Hip_Knee_Quality = 'Worse'  -- Chất lượng kém với chi phí thấp
ORDER BY 
    Procedure_Hip_Knee_Cost ASC;

