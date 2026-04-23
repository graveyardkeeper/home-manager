{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
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
    kitty
    markdownlint-cli
    mitmproxy
    mpv
    neovim
    neovim-remote
    nixfmt
    nodejs
    prettierd
    python3
    ripgrep
    sqlfluff
    typos-lsp
    yazi
    zk
    zoxide
    # hm-packages:end
  ];
}
