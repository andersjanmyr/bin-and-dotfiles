#!/bin/bash
#
set -o errexit

biz=${1?'biz is required'}
sql_file=${2:-'script.sql'}
user=${user:-'smrtreadonly'}
used_implicitly=${MYSQL_PWD?'is required'}

echo $biz
mysql --verbose -A -u $user -h 127.0.0.1 -P 3306 -D "${biz}_prod" < "$sql_file"
