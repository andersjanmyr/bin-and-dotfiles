#!/usr/bin/env bash
#
set -e

queues=( "_aaa_async_jobs_deadletter.fifo"
"_aaa_background_jobs_deadletter.fifo"
"_aaa_batch_jobs_deadletter"
"_aaa_data_sync_jobs_deadletter"
"_aaa_delayed_jobs_deadletter"
"_aaa_elastic_jobs_deadletter"
"_aaa_elastic_report_jobs_deadletter"
"_aaa_import_jobs_deadletter"
"_aaa_pdf_jobs_deadletter.fifo"
"_aaa_slow_jobs_deadletter"
"_aaa_sysop_jobs_deadletter")



aws_profile="$1"
[ -z "$1" ] && echo "please specify aws profile" && exit

get_aws_account_id() {
  aws sts get-caller-identity --profile $1|jq -r .Account
}

strip_cdk() {
 echo "$1" |cut -d- -f2
}

strip_deadletter() {
  echo "$1" |sed 's/_deadletter//g'
}

get_number_of_msgs(){
  aws sqs get-queue-attributes --attribute-names ApproximateNumberOfMessages \
  --queue-url https://sqs.us-east-1.amazonaws.com/$(get_aws_account_id $aws_profile)/$1 \
  --profile $aws_profile|jq -r .Attributes.ApproximateNumberOfMessages
}
deadletters() {
  for q in ${queues[@]}; do
    #echo "https://sqs.us-east-1.amazonaws.com/$(get_aws_account_id $aws_profile)/production_phpweb-$(strip_cdk $1)$q"
    queue="production_phpweb-$(strip_cdk $1)$q"
    echo "$queue: $(get_number_of_msgs $queue)"
  done
}

queues() {
  echo "queues"
  for q in ${queues[@]}; do
    #echo "https://sqs.us-east-1.amazonaws.com/$(get_aws_account_id $aws_profile)/production_phpweb-$(strip_cdk $1)$q"
    dead_queue="production_phpweb-$(strip_cdk $1)$q"
    queue="$(strip_deadletter $dead_queue)"
    echo "$queue: $(get_number_of_msgs $queue)"
  done
}
[ -z "$2" ] && deadletters "$1" || queues "$1"
