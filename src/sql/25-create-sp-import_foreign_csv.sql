-- Active: 1692635254843@@0.0.0.0@5432@fieldsets
/**
 * import_foreign_csv_table: Create a foreign table from a local CSV file.
 * @param TEXT: target_schema
 * @param TEXT: target_table
 * @param TEXT: csv_file_path
 * @param INT: col_count
 **/
CREATE OR REPLACE PROCEDURE fieldsets.import_foreign_csv_table(target_schema TEXT, target_table TEXT, csv_file_path TEXT, col_count INT) AS $procedure$
    DECLARE
        iter            INT;  -- dummy integer to iterate columns with
        col             TEXT; -- to keep column names in each iteration
        sanitized_col   TEXT; -- remove bad characters
        col_first       TEXT; -- first column name, e.g., top left corner on a csv file or spreadsheet
    BEGIN
        EXECUTE format('SET schema %I;', target_schema);
        EXECUTE format('DROP TABLE IF EXISTS %I.%I;', target_schema, target_table);
        EXECUTE format('CREATE TABLE %I.temp_table();', target_schema);

        -- add just enough number of columns
        FOR iter IN 1..col_count
        LOOP
            EXECUTE format('ALTER TABLE %I.temp_table ADD COLUMN col_%s text;', target_schema, iter);
        END LOOP;

        -- copy the data from csv file
        EXECUTE format('COPY %I.temp_table FROM %L WITH DELIMITER '','' QUOTE ''"'' csv ', target_schema, csv_file_path);

        iter := 1;
        col_first := (SELECT col_1 FROM temp_table LIMIT 1);

        -- update the column names based on the first row which has the column names
        FOR col IN EXECUTE format('SELECT unnest(string_to_array(trim(temp_table::TEXT, ''()''), '','')) FROM %I.temp_table WHERE col_1 = %L', target_schema, col_first)
        LOOP
            sanitized_col := lower(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    col, '%', '_pct'
                                                ),'.','_'
                                            ), ' ', '_'
                                        ), '(', '_'
                                    ), ')', ''
                                ), '-', '_'
                            ), '?',''
                        ), '>', ''
                    ), '<', ''
                )
            );
            sanitized_col := regexp_replace(sanitized_col, '_+', '_');
            EXECUTE format('ALTER TABLE %I.temp_table RENAME COLUMN col_%s TO %s', target_schema, iter, sanitized_col);
            iter := iter + 1;
        END LOOP;

        -- delete the columns row
        EXECUTE format ('DELETE FROM %I.temp_table WHERE %s = %L', target_schema, col_first, col_first);

        -- change the temp table name to the name given as parameter, if not blank
        IF length(target_table) > 0 THEN
            EXECUTE format('ALTER TABLE %I.temp_table RENAME TO %I.%I', target_schema, target_schema, target_table);
        END IF;
    END;
$procedure$ LANGUAGE plpgsql;

COMMENT ON PROCEDURE fieldsets.import_foreign_csv_table(TEXT, TEXT, TEXT, INT) IS
'/**
 * import_foreign_csv_table: Create a foreign table from a local CSV file.
 * @param TEXT: target_schema
 * @param TEXT: target_table
 * @param TEXT: csv_file_path
 * @param INT: col_count
 **/';
