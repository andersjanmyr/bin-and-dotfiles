#!/bin/bash

ES_URL=$ES_QA3 es.sh /_cat/aliases |grep _index | awk '{ print $1 }' | sort | tee ~/tmp/elastic_indexes.txt
