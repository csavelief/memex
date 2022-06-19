#!/bin/bash

# Exits when a command fails.
set -o errexit

# Use "strict mode with pipefail" (exit without continuing at first error).
set -o pipefail

# Detects uninitialised variables in your script (and exits with an error).
set -o nounset

# Prints every expression before executing it.
# set -o xtrace

# Immutable global variables
readonly MEMEX="/opt/git/memex/memex.html"
readonly MARKER="{date: '', title: '', text: '', file: ''}"
readonly DATE=$(date '+%Y-%m-%d %H:%M')

function add() {

  local FILE="$(date '+%Y%m%d-%H%M%S').html"
  local TITLE="$1"

  nano -w "$FILE" \
    && JSON=$(jq -n -c --null-input --arg date "$DATE" --arg title "$TITLE" --rawfile text "$FILE" --arg file "$FILE" '{"date":$date,"title":$title,"text":$text,"file":$file}') \
    && echo "$JSON" | jq \
    && JSON_ESCAPED=$(printf '%s' "$JSON" | sed -e 's/[]\/$*.^[]/\\&/g') \
    && sed -i "s/$MARKER/$JSON_ESCAPED,\n\t\t\t$MARKER/g" "$MEMEX" \
    && git add . \
    && git commit -m "$FILE - $TITLE"
}

function edit() {

  local FILE=$(ls -t /opt/git/memex/*-*.html | head -1)
  local TITLE=$(cat "$MEMEX" | grep -oP "(?<=\"title\":\")(.*)(?=\",\"text\".*$(basename $FILE))")

  nano -w "$FILE" \
    && JSON=$(jq -n -c --null-input --arg date "$DATE" --arg title "$TITLE" --rawfile text "$FILE" --arg file "$FILE" '{"date":$date,"title":$title,"text":$text,"file":$file}') \
    && echo "$JSON" | jq \
    && JSON_ESCAPED=$(printf '%s' "$JSON" | sed -e 's/[]\/$*.^[]/\\&/g') \
    && sed -i "s/^.*$(basename $FILE).*$/\t\t\t$JSON_ESCAPED,/g" "$MEMEX" \
    && git add . \
    && git commit -m "Fixup! $(basename $FILE) - $TITLE"
}

if [ "${1-}" == "" ]; then
  edit
else
  add "$1"
fi


