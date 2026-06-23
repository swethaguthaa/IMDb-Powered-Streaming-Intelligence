DROP INDEX IF EXISTS idx_genre_name;
DROP INDEX IF EXISTS idx_title_genre_genre_tconst;
DROP INDEX IF EXISTS idx_title_ratings_votes_rating;
DROP INDEX IF EXISTS idx_title_basics_type_tconst;
DROP INDEX IF EXISTS idx_name_basics_lower_name;
DROP INDEX IF EXISTS idx_title_principals_nconst_category_tconst;
DROP INDEX IF EXISTS idx_title_episode_parent_season_episode;

-- Problem Query 1: Top titles by genre BEFORE indexing.
EXPLAIN (ANALYZE, BUFFERS)
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

-- Problem Query 2: Talent lookup BEFORE indexing.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    nb.primary_name,
    tb.primary_title,
    tr.average_rating,
    tr.num_votes
FROM name_basics nb
JOIN title_principals tp ON nb.nconst = tp.nconst
JOIN title_basics tb ON tp.tconst = tb.tconst
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE LOWER(nb.primary_name) = LOWER('Christopher Nolan')
ORDER BY tr.average_rating DESC;

-- Problem Query 3: Episode hierarchy BEFORE indexing.
EXPLAIN (ANALYZE, BUFFERS)
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

CREATE INDEX idx_genre_name
ON genre(genre_name);

CREATE INDEX idx_title_genre_genre_tconst
ON title_genre(genre_id, tconst);

CREATE INDEX idx_title_ratings_votes_rating
ON title_ratings(num_votes DESC, average_rating DESC, tconst);

CREATE INDEX idx_title_basics_type_tconst
ON title_basics(title_type, tconst);

CREATE INDEX idx_name_basics_lower_name
ON name_basics(LOWER(primary_name));

CREATE INDEX idx_title_principals_nconst_category_tconst
ON title_principals(nconst, category, tconst);

CREATE INDEX idx_title_episode_parent_season_episode
ON title_episode(parent_tconst, season_number, episode_number);

ANALYZE;

-- Problem Query 1: Top titles by genre AFTER indexing.
EXPLAIN (ANALYZE, BUFFERS)
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

-- Problem Query 2: Talent lookup AFTER indexing.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    nb.primary_name,
    tb.primary_title,
    tr.average_rating,
    tr.num_votes
FROM name_basics nb
JOIN title_principals tp ON nb.nconst = tp.nconst
JOIN title_basics tb ON tp.tconst = tb.tconst
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE LOWER(nb.primary_name) = LOWER('Christopher Nolan')
ORDER BY tr.average_rating DESC;

-- Problem Query 3: Episode hierarchy AFTER indexing.
EXPLAIN (ANALYZE, BUFFERS)
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
