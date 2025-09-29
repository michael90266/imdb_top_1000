SELECT *
FROM top_movies.imdb_1000;

-- Create staging table
CREATE TABLE top_movies.imdb_1000_staging
SELECT *
FROM top_movies.imdb_1000;

SELECT *
FROM top_movies.imdb_1000_staging;

-- Add ranking column
ALTER TABLE top_movies.imdb_1000_staging
ADD COLUMN ranking INT;

SET @row_num = 0;

UPDATE top_movies.imdb_1000_staging
SET ranking = (@row_num := @row_num + 1);

SET SQL_SAFE_UPDATES = 0;

-- Remove parenthesis from release_year
UPDATE top_movies.imdb_1000_staging
SET release_year = SUBSTRING(release_year, 2, 4);

SELECT *
FROM top_movies.imdb_1000_staging;

-- modify release year into integer
ALTER TABLE top_movies.imdb_1000_staging
MODIFY COLUMN release_year INT;

-- Adjust errors in release year
UPDATE top_movies.imdb_1000_staging
SET release_year = '2018'
WHERE release_year = 'II) ';

UPDATE top_movies.imdb_1000_staging
SET release_year = '2018'
WHERE release_year = 'III)';

-- Remove units from gross column
UPDATE top_movies.imdb_1000_staging
SET gross = REPLACE(REPLACE(gross, '$',''),'M','');

-- Modify gross into double
ALTER TABLE top_movies.imdb_1000_staging
MODIFY COLUMN gross DOUBLE;

-- Rename gross to more descriptive name that accounts for units
ALTER TABLE top_movies.imdb_1000_staging
RENAME COLUMN gross to domestic_gross_box_office_m;

UPDATE top_movies.imdb_1000_staging
SET runtime = REPLACE(runtime, ' min','');

ALTER TABLE top_movies.imdb_1000_staging
MODIFY COLUMN runtime int;

ALTER TABLE top_movies.imdb_1000_staging
RENAME COLUMN runtime to runtime_min;

ALTER TABLE top_movies.imdb_1000_staging
RENAME COLUMN rating to imdb_rating;

UPDATE top_movies.imdb_1000_staging
SET metascore = NULL
WHERE metascore = 0;

UPDATE top_movies.imdb_1000_staging
SET domestic_gross_box_office_m = NULL
WHERE domestic_gross_box_office_m = 0;

-- Adjust for inflation using Consumer Price Index (CPI)
SELECT MAX(release_year)
FROM top_movies.imdb_1000_staging;
-- 2023 base

-- Import and adjust CPI table 
-- Sources: 
-- https://fred.stlouisfed.org/series/CPIAUCSL for 1947-2025 
-- https://www.minneapolisfed.org/about-us/monetary-policy/inflation-calculator/consumer-price-index-1913- for 1921-1946
SELECT *
FROM inflation.cpi;

CREATE TABLE inflation.cpi_staging
SELECT
	YEAR(observation_date) AS years,
	AVG(CPIAUCSL) AS avg_cpi
FROM inflation.cpi
GROUP BY 1;

CREATE TABLE top_movies.imdb_1000_staging2
SELECT 
	i.ranking,
    i.title,
    i.director,
    i.release_year,
    i.runtime_min,
    i.genre,
    i.imdb_rating,
    i.metascore,
    i.domestic_gross_box_office_m,
    ROUND(i.domestic_gross_box_office_m * (304.70416666666665 / COALESCE(c.avg_cpi, 
			CASE i.release_year
                WHEN 1921 THEN 17.9
                WHEN 1922 THEN 16.8
                WHEN 1923 THEN 17.1
                WHEN 1924 THEN 17.1
                WHEN 1925 THEN 17.5
                WHEN 1926 THEN 17.7
                WHEN 1927 THEN 17.4
                WHEN 1928 THEN 17.2
                WHEN 1929 THEN 17.2
                WHEN 1930 THEN 16.7
                WHEN 1931 THEN 15.2
                WHEN 1932 THEN 13.6
                WHEN 1933 THEN 12.9
                WHEN 1934 THEN 13.4
                WHEN 1935 THEN 13.7
                WHEN 1936 THEN 13.9
                WHEN 1937 THEN 14.4
                WHEN 1938 THEN 14.1
                WHEN 1939 THEN 13.9
                WHEN 1940 THEN 14.0
                WHEN 1941 THEN 14.7
                WHEN 1942 THEN 16.3
                WHEN 1943 THEN 17.3
                WHEN 1944 THEN 17.6
                WHEN 1945 THEN 18.0
                WHEN 1946 THEN 19.5
                ELSE NULL
            END
			)
		), 
	2) AS dom_gross_adj_m
FROM top_movies.imdb_1000_staging i
LEFT JOIN inflation.cpi_staging c 
	ON c.years = i.release_year
;

-- Check if all values filled
SELECT *
FROM top_movies.imdb_1000_staging2
WHERE dom_gross_adj_m IS NULL
AND domestic_gross_box_office_m IS NOT NULL;

-- Used to identify years not filled by inflation.cpi table
SELECT DISTINCT(release_year) 
FROM top_movies.imdb_1000_staging2
WHERE dom_gross_adj_m IS NULL
AND domestic_gross_box_office_m IS NOT NULL
ORDER BY 1;

-- Seperate genres and save final cleaned and prepped table
CREATE TABLE top_movies.imdb_1000_clean
SELECT 
	ranking, 
    title, 
    director, 
    release_year, 
    runtime_min,  
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(genre, ',', n.n), ',', -1)) AS genre, 
    imdb_rating, 
    metascore, 
    domestic_gross_box_office_m,
    dom_gross_adj_m
FROM top_movies.imdb_1000_staging2
JOIN (
    SELECT 1 AS n UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5 UNION ALL
    SELECT 6
) n
  ON n.n <= 1 + LENGTH(genre) - LENGTH(REPLACE(genre, ',', ''));

SELECT *
FROM top_movies.imdb_1000_clean;