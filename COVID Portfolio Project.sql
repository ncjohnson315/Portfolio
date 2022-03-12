--All CovidDeath data
SELECT *
FROM PortfolioProject.dbo.CovidDeaths

--Select data we will be using

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Liklihood of dying if you contract covid in the US

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Looking at Total Cases vs Population

SELECT location,date,total_cases,population,(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2

--Look at Countries with Highest Infection Rate to Population

SELECT location,population,MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

--Look at Countries with Highest Death Count

SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Look at CONTINENTS with Highest Death Count

SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location <> 'World' AND location <> 'International' AND location <> 'European Union'
GROUP BY location
ORDER BY TotalDeathCount DESC

--Look at CONTINENTS with Highest Death Count to Population

SELECT location,MAX(total_deaths) AS TotalDeathCount,MAX(population) AS TotalPopulation,(MAX(total_deaths)/MAX(population))*100 AS TotalDeathRate
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location <> 'World' AND location <> 'International' AND location <> 'European Union'
GROUP BY location
ORDER BY TotalDeathRate DESC

--Look at GLOBAL NUMBERS by Date

SELECT date,SUM(new_cases) AS TotalCases,SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC

--Look at TOTAL NUMBERS through Feb. 2022

SELECT SUM(new_cases) AS TotalCases,SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL

--JOIN CovidDeaths with CovidVaccinations

SELECT *
FROM PortfolioProject.dbo.CovidDeaths AS Dea
JOIN PortfolioProject.dbo.CovidVaccinations AS Vac
ON Dea.location = Vac.location AND Dea.date = Vac.date

--Looking at Total Population to Vaccinations

SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
    SUM(Vac.new_vaccinations) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS Dea
JOIN PortfolioProject.dbo.CovidVaccinations AS Vac
ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2,3

--CTE, Rolling percent of population vaccinated

WITH PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
AS
(
    SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
        SUM(Vac.new_vaccinations) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject.dbo.CovidDeaths AS Dea
    JOIN PortfolioProject.dbo.CovidVaccinations AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date
    WHERE Dea.continent IS NOT NULL
    --ORDER BY 2,3
)
SELECT *,(RollingPeopleVaccinated/population)*100
FROM PopvsVac

--Temp table, Rolling percent of population vaccinated

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
        SUM(Vac.new_vaccinations) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject.dbo.CovidDeaths AS Dea
    JOIN PortfolioProject.dbo.CovidVaccinations AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date
    WHERE Dea.continent IS NOT NULL
    --ORDER BY 2,3

SELECT *,(RollingPeopleVaccinated/population)*100 AS PercentPopVaccinated
FROM #PercentPopulationVaccinated
ORDER BY location,date

--Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
        SUM(Vac.new_vaccinations) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject.dbo.CovidDeaths AS Dea
    JOIN PortfolioProject.dbo.CovidVaccinations AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date
    WHERE Dea.continent IS NOT NULL
    --ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated