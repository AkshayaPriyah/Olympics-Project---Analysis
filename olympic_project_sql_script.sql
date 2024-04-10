CREATE TABLE IF NOT EXISTS athlete_events(
ID VARCHAR(100),
Name VARCHAR(150),
Sex VARCHAR(100),
Age VARCHAR(100),	
Height VARCHAR(100),
Weight VARCHAR(100),
Team VARCHAR(100),
NOC VARCHAR(100),
Games VARCHAR(200),
YEAR VARCHAR(50),
Season VARCHAR(100),
City VARCHAR(100),
Sport VARCHAR(100),
Event VARCHAR(150),
Medal VARCHAR(100)
);

SELECT *
FROM athlete_events;

SELECT *
from noc_regions;

SELECT COUNT(DISTINCT region)
FROM noc_regions;

SELECT COUNT(*)
FROM athlete_events;

-- EXPLORATORY DATA ANALYSIS
-- 1)How many olympics games have been held?
SELECT COUNT(DISTINCT(games))
from athlete_events;
-- 51 distinct olympic games have been held

-- 2)List down all Olympics games held so far

SELECT distinct year,season,city
from athlete_events
order by year;

--3)Mention the total no of nations who participated in each olympics game?

with all_countries as(
SELECT games,region
from athlete_events ai
JOIN noc_regions nr
ON ai.noc= nr.noc
group by games,region
)
SELECT games,count(region)
from all_countries
group by games
order by games;

-- 4)Which year saw the highest and lowest no of countries participating in olympics
with all_countries as(
SELECT year,region
from athlete_events ai
JOIN noc_regions nr
ON ai.noc= nr.noc
group by year,region
),
Total_countries as (SELECT year,count(region)as total_count
from all_countries
group by year
)

SELECT DISTINCT
CONCAT(first_value(year)over(order by total_count desc),'-',first_value(total_count)over(order by total_count desc))as highest_year,
CONCAT(first_value(year)over(order by total_count asc),'-',first_value(total_count)over(order by total_count asc))as lowest_year
from Total_countries
ORDER BY 1;

-- 5)Which nation has participated in all of the olympic games
WIth t1 as
(SELECT count(distinct games) as total_olympic_games_count
from athlete_events),
t2 as(
SELECT distinct games,region as country
from athlete_events ai
Join noc_regions nr
on ai.noc = nr.noc
group by games,region),
t3 as (
SELECT DISTINCT country,count(games)as countries_participated
from t2
group by country
)
SELECT *
from t3 ti3
join t1 ti1
on ti3.countries_participated=ti1.total_olympic_games_count;

-- 6)Identify the sport which was played in all summer olympics.
with t1 as
(SELECT count(DISTINCT games)as total_summer_games_count
from athlete_events
 where season = 'Summer'),
--29 summer olympic games are present
t2 as(
SELECT sport,games
from athlete_events
where season ='Summer'
group by sport,games
	),
t3 as
(SELECT sport,count(games)as count_of_each_sport
from t2
group by sport
)

SELECT *
from t3 ti3
join t1 ti1
on ti3.count_of_each_sport = ti1.total_summer_games_count;

-- 7)Which Sports were just played only once in the olympics.
with table_1 as(
SELECT sport,games
from athlete_events
group by sport,games
	)
SELECT sport,count(games)
from table_1
group by sport
Having count(games) = 1 ;

-- 10 games have been played only once!!

--8)Fetch the total no of sports played in each olympic games.
With table_1 as (
SELECT sport,games
from athlete_events
group by sport,games)

SELECT distinct games,count(sport)
from table_1
group by games
order by count(sport)desc;

-- 9)Fetch oldest athletes to win a gold medal
SELECT name,age,medal
from athlete_events
where medal = 'Gold'and age <> 'NA'
order by age desc;

-- Charles Jacobus and Oscar Gomer Swahn are the oldest people with age 64 who won gold medal!

