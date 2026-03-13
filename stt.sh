#!/usr/bin/env bash
set -uo pipefail

# ── Groq Whisper STT — KDE Wayland Toggle ─────────────────────
#
# First trigger  → starts recording  🎙
# Second trigger → stops, transcribes, copies to clipboard 📋
# Fuse           → auto-stops after MAX_DURATION seconds ⏰
#
# Dependencies: pw-record curl jq wl-copy notify-send
#   sudo pacman -S pipewire-audio curl jq wl-clipboard libnotify

# ── Configuration ──────────────────────────────────────────────
API_KEY="${GROQ_API_KEY:-gsk_REPLACE_ME_WITH_YOUR_ACTUAL_GROQ_API_KEY}"
MODEL="whisper-large-v3-turbo"
LANGUAGE="en"           # Force English alphabet output (Hinglish → romanized)
MAX_DURATION=60         # Safety fuse: auto-stop recording after N seconds
PID_FILE="/tmp/groq_stt.pid"
AUDIO_FILE="/tmp/groq_stt_audio.wav"
SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"

# Ensure Wayland clipboard access (needed when run from KDE shortcut)
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# ── Helpers (DRY) ─────────────────────────────────────────────
log()  { printf '[STT %s] %s\n' "$(date +%T)" "$*" >&2; }

die() {
    log "FATAL: $1"
    notify-send -u critical "Groq STT Error" "$1"
    exit 1
}

notify() {
    log "$1 — $2"
    notify-send "$1" "$2"
}

cleanup() { rm -f "$PID_FILE" "$AUDIO_FILE"; }

# ── Dependency check ──────────────────────────────────────────
for cmd in pw-record curl jq wl-copy notify-send; do
    command -v "$cmd" &>/dev/null || die "Missing dependency: $cmd"
done

# ── STOP path (PID file exists) ──────────────────────────────
if [[ -f "$PID_FILE" ]]; then
    PID=$(<"$PID_FILE")
    rm -f "$PID_FILE"

    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        sleep 0.3
        log "Stopped recording (PID $PID)"
    else
        log "Stale PID $PID — cleaning up"
        cleanup
    fi

    # Transcribe only if audio file exists
    if [[ -f "$AUDIO_FILE" ]]; then
        notify "⏳ Transcribing…" "Processing audio with Groq API…"

        CURL_ARGS=(
            -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions"
            -H "Authorization: Bearer $API_KEY"
            -F "file=@$AUDIO_FILE"
            -F "model=$MODEL"
            -F "response_format=json"
        )
        [[ -n "$LANGUAGE" ]] && CURL_ARGS+=(-F "language=$LANGUAGE")

        if ! RESPONSE=$(/usr/bin/curl "${CURL_ARGS[@]}"); then
            cleanup
            die "curl failed — check your network"
        fi
        log "API response: $RESPONSE"

        # ── Parse response — IFS=tab so spaces in TEXT don't leak into ERROR
        IFS=$'\t' read -r TEXT ERROR < <(
            printf '%s' "$RESPONSE" |
            jq -r '[ (.text // ""), (.error.message // "") ] | @tsv'
        )

        [[ -n "$ERROR" ]] && { cleanup; die "API: $ERROR"; }
        [[ -z "$TEXT" ]]  && { cleanup; die "Empty transcript (silence or noise?)"; }

        # Trim leading whitespace (Whisper quirk)
        TEXT="${TEXT#"${TEXT%%[![:space:]]*}"}"

        # ── Output: terminal + clipboard ──────────────────────
        log "Transcript: $TEXT"
        echo "$TEXT"
        wl-copy -- "$TEXT"
        notify "📋 Copied to clipboard" "$TEXT"
        rm -f "$AUDIO_FILE"
        exit 0
    fi
fi

# ── START path ────────────────────────────────────────────────
rm -f "$AUDIO_FILE"

pw-record --rate 16000 --channels 1 --format s16 "$AUDIO_FILE" &>/dev/null &
PID=$!
sleep 0.2

if ! kill -0 "$PID" 2>/dev/null; then
    rm -f "$PID_FILE"
    die "pw-record failed to start"
fi

echo "$PID" > "$PID_FILE"

# ── Fuse: auto-stop after MAX_DURATION ────────────────────────
(
    sleep "$MAX_DURATION"
    if [[ -f "$PID_FILE" ]] && [[ "$(<"$PID_FILE")" == "$PID" ]]; then
        notify-send -u warning "⏰ STT Fuse" \
            "Auto-stopping: recording exceeded ${MAX_DURATION}s"
        exec "$SELF"          # Re-runs script → hits STOP path → transcribes
    fi
) &>/dev/null &
disown                        # Detach so parent shell exit doesn't kill it

notify "🎙 Recording…" "Press shortcut again to stop (auto-stops in ${MAX_DURATION}s)"