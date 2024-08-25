/*

Banking Customer Churn Analysis.

1) The dataset used for this project was found in Kaggle: https://www.kaggle.com/datasets/radheshyamkollipara/bank-customer-churn.

2) I imported the data into SQL Server on my desktop.

3) I created a new view with filtered data and added KPI columns.

4) I connected my database to Power BI.

5) I visualized the data in Power BI.

*/

-- Create new SQL view.
create or alter view churn_view AS
SELECT CustomerId, Surname, CreditScore, Geography,	Gender,	Age, Tenure, Balance, NumOfProducts, HasCrCard,	IsActiveMember,	
EstimatedSalary, Exited, Complain as Complain_Flag, "Satisfaction Score","Card Type" as Card_Type,

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
        WHEN Tenure <= 6 THEN 'Intermediate Customer'
        ELSE 'Long-term customers'
	END AS Tenure_Classification,

	-- Add Balance Category.
	CASE
	    WHEN cast(Balance as Float) <= 0 THEN '0'
        WHEN cast(Balance as Float) <= 10000 THEN 'Under 10k'
		WHEN cast(Balance as Float) <= 50000 THEN '10k - 50k'
		WHEN cast(Balance as Float) <= 100000 THEN '50k - 100k'
        ELSE 'Over 100k'
	END AS Balance_Category,
	CASE
	    WHEN cast(Balance as Float) <= 0 THEN 1
        WHEN cast(Balance as Float) <= 10000 THEN 2
		WHEN cast(Balance as Float) <= 50000 THEN 3
		WHEN cast(Balance as Float) <= 100000 THEN 4
        ELSE 5
	END AS Balance_Rank,

	-- Add Salary Category.
	CASE
        WHEN cast(EstimatedSalary as Float) <= 30000 THEN 'Under 30k'
		WHEN cast(EstimatedSalary as Float) <= 60000 THEN '30k - 60k'
		WHEN cast(EstimatedSalary as Float) <= 90000 THEN '60k - 90k'
		WHEN cast(EstimatedSalary as Float) <= 120000 THEN '90k - 120k'
        ELSE 'Over 120k'
	END AS Salary_Category,
	CASE
        WHEN CAST(EstimatedSalary AS FLOAT) <= 30000 THEN 1
        WHEN CAST(EstimatedSalary AS FLOAT) <= 60000 THEN 2
        WHEN CAST(EstimatedSalary AS FLOAT) <= 90000 THEN 3
        WHEN CAST(EstimatedSalary AS FLOAT) <= 120000 THEN 4
        ELSE 5
    END AS Salary_Rank,

	-- Add Credit Score Category.
	CASE
	    WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor' 
        WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair' 
		WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good' 
		WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good' 
		WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent' 
        ELSE 'Invalid Credit Score'
	END AS CreditScore_Category,

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
	
	-- Add Loyalty Indicator Column. Determine loyalty status for customers with a tenure greater than 6 years and a high satisfaction score.
	CASE 
        WHEN Tenure > 6 AND "Satisfaction Score" > 4 THEN 1
		ELSE 0
    END AS Loyalty_Indicator,

   -- Add Customer Value Column. Calculate hypothetical annual revenue from debt assuming an interest rate of 10% if debt balance generates a 10% annual interest for the bank.
	CAST(Balance as FLOAT) * 0.1 AS Customer_Annual_Value,

	-- Add Active Member with Credit Card Flag.
	CASE 
        WHEN IsActiveMember = 1 AND HasCrCard = 1 THEN 1
		ELSE 0
    END AS Active_Member_Credit_Card,

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


select EstimatedSalary from tbl_customer_churn order by EstimatedSalary