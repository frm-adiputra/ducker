CREATE
OR REPLACE TABLE mtcars AS
SELECT
    *
FROM
    read_csv ('data/mtcars.csv');
