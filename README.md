# Parallel SSH

A simple shell script to broadcast SSH commands to multiple hosts in parallel.

*Requires [GNU Parallel](http://www.gnu.org/software/parallel/)*.

## Usage

    Usage: pssh.sh [-nh] [-f HOSTLIST_FILE] [-l LOGFILE] [-s SSH_OPTIONS]
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
        -o StrictHostKeyChecking=no -o BatchMode=yes -x
    
    -p PARALLEL_OPTIONS
        Options to pass on to the parallel command.  If not provided,
        defaults to:
        --no-notice --progress -P 0
    
    -n
        Do not append a tag to the beginning of log output.  If this flag
        is not given, then every log line will be prefixed with the string
        "[hostname] " to make it easier to tell what lines in the output
        came from which host.
    
    -h, --help
        Show this help output.

## Example

Setup:

    [damona ~]% cat > example_hosts
    euclid.colorado.edu
    verbs.colorado.edu
    totally.bogus.hostname
    [damona ~]% touch example_log

Run pssh:

    [damona ~]% pssh.sh -f example_hosts -l example_log "echo hello from {}; hostname; boguscommand; echo bye from {}"
    
    Computers / CPU cores / Max jobs to run
    1:local / 8 / 3
    
    Computer:jobs running/jobs completed/%of started jobs/Average seconds to complete
    local:0/3/100%/0.0s 

Take a look at the output:

    [damona ~]% cat example_log 
    [totally.bogus.hostname] ssh: totally.bogus.hostname: Name or service not known
    [euclid.colorado.edu] hello from euclid.colorado.edu
    [euclid.colorado.edu] euclid.colorado.edu
    [euclid.colorado.edu] zsh:1: command not found: boguscommand
    [euclid.colorado.edu] bye from euclid.colorado.edu
    [verbs.colorado.edu] hello from verbs.colorado.edu
    [verbs.colorado.edu] verbs.colorado.edu
    [verbs.colorado.edu] bye from verbs.colorado.edu
    [verbs.colorado.edu] zsh:1: command not found: boguscommand
    
