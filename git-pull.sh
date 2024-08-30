#!/usr/bin/env bash

waiting_interval=10 # In seconds
timeout=300         # In seconds

print_usage() {
    echo ""
    echo "NAME"
    echo "    git-pull -- pull git repository,"
    echo "                sync submodules if you need"
    echo "SYNOPSIS"
    echo "    git-pull -d <directory> -b <branch> [-s]"
    echo "DESCRIPTION"
    echo "    The following options are available:"
    echo "    -d    The path to the git repository"
    echo "    -b    The branch of the git repository"  
    echo "    -s    Check submodules"
    echo ""
    exit 1
}

check_arg() {
    if [[ $2 == -* ]]; then
        echo "Option $1 requires an argument" >&2
        exit 1
    fi
}

parse_param() {
    if [ -z "$1" ]; then
        echo "Empty list of options" >&2
        print_usage
    fi
    while getopts ":d:b:s" opt; do
        case $opt in
        d)
            check_arg "-d" "$OPTARG"
            LOCAL_REPO_PATH=${OPTARG}
            ;;
        b)
            check_arg "-b" "$OPTARG"
            BRANCH=${OPTARG}
            ;;
        s)
            check_sub=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            print_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            print_usage
            ;;
        esac
    done
}


main_script() {
    cd "$LOCAL_REPO_PATH" || exit 1

    REPO_URL=$(git config --get remote.origin.url)

    git pull $REPO_URL $BRANCH

    if [[ $check_sub ]]; then
        git submodule update --remote --recursive
    fi
}

parse_param "$@"
main_script
