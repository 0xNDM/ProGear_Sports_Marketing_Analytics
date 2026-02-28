-- Select product details and assign a price category based on price thresholds
select ProductID, ProductName, Price, Category, 
	case 
		when price < 50 then 'Low'
		when price between 50 and 200 then 'Medium'
		Else 'High'
	end as PriceCategory
from products;

-- Retrieve customer details along with their geographic location
select c.CustomerID, c.CustomerName, c.Email, c.Gender, c.Age, g.Country, g.City,
			CASE
				when c.Age < 18 then '< 18'
				when c.Age between 18 and 30 then '18 - 30'
				when c.Age between 31 and 45 then '31 - 45'
				when c.Age between 46 and 65 then '46 - 65'
				else '65+'
			END as AgeGroup
from customers c
left join  geography g
	on c.GeographyID = g.GeographyID;

-- Retrieve customer review details and remove double spaces from review text
select ReviewID, CustomerID, ProductID, ReviewDate, Rating, 
	REPLACE(ReviewText, '  ', ' ') as ReviewText
from customer_reviews;

-- Retrieve engagement data, normalize content type, split views and clicks, format dates
select EngagementID, ContentID, CampaignID, ProductID, 
	UPPER(replace(contentType, 'Socialmedia', 'Social Media')) as ContentType,
	left(viewsclickscombined, CHARINDEX('-', viewsclickscombined) - 1) as Views,
	right(viewsclickscombined, len(viewsclickscombined) - CHARINDEX('-', viewsclickscombined)) as Clicks,
	Likes,
	format(convert(date, EngagementDate), 'dd.MM.yyyy') as EngagementDate
from engagement_data
where ContentType != 'Newsletter';


-- Identify duplicate customer journey records by assigning a row number
-- to each record within groups of identical customer, product, date, stage, and action
with DuplicateRecords as (
		select JourneyID, CustomerID, ProductID, VisitDate, Stage, Action, Duration,
			ROW_NUMBER() Over (
				PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
				ORDER BY JourneyID  
			) AS row_num
		from customer_journey
)
-- Return all records with their assigned row numbers, ordered by JourneyID
select count(*)
from DuplicateRecords
where row_num > 1
order by journeyID;


-- Clean customer journey data by removing duplicates and filling missing durations
-- using the average duration for the same visit date
select 
		JourneyID,
		CustomerID, 
		ProductID, 
		VisitDate, 
		Stage, 
		Action,
		COALESCE(duration, avg_duration) as Duration
from (
		-- Calculate average duration per visit date,  assign row numbers
    	-- to identify duplicate journey records
		select *,
			AVG(duration) over (partition by VisitDate) as Avg_duration,
			ROW_NUMBER() Over (
				PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
				ORDER BY JourneyID  
			) AS row_num
		from customer_journey
) as subquery
where row_num = 1;









