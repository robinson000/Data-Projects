/*

Banking Customer Churn Analysis.

1) The dataset used for this project was found in Kaggle: https://www.kaggle.com/datasets/radheshyamkollipara/bank-customer-churn.

2) I imported the data into SQL Server on my desktop.

3) I created a new view with filtered data and added KPI columns.

4) I connected my database to Power BI.

5) I visualized the data in Power BI.

*/

-- Create or alter new SQL view.
create or alter view churn_view AS
SELECT CustomerId, Surname, CreditScore, Geography,	Gender,	Age, Tenure, Balance, NumOfProducts, HasCrCard,	IsActiveMember,	
EstimatedSalary, Exited, Complain as Complain_Flag, "Satisfaction Score","Card Type" as Card_Type,

-- Add Retention Status.
	CASE 
        WHEN Exited = '0' THEN 'Retained'
        WHEN Exited = '1' THEN 'Churned'
        ELSE NULL
	END AS Retention_Status,

	-- Add Age Group Column.
	CASE 
			WHEN Age <= 25 THEN '18-25'
			WHEN Age <= 35 THEN '26-35'
			WHEN Age <= 45 THEN '36-45'
			WHEN Age <= 55 THEN '46-55'
			WHEN Age <= 65 THEN '56-65'
			ELSE '66+'
	END AS Age_Group,

	-- Add Tenure Classification.
	CASE 
        WHEN Tenure <= 2 THEN 'New Customer'
        WHEN Tenure <= 6 THEN 'Established Customer'
        ELSE 'Long-term customer'
	END AS Tenure_Classification,


	-- Add Balance Category on the same scale as the Salary Category to enable visual comparison.
	CASE
	    WHEN Balance IS NULL THEN 'Unknown'
		WHEN cast(Balance as Float) = 0 THEN '$0'
		WHEN cast(Balance as Float) > 0 AND cast(Balance as Float) <= 30000 THEN 'Under $30k'
		WHEN cast(Balance as Float) > 30000 AND cast(Balance as Float) <= 60000 THEN '$30k - $60k'
		WHEN cast(Balance as Float) > 60000 AND cast(Balance as Float) <= 90000 THEN '$60k - $90k'
		WHEN cast(Balance as Float) > 90000 AND cast(Balance as Float) <= 120000 THEN '$90k - $120k'
		ELSE 'Over $120k'
	END AS Balance_Category,

	-- Add a Balance Rank column to facilitate sorting of Balance_Category text values.
	CASE
	    WHEN Balance IS NULL THEN 'Unknown'
		WHEN cast(Balance as Float) = 0 THEN 1
		WHEN cast(Balance as Float) > 0 AND cast(Balance as Float) <= 30000 THEN 2
		WHEN cast(Balance as Float) > 30000 AND cast(Balance as Float) <= 60000 THEN 3
		WHEN cast(Balance as Float) > 60000 AND cast(Balance as Float) <= 90000 THEN 4
		WHEN cast(Balance as Float) > 90000 AND cast(Balance as Float) <= 120000 THEN 5
		ELSE 6
	END AS Balance_Rank,

	-- Add Salary Category on the same scale as the Balance Category to enable visual comparison.
	CASE
		WHEN EstimatedSalary IS NULL THEN 'Unknown'
		WHEN cast(EstimatedSalary as Float) <= 0 THEN '$0'
		WHEN cast(EstimatedSalary as Float) > 0 AND cast(EstimatedSalary as Float) <= 30000 THEN 'Under $30k'
		WHEN cast(EstimatedSalary as Float) > 30000 AND cast(EstimatedSalary as Float) <= 60000 THEN '$30k - $60k'
		WHEN cast(EstimatedSalary as Float) > 60000 AND cast(EstimatedSalary as Float) <= 90000 THEN '$60k - $90k'
		WHEN cast(EstimatedSalary as Float) > 90000 AND cast(EstimatedSalary as Float) <= 120000 THEN '$90k - $120k'
		ELSE 'Over $120k'
	END AS Salary_Category,

	-- Add a Salary Rank column to facilitate sorting of Balance_Category text values.
	CASE
        WHEN EstimatedSalary IS NULL THEN 0
		WHEN cast(EstimatedSalary as Float) = 0 THEN 1
		WHEN cast(EstimatedSalary as Float) > 0 AND cast(EstimatedSalary as Float) <= 30000 THEN 2
		WHEN cast(EstimatedSalary as Float) > 30000 AND cast(EstimatedSalary as Float) <= 60000 THEN 3
		WHEN cast(EstimatedSalary as Float) > 60000 AND cast(EstimatedSalary as Float) <= 90000 THEN 4
		WHEN cast(EstimatedSalary as Float) > 90000 AND cast(EstimatedSalary as Float) <= 120000 THEN 5
		ELSE 6
    END AS Salary_Rank,

	-- Add a Salary Rank column to facilitate sorting of Balance_Category text values.
	CASE
        WHEN NumOfProducts IS NULL THEN NULL
		WHEN NumOfProducts = 1 THEN 0
		WHEN NumOfProducts > 1 THEN 1
		ELSE NULL
    END AS Multiple_Products_IND,

	-- Add Credit Score Category.
	CASE
	    WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor' 
        WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair' 
		WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good' 
		WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good' 
		WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent' 
        ELSE 'Invalid Credit Score'
	END AS CreditScore_Category,

	-- Add Credit Score Rank.
	CASE
	    WHEN CreditScore BETWEEN 300 AND 579 THEN 1 
        WHEN CreditScore BETWEEN 580 AND 669 THEN 2 
		WHEN CreditScore BETWEEN 670 AND 739 THEN 3 
		WHEN CreditScore BETWEEN 740 AND 799 THEN 4
		WHEN CreditScore BETWEEN 800 AND 850 THEN 5
        ELSE 'Invalid Credit Score'
	END AS CreditScore_Category_Rank,

	-- Modify Satisfaction Score values
	CASE
	    WHEN "Satisfaction Score" = '1' Then 'Very Dissatisfied'
        WHEN "Satisfaction Score" = '2' Then 'Dissatisfied'
		WHEN "Satisfaction Score" = '3' Then 'Neutral'
		WHEN "Satisfaction Score" = '4' Then 'Satisfied'
		WHEN "Satisfaction Score" = '5' Then 'Very Satisfied'
        ELSE 'Invalid Satisfaction Score'
	END AS Satisfaction_Score,
	
	-- Add Satisfaction Weighted Tenure Column. Calculate new metric that adjusts the Tenure of an customer based on their Satisfaction Score.
	Round(Tenure * ("Satisfaction Score" / 5.0), 2) AS Satisfaction_Weighted_Tenure,

	-- Add Debt to Income Ratio Column.
	Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) as Debt_Income_Ratio,

	-- Add Debt to Income Ratio Categories
	CASE
		WHEN EstimatedSalary IS NULL THEN 'Unknown'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 0.25 THEN '0% - 25%'        
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 0.5 THEN '25% - 50%'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 1 THEN '50% - 100%'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 3 THEN '100% - 300%'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 5 THEN '300% - 500%'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 10 THEN '500% - 1,000%'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 15 THEN '1,000% - 5,000%'
		ELSE 'Over 5,000%'
	END AS DTI_Category,

	-- Add Debt to Income Ratio Rank
	CASE
		WHEN EstimatedSalary IS NULL THEN 'Unknown'
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 0.25 THEN 1        
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 0.5 THEN 2
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 1 THEN 3
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 3 THEN 4
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 5 THEN 5
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 10 THEN 6
		WHEN Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) <= 15 THEN 7
		ELSE 8
	END AS DTI_Category_Rank,
	
	-- Add Loyalty Indicator Column. Determine loyalty status for customers with a tenure greater than 6 years and a high satisfaction score.
	CASE 
        WHEN Tenure > 6 AND "Satisfaction Score" > 4 THEN 1
		ELSE 0
    END AS Loyalty_Indicator,

   -- Add Customer Value Column. Calculate hypothetical annual revenue from debt assuming an interest rate of 10% if debt balance generates a 10% annual interest for the bank.
	CAST(Balance as FLOAT) * 0.1 AS Customer_Annual_Value,

	-- Add Activity Status Column.
	CASE 
        WHEN IsActiveMember = 1 THEN 'Active Member'
		WHEN IsActiveMember = 0 THEN 'Inactive  Member'
    END AS Activity_Status,

	-- Add Compliant Status Column.
	CASE 
        WHEN Complain = 1 THEN 'Complaint Submitted'
		WHEN IsActiveMember = 0 THEN 'No Complaint'
    END AS Complaint_Status,

	-- Add Churn Risk KPI 
    CASE
        WHEN Exited = 1 THEN 'Churned'
        ELSE
            CASE
                -- High Risk: Characterized by low tenure, inactivity, a history of complaints, and a low satisfaction score.
                WHEN (Tenure < 2 AND IsActiveMember = 0 AND Complain = 1) OR 
                     ("Satisfaction Score" < 3) THEN 'High Risk'
               
                -- Medium Risk: Defined by medium tenure, inactivity, a history of complaints, and a moderate satisfaction score.
                WHEN (Tenure BETWEEN 2 AND 5 AND IsActiveMember = 0) OR
                     ("Satisfaction Score" BETWEEN 3 AND 4 AND Complain = 1) THEN 'Medium Risk'
                
                -- Low Risk: all other scenarios.
                ELSE 'Low Risk'
            END
    END AS Churn_Risk_Level

FROM tbl_customer_churn;



select * from churn_view

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'churn_view';