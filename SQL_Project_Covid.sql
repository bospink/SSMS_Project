/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Order by 3, 4

--Select *
--From PortfolioProject..CovidVaccinations
--Order by 3, 4

--Select Data that we are going to be using

Select Location, Date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1, 2 --order by location (1) and date (2)

--Looking at Total Cases vs Total Deaths 

--first we need to change the column type of Total_deaths and Total_cases from 'nvarchar' to 'float' so we can calculate and get percentage

ALTER TABLE CovidDeaths ALTER COLUMN total_deaths float;  
GO  

ALTER TABLE CovidDeaths ALTER COLUMN total_cases float;  
GO  
--shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Italy%'
Order by 1,2

--Looking at Total Cases vs Population
-- shows what percentage of population got Covid

SELECT Location, date,  population, total_cases, (total_cases/population) * 100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%Italy%'
Order by 1,2

--Looking at Countries with Highest Infection Rate compared to Polulation 

SELECT Location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%Italy%'
GROUP BY location, population, date
Order by PercentPopulationInfected DESC

--Looking at Continents with Highest Infection Rate compared to Population

--SELECT DISTINCT continent
--FROM PortfolioProject..CovidDeaths
--WHERE continent is not NULL

SELECT DISTINCT continent, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
Order by PercentPopulationInfected DESC


--Showing Countries with Highest Death Count per Population 

SELECT Location, MAX(total_deaths) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is not NULL --to not show results where the Continent name is written instead of Country name
GROUP BY Location
Order by TotalDeathCount DESC

SELECT location, MAX(total_deaths) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is NULL
and location not in ('World','European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
Order by TotalDeathCount DESC

--Let's break things down by Continent
--Showing continents with the highest death count per population

SELECT continent, MAX(total_deaths) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
Order by TotalDeathCount DESC


--GLOBAL NUMBERS

--per day

SELECT date, SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths,
CASE 
	WHEN SUM(new_deaths) = 0
	THEN NULL
	ELSE SUM(new_deaths)/SUM(new_cases)* 100
END as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

--overall across the world (since the data is collected)
SELECT SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths,
CASE 
	WHEN SUM(new_deaths) = 0
	THEN NULL
	ELSE SUM(new_deaths)/SUM(new_cases)* 100
END as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2



SELECT *
FROM PortfolioProject..CovidVaccinations

--JOINING TWO TABLES TOGETHER

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not NULL
Order by 2,3 --location (2) and date (3)

--2 ways of doing the same thing:

--1. USE CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
SELECT dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not NULL
--Order by 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentageVaccinatedPopulation
FROM PopvsVac

--2. USE TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated --we put this DROP table before CREATE table if we want to run this table multiple times or to change something in it and run again
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not NULL
--Order by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentageVaccinatedPopulation
FROM #PercentPopulationVaccinated


--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE View PercentPopulationVaccinated AS 
SELECT dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not NULL
--Order by 2,3

SELECT *
FROM PercentPopulationVaccinated


