# ~/.bash_profile: read by bash *login* shells (ssh, console, `bash -l`).
#
# Bash reads the first of ~/.bash_profile, ~/.bash_login, ~/.profile that
# exists — and stops there. Without this file an ssh session would read
# ~/.profile and never source ~/.bashrc, so none of the interactive config
# (prompt, aliases, PATH, nvm, keychain) would load. Pull in both:
#
#   ~/.profile — not stowed; where third-party installers (rustup, uv) append
#                their PATH lines. Sourced first so ~/.bashrc wins on conflict.
#   ~/.bashrc  — the interactive config; it returns early when non-interactive.

[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
