SELECT
    json_build_object(
        'type', 'array',
        'length', json_build_object('type', 'number', 'constant', 1),
        'content', (
            SELECT json_build_object('type', 'object')
            ||
            json_object_agg(
                _column_name_,
                CASE
                    WHEN column_type LIKE 'bool%' THEN json_build_object('type', 'bool', 'frequency', 0.5)
                    ELSE json_build_object(
                        'type', CASE
                            WHEN column_type LIKE 'numeric%' THEN 'number'
                            WHEN column_type LIKE 'varchar%' THEN 'string'
                            WHEN column_type LIKE 'text%' THEN 'string'
                            WHEN column_type LIKE 'int%' THEN 'random_number'
                            WHEN column_type IS NULL THEN NULL
                            ELSE 'string'
                        END,
                        'faker', json_build_object('generator', CASE
                            WHEN column_type LIKE 'numeric%' THEN 'random_number'
                            WHEN column_type LIKE 'varchar%' THEN 'buzzword'
                            WHEN column_type LIKE 'bool%' THEN 'boolean'
							WHEN column_type LIKE 'text%' THEN 'buzzword'
							WHEN column_type LIKE 'int%' THEN 'random_number'
                            WHEN column_type IS NULL THEN NULL
                            ELSE 'buzzword'
                        END)
                    )
                END
            )
            FROM (
                SELECT
                    c.relname AS _table_name_,
                    a.attnum AS _column_number_,
                    a.attname AS _column_name_,
                    pg_catalog.format_type(a.atttypid, a.atttypmod) AS column_type,
                    a.attlen AS column_length,
                    a.atttypmod AS type_modifier,
                    CASE
                        WHEN a.attnotnull THEN 'NOT NULL'
                        ELSE 'NULL'
                    END AS is_nullable
                FROM
                    pg_catalog.pg_class c
                    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
                WHERE
                    c.relname = 'agente'
                    AND a.attnum > 0
                    AND NOT a.attisdropped
                ORDER BY
                    a.attnum
            ) AS _cte_
        )
    );