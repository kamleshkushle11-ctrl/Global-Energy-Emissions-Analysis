CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM EMISSION_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);


SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;


-- 1 What is the total emission per country for the most recent year available?
SELECT country,SUM(emission) AS total_emission
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country
ORDER BY total_emission DESC;


-- 2 What are the top 5 countries by GDP in the most recent year?
SELECT Country, Value AS GDP
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
ORDER BY GDP DESC
LIMIT 5;


-- 3 Compare energy production and consumption by country and year. 
SELECT p.country, p.year, p.energy,
       p.production,
       c.consumption
FROM production p
JOIN consumption c
  ON p.country = c.country
 AND p.year = c.year
 AND p.energy = c.energy
ORDER BY p.country, p.year;

-- 4 Which energy types contribute most to emissions across all countries?

SELECT energy_type,SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;


 -- Trend Analysis Over Time
-- 5 How have global emissions changed year over year?

SELECT year,SUM(emission) AS global_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- 6 What is the trend in GDP for each country over the given years?

SELECT Country, year, Value AS GDP
FROM gdp_3
ORDER BY Country, year;

-- 7 How has population growth affected total emissions in each country?
SELECT e.country,e.year,
    SUM(e.emission) AS total_emission,
    MAX(p.Value) AS population,
    ROUND(SUM(e.emission) / MAX(p.Value), 4) AS emission_per_person
FROM emission_3 e
JOIN population p
    ON e.country = p.countries
   AND e.year = p.year
GROUP BY e.country, e.year
ORDER BY e.country, e.year;

-- 8 Has energy consumption increased or decreased over the years for major economies?

SELECT c.country, c.year, SUM(c.consumption) AS total_consumption
FROM consumption c
WHERE c.country IN (
    SELECT Country
    FROM gdp_3
    WHERE year = (SELECT MAX(year) FROM gdp_3)
    ORDER BY Value DESC
)
GROUP BY c.country, c.year
ORDER BY c.country, c.year;


-- 9 What is the average yearly change in emissions per capita for each country?

SELECT country,
       AVG(per_capita_emission) AS avg_yearly_change
FROM emission_3
GROUP BY country;

-- Ratio & Per Capita Analysis
-- 10 What is the emission-to-GDP ratio for each country by year?
SELECT e.country,e.year,
    SUM(e.emission) AS total_emission,
    MAX(g.Value) AS gdp,
    ROUND(SUM(e.emission) / MAX(g.Value), 6) AS emission_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g
    ON e.country = g.Country
   AND e.year = g.year
GROUP BY e.country, e.year
ORDER BY e.country, e.year;

-- 11 What is the energy consumption per capita for each country over the last decade?
SELECT c.country,c.year,
    SUM(c.consumption) AS total_consumption,
    MAX(p.Value) AS population,
    ROUND(SUM(c.consumption) / MAX(p.Value), 4) AS consumption_per_capita
FROM consumption c
JOIN population p
    ON c.country = p.countries
   AND c.year = p.year
GROUP BY c.country, c.year
ORDER BY c.country, c.year;



-- 12 How does energy production per capita vary across countries?
SELECT pr.country,pr.year,
    SUM(pr.production) AS total_production,
    MAX(p.Value) AS population,
    ROUND(SUM(pr.production) / MAX(p.Value), 4) AS production_per_capita
FROM production pr
JOIN population p
    ON pr.country = p.countries
   AND pr.year = p.year
GROUP BY pr.country, pr.year
ORDER BY pr.country, pr.year;



-- 13 Which countries have the highest energy consumption relative to GDP?

SELECT c.country,c.year,
    SUM(c.consumption) AS total_consumption,
    SUM(g.value) AS total_gdp,
    SUM(c.consumption) / SUM(g.value) AS consumption_gdp_ratio
FROM consumption c
JOIN gdp_3 g
      ON c.country = g.Country
     AND c.year = g.year
GROUP BY c.country, c.year
ORDER BY consumption_gdp_ratio DESC;


-- 14 What is the correlation between GDP growth and energy production growth?

SELECT g.year,
    (g.total_gdp - prev.total_gdp) / NULLIF(prev.total_gdp, 0) * 100 AS gdp_growth_pct
FROM (
    SELECT year, SUM(Value) AS total_gdp
    FROM gdp_3
    GROUP BY year
) g
JOIN (
    SELECT year, SUM(Value) AS total_gdp
    FROM gdp_3
    GROUP BY year
) prev
ON g.year = prev.year + 1
ORDER BY g.year;






 -- Global Comparisons

-- 15 What are the top 10 countries by population and how do their emissions compare?

WITH latest_pop AS (
    SELECT countries AS country, year, value AS population
    FROM population
    WHERE year = (SELECT MAX(year) FROM population)
),
latest_emissions AS (
    SELECT country, SUM(emission) AS total_emissions
    FROM emission_3
    WHERE year = (SELECT MAX(year) FROM emission_3)
    GROUP BY country
)
SELECT p.country,p.population,e.total_emissions,
    ROUND(e.total_emissions / NULLIF(p.population, 0), 6) AS emission_per_capita
FROM latest_pop p
LEFT JOIN latest_emissions e
    ON p.country = e.country
ORDER BY p.population DESC
LIMIT 10;

-- 16 Which countries have improved (reduced) their per capita emissions the most over the last decade?

SELECT country,
       (MAX(per_capita_emission) - MIN(per_capita_emission)) AS emission_change
FROM emission_3
GROUP BY country
ORDER BY emission_change ASC;
WITH per_capita AS (
    SELECT
        e.country,
        e.year,
        SUM(e.emission) / NULLIF(MAX(p.value), 0) AS emission_per_capita
    FROM emission_3 e
    JOIN population p
      ON e.country = p.countries
     AND e.year = p.year
    GROUP BY e.country, e.year
),
compare_years AS (
    SELECT
        pc1.country,
        pc1.emission_per_capita AS recent_value,
        pc2.emission_per_capita AS old_value,
        (pc2.emission_per_capita - pc1.emission_per_capita) AS improvement
    FROM per_capita pc1
    JOIN per_capita pc2
      ON pc1.country = pc2.country
     AND pc2.year = pc1.year - 10
    WHERE pc1.year = (SELECT MAX(year) FROM per_capita)
      AND pc2.emission_per_capita IS NOT NULL
)

SELECT
    country,
    recent_value AS current_per_capita_emission,
    old_value AS per_capita_10yrs_ago,
    improvement AS reduction_amount
FROM compare_years
ORDER BY improvement DESC
LIMIT 10;




-- 17 What is the global share (%) of emissions by country?

SELECT country,
	SUM(emission) AS total_emission,
	SUM(emission) * 100.0 / (SELECT SUM(emission) FROM emission_3) AS global_share_percent
FROM emission_3
GROUP BY country
ORDER BY global_share_percent DESC;


-- 18 What is the global average GDP, emission, and population by year?

SELECT
    y.year,
    ROUND(AVG(y.avg_gdp), 2) AS global_avg_gdp,
    ROUND(AVG(y.avg_emission), 2) AS global_avg_emission,
    ROUND(AVG(y.avg_population), 2) AS global_avg_population
FROM (
    SELECT g.year,AVG(g.value) AS avg_gdp,
        AVG(e.emission) AS avg_emission,
        AVG(p.value) AS avg_population
    FROM gdp_3 g
    JOIN emission_3 e
      ON g.Country = e.country
     AND g.year = e.year
    JOIN population p
      ON g.Country = p.countries
     AND g.year = p.year
    GROUP BY g.year
) y
GROUP BY y.year
ORDER BY y.year;




