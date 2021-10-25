#/bin/bash

nouns=($(shuf -n3 /usr/share/dict/web2a))
con=($(shuf -n2 /usr/share/dict/connectives))

echo ${nouns[0]}-${con[0]}-${nouns[1]}-${con[1]}-${nouns[2]}
