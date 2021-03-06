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

quoteRe() {
	sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n';
}

function quoteSubst() {
  IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$1")
  printf %s "${REPLY%$'\n'}"
}

function add() {

  local FILE="$(date '+%Y%m%d-%H%M%S').html"
  local TITLE="$1"

  nano -w "$FILE" \
    && JSON=$(jq -n -c --null-input --arg date "$DATE" --arg title "$TITLE" --rawfile text "$FILE" --arg file "$FILE" '{"date":$date,"title":$title,"text":$text,"file":$file}') \
    && echo "$JSON" | jq \
    && JSON_ESCAPED=$(quoteSubst "$JSON") \
    && sed -i "s/$MARKER/$JSON_ESCAPED,\n\t\t\t$MARKER/g" "$MEMEX" \
    && git add . \
    && git commit -m "$FILE - $TITLE"
}

function edit() {

  local FILE

  if [ "${1-}" == "" ]; then
    FILE=$(ls -t /opt/git/memex/*-*.html | head -1)
  else
    FILE="/opt/git/memex/$1"
  fi

  local TITLE=$(cat "$MEMEX" | grep -oP "(?<=\"title\":\")(.*)(?=\",\"text\".*$(basename $FILE))")

  nano -w "$FILE" \
    && JSON=$(jq -n -c --null-input --arg date "$DATE" --arg title "$TITLE" --rawfile text "$(basename $FILE)" --arg file "$FILE" '{"date":$date,"title":$title,"text":$text,"file":$file}') \
    && echo "$JSON" | jq \
    && JSON_ESCAPED=$(quoteSubst "$JSON") \
    && sed -i "s/^.*$(basename $FILE).*$/\t\t\t$JSON_ESCAPED,/g" "$MEMEX" \
    && git add . \
    && git commit -m "Fixup! $(basename $FILE) - $TITLE"
}

if [ "${1-}" == "" ]; then
  edit
elif [[ "$1" =~ ^[0-9]{8}-[0-9]{6}\.html$ ]]; then
  edit "$1"
else
  add "$1"
fi


