CREATE
OR REPLACE TABLE ducker_validate_result (
    "type" TEXT,
    entity TEXT,
    validate TEXT,
    fail_count INT,
    fail_query TEXT,
    PRIMARY KEY (type, entity, validate)
)
