
/*
Store Background

# A retail store chain tracks daily sales transactions, including order details, customer info, product categories, order time,
and order status.

# The business wants to optimize operations, improve customer experiance, and increase profitability using data-driven decisions.


-- Problem Statement
-- Problem

# The store doesnt have cleare idea about which 'product sell the most'
# Customers preference
# Which items bring most profit and where things are going wrong in delivery or operations.

-- Solution

# They need proper reports and simple insights to understand their sales, customers, and product performance better.
# because of this, they are missing chances to earn more, losing customers, and making poor business decisions.

-- Why it need to be solved

Without proper insights:

# Missing sales opportunites
# Poor inventory and staffing decisions 
# Incresed operational costs
# Low customer satisfaction
# Inaccurate business forecasts

Solving this will help increase revenue, improve service quality, optimize operations.



-- Stakeholders

Stakeholders are the people or team who are directly affected by business decisions and use sales insights to improve their
work and the company's performance.


Store Manager --> To improve daily operations and sales performance
     |
Inventory Team--> To plan stock and refilling based on demand
     |
Marketing Team--> To target promotions and loyalty programs
     |
Logistic Team--> To address delivery delays and optimize routes
     |
Finance Team--> For profit analysis and revenue forcasting
     |
Senior Management--> To set business strategy and growth plans



-- Business Problems

1. What are the top 5 most selling products by quantity?
2. which products are most frequently canceled?
3. What time of the day has highest number of purchase happened?
4. who are the top 5 highest spending customers?
5. which product categories generates the highest revenue?
6. What is the return/cancellation rate per product category?
7. What is the most preferred payment mode?
8. How does age group affect purchasing behavior?
9. Whats the monthly sales trend?
10. Are certain genders buying more specific product categories?

*/

-- Create the database

create Database Sales_Store

use sales_store

-- Create Table

create table Sales
(transaction_ID varchar(15), Customer_ID varchar(15),
Customer_Name varchar(30), Customer_Age int,
Gender Varchar(15), Product_ID varchar(15),
Product_Name varchar(15), Product_Category varchar(15),
Quantiy Int, Prce Float, Payment_Mode varchar(15),
Purchase_Date date, Time_of_Purchase time, status varchar(15))

select * from Sales

-- insert the data into the table using (bulk Insert method)

set dateformat DMY
Bulk insert sales 
from 'C:\Users\mdadi\Downloads\Business Analyst Projects\sales_store.csv'
       with (
	       Firstrow=2, 
		   Fieldterminator=',',
		   Rowterminator='\n'
		   )


-- Note: Here purchase_date error is coming because the excel file is date month year(dd-mm-yyyy) is there, but
-- SQL server support (yyyy-mm-dd)

select * from Sales

-- Data Cleaning

-- Step 1: To check the duplicate records

select transaction_ID, 
       COUNT(*) as 'noforecrds'
from Sales
group by transaction_ID
having COUNT(transaction_ID)>1

TXN240646
TXN342128
TXN855235
TXN981773

-- second method to check duplicate records

With Duplicate as (
select *,
         ROW_NUMBER() over (partition by transaction_id order by transaction_id) as 'Row_Num'
from Sales
)
select * from Duplicate
where Row_Num > 1

-- Is it really duplicate or just on the basis of transaction_id it just showing the duplicate, one more step to verify

With Duplicate as (
select *,
         ROW_NUMBER() over (partition by transaction_id order by transaction_id) as 'Row_Num'
from Sales
)
select * from Duplicate
where transaction_ID in ('TXN240646', 'TXN342128', 'TXN855235' ,'TXN981773')

-- Here First one is orignal and second one is duplicate

-- lets delete the 2 number records

With Duplicate as (
select *,
         ROW_NUMBER() over (partition by transaction_id order by transaction_id) as 'Row_Num'
from Sales
)
delete from Duplicate
where Row_Num=2


-- Step 2: Correct the headers spelling

exec sp_rename'sales.quantiy','quantity','column'

exec sp_rename'sales.prce','price','column'

select * from Sales

-- Step 3: check the data type

select COLUMN_NAME,  data_type 
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='sales'

-- Step 4: Check the null values

select * from Sales
where transaction_ID is null
      or 
      Customer_ID is null
	  or
	  Customer_Age is null
	  or 
	  Gender is null
	  or 
	  Product_ID is null
	  or 
	  Product_Name is null
	  or 
	  Product_Category is null
	  or
	  quantity is null
	  or
	  price is null
	  or
	  Payment_Mode is null
	  or
	  Time_of_Purchase is null
	  or
	  status is null

-- Delete the outlier

delete from Sales
where transaction_ID is null

-- treating null values -- means wherever is null values and their if data is availabe just updatig that.

--1.
select * from Sales
where Customer_Name='Ehsaan Ram'

update Sales set Customer_ID ='Cust9494'
where transaction_id='TXN977900'

--2.
select * from Sales
where Customer_Name='Damini Raju'

update Sales set Customer_ID='CUST1401'
where transaction_ID='TXN985663'

--3.
select * from Sales
where Customer_ID='CUST1003'

update Sales set Customer_Name='Mahika Saini', Customer_Age=35, Gender='Male'
where Customer_ID='CUST1003'


-- now there is no any null values in the table

select * from Sales

-- Data cleaning 
-- Data cleaning for gender and payment mode

-- Clean the gender column data

select distinct Gender,COUNT(*) from Sales
group by Gender

update Sales set Gender='Male'
where Gender='M'

update Sales set Gender='Female'
where Gender='F'

-- Clean the payment mode column data.

select distinct Payment_Mode,
       COUNT(*)
from Sales
group by Payment_Mode

-- CC convert into the credit card

