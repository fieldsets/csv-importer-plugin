#!/usr/bin/env bash

#===
# import-csv.sh: Import a CSV file as a foreign data table in the FieldSets Framework
# See shell coding standards for details of formatting.
# https://github.com/fieldsets/fieldsets/blob/main/docs/developer/coding-standards/shell.md
#
# @envvar VERSION | String
# @envvar ENVIRONMENT | String
#
#===

set -eEa -o pipefail

#===
# Variables
#===
last_checkpoint="/fieldsets-plugins/csv-importer-plugin/init.sh"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export PGPASSWORD=${POSTGRES_PASSWORD}
CSV_FILE_PATH=${1}

#===
# Functions
#===

source /fieldsets-lib/shell/utils.sh

##
# import_csv_data: Create our SQL structures
##
import_csv_data() {
    log "Importing Econcircles CSV Files as Foreign Tables SQL...."
    local accounts_csv
    local col_count
    local csv_stat

    if [ -d "${SCRIPT_DIR}/data/init/" ]; then
        cd "${SCRIPT_DIR}/data/init/"
        accounts_csv="accounts_2023_08_31"
        csvclean ${SCRIPT_DIR}/data/init/${accounts_csv}.csv
        head -n 1 ${SCRIPT_DIR}/data/init/${accounts_csv}_out.csv > ${SCRIPT_DIR}/data/init/accounts.csv
        tail -n +3 ${SCRIPT_DIR}/data/init/${accounts_csv}_out.csv >> ${SCRIPT_DIR}/data/init/accounts.csv

        csv_stat=$(csvstat -n ${SCRIPT_DIR}/data/init/accounts.csv | tail -n 1)
        IFS=':' read -ra COL_ARR <<< "$csv_stat"
        col_count="${COL_ARR[0]}"
        psql -v ON_ERROR_STOP=1 --host "${POSTGRES_HOST}" --port "${POSTGRES_PORT}" --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            SET search_path TO 'econcircles';
            CALL econcircles.import_foreign_csv_table('accounts_import_file', '${SCRIPT_DIR}/data/init/accounts.csv', ${col_count})
		EOSQL
    fi
    log "Econcircles Plugin Initialized..."
}


##
# init: Initialize plugin
##
init() {
    mkdir -p "${FIELDSETS_DATA_PATH}imports/csv"
    import_csv_data
}

#===
# Main
#===
trap traperr ERR

init
