{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      nv = "nvim";
      y  = "yazi";
    };
    interactiveShellInit = ''
      if status is-interactive
      end
    '';
  };

  xdg.configFile."fish/functions".source = pkgs.lib.cleanSourceWith {
    src = ../files/fish/functions;
    filter = path: type:
      let
        baseName = builtins.baseNameOf path;
      in
        !(builtins.elem baseName [ ".DS_Store" ])
        && !pkgs.lib.hasSuffix ".tmp" baseName
        && !pkgs.lib.hasSuffix ".bak" baseName
        && !pkgs.lib.hasSuffix ".swp" baseName;
  };
}