update Sales set Payment_Mode='Credit Card'
where Payment_Mode='CC'




-- Data Analysis

-- 1. What are the top 5 most selling products by quantity?

select top 5 Product_Name, 
             SUM(quantity) as 'Totalqty'
from Sales
where status='delivered'
group by Product_Name
order by Totalqty desc

-- Business problem we dont know which product is in more demand. 
-- this problem we have solved with above query

-- Business Impact: It helps prioritize stock and boost sales through targeted promotions.


-- 2. which products are most Frequently canceled?

select top 5 Product_Name,
             product_category,
             COUNT(*) as 'total_cancelled'
from Sales
where status='Cancelled'
group by Product_Name,
         Product_Category
order by total_cancelled desc

-- Business Problem: frequantly cancellations affect revenue and customer trust.
-- Business Impact: Identify poor-performing products to improve the quality or discountinue the catalog.

-- 3. What time of the day has highest number of purchase happened?

select 
	   case 
	        when DATEPART(hour,time_of_purchase) between 0 and 5 then 'Night'
			when DATEPART(hour,time_of_purchase) between 6 and 11 then 'Morning'
			when DATEPART(hour,time_of_purchase) between 12 and 17 then 'Afternoor'
			when DATEPART(hour,time_of_purchase) between 18 and 23 then 'Evening'
       end as 'Purchase_happened',
	   COUNT(*) as 'total_orders'
from Sales
group by
		 case 
	        when DATEPART(hour,time_of_purchase) between 0 and 5 then 'Night'
			when DATEPART(hour,time_of_purchase) between 6 and 11 then 'Morning'
			when DATEPART(hour,time_of_purchase) between 12 and 17 then 'Afternoor'
			when DATEPART(hour,time_of_purchase) between 18 and 23 then 'Evening'
       end
order by total_orders desc

-- Business Problem: Find the peak sales time.
-- Business Impact: Optimize staffing, maintaining stock of the salable products, promotions, and server loads.

-- 4. who are the top 5 highest spending customers?

select top 5 Customer_Name,
            FORMAT(SUM(price*quantity),'C0','en-IN') as 'total_Spend'
from Sales
group by Customer_Name
order by sum(quantity*price) desc

-- N - stands for number format
-- 0 - menas no decimal space
-- C - $ sign
-- en-IN - rupees sign


-- Business Problem: Identify VIP customers
-- Business Impact: Personalized offers, loyalty rewards, and retention.


-- 5. which product categories generates the highest revenue?

select Product_Category,
       format(sum(quantity*price),'C0','en-IN') as 'Total_revenue'
from Sales
group by Product_Category
order by sum(quantity*price) desc

-- Busines Problem solved: Identify top performing categories.
-- Business impact: refine product strategy, supply chain, and promotions. allowing business to invest more in high-margin
-- or high demand categories.

-- 6. What is the return/cancellation rate per product category?
-- Cancelled
select Product_Category,
       format(count(case when status='Cancelled' then 1 end)*100.0/count(*),'n3')+' %' as 'Cancelled_%'
from Sales
group by Product_Category
order by [Cancelled_%] desc
	
-- Return

select Product_Category,
       format(count(case when status='Returned' then 1 end)*100.0/count(*),'n3')+' %' as 'Cancelled_%'
from Sales
group by Product_Category
order by [Cancelled_%] desc

-- Business problem solved: Monitor dissatisfaction trends per category. how much return and cancelled happened
-- Busines Impact: Reduce returns, improve product descriptions/expectations. help identify and fix product or logistics issues.

-- 7. What is the most prefferred payment mode?

select Payment_Mode,
       count(payment_mode) as 'total_payment'
from Sales
group by Payment_Mode
order by total_payment desc

-- Business Problem solved: know which payment options customers prefer.
-- Business impact: streamline payment processing, prioritize popular modes.

-- 8. How does age group affect purchasing behavior?

select 
          case 
			    when Customer_Age between 18 and 25 then '18-25'
				when Customer_Age between 26 and 35 then '26-35'
				when Customer_Age between 36 and 50 then '36-50'
			    else '51+'
          end as 'age_wise_purchase',
          format(sum(quantity*price),'C0','en-IN') as 'total_spend'
from Sales
group by   case 
			    when Customer_Age between 18 and 25 then '18-25'
				when Customer_Age between 26 and 35 then '26-35'
				when Customer_Age between 36 and 50 then '36-50'
			    else '51+'
            end
order by (sum(quantity*price)) desc

-- Note: using only C0 for $ sign and for INR ('en-IN')

-- max age - 60
-- min age - 18

-- Business Problem solved: Uderstand customer demogrophics.
-- Business Impact: Targeted marketing and product recommendations by age group

-- 9. Whats the monthly sales trend?

select FORMAT(purchase_date,'yyyy-MM') as 'Month_Year',
       FORMAT(sum(price*quantity), 'C0','en-IN') as 'total_sales',
	   sum(quantity) as 'total_qty'
from Sales
group by FORMAT(purchase_date,'yyyy-MM')
order by (sum(price*quantity)) desc

-- business Problem solved: sales fluctuations go unnoticed.
-- business impact: plan inventory and marketing according to seasonal trend.

-- 10. Are certain genders buying more specific product categories?

-- method 1
select Gender, 
       product_category,
	   count(Product_Category)
from Sales
group by Gender,
         Product_Category
order by Gender

-- method 2
select * from 
     ( select gender, PRODUCT_category from Sales) as source_table
pivot
     (count(gender) for gender in ([Male],[Female])) As pivotea_table
order by Product_Category

-- Business Proble: geneder based product preferences.

-- Business Impact: personalized ads, geneder-focused compaigns.
