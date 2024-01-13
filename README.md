### About

A simple bash script to watch a git repository and pull upstream changes if available (including submodules).
If there are changes, the image will be built and push into the docker registry.

Based on repo https://github.com/kolbasa/git-repo-watcher

### Requirements

* Bash with Version > 3
* Tested on Ubuntu, Debian

Basically, it will work anywhere you can install Bash.

### Usage

You only need the path to your git repository to start.  
Make sure your local repository is tracking a remote branch, otherwise the script will fail.

This will start a script:
```bash
./lbpl -d "/path/to/your/repository"
```

You can also turn on submodules changes check by passing `-s`.  
```bash
./lbpl -d "/path/to/your/repository" -s
```

You can buld & push image even if there are no changes in repo by passing `-b`.  
```bash
./lbpl -d "/path/to/your/repository" -b
```

Folder `tmpl-repo` contains files `build.sh` and `VERSION`. Copy them to your repository folder and edit them.
The logic for building and pushing image is written in `build.sh`.
If `VERSION` file exists, then tag for image will be read from it.

### Customizations

You can add your own logic to the file: [`lbpl-hooks`](https://github.com/coralhl/local-builder-pipeline/blob/master/lbpl-hooks)

For example, you can start your specific process in case of changes:

```bash
# $1 - Git repository name
# $2 - Branch name
# $3 - Commit details
change_pulled() {
    echo "Starting process for commit: $@"
    ./your-specific-script.sh
}
```

If you have more than one repository you can pass a copy of the `lbpl-hooks` file like so:
```bash
./lbpl -d "/path/to/your/repository" -h "/path/to/your/hooks-file"
```

### Private repositories

The script works with private repositories.  

First configure a password cache with `git config --global credential.helper "cache --timeout=60"`.  
Make sure the `timeout` is greater than the time interval given to the script. Both are given as seconds.  
The program will execute `git fetch` and ask for your login data. The script itself **does not** store passwords!

If you want it to run in the background as a daemon process, you have to execute `git fetch` beforehand.

Example code:

```bash
cd "/path/to/your/repository"
git config --global credential.helper "cache --timeout=60"
git fetch

# Checking exit code
if [[ $? -eq 1 ]]; then
    echo "Wrong password!" >&2
    exit 1
fi

# Disown process
./git-repo-watcher -d "/path/to/your/repository" > "/path/to/your/logfile.log" & disown
```
