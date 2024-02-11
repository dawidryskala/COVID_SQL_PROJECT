Select *
FROM PortfolioProject..CovidDeaths
order by 5,4

Select date, sum(new_cases) as newCases
From PortfolioProject..CovidDeaths
where continent is not null
group by date
--order by 3, 4

Select date, sum(new_cases) as newCases
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by date

--Update PortfolioProject..CovidDeaths
--Set new_deaths = CAST(TRY_CAST(new_deaths AS FLOAT) AS INT)


Select 
	date, 
	new_cases,
	new_deaths,
	Case
		WHEN new_cases = 0 THEN 0
		ELSE new_deaths/new_cases*100
	END
From PortfolioProject..CovidDeaths
where continent is not null
group by date, new_cases, new_deaths
order by date


--Select *
--From PortfolioProject..CovidVaccinations
--order by 3, 4

-- 1) Select data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Update PortfolioProject..CovidDeaths
--Set total_deaths = CAST(TRY_CAST(total_deaths AS FLOAT) AS INT)

--Update PortfolioProject..CovidDeaths
--Set total_cases = CAST(TRY_CAST(total_cases AS FLOAT) AS INT)

-- Funkcja TRY_CAST spróbuje przekonwertowaæ wartoœci w kolumnie nazwa_kolumny na typ FLOAT, który obs³uguje wartoœci z miejscami po przecinku. Nastêpnie, korzystaj¹c z CAST, konwertujemy tê wartoœæ do typu INT, aby uzyskaæ liczbê ca³kowit¹. Ta kombinacja funkcji pozwoli na konwersjê wszystkich wartoœci w kolumnie, nawet jeœli niektóre z nich zawieraj¹ miejsca po przecinku.

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--ALTER TABLE PortfolioProject..CovidDeaths
--ALTER COLUMN total_deaths BIGINT;

--ALTER TABLE PortfolioProject..CovidVaccinations
--ALTER COLUMN new_vaccinations BIGINT;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contaract covid in your country

Select 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths * 1.0/total_cases) *100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
Where 
	location like '%Poland' AND
	continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select 
	location, 
	date,
	population,
	total_cases,
	(total_cases *1.0/population)*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%Poland%' 
where continent is not null
order by 1,2


-- Looking at Countries with Highest Infextion Rate compared to Population

Select 
	location, 
	population,
	MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases *1.0/population))*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%Poland%' 
where continent is not null
Group by location, population
order by PercentagePopulationInfected desc


-- Showing Countries with Highest Death Count per Population

Select 
	location, 
	MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Poland%' 
where continent is not null
Group by location 
order by TotalDeathCount desc


-- Let's break things down by continent

Select 
	location, 
	MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Poland%' 
where
	location not like '%income%' AND
	continent is null 
Group by location 
order by TotalDeathCount desc

-- Showing continents with th ehighest death count per population

Select 
	continent, 
	MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null 
Group by continent 
order by TotalDeathCount desc


-- GLOBAL NUMBERS per week

Select 
	--date, 
	sum(new_cases) as TotalCases,
	sum(cast(new_deaths as int)) as TotalDeaths,
	CASE
        WHEN sum(new_cases) = 0 THEN 0
        ELSE sum(cast(new_deaths as int)) / sum(new_cases) * 100
    END AS DeathPercentage

FROM PortfolioProject..CovidDeaths
Where 
	continent is not null
--group by date
having 
	sum(new_cases) >= sum(cast(new_deaths as int)) and 
	sum(new_cases) > 0
--order by date

-- 50:31 

-- Looking at Total Population vs Vaccinations

--Update PortfolioProject..CovidVaccinations
--Set	new_vaccinations  = CAST(TRY_CAST(new_vaccinations AS FLOAT) AS INT)

--ALTER TABLE PortfolioProject..CovidVaccinations
--ALTER COLUMN new_vaccinations BIGINT;

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location , dea.Date) as RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where 
	dea.continent is not null --and 
	--dea.location like '%Poland%' and 
	--vac.new_vaccinations is not null
order by 2,3


-- USE CTE

With PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location , dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where 
	dea.continent is not null --and 
	--dea.location like '%Poland%' --and 
	--vac.new_vaccinations is not null
--order by 2,3
)

Select *, (RollingPeopleVaccinated/Population) *100 
FROM PopVsVac


-- TEMP TABLE 

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location , dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where 
	dea.continent is not null --and 
	--dea.location like '%Poland%' --and 
	--vac.new_vaccinations is not null
order by 2,3

Select *, (RollingPeopleVaccinated/Population) *100 
FROM #PercentPopulationVaccinated




-- Creating View to store data for late visualizations

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location , dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where 
	dea.continent is not null --and 
	--dea.location like '%Poland%' --and 
	--vac.new_vaccinations is not null
--order by 2,3

Select *
FROM PercentPopulationVaccinated