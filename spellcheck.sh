#!/bin/bash
SPELLING_MISSTAKES=0

# Allow words from wordlist.txt
aspell --lang=en create master /tmp/en-personal.pws < ./wordlist.txt
cp /tmp/en-personal.pws /usr/lib/aspell
echo "add en-personal.pws" >> /usr/lib/aspell/en_US.multi

for filename in ./content/posts/*.md; do
    SPELLING_MISSTAKES=`cat ${filename} | aspell list | wc -l`
    if [ "$SPELLING_MISSTAKES" -ne "0" ]; then
        echo "Spelling mistakes found in ${filename}. Run 'aspell check ${filename}' to correct"
    fi
done
