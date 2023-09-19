-- Exploratory Data Analysis of Covid-19 Deaths and Vaccinations Showcasing Basic to Advanced SQL Functions

-- Dataset: 
SELECT *
FROM [Project Portfolio].dbo.CovidDeaths$
ORDER BY location, date

SELECT *
FROM [Project Portfolio].dbo.CovidVaccinations$


-- A. Looking at the Total cases vs Total deaths
-- Shows the likelihood of dying if you contract covid in your country
SELECT 
  location, 
  date,
  population,
  total_cases, 
  total_deaths, 
 (total_deaths/total_cases)*100 AS death_percentage,
 (total_cases/population) *100 AS infection_vs_population
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE 
  continent is NOT NULL --if the continent is NULL, the location that will be displayed is the continent
ORDER BY location, date

-- B. Looking at the Total Cases vs the Population
-- Shows what percentage of population have gotten covid
SELECT 
  location, 
  date, 
  population,
  total_cases,  
  ROUND((total_cases/population)*100, 10)AS infection_percentage
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE location = 'Philippines' AND 
continent IS NOT NULL
ORDER BY location, date


-- C. Looking at countries with highest infection rate compared to population
-- using MAX function
SELECT 
  location, 
  population,
  MAX(total_cases) AS highest_infection,
  MAX((total_cases/population))*100 AS infection_percentage
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_percentage desc


-- D. Showing the Countries with the highest Death count per population
SELECT
  location,
  MAX(CAST(total_deaths AS int)) AS total_death_count
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent IS NOT NULL -- because if the continent is NULL, the location entry will be the corresponding continent
GROUP BY location, population
ORDER BY total_death_count desc

-- Checking the CovidDeaths$ table: 
SELECT *
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent is not null -- since location are filled up as continent when the continent is NULL
order by 3,4 


-- E. Breaking it down by continent
SELECT
  continent,
  MAX(total_deaths) AS max_total_deaths
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY max_total_deaths desc
-- the above query is wrong because the number for North America is not collective

-- Trying again the previous query by location but continent is null, 
-- because if the continent is NULL, the location entry will be the corresponding continent
SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent IS NULL 
GROUP BY location
ORDER BY total_death_count desc
-- The above query is more accurate since it is more collective

-- Showing the continents with the highest death
SELECT
  continent,
  MAX(total_deaths) AS total_death_count
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY total_death_count desc


-- F. GLOBAL NUMBERS
SELECT
  -- date,
  SUM(new_deaths) AS total_new_deaths,
  SUM(new_cases) AS total_new_cases,
  (SUM(new_deaths)/SUM(new_cases)) * 100 AS death_percentage
FROM [Project Portfolio].dbo.CovidDeaths$
WHERE
  new_cases is NOT NULL AND
  continent IS NOT NULL
--GROUP BY date 
ORDER BY 1, 2


-- G. JOINING THE TWO TABLES BY LOCATION AND BY DATE

SELECT *
FROM [Project Portfolio].dbo.CovidDeaths$ AS deaths
JOIN [Project Portfolio].dbo.CovidVaccinations$ AS vacc
  ON deaths.location = vacc.location 
  AND deaths.date = vacc.date


-- H. LOOKING AT TOTAL POPULATION VS NEWS VACCINATIONS PER DAY, BREAKING IT BY LOCATION
SELECT
  deaths.location,
  deaths.date,
  deaths.population,
  vacc.new_vaccinations,
  SUM(CAST(vacc.new_vaccinations AS bigint)) 
  OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 
  AS rolling_people_vaccinated
FROM [Project Portfolio].dbo.CovidDeaths$ AS deaths
JOIN [Project Portfolio].dbo.CovidVaccinations$ AS vacc
  ON deaths.location = vacc.location
  AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 
ORDER BY location, date


-- TO GET THE PERCENTAGE OF THE VACCINATED PEOPLE VS THE POPULATION
-- You cannot use the newly made rolling_people_vaccinated column in the formula
-- so you need to use CTE or temp table


-- 1. USING CTE
-- number of columns in the CTE should be the same as
-- the number of columns in the SELECT STATEMENT
WITH CTE_pop_vs_vacc 
( continent,
  location, 
  date,
  population,
  new_vaccinations,
  rolling_people_vaccinated
)
AS
(SELECT
  deaths.continent,
  deaths.location,
  deaths.date,
  deaths.population,
  vacc.new_vaccinations,
  SUM(CAST(vacc.new_vaccinations AS bigint))
  OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 
  AS rolling_people_vaccinated
FROM [Project Portfolio].dbo.CovidDeaths$ AS deaths
JOIN [Project Portfolio].dbo.CovidVaccinations$ AS vacc
  ON deaths.location = vacc.location
  AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, 
  (rolling_people_vaccinated/population) * 100 AS percentage_vaccinated
FROM CTE_pop_vs_vacc 



-- USING TEMPORARY TABLE
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #percent_population_vaccinated
SELECT
  deaths.continent,
  deaths.location,
  deaths.date,
  deaths.population,
  vacc.new_vaccinations,
  SUM(CAST(vacc.new_vaccinations AS bigint))
  OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 
  AS rolling_people_vaccinated
FROM [Project Portfolio].dbo.CovidDeaths$ AS deaths
JOIN [Project Portfolio].dbo.CovidVaccinations$ AS vacc
  ON deaths.location = vacc.location
  AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 

-- To check if the above query was executed: 
SELECT *, 
  (rolling_people_vaccinated/population) * 100 AS percentage_vaccinated
FROM #percent_population_vaccinated



-- CREATING VIEW
CREATE VIEW percent_population_vaccinated AS
SELECT
  deaths.continent,
  deaths.location,
  deaths.date,
  deaths.population,
  vacc.new_vaccinations,
  SUM(CAST(vacc.new_vaccinations AS bigint)) 
  OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 
  AS rolling_people_vaccinated
FROM [Project Portfolio].dbo.CovidDeaths$ AS deaths
JOIN [Project Portfolio].dbo.CovidVaccinations$ AS vacc
  ON deaths.location = vacc.location
  AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 
--ORDER BY 2,3

