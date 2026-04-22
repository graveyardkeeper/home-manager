# Home Manager 使用参考

## 唯一事实来源
- 唯一的配置源码仓库是 `~/.config/home-manager`。
- 不要直接修改 `~/.config/kitty`、`~/.config/yazi`、`~/.config/nvim`、`~/.config/fish/functions` 这些由 Home Manager 生成的目标路径。
- 配置内容本身应修改 `~/.config/home-manager/files/...`。
- Home Manager 声明应修改 `~/.config/home-manager/modules/...`。
- 本文件只是仓库内参考文档，不会通过 Home Manager 部署到 `$HOME`。

## 仓库结构
- `flake.nix`：flake 入口
- `flake.lock`：flake 依赖锁定文件
- `profiles/default.nix.example`：提交到仓库的机器身份模板（`system`、`username`、`homeDirectory`）
- `profiles/default.nix`：本机本地文件，不纳入 git；首次使用时从 `profiles/default.nix.example` 复制并填写
- `home.nix`：模块聚合入口
- `modules/`：Home Manager 模块声明
- `files/`：被托管出去的配置内容和脚本
- `README.md`：仓库内操作参考文档

## 新机器初始化
### 1. 安装 Nix
在 macOS 上，先执行官方安装脚本：

```bash
sh <(curl -L https://nixos.org/nix/install)
```

如果安装过程要求你手动执行额外命令或重启 shell，按提示完成。

安装完成后，先确认：

```bash
nix --version
```

### 2. 开启 flakes
确保 `~/.config/nix/nix.conf` 中包含：

```ini
experimental-features = nix-command flakes
```

如果这个文件还不存在，就新建它。

### 3. 获取配置仓库
把 `~/.config/home-manager` 放到目标机器上。常见方式有两种：
- 直接 `git clone` 你的配置仓库到 `~/.config/home-manager`
- 从旧机器复制整个 `~/.config/home-manager` 目录

### 4. 创建本机 profile
当前默认入口是 `homeConfigurations.default`，它对应的机器身份信息来自本机本地的 `profiles/default.nix`，而不是当前 shell 的环境变量。

首次使用前先复制模板：

```bash
cp ~/.config/home-manager/profiles/default.nix.example ~/.config/home-manager/profiles/default.nix
```

然后按当前机器填写这三个字段：
- `system`
- `username`
- `homeDirectory`

如果缺少这个文件，flake 评估会直接报错并提醒你创建它。

### 5. 首次应用配置
进入一个已经能使用 `nix` 的 shell 后执行：

```bash
nix run path:~/.config/home-manager#homeConfigurations.default.activationPackage
```

如果你此时还没有 fish 环境，也没关系，首次应用可以先在当前 shell 里完成。

### 6. 首次验证
打开一个新的 shell，确认：

```bash
command -v nix
command -v fish
command -v nvim
command -v yazi
```

如果默认 shell 计划使用 fish，再额外验证：

```bash
fish -ic 'command -v nix; nix --version'
```

## 软件如何通过 Nix / Home Manager 安装和托管
这个仓库同时管理两类东西：

### 1. 软件安装
软件包通过 Home Manager 的 `home.packages` 安装。
当前主要定义在：

- `modules/base.nix`

比如：
- `fish`
- `git`
- `neovim`
- `yazi`
- `fd`
- `ripgrep`
- `nodejs`
- `python3`

如果你想新增一个命令行工具，一般做法是：
1. 在 repo 根目录执行：
   - `just install <pkg>`
   - `just check`
   - `just rebuild`
2. 打开新 shell 验证 `command -v <tool>`
3. 如果要删除软件包，则执行：
   - `just uninstall <pkg>`
   - `just check`
   - `just rebuild`

### 2. 配置托管
应用配置文件通过 Home Manager 的 `xdg.configFile` 或 `home.file` 托管。
例如：
- `~/.config/kitty` <- `files/kitty`
- `~/.config/yazi` <- `files/yazi`
- `~/.config/nvim` <- `files/nvim`
- `~/.config/fish/functions` <- `files/fish/functions`
- `~/.local/bin/*` <- `files/bin/*`

也就是说：
- 想安装软件：优先改 `modules/*.nix`
- 想改软件配置：优先改 `files/...`

## 日常修改流程
1. 在 `~/.config/home-manager` 中修改源码。
2. 优先使用 repo 根目录下的 `justfile`：
   - `just build`
   - `just apply`
   - `just rebuild`
   - `just check`
   - `just show`
   - `just verify`
3. 对应的底层命令仍然是：
   - `nix build --no-link path:~/.config/home-manager#homeConfigurations.default.activationPackage`
   - `nix run path:~/.config/home-manager#homeConfigurations.default.activationPackage`
   - 其中 `--no-link` 用来避免在当前目录生成 `result` 软链。
4. 打开新的 shell 或应用会话验证修改结果。

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
