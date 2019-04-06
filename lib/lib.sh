#!/usr/bin/env bash

set -e
set -o pipefail
set -o errtrace

export LIB_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

function die() {
	echo -e "\e[38;5;9m$*\e[0m" >&2
	exit 1
}

export APPLICATION_NAME=""
export APPLICATION_CODE=""
export BIN_NAME=""
export APPEND_SCRIPT=""
function load_application() {
	export APPLICATION_TITLE=""
	export APPLICATION_NAME=""
	export APPLICATION_CODE=""
	export BIN_NAME=""
	export APPEND_SCRIPT=""
	local what=$1
	source "$LIB_ROOT/apps/$what.sh" || die "There's no application named $what"
}
