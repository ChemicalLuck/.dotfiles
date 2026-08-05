#!/bin/sh
# Bootstrap: install Ansible, then provision this machine with playbook.yml.
# Safe to re-run — Ansible converges the machine to the desired state.
#
# POSIX sh, not bash: on a fresh Alpine box /bin/sh is busybox ash and bash
# isn't installed yet (the playbook installs it).
set -eu

cd "$(dirname "$(readlink -f "$0")")"

# --- privilege escalation ---------------------------------------------------
# Alpine installs neither sudo nor doas by default, and a container often runs
# as root already. Work out what's available before assuming sudo.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
    BECOME_METHOD=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    BECOME_METHOD="sudo"
elif command -v doas >/dev/null 2>&1; then
    SUDO="doas"
    BECOME_METHOD="doas"
else
    echo "Error: need root, sudo or doas to install packages." >&2
    echo "Install one (Alpine: 'apk add sudo') or re-run as root." >&2
    exit 1
fi

# --- Ansible ----------------------------------------------------------------
install_ansible() {
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update
        $SUDO apt-get install -y ansible
    elif command -v apk >/dev/null 2>&1; then
        # ansible (the full distribution) lives in Alpine's community repo;
        # fall back to ansible-core if community isn't enabled yet.
        $SUDO apk add --no-cache ansible || $SUDO apk add --no-cache ansible-core
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y ansible-core
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y ansible
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm ansible
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper install -y ansible
    else
        echo "Error: no supported package manager found." >&2
        echo "Install Ansible yourself, then re-run this script." >&2
        exit 1
    fi
}

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible..."
    install_ansible
fi

# --- collections ------------------------------------------------------------
# --force, not a plain install, and not --upgrade.
#
# A distro can leave a collection directory present but unusable. Alpine's
# `ansible-pyc` package ships only compiled bytecode — the .py sources live in
# the `ansible` package — so site-packages ends up holding a community.general
# whose plugins/modules/ contains nothing but __pycache__. Ansible's loader
# only looks for .py, so every module in it is invisible and roles die at load
# time with "couldn't resolve module/action".
#
# Against that, a plain install sees the directory, reports "already installed"
# and leaves it broken; --upgrade feeds the version-less collection to the
# dependency resolver, which aborts with "invalid semantic version '*'".
# --force skips both traps and always writes a complete copy to
# ~/.ansible/collections, which takes precedence over site-packages.
echo "Installing required Ansible collections..."
if ansible-galaxy collection install -r requirements.yml --force; then
    :
elif ansible-galaxy collection install -r requirements.yml; then
    :
else
    echo "Warning: could not install collections from Galaxy; continuing with" >&2
    echo "the collections already present. If a role later reports 'couldn't"  >&2
    echo "resolve module/action', that collection is the one to install."      >&2
fi

# --- run --------------------------------------------------------------------
echo "Running playbook..."
# Already root: nothing to escalate to, so skip the password prompt entirely.
# Otherwise --ask-become-pass prompts for your password; with passwordless
# sudo/doas, just press Enter.
if [ -z "$BECOME_METHOD" ]; then
    ansible-playbook playbook.yml "$@"
else
    ansible-playbook playbook.yml \
        --ask-become-pass \
        -e "ansible_become_method=$BECOME_METHOD" \
        "$@"
fi

echo "Done. Open a new shell (or 'source ~/.bashrc') to load the environment."
