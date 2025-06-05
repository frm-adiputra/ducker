CREATE
OR REPLACE TABLE mtcars AS
SELECT
    *
FROM
    read_csv ('data/mtcars.csv');

---
CREATE
OR REPLACE TABLE mtcars_colors AS
SELECT
    *
FROM
    read_csv ('data/mtcars_colors.csv');
