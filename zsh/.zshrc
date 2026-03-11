# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(git zsh-syntax-highlighting zsh-autosuggestions autojump)

# Cache compinit - only regenerate once a day
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Setup locale variables
# For tmux to know that UTF-8 is supported
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Mainly for tmuxinator
export EDITOR='nvim'

alias tx='tmuxinator'

# export PATH="$PATH:/opt/nvim-linux-x86_64/bin"  # Linux-specific path, nvim available via Homebrew on macOS

# Rubygems

export PATH="$PATH:$HOME/.local/share/gem/ruby/3.2.0/bin"

# Go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Hugo Version Manager: override path to the hugo executable.
hugo() {
  hvm_show_status=true
  if hugo_bin=$(hvm status --printExecPathCached); then
    if [ "${hvm_show_status}" = "true" ]; then
      >&2 printf "Hugo version management is enabled in this directory.\\n"
      >&2 printf "Run 'hvm status' for details, or 'hvm disable' to disable.\\n\\n"
    fi
  else
    if hugo_bin=$(hvm status --printExecPath); then
      if ! hvm use --useVersionInDotFile; then
        return 1
      fi
    else
      if ! hugo_bin=$(whence -p hugo); then
        >&2 printf "Command not found.\\n"
        return 1
      fi
    fi
  fi
  "${hugo_bin}" "$@"
}

export PATH=$PATH:$HOME/.cache/hvm/default

# Use eza instead of ls
alias ls='eza'
alias ll='eza -al --group-directories-first' # list everything, directories first
alias lh='eza -dl .*' # list hidden files
alias ld='eza -lD' # list directories only
alias lf='eza -lF --color=always | grep -v /' # list files only
alias lt='eza -al --sort=modified' # list by modification time

# Lazy-load NVM for faster shell startup
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { nvm && node "$@"; }
npm() { nvm && npm "$@"; }
npx() { nvm && npx "$@"; }

# pipx
export PATH="$PATH:$HOME/.local/bin"

# Docker aliases
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dps="docker ps"
alias dpsa="docker ps -a"

# Remove all exited containers
function drmc-fn {
       docker rm $(docker ps --all -q -f status=exited)
}

alias drmc=drmc-fn

# Remove stale git index.lock
alias git-unlock='rm -f .git/index.lock && echo "Removed .git/index.lock"'

# pnpm
export PNPM_HOME="/Users/pottekkat/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"

# For Enchanted
# . "$HOME/Library/Application Support/enchanted/bin/env"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

. "$HOME/.local/bin/env"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/pottekkat/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/pottekkat/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/pottekkat/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/pottekkat/google-cloud-sdk/completion.zsh.inc'; fi

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
