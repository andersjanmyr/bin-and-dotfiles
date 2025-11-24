#!/bin/bash
#
set -o errexit

biz=${1?'biz is required'}
sql_file=${2:-'script.sql'}
user=${user:-'smrtreadonly'}
DB_HOST=${DB_HOST:-mysql-ro-prod5}
used_implicitly=${MYSQL_PWD?'is required'}

echo $biz
mysql --verbose -A -u $user -h $DB_HOST -P 3306 -D "${biz}_prod" < "$sql_file"
