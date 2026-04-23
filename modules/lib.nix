{ lib }:

{
  cleanSource = src: extraIgnoredNames:
    lib.cleanSourceWith {
      inherit src;
      filter = path: type:
        let
          baseName = builtins.baseNameOf path;
        in
          !(builtins.elem baseName ([ ".DS_Store" ".direnv" "__pycache__" ] ++ extraIgnoredNames))
          && !lib.hasSuffix ".pyc" baseName
          && !lib.hasSuffix ".tmp" baseName
          && !lib.hasSuffix ".bak" baseName
          && !lib.hasSuffix ".swp" baseName;
    };
}
