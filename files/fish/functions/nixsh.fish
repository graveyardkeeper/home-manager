function nixsh
    if test (count $argv) -eq 0
        echo "Usage: nixsh <package1> [package2...]"
        return 1
    end

    # set -g PATH (cached-nix-shell --expr "with (import $HOME/nix/default.nix {}).pkgs; mkShell {packages = [ $argv ];}" --run 'echo $PATH')
    set -l path (nix shell --extra-experimental-features "nix-command flakes" --impure --expr "with (import $HOME/nix/default.nix {}).pkgs; buildEnv {name=\"my-shell\";paths=[$argv];}" --command printenv PATH)
    and set -g PATH "$path"
    and echo "$PATH"
end
