{ pkgs, ... }:

{
  xdg.configFile."yazi".source = pkgs.lib.cleanSourceWith {
    src = ../files/yazi;
    filter = path: type:
      let
        baseName = builtins.baseNameOf path;
      in
        !(builtins.elem baseName [ "bookmark" "vfs.toml" ".DS_Store" ])
        && !pkgs.lib.hasSuffix ".tmp" baseName
        && !pkgs.lib.hasSuffix ".bak" baseName
        && !pkgs.lib.hasSuffix ".swp" baseName;
  };
}
