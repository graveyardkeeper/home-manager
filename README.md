# Home Manager 使用参考

## 这是什么

这是开发环境的软件和配置托管仓库，可将这套完善的环境（包含 `fish`、`kitty`、`yazi`、`neovim`、`lazygit` 等应用和大量实用配置、脚本）一键应用到其他机器上。你也可以 Fork 一份，在此基础上定制你自己的环境。

## 首次使用

1. 安装 Nix：

```bash
sh <(curl -L https://nixos.org/nix/install)
```

安装后确认：

```bash
nix --version
```

2. 运行下面这条命令，确保 `~/.config/nix/nix.conf` 包含所需配置（若文件或目录不存在会自动创建）：

```bash
mkdir -p ~/.config/nix && grep -qxF 'experimental-features = nix-command flakes' ~/.config/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

3. 获取仓库到 `~/.config/home-manager`。

4. 创建本机 profile：

```bash
cp ~/.config/home-manager/profiles/default.nix.example ~/.config/home-manager/profiles/default.nix
```

并根据你的机器情况填写：

- `system`
- `username`
- `homeDirectory`

5. 首次应用：

```bash
nix run "path:$HOME/.config/home-manager#homeConfigurations.default.activationPackage"
```

后续更新配置时，只需在仓库根目录运行：

```bash
just apply
```

## 日常操作

- 修改配置后，在仓库根目录运行 `just apply`
- 安装软件：`just install <pkg>`
- 卸载软件：`just uninstall <pkg>`
- 其他命令见 `justfile`

## 常用目录

- `flake.nix`：入口
- `profiles/default.nix.example`：profile 模板
- `profiles/default.nix`：本机本地配置
- `home.nix`：模块聚合入口
- `modules/`：Home Manager 模块
- `files/`：托管的配置和脚本

## 修改约定

- 安装或删除软件：改 `modules/*.nix`，或用 `just install/uninstall`
- 修改应用配置：改 `files/...`
- 不确定某个路径是否被托管时先检查：

```bash
ls -l ~/.config/<name>
```

### 建议：用 AI 辅助修改配置

这个仓库很适合配合 AI 一起维护。你可以直接用自然语言描述想要的改动，让 AI 帮你定位应该修改的托管文件并完成变更。

例如：

- “将 yazi 的后退和前进改成左右箭头按键，而不是 `H` 和 `L`”
- “给 kitty 增加一个更大的默认字体”
- “把 fish 的某个别名改掉”

这样做通常比手动在各个目录里找配置更快，尤其适合你不确定应该改 `modules/` 还是 `files/` 的时候。

## 当前托管路径

- `~/.config/kitty` <- `files/kitty`
- `~/.config/yazi` <- `files/yazi`
- `~/.config/nvim` <- `files/nvim`
- `~/.config/fish/functions` <- `files/fish/functions`
- `~/.local/bin/*` <- `files/bin/*`
- `~/.claude/skills/*` <- `files/claude/skills/*`

## 非Nix托管应用

有些应用不在`nixpkgs`中，无法通过Nix安装，在此记录，如有需求可手动安装：

```bash
uv tool install thrift-fmt
```
