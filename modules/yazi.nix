{ pkgs, ... }:

let
  hmLib = import ./lib.nix { lib = pkgs.lib; };
in
{
  xdg.configFile."yazi".source = hmLib.cleanSource ../files/yazi [ "bookmark" ];
}
