DROP TRIGGER IF EXISTS trg_validate_title_rating ON title_ratings;
DROP FUNCTION IF EXISTS validate_title_rating_trigger;
DROP FUNCTION IF EXISTS safe_insert_rating;
DROP TABLE IF EXISTS trigger_demo_result;

CREATE OR REPLACE FUNCTION validate_title_rating_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.average_rating < 0 OR NEW.average_rating > 10 THEN
        RAISE EXCEPTION 'Transaction failed: average_rating % is outside valid range 0-10',
            NEW.average_rating;
    END IF;

    IF NEW.num_votes < 0 THEN
        RAISE EXCEPTION 'Transaction failed: num_votes % cannot be negative',
            NEW.num_votes;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_title_rating
BEFORE INSERT OR UPDATE ON title_ratings
FOR EACH ROW
EXECUTE FUNCTION validate_title_rating_trigger();

CREATE OR REPLACE FUNCTION safe_insert_rating(
    p_tconst VARCHAR,
    p_average_rating NUMERIC,
    p_num_votes INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO title_ratings(tconst, average_rating, num_votes)
    VALUES (p_tconst, p_average_rating, p_num_votes);

    RETURN 'SUCCESS: rating inserted';

EXCEPTION WHEN OTHERS THEN
    INSERT INTO transaction_failure_log
    (operation_name, error_message, attempted_payload)
    VALUES
    (
        'INSERT INTO title_ratings',
        SQLERRM,
        jsonb_build_object(
            'tconst', p_tconst,
            'average_rating', p_average_rating,
            'num_votes', p_num_votes
        )
    );

    RETURN 'FAILED: ' || SQLERRM;
END;
$$;

DELETE FROM title_ratings
WHERE tconst = 'tt9999010';

DELETE FROM title_basics
WHERE tconst = 'tt9999010';

INSERT INTO title_basics
(tconst, title_type, primary_title, original_title, is_adult, start_year, runtime_minutes)
VALUES
('tt9999010', 'movie', 'Trigger Test Movie', 'Trigger Test Movie', FALSE, 2026, 100);

CREATE TEMP TABLE trigger_demo_result AS
SELECT safe_insert_rating('tt9999010', 11.5, 1000) AS transaction_result;

SELECT
    r.transaction_result,
    l.operation_name,
    l.error_message,
    l.attempted_payload,
    (
        SELECT COUNT(*)
        FROM title_ratings
        WHERE tconst = 'tt9999010'
    ) AS invalid_rating_rows_inserted
FROM trigger_demo_result r
LEFT JOIN LATERAL (
    SELECT *
    FROM transaction_failure_log
    ORDER BY created_at DESC
    LIMIT 1
) l ON TRUE;
