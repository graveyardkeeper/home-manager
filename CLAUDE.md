# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Source of truth
- This repository is the only source of truth for the managed config.
- Do not edit generated live targets under `~/.config/...` when they are managed by Home Manager.
- Edit `modules/*.nix` for Home Manager declarations.
- Edit `files/...` for the managed config payloads and scripts.
- The repo-local operator reference is `README.md` in the repo root.

## Common commands
- Preferred shorthand from the repo root:
  - `just build`
  - `just apply`
  - `just rebuild`
  - `just check`
  - `just show`
  - `just verify`
  - `just packages`
  - `just install <pkg>`
  - `just uninstall <pkg>`
- Underlying Nix commands used by the justfile:
  - `nix build --no-link path:~/.config/home-manager#homeConfigurations.default.activationPackage`
  - `nix run path:~/.config/home-manager#homeConfigurations.default.activationPackage`
  - `nix eval path:~/.config/home-manager#homeConfigurations.default.activationPackage.drvPath`
  - `nix flake show path:~/.config/home-manager`
  - `fish -ic 'command -v nix; nix --version'`
- Check whether a live config path is Home Manager-managed:
  - `ls -l ~/.config/<name>`

## Architecture
- `flake.nix` is the single entrypoint. It exports `homeConfigurations.default` and imports machine identity from the local `profiles/default.nix` rather than reading `USER`/`HOME` from the shell.
- `profiles/default.nix.example` is the repo-tracked template for machine identity. Each machine must create its own local `profiles/default.nix` with `system`, `username`, and `homeDirectory` before evaluation.
- `home.nix` is the root Home Manager module. It receives `username` and `homeDirectory` via `extraSpecialArgs`, sets `home.username` / `home.homeDirectory`, and aggregates the feature modules under `modules/`.
- `modules/base.nix` owns shared packages, PATH, and session variables. Reuse `config.home.homeDirectory` when building user-relative paths.
- The `home.packages` block in `modules/base.nix` now contains a marker-delimited managed section for simple package identifiers. `just install` / `just uninstall` edit only that managed section through `hm-packages`.
- `modules/kitty.nix`, `modules/yazi.nix`, and `modules/neovim.nix` manage whole config directories from `files/`.
- `modules/fish.nix` is intentionally different: keep `programs.fish` for the writable fish runtime model, and only manage `fish/functions` from `files/fish/functions`. Do not try to convert all of `~/.config/fish` into a read-only directory symlink.
- `modules/scripts.nix` manages helper binaries under `~/.local/bin` and the Claude skill installed into `~/.claude/skills/home-manager-safe-edit/SKILL.md`.

## Managed path mapping
- `~/.config/kitty` <- `files/kitty`
- `~/.config/yazi` <- `files/yazi`
- `~/.config/nvim` <- `files/nvim`
- `~/.config/fish/functions` <- `files/fish/functions`
- `~/.local/bin/*` <- `files/bin/*`
- `~/.claude/skills/*` <- `files/claude/skills/*` when declared in Home Manager

## Important repo-specific behavior
- The mapping list above is current state, not a permanent exhaustive list. If asked to modify a live path, first determine whether Home Manager manages it, then trace back to the correct file under `modules/` or `files/`.
- `README.md` is a repo-local reference document only. It is not deployed into `$HOME`.
- Yazi shell bindings intentionally use `$SHELL`; fish startup exports `SHELL` to the current fish path in `modules/fish.nix`, so shell-open behavior depends on launching Yazi from a fresh fish environment.
- `nix build` examples in this repo should use `--no-link` so worktrees do not accumulate `result` symlinks.
- The repo root `justfile` is the preferred shorthand entrypoint for routine operator commands; keep recipes thin and let scripts under `files/bin` handle interactive or stateful workflows.
- Package automation only supports simple package identifiers inside the managed `home.packages` block. If a package needs a more complex Nix expression, edit `modules/base.nix` manually outside that managed section.
- When testing shell-related changes, prefer a fresh fish session and then launch the affected app from there.
