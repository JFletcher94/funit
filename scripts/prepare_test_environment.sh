#!/bin/bash

# SPDX-License-Identifier: LGPL-3.0-or-later WITH FUnit-CI-Exception

set -euo pipefail

project_dir="${CI_PROJECT_DIR:-$PWD}"
artifacts_dir="$project_dir/artifacts/${MOD_NAME}"

mkdir -p "$CONFIG" "$MODS" /factorio/saves /factorio/scenarios /factorio/script-output

cp -a "$project_dir/$MOD_NAME/test/." /
cp -a "$artifacts_dir/test/." /
cp "$project_dir"/artifacts/*/*.zip /
cp "$artifacts_dir/save_names.txt" /save_names.txt
cp "$artifacts_dir/scenario_names.txt" /scenario_names.txt
cp -a "$artifacts_dir/scenarios/." /factorio/scenarios/

sed -i '/^write-data=/c\write-data=/factorio/' /opt/factorio/config/config.ini
envsubst < /server-settings.json > "$CONFIG/server-settings.json"
envsubst < /player-data.json > /factorio/player-data.json
