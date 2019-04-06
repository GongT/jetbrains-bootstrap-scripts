#!/usr/bin/env bash

what=$1
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib.sh

load_application "$what"

TARGET_PATH="$(dirname "$LIB_ROOT")/bin"
mkdir -p "$TARGET_PATH"

echo "Create application $APPLICATION_TITLE as $BIN_NAME"
echo "  in folder $TARGET_PATH"

cat << EOF > "$TARGET_PATH/$BIN_NAME"
#!/usr/bin/env bash

APPLICATION_TITLE="${APPLICATION_TITLE}"
APPLICATION_NAME="${APPLICATION_NAME}"
JB_ROOT="$(dirname "$LIB_ROOT")"
${APPEND_SCRIPT}
source "\${JB_ROOT}/jetbrains.boot.sh" "\${@}"

EOF

chmod a+x "$TARGET_PATH/$BIN_NAME"
