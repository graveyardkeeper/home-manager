{ pkgs, ... }:

let
  hmLib = import ./lib.nix { lib = pkgs.lib; };
in
{
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];
    shellAliases = {
      lg = "lazygit";
      nv = "nvim";
    };
    interactiveShellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
      set -gx SHELL (command -s fish)
      if status is-interactive
      end
    '';
  };

  xdg.configFile."fish/functions".source = hmLib.cleanSource ../files/fish/functions [ ];
}
