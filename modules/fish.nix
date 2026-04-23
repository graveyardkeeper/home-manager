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
        # Tide stores its preset in universal variables, so seed it once per machine.
        if not set -q tide_configured_by_hm
          tide configure --auto --style=Lean --prompt_colors='True color' --show_time=No --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Few icons' --transient=No
          set -U tide_character_vi_icon_default ❯
          set -U tide_configured_by_hm 1
        end
      end
    '';
  };

  xdg.configFile."fish/functions".source = hmLib.cleanSource ../files/fish/functions [ ];
}
