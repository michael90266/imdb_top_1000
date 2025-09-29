SELECT *
FROM top_movies.imdb_1000_clean;

-- General averages
SELECT 
	ROUND(AVG(release_year), 0) AS avg_year,
	ROUND(AVG(runtime_min), 0) AS avg_runtime,
	ROUND(AVG(imdb_rating), 1) AS avg_rating,
    ROUND(AVG(metascore), 0) AS avg_metascore,
    ROUND(AVG(dom_gross_adj_m), 2) AS avg_gross_adj
FROM top_movies.imdb_1000_clean;

-- Most common genres
SELECT
	genre,
    COUNT(*) AS frequency
FROM top_movies.imdb_1000_clean
GROUP BY genre
ORDER BY 2 DESC;

-- Frequency by decade
SELECT
	TRUNCATE(release_year, -1) as decade,
    COUNT(*) AS frequency
FROM top_movies.imdb_1000_clean
GROUP BY decade
ORDER BY 2 DESC;

-- Average imdb rating by decade (x10 for easier comparison with metascore)
SELECT
	TRUNCATE(release_year, -1) as decade,
    COUNT(*) AS frequency,
    ROUND(AVG(imdb_rating) * 10, 2) AS avg_imdb_rating
FROM top_movies.imdb_1000_clean
GROUP BY decade
ORDER BY 3 DESC;

-- Average metascore by decade
SELECT
	TRUNCATE(release_year, -1) as decade,
    COUNT(*) AS frequency,
    ROUND(AVG(metascore), 2) AS avg_metascore
FROM top_movies.imdb_1000_clean
GROUP BY decade
ORDER BY 3 DESC;

-- Average runtime by decade
SELECT
	TRUNCATE(release_year, -1) as decade,
    COUNT(*) AS frequency,
    ROUND(AVG(runtime_min), 0) AS avg_runtime
FROM top_movies.imdb_1000_clean
GROUP BY decade
ORDER BY 3 DESC;

-- Average gross domestic box office adjusted by decade with general frequency
SELECT
	TRUNCATE(release_year, -1) as decade,
    ROUND(AVG(dom_gross_adj_m), 2) AS avg_gross_adj,
    COUNT(*) AS frequency
FROM top_movies.imdb_1000_clean
GROUP BY decade
ORDER BY 2 DESC;

-- Closer look at 1930s movies
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 1930
GROUP BY ranking
ORDER BY 4 DESC;

-- Box office percentage for top 5 grossing decades
-- Gone With The wind and Snow White acount for majority gross in 1930s
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m,
    CONCAT(
        ROUND(dom_gross_adj_m * 100.0 / SUM(dom_gross_adj_m) OVER (), 2),
        '%'
    ) AS percent_box_office
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 1930 AND domestic_gross_box_office_m IS NOT NULL
GROUP BY ranking
ORDER BY 4 DESC;

-- Sound of Music acounts for majority gross in 1960s but much more even spread
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m,
    CONCAT(
        ROUND(dom_gross_adj_m * 100.0 / SUM(dom_gross_adj_m) OVER (), 2),
        '%'
    ) AS percent_box_office
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 1960 AND domestic_gross_box_office_m IS NOT NULL
GROUP BY ranking
ORDER BY 4 DESC;

-- Spider-Man: No Way Home acounts for majority gross in 2020s but not by much
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m,
    CONCAT(
        ROUND(dom_gross_adj_m * 100.0 / SUM(dom_gross_adj_m) OVER (), 2),
        '%'
    ) AS percent_box_office
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 2020 AND domestic_gross_box_office_m IS NOT NULL
GROUP BY ranking
ORDER BY 4 DESC;

-- Star Wars: Episode IV - A New Hope account and The Exorcist account for majority gross in 1970s but close spread
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m,
    CONCAT(
        ROUND(dom_gross_adj_m * 100.0 / SUM(dom_gross_adj_m) OVER (), 2),
        '%'
    ) AS percent_box_office
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 1970 AND domestic_gross_box_office_m IS NOT NULL
GROUP BY ranking
ORDER BY 4 DESC;

