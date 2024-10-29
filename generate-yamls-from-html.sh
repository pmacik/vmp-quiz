#!/bin/bash

questions_url="${1:-http://www.spspraha.cz/zkousky/otazky.asp?zp=M%202015}"

id=$(echo "$questions_url" | sed -e 's,.*zp=\(.*\),\1,g' | sed -e 's, ,_,g' | sed -e 's,%20,_,g')
html="$(readlink -m $id.html)"
curl -sSL -o "$html" "$questions_url"
#download images
mkdir -p "./public/images/$id"
pushd "./public/images/$id"
for i in $(grep -Po 'http://.*.jpg' "$html"); do
    curl -sSL -O $i
done
popd

# html -> txt
grep -E 'tázka|dpověď' "$html" | sed -e 's,.*<th .*>.*\(\( \?.tázka\|.dpověď\)\).*</th><td[^>]*>\([^<]*\)</td>\(<td[^>]*><img src="\(.*\)"></td>\)\?,\3;\5,g' >$id.txt

# txt -> yaml

{
    echo "questions:"
    for i in $(seq 1 $(wc -l <"$id.txt")); do
        if [ $((i % 4)) -eq 1 ]; then
            IFS=";" read -r -a tokens <<<"$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
            echo "- question: '${tokens[0]}'"
            if [ -z "${tokens[1]}" ]; then
                img=""
            else
                img="$id/$(basename "${tokens[1]}")"
            fi
            echo "  img: '$img'"
            echo "  answers:"
        elif [ $((i % 4)) -eq 2 ]; then
            line="$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
            echo "  - answer: '${line%;}'"
            echo "    correct: 'true'"
        elif [ $((i % 4)) -eq 3 ]; then
            line="$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
            echo "  - answer: '${line%;}'"
            echo "    correct: 'false'"
        else
            line="$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
            echo "  - answer: '${line%;}'"
            echo "    correct: 'false'"
        fi
    done
} >quizzes/$id.yaml