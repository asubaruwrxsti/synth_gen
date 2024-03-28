WITH column_lengths (column_name, character_max_length) AS (
  SELECT column_name, CHARACTER_MAXIMUM_LENGTH
  FROM information_schema.columns
  WHERE table_name = '%s'
)
SELECT
    jsonb_build_object(
        'type', 'array',
        'length', jsonb_build_object('type', 'number', 'constant', 1),
        'content', (
            SELECT jsonb_build_object('type', 'object')
            ||
            jsonb_object_agg(
                _column_name_,
                CASE
                    WHEN column_type LIKE 'bool%%' THEN jsonb_build_object('type', 'bool', 'frequency', 0.5)
                    WHEN column_type LIKE '%%int%%' THEN jsonb_build_object('type', 'number', 'range', jsonb_build_object('low', 1, 'high', 5), 'step', 1)
                    WHEN column_type LIKE 'character%%' THEN jsonb_build_object(
                        'type', 'string',
                        'truncated', jsonb_build_object(
                            'content', jsonb_build_object('type', 'string', 'pattern','[a-zA-Z0-9]{0, 255}'),
                            'length', (
                                SELECT CHARACTER_MAXIMUM_LENGTH
                                FROM information_schema.columns
                                WHERE table_name =  '%s'
                                AND column_name = _column_name_
                            )
                        )
                    )
                    WHEN column_type LIKE 'date%%' THEN jsonb_build_object('type', 'date_time', 'format', '%%Y-%%m-%%d', 'begin' , '2024-01-01', 'end', '2025-12-31')
                    WHEN column_type IS NULL THEN NULL
                END
                || 
				CASE
					WHEN fk_definition IS NOT NULL THEN jsonb_build_object(
						'type', 'same_as',
						'ref', regexp_replace(fk_definition, 'FOREIGN KEY \((.*)\) REFERENCES (.*)\((.*)\)', '\2.\3')
					)
					ELSE '{}'
				END
            )::jsonb
            FROM (
                SELECT
                    a.attname AS _column_name_,
                    pg_catalog.format_type(a.atttypid, a.atttypmod) AS column_type,
                    a.attnotnull AS is_not_null,
                    pg_catalog.pg_get_constraintdef(b.oid) AS fk_definition
                FROM pg_catalog.pg_attribute a
                JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
                JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
                LEFT JOIN pg_catalog.pg_constraint b ON a.attrelid = b.conrelid AND a.attnum = ANY(b.conkey) AND b.contype = 'f'
                WHERE c.relname = '%s'
                  AND n.nspname = 'anagrafica'
                  AND a.attnum > 0
                  AND NOT a.attisdropped
                ORDER BY
                    a.attnum
            ) AS _cte_
        )
    );