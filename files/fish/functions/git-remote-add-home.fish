function git-remote-add-home
    set -l name "$argv[1]"
    if test -z "$name"
        echo "Usage: $(status current-command) REPO_NAME" >&2
        return 1
    end
    git remote add home "git@git.lubui.com:$name.git"
    git remote -v
    echo "git push --set-upstream home master"
end
