DROP PROCEDURE IF EXISTS add_title_with_rating(
    VARCHAR, VARCHAR, TEXT, TEXT, BOOLEAN, INTEGER, INTEGER, NUMERIC, INTEGER
);

DROP PROCEDURE IF EXISTS update_title_rating(
    VARCHAR, NUMERIC, INTEGER
);

DROP PROCEDURE IF EXISTS delete_title(
    VARCHAR
);

DROP FUNCTION IF EXISTS get_top_titles_by_genre(
    VARCHAR, NUMERIC, INTEGER, INTEGER
);

CREATE OR REPLACE PROCEDURE add_title_with_rating(
    p_tconst VARCHAR,
    p_title_type VARCHAR,
    p_primary_title TEXT,
    p_original_title TEXT,
    p_is_adult BOOLEAN,
    p_start_year INTEGER,
    p_runtime_minutes INTEGER,
    p_average_rating NUMERIC,
    p_num_votes INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO title_basics
    (tconst, title_type, primary_title, original_title, is_adult, start_year, runtime_minutes)
    VALUES
    (
        p_tconst,
        p_title_type,
        p_primary_title,
        p_original_title,
        p_is_adult,
        p_start_year::SMALLINT,
        p_runtime_minutes::SMALLINT
    );

    INSERT INTO title_ratings
    (tconst, average_rating, num_votes)
    VALUES
    (p_tconst, p_average_rating, p_num_votes);
END;
$$;

CREATE OR REPLACE PROCEDURE update_title_rating(
    p_tconst VARCHAR,
    p_average_rating NUMERIC,
    p_num_votes INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE title_ratings
    SET average_rating = p_average_rating,
        num_votes = p_num_votes
    WHERE tconst = p_tconst;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_title(
    p_tconst VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM title_basics
    WHERE tconst = p_tconst;
END;
$$;

CREATE OR REPLACE FUNCTION get_top_titles_by_genre(
    p_genre_name VARCHAR,
    p_min_rating NUMERIC,
    p_min_votes INTEGER,
    p_limit INTEGER
)
RETURNS TABLE (
    title_name TEXT,
    release_year SMALLINT,
    rating NUMERIC,
    votes INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        tb.primary_title,
        tb.start_year,
        tr.average_rating,
        tr.num_votes
    FROM title_basics tb
    JOIN title_ratings tr ON tb.tconst = tr.tconst
    JOIN title_genre tg ON tb.tconst = tg.tconst
    JOIN genre g ON tg.genre_id = g.genre_id
    WHERE g.genre_name = p_genre_name
      AND tr.average_rating >= p_min_rating
      AND tr.num_votes >= p_min_votes
    ORDER BY tr.average_rating DESC, tr.num_votes DESC
    LIMIT p_limit;
END;
$$;

DELETE FROM title_basics
WHERE tconst = 'tt9999002';

CALL add_title_with_rating(
    'tt9999002',
    'movie',
    'Stored Procedure Movie',
    'Stored Procedure Movie',
    FALSE,
    2026,
    120,
    9.1,
    50000
);

CALL update_title_rating('tt9999002', 9.2, 52000);

SELECT
    tb.tconst,
    tb.primary_title,
    tr.average_rating,
    tr.num_votes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.tconst = 'tt9999002';

CALL delete_title('tt9999002');

SELECT *
FROM get_top_titles_by_genre('Action', 7.5, 10000, 10);
