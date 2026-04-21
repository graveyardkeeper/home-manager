{ pkgs, ... }:

{
  home.packages = [ pkgs.lazygit ];

  xdg.configFile."lazygit".source = ../files/lazygit;
}
