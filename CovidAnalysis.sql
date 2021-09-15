SELECT * 
FROM Project#1..CovidDeaths
ORDER BY 3,4;

SELECT *
FROM Project#1..CovidVaccinations
ORDER BY 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Project#1..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2;

-- Total Cases vs Total Deaths (Likelihood of dying if you contract covid in India)
SELECT Location, date, total_cases,total_deaths, ROUND((total_deaths/total_cases)*100,2) as DeathPercentage
FROM Project#1..CovidDeaths
WHERE location like '%India'
ORDER BY 1,2;

-- Total Cases vs Population (Percentage of population infected with covid in India)
SELECT Location, date, Population, total_cases,  ROUND((total_cases/population)*100,2) as PopulationInfectedPercentage
FROM Project#1..CovidDeaths
WHERE location like '%India'
ORDER BY 1,2;

-- Top 10 countries with highest Infection Rate per Population
SELECT TOP(10) Location, Population, MAX(total_cases) AS HighestInfectionCount,  ROUND(Max((total_cases/population))*100,2) as PopulationInfectedPercentage
FROM Project#1..CovidDeaths
GROUP BY Location, Population
ORDER BY PopulationInfectedPercentage DESC;

-- Top 10 countries with highest Death Rate per Population
SELECT TOP(10) Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM Project#1..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Top 3 contintents with the highest death count per population.
SELECT TOP(3) continent, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM Project#1..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Total Population vs Vaccinations (Percentage of people vaccinated)
SELECT cv.continent, cv.location, cv.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (PARTITION BY cd.Location Order by cd.location, cd.Date)  as RollingPeopleVaccinated
FROM Project#1..CovidDeaths cd
JOIN Project#1..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cv.continent is not null 
ORDER BY 2,3;

-- Using CTE to perform calculation
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cv.continent, cv.location, cv.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (PARTITION BY cd.Location Order by cd.location, cd.Date)  as RollingPeopleVaccinated
FROM Project#1..CovidDeaths cd
JOIN Project#1..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cv.continent is not null
)


SELECT continent, population, Round((RollingPeopleVaccinated/population),2)*100 as PercentVaccinated
FROM PopvsVac


-- Creting a Temp table.

DROP Table if exists #PercentageVaccinated
CREATE TABLE #PercentageVaccinated
(
Continent nvarchar(250),
Location nvarchar(250),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentageVaccinated
SELECT cv.continent, cv.location, cv.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (PARTITION BY cd.Location Order by cd.location, cd.Date)  as RollingPeopleVaccinated
FROM Project#1..CovidDeaths cd
JOIN Project#1..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cv.continent is not null ;

SELECT *
FROM #PercentageVaccinated;


-- Creating View to store data for further use.

CREATE VIEW PercentageVaccinated as
SELECT cv.continent, cv.location, cv.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (PARTITION BY cd.Location Order by cd.location, cd.Date)  as RollingPeopleVaccinated
FROM Project#1..CovidDeaths cd
JOIN Project#1..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cv.continent is not null ;
