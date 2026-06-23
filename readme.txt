Project Title:
IMDb-Powered Streaming Intelligence: A Relational Database for Content Ranking and Recommendation Analytics

Team Members:
Swetha Lokanadham - swethalo
Sai Akshitha Yarlagadda - syarlaga
T N Akash Chowdary Bollimpalli - tnakashc

Database:
PostgreSQL

Data Source:
IMDb Non-Commercial Datasets.

Raw IMDb Files Used:
1. title.basics.tsv.gz
2. title.ratings.tsv.gz
3. name.basics.tsv.gz
4. title.principals.tsv.gz
5. title.episode.tsv.gz
6. title.akas.tsv.gz

Generated CSV Files:
1. title_basics.csv
2. title_ratings.csv
3. genre.csv
4. title_genre.csv
5. name_basics.csv
6. profession.csv
7. person_profession.csv
8. title_principals.csv
9. title_episode.csv
10. title_akas.csv

Total Loaded Records:
792,786 rows after removing one orphan title_principals row that violated the foreign key constraint.

Execution Order:
1. Run prepare_imdb_phase2_data.py to generate cleaned CSV files.
2. Run sql/create.sql to create all tables.
3. Run sql/load.sql to load CSV data into PostgreSQL.
4. Run sql/queries.sql to test insert, update, delete, and select queries.
5. Run sql/procedures_functions.sql to create and test procedures/functions.
6. Run sql/transaction_trigger.sql to demonstrate trigger-based failure handling.
7. Run sql/indexing_analysis.sql to compare EXPLAIN plans before and after indexing.

Notes:
- Screenshots are embedded in the final report.
- database_dump.sql contains the PostgreSQL database dump.
