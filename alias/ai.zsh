# -----------------------------
# AI
# -----------------------------
alias cc='claude'
alias cc-agents='claude agents'
alias cx='codex'

# cc-bg: launch a Claude session in the background.
# Flags:
#   -n, --name   display name shown in Agent View and /resume picker
#   -a, --agent  built-in or custom agent (e.g. Explore, general-purpose)
# Usage: cc-bg [-n <name>] [-a <agent>] <prompt...>
cc-bg() {
  local name="" agent=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        printf "Usage: cc-bg [-n <name>] [-a <agent>] <prompt...>\n\n"
        printf "Launch a Claude Code session in the background (Agent View).\n\n"
        printf "Options:\n"
        printf "  -n, --name <name>    Display name shown in Agent View and /resume picker\n"
        printf "  -a, --agent <agent>  Agent to use (run 'claude agents' to list available)\n"
        printf "  -h, --help           Show this help message\n\n"
        printf "Examples:\n"
        printf "  cc-bg \"investigate the flaky SettingsChangeDetector test\"\n"
        printf "  cc-bg -n \"PR Review\" \"address review comments on PR 1234\"\n"
        printf "  cc-bg -a Explore \"find all usages of deprecated APIs\"\n"
        printf "  cc-bg -n \"Audit\" -a general-purpose \"review auth module\"\n"
        return 0
        ;;
      -n|--name)  name="$2";  shift 2 ;;
      -a|--agent) agent="$2"; shift 2 ;;
      --) shift; break ;;
      -*) printf "cc-bg: unknown flag '%s'\n" "$1" >&2; return 1 ;;
      *)  break ;;
    esac
  done

  if [[ $# -eq 0 ]]; then
    printf "Usage: cc-bg [-n <name>] [-a <agent>] <prompt...>\n" >&2
    return 1
  fi

  local -a cmd=(claude --bg)
  [[ -n "$name"  ]] && cmd+=(-n "$name")
  [[ -n "$agent" ]] && cmd+=(--agent "$agent")
  cmd+=("$*")
  "${cmd[@]}"
}

_cc_bg_agents() {
  local -a agents
  agents=(${(f)"$(claude agents 2>/dev/null | awk '/^  [a-zA-Z]/{printf "%s:%s\n", $1, $3}')"})
  _describe 'agent' agents
}

_cc_bg() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help message]' \
    '(-n --name)'{-n,--name}'[display name for the session]:name:' \
    '(-a --agent)'{-a,--agent}'[agent to use]:agent:_cc_bg_agents' \
    '*:prompt:'
}

if (( ${+_comps} )); then
  _comps[cc-bg]=_cc_bg
fi
