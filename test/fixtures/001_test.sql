CREATE
OR REPLACE TABLE mtcars AS
SELECT
    *
FROM
    read_csv ('001_test.csv');

---
SELECT
    '<%= @work_dir %>';

---
SELECT
    '<%= if true do %>
        ' true '
    <% else %>
        ' false '
    ';
