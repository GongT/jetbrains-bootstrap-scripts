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

function pushd() {
	builtin pushd "$@" >/dev/null
}
function popd() {
	builtin popd >/dev/null
}
function push_gitignore_line() {
	local LINE="$1"
	if [[ -e .gitignore ]] && cat .gitignore | grep -q -E "^$LINE$" ; then
		return
	fi
	echo "$LINE" >> .gitignore
}
