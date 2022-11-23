/*
Checking data upload

Select * 
From PortfolioProject..NBAPlayerSize

Select * 
From PortfolioProject..PerGameStats

Select * 
From PortfolioProject..ShootingPercentages

Select * 
From PortfolioProject..AdvancedStatistics
*/

--Looking at the progression of scoring in nba history

Select Season, PTS
From PortfolioProject..PerGameStats
order by 1 

--Compare average scoring of pre-modern era and modern era(1980 cutoff)
Select AVG(PTS) as 'PreModernEra', (Select AVG(PTS) from PerGameStats Where Season > 1979) as 'ModernEra'
from PerGameStats 
where Season <= 1979

--Find percentage of shots that were 3 point attempts
Select Season, (ThreePA/FGA) * 100 as PercentShotThreePointers
from PerGameStats
order by 1

--Looking at progression of player size
--Height Weight data not collected pre 1952

Select Season, HeightInches, Wt
From PortfolioProject..NBAPlayerSize
where Season > 1951
order by 1

--League wide scoring rate seems to have moved in a roller coaster pattern
--Will make new column adjusting the scoring to the pace of play
--PACE Statistics not tracked prior to 1974

Select PerGameStats.Season, PerGameStats.PTS, AdvancedStatistics.Pace, AdvancedStatistics.ORtg, 
((100 / AdvancedStatistics.Pace) * PerGameStats.PTS) AS AdjustedScoring
From PerGameStats
INNER JOIN AdvancedStatistics ON PerGameStats.Season=AdvancedStatistics.Season
Where PerGameStats.Season > 1973;

--USE CTE WITH NEW ADJUSTED SCORING COLUMN TO PERFORM MORE CALCULATIONS

With AdjScoring (Season, Points, ORating, EffectiveFgPercentage, Pace, AdjustedScoring)
as
(
Select PerGameStats.Season, PerGameStats.Pts, AdvancedStatistics.ORtg, 
	AdvancedStatistics.EFgPercentage, AdvancedStatistics.Pace, ((100 / AdvancedStatistics.Pace) * PerGameStats.PTS) as AdjustedScoring
From PerGameStats 
Join AdvancedStatistics 
	On PerGameStats.Season = AdvancedStatistics.Season
)
Select *
From AdjScoring
order by AdjustedScoring Desc

/* Despite the Pre-Modern Nba Scoring at a higher average rate than the modern nba(105.07ppg vs 103.2ppg), the modern nba scores much 
more efficiently as shown in the above query. The higher EFg% in more recent years along with lower pace shows that the addition
of the three point shot is likely the largest reason for this. */

Select Season, ThreePtPercentage
From ShootingPercentages
where ThreePtPercentage is not null
order by 1 desc;

With FGEfficiencyAnalysis (Season, TwoPointers, TwoPointersAttempted, ThreePointPercentage)
as
(
Select PerGameStats.Season, (PerGameStats.FG - PerGameStats.ThreeP) as TwoPointers, 
	(PerGameStats.FGA - PerGameStats.ThreePA) as TwoPointersAttempted, ShootingPercentages.ThreePtPercentage
from PerGameStats
join ShootingPercentages 
	on PerGameStats.Season = ShootingPercentages.Season
where PerGameStats.Season > 1979
)

Select Season, (TwoPointers/TwoPointersAttempted) * 100 as TwoPointFGPercentage, 
	ThreePointPercentage*1.5 as AdjustedEfficiencyRating3Pointers 
from FGEfficiencyAnalysis

/*The above CTE was used to compare the efficiency levels between a 2pt and 3pt shot. When adjusting for points and fgm percentages,
the 3p shot has been at least as efficient for most of the last 32 years. It took about 10 years after the 3p line was added in the 
1979-1980 season for the shot to pass up 2p efficiency. Another observation from the data is that the efficiency of the three point
shot is no longer rising but has stabilized over the past 20 years while the 2 point shot has steadily become more efficient to the
point where the difference in efficiency between the three point shot or the two point shot has become negligible in the current season.*/

--TEMP TABLE

Drop Table if exists #TwoPointVsThreePoint
Create Table #TwoPointVsThreePoint
(
Season Int,
TwoPointers Float,
TwoPointersAttempted Float,
ThreePtPercentage Float
)

Insert into #TwoPointVsThreePoint
Select PerGameStats.Season, (PerGameStats.FG - PerGameStats.ThreeP) as TwoPointers, 
	(PerGameStats.FGA - PerGameStats.ThreePA) as TwoPointersAttempted, ShootingPercentages.ThreePtPercentage
from PerGameStats
join ShootingPercentages 
	on PerGameStats.Season = ShootingPercentages.Season
where PerGameStats.Season > 1979

Select *
from #TwoPointVsThreePoint

--Creating View to store data for later visualizations

Create View FGEfficiencyAnalysis as
Select PerGameStats.Season, (PerGameStats.FG - PerGameStats.ThreeP) as TwoPointers, 
	(PerGameStats.FGA - PerGameStats.ThreePA) as TwoPointersAttempted, ShootingPercentages.ThreePtPercentage
from PerGameStats
join ShootingPercentages 
	on PerGameStats.Season = ShootingPercentages.Season
where PerGameStats.Season > 1979

Create View AdjustedScoring as
Select PerGameStats.Season, PerGameStats.Pts, AdvancedStatistics.ORtg, 
	AdvancedStatistics.EFgPercentage, AdvancedStatistics.Pace, ((100 / AdvancedStatistics.Pace) * PerGameStats.PTS) as AdjustedScoring
From PerGameStats 
Join AdvancedStatistics 
	On PerGameStats.Season = AdvancedStatistics.Season