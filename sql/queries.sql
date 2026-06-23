-- ============================================================
-- Phase 2 SQL Query Testing
-- IMDb-Powered Streaming Intelligence Database
-- ============================================================

-- Q1: INSERT a new title.
INSERT INTO title_basics
(tconst, title_type, primary_title, original_title, is_adult, start_year, runtime_minutes)
VALUES
('tt9999001', 'movie', 'Database Dreams', 'Database Dreams', FALSE, 2026, 118);

-- Q2: INSERT rating for the new title.
INSERT INTO title_ratings
(tconst, average_rating, num_votes)
VALUES
('tt9999001', 8.7, 25000);

-- Check inserted row.
SELECT
    tb.tconst,
    tb.primary_title,
    tb.start_year,
    tr.average_rating,
    tr.num_votes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.tconst = 'tt9999001';


-- Q3: UPDATE rating after new votes arrive.
UPDATE title_ratings
SET average_rating = 8.9,
    num_votes = 31000
WHERE tconst = 'tt9999001';

-- Check updated row.
SELECT
    tb.tconst,
    tb.primary_title,
    tr.average_rating,
    tr.num_votes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.tconst = 'tt9999001';


-- Q4: DELETE test title.
DELETE FROM title_basics
WHERE tconst = 'tt9999001';

-- Confirm delete. This should return 0 rows.
SELECT *
FROM title_basics
WHERE tconst = 'tt9999001';


-- Q5: Top-rated movies in a selected genre.
SELECT
    tb.primary_title,
    tb.start_year,
    g.genre_name,
    tr.average_rating,
    tr.num_votes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
JOIN title_genre tg ON tb.tconst = tg.tconst
JOIN genre g ON tg.genre_id = g.genre_id
WHERE g.genre_name = 'Drama'
  AND tb.title_type = 'movie'
  AND tr.num_votes >= 10000
ORDER BY tr.average_rating DESC, tr.num_votes DESC
LIMIT 10;


-- Q6: Average rating by genre.
SELECT
    g.genre_name,
    COUNT(*) AS total_titles,
    ROUND(AVG(tr.average_rating), 2) AS avg_genre_rating,
    SUM(tr.num_votes) AS total_votes
FROM genre g
JOIN title_genre tg ON g.genre_id = tg.genre_id
JOIN title_ratings tr ON tg.tconst = tr.tconst
GROUP BY g.genre_name
HAVING COUNT(*) >= 10
ORDER BY avg_genre_rating DESC
LIMIT 10;


-- Q7: Titles above the global average rating.
SELECT
    tb.primary_title,
    tb.start_year,
    tr.average_rating
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tr.average_rating > (
    SELECT AVG(average_rating)
    FROM title_ratings
)
ORDER BY tr.average_rating DESC, tb.primary_title
LIMIT 10;


-- Q8: Directors with the highest number of highly-rated titles.
SELECT
    nb.primary_name AS director_name,
    COUNT(*) AS high_rated_titles,
    ROUND(AVG(tr.average_rating), 2) AS avg_rating
FROM name_basics nb
JOIN title_principals tp ON nb.nconst = tp.nconst
JOIN title_ratings tr ON tp.tconst = tr.tconst
WHERE tp.category = 'director'
  AND tr.average_rating >= 8.0
  AND tr.num_votes >= 5000
GROUP BY nb.primary_name
ORDER BY high_rated_titles DESC, avg_rating DESC
LIMIT 10;


-- Q9: Localized titles by region.
SELECT
    ta.region,
    COUNT(*) AS localized_title_count
FROM title_akas ta
WHERE ta.region IS NOT NULL
  AND ta.region <> ''
GROUP BY ta.region
ORDER BY localized_title_count DESC
LIMIT 10;


-- Q10: Episode hierarchy query.
-- This automatically selects parent series with the most episodes in this dataset.
WITH top_series AS (
    SELECT parent_tconst
    FROM title_episode
    GROUP BY parent_tconst
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
SELECT
    parent.primary_title AS series_name,
    episode.primary_title AS episode_title,
    te.season_number,
    te.episode_number
FROM title_episode te
JOIN top_series ts ON te.parent_tconst = ts.parent_tconst
JOIN title_basics parent ON te.parent_tconst = parent.tconst
JOIN title_basics episode ON te.episode_tconst = episode.tconst
ORDER BY te.season_number, te.episode_number
LIMIT 15;


-- Q11: Recommendation query based on shared cast/crew.
-- This automatically selects one highly voted title and finds titles sharing people.
WITH target_title AS (
    SELECT tconst
    FROM title_ratings
    ORDER BY num_votes DESC
    LIMIT 1
),
target_people AS (
    SELECT tp.nconst
    FROM title_principals tp
    JOIN target_title tt ON tp.tconst = tt.tconst
)
SELECT
    tb.tconst,
    tb.primary_title,
    COUNT(DISTINCT tp.nconst) AS shared_people,
    tr.average_rating,
    tr.num_votes
FROM title_principals tp
JOIN target_people tpe ON tp.nconst = tpe.nconst
JOIN title_basics tb ON tp.tconst = tb.tconst
LEFT JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.tconst NOT IN (SELECT tconst FROM target_title)
GROUP BY tb.tconst, tb.primary_title, tr.average_rating, tr.num_votes
ORDER BY shared_people DESC, tr.average_rating DESC NULLS LAST
LIMIT 10;


-- Q12: Top 5 titles per genre using window function.
WITH ranked_titles AS (
    SELECT
        g.genre_name,
        tb.primary_title,
        tb.start_year,
        tr.average_rating,
        tr.num_votes,
        ROW_NUMBER() OVER (
            PARTITION BY g.genre_name
            ORDER BY tr.average_rating DESC, tr.num_votes DESC
        ) AS genre_rank
    FROM genre g
    JOIN title_genre tg ON g.genre_id = tg.genre_id
    JOIN title_basics tb ON tg.tconst = tb.tconst
    JOIN title_ratings tr ON tb.tconst = tr.tconst
    WHERE tr.num_votes >= 10000
)
SELECT *
FROM ranked_titles
WHERE genre_rank <= 5
ORDER BY genre_name, genre_rank
LIMIT 30;
