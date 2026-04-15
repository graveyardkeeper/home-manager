{ pkgs, ... }:

{
  xdg.configFile."kitty".source = pkgs.lib.cleanSourceWith {
    src = ../files/kitty;
    filter = path: type:
      let
        baseName = builtins.baseNameOf path;
      in
        !(builtins.elem baseName [ ".direnv" "__pycache__" ".DS_Store" ])
        && !pkgs.lib.hasSuffix ".pyc" baseName
        && !pkgs.lib.hasSuffix ".tmp" baseName
        && !pkgs.lib.hasSuffix ".bak" baseName
        && !pkgs.lib.hasSuffix ".swp" baseName;
  };
}
