let
  inherit (import "${builtins.getEnv "HOME"}/nix" { }) pkgs;
in

pkgs.mkShellNoCC {
  shellHook =
    let
      kitty-src = pkgs.runCommand "kitty-src" { } ''
        mkdir $out
        cp -r ${pkgs.kitty.src}/{kitty,kittens} $out
      '';
    in
    ''
      export PYTHONPATH="PYTHONPATH:${kitty-src}"
    '';
  packages = with pkgs; [ ];
}
