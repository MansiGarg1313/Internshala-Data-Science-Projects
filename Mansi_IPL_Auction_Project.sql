                                          /* IPL Auction Project */
/* Developing auction strategy for new IPL franchise by analyzing past IPL data to create a strong and balanced squad */
                                            /* Prepared By
											   Mansi Garg
											   Internshala
											 Data Science PGC */
                        /* Creating tables and importing information from data sets provided */

Create table IPL_Player_Information
(Id INT, Inning INT, Over INT, Ball INT, Batsman VARCHAR(225), Non_Striker VARCHAR(225),
 Bowler VARCHAR(225), Batsman_Runs INT,	Extra_Runs INT,	Total_Runs INT, Is_Wicket INT,
 Dismissal_Kind VARCHAR(225),	Player_Dismissed VARCHAR(225),	Fielder VARCHAR(225),
 Extras_Type VARCHAR(225),	Batting_Team VARCHAR(225),	Bowling_Team VARCHAR(225));
 
Copy IPL_Player_Information from 'D:\Internshala\SQL_Data-Resource\IPL Dataset (1)\IPL Dataset\IPL_Ball.csv'
Delimiter ',' csv Header;

select * from  IPL_Player_Information;

Create table IPL_Match_Information
(Id INT, City VARCHAR(225),	Match_Date Date, Player_Of_Match VARCHAR(225), Venue VARCHAR(225),	
 Neutral_Venue INT, Team1 VARCHAR(225),	Team2 VARCHAR(225),	Toss_Winner VARCHAR(225),
 Toss_Decision VARCHAR(225), Winner VARCHAR(225), Result VARCHAR(225),	Result_Margin INT,
 Eliminator	VARCHAR(225), Method VARCHAR(225),	Umpire1 VARCHAR(225),	Umpire2 VARCHAR(225));
 
Copy IPL_Match_Information From 'D:\Internshala\SQL_Data-Resource\IPL Dataset (1)\IPL Dataset\IPL_matches.csv' 
 Delimiter ',' csv Header;
 
 select * from IPL_Match_Information;
 
/* To get 2-3 players with high S.R who have faced at least 500 balls.And to do that you have to make a list of 
10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the
amount greater than you have in the purse for a particular player. */

select Batsman, count(Ball) as Total_Balls_Played, sum(Batsman_runs) as Total_runs, 
(sum(Batsman_runs) * 1.0 /count(Ball))*100 as Strike_Rate from IPL_Player_Information
where not extras_type = 'wides'
group by Batsman having count(Ball)>500
order by (sum(Batsman_runs) * 1.0 /count(Ball))*100  desc 
limit 10; 

/* need to get 2-3 players with good Average who have played more the 2 ipl seasons.And to do that you have to 
make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should
not pay the amount greater than you have in the purse for a particular player. */

create table players_data as (select p.batsman, p.batsman_runs, p.is_wicket, m.match_date 
from IPL_Player_Information as p 
inner join IPL_Match_Information as m
on p.id = m.id);

select * from players_data;

select batsman, (sum(batsman_runs)/sum(is_wicket)) as average_score, count(distinct(extract(year from match_date)))
as year_count
from players_data
group by batsman
having count(distinct(extract(year from match_date))) >2 AND sum(is_wicket) != 0
order by (sum(batsman_runs)/sum(is_wicket)) desc
limit 10;

/* you need to get 2-3 Hard-hitting players who have scored most runs in boundaries and have played more the 2 ipl
season. To do that you have to make a list of 10 players you want to bid in the auction so that when you try to 
grab them in auction you should not pay the amount greater than you have in the purse for a particular player.*/

SELECT P.BATSMAN, SUM(P.BATSMAN_RUNS), COUNT(CASE WHEN P.BATSMAN_RUNS = 4 THEN 1 END) AS FOUR_RUNS,
COUNT(CASE WHEN P.BATSMAN_RUNS = 6 THEN 1 END) AS SIX_RUNS,
(COUNT(CASE WHEN P.BATSMAN_RUNS = 4 THEN 1 END) +COUNT(CASE WHEN P.BATSMAN_RUNS = 6 THEN 1 END)) AS BOUNDARIES,
((((COUNT(CASE WHEN P.BATSMAN_RUNS = 4 THEN 1 END)*4)+(COUNT(CASE WHEN P.BATSMAN_RUNS = 6 THEN 1 END)*6))*100)/SUM(P.BATSMAN_RUNS)) AS BOUNDARIES_PERCENTAGE,
COUNT(DISTINCT(EXTRACT(YEAR FROM M.MATCH_DATE))) AS SEASONS
FROM IPL_PLAYER_INFORMATION AS P
INNER JOIN IPL_MATCH_INFORMATION AS M
ON P.ID = M.ID
GROUP BY P.BATSMAN
HAVING COUNT(DISTINCT(EXTRACT(YEAR FROM M.MATCH_DATE)))>2
ORDER BY BOUNDARIES_PERCENTAGE DESC
LIMIT 10;

