#!/usr/bin/env bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib/lib.sh

export SETTINGS_ROOT="$(dirname "$LIB_ROOT")/settings-repo"

REMOTE_GIT_URL=
if [[ -e "$SETTINGS_ROOT" ]] && [[ -e "$SETTINGS_ROOT/HEAD" ]]; then
	pushd "$SETTINGS_ROOT"
	REMOTE_GIT_URL=$(git remote get-url --push origin || true)
	REMOTE_GIT_URL=$(echo ${REMOTE_GIT_URL})
	popd
fi

echo "Where is your remote git storage url?"
if [[ -n "$REMOTE_GIT_URL" ]]; then
	echo "Current is: $REMOTE_GIT_URL (leave empty if not change this)"
fi
read -p "> " NEW_REMOTE_GIT_URL

if [[ -z "$NEW_REMOTE_GIT_URL" ]] || [[ "$REMOTE_GIT_URL" = "$NEW_REMOTE_GIT_URL" ]]; then
	echo "Will not clone or update."
else
	echo ""
	echo -e "Clone $NEW_REMOTE_GIT_URL to $SETTINGS_ROOT"
	echo ""
	read -p "press Enter to continue."

	rm -rf "$SETTINGS_ROOT"
	mkdir -p "$SETTINGS_ROOT"
	git clone --mirror "$NEW_REMOTE_GIT_URL" "$SETTINGS_ROOT"
fi

function write_ignore() {
	push_gitignore_line 'tasks/'
	push_gitignore_line 'port.lock'
	push_gitignore_line 'port'
	push_gitignore_line '*.key'

	push_gitignore_line 'settingsRepository/'
	push_gitignore_line 'plugins/idea-multimarkdown/'
	push_gitignore_line 'plugins/PowerShell/lib/LanguageHost/'

	push_gitignore_line 'terminal/history/'
	push_gitignore_line 'options/recentProjectDirectories.xml*'
	push_gitignore_line 'options/window.manager.xml'
	push_gitignore_line 'options/window.state.xml'
	push_gitignore_line 'options/statistics.*.xml'
	push_gitignore_line 'options/*.statistics.xml'
	push_gitignore_line 'options/dimensions.xml'
	push_gitignore_line 'options/options.xml'

	push_gitignore_line 'javascript/nodejs/'
	push_gitignore_line '**/*.jar'
	push_gitignore_line '**/*.exe'
	push_gitignore_line '**/*.dll'
	push_gitignore_line '**/*.so'
}

cd "$(dirname "$LIB_ROOT")"
for P in lib/apps/*.sh ; do
	source "$P"
	mkdir -p "DATA/$APPLICATION_TITLE/config"
	pushd "DATA/$APPLICATION_TITLE/config"
	rm -rf .git
	TARGET=$(pwd)

	pushd "$SETTINGS_ROOT"
	mv "$TARGET" "$TARGET.BAK"

	echo "run [git worktree add] for $APPLICATION_NAME"
	git worktree add --checkout -f "$TARGET" master

	mv "$TARGET/.git" "$TARGET.BAK/.git"
	rm -rf "$TARGET"

	mv "$TARGET.BAK" "$TARGET"

	popd

	write_ignore
	popd
done

cd "$SETTINGS_ROOT"
git worktree prune