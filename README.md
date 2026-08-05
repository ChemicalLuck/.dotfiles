# .dotfiles
ChemicalLuck's Linux / WSL2 dotfiles. Provisioning is handled by **Ansible**;
symlinking is handled by **GNU Stow** (invoked from Ansible).

## Bootstrap
```sh
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```
`bootstrap.sh` detects your package manager, installs Ansible if needed, pulls
the required collections, then runs `playbook.yml` against localhost. It's
POSIX `sh`, so it runs on a stock Alpine box before `bash` exists.

Requirements: root, `sudo` or `doas`, plus internet access. `bootstrap.sh`
picks whichever it finds and skips the password prompt entirely when you're
already root. The playbook is **convergent** — re-running `./bootstrap.sh`
brings the machine up to date and is safe to run repeatedly.

## Supported distros
Tested on **Debian/Ubuntu** and **Alpine**. Arch and Fedora/RHEL have
best-effort package lists but haven't been run end to end.

Nothing in `roles/` names a package manager directly — the roles ask for
`ansible_os_family` and look the answer up. Two mechanisms carry that:

- **`*_by_family` maps** in `group_vars/all.yml`, keyed by `ansible_os_family`
  (`Debian`, `Alpine`, `Archlinux`, `RedHat`, ...), for package *names*.
  Installs go through `ansible.builtin.package`, which dispatches to apt, apk,
  pacman or dnf on its own.
- **Per-family task files** (`roles/<role>/tasks/<Family>.yml`) for anything
  that isn't just a name — third-party repos, GPG keyrings, install methods —
  with `default.yml` as the fallback.

To add a distro: add its family to the maps in `group_vars/all.yml` and, if it
needs extra repositories, drop in a `roles/packages/tasks/<Family>.yml`. The
playbook fails fast, before installing anything, on a family it has no map for.

### Where distros actually differ
| Thing | Debian/Ubuntu | Alpine |
| --- | --- | --- |
| Python 3.12 | deadsnakes PPA | system `python3` |
| GitHub CLI | `cli.github.com` apt repo | `github-cli` (community) |
| Terraform | HashiCorp apt repo | not packaged — see the note in `group_vars/all.yml` |
| Docker | Docker's official apt repo | `docker` (community) |
| Node | nvm | `nodejs` — nvm's prebuilt binaries are glibc-only |
| Neovim | upstream AppImage | `neovim` — the AppImage is glibc-only |
| AWS CLI v2 | AWS's bundled installer | `aws-cli` — the installer is glibc-only |
| Services | systemd | OpenRC (both via `ansible.builtin.service`) |

Alpine also needs `coreutils`/`findutils` (busybox's `find`/`readlink` are too
thin for the dotfiles role) and `bash` (its shell tasks aren't ash-compatible);
both are in the Alpine package list. The `packages` role enables Alpine's
`community` repository if it isn't already, since most of the tooling lives
there.

The install methods are overridable if a default doesn't suit you — e.g.
`node_install_method: nvm`, `neovim_install_method: package`,
`awscli_install_method: bundle`.

## Layout
```
bootstrap.sh        # detects the package manager, installs Ansible, runs the playbook
playbook.yml        # roles run in order against localhost
ansible.cfg         # inventory / roles_path / defaults
inventory.ini       # localhost, connection: local
requirements.yml    # Ansible collections (community.general)
group_vars/all.yml  # ALL package lists + settings (single source of truth)
roles/
  packages/         # system packages; Debian.yml adds PPA + GitHub CLI/HashiCorp
                    # repos, Alpine.yml enables the community repo
  docker/           # Docker Engine: Debian.yml adds Docker's repo, else distro pkgs
  awscli/           # AWS CLI v2: bundle.yml (installer) or package.yml (distro)
  rust/             # rustup, nightly toolchain, cargo crates
  node/             # nvm.yml or package.yml, then global npm packages
  uv/               # uv + uv tool installs
  neovim/           # appimage.yml or package.yml + uv-managed provider venv
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
### Alpine
- **`ERROR: unable to select packages`** — the `community` repository isn't
  enabled and the playbook couldn't turn it on. Check `/etc/apk/repositories`
  has a `.../community` line, or run `setup-apkrepos -c -1`.
- **`sudo: not found`** — Alpine ships neither `sudo` nor `doas`. Run
  `bootstrap.sh` as root, or `apk add sudo` first.

### Clipboard
On WSL2, install [win32yank](https://github.com/equalsraf/win32yank) in order for the clipboard to work between WSL2 and Windows.
Install using [choco](https://chocolatey.org/install#individual) via powershell by running `choco install win32yank`
