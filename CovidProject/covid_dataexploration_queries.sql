/*
Covid 2022 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions(PARTITION, COALESCE,etc), Aggregate Functions,
						Creating Views, Converting Data Types, 

*/

SELECT COUNT(index)
FROM public."CovidDeaths";


-- 1)	Data that we are going to be starting with

SELECT	Location, date, total_cases, new_cases, total_deaths, population
FROM 	public."CovidDeaths"
WHERE 	continent is not null
ORDER BY 1,2;


-- 2)	Total Cases vs Total Deaths
--		Shows likelihood of dying if you contract covid in your country

SELECT 	location, date, total_cases,total_deaths,
		(total_deaths/total_cases)*100 as DeathPercentage
FROM 	public."CovidDeaths"
WHERE  	LOWER(location) LIKE '%states%' and(continent is not null)
ORDER 	BY 1,2;


-- 3)	Total Cases vs Population
--		Shows what percentage of population infected with Covid, per day

SELECT 	Location, date, Population,
		total_cases,  (total_cases/population)*100 as PercentPopulationInfected
FROM 	public."CovidDeaths"
--WHERE location ILIKE '%states%'
ORDER BY 1,2;


-- 4)	Countries, using their Highest Infection Rate, compared to population

SELECT	location, MAX(total_cases) as highest_infection_count,
		population, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM 	public."CovidDeaths"
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- 5)	Countries with the Highest Death Count per Population
--		Using CTE, to use the ALIAS in the where clause

WITH temp1 as (
	SELECT location,
		MAX(cast(total_deaths as bigint)  ) as TotalDeathCount
	FROM public."CovidDeaths"
	WHERE continent IS NOT NULL
	GROUP BY  location
)
SELECT 	location, TotalDeathCount -- Can just use *, to avoid redundancy
FROM 	temp1
WHERE	(TotalDeathCount IS NOT NULL)
ORDER BY TotalDeathCount DESC;



-- 6) 	By continent: Showing contintents with the highest death count per population
--		Using CTE, and than Window functions

WITH ConDeaths AS
(	SELECT	continent, location,
		MAX(cast(total_deaths as bigint)) as TotalDeathCount
			--OVER (PARTITION BY continent, location ) as TotalDeathCount
	FROM public."CovidDeaths"
	WHERE (continent IS NOT NULL)
 	GROUP BY continent, location
)
SELECT continent, SUM(TotalDeathCOUNT) as TotalContinentDeath
FROM ConDeaths
WHERE TotalDeathCount IS NOT NULL
GROUP BY continent
ORDER BY ContinentDeath DESC;



-- 7) 	Global Numbers

--		Using CTE for readability
WITH T2 AS (
	SELECT	 SUM(cast(new_cases as bigint)) as total_cases,
			SUM(cast(new_deaths as bigint)) as total_deaths
	FROM 	public."CovidDeaths"
	WHERE 	continent IS NOT NULL
)
SELECT 	total_cases, total_deaths,
		(total_deaths/total_cases)*100 as DeathPercentage
FROM 	T2
ORDER BY 1,2;


--Alternate (7)
SELECT 	SUM(cast(new_cases as bigint)) as total_cases,
		SUM(cast(new_deaths as bigint)) as total_deaths,
		(SUM(cast(new_deaths as bigint))/SUM(cast(new_cases as bigint)))*100 as DeathPercentage
FROM	public."CovidDeaths"
WHERE	continent is not null
ORDER BY 1,2;



-- 8)  	Total Population vs Vaccinations
-- 		Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT * FROM public."CovidVaccination_2021" LIMIT 400;

SELECT 	dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location
			ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM public."CovidDeaths" dea
JOIN public."CovidVaccination_2021" vac
	ON 	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- 9)	Using CTE to perform Calculation on Partition By in previous query
--		Percentage of Rolling people vaccinated vs the Population

WITH PopvsVac AS (
SELECT 	dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int))
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM public."CovidDeaths" dea
JOIN public."CovidVaccination_2021" vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 As PercentPeopleVaccinated
FROM PopvsVac;


-- 10)	Creating a TEMP TABLE, an alternate to the CTE version,
-- 		of Rolling people vaccinated vs the Population


--- (10) Using TEMP TABLE for PostgresTempTable

DROP TABLE if exists PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated AS
SELECT 	dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int))
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM public."CovidDeaths" dea
JOIN public."CovidVaccination_2021" vac
ON dea.location = vac.location and dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/population)*100 As percent_people_vaccinated
FROM PercentPopulationVaccinated;



-- 11) Creating a VIEW TABLE, for Rolling PPl Vaccinated vs Population

CREATE VIEW IF NOT EXISTS PercentPopulationVaccinated AS
(SELECT 	dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int))
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM public."CovidDeaths" dea
JOIN public."CovidVaccination_2021" vac
ON dea.location = vac.location and dea.date = vac.date);

-- Deletes the view

DROP VIEW public.PercentPopulationVaccinated CASCADE;
