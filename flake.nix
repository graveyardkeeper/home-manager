{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      profile = import ./profiles/default.nix;
    in {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = profile.system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit (profile) username homeDirectory;
        };
        modules = [ ./home.nix ];
      };
    };
}
