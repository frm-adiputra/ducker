CREATE
OR REPLACE TABLE mtcars AS
SELECT
    *
FROM
    read_csv ('002_test.csv');
