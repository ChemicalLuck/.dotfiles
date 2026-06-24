# .dotfiles
ChemicalLuck's Linux / WSL2 dotfiles. Provisioning is handled by **Ansible**;
symlinking is handled by **GNU Stow** (invoked from Ansible).

## Bootstrap
```sh
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```
`bootstrap.sh` installs Ansible if needed, pulls the required collections, then
runs `playbook.yml` against localhost. It prompts for your sudo password
(`--ask-become-pass`); if you have passwordless sudo, just press Enter.

Requirements: a Debian/Ubuntu-based system with `sudo` and internet access. The
playbook is **convergent** — re-running `./bootstrap.sh` brings the machine up
to date and is safe to run repeatedly.

## Layout
```
bootstrap.sh        # installs Ansible, runs the playbook
playbook.yml        # roles run in order against localhost
ansible.cfg         # inventory / roles_path / defaults
inventory.ini       # localhost, connection: local
requirements.yml    # Ansible collections (community.general)
group_vars/all.yml  # ALL package lists + settings (single source of truth)
roles/
  packages/         # apt packages, deadsnakes PPA, GitHub CLI repo
  rust/             # rustup, nightly toolchain, cargo crates
  node/             # nvm, node, global npm packages
  uv/               # uv + uv tool installs
  neovim/           # AppImage install into /opt
  dotfiles/         # stow each package, write per-machine stubs
stow/               # the stow packages (this is the stow dir)
  bash/  git/  tmux/  rust/  nvim/  tealdeer/  scripts/  ubuntu/
```
To change what gets installed, edit `group_vars/all.yml` — not the roles.

## Per-machine overrides
Identity and machine-specific values are kept out of the repo (gitignored) and
layered in via local files:

- `~/.gitconfig.local` — your git `name`/`email`, included by `git/.gitconfig`.
  The dotfiles role writes a stub on first run; edit it with your details.
- `~/.bashrc.local` — per-machine shell settings, sourced at the end of
  `bash/.bashrc` if present.

## Stow note
The `dotfiles` role stows **every directory under `stow/`** — there's no list to
maintain; add a package by adding a directory. Before stowing it backs up any
conflicting real file to `<file>.bak` and clears stale symlinks left by a
previous layout, so it's safe to re-run.

It stows with `--no-folding`, which links individual files rather than folding a
whole directory (e.g. `~/.config`) into a single symlink — avoiding the failure
mode where every app writing to `~/.config` ends up writing into the repo. So
don't run a bare `stow nvim`; let the playbook do it, or run it manually from
the repo root: `stow --dir=stow --no-folding --restow --target="$HOME" <pkg>`.

## Troubleshooting
### Clipboard
On WSL2, install [win32yank](https://github.com/equalsraf/win32yank) in order for the clipboard to work between WSL2 and Windows.
Install using [choco](https://chocolatey.org/install#individual) via powershell by running `choco install win32yank`
