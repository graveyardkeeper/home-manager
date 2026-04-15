{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";
    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
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
