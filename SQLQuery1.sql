/*

Banking Customer Churn Analysis

1) The dataset used for this project was found in Kaggle: https://www.kaggle.com/datasets/radheshyamkollipara/bank-customer-churn

2) I imported the data into the SQL Server on my desktop

3) I created a new view which contains a filtered version of the dataset and new added columns.

4) I established a connection with my Database and Power BI.

5) I visualized the data in Power BI.


*/


create or alter view churn_view AS
SELECT CustomerId, Surname, CreditScore, Geography,	Gender,	Age, Tenure, Balance, NumOfProducts, HasCrCard,	IsActiveMember,	
EstimatedSalary, Exited, Complain as Complain_Flag, "Satisfaction Score" as Satisfaction_Score ,"Card Type" as Card_Type,

	--Add Age Group Column
	CASE 
			WHEN Age <= 25 THEN '18-25'
			WHEN Age <= 35 THEN '26-35'
			WHEN Age <= 45 THEN '36-45'
			WHEN Age <= 55 THEN '46-55'
			WHEN Age <= 65 THEN '56-65'
			ELSE '66+'
	END AS Age_Group,

	--Add Tenure Classification
	CASE 
        WHEN Tenure <= 2 THEN 'New Customer'
        WHEN Tenure <= 6 THEN 'Intermediate Customer'
        ELSE 'Long-term customers'
	END AS Tenure_Classification,

	--Add Balance Category
	CASE
	    WHEN cast(Balance as Float) = 0 THEN '0'
        WHEN cast(Balance as Float) <= 10000 THEN 'Low'
		WHEN cast(Balance as Float) <= 50000 THEN 'Medium'
        ELSE 'High'
	END AS Balance_Category,

	--Add Credit Score Category
	CASE
	    WHEN CreditScore BETWEEN 300 AND 579 Then 'Poor' 
        WHEN CreditScore BETWEEN 580 AND 669 Then 'Fair' 
		WHEN CreditScore BETWEEN 670 AND 739 Then 'Good' 
		WHEN CreditScore BETWEEN 740 AND 799 Then 'Very Good' 
		WHEN CreditScore BETWEEN 800 AND 850 Then 'Excellent' 
        ELSE 'Invalid Credit Score'
	END AS CreditScore_Category,
	
	--Add Satisfaction Weighted Tenure Column 
	Round(Tenure * ("Satisfaction Score" / 5.0), 2) AS Satisfaction_Weighted_Tenure,


	--Add Debt to Income Ratio Column
	Round(CAST(Balance as FLOAT) / CAST(EstimatedSalary as FLOAT),2) as Debt_Income_Ratio,
	
	--Add Loyalty Indicator Column
	CASE 
        WHEN Tenure > 6 AND "Satisfaction Score" > 4 THEN 1
		ELSE 0
    END AS Loyalty_Indicator,

   --Add Customer Value Column
	CAST(Balance as FLOAT) * 0.1 AS Customer_Annual_Value,

	--Add Active Member with Credit Card Flag
	CASE 
        WHEN IsActiveMember = 1 AND HasCrCard = 1 THEN 1
		ELSE 0
    END AS Active_Member_Credit_Card,

	-- Churn Risk KPI (to Fix)
    CASE
        WHEN Exited = 1 THEN 'Churned'
        ELSE
            CASE
                -- High Risk
                WHEN (Tenure < 2 AND IsActiveMember = 0 AND Complain = 1) OR 
                     ("Satisfaction Score" < 3) THEN 'High Risk'
               
                -- Medium Risk
                WHEN (Tenure BETWEEN 2 AND 5 AND IsActiveMember = 0) OR
                     ("Satisfaction Score" BETWEEN 3 AND 4 AND Complain = 1) THEN 'Medium Risk'
                
                -- Low Risk
                ELSE 'Low Risk'
            END
    END AS Churn_Risk_Level



FROM tbl_customer_churn;

select * from churn_view

select NumOfProducts
from churn_view 