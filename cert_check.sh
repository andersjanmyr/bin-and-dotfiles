#!/bin/bash

domain=$1

openssl s_client -connect $domain:443 -servername $domain
