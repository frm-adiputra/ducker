CREATE OR REPLACE MACRO ducker_relative_to_work_dir(path) AS (
  getvariable('ducker_work_dir') || '/' || path
);

---

CREATE OR REPLACE MACRO ducker_validate
(validation_type, tbl, expr) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,
      expr AS validate,
      (SELECT * FROM query('SELECT count(*) FROM ' || tbl || ' WHERE NOT (' || expr || ')')) AS fail_count,
      'SELECT * FROM ' || tbl || ' WHERE NOT (' || expr || ')' AS sql_query
  ),

(validation_type, tbl, expr, where_clause) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,
      expr || ' WHERE (' || where_clause || ')' AS validate,
      (SELECT * FROM query('SELECT count(*) FROM ' || tbl || ' WHERE (' || where_clause || ') AND NOT (' || expr || ')')) AS fail_count,
      'SELECT * FROM ' || tbl || ' WHERE (' || where_clause || ') AND NOT (' || expr || ')' AS sql_query
  );

---

CREATE OR REPLACE MACRO ducker_validate_unique
(validation_type, tbl, columns) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,

      'unique(' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ')' AS validate,

      (SELECT ifnull(sum(number_of_occurences), 0) FROM query(
        'SELECT count(*) AS number_of_occurences FROM ' || tbl
        || ' GROUP BY ' || list_reduce(columns, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
      )) AS fail_count,

      'SELECT a.*'
      || ' FROM ' || tbl || ' AS a'
      || ' LEFT JOIN ('
        || 'SELECT ' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ', count(*) AS number_of_occurences FROM ' || tbl
        || ' GROUP BY ' || list_reduce(columns, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
        || ') AS b'
      || ' ON (' || list_reduce(list_transform(columns, x -> 'a.' || x || ' = b.' || x), (acc, x) -> acc || ' AND ' || x) || ')'
      || ' WHERE b.' || columns[1] || ' IS NOT NULL'
      AS sql_query
  ),

(validation_type, tbl, columns, where_clause) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,

      'unique(' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ') WHERE (' || where_clause || ')' AS validate,

      (SELECT ifnull(sum(number_of_occurences), 0) FROM query(
        'SELECT count(*) AS number_of_occurences FROM ' || tbl
        || ' WHERE (' || where_clause || ')'
        || ' GROUP BY ' || list_reduce(columns, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
      )) AS fail_count,

      'SELECT a.*'
      || ' FROM ' || tbl || ' AS a'
      || ' LEFT JOIN ('
        || 'SELECT ' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ', count(*) AS number_of_occurences FROM ' || tbl
        || ' WHERE (' || where_clause || ')'
        || ' GROUP BY ' || list_reduce(columns, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
        || ') AS b'
      || ' ON (' || list_reduce(list_transform(columns, x -> 'a.' || x || ' = b.' || x), (acc, x) -> acc || ' AND ' || x) || ')'
      || ' WHERE b.' || columns[1] || ' IS NOT NULL'
      AS sql_query
  );

---

CREATE OR REPLACE MACRO ducker_validate_reference
(validation_type, tbl, columns, foreign_table, foreign_columns) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,
      '(' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ') -> ' || foreign_table || '(' || list_reduce(foreign_columns, (acc, x) -> acc || ', ' || x) || ')' AS validate,


      (SELECT * FROM query(
        'SELECT count(*) '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || foreign_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(columns, foreign_columns), x -> '"' || tbl || '"."' || x[1] || '" = "' || foreign_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE "' || foreign_table || '"."' || foreign_columns[1] || '" IS NULL'
        )) AS fail_count,

      'SELECT "' || tbl || '".* '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || foreign_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(columns, foreign_columns), x -> '"' || tbl || '"."' || x[1] || '" = "' || foreign_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE "' || foreign_table || '"."' || foreign_columns[1] || '" IS NULL'
      AS sql_query
  ),

(validation_type, tbl, columns, foreign_table, foreign_columns, where_clause) AS TABLE
  (
    SELECT
      validation_type AS type,
      tbl AS entity,
      '(' || list_reduce(columns, (acc, x) -> acc || ', ' || x) || ') -> ' || foreign_table || '(' || list_reduce(foreign_columns, (acc, x) -> acc || ', ' || x) || ') WHERE (' || where_clause || ')' AS validate,


      (SELECT * FROM query(
        'SELECT count(*) '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || foreign_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(columns, foreign_columns), x -> '"' || tbl || '"."' || x[1] || '" = "' || foreign_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE (' || where_clause || ') AND "' || foreign_table || '"."' || foreign_columns[1] || '" IS NULL'
        )) AS fail_count,

      'SELECT A.* '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || foreign_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(columns, foreign_columns), x -> '"' || tbl || '"."' || x[1] || '" = "' || foreign_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE (' || where_clause || ') AND "' || foreign_table || '"."' || foreign_columns[1] || '" IS NULL'
      AS sql_query
  );
