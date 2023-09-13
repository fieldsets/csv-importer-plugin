#!/usr/bin/env bash

#===
# run.sh: Run Plugin Services.
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
last_checkpoint="/fieldsets-plugins/fieldsets-starter-plugin/run.sh"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#===
# Functions
#===

source /fieldsets-lib/shell/utils.sh

##
# run: Run plugin
##
run() {
    log "Run Plugin...."
    log "Plugin Running..."
}

#===
# Main
#===
trap traperr ERR

run