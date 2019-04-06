#!/usr/bin/env bash

what=$1
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib.sh

load_application "$what"

RELEASE_URL="https://data.services.jetbrains.com/products/releases?code=$APPLICATION_CODE&latest=true&type=release&build="
echo "Finding download url..."
echo "  -- $RELEASE_URL"

PAGE=$(curl -s "$RELEASE_URL")
DOWNLOAD=$(echo "$PAGE" | jq -rM '.[][].downloads.linux.link')
FILENAME=$(basename "$DOWNLOAD")
TARGET_PATH="$(dirname "$LIB_ROOT")/.download"
mkdir -p "$TARGET_PATH"

echo "Download from: $DOWNLOAD"
echo "         to: $TARGET_PATH/$FILENAME"

if [[ -e "$TARGET_PATH/$FILENAME" ]]; then
	echo "Target already exists."
else
	wget -c --quiet --show-progress --progress=bar:force -O "$TARGET_PATH/$FILENAME.tmp" "$DOWNLOAD"
	echo "Downloaded."
	mv "$TARGET_PATH/$FILENAME.tmp" "$TARGET_PATH/$FILENAME"
	echo ""
fi

INSTALL_TARGET="$(dirname "$LIB_ROOT")/Applications/${APPLICATION_TITLE}"
echo "Extract to: $INSTALL_TARGET"
mkdir -p "$INSTALL_TARGET"
tar xf "$TARGET_PATH/$FILENAME" -C "$INSTALL_TARGET" --strip-components=1

echo "Done."
