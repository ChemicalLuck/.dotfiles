# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi
export PATH=~/.cargo/bin:$PATH
alias ls='exa -1lF -a --git --icons --group-directories-first --sort=created'
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
