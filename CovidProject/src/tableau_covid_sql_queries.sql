/*
Queries used for Tableau COVID 2022 Project
Data pulled up to May 1, 2022
*/

-- 1.
-- Global Figures (total cases, total deaths and Death %)

SELECT	SUM(new_cases) AS total_cases,
				SUM(CAST(new_deaths as bigint)) AS total_deaths,
				SUM(CAST(new_deaths AS bigint))/SUM(new_cases)*100 AS death_percentage
FROM	public."CovidDeaths_2022"
WHERE	continent IS NOT NULL
ORDER by 1,2;


-- 2.
-- We take these out as they are not included in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT	location, SUM(CAST(new_deaths as int)) AS total_death_count
FROM	public."CovidDeaths_2022"
WHERE continent IS NULL
			AND location NOT IN ('World', 'European Union', 'International')
			AND Lower(location) NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC;


-- 3.
-- The MAX, population infected percentage, for each location

SELECT	location, population,
		MAX(total_cases) AS highest_infection_count,
		Max((total_cases/population))*100 AS percent_population_infected
FROM public."CovidDeaths_2022"
WHERE Lower(location) NOT LIKE '%income%'
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- 4.
-- The Max, percent of a Population/location Infected, vs Date

SELECT	location, population, date,
		MAX(total_cases) as highest_infection_count,
		Max((total_cases/population))*100 as percent_population_infected
FROM public."CovidDeaths_2022"
--WHERE location LIKE '%States'
GROUP BY location, population, date
ORDER BY percent_population_infected DESC;


-- (Didn't include this query in dashboard)
-- 5) Extra: DAILY PERCENT OF INFECTION per day

SELECT	location, population, cast(date as date), total_cases, new_cases,
		(new_cases/population)*100 as daily_infection_percent
FROM public."CovidDeaths_2022"
WHERE	Lower(location) NOT LIKE '%income%'
	--AND Lower(location) like '%states'
	--and date_trunc('year', cast(date AS date)) = 2020
	--and (EXTRACT(year from cast(date as date)) = 2020)
ORDER BY   date DESC;


--6) NEW:
-- Population Fully Vaccinated
SELECT	vac.continent, vac.location, vac.date,
				COALESCE(vac.people_fully_vaccinated,0) as people_fully_vaccinated,
				dea.population,
				(vac.people_fully_vaccinated/dea.population)* 100 as population_fully_vaccinated_percent
FROM public."CovidVaccinations_2022" vac
JOIN public."CovidDeaths_2022" dea
ON	vac.date = dea.date AND vac.continent = dea.continent
	AND  vac.location = dea.location
WHERE vac.continent IS NOT NULL
--AND lower(vac.location) like '%states'
ORDER BY people_fully_vaccinated DESC;

-- Checking to see if locations like 'low income' doesn't show up from the location column
-- select distinct continent, location
-- from public."CovidVaccinations_2022"
-- WHERE continent IS NOT NULL
-- group by continent, location;
