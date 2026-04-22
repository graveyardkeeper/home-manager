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
      profilePath = ./profiles/default.nix;
      profile =
        if builtins.pathExists profilePath then
          import profilePath
        else
          throw ''
            Missing local profile: profiles/default.nix

            Copy profiles/default.nix.example to profiles/default.nix and set:
              - system
              - username
              - homeDirectory
          '';
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
