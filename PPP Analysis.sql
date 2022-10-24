use ppp;

----------------------Cleaning Data---------------------
-- 1.Naics Codes table is not organized

select  
		trim(substring([NAICS Industry Description],1,desr-1)) as Sector,
		SUBSTRING([NAICS Industry Description],8,2) look_up ,
		trim(substring([NAICS Industry Description], desr+1, Total_len-desr+1)) as Industry_Discription

		into Modified_Naics_table
from
(
select 
		[NAICS Industry Description],
		PATINDEX('%– [a-z]%',[NAICS Industry Description]) as desr, 
		len([NAICS Industry Description]) as Total_len
from ind_desc
where [NAICS Industry Description] like 'sector%'

) x
insert into Modified_Naics_table 
values
('Sector 31 - 33', 32,'Manufacturing'),
('Sector 31 - 33', 33,'Manufacturing'),
('Sector 44 - 45', 45,'Retail Trade'),
('Sector 48 - 49', 49,'Transportation and Warehousing')

--------------------Analysis-----------------------------
--1. Summary of All PPP Approved Lending

Select count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Total_Net_Dollars, AVG(InitialApprovalAmount) Average_Loan_Size, 
(select count(distinct (OriginatingLender))from ppp_files)Total_Originating_Lender_Count
from ppp_files
order by 3 desc

--Summary of 2021 PPP Approved Lending

Select count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Total_Net_Dollars, AVG(InitialApprovalAmount) Average_Loan_Size, 
(select count(distinct (OriginatingLender))from ppp_files where year(DateApproved) = 2021)Total_Originating_Lender_Count
from ppp_files
where year(DateApproved) = 2021
order by 3 desc

--Summary of 2020 PPP Approved Lending
Select count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Total_Net_Dollars, AVG(InitialApprovalAmount) Average_Loan_Size, 
(select count(distinct (OriginatingLender))from ppp_files where year(DateApproved) = 2020)Total_Originating_Lender_Count
from ppp_files
where year(DateApproved) = 2020
order by 3 desc



--2. Summary of 2021 PPP Approved Loans per Originating Lender, loan count, total amount and average
--Top 15 Originating Lenders for 2021 PPP Loans
--Data is ordered by Net_Dollars
Select top 15 OriginatingLender, count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Net_Dollars, AVG(InitialApprovalAmount) Average_Loan_Size
from ppp_files
where year(DateApproved) = 2021
group by OriginatingLender
order by 3 desc

Select top 15 OriginatingLender, count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Net_Dollars, AVG(InitialApprovalAmount) Average_Loan_Size
from ppp_files
where year(DateApproved) = 2020
group by OriginatingLender
order by 3 desc

---3----
---Top 20 Industries that received the PPP Loans in 2021
-- I need to add the NAICS codes to the GitHub Repo, extracted from SQL
with cte as (

	select ncd.Sector, count(LoanNumber) as Loans_Approved, sum(CurrentApprovalAmount) Net_Dollars
	from ppp_files main
	inner join Modified_Naics_table  ncd
		on left(cast(main.NAICSCode as varchar), 2) = ncd.look_up
	where year(DateApproved) = 2021 
	group by ncd.Sector
	--order by 3 desc

)
SELECT 
	sector,Loans_Approved,
	SUM(Net_Dollars) OVER(PARTITION BY sector) AS Net_Dollars,
	--SUM(Net_Dollars) OVER() AS Total,
	CAST(1. * Net_Dollars / SUM(Net_Dollars) OVER() AS DECIMAL(5,2)) * 100 AS "Percent by Amount"  
FROM cte  
order by 3 desc
--where year(DateApproved) = 2021 

---4---
--States and Territories
select BorrowerState as state, count(LoanNumber) as Loan_Count, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files main
--where cast(DateApproved as date) < '2021-06-01'
group by BorrowerState
order by 1


---5----
---Demographics for PPP
select race, count(LoanNumber) as Loan_Count, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files
group by race
order by 3

select gender, count(LoanNumber) as Loan_Count, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files
group by gender
order by 3

select Ethnicity, count(LoanNumber) as Loan_Count, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files
group by Ethnicity
order by 3

select Veteran, count(LoanNumber) as Loan_Count, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files
group by Veteran
order by 3

---6---
---How much of the PPP Loans of 2021 have been fully forgiven
select count(LoanNumber) as Count_of_Payments,  sum(ForgivenessAmount) Forgiveness_amount_paid
from ppp_files
where year(DateApproved) = 2020 and ForgivenessAmount <> 0

---Summary of 2021 PPP Approved Lending
Select count(LoanNumber) as Loans_Approved, sum(InitialApprovalAmount) Total_Net_Dollars, sum(ForgivenessAmount) Forgiveness_amount_paid,
(select count(distinct (OriginatingLender))from ppp_files where year(DateApproved) = 2021)Total_Originating_Lender_Count
from ppp_files
where year(DateApproved) = 2020 
order by 3 desc


--7---
--In which month was the highest amount given out by the SBA to borrowers
select Year(DateApproved) Year_Approved, Month(DateApproved)Month_Approved, ProcessingMethod, sum(CurrentApprovalAmount) Net_Dollars
from ppp_files
group by Year(DateApproved),  Month(DateApproved), ProcessingMethod
order by 4 desc


-----Creating View------
use ppp
create view ppp_main as
select d.Industry_Discription,
year(dateapproved) year_approved,
month(dateapproved)month_approved,
OriginatingLender,
BorrowerState,
race,
Gender,
Ethnicity,
count (loannumber) no_of_approved,
sum(currentapprovalamount) current_approval_amount,
avg(currentapprovalamount) current_avg_loan_size,
sum(forgivenessamount) amount_forgiven,
sum(initialapprovalamount) approved_amount,
avg(initialapprovalamount) avg_loan_size

from [dbo].[ppp_files] p
inner join [dbo].[Modified_Naics_table] d
on left(p.NAICSCode,2)=d.look_up
group by
d.Industry_Discription,
year(dateapproved),
MONTH(dateapproved),
OriginatingLender,
BorrowerState,
Race,
Gender,
Ethnicity

select top(10) * from [dbo].[Modified_Naics_table]