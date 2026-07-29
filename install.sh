#!/usr/bin/env bash
# Install (symlink) the agent-deck shell completions.
#
#   ./install.sh              # install for whichever shells are present
#   ./install.sh --bash       # bash only
#   ./install.sh --zsh        # zsh only
#   ./install.sh --uninstall  # remove the symlinks
#   ./install.sh --system     # also link zsh into /usr/local/share/zsh/site-functions
#
# Symlinks, not copies: `git pull` in this repo updates the installed
# completions with no reinstall step.
set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

BASH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
ZSH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
SYSTEM_ZSH_DIR=/usr/local/share/zsh/site-functions

do_bash=0 do_zsh=0 do_system=0 uninstall=0 picked_shell=0
for arg in "$@"; do
  case $arg in
    --bash)      do_bash=1; picked_shell=1 ;;
    --zsh)       do_zsh=1;  picked_shell=1 ;;
    --system)    do_system=1 ;;   # modifier: does not narrow the shell selection
    --uninstall) uninstall=1; do_bash=1; do_zsh=1; do_system=1; picked_shell=1 ;;
    -h|--help)   sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
if (( ! picked_shell )); then
  command -v bash >/dev/null 2>&1 && do_bash=1
  command -v zsh  >/dev/null 2>&1 && do_zsh=1
fi

if (( uninstall )); then
  rm -fv "$BASH_DIR/agent-deck" "$ZSH_DIR/_agent-deck"
  if [[ -w ${SYSTEM_ZSH_DIR%/*} ]]; then
    rm -fv "$SYSTEM_ZSH_DIR/_agent-deck"
  fi
  echo "Removed. Start a new shell (zsh: rm -f ~/.zcompdump*) to drop the stale cache."
  exit 0
fi

if (( do_bash )); then
  mkdir -p "$BASH_DIR"
  ln -sfn "$REPO/bash/agent-deck.bash" "$BASH_DIR/agent-deck"
  echo "bash -> $BASH_DIR/agent-deck"
fi

if (( do_zsh )); then
  mkdir -p "$ZSH_DIR"
  ln -sfn "$REPO/zsh/_agent-deck" "$ZSH_DIR/_agent-deck"
  echo "zsh  -> $ZSH_DIR/_agent-deck"
  if (( do_system )) && [[ -d $SYSTEM_ZSH_DIR || -w /usr/local/share ]]; then
    mkdir -p "$SYSTEM_ZSH_DIR"
    ln -sfn "$ZSH_DIR/_agent-deck" "$SYSTEM_ZSH_DIR/_agent-deck"
    echo "zsh  -> $SYSTEM_ZSH_DIR/_agent-deck (already on the default \$fpath)"
  elif (( do_zsh )); then
    echo "note: add this to ~/.zshrc *before* compinit / oh-my-zsh if $ZSH_DIR is not on \$fpath:"
    echo "      fpath=($ZSH_DIR \$fpath)"
  fi
fi

echo
echo "Open a new shell to pick it up (zsh may need: rm -f ~/.zcompdump*)."