/* Your first priority is to get 2-3 bowlers with good economy who have bowled at least 500 balls in IPL so far.
To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them
in auction you should not pay the amount greater than you have in the purse for a particular player. */

CREATE TABLE BOWLERS_INFO AS (select bowler, count(ball) as total_balls, sum(total_runs) as total_runs_scored
from IPL_PLAYER_INFORMATION group by bowler);

SELECT * FROM BOWLERS_INFO;

SELECT BOWLER, TOTAL_BALLS, (TOTAL_RUNS_SCORED/(TOTAL_BALLS/6.0)) AS ECONOMY FROM BOWLERS_INFO
WHERE TOTAL_BALLS>=500 GROUP BY BOWLER, TOTAL_BALLS, TOTAL_RUNS_SCORED ORDER BY ECONOMY ASC
LIMIT 10;

/*  you need to get 2-3 bowlers with the best strike rate and who have bowled at least 500 balls in IPL so far.
To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them
in auction you should not pay the amount greater than you have in the purse for a particular player. */

CREATE TABLE BOWLER_STRIKE AS (SELECT BOWLER, COUNT(BALL) AS TOTAL_BALLS, 
							   COUNT(CASE WHEN IS_WICKET = 1 THEN 1 END) AS WICKET_TAKEN
FROM IPL_PLAYER_INFORMATION GROUP BY BOWLER);
SELECT * FROM BOWLER_STRIKE;

SELECT BOWLER, WICKET_TAKEN, (TOTAL_BALLS/(WICKET_TAKEN*1.0)) AS STRIKE_RATE
FROM BOWLER_STRIKE WHERE TOTAL_BALLS>=500 GROUP BY BOWLER, TOTAL_BALLS, WICKET_TAKEN
ORDER BY STRIKE_RATE ASC
LIMIT 10;

/* you need to get 2-3 All_rounders with the best batting as well as bowling strike rate and who have faced at
least 500 balls in IPL so far and have bowled minimum 300 balls.To do that you have to make a list of 10 players 
you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater
than you have in the purse for a particular player. */

SELECT BATTING.BATSMAN, BATTING.BATTING_SR,
BOWLLING.BOWLER, BOWLLING.BOWLER_SR
FROM (select batsman, (sum(batsman_runs)*100.0/count(ball)) as batting_SR 
from IPL_PLAYER_INFORMATION 
group by batsman having count(ball)>=500 order by batting_SR DESC) AS  BATTING
  JOIN
(SELECT BOWLER, (COUNT(BALL)*1.0/COUNT(CASE WHEN IS_WICKET = 1 THEN 1 END)) AS BOWLER_SR
FROM IPL_PLAYER_INFORMATION 
group by BOWLER having count(ball)>=300 order by BOWLER_SR ASC) AS BOWLLING
ON BATTING.BATSMAN = BOWLLING.BOWLER
LIMIT 10;

/* Selection of fielders.*/

SELECT DISTINCT(DISMISSAL_KIND) FROM IPL_PLAYER_INFORMATION;

SELECT
    FIELDER,
    SUM(CASE WHEN DISMISSAL_KIND = 'stumped' THEN 1 ELSE 0 END) AS STUMPED_TOTAL,
    SUM(CASE WHEN DISMISSAL_KIND = 'run out' THEN 1 ELSE 0 END) AS RUN_OUT_TOTAL,
    SUM(CASE WHEN DISMISSAL_KIND = 'caught' THEN 1 ELSE 0 END) AS CAUGHT_TOTAL,
    (SUM(CASE WHEN DISMISSAL_KIND = 'stumped' THEN 1 ELSE 0 END) +
     SUM(CASE WHEN DISMISSAL_KIND = 'run out' THEN 1 ELSE 0 END) +
     SUM(CASE WHEN DISMISSAL_KIND = 'caught' THEN 1 ELSE 0 END)) AS TOTAL_DISMISSAL
