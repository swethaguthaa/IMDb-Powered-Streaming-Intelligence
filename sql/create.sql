DROP TABLE IF EXISTS transaction_failure_log CASCADE;
DROP TABLE IF EXISTS title_akas CASCADE;
DROP TABLE IF EXISTS title_episode CASCADE;
DROP TABLE IF EXISTS title_principals CASCADE;
DROP TABLE IF EXISTS person_profession CASCADE;
DROP TABLE IF EXISTS profession CASCADE;
DROP TABLE IF EXISTS title_genre CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS title_ratings CASCADE;
DROP TABLE IF EXISTS name_basics CASCADE;
DROP TABLE IF EXISTS title_basics CASCADE;

CREATE TABLE title_basics (
    tconst VARCHAR(12) PRIMARY KEY,
    title_type VARCHAR(30) NOT NULL,
    primary_title TEXT NOT NULL,
    original_title TEXT NOT NULL,
    is_adult BOOLEAN NOT NULL DEFAULT FALSE,
    start_year SMALLINT,
    end_year SMALLINT,
    runtime_minutes SMALLINT,
    CHECK (runtime_minutes IS NULL OR runtime_minutes > 0),
    CHECK (end_year IS NULL OR start_year IS NULL OR end_year >= start_year)
);

CREATE TABLE title_ratings (
    tconst VARCHAR(12) PRIMARY KEY,
    average_rating NUMERIC(4,1) NOT NULL,
    num_votes INTEGER NOT NULL,
    FOREIGN KEY (tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE,
    CHECK (average_rating >= 0.0 AND average_rating <= 10.0),
    CHECK (num_votes >= 0)
);

CREATE TABLE genre (
    genre_id INTEGER PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE title_genre (
    tconst VARCHAR(12) NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (tconst, genre_id),
    FOREIGN KEY (tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE,
    FOREIGN KEY (genre_id)
        REFERENCES genre(genre_id)
        ON DELETE RESTRICT
);

CREATE TABLE name_basics (
    nconst VARCHAR(12) PRIMARY KEY,
    primary_name TEXT NOT NULL,
    birth_year SMALLINT,
    death_year SMALLINT
);

CREATE TABLE profession (
    profession_id INTEGER PRIMARY KEY,
    profession_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE person_profession (
    nconst VARCHAR(12) NOT NULL,
    profession_id INTEGER NOT NULL,
    PRIMARY KEY (nconst, profession_id),
    FOREIGN KEY (nconst)
        REFERENCES name_basics(nconst)
        ON DELETE CASCADE,
    FOREIGN KEY (profession_id)
        REFERENCES profession(profession_id)
        ON DELETE RESTRICT
);

CREATE TABLE title_principals (
    tconst VARCHAR(12) NOT NULL,
    ordering SMALLINT NOT NULL,
    nconst VARCHAR(12) NOT NULL,
    category VARCHAR(50) NOT NULL,
    job TEXT,
    characters TEXT,
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE,
    FOREIGN KEY (nconst)
        REFERENCES name_basics(nconst)
        ON DELETE RESTRICT
);

CREATE TABLE title_episode (
    episode_tconst VARCHAR(12) PRIMARY KEY,
    parent_tconst VARCHAR(12) NOT NULL,
    season_number SMALLINT,
    episode_number SMALLINT,
    FOREIGN KEY (episode_tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE,
    FOREIGN KEY (parent_tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE,
    CHECK (episode_tconst <> parent_tconst)
);

CREATE TABLE title_akas (
    tconst VARCHAR(12) NOT NULL,
    ordering SMALLINT NOT NULL,
    title TEXT NOT NULL,
    region VARCHAR(20),
    language VARCHAR(20),
    types TEXT,
    is_original_title BOOLEAN,
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst)
        REFERENCES title_basics(tconst)
        ON DELETE CASCADE
);

CREATE TABLE transaction_failure_log (
    log_id BIGSERIAL PRIMARY KEY,
    operation_name TEXT NOT NULL,
    error_message TEXT NOT NULL,
    attempted_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
