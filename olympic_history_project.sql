use olympic_history;

SELECT * FROM athlete_events;
SELECT * FROM noc_regions;

-- I. Olympic Games Overview
-- How many Olympic Games have been held?
Select count(distinct games) as  Olympic_Games
from athlete_events;  -- 51
-- List all Olympic Games held so far.
Select `Year`, Season, City
from athlete_events
order by `Year`;

-- II. Participation and Representation
-- Total number of nations participating in each Olympic Games:

/*WITH Countries as
(Select ae.games, nr.region 
from athlete_events ae
join noc_regions nr on ae.NOC = nr.NOC 
group by ae.games, nr.region
order by ae.games
)
Select games, count(1) as total_games
from Countries
group by games
order by games;
*/
-- Year with the highest and lowest number of countries participating in the Olympics:

/*
WITH nations as
(Select ae.games, nr.region 
from athlete_events ae
join noc_regions nr on ae.NOC = nr.NOC 
group by ae.games, nr.region
order by ae.games
), total_nation as
(Select games, count(*) as total_nations
from nations
group by games
order by games)     */
select distinct
      concat(first_value(games) over(order by total_nations)
      , ' - '
      , first_value(total_nations) over(order by total_nations)) as Lowest_Countries,
      concat(first_value(games) over(order by total_nations desc)
      , ' - '
      , first_value(total_nations) over(order by total_nations desc)) as Highest_Countries
      from total_nation
      order by 1;		-- '1896 Summer - 5', '2016 Summer - 171'

-- Nation participating in all Olympic Games.
/*
WITH total_games as
(Select count(distinct games) as  Olympic_Games
from athlete_events),
nations as (
Select games, nr.region as nation
from athlete_events ae
join noc_regions nr on ae.NOC = nr.NOC 
group by games, nr.region
order by games)
, participated_nations as
(Select nation, count(1) as total_participated
from nations
group by nation)
Select pn.*
from participated_nations pn
join total_games tg
ON tg.Olympic_Games = pn.total_participated
order by 1;   					-- No One!
*/
-- III. Sports and Events Analysis
-- Sport played in all Summer Olympics:

/*
WITH total_Summer_games as
(Select count(distinct games) as  Summer_Olympic_Games
from athlete_events
where Season = 'Summer'), 
summer_sports as
(Select distinct games, sport
from athlete_events
where Season = 'Summer'),
tot_games as
(select sport, count(1) as no_of_games
from summer_sports
group by sport)  */
Select *
from tot_games tg
join total_Summer_games tsg
on tsg.Summer_Olympic_Games = tg.no_of_games;   -- 'Athletics', 'Gymnastics', 'Fencing'

-- Sports played only once in the Olympics:
/*
WITH sports as
(Select distinct games, sport
from athlete_events),
tot_games as
(select sport, count(1) as no_of_games
from sports
group by sport) */
Select tg.*, s.games
from tot_games tg
join sports s ON tg.sport = s.sport
where tg.no_of_games = 1
order by s.sport;

-- Total number of sports played in each Olympic Games:
/*
WITH sports as
(Select distinct games, sport
from athlete_events),
tot_games as
(select games, count(*) as no_of_sports
from sports
group by games)
*/
Select * from tot_games
order by no_of_sports;

-- IV. Athlete Insights
-- Details of the oldest athletes to win a gold medal:

Select ae.*, nr.region
from athlete_events ae
join noc_regions nr on ae.NOC = nr.NOC
Where Medal = 'Gold'
order by age desc
limit 1;    -- 'Charles Granville Bruce'

-- Ratio of male to female athletes in all Olympic Games:
/*
WITH t1 as(
Select sex, count(1) as cnt
from athlete_events
group by sex),
t2 as (
Select *, row_number() over(order by cnt) as rn
from t1),
min_cnt as (Select cnt from t2 where rn = 1),
max_cnt as (Select cnt from t2 where rn = 2)
*/
Select concat('1 : ', round(cast(max_cnt.cnt as decimal)/ cast(min_cnt.cnt as decimal), 2)) as ratio
from min_cnt, max_cnt;

-- V. Medal and Performance Analysis
-- Top 5 athletes with the most gold medals:
/*
WITH Gold_medal as(
Select name, team
from athlete_events ae
Where Medal = 'Gold'),
cnt_gold as(
Select name, team, count(*) as total_gold_medals 
from Gold_medal
group by name, team)
*/
Select *
From cnt_gold
order by total_gold_medals Desc;
-- Top 5 athletes with the most medals (gold, silver, bronze):
/*
WITH medals as(
Select name, team, count(1) as total_medals
from athlete_events ae
Where Medal IN ('Gold', 'silver', 'bronze')
group by name, team
order by total_medals desc),
rnk as(
Select *, dense_rank() over(order by total_medals desc) as rank_
from medals)
*/
select name, team, total_medals
from rnk
where rank_ <= 5;

-- Top 5 most successful countries in the Olympics (by total medals won):

WITH medals as(
Select nr.region, count(1) as total_medals
from athlete_events ae 
join noc_regions nr on nr.noc = ae.noc
Where Medal <> 'NA'
group by nr.region
order by total_medals desc),
rnk as(
Select *, dense_rank() over(order by total_medals desc) as rank_
from medals)
select *
from rnk
where rank_ <= 5; -- USA, Russia, Germany, Italy, Uk

-- Total gold, silver, and bronze medals won by each country:
SELECT
    nr.region AS country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END), 0) AS bronze
from athlete_events ae 
JOIN noc_regions nr ON nr.noc = ae.noc
WHERE medal <> 'NA'
GROUP BY nr.region
ORDER BY gold DESC, silver DESC, bronze DESC;