FROM IPL_PLAYER_INFORMATION
WHERE NOT FIELDER = 'NA' AND DISMISSAL_KIND IN ('stumped', 'run out', 'caught')
GROUP BY FIELDER
ORDER BY TOTAL_DISMISSAL DESC
LIMIT 10;

                                        /* ADDitional Questions */
/* count of cities that have hosted an IPL match */

SELECT COUNT(DISTINCT(CITY)) AS CITY_COUNT FROM IPL_MATCH_INFORMATION;

/* Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional column
ball_result containing values boundary, dot or other depending on the total_run (boundary for >= 4, dot for 0 
and other for any other number. */

CREATE TABLE DELIVERIES_VO2 AS 
(SELECT *, 
CASE
    WHEN TOTAL_RUNS >= 4 THEN 'BOUNDARY' 
    WHEN TOTAL_RUNS = 0 THEN 'DOT'
	ELSE 'OTHER'
	END AS BALL_RESULT
	FROM IPL_PLAYER_INFORMATION);
SELECT * FROM DELIVERIES_VO2;

/* query to fetch the total number of boundaries and dot balls from the deliveries_v02 table. */
SELECT SUM(CASE WHEN BALL_RESULT = 'BOUNDARY' THEN 1 ELSE 0 END ) AS BOUNDARY_COUNT,
       SUM(CASE WHEN BALL_RESULT = 'DOT' THEN 1 ELSE 0 END) AS DOT_COUNT
	   FROM DELIVERIES_VO2;

/* query to fetch the total number of boundaries scored by each team from the deliveries_v02 table and order it
in descending order of the number of boundaries scored. */

select batting_team, 
sum(case when ball_result = 'BOUNDARY' THEN 1 ELSE 0 END ) AS BOUNDARY_COUNT
from  DELIVERIES_VO2
group by batting_team
order by boundary_count desc;

/* Query to fetch the total number of dot balls bowled by each team and order it in descending order of the 
total number of dot balls bowled. */
select bowling_team, 
sum(case when ball_result = 'DOT' THEN 1 ELSE 0 END ) AS DOT_COUNT
from  DELIVERIES_VO2
group by bowling_team
order by dot_count desc;

/* Query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA. */

SELECT
    DISMISSAL_KIND, COUNT(DISMISSAL_KIND) AS DISMISSAL_COUNT
	FROM DELIVERIES_VO2
	WHERE NOT DISMISSAL_KIND = 'NA'
	GROUP BY DISMISSAL_KIND
	ORDER BY DISMISSAL_COUNT DESC;
	
/* Query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table. */

 SELECT BOWLER, SUM(EXTRA_RUNS) AS EXTRA_RUNS_CONCEDED FROM DELIVERIES_VO2
 GROUP BY BOWLER
 ORDER BY EXTRA_RUNS_CONCEDED DESC
 LIMIT 5;

/* Query to create a table named deliveries_v03 with all the columns of deliveries_v02 table and two additional 
column (named venue and match_date) of venue and date from table matches. */

CREATE TABLE Deliveries_v03 AS (SELECT *
FROM (SELECT D.* , M.MATCH_DATE, M.VENUE FROM DELIVERIES_VO2 AS D
	 INNER JOIN 
	 IPL_MATCH_INFORMATION AS M
	 ON D.ID = M.ID));
SELECT * FROM Deliveries_v03;

/* Query to fetch the total runs scored for each venue and order it in the descending order of total
runs scored. */
SELECT VENUE, SUM(TOTAL_RUNS) AS TOTAL_RUNS_SCORED 
FROM Deliveries_v03
GROUP BY VENUE
ORDER BY TOTAL_RUNS_SCORED DESC;

/* Query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total 
runs scored. */
SELECT DISTINCT(EXTRACT(YEAR FROM MATCH_DATE)) AS  YEAR, VENUE, SUM(TOTAL_RUNS) AS TOTAL_RUNS_SCORED
FROM Deliveries_v03
WHERE VENUE = 'Eden Gardens'
GROUP BY YEAR, VENUE
ORDER BY TOTAL_RUNS_SCORED DESC;










 

