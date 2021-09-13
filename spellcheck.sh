#!/bin/bash
SPELLING_MISSTAKES=0
PWS_FILE_PATH="/tmp/en-personal.pws"
ASPELL_LIB_PATH="/usr/lib/aspell"

# Allow words from wordlist.txt
rm -f ${PWS_FILE_PATH}
aspell --lang=en create master ${PWS_FILE_PATH} < ./wordlist.txt
cp ${PWS_FILE_PATH} ${ASPELL_LIB_PATH}
echo "add en-personal.pws" >> ${ASPELL_LIB_PATH}/en_US.multi

for filename in ./content/posts/*.md; do
    SPELLING_MISSTAKES=`cat ${filename} | aspell list | sort -u | wc -l`
    if [ "$SPELLING_MISSTAKES" -ne "0" ]; then
        echo "Spelling mistakes found in ${filename}. Run 'aspell check ${filename}' to correct"
        echo "---------------------------------------------------------------------------------"
        cat ${filename} | aspell list | sort -u
    fi
done
