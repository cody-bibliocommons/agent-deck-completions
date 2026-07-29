#!/usr/bin/env zsh
# Feed a partial command line + TAB to an interactive zsh that has only this
# repo's zsh/ dir on $fpath, then print what got completed.
#
#   tests/comptest.zsh 'agent-deck session '
#   tests/comptest.zsh 'agent-deck add -c '
#
# zsh completion needs a real terminal, so this drives one through zsh/zpty.
# Note: PS1 must contain no spaces or redirect characters — zpty parses its own
# argv, and a '>' in PS1 makes it fail with a parse error.

zmodload zsh/zpty

local REPO=${0:A:h:h}
local COMPDIR=$REPO/zsh
local LINE=${1:?usage: comptest.zsh '<partial command line>'}

zpty -b comp env TERM=dumb PS1=PROMPT zsh -f -i

drain() {
  local acc="" chunk
  while zpty -r -t comp chunk 2>/dev/null; do acc+=$chunk; done
  print -rn -- $acc
}

setup() {
  zpty -w comp "fpath=($COMPDIR \$fpath)"
  zpty -w comp "autoload -Uz compinit && compinit -u -D"
  zpty -w comp "zstyle ':completion:*' menu no"
  zpty -w comp "zstyle ':completion:*' verbose yes"
  zpty -w comp "zstyle ':completion:*:descriptions' format '--- %d ---'"
  zpty -w comp "LISTMAX=500"
  sleep 1
  drain >/dev/null
}

setup

zpty -w -n comp "$LINE"
sleep 0.3
drain >/dev/null
zpty -w -n comp $'\t'
sleep 2.5
local out="$(drain)"
zpty -w -n comp $'\C-c'
zpty -d comp 2>/dev/null

print -r -- ${out//$'\r'/}
