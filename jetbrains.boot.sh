#!/usr/bin/env bash

set -e
set -o pipefail
set -o errtrace

if [[ -z "${JB_ROOT}" ]]; then
	echo "do not call this directly" >&2
	exit 1
fi
if [[ -z "${DISPLAY}" ]]; then
	echo "DISPLAY is not set" >&2
	exit 1
fi

JUSER_ARG="-u"
if [[ "$(id -u)" != "0" ]]; then
	USER_ARG="--user"
	JUSER_ARG="--user-unit"
	export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

DEBUG_ARG=""
if [[ -n "$DEBUG" ]]; then
	DEBUG_ARG="--pipe --wait"
fi

function exists() {
	systemctl $USER_ARG list-units --all | grep "${NAME}.service" | grep -q running
}

function exists_fail() {
	systemctl $USER_ARG list-units --all | grep "${NAME}.service"
}

function startup() {
	echo XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
	if exists ; then
		echo "send signal to exists instance"
		set -x
		exec "${SCRIPT}" "$@"
	elif exists_fail ; then
		journalctl --no-pager -u "${NAME}.service" || true
		systemctl reset-failed "${NAME}.service" || true
		echo "Error cleared, please re-run."
	else
		reset_important_config
		echo "starting new instance on display: $DISPLAY"
		env > "/tmp/jb.${NAME}.shopt"
		if systemctl $USER_ARG list-units --all | grep -q "${NAME}.service" ; then
			echo "reset last failed instance"
			systemctl $USER_ARG reset-failed "${NAME}.service"
		fi
		systemd-run \
			${USER_ARG} \
			${DEBUG_ARG} \
			--unit="${NAME}.service" \
			--description="Jetbrains ${NAME} process" \
			--slice="jetbrains.slice" \
			--service-type=simple \
			--setenv="DISPLAY=${DISPLAY}" \
			--property="EnvironmentFile=/tmp/jb.${NAME}.shopt" \
			--property="PrivateTmp=yes" \
			/bin/bash "${SCRIPT}" "$@"
		if [[ "$?" -ne 0 ]]; then
			systemctl $USER_ARG status "${NAME}.service" | cat
			echo -e "\n\n\n"
			journalctl $JUSER_ARG "${NAME}.service" | cat
			echo -e "\n\n\n"
			systemctl $USER_ARG reset-failed "${NAME}.service"
		fi
		unlink "/tmp/jb.${NAME}.shopt"
	fi
}

function _push_arg() {
	ARGV+=("$1")
}

function parse_args() {
	for ARG in "$@" ; do
		if [[ "$ARG" = "." ]] ;  then
			_push_arg "$(pwd)"
		elif [[ "${ARG:0:1}" = "." ]] && echo "$ARG" | grep -qE '^\.\.?/' ; then
			_push_arg "$(realpath -m "$ARG")"
		else
			_push_arg "$ARG"
		fi
	done
}

function escape() {
	echo "$*" | sed -e 's/[#$*.^]/\\&/g'
}

function _config_ensure() {
	local N=$1
	local V=$2
	local LINE="${N}=${V}"
	local CONFIG_FILE="$APPLICATION_PATH/bin/idea.properties"

	if ! grep -qEe "^$(escape ${LINE})$" "${CONFIG_FILE}" ; then
		echo "modify config file: ${CONFIG_FILE} with ${LINE}"
		sed "-i.bak" "s#^\# *$(escape ${N})=.*#${LINE}#g" "${CONFIG_FILE}"
		if cmp -s "${CONFIG_FILE}" "${CONFIG_FILE}.bak" ; then
			echo -e "\n${LINE}" >> "${CONFIG_FILE}"
		fi
		unlink "${CONFIG_FILE}.bak"
	fi
}

function _options_ensure() {
	local N=$1
	local V=$2
	local LINE="${N}${V}"
	local CONFIG_FILE="$APPLICATION_PATH/bin/${BASE}64.vmoptions"

	if ! grep -qEe "^$(escape ${LINE})$" "${CONFIG_FILE}" ; then
		sed "-i.bak" "s#^$(escape ${N}).*#${LINE}#g" "${CONFIG_FILE}"
		if cmp -s "${CONFIG_FILE}" "${CONFIG_FILE}.bak" ; then
			echo -e "\n${LINE}" >> "${CONFIG_FILE}"
		fi
		unlink "${CONFIG_FILE}.bak"
	fi
}

function reset_important_config() {
	_config_ensure idea.config.path "${JB_ROOT}/DATA/${NAME}/config"
	_config_ensure idea.system.path "${JB_ROOT}/DATA/${NAME}/system"
	_options_ensure '-Xms' 512m
	_options_ensure '-Xmx' 4G
	if [[ -e "${JB_ROOT}/crack.jar" ]] ; then
		echo "Running cracked"
		_options_ensure '-javaagent:' "${JB_ROOT}/crack.jar"
	fi
}

NAME="$APPLICATION_TITLE"
BASE="$APPLICATION_NAME"
APPLICATION_PATH="${JB_ROOT}/Applications/${NAME}"
SCRIPT="$APPLICATION_PATH/bin/${BASE}.sh"
CONFIG_FILE="$APPLICATION_PATH/${NAME}/bin/idea.properties"
declare -a ARGV

parse_args "$@"
echo "arguments: ${ARGV[*]}" >&2
startup "${ARGV[@]}"

