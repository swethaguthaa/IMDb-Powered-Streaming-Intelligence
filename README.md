# IMDb-Powered Streaming Intelligence

**A Relational Database for Content Ranking and Recommendation Analytics**

This project designs and implements a PostgreSQL relational database using IMDb non-commercial datasets to support content ranking, recommendation-style analytics, genre insights, talent analysis, and performance comparison through indexing.

## Team

- Swetha Lokanadham
- Sai Akshitha Yarlagadda
- T N Akash Chowdary Bollimpalli

## Database

- PostgreSQL

## Dataset

IMDb Non-Commercial Datasets:

- `title.basics.tsv.gz`
- `title.ratings.tsv.gz`
- `name.basics.tsv.gz`
- `title.principals.tsv.gz`
- `title.episode.tsv.gz`
- `title.akas.tsv.gz`

## Generated Data

The preprocessing script generates cleaned CSV files for:

- Titles and ratings
- Genres and title-genre mappings
- Names, professions, and person-profession mappings
- Principal cast/crew records
- Episodes and alternate titles

After cleaning, the database loads **792,786 records**.

## Project Contents

```text
data/                         Cleaned CSV files
sql/create.sql                Database schema
sql/load.sql                  CSV loading scripts
sql/queries.sql               Insert, update, delete, and analytical queries
sql/procedures_functions.sql  Stored procedures and functions
sql/transaction_trigger.sql   Trigger and transaction handling
sql/indexing_analysis.sql     Indexing and EXPLAIN plan analysis
database_dump.sql             PostgreSQL database dump
prepare_imdb_phase2_data.py   Data cleaning and CSV generation script
screenshots/                  pgAdmin and query result screenshots
```

## Execution Order

1. Run `prepare_imdb_phase2_data.py` to generate cleaned CSV files.
2. Run `sql/create.sql` to create tables.
3. Run `sql/load.sql` to load CSV data into PostgreSQL.
4. Run `sql/queries.sql` to test insert, update, delete, and select queries.
5. Run `sql/procedures_functions.sql` to create and test procedures/functions.
6. Run `sql/transaction_trigger.sql` to demonstrate trigger-based failure handling.
7. Run `sql/indexing_analysis.sql` to compare query plans before and after indexing.

## Highlights

- Normalized relational schema for IMDb-derived content analytics
- Recommendation-oriented SQL queries
- Stored procedures and functions
- Transaction and trigger-based validation
- Indexing analysis with before/after EXPLAIN plans
- PostgreSQL dump and screenshots for reproducibility