--  Empire Strikes Back and E.T. account for majority gross in 1980s but closer spread
SELECT
	title,
	release_year,
    domestic_gross_box_office_m,
    dom_gross_adj_m,
    CONCAT(
        ROUND(dom_gross_adj_m * 100.0 / SUM(dom_gross_adj_m) OVER (), 2),
        '%'
    ) AS percent_box_office
FROM top_movies.imdb_1000_clean
WHERE TRUNCATE(release_year, -1) = 1980 AND domestic_gross_box_office_m IS NOT NULL
GROUP BY ranking
ORDER BY 4 DESC;

-- Average gross of top 5 highest grossing movies of each decade 
SELECT
	TRUNCATE(release_year, -1) AS decade,
    CASE WHEN rank_in_decade = 1 THEN title END AS highest_gross_movie,
    ROUND(AVG(domestic_gross_box_office_m), 2) AS avg_top5_gross,
	ROUND(AVG(dom_gross_adj_m), 2) AS avg_top5_gross_adj
FROM
(
	SELECT
		title,
		release_year,
        domestic_gross_box_office_m,
		dom_gross_adj_m,
		DENSE_RANK() OVER(
			PARTITION BY TRUNCATE(release_year, -1)
			ORDER BY dom_gross_adj_m DESC
		) AS rank_in_decade
	FROM top_movies.imdb_1000_clean
    GROUP BY ranking
) AS ranked_movies
WHERE rank_in_decade <= 5
GROUP BY 1
ORDER BY 4 DESC;

-- Top movies and their contribution to top 5 domestic grossing movies of each decade
WITH ranked_movies AS
(
	SELECT
		title,
		release_year,
		dom_gross_adj_m,
        TRUNCATE(release_year, -1) AS decade,
		ROW_NUMBER() OVER(
			PARTITION BY TRUNCATE(release_year, -1)
			ORDER BY dom_gross_adj_m DESC, ranking ASC
		) AS rank_in_decade
	FROM top_movies.imdb_1000_clean
    WHERE dom_gross_adj_m IS NOT NULL
    GROUP BY ranking
)
SELECT
	decade,
    MAX(CASE WHEN rank_in_decade = 1 THEN title END) AS highest_gross_movie,
    MAX(CASE WHEN rank_in_decade = 1 THEN dom_gross_adj_m END) AS top_movie_gross_adj,
	ROUND(SUM(dom_gross_adj_m), 2) AS sum_top5_gross_adj,
    CONCAT(ROUND(CASE WHEN rank_in_decade = 1 THEN dom_gross_adj_m END * 100.0 / SUM(dom_gross_adj_m), 2), '%') AS movie_percent_top_5
FROM ranked_movies
WHERE rank_in_decade <= 5
GROUP BY 1
ORDER BY 4 DESC;

-- -- Top movies and their contribution to total domestic grossing movies of each decade
SELECT 
	TRUNCATE(release_year, -1) AS decade, 
    CASE WHEN rank_in_decade = 1 THEN title END AS highest_gross_movie, 
    CASE WHEN rank_in_decade = 1 THEN dom_gross_adj_m END AS top_movie_gross_adj, 
    ROUND(SUM(dom_gross_adj_m), 2) AS sum_gross_adj, 
    CONCAT(ROUND(CASE WHEN rank_in_decade = 1 THEN dom_gross_adj_m END * 100 / SUM(dom_gross_adj_m), 2), '%') AS movie_percent_box_office 
FROM 
( 
	SELECT 
		title, 
		release_year, 
		domestic_gross_box_office_m, 
		dom_gross_adj_m, 
        DENSE_RANK() OVER(
			PARTITION BY TRUNCATE(release_year, -1) ORDER BY dom_gross_adj_m DESC 
		) AS rank_in_decade 
        FROM top_movies.imdb_1000_clean 
        GROUP BY ranking
) AS ranked_movies 
GROUP BY 1 
ORDER BY 3 DESC;

