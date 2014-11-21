#!/bin/bash

parallel_opts='--no-notice --progress -P 0'
ssh_opts='-o StrictHostKeyChecking=no -o BatchMode=yes -x'
tag_str='[{}] '
tag_cmd="sed -e 's/^/${tag_str}/'"

usage="Usage: $(basename ${0}) [-nh] [-f HOSTLIST_FILE] [-l LOGFILE] [-s SSH_OPTIONS]
    [-p PARALLEL_OPTIONS] COMMAND ...

Runs COMMAND over SSH on all given hosts in parallel.

Requires GNU Parallel.

The string '{}' in COMMAND will be replaced with the hostname when
COMMAND is run.  Other template strings are available as well.  See the
GNU Parallel man page for more info.

-f HOSTLIST_FILE
    Specifies a file containing a list of hostnames to run commands on
    over SSH.  One hostname per line.  If this option is not provided,
    hostnames are read from stdin instead.

-l LOGFILE
    Specifies a file to write log output.  If not provided, logs are
    written to stdout.  Diagnostic information will always be written to
    stderr regardless of whether logs are written to stdout or a logfile.

-s SSH_OPTIONS
    Options to pass on to the SSH command.  If not provided, defaults
    to:
    $ssh_opts

-p PARALLEL_OPTIONS
    Options to pass on to the parallel command.  If not provided,
    defaults to:
    $parallel_opts

-n
    Do not append a tag to the beginning of log output.  If this flag
    is not given, then every log line will be prefixed with the string
    \"[hostname] \" to make it easier to tell what lines in the output
    came from which host.

-h, --help
    Show this help output.
"

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

ssh_cmd="( ssh ${ssh_opts} {} '${cmd}' ) 2>&1"

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
