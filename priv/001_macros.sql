CREATE OR REPLACE MACRO ducker_relative_to_work_dir(path) AS (
  getvariable('ducker_work_dir') || '/' || path
);

---

CREATE OR REPLACE MACRO ducker_data_test
(test_type, tbl, expr) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,
      expr AS validate,
      (SELECT * FROM query('SELECT count(*) FROM ' || tbl || ' WHERE NOT (' || expr || ')')) AS fail_count,
      'SELECT * FROM ' || tbl || ' WHERE NOT (' || expr || ')' AS sql_query
  ),

(test_type, tbl, expr, where_clause) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,
      expr || ' WHERE (' || where_clause || ')' AS validate,
      (SELECT * FROM query('SELECT count(*) FROM ' || tbl || ' WHERE (' || where_clause || ') AND NOT (' || expr || ')')) AS fail_count,
      'SELECT * FROM ' || tbl || ' WHERE (' || where_clause || ') AND NOT (' || expr || ')' AS sql_query
  );

---

CREATE OR REPLACE MACRO ducker_data_test_unique
(test_type, tbl, fields) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,

      'unique(' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ')' AS validate,

      (SELECT ifnull(sum(number_of_occurences), 0) FROM query(
        'SELECT count(*) AS number_of_occurences FROM ' || tbl
        || ' GROUP BY ' || list_reduce(fields, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
      )) AS fail_count,

      'SELECT a.*'
      || ' FROM ' || tbl || ' AS a'
      || ' LEFT JOIN ('
        || 'SELECT ' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ', count(*) AS number_of_occurences FROM ' || tbl
        || ' GROUP BY ' || list_reduce(fields, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
        || ') AS b'
      || ' ON (' || list_reduce(list_transform(fields, x -> 'a.' || x || ' = b.' || x), (acc, x) -> acc || ' AND ' || x) || ')'
      || ' WHERE b.' || fields[1] || ' IS NOT NULL'
      AS sql_query
  ),

(test_type, tbl, fields, where_clause) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,

      'unique(' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ') WHERE (' || where_clause || ')' AS validate,

      (SELECT ifnull(sum(number_of_occurences), 0) FROM query(
        'SELECT count(*) AS number_of_occurences FROM ' || tbl
        || ' WHERE (' || where_clause || ')'
        || ' GROUP BY ' || list_reduce(fields, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
      )) AS fail_count,

      'SELECT a.*'
      || ' FROM ' || tbl || ' AS a'
      || ' LEFT JOIN ('
        || 'SELECT ' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ', count(*) AS number_of_occurences FROM ' || tbl
        || ' WHERE (' || where_clause || ')'
        || ' GROUP BY ' || list_reduce(fields, (acc, x) -> acc || ', ' || x)
        || ' HAVING number_of_occurences > 1'
        || ') AS b'
      || ' ON (' || list_reduce(list_transform(fields, x -> 'a.' || x || ' = b.' || x), (acc, x) -> acc || ' AND ' || x) || ')'
      || ' WHERE b.' || fields[1] || ' IS NOT NULL'
      AS sql_query
  );

---

CREATE OR REPLACE MACRO ducker_data_test_relationship
(test_type, tbl, fields, to_table, to_fields) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,
      '(' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ') -> ' || to_table || '(' || list_reduce(to_fields, (acc, x) -> acc || ', ' || x) || ')' AS validate,


      (SELECT * FROM query(
        'SELECT count(*) '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || to_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(fields, to_fields), x -> '"' || tbl || '"."' || x[1] || '" = "' || to_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE "' || to_table || '"."' || to_fields[1] || '" IS NULL'
        )) AS fail_count,

      'SELECT "' || tbl || '".* '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || to_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(fields, to_fields), x -> '"' || tbl || '"."' || x[1] || '" = "' || to_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE "' || to_table || '"."' || to_fields[1] || '" IS NULL'
      AS sql_query
  ),

(test_type, tbl, fields, to_table, to_fields, where_clause) AS TABLE
  (
    SELECT
      test_type AS type,
      tbl AS entity,
      '(' || list_reduce(fields, (acc, x) -> acc || ', ' || x) || ') -> ' || to_table || '(' || list_reduce(to_fields, (acc, x) -> acc || ', ' || x) || ') WHERE (' || where_clause || ')' AS validate,


      (SELECT * FROM query(
        'SELECT count(*) '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || to_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(fields, to_fields), x -> '"' || tbl || '"."' || x[1] || '" = "' || to_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE (' || where_clause || ') AND "' || to_table || '"."' || to_fields[1] || '" IS NULL'
        )) AS fail_count,

      'SELECT A.* '
        || 'FROM "' || tbl || '"'
        || 'LEFT JOIN "' || to_table || '"'
        || 'ON (' || list_reduce(list_transform(list_zip(fields, to_fields), x -> '"' || tbl || '"."' || x[1] || '" = "' || to_table || '"."' ||  x[2] || '"'), (acc, x) -> acc || ' AND ' || x) || ') '
        || 'WHERE (' || where_clause || ') AND "' || to_table || '"."' || to_fields[1] || '" IS NULL'
      AS sql_query
  );
