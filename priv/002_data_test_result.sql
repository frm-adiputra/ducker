CREATE
OR REPLACE TABLE ducker_data_test_result (
    "type" TEXT,
    entity TEXT,
    label TEXT,
    fail_count INT,
    fail_query TEXT,
    PRIMARY KEY (type, entity, label)
)
