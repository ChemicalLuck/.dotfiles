#!/bin/sh
# Pinpoint which stage of the Claude Code install stalls. Run it directly in
# the VM (not through Ansible) so you see output as it happens:
#
#     sh scripts/claude-install-diagnose.sh
#
# Deliberately POSIX sh with no bashisms, so it runs on a stock Alpine before
# the packages role has installed bash. Every network stage is wrapped in a
# timeout, so the script always finishes and tells you where it got stuck
# rather than hanging the way the install does.
#
# Nothing here writes outside $TMPDIR — it does not install anything.

BASE=https://downloads.claude.ai/claude-code-releases
TMP="${TMPDIR:-/tmp}/claude-diag.$$"
mkdir -p "$TMP" || exit 1
trap 'rm -rf "$TMP"' EXIT INT TERM

say() { printf '\n=== %s ===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Every `timeout` below carries -k. `timeout` sends SIGTERM and then waits for
# the child to exit, so a child that ignores SIGTERM hangs `timeout` itself —
# the -k follow-up SIGKILL is what makes a bounded step genuinely bounded.

say "0. Host"
uname -srm
[ -f /etc/os-release ] && . /etc/os-release && echo "$PRETTY_NAME"
if [ -f /lib/libc.musl-x86_64.so.1 ]; then
    PLATFORM=linux-x64-musl
elif [ -f /lib/libc.musl-aarch64.so.1 ]; then
    PLATFORM=linux-arm64-musl
else
    case "$(uname -m)" in
        x86_64|amd64) PLATFORM=linux-x64 ;;
        aarch64|arm64) PLATFORM=linux-arm64 ;;
        *) PLATFORM="unknown-$(uname -m)" ;;
    esac
fi
echo "platform: $PLATFORM"

say "1. Resources"
# The installer needs ~512MB free RAM, and lands two ~305MB copies of the
# binary: one in ~/.claude/downloads, one in ~/.local/share/claude/versions.
echo "--- memory (MB) ---"
free -m 2>/dev/null || awk '/MemTotal|MemAvailable|SwapTotal/ {printf "%-14s %6d MB\n", $1, $2/1024}' /proc/meminfo
echo "--- disk on \$HOME ($HOME) ---"
df -h "$HOME" 2>/dev/null
echo "Need roughly 650MB free on \$HOME and 512MB of free RAM."

say "2. Shell config paths"
# A *directory* at any of these hangs claude install/update/doctor before
# v2.1.214. A 'd' at the start of a line is the problem; "No such file" is fine.
ls -ld "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" \
       "$HOME/.config/fish/config.fish" 2>&1

say "3. Version pointer (a few bytes)"
if ! VERSION=$(timeout -k 5 30 curl -fsSL "$BASE/latest" 2>&1); then
    echo "FAILED — cannot reach $BASE/latest"
    echo "$VERSION"
    exit 1
fi
echo "latest = $VERSION"
case "$VERSION" in
    [0-9]*) ;;
    *) echo "FAILED — got non-version content, likely a proxy or captive portal"; exit 1 ;;
esac

say "4. Manifest (a few KB)"
if ! timeout -k 5 30 curl -fsSL "$BASE/$VERSION/manifest.json" -o "$TMP/manifest.json"; then
    echo "FAILED — reachable pointer but manifest download failed"
    exit 1
fi
echo "ok, $(wc -c < "$TMP/manifest.json") bytes"

say "5. Sustained throughput (32MB range request)"
# This is the stage a HEAD request cannot tell you about. The real download is
# ~305MB, and claude install then pulls the same binary a second time, so the
# install moves ~610MB in total.
START=$(date +%s)
if timeout -k 5 120 curl -fsSL -r 0-33554431 "$BASE/$VERSION/$PLATFORM/claude" \
        -o "$TMP/chunk" 2>/dev/null; then
    ELAPSED=$(( $(date +%s) - START ))
    BYTES=$(wc -c < "$TMP/chunk")
    [ "$ELAPSED" -lt 1 ] && ELAPSED=1
    KBPS=$(( BYTES / ELAPSED / 1024 ))
    echo "got $BYTES bytes in ${ELAPSED}s = ${KBPS} KB/s"
    if [ "$KBPS" -gt 0 ]; then
        SECS=$(( 610 * 1024 / KBPS ))
        echo "=> ~610MB install would take about ${SECS}s ($(( SECS / 60 )) min)"
        echo "   claude_install_timeout is 900s by default."
    fi
else
    echo "FAILED or timed out after 120s on a 32MB range request."
    echo "This is your stall: the host answers, but bulk transfer does not complete."
fi

say "6. Other hosts the CLI contacts on first run"
echo "Any HTTP code means the host answered; 403/404/400 on a bare / are expected."
# A host that is silently dropped (no RST) hangs until connect timeout rather
# than erroring, which looks identical to the download stalling.
for h in api.anthropic.com claude.ai platform.claude.com storage.googleapis.com; do
    if timeout -k 5 15 curl -sS -o /dev/null -w '%{http_code}' "https://$h/" >"$TMP/code" 2>"$TMP/err"; then
        echo "$h -> $(cat "$TMP/code")"
    else
        echo "$h -> UNREACHABLE ($(tr -d '\n' < "$TMP/err"))"
    fi
done

say "Done"
echo "Stage 5 slow or failing  -> throughput; raise claude_install_timeout or fix the link."
echo "Stage 1 tight            -> add RAM or disk to the VM."
echo "Stage 2 shows a 'd' line -> move that directory aside."
echo "Stage 6 UNREACHABLE      -> that host is being dropped, not refused."
