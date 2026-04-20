{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    GOPATH = "${config.home.homeDirectory}/workspace/go";
    GOSUMDB = "sum.golang.google.cn";
    GOPRIVATE = "*.byted.org,*.everphoto.cn,git.smartisan.com";
    GOPROXY = "https://goproxy.byted.org|https://goproxy.cn|direct";
  };

  home.sessionPath = [
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "/usr/local/go/bin"
    "${config.home.homeDirectory}/workspace/go/bin"
    "${config.home.homeDirectory}/workspace/go/bin/darwin_amd64"
  ];

  home.packages = with pkgs; [
    # hm-packages:start
    delta
    fd
    fish
    fzf
    git
    gofumpt
    hadolint
    jq
    just
    markdownlint-cli
    mpv
    neovim
    nodejs
    python3
    ripgrep
    sqlfluff
    yazi
    zk
    zoxide
    # hm-packages:end
  ];
}
