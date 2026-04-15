#!/bin/bash

ANY_FAILURE=0
EARLY_SUCCESS_FLAG="/funit_early_success.$$"

mkdir -p /factorio/saves

# TODO: Move saves to $SAVES
if [ -s "save_names.txt" ]; then
    for fn in $(cat save_names.txt); do
        EXIT_CODE=0
        echo "____SCENARIO____: $fn"

        cp "/$ARCHIVE_NAME" "$MODS"/
        cp "/mod-list.json" "$MODS"/
        export UPDATE_IGNORE="${MOD_NAME}"
        /docker-update-mods.sh

        export SAVE_NAME=$fn
        export EARLY_SUCCESS_FLAG
        timeout -f "$TIMEOUT" bash -c '/opt/factorio/bin/x64/factorio \
            --start-server "$SAVE_NAME" \
            --sync-mods "$SAVE_NAME" \
            --mod-directory "$MODS" \
            --server-settings "$CONFIG/server-settings.json" 2>&1 | \
        while IFS= read -r line; do
            printf "%s\\n" "$line"
            case "$line" in
                (*__FUNIT__*====END====*)
                    echo "FUNIT end signal detected"
                    touch "$EARLY_SUCCESS_FLAG"
                    pkill -TERM -f ".*factorio.*--start-server" 2>/dev/null || true
                    exit 0
                    ;;
            esac
        done
        exit ${PIPESTATUS[0]}'

        EXIT_CODE=$?
        if [ -f "$EARLY_SUCCESS_FLAG" ]; then
            rm -f "$EARLY_SUCCESS_FLAG"
            EXIT_CODE=0
        fi
        if [ "$EXIT_CODE" -ne 124 ] && [ "$EXIT_CODE" -ne 0 ]; then
            ANY_FAILURE=$EXIT_CODE
        fi
        sleep 1
    done
fi

if [ -s "scenario_names.txt" ]; then
    mkdir -p /mods_cache
    cp /*.zip /mods_cache/
    for fn in $(cat scenario_names.txt); do
        EXIT_CODE=0
        UPDATE_IGNORE=""
        mv "$MODS"/*.zip /mods_cache 2>/dev/null || true
        echo "____SCENARIO____: $fn"

        if [ -s "/factorio/scenarios/$fn/mod-list.json" ]; then
            echo "Using $fn/mod-list.json"
            cp "/factorio/scenarios/$fn/mod-list.json" "$MODS"/
        else
            echo "Using default mod-list.json"
            cp "/mod-list.json" "$MODS"/
        fi
        if [ -s "factorio/scenarios/$fn/mod-settings.dat" ]; then
            echo "Using $fn/mod-settings.dat"
            cp "factorio/scenarios/$fn/mod-settings.dat" "$MODS"/
        else
            echo "Using default mod settings"
            rm -f "$MODS/mod-settings.dat"
        fi

        for next_mod in $(jq -r '.mods[] | select(.enabled == true) | .name'  "$MODS"/mod-list.json); do
            case "$next_mod" in
                ("base"|"quality"|"elevated-rails"|"space-age") continue ;; 
            esac

            for zipfile in /mods_cache/"${next_mod}"_*.zip; do
                [ -f $zipfile ] || continue
                cp $zipfile "$MODS"/
                UPDATE_IGNORE="${UPDATE_IGNORE:+$UPDATE_IGNORE,}${next_mod}"
            done
        done
        export UPDATE_IGNORE
        /docker-update-mods.sh

        export SCENARIO_NAME=$fn
        export EARLY_SUCCESS_FLAG
        timeout -f "$TIMEOUT" bash -c '/opt/factorio/bin/x64/factorio \
            --load-scenario "$SCENARIO_NAME" \
            --mod-directory "$MODS" 2>&1 | \
        while IFS= read -r line; do
            printf "%s\\n" "$line"
            case "$line" in
                (*__FUNIT__*====END====*)
                    echo "FUNIT end signal detected"
                    touch "$EARLY_SUCCESS_FLAG"
                    pkill -TERM -f ".*factorio.*--start-server-load-scenario" 2>/dev/null || true
                    exit 0
                    ;;
            esac
        done
        exit ${PIPESTATUS[0]}'

        EXIT_CODE=$?
        if [ -f "$EARLY_SUCCESS_FLAG" ]; then
            rm -f "$EARLY_SUCCESS_FLAG"
            EXIT_CODE=0
        fi
        if [ "$EXIT_CODE" -ne 124 ] && [ "$EXIT_CODE" -ne 0 ]; then
            ANY_FAILURE=$EXIT_CODE
        fi
        sleep 1
    done
fi

if [ ! -s "scenario_names.txt" ] && [ ! -s "save_names.txt" ]; then
    EXIT_CODE=0
    export UPDATE_MODS_ON_START="true"
    export UPDATE_IGNORE="${MOD_NAME}"
    echo "____SCENARIO____: freeplay"
    echo "Using default mod-list.json"
    cp "/$ARCHIVE_NAME" "$MODS"/
    cp "/mod-list.json" "$MODS"/
    timeout -f "$TIMEOUT" /docker-entrypoint.sh || EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 124 ] && [ "$EXIT_CODE" -ne 0 ]; then
        ANY_FAILURE=$EXIT_CODE
    fi
fi

exit $ANY_FAILURE
