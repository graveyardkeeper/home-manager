function git-server-new-repo
    set -l name "$argv[1]"
    if test -z "$name"
        echo "Usage: $(status current-command) REPO_NAME" >&2
        return 1
    end
    sudo -u git sh -c "mkdir ~/$name.git && cd ~/$name.git && git init --bare"
    echo "git remote add home git@git.lubui.com:$name.git"
    echo "git push home"
end
