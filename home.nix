{ username, homeDirectory, ... }:

{
  imports = [
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/neovim.nix
    ./modules/scripts.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
