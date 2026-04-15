---
name: home-manager-safe-edit
description: Safely modify this Home Manager repo by editing repo source files instead of generated symlink targets under ~/.config.
---

# home-manager-safe-edit

## Purpose
Use this skill when changing terminal, editor, Yazi, Fish, Kitty, helper script, or Claude-skill configuration that is managed from `~/.config/home-manager`.

## Source of truth
- Source of truth repo: `~/.config/home-manager`
- Do not directly edit generated targets under `~/.config/...` when those paths are managed by Home Manager.
- Prefer editing:
  - `modules/*.nix` for declarations
  - `files/...` for managed config payloads
- Use `~/.config/home-manager/HOME_MANAGER_REFERENCE.md` as the repo-local workflow reference; do not expect a managed SOP file in `$HOME`.

## Path mapping
Current known mappings include:
- `~/.config/kitty` -> `~/.config/home-manager/files/kitty`
- `~/.config/yazi` -> `~/.config/home-manager/files/yazi`
- `~/.config/nvim` -> `~/.config/home-manager/files/nvim`
- `~/.config/fish/functions` -> `~/.config/home-manager/files/fish/functions`
- `~/.local/bin/*` -> `~/.config/home-manager/files/bin/*`
- `~/.claude/skills/*` -> managed from `~/.config/home-manager/files/claude/skills/*` when declared in Home Manager

## Important mapping note
- The mapping table above describes the current state only.
- This repo will continue to evolve, and new managed directories or files may be added in the future.
- Do not assume the current list is exhaustive forever.
- When asked to modify a live path, first determine whether it is currently managed by Home Manager, then map it back to the correct source file under `modules/...` or `files/...`.

## Rules
1. Before editing, determine whether the live target is Home Manager-managed.
2. If it is managed, edit the repo source file instead of the symlink target.
3. Do not replace managed symlinks with regular files or directories unless intentionally migrating ownership.
4. Keep the current Fish model: `programs.fish` plus managed `fish/functions`.
5. Prefer minimal edits to the correct source file.
6. If the path is not in the current mapping table, investigate instead of guessing.

## Apply workflow
After edits:
1. Run:
   - `source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
   - `nix build ~/.config/home-manager#homeConfigurations.bytedance.activationPackage`
   - `nix run ~/.config/home-manager#homeConfigurations.bytedance.activationPackage`
2. Run app-specific smoke checks for the changed area.

## Validation examples
- Fish changes: open a fresh fish shell and test aliases/functions.
- Yazi changes: launch Yazi and test relevant keybindings.
- Neovim changes: start Neovim and test shell-dependent features.
- Kitty changes: open a new Kitty window and confirm behavior.

## Anti-patterns
- Editing `~/.config/nvim/...` directly when it is a Home Manager symlink.
- Editing `~/.config/yazi/...` directly when it is a Home Manager symlink.
- Copying files into managed target directories instead of updating repo sources.
- Breaking symlink ownership just to make a one-off edit.
