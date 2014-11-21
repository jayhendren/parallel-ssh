#!/bin/bash

usage="usage..."

parallel_opts='--no-notice --progress -P 0'
ssh_opts='-o StrictHostKeyChecking=no -o BatchMode=yes -x'
tag_str='[{}] '
tag_cmd="sed -e 's/^/${tag_str}/'"

hosts_file=""
logfile=""
tag="yes"

help () {
    echo "$usage"
    exit 2
}

if [[ "$@" == "--help" ]]; then
    help
fi

while getopts :f:l:s:p:nh opt; do
    case $opt in 
        f)
            hosts_file="${OPTARG}"
            ;;
        l)
            logfile="${OPTARG}"
            ;;
        s)
            ssh_opts="${OPTARG}"
            ;;
        p)
            parallel_opts="${OPTARG}"
            ;;
        n)
            tag="no"
            ;;
        h)
            help
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            help
            ;;
    esac
done

shift $((OPTIND-1))

cmd="$@"

ssh_cmd="( ssh ${ssh_opts} {} ${cmd} ) 2>&1"

if [[ "$tag" = "yes" ]]; then
    ssh_cmd="${ssh_cmd} | ${tag_cmd}"
fi

hostlist=""
while read line; do
    hostlist="$hostlist $line"
done < "${hosts_file:-/proc/${$}/fd/0}"

parallel_cmd="parallel ${parallel_opts} \"${ssh_cmd}\" ::: ${hostlist}"

if [[ -n "$logfile" ]]; then
    parallel_cmd="$parallel_cmd > $logfile"
fi

eval "$parallel_cmd"
