# Home Manager 使用参考

## 唯一事实来源
- 唯一的配置源码仓库是 `~/.config/home-manager`。
- 不要直接修改 `~/.config/kitty`、`~/.config/yazi`、`~/.config/nvim`、`~/.config/fish/functions` 这些由 Home Manager 生成的目标路径。
- 配置内容本身应修改 `~/.config/home-manager/files/...`。
- Home Manager 声明应修改 `~/.config/home-manager/modules/...`。
- 本文件只是仓库内参考文档，不会通过 Home Manager 部署到 `$HOME`。

## 仓库结构
- `flake.nix`：flake 入口
- `home.nix`：模块聚合入口
- `modules/`：Home Manager 模块声明
- `files/`：被托管出去的配置内容和脚本
- `HOME_MANAGER_REFERENCE.md`：仓库内操作参考文档

## 新机器初始化
1. 安装 Nix。
2. 确保 `~/.config/nix/nix.conf` 已开启 flakes。
3. 克隆或复制 `~/.config/home-manager` 到目标机器。
4. 执行：
   - `source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
   - `nix run ~/.config/home-manager#homeConfigurations.bytedance.activationPackage`
5. 打开一个新的 shell，确认：
   - `command -v nix`
   - `command -v fish`
   - `command -v nvim`
   - `command -v yazi`

## 日常修改流程
1. 在 `~/.config/home-manager` 中修改源码。
2. 构建或应用：
   - `source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
   - `nix build ~/.config/home-manager#homeConfigurations.bytedance.activationPackage`
   - `nix run ~/.config/home-manager#homeConfigurations.bytedance.activationPackage`
3. 打开新的 shell 或应用会话验证修改结果。

## 当前已托管的路径映射
- `~/.config/kitty` <- `files/kitty`
- `~/.config/yazi` <- `files/yazi`
- `~/.config/nvim` <- `files/nvim`
- `~/.config/fish/functions` <- `files/fish/functions`
- `~/.local/bin/*` <- `files/bin/*`
- `~/.claude/skills/*` <- `files/claude/skills/*`（前提是已在 Home Manager 中声明）

## 关于路径映射的说明
- 上面的映射只是当前状态，不是永久固定清单。
- 未来这个仓库还会继续扩展，可能新增新的托管目录、脚本路径或 Claude 配置路径。
- 所以当你或 AI 需要修改某个 live 路径时，不要只死记当前映射表，而是应先判断该路径是否已被 Home Manager 接管，再决定应该改 `modules/...` 还是 `files/...`。

## 排障与恢复
- 如果某个托管路径看起来不对，先检查 repo 源文件，不要直接改 live target。
- 修改后重新执行 activation package。
- 可以通过 `ls -l ~/.config/<name>` 判断某个路径是否被托管。
- shell 相关问题优先在全新的 fish 会话里验证。
- 如果某个进程依赖 `$SHELL`，要记住它拿到的是父进程继承下来的环境变量，不一定等于“当前正在运行的 shell 进程”。

## 验证清单
- `command -v nix`
- `nix --version`
- `fish -ic 'command -v nix'`
- 打开 Yazi 并测试 shell 相关按键
- 在 Neovim 中执行 `:set shell?`
- 确认 Fish prompt 和自定义函数正常
