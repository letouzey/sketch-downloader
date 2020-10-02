#!/bin/sh

## Download internal data of a https://sketch.sh page (in json format)
## Pierre Letouzey, 2020
## This file is released under the CC0 License, see the LICENSE file

# Reference : https://github.com/Sketch-sh/sketch-sh/blob/master/client/src/gql/GqlGetNoteById.re
# See also https://github.com/Sketch-sh/sketch-sh/issues/41
# For now, I've removed user_id, fork_from, updated_at

TOKEN=$1
OUT=$2

if [ -z $TOKEN ]; then
    echo "usage: $0 Sketch_ID_or_URL {out.json}";
    exit 1;
fi

# Hack for fetching Sketch ID from URL :)
# Works with https:// and http://, with trailing / or not,
# and keeps IDs untouched
TOKEN=$(basename $TOKEN)

if [ ${#TOKEN} -ne 22 ]; then
    echo "Error: bad length of sketch ID $TOKEN"
    exit 1;
fi

if [ -z $OUT ]; then
    OUT=$TOKEN.json;
fi

curl -sS 'https://api.sketch.sh/graphql' \
     -o $OUT \
     -H 'content-type: application/json' \
     --data-raw '{"operationName":"getNoteById","variables":{"noteId":"'$TOKEN'"},"query":"query getNoteById($noteId: String!) {note: note(where: {id: {_eq: $noteId}}) {id title data}}"}'
