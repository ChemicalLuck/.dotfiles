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
# anyway. Every step is wrapped in a timeout, so the script always returns.

BASE=https://downloads.claude.ai/claude-code-releases
LOG="${TMPDIR:-/tmp}/claude-stage2.log"
: > "$LOG"

say() { printf '\n=== %s ===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "0. Platform"
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
if have apk; then
    echo "musl:     $(apk info -d musl 2>/dev/null | head -1)"
fi

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
VERSION=$(timeout 30 curl -fsSL "$BASE/latest") || { echo "cannot reach $BASE"; exit 1; }
BIN="$HOME/.claude/downloads/claude-$VERSION-$PLATFORM"
mkdir -p "$HOME/.claude/downloads"
if [ -x "$BIN" ]; then
    echo "already present: $BIN"
else
    echo "downloading $VERSION..."
    if ! timeout 600 curl -fsSL "$BASE/$VERSION/$PLATFORM/claude" -o "$BIN"; then
        echo "FAILED — download did not finish in 600s"
        rm -f "$BIN"; exit 1
    fi
    chmod +x "$BIN"
fi
echo "size: $(wc -c < "$BIN") bytes"

say "3. Dynamic linking"
# On musl `ldd` is the loader itself; "Error loading shared library" here is the
# whole answer and means a missing runtime package from step 1.
timeout 30 ldd "$BIN" 2>&1 | head -20

say "4. Does the binary execute at all? (claude --version)"
# This is the key discriminator. It starts the runtime and exits immediately,
# touching no install machinery.
# Redirect rather than pipe: through a pipe $? is tee's status, not timeout's,
# and timeout's 124 is the whole point of this step.
timeout 60 "$BIN" --version > "$LOG.version" 2>&1
rc=$?
cat "$LOG.version"
if [ "$rc" -eq 0 ]; then
    echo "-> the binary runs. The stall is in the install subcommand, not the runtime."
else
    if [ "$rc" -eq 124 ]; then
        echo "-> TIMED OUT. The binary itself hangs on startup; \`claude install\` never"
        echo "   had a chance. This is a musl runtime problem, not an installer problem."
    else
        echo "-> exited $rc without hanging. Read the error above."
    fi
fi

say "5. The install step itself (5 minute cap)"
echo "Running: $BIN install $VERSION"
echo "install.sh runs exactly this as its last step, with no timeout."
START=$(date +%s)
timeout 300 "$BIN" install "$VERSION" > "$LOG" 2>&1
rc=$?
cat "$LOG"
ELAPSED=$(( $(date +%s) - START ))
echo "(exit $rc after ${ELAPSED}s)"
if [ "$rc" -eq 124 ]; then
    echo "-> TIMED OUT. This is your hang, confirmed."
    if have strace; then
        say "5b. Where it is blocked (strace, 20s sample)"
        # Whatever it is waiting on shows up as the syscall it never returns
        # from — a read on a fd, a futex, a connect, a poll.
        timeout 20 strace -f -tt -e trace=network,desc,futex -o "$LOG.strace" \
            "$BIN" install "$VERSION" >/dev/null 2>&1
        echo "last 40 syscalls before the sample ended:"
        tail -40 "$LOG.strace" 2>/dev/null
        echo "(full trace: $LOG.strace)"
    else
        echo "Install strace and re-run this script for the blocking syscall:"
        echo "    sudo apk add strace"
    fi
fi

say "Done"
echo "Output log: $LOG"
echo
echo "Step 4 timed out -> the musl binary hangs on startup; report it upstream"
echo "                    with your Alpine and musl versions from step 0."
echo "Step 4 ok, 5 hung -> the install subcommand is the hang."
echo "Both ok           -> the install works by hand; the difference is Ansible's"
echo "                    environment. Compare with: env -i sh -c '...'"
