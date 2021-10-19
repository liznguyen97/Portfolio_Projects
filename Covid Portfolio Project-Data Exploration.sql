/*
Covid 19 Data Exploration

Skills Used: Joins, Aggregate Functions, Window Functions, Converting Data Types, Temp Tables, CTE, VIEW
*/

-- Downloaded data from www.ourworldindata.org/coronavirus
-- Created two tables (Covid Deaths and Covid Vaccinations) on Excel and imported into SQL server


-- Data on Covid deaths and vaccinations in each country daily since beginning of 2020
---- Ordered by location (country), then date
---- WHERE continent is NULL, it shows worldwide and each continent data
SELECT *
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM [Portfolio Project].dbo.CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4



-- Select data we are starting with
SELECT location, date, new_cases, total_cases, new_deaths, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- 1) Total Cases vs Total Deaths 
---- Shows likelihood of dying if you contract Covid in your country (USA)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE '%States%'
and continent IS NOT NULL
ORDER BY 1,2



-- 2) Total Cases vs Population (USA)
---- Shows what percentage of the population infected by Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE '%States%'
and continent IS NOT NULL
ORDER BY 1,2



-- 3) Countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount,
	   MAX((total_cases)/population)*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 desc



-- 4) Population with Highest Death Count Per Population
---- total_deaths column data type was a string 
---- Must convert into int with either a CAST or CONVERT function
SELECT location, population, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount desc 



-- BREAKING THINGS DOWN BY CONTINENT

-- 5) Showing contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount desc 


-- 6) Global Numbers
---- Percentage of people who contracted covid and died in the world
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	   SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- 7) Total Population vs Vaccinations
-- Shows rolling count of population vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 



-- 8) Using CTE to perform Calculation on Partition By in previous query
-- Shows Percentage of Population that has received at least one Covid Vaccine
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

Select *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
From PopvsVac



-- 9) Using TEMP TABLE to perform Calculation on Partition By in previous query
DROP TABLE if exists #PercentPopulationVacinnated
CREATE TABLE #PercentPopulationVacinnated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVacinnated
SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
	    SUM(CONVERT(int,new_vaccinations)) OVER (Partition by dea.location Order by
		dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
FROM #PercentPopulationVacinnated




-- 10) Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVacinnated as
SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
	    SUM(CONVERT(int,new_vaccinations)) OVER (Partition by dea.location Order by
		dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
