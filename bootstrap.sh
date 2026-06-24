#!/bin/bash
# Bootstrap: install Ansible, then provision this machine with playbook.yml.
# Safe to re-run — Ansible converges the machine to the desired state.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible..."
    sudo apt-get update
    sudo apt-get install -y ansible
fi

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo "Running playbook..."
# --ask-become-pass prompts for the sudo password. If you have passwordless
# sudo, just press Enter at the prompt (or drop the flag).
ansible-playbook playbook.yml --ask-become-pass "$@"

echo "Done. Open a new shell (or 'source ~/.bashrc') to load the environment."
