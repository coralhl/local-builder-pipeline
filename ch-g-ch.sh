#!/usr/bin/env bash

WAITING_INTERVAL=10 # In seconds
TIMEOUT=300         # In seconds

# Напечатать, как использовать скрипт
print_usage() {
    echo ""
    echo "NAME"
    echo "    ch-g-ch -- checks a git repository if it synced with its origin,"
    echo "               check submodules if you need"
    echo "SYNOPSIS"
    echo "    ch-g-ch -d <directory> -b <branch> [-s]"
    echo "DESCRIPTION"
    echo "    The following options are available:"
    echo "    -d    The path to the git repository"
    echo "    -b    The branch of the git repository"    
    echo "    -s    Check submodules"
    echo ""
    exit 1
}

# Проверить аргумены 
check_arg() {
    if [[ $2 == -* ]]; then
        echo "Option $1 requires an argument" >&2
        exit 1
    fi
}

# Распарсить параметры
parse_param() {
    if [ -z "$1" ]; then
        echo "Empty list of options" >&2
        print_usage
        exit 1
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

validate_git_directory() {
    if [[ -z "$LOCAL_REPO_PATH" ]]; then
        echo -e "\nERROR: Git directory (-d) not given!" >&2
        print_usage
    fi

    if [[ -z "$BRANCH" ]]; then
        echo -e "\nERROR: Git branch (-b) not given!" >&2
        print_usage
    fi

    if [[ ! -d "$LOCAL_REPO_PATH/.git" ]] || [[ ! -r "$LOCAL_REPO_PATH/.git" ]]; then
        echo "ERROR: Git directory (-d) not found: '$LOCAL_REPO_PATH/.git'!" >&2
        print_usage
    fi

    if [[ ! -w "$LOCAL_REPO_PATH/.git" ]]; then
        echo "ERROR: Missing write permissions for the git directory (-d): '$LOCAL_REPO_PATH/.git'!" >&2
        print_usage
    fi

    # Convert to absolute file path if necessary
    if [[ "$LOCAL_REPO_PATH" != /* ]]; then
        LOCAL_REPO_PATH="$PWD/$LOCAL_REPO_PATH"
    fi
}

check_git_lock() {
    local seconds=0
    local TIMEOUT_remaining=$TIMEOUT

    ((TIMEOUT_remaining=TIMEOUT-$WAITING_INTERVAL))
    until [ ! -f ".git/index.lock" ]; do
        if (( seconds > TIMEOUT_remaining )); then
            echo "Giving up..."
            exit 1
        fi
        echo "ERROR: Git repository is locked, waiting to unlock..."
        ((seconds+=WAITING_INTERVAL))
        sleep $WAITING_INTERVAL
    done
}

# Функция для проверки изменений
check_branch() {
    # Проверка наличия ветки
    if ! git show-ref --verify --quiet refs/heads/"$BRANCH"; then
        echo "Branch '$BRANCH' does not exist."
        exit 1
    fi

    # Проверить изменения в указанном репозитории
    LOCAL=$(git rev-parse "$BRANCH")
    REMOTE=$(git rev-parse "origin/$BRANCH")

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Основной репозиторий изменён."
        br_ch=1
    else
        echo "Основной репозиторий не изменён."
    fi
}

# Функция для проверки изменений подмодулей
check_submodules() {
    # Получить список подмодулей
    submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

    for submodule in $submodules; do
        echo "Checking submodule: $submodule"

        # Перейти в подмодуль
        cd "$submodule" || continue

        # Получить локальный и удаленный хэши подмодуля
        local_sha=$(git rev-parse HEAD)
        remote_sha=$(git ls-remote origin -h HEAD | awk '{print $1}')

        # Проверить, изменился ли подмодуль
        if [[ "$local_sha" != "$remote_sha" ]]; then
            echo "Подмодуль $submodule был изменён: $local_sha -> $remote_sha"
            ((sm_ch++))
        else
            echo "Подмодуль $submodule не изменён."
        fi

        # Вернуться в корневую директорию репозитория
        cd "$LOCAL_REPO_PATH" || exit 1
    done

    if [ "$sm_ch" -ne 0 ]; then
        echo "Один или больше подмодулей были изменены."
    else
        echo "Подмодули не изменены."
    fi
}

main_git() {
    # Перейти в локальный репозиторий
    cd "$LOCAL_REPO_PATH" || exit 1

    # Обновить информацию об удалённом репозитории
    git fetch

    br_ch=0
    sm_ch=0

    # Проверка изменений ветки
    check_branch

    if [[ $check_sub ]]; then
        # Проверка изменений подмодулей
        check_submodules
    fi

    if [ $br_ch -ne 0 ] || [ $sm_ch -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

parse_param "$@"

validate_git_directory

check_git_lock

main_git
