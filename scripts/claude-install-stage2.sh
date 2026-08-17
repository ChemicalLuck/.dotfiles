#!/bin/sh
# Second-stage diagnostic, for when claude-install-diagnose.sh comes back clean
# and the install still stalls. That result exonerates the network, the disk
# and the RAM, which leaves the last line of install.sh:
#
#     "$binary_path" install ${TARGET:+"$TARGET"}
#
# This script reproduces the install by hand, one step at a time, so you can
# see which one goes quiet:
#
#     sh scripts/claude-install-stage2.sh
#
# Steps 1-4 are read-only. Step 5 runs the real `claude install` and, if it
# succeeds, leaves Claude Code installed — which is the outcome you wanted
# anyway. Every step is hard-bounded, so the script always returns.

BASE=https://downloads.claude.ai/claude-code-releases
LOG="${TMPDIR:-/tmp}/claude-stage2.log"
: > "$LOG"

say() { printf '\n=== %s ===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Both GNU coreutils and busybox `timeout` send SIGTERM and then *wait* for the
# child to exit. A child that ignores SIGTERM makes `timeout` itself hang, which
# is how a "bounded" step ends up running forever. -k follows up with SIGKILL,
# which cannot be caught or ignored — the one exception being a process stuck in
# uninterruptible sleep, which step 6 checks for.
run_bounded() {
    _secs=$1
    shift
    timeout -k 10 "$_secs" "$@"
}

# 124: SIGTERM did the job. 137: SIGTERM was ignored and SIGKILL was needed —
# worth calling out separately, since it says the process was not responding to
# signals rather than merely being slow.
timed_out() { [ "$1" -eq 124 ] || [ "$1" -eq 137 ]; }
report_rc() {
    if [ "$1" -eq 137 ]; then
        echo "   (ignored SIGTERM; only SIGKILL stopped it)"
    elif [ "$1" -eq 124 ]; then
        echo "   (stopped by SIGTERM at the deadline)"
    fi
}

# Anything still alive under that name, with the kernel's view of what it is
# doing. state=D is uninterruptible sleep — blocked in the kernel on I/O, which
# even SIGKILL will not interrupt, and on a VM usually means the virtual disk or
# a network filesystem, not Claude Code.
claude_procs() {
    _found=0
    for d in /proc/[0-9]*; do
        [ -r "$d/comm" ] || continue
        _c=$(cat "$d/comm" 2>/dev/null) || continue
        case "$_c" in
            *claude*)
                _pid=${d#/proc/}
                _state=$(awk '{print $3}' "$d/stat" 2>/dev/null)
                _wchan=$(cat "$d/wchan" 2>/dev/null)
                echo "  pid $_pid  state=${_state:-?}  wchan=${_wchan:-?}  comm=$_c"
                _found=1
                ;;
        esac
    done
    [ "$_found" -eq 0 ] && echo "  none"
}

say "0. Platform"
if ! have timeout; then
    echo "WARNING: no \`timeout\` command — steps below are unbounded."
    echo "Install it first:  sudo apk add coreutils"
fi
if [ -f /lib/libc.musl-x86_64.so.1 ]; then
    PLATFORM=linux-x64-musl
elif [ -f /lib/libc.musl-aarch64.so.1 ]; then
    PLATFORM=linux-arm64-musl
else
    case "$(uname -m)" in
        x86_64|amd64) PLATFORM=linux-x64 ;;
        aarch64|arm64) PLATFORM=linux-arm64 ;;
        *) echo "unsupported: $(uname -m)"; exit 1 ;;
    esac
fi
echo "platform: $PLATFORM"
have apk && echo "musl:     $(apk info -d musl 2>/dev/null | head -1)"

say "1. Runtime dependencies the role is supposed to have installed"
# Missing libstdc++ makes the binary fail loudly rather than hang, but rule it
# out anyway — it is one apk command.
if have apk; then
    for p in libgcc libstdc++ ripgrep; do
        if apk info -e "$p" >/dev/null 2>&1; then
            echo "$p: installed"
        else
            echo "$p: MISSING  <-- the claude role should have installed this"
        fi
    done
