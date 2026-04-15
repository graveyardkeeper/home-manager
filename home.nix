{ ... }:

{
  imports = [
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/neovim.nix
    ./modules/scripts.nix
  ];

  home.username = "bytedance";
  home.homeDirectory = "/Users/bytedance";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
