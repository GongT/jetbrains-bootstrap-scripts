#!/usr/bin/env bash

WHAT="$1"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib/lib.sh

load_application "$WHAT"

bash lib/download-application.sh "$WHAT"
bash lib/create-bin.sh "$WHAT"

echo 'export PATH=${PATH}:/opt/JetBrains/bin' > '/etc/profile.d/jetbrains.sh'