else
    echo "not an apk system, skipping"
fi

say "2. Fetch the binary"
VERSION=$(run_bounded 30 curl -fsSL "$BASE/latest") || { echo "cannot reach $BASE"; exit 1; }
BIN="$HOME/.claude/downloads/claude-$VERSION-$PLATFORM"
mkdir -p "$HOME/.claude/downloads"
if [ -x "$BIN" ]; then
    echo "already present: $BIN"
else
    echo "downloading $VERSION..."
    if ! run_bounded 600 curl -fsSL "$BASE/$VERSION/$PLATFORM/claude" -o "$BIN"; then
        echo "FAILED — download did not finish in 600s"
        rm -f "$BIN"; exit 1
    fi
    chmod +x "$BIN"
fi
echo "size: $(wc -c < "$BIN") bytes"

say "3. Dynamic linking"
# On musl `ldd` is the loader itself; "Error loading shared library" here is the
# whole answer and means a missing runtime package from step 1.
run_bounded 30 ldd "$BIN" 2>&1 | head -20

say "4. Does the binary execute at all? (claude --version)"
# The key discriminator: this starts the runtime and exits immediately, touching
# no install machinery. Redirect rather than pipe — through a pipe $? would be
# tee's status, and the timeout code is the whole point of this step.
run_bounded 60 "$BIN" --version > "$LOG.version" 2>&1
rc=$?
cat "$LOG.version"
if [ "$rc" -eq 0 ]; then
    echo "-> the binary runs. The stall is in the install subcommand, not the runtime."
elif timed_out "$rc"; then
    echo "-> TIMED OUT after 60s. The binary itself hangs on startup, so"
    echo "   \`claude install\` never had a chance. This is a musl runtime problem."
    report_rc "$rc"
else
    echo "-> exited $rc without hanging. Read the error above."
fi

say "5. The install step itself (5 minute cap)"
echo "Running: $BIN install $VERSION"
echo "install.sh runs exactly this as its last step, with no bound at all."
START=$(date +%s)
run_bounded 300 "$BIN" install "$VERSION" > "$LOG" 2>&1
rc=$?
cat "$LOG"
ELAPSED=$(( $(date +%s) - START ))
echo "(exit $rc after ${ELAPSED}s)"
if timed_out "$rc"; then
    echo "-> TIMED OUT. This is your hang, confirmed."
    report_rc "$rc"
    if have strace; then
        say "5b. Where it is blocked (strace, 20s sample)"
        # Whatever it waits on shows up as the syscall it never returns from.
        run_bounded 25 strace -f -tt -o "$LOG.strace" \
            "$BIN" install "$VERSION" >/dev/null 2>&1
        echo "last 40 syscalls before the sample ended:"
        tail -40 "$LOG.strace" 2>/dev/null
        echo "(full trace: $LOG.strace)"
    else
        echo "Install strace and re-run for the blocking syscall:"
        echo "    sudo apk add strace"
    fi
fi

say "6. Surviving claude processes"
claude_procs
echo
echo "An interactive session you left running shows up here too (state=S,"
echo "wchan=ep_poll is a healthy idle process); what matters is a leftover from"
echo "the step above. state=D means blocked in the kernel on I/O — SIGKILL will"
echo "not clear it, and on a VM that points at the virtual disk, not at Claude."

say "Done"
echo "Output log: $LOG"
echo
echo "Step 4 timed out -> the musl binary hangs on startup; report it upstream"
echo "                    with the Alpine and musl versions from step 0."
echo "Step 4 ok, 5 hung -> the install subcommand is the hang."
echo "Both ok           -> it installs by hand, so the difference is Ansible's"
echo "                    environment (CI=1, TERM=dumb, closed stdin)."