-- Directors, movies, and their gross sum and highest grossing movie
SELECT
	director,
    COUNT(title) AS number_of_movies,
    CASE WHEN director_rank = 1 THEN title END AS highest_gross_movie,
    CASE WHEN director_rank = 1 THEN dom_gross_adj_m END AS top_movie_gross_adj,
	ROUND(SUM(dom_gross_adj_m), 2) AS sum_director_gross_adj,
	CONCAT(ROUND(CASE WHEN director_rank = 1 THEN dom_gross_adj_m END * 100 / SUM(dom_gross_adj_m), 2), '%') AS movie_percent_gross
FROM
(
	SELECT
		title,
		director,
        domestic_gross_box_office_m,
		dom_gross_adj_m,
		DENSE_RANK() OVER(
			PARTITION BY director
			ORDER BY dom_gross_adj_m DESC
		) AS director_rank
	FROM top_movies.imdb_1000_clean
    GROUP BY ranking
) AS director_ranked_movies
WHERE dom_gross_adj_m IS NOT NULL
GROUP BY 1
ORDER BY 5 DESC;

-- Compare imdb score to metascore
SELECT 
	ranking,
    title,
    imdb_rating * 10 AS imdb_rating_adj,
    metascore,
    CASE 
		WHEN imdb_rating * 10 - metascore LIKE '-%' THEN (imdb_rating * 10 - metascore) * -1
        ELSE imdb_rating * 10 - metascore 
	END AS score_difference
FROM top_movies.imdb_1000_clean
WHERE metascore IS NOT NULL
GROUP BY ranking
ORDER BY 1;

-- Rank by highest scoring between imdb rating and metascore
SELECT
	ROW_NUMBER() OVER(ORDER BY (imdb_rating * 10 + metascore) / 2 DESC, ranking ASC) AS new_ranking,
	ranking AS original_ranking,
	title,
	director,
	release_year,
	ROUND((imdb_rating * 10 + metascore) / 2, 2) AS combined_rating
FROM top_movies.imdb_1000_clean
WHERE metascore IS NOT NULL
GROUP BY ranking;

-- Highest rated decades with new rating
WITH new_rating AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY (imdb_rating * 10 + metascore) / 2 DESC, ranking ASC) AS new_ranking,
		ranking AS original_ranking,
		title,
		director,
		release_year,
		ROUND((imdb_rating * 10 + metascore) / 2, 2) AS combined_rating
	FROM top_movies.imdb_1000_clean
	WHERE metascore IS NOT NULL
	GROUP BY ranking
)
SELECT 
	TRUNCATE(release_year, -1) as decade,
    ROUND(AVG(combined_rating), 1) AS avg_combined_rating
FROM new_rating
GROUP BY decade
ORDER BY 2 DESC;

-- Compare the original decade ranking
WITH t1 AS
(
	WITH new_rating AS
	(
		SELECT
			ROW_NUMBER() OVER(ORDER BY (imdb_rating * 10 + metascore) / 2 DESC, ranking ASC) AS new_ranking,
			ranking AS original_ranking,
			title,
			director,
			release_year,
			ROUND((imdb_rating * 10 + metascore) / 2, 2) AS combined_rating
		FROM top_movies.imdb_1000_clean
		WHERE metascore IS NOT NULL
		GROUP BY ranking
	)
	SELECT 
		title,
		TRUNCATE(release_year, -1) as decade,
		ROUND(AVG(combined_rating), 1) AS avg_combined_rating,
        ROW_NUMBER() OVER (ORDER BY AVG(combined_rating) DESC) AS row_num
	FROM new_rating
	GROUP BY decade
),
t2 AS
(
	SELECT
		TRUNCATE(release_year, -1) as decade,
		ROUND(AVG(imdb_rating)*10, 1) AS avg_imdb_rating,
        ROW_NUMBER() OVER (ORDER BY AVG(imdb_rating) DESC) AS row_num
	FROM top_movies.imdb_1000_clean
	GROUP BY decade
),
t3 AS
(
	SELECT
		TRUNCATE(release_year, -1) as decade,
		ROUND(AVG(metascore), 1) AS avg_metascore,
        ROW_NUMBER() OVER (ORDER BY avg(metascore) DESC) AS row_num
	FROM top_movies.imdb_1000_clean
	GROUP BY decade
),
t4 AS
(
	SELECT
		TRUNCATE(release_year, -1) as decade,
		genre,
		COUNT(*) AS frequency,
		ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_num
	FROM top_movies.imdb_1000_clean
	GROUP BY genre
)
SELECT
	t1.decade,
	t1.avg_combined_rating,
    t4.genre AS top_combined_genre,
    t2.decade,
    t2.avg_imdb_rating,
    t4.genre AS top_imdb_genre,
    t3.decade,
    t3.avg_metascore,
    t4.genre AS top_metascore_genre
