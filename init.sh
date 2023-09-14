#!/usr/bin/env bash

#===
# init.sh: Initialize the FieldSets CSV Importer Plugin
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

#===
# Functions
#===

source /fieldsets-lib/shell/utils.sh

##
# exec_sql: Create our SQL structures
##
exec_sql() {
    log "Executing CSV Importer Plugin SQL...."
    local f
    for f in ${SCRIPT_DIR}/src/sql/*.sql; do
        psql -v ON_ERROR_STOP=1 --host "${POSTGRES_HOST}" --port "${POSTGRES_PORT}" --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" -f "${f}"
    done
    log "CSV Importer Plugin Initialized..."
}

##
# init: Initialize plugin
##
init() {
    log "Initialize CSV Importer Plugin...."
    pip install csvkit
    mkdir -p /fieldsets-data/imports/csv/
    exec_sql
    log "CSV Importer Plugin Initialized..."
}



#===
# Main
#===
trap traperr ERR

init
