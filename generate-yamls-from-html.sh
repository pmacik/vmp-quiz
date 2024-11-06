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
        line="$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
        IFS=";" read -r -a tokens <<<"$line"
        text="${tokens[0]}"
        if [ -z "${tokens[1]}" ]; then
            img=""
        else
            img="$id/$(basename "${tokens[1]}")"
        fi
        if [ $((i % 4)) -eq 1 ]; then
            echo "- question: '$text'"
            echo "  img: '$img'"
            echo "  answers:"
        elif [ $((i % 4)) -eq 2 ]; then
            echo "  - answer: '$text'"
            echo "    correct: 'true'"
            echo "    img: '$img'"
        else
            line="$(sed -n "${i}p" "$id.txt" | tr -d '\r\n')"
            echo "  - answer: '$text'"
            echo "    correct: 'false'"
            echo "    img: '$img'"
        fi
    done
} >quizzes/$id.yaml
