CREATE
OR REPLACE TABLE mtcars_color AS
SELECT
    *
FROM
    read_csv ('002_test.csv');