FROM t1
JOIN t2 ON t1.row_num = t2.row_num
JOIN t3 ON t1.row_num = t3.row_num
JOIN t4 ON t1.row_num = t4.row_num;

-- Ranked genres
SELECT
	ROW_NUMBER() OVER(ORDER BY MAX(imdb_rating) DESC) as genre_ranking,
	genre,
    MAX(imdb_rating) * 10 AS max_imdb_rating,
    SUM(
		CASE 
			WHEN imdb_rating = (
				SELECT MAX(t2.imdb_rating) 
                FROM top_movies.imdb_1000_clean t2
                WHERE t2.genre = t1.genre
			)
			THEN 1 ELSE 0 
		END 
	) AS frequency,
    COUNT(*) as total_frequency
FROM top_movies.imdb_1000_clean t1
GROUP BY genre;

SELECT
	ROW_NUMBER() OVER(ORDER BY AVG(imdb_rating) DESC) as genre_ranking,
	genre,
    ROUND(AVG(imdb_rating) * 10,2) AS avg_imdb_rating,
    COUNT(*) AS frequency
FROM top_movies.imdb_1000_clean
GROUP BY genre;

SELECT
	ROW_NUMBER() OVER(ORDER BY MAX(metascore) DESC) as genre_ranking,
	genre,
    MAX(metascore) AS max_metascore,
    SUM(
		CASE 
			WHEN metascore = (
				SELECT MAX(t2.metascore) 
                FROM top_movies.imdb_1000_clean t2
                WHERE t2.genre = t1.genre
			)
			THEN 1 ELSE 0 
		END 
	) AS frequency,
    COUNT(*) as total_frequency
FROM top_movies.imdb_1000_clean t1
GROUP BY genre;

SELECT
	ROW_NUMBER() OVER(ORDER BY AVG(metascore) DESC) as genre_ranking,
	genre,
    ROUND(AVG(metascore),2) AS avg_metascore,
    COUNT(*) AS frequency
FROM top_movies.imdb_1000_clean
GROUP BY genre;

-- Compare rankings side by side
WITH t1 AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY MAX(imdb_rating) DESC) as imdb_genre_ranking,
		genre,
		MAX(imdb_rating) * 10 AS max_imdb_rating,
		SUM(
			CASE 
				WHEN imdb_rating = (
					SELECT MAX(t2.imdb_rating) 
					FROM top_movies.imdb_1000_clean t2
					WHERE t2.genre = t1.genre
				)
				THEN 1 ELSE 0 
			END 
		) AS frequency,
		COUNT(*) as total_frequency
	FROM top_movies.imdb_1000_clean t1
	GROUP BY genre
), t2 AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY MAX(metascore) DESC) as meta_genre_ranking,
		genre,
		MAX(metascore) AS max_metascore,
		SUM(
			CASE 
				WHEN metascore = (
					SELECT MAX(t2.metascore) 
					FROM top_movies.imdb_1000_clean t2
					WHERE t2.genre = t1.genre
				)
				THEN 1 ELSE 0 
			END 
		) AS frequency,
		COUNT(*) as total_frequency
	FROM top_movies.imdb_1000_clean t1
	GROUP BY genre
)
SELECT
	t1.imdb_genre_ranking,
    t1.genre,
    t1.max_imdb_rating,
    t1.frequency,
    t1.total_frequency,
    t2.meta_genre_ranking,
    t2.genre,
    t2.max_metascore,
    t2.frequency,
    t2.total_frequency
FROM t1
JOIN t2 ON t1.imdb_genre_ranking = t2.meta_genre_ranking;
    