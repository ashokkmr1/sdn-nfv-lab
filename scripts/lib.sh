# Demo helpers, sourced by demo1.sh / demo2.sh.
# run "<cmd>"  shows the command like a prompt, waits for Enter, then runs it.
# say "<txt>"  prints a yellow section banner (what to tell the audience).
BOLD=$'\e[1m'; CYAN=$'\e[36m'; YEL=$'\e[33m'; GRN=$'\e[32m'; RED=$'\e[31m'; DIM=$'\e[2m'; RST=$'\e[0m'
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OF="sudo ovs-ofctl -O OpenFlow13"

say()   { echo; echo "${YEL}${BOLD}━━ $* ${RST}"; auto_wait 2; }
note()  { echo "${DIM}   $*${RST}"; auto_wait 1.5; }
run()   {
  if [ -n "${DEMO_AUTO:-}" ]; then   # unattended (backup video): type the command, pause, run, let it sink in
    printf '%s%s$ ' "$GRN" "$BOLD"; local i c="$*"
    for ((i = 0; i < ${#c}; i++)); do printf '%s' "${c:i:1}"; sleep 0.025; done
    printf '%s' "$RST"; sleep 1; echo; eval "$*"; echo; sleep "$DEMO_AUTO"; return
  fi
  printf '%s%s$ %s%s' "$GRN" "$BOLD" "$*" "$RST"; read -r _; eval "$*"; echo
}
pause() { [ -n "${DEMO_AUTO:-}" ] && { sleep "$DEMO_AUTO"; return; }; printf '%s[Enter]%s' "$DIM" "$RST"; read -r _; }
auto_wait() { [ -n "${DEMO_AUTO:-}" ] && sleep "$1"; return 0; }   # DEMO_AUTO=<seconds to read each output>
ok()    { echo "  ${GRN}✔${RST} $*"; }
bad()   { echo "  ${RED}✘${RST} $*"; }

# run a range of steps:  ./demo1.sh 3 (step 3 to the end)   ./demo1.sh 2 3 (steps 2 and 3 only)
STEP_FROM="${1:-0}"
STEP_TO="${2:-99}"
step() { [ "$1" -ge "$STEP_FROM" ] && [ "$1" -le "$STEP_TO" ]; }