-- 10)Find the Ratio of male and female athletes participated in all olympic games.
With table_1 as (
SELECT sex,count(sex)as count_by_gender
from athlete_events
where sex <> 'N/A'
group by sex
	),
table_2 as 
(SELECT count(sex)as total_head_count
from athlete_events)

SELECT
CASE
WHEN sex='F'then DIVIDE(count_by gender/271116)
END
FROM table_1;

-- 11)Fetch the top 5 athletes who have won the most gold medals
With table_1 as
(SELECT name,team,count(name)as medals_count
from athlete_events
where medal = 'Gold'
group by name,team
order by medals_count desc),

table_2 as(
SELECT *,
DENSE_RANK() OVER(ORDER BY medals_count desc)as ranking
from table_1)

SELECT *
from table_2
where ranking <=5;

-- 12)Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
With table_1 as (
SELECT name,team,count(medal)as medal_count
from athlete_events
where medal <>'NA'
group by name,team
order by medal_count desc),
table_2 as(
SELECT *,
DENSE_RANK()OVER(ORDER BY medal_count desc)as ranking
FROM table_1)

SELECT *
from table_2
where ranking <=5; 

-- 13)Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with table_1 as (
SELECT region,count(medal) as medal_count
from athlete_events ai
join noc_regions nr
on ai.noc = nr.noc
where medal<> 'NA'
group by region
)
SELECT *,
DENSE_RANK()OVER(ORDER BY medal_count desc)as ranking
from table_1
LIMIT 5;

-- 14)List down total gold, silver and bronze medals won by each country.
SELECT region,medal,count(medal)
from athlete_events ai
join noc_regions nr
on ai.noc = nr.noc
where medal <> 'NA'
group by region,medal;

CREATE EXTENSION tablefunc;
SELECT country,
coalesce(bronze,'0') as bronze,
coalesce(gold, '0') as gold,
coalesce(silver,'0') as silver
from CROSSTAB('SELECT region as country,medal,count(medal)
from athlete_events ai
join noc_regions nr
on ai.noc = nr.noc
where medal <> ''NA''
group by region,medal
order by region,medal',			  			  
'VALUES (''Bronze''),(''Gold''),(''Silver'')')
as FINAL_RESULT(country VARCHAR,Bronze VARCHAR,Gold VARCHAR,Silver VARCHAR)
ORDER BY country;

-- 15)List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
SELECT 
substring(game_country,1,11),
substring(game_country,position('-' in game_country)+1)as country_area,
coalesce(bronze,'0') as bronze,
coalesce(gold, '0') as gold,
coalesce(silver,'0') as silver
from CROSSTAB('SELECT concat(games, '' - '',nr.region) as game_country,medal,count(medal)
from athlete_events ai
join noc_regions nr
on ai.noc = nr.noc
where medal <> ''NA''
group by games,nr.region,medal
order by games,nr.region,medal',			  			  
'VALUES (''Bronze''),(''Gold''),(''Silver'')')
as FINAL_RESULT(game_country VARCHAR,Bronze VARCHAR,Gold VARCHAR,Silver VARCHAR)
ORDER BY game_country;
 
-- 16) In which Sport/event, India has won highest medals
with table_1 as(
SELECT region,sport,count(medal)as medal_count
from athlete_events ai
join noc_regions nr
on ai.noc = nr.noc
where medal <> 'NA' and region = 'India'
group by region,sport
order by medal_count desc
),
table_2 as
(
SELECT *,
DENSE_RANK()OVER(ORDER BY medal_count desc)as ranking
from table_1
)

SELECT *
from table_2
where ranking = 1;

-- 17)Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
SELECT games,sport,count(medal)
from athlete_events ai
JOIN noc_regions nr
ON ai.noc = nr.noc
where region = 'India' and medal <> 'NA' and sport = 'Hockey'
group by games,sport
order by count(medal)desc;


