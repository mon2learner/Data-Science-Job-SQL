


/*1. You're a Compensation analyst employed by a multinational corporation. Your Assignment is to Pinpoint Countries who give work fully remotely, for the title
 'managers’ Paying salaries Exceeding $90,000 USD */

 select distinct company_location
 from salaries
 where remote_ratio = 100 
 and job_title like '%Manager%' 
 and salary_in_usd > 90000             


/*2. AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. you're tasked WITH 
Identifying top 5 Country Having  greatest count of large(company size) number of companies. */

select company_location, large_companies_count
from 
	(
	select company_location , count(*) as large_companies_count, rank() over( order by  COUNT(*) desc) as rn
	from salaries
	where company_size = 'L' and experience_level = 'EN'
	group by company_location) sub1
where rn <=5
;


/*3.  Picture yourself AS a data scientist Working for a workforce management platform. Your objective is to calculate the percentage of employees. 
Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying remote positions IN today's job market. */

select	COUNT( case when remote_ratio = 100 then 1 else null end) as remote_emp , 
		COUNT(*) as total_emp, 
		cast(round(1.0* COUNT( case when remote_ratio = 100 then 1 else null end) / COUNT(*) * 100,2) as decimal(10,2)) as 'percentage'
from salaries
where salary_in_usd > 100000;  




/*4.	Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations where entry-level average salaries exceed the 
average salary for that job title in market for entry level, helping your agency guide candidates towards lucrative countries. */

select distinct company_location, job_title
from 
	(
	select	company_location ,
			job_title,
			AVG(salary_in_usd) over(partition by job_title) as avg_salary_market,
			AVG(salary_in_usd) over(partition by company_location, job_title) as avg_sal_country
	from salaries
	where experience_level = 'EN') sub1
where  avg_sal_country > avg_salary_market




/*5. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the annual salary growth rate for various job titles. 
By Calculating the percentage Increase IN salary FROM previous year to this year, you aim to provide valuable Insights Into salary trends WITHIN different job roles. */



with cte as (
		select	work_year, job_title, 
				AVG(salary_in_usd)  as avg_sal		
		from salaries
		where work_year in (2024,2023)
		group by work_year, job_title
), final_cte as (
	select  job_title,
			avg_sal,
			LAG(avg_sal) over(partition by job_title order by work_year) as prev_year_sal,
			cast((1.0 * avg_sal - LAG(avg_sal) over(partition by job_title order by work_year)) / LAG(avg_sal) over(partition by job_title order by work_year) * 100 as decimal (10,2)) as perc
	from cte 
)
	select	job_title,
			avg_sal as current_year,
			prev_year_sal,
			perc as change_in_percentage
	from final_cte
	where perc is not null
	order by change_in_percentage desc
	


/* 6. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. 
Your job is to Find out for each job title which. Country pays the maximum average salary. This helps you to place your candidates IN those countries. */
	 



with cte as (

	select	company_location,
			job_title, 
			AVG(salary_in_usd) as avg_sal
	from salaries
	group by company_location, 	job_title
),
final_cte as (

	select  *, RANK() over(partition by job_title order by avg_sal desc) as rn
	from cte
)
	select	company_location,
			job_title,
			avg_sal
	from final_cte
	where rn =1 


/*7. AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations. 
Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years 
(Countries WHERE data is available for 3 years Only(present year and past two years) providing Insights into Locations experiencing Sustained salary growth. */


with cte1 as (
	select company_location
	from salaries
	where work_year in (2024,2023,2022)
	group by company_location
	having COUNT(distinct work_year) = 3

), cte2 as (
	select w.company_location,
			work_year,
			AVG(salary_in_usd) as avg_sal,
			LAG(AVG(salary_in_usd),1,0) over(partition by w.company_location order by work_year) as prev_year_sal
	from cte1 w
	left join salaries s on w.company_location = s.company_location
	where work_year in (2024,2023,2022) 
	group by w.company_location, work_year

), cte3 as (
	select	company_location, work_year, avg_sal, prev_year_sal, COUNT(*) over(partition by company_location) as flag
	from cte2
	where avg_sal > prev_year_sal

), cte4 as (	
	select	company_location,
			work_year,
			avg_sal
	from cte3
	where flag = 3
)
	select	company_location,
			max(case when work_year = 2022 then avg_sal end) as '2022',
			max(case when work_year = 2023 then avg_sal end) as '2023',
			max(case when work_year = 2024 then avg_sal end) as '2024'
	from cte4 
	group by company_location;


/*8.	 Picture yourself AS a workforce strategist employed by a global HR tech startup. 
	Your Mission is to Determine the percentage of fully remote work for each experience level IN 2021 and compare it WITH the corresponding figures for 2024, 
	Highlighting any significant Increases or decreases IN remote work Adoption over the years. */
	 
	

with cte as (
	select  distinct  work_year,
			experience_level,
			--count(case when remote_ratio = 100 then 1 else null end)over(partition by work_year , experience_level) as remote_count,
			--COUNT(remote_ratio) over(partition by work_year, experience_level) as total_count,
			cast(1.0 * count(case when remote_ratio = 100 then 1 else null end)over(partition by work_year , experience_level)  / 
			COUNT(remote_ratio) over(partition by work_year, experience_level) * 100 as decimal(10,2)) as remote_perc		
	from salaries
	where work_year in (2021, 2024)
)
	select	experience_level, 
			max(case when work_year = 2021 then remote_perc end) as '2021',
			max(case when work_year = 2024 then remote_perc end) as '2024'
	from cte
	group by experience_level;


	/*9.	AS a Compensation specialist at a Fortune 500 company, you're tasked WITH analyzing salary trends over time. 
	Your objective is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024, helping the company stay competitive IN the talent market. */
	

	
	with cte as (
		select	work_year, experience_level, job_title, avg(salary_in_usd) as avg_salary 
		from salaries
		where work_year in (2024,2023) 
		group by  work_year, experience_level, job_title
		
	), cte2 as (
		select	*, COUNT(work_year) over(partition by experience_level , job_title) as total_cnt
		from cte
	), cte3 as (
		select	job_title, experience_level, 
				max(case when work_year = 2023 then avg_salary end) as '2023',
				max(case when work_year = 2024 then avg_salary end) as '2024',
				cast(((1.0 * max(case when work_year = 2024 then avg_salary end) - max(case when work_year = 2023 then avg_salary end)) / max(case when work_year = 2023 then avg_salary end)) * 100 as decimal(10,2)) as change_in_percentage
 		from cte2
		where total_cnt = 2
		group by experience_level, job_title
	)
		select	*
		from cte3
	
	;










	