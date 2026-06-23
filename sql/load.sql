\copy title_basics(tconst, title_type, primary_title, original_title, is_adult, start_year, end_year, runtime_minutes) FROM 'data/title_basics.csv' WITH CSV HEADER;
\copy title_ratings(tconst, average_rating, num_votes) FROM 'data/title_ratings.csv' WITH CSV HEADER;
\copy genre(genre_id, genre_name) FROM 'data/genre.csv' WITH CSV HEADER;
\copy title_genre(tconst, genre_id) FROM 'data/title_genre.csv' WITH CSV HEADER;
\copy name_basics(nconst, primary_name, birth_year, death_year) FROM 'data/name_basics.csv' WITH CSV HEADER;
\copy profession(profession_id, profession_name) FROM 'data/profession.csv' WITH CSV HEADER;
\copy person_profession(nconst, profession_id) FROM 'data/person_profession.csv' WITH CSV HEADER;
\copy title_principals(tconst, ordering, nconst, category, job, characters) FROM 'data/title_principals.csv' WITH CSV HEADER;
\copy title_episode(episode_tconst, parent_tconst, season_number, episode_number) FROM 'data/title_episode.csv' WITH CSV HEADER;
\copy title_akas(tconst, ordering, title, region, language, types, is_original_title) FROM 'data/title_akas.csv' WITH CSV HEADER;

ANALYZE;
