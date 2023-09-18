-- Active: 1692635254843@@0.0.0.0@5432@fieldsets
/**
 * migrate_csv_data: Create a foreign table from a local CSV file.
 * @param TEXT: target_schema
 * @param TEXT: target_table
 * @param TEXT: csv_file_path
 * @param INT: col_count
 **/
CREATE OR REPLACE PROCEDURE fieldsets.migrate_csv_data(source_schema TEXT, source_table TEXT, destination_schema TEXT, destination_table TEXT, num_cols INT, csv_file_path TEXT, mapping_json_path TEXT) AS $procedure$
    DECLARE
        file_check      TEXT; -- output of pg_stat_file to check existance.
        del_cmd         TEXT; -- Delete shell command.
    BEGIN
        EXECUTE format('SET schema %I;', destination_schema);
        EXECUTE format('SELECT pg_stat_file(%L, TRUE)', csv_file_path) INTO file_check;

        IF file_check IS NOT NULL THEN
            -- Import to temp table
            EXECUTE format('CALL fieldsets.import_foreign_csv_table(%L, %L, %L, %s);', source_schema, source_table, csv_file_path, num_cols);

            -- Get mapping

            -- Copy mapped columns to fieldset values by token  
            EXECUTE format('COPY (SELECT %L) TO PROGRAM %L', '', del_cmd);

            -- Wipe foreign table
            EXECUTE format('DROP TABLE IF EXISTS %L.%L;', source_schema, source_table);
            -- Wipe file. Requires permissions pg_execute_server_program
            del_cmd := format('rm -f %L', csv_file_path);
            EXECUTE format('COPY (SELECT %L) TO PROGRAM %L', '', del_cmd);
        END IF;

    END;
$procedure$ LANGUAGE plpgsql;

COMMENT ON PROCEDURE fieldsets.migrate_csv_data(TEXT, TEXT, TEXT, INT) IS
'/**
 * migrate_csv_data: Create a foreign table from a local CSV file.
 * @param TEXT: target_schema
 * @param TEXT: target_table
 * @param TEXT: csv_file_path
 * @param INT: col_count
 **/';