-- Total gold, silver, and bronze medals won by each country in each Olympic Games:
SELECT
    ae.games, nr.region AS country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END), 0) AS bronze
from athlete_events ae 
JOIN noc_regions nr ON nr.noc = ae.noc
WHERE medal <> 'NA'
GROUP BY nr.region, ae.games
ORDER BY ae.games;

-- Country with the most gold, silver, and bronze medals in each Olympic Games:
/*
WITH MedalCounts AS (
    SELECT
        SUBSTRING_INDEX(games, ' - ', 1) AS games,
        SUBSTRING_INDEX(games, ' - ', -1) AS country,
        SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
        SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
        SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
    FROM athlete_events ae 
    JOIN noc_regions nr ON nr.noc = ae.noc
    WHERE medal <> 'NA'
    GROUP BY games, country
),
RankedMedals AS (
    SELECT
        games, country, gold, silver, bronze,
        ROW_NUMBER() OVER (PARTITION BY games ORDER BY gold DESC) AS gold_rank,
        ROW_NUMBER() OVER (PARTITION BY games ORDER BY silver DESC) AS silver_rank,
        ROW_NUMBER() OVER (PARTITION BY games ORDER BY bronze DESC) AS bronze_rank
    FROM MedalCounts )
*/
SELECT
    games,
    CONCAT(
        (SELECT country FROM RankedMedals WHERE gold_rank = 1 AND games = rm.games LIMIT 1), ' - ',
        (SELECT gold FROM RankedMedals WHERE gold_rank = 1 AND games = rm.games LIMIT 1)
    ) AS Max_Gold,
    CONCAT(
        (SELECT country FROM RankedMedals WHERE silver_rank = 1 AND games = rm.games LIMIT 1), ' - ',
        (SELECT silver FROM RankedMedals WHERE silver_rank = 1 AND games = rm.games LIMIT 1)
    ) AS Max_Silver,
    CONCAT(
        (SELECT country FROM RankedMedals WHERE bronze_rank = 1 AND games = rm.games LIMIT 1), ' - ',
        (SELECT bronze FROM RankedMedals WHERE bronze_rank = 1 AND games = rm.games LIMIT 1)
    ) AS Max_Bronze
FROM RankedMedals rm
GROUP BY games
ORDER BY games;

-- Country with the most total medals in each Olympic Games:
/*
WITH MedalCounts AS ( -- This CTE calculates the total number of gold, silver, and bronze medals for each country and event by using SUM with CASE statements.
    SELECT
        SUBSTRING_INDEX(games, ' - ', 1) AS games,
        SUBSTRING_INDEX(games, ' - ', -1) AS country,
        SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
        SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
        SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
    from athlete_events ae 
	JOIN noc_regions nr ON nr.noc = ae.noc
    WHERE medal <> 'NA'
    GROUP BY games, country
),
TotalMedals AS (		-- This CTE counts the total number of medals won by each country for each event.
    SELECT
        SUBSTRING_INDEX(games, ' - ', 1) AS games,
        nr.region AS country,
        COUNT(1) AS total_medals
    from athlete_events ae 
	JOIN noc_regions nr ON nr.noc = ae.noc
    WHERE medal <> 'NA'
    GROUP BY games, nr.region
)
*/
SELECT
    mc.games,
    CONCAT(
        (SELECT country FROM MedalCounts WHERE games = mc.games ORDER BY gold DESC LIMIT 1),
        ' - ',
        (SELECT gold FROM MedalCounts WHERE games = mc.games ORDER BY gold DESC LIMIT 1)
    ) AS Max_Gold,
    CONCAT(
        (SELECT country FROM MedalCounts WHERE games = mc.games ORDER BY silver DESC LIMIT 1),
        ' - ',
        (SELECT silver FROM MedalCounts WHERE games = mc.games ORDER BY silver DESC LIMIT 1)
    ) AS Max_Silver,
    CONCAT(
        (SELECT country FROM MedalCounts WHERE games = mc.games ORDER BY bronze DESC LIMIT 1),
        ' - ',
        (SELECT bronze FROM MedalCounts WHERE games = mc.games ORDER BY bronze DESC LIMIT 1)
    ) AS Max_Bronze,
    CONCAT(
        (SELECT country FROM TotalMedals WHERE games = mc.games ORDER BY total_medals DESC LIMIT 1),
        ' - ',
        (SELECT total_medals FROM TotalMedals WHERE games = mc.games ORDER BY total_medals DESC LIMIT 1)
    ) AS Max_Medals
FROM MedalCounts mc
GROUP BY mc.games
ORDER BY mc.games;

-- VI. Special Case Studies
-- Countries that have never won a gold medal but have won silver/bronze medals:
SELECT 
    nr.region as country, 
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END), 0) AS gold, 
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END), 0) AS silver, 
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END), 0) AS bronze
from athlete_events ae 
JOIN noc_regions nr ON nr.noc = ae.noc 
WHERE medal <> 'NA'
GROUP BY country
HAVING gold = 0 AND (silver > 0 OR bronze > 0)
ORDER BY gold DESC, silver DESC, bronze DESC;

-- Sport/event where Morocco has won the highest number of medals:
/*
with t1 as
        	(select sport, count(1) as total_medals
        	from athlete_events
        	where medal <> 'NA'
        	and team = 'Morocco'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
*/    
select sport, total_medals
from t2
where rnk = 1; -- Athletics - 8
-- Breakdown of all Olympic Games where Morocco won medals in Hockey and the number of medals in each:
select team, sport, games, count(1) as total_medals
    from athlete_events
    where medal <> 'NA'
    and team = 'Morocco' and sport = 'Boxing'
    group by team, sport, games
    order by total_medals desc; -- '1988 Summer' - 1 , '1992 Summer' - 1.