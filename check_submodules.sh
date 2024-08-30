#!/usr/bin/env bash

# Параметры
LOCAL_REPO_PATH="/home/coral/git/tp-seti/auth-erp-tp-seti-front"

# Функция для проверки изменений подмодулей
check_submodules() {
    cd "$LOCAL_REPO_PATH" || exit 1

    # Обновить информацию о удаленном репозитории
    git fetch

    # Обновить все подмодули
    #git submodule update --init --recursive

    # Получить список подмодулей
    submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

    # Флаг изменений подмодулей
    submodules_changed=false

    for submodule in $submodules; do
        echo "Checking submodule: $submodule"

        # Перейти в подмодуль
        cd "$submodule" || continue

        # Получить локальный и удаленный хэши подмодуля
        local_sha=$(git rev-parse HEAD)
        remote_sha=$(git ls-remote origin -h HEAD | awk '{print $1}')

        # Проверить, изменился ли подмодуль
        if [[ "$local_sha" != "$remote_sha" ]]; then
            echo "Submodule $submodule has changed: $local_sha -> $remote_sha"
            submodules_changed=true
        else
            echo "Submodule $submodule is up to date."
        fi

        # Вернуться в корневую директорию репозитория
        cd "$LOCAL_REPO_PATH" || exit 1
    done

    if [ "$submodules_changed" = true ]; then
        echo "One or more submodules have changed."
        return 0
    else
        echo "No submodules have changed."
        return 1
    fi
}

check_submodules
