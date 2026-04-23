{ pkgs, ... }:

let
  hmLib = import ./lib.nix { lib = pkgs.lib; };
in
{
  xdg.configFile."kitty/kitty.conf".text = ''
    shell ${pkgs.fish}/bin/fish
    globinclude kitty.d/**/*.conf
  '';

  xdg.configFile."kitty/kitty.d".source = hmLib.cleanSource ../files/kitty/kitty.d [ ];
  xdg.configFile."kitty/scripts".source = hmLib.cleanSource ../files/kitty/scripts [ ];
  xdg.configFile."kitty/quick-access-terminal.conf".source = ../files/kitty/quick-access-terminal.conf;
}
