#!/bin/bash

hostname=${1?hostname is required}
key=${2?key is required}
sshuttle --dns -vr ec2-user@$hostname 0/0 --ssh-cmd "ssh -i $key"
