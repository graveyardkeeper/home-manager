set shell := ["bash", "-euo", "pipefail", "-c"]

repo := env_var('HOME') + "/.config/home-manager"
flake := "path:" + repo
target := flake + "#homeConfigurations.default.activationPackage"

_default:
    just --list

# 构建 Home Manager activation package，并避免生成 ./result
build:
    nix build --no-link {{target}}

# 应用当前 Home Manager 配置
apply:
    nix run {{target}}

# 先构建再应用当前 Home Manager 配置
rebuild: build apply

# 求值 activation derivation 路径
check:
    nix eval {{target}}.drvPath

# 查看 flake 输出
show:
    nix flake show {{flake}}

# 在全新的 fish shell 中验证 nix 是否可用
verify:
    fish -ic 'command -v nix; nix --version'

# 列出当前声明式软件包
packages:
    {{repo}}/files/bin/hm-packages list

# 向声明式软件包列表中添加一个软件包
install pkg:
    {{repo}}/files/bin/hm-packages install {{pkg}}

# 从声明式软件包列表中移除一个软件包
uninstall pkg:
    {{repo}}/files/bin/hm-packages uninstall {{pkg}}

# 通过 rsync-tool 从远端拉取文件到本地选中的目录
sync-pull host remote_path port='':
    rsync-tool --action pull --host {{host}} {{ if port != '' { '--port ' + port } else { '' } }} -- {{remote_path}}

# 通过 rsync-tool 将本地选中的文件推送到远端目录
sync-push host remote_path port='':
    rsync-tool --action push --host {{host}} {{ if port != '' { '--port ' + port } else { '' } }} -- {{remote_path}}

# 通过 rsync-tool 监听本地目录并同步变更到远端目录
sync-watch host remote_path port='':
    rsync-tool --action sync-dir-to-remote --host {{host}} {{ if port != '' { '--port ' + port } else { '' } }} -- {{remote_path}}
