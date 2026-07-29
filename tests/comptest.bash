#!/usr/bin/env bash
# Drive the bash completion function directly and print the candidates.
#
#   tests/comptest.bash 'agent-deck session st'
#   tests/comptest.bash 'agent-deck mcp attach '      # trailing space = new word
#
# bash completions are plain functions over COMP_WORDS/COMP_CWORD, so no pty is
# needed — set the same variables readline would and inspect COMPREPLY.
set -uo pipefail

for bc in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
  # Loading bash-completion also loads /etc/bash_completion.d/*, some of which
  # chatter on stdout; keep the harness output clean.
  [[ -r $bc ]] && { # shellcheck disable=SC1090
    source "$bc" >/dev/null 2>&1; break; }
done

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../bash/agent-deck.bash
source "$here/../bash/agent-deck.bash"

line=${1:?usage: comptest.bash '<partial command line>'}

# Reproduce how readline splits the line: a backslash-escaped or quoted word is
# a single COMP_WORDS element, and bash keeps it in its escaped form (verified
# against a real interactive bash).
_words=()
if [[ $line == *\\* || $line == *\"* || $line == *\'* ]]; then
  eval "set -- $line"
  for _w in "$@"; do _words+=( "$(printf '%q' "$_w")" ); done
else
  read -r -a _words <<< "$line"
fi
[[ $line == *' ' ]] && _words+=('')

COMP_WORDS=("${_words[@]}")
COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
COMP_LINE=$line
COMP_POINT=${#line}

COMPREPLY=()
_agent_deck
printf '%s\n' "${COMPREPLY[@]}"
