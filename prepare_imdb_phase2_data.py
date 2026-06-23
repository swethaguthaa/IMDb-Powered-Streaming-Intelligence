from pathlib import Path
import pandas as pd

RAW_DIR = Path("raw")
OUT_DIR = Path("data")
OUT_DIR.mkdir(exist_ok=True)

# You can increase this later.
# 30,000 titles is already more than enough for the project.
TITLE_LIMIT = 30000
MIN_VOTES = 500

MAX_PRINCIPALS = 250000
MAX_AKAS = 120000
MAX_EPISODES = 30000


def read_tsv_gz(path, usecols=None, chunksize=None):
    return pd.read_csv(
        path,
        sep="\t",
        dtype=str,
        na_values="\\N",
        keep_default_na=False,
        usecols=usecols,
        chunksize=chunksize,
        low_memory=False,
    )


def to_nullable_int(series):
    return pd.to_numeric(series, errors="coerce").astype("Int64")


def bool_0_1_to_text(series):
    return series.map({"0": "false", "1": "true", 0: "false", 1: "true"}).fillna("")


def write_csv(df, filename):
    path = OUT_DIR / filename
    df.to_csv(path, index=False, na_rep="")
    print(f"Created {path} with {len(df):,} rows")


print("Step 1: Reading ratings and selecting popular titles...")

ratings = pd.read_csv(
    RAW_DIR / "title.ratings.tsv.gz",
    sep="\t",
    dtype={"tconst": str},
    na_values="\\N",
    keep_default_na=False,
)

ratings["averageRating"] = pd.to_numeric(ratings["averageRating"], errors="coerce")
ratings["numVotes"] = pd.to_numeric(ratings["numVotes"], errors="coerce")

ratings = ratings[ratings["numVotes"] >= MIN_VOTES]
ratings = ratings.sort_values(["numVotes", "averageRating"], ascending=False)
ratings = ratings.head(TITLE_LIMIT)

initial_title_set = set(ratings["tconst"])
print(f"Selected {len(initial_title_set):,} popular titles from ratings")


print("Step 2: Reading episode file and collecting parent series...")

episode_rows = []
parent_title_set = set()

episode_cols = ["tconst", "parentTconst", "seasonNumber", "episodeNumber"]

for chunk in read_tsv_gz(
    RAW_DIR / "title.episode.tsv.gz",
    usecols=episode_cols,
    chunksize=500000,
):
    chunk = chunk[chunk["tconst"].isin(initial_title_set)]
    if not chunk.empty:
        episode_rows.append(chunk)
        parent_title_set.update(chunk["parentTconst"].dropna().tolist())

    if sum(len(x) for x in episode_rows) >= MAX_EPISODES:
        break

if episode_rows:
    episode_raw = pd.concat(episode_rows, ignore_index=True).head(MAX_EPISODES)
else:
    episode_raw = pd.DataFrame(columns=episode_cols)

title_set = initial_title_set.union(parent_title_set)
print(f"Added {len(parent_title_set):,} parent series titles")
print(f"Total title set size: {len(title_set):,}")


print("Step 3: Reading title basics for selected titles...")

basics_cols = [
    "tconst",
    "titleType",
    "primaryTitle",
    "originalTitle",
    "isAdult",
    "startYear",
    "endYear",
    "runtimeMinutes",
    "genres",
]

basics_rows = []

for chunk in read_tsv_gz(
    RAW_DIR / "title.basics.tsv.gz",
    usecols=basics_cols,
    chunksize=500000,
):
    chunk = chunk[chunk["tconst"].isin(title_set)]
    if not chunk.empty:
        basics_rows.append(chunk)

title_basics_raw = pd.concat(basics_rows, ignore_index=True)
actual_title_set = set(title_basics_raw["tconst"])

print(f"Loaded {len(title_basics_raw):,} title_basics rows")


print("Step 4: Creating title_basics.csv...")

title_basics = title_basics_raw.copy()

title_basics["isAdult"] = bool_0_1_to_text(title_basics["isAdult"])
title_basics["startYear"] = to_nullable_int(title_basics["startYear"])
title_basics["endYear"] = to_nullable_int(title_basics["endYear"])
title_basics["runtimeMinutes"] = to_nullable_int(title_basics["runtimeMinutes"])

title_basics_final = title_basics[
    [
        "tconst",
        "titleType",
        "primaryTitle",
        "originalTitle",
        "isAdult",
        "startYear",
        "endYear",
        "runtimeMinutes",
    ]
].rename(
    columns={
        "titleType": "title_type",
        "primaryTitle": "primary_title",
        "originalTitle": "original_title",
        "isAdult": "is_adult",
        "startYear": "start_year",
        "endYear": "end_year",
        "runtimeMinutes": "runtime_minutes",
    }
)

write_csv(title_basics_final, "title_basics.csv")


print("Step 5: Creating title_ratings.csv...")

title_ratings = ratings[ratings["tconst"].isin(actual_title_set)].copy()
title_ratings = title_ratings.rename(
    columns={
        "averageRating": "average_rating",
        "numVotes": "num_votes",
    }
)
title_ratings = title_ratings[["tconst", "average_rating", "num_votes"]]

write_csv(title_ratings, "title_ratings.csv")


print("Step 6: Creating genre.csv and title_genre.csv...")

genre_names = set()

for value in title_basics_raw["genres"].dropna():
    if value and value != "\\N":
        for genre in value.split(","):
            genre = genre.strip()
            if genre:
                genre_names.add(genre)

genre_names = sorted(genre_names)

genre_df = pd.DataFrame(
    {
        "genre_id": range(1, len(genre_names) + 1),
        "genre_name": genre_names,
    }
)

genre_map = dict(zip(genre_df["genre_name"], genre_df["genre_id"]))

title_genre_rows = []

for _, row in title_basics_raw.iterrows():
    tconst = row["tconst"]
    genres = row.get("genres")

    if pd.isna(genres) or genres == "" or genres == "\\N":
        continue

    for genre in genres.split(","):
        genre = genre.strip()
        if genre in genre_map:
            title_genre_rows.append(
                {
                    "tconst": tconst,
                    "genre_id": genre_map[genre],
                }
            )

title_genre_df = pd.DataFrame(title_genre_rows).drop_duplicates()

write_csv(genre_df, "genre.csv")
write_csv(title_genre_df, "title_genre.csv")


print("Step 7: Creating title_episode.csv...")

if not episode_raw.empty:
    episode_final = episode_raw[
        episode_raw["tconst"].isin(actual_title_set)
        & episode_raw["parentTconst"].isin(actual_title_set)
    ].copy()

    episode_final["seasonNumber"] = to_nullable_int(episode_final["seasonNumber"])
    episode_final["episodeNumber"] = to_nullable_int(episode_final["episodeNumber"])

    episode_final = episode_final.rename(
        columns={
            "tconst": "episode_tconst",
            "parentTconst": "parent_tconst",
            "seasonNumber": "season_number",
            "episodeNumber": "episode_number",
        }
    )

    episode_final = episode_final[
        ["episode_tconst", "parent_tconst", "season_number", "episode_number"]
    ]
else:
    episode_final = pd.DataFrame(
        columns=["episode_tconst", "parent_tconst", "season_number", "episode_number"]
    )

write_csv(episode_final, "title_episode.csv")


print("Step 8: Reading title principals for selected titles...")

principal_cols = ["tconst", "ordering", "nconst", "category", "job", "characters"]
principal_rows = []
person_set = set()

for chunk in read_tsv_gz(
    RAW_DIR / "title.principals.tsv.gz",
    usecols=principal_cols,
    chunksize=500000,
):
    chunk = chunk[chunk["tconst"].isin(actual_title_set)]

    if not chunk.empty:
        principal_rows.append(chunk)
        person_set.update(chunk["nconst"].dropna().tolist())

    if sum(len(x) for x in principal_rows) >= MAX_PRINCIPALS:
        break

if principal_rows:
    title_principals = pd.concat(principal_rows, ignore_index=True).head(MAX_PRINCIPALS)
else:
    title_principals = pd.DataFrame(columns=principal_cols)

title_principals["ordering"] = to_nullable_int(title_principals["ordering"])

title_principals = title_principals[
    ["tconst", "ordering", "nconst", "category", "job", "characters"]
]

write_csv(title_principals, "title_principals.csv")

print(f"Collected {len(person_set):,} unique people from title_principals")


print("Step 9: Reading name basics for selected people...")

name_cols = [
    "nconst",
    "primaryName",
    "birthYear",
    "deathYear",
    "primaryProfession",
    "knownForTitles",
]

name_rows = []

for chunk in read_tsv_gz(
    RAW_DIR / "name.basics.tsv.gz",
    usecols=name_cols,
    chunksize=500000,
):
    chunk = chunk[chunk["nconst"].isin(person_set)]
    if not chunk.empty:
        name_rows.append(chunk)

if name_rows:
    name_raw = pd.concat(name_rows, ignore_index=True)
else:
    name_raw = pd.DataFrame(columns=name_cols)

print(f"Loaded {len(name_raw):,} name_basics rows")


print("Step 10: Creating name_basics.csv, profession.csv, and person_profession.csv...")

name_basics = name_raw.copy()
name_basics["birthYear"] = to_nullable_int(name_basics["birthYear"])
name_basics["deathYear"] = to_nullable_int(name_basics["deathYear"])

profession_names = set()

for value in name_raw["primaryProfession"].dropna():
    if value and value != "\\N":
        for prof in value.split(","):
            prof = prof.strip()
            if prof:
                profession_names.add(prof)

profession_names = sorted(profession_names)

profession_df = pd.DataFrame(
    {
        "profession_id": range(1, len(profession_names) + 1),
        "profession_name": profession_names,
    }
)

profession_map = dict(zip(profession_df["profession_name"], profession_df["profession_id"]))

person_profession_rows = []

for _, row in name_raw.iterrows():
    nconst = row["nconst"]
    professions = row.get("primaryProfession")

    if pd.isna(professions) or professions == "" or professions == "\\N":
        continue

    for prof in professions.split(","):
        prof = prof.strip()
        if prof in profession_map:
            person_profession_rows.append(
                {
                    "nconst": nconst,
                    "profession_id": profession_map[prof],
                }
            )

person_profession_df = pd.DataFrame(person_profession_rows).drop_duplicates()

name_basics_final = name_basics[
    ["nconst", "primaryName", "birthYear", "deathYear"]
].rename(
    columns={
        "primaryName": "primary_name",
        "birthYear": "birth_year",
        "deathYear": "death_year",
    }
)

write_csv(name_basics_final, "name_basics.csv")
write_csv(profession_df, "profession.csv")
write_csv(person_profession_df, "person_profession.csv")


print("Step 11: Creating title_akas.csv...")

akas_cols = [
    "titleId",
    "ordering",
    "title",
    "region",
    "language",
    "types",
    "attributes",
    "isOriginalTitle",
]

akas_rows = []

for chunk in read_tsv_gz(
    RAW_DIR / "title.akas.tsv.gz",
    usecols=akas_cols,
    chunksize=500000,
):
    chunk = chunk[chunk["titleId"].isin(actual_title_set)]

    if not chunk.empty:
        akas_rows.append(chunk)

    if sum(len(x) for x in akas_rows) >= MAX_AKAS:
        break

if akas_rows:
    title_akas = pd.concat(akas_rows, ignore_index=True).head(MAX_AKAS)
else:
    title_akas = pd.DataFrame(columns=akas_cols)

title_akas["ordering"] = to_nullable_int(title_akas["ordering"])
title_akas["isOriginalTitle"] = bool_0_1_to_text(title_akas["isOriginalTitle"])

title_akas = title_akas.rename(
    columns={
        "titleId": "tconst",
        "isOriginalTitle": "is_original_title",
    }
)

title_akas = title_akas[
    ["tconst", "ordering", "title", "region", "language", "types", "is_original_title"]
]

write_csv(title_akas, "title_akas.csv")


print("\nDone. Final CSV files created in data/ folder.")
print("Generated files:")
for path in sorted(OUT_DIR.glob("*.csv")):
    print(" -", path)