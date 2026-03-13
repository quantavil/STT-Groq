# Groq Whisper STT for KDE Wayland

A lightweight, toggle-based speech-to-text (STT) script for Linux (KDE Wayland) using the Groq API and Whisper. Automatically records audio, transcribes it via Groq's high-speed Whisper model, and copies the result directly to your clipboard.

## Features
- **Toggle Recording:** Press a shortcut to start, press again to stop and transcribe.
- **Auto-Stop Fuse:** Automatically stops recording after a configurable duration (default: 60s).
- **Clipboard Integration:** Transcripts are automatically copied to the system clipboard (`wl-copy`).
- **Desktop Notifications:** Provides visual feedback on recording, transcribing, and completion.
- **High Speed:** Leverages Groq's fast inference for near-instant transcriptions.

## Prerequisites

Ensure you have the following dependencies installed:

```bash
# Arch Linux (CachyOS)
sudo pacman -S pipewire-audio curl jq wl-clipboard libnotify
```

Dependencies:
- `pw-record`: Part of PipeWire for recording audio.
- `curl`: For API requests.
- `jq`: For parsing JSON responses.
- `wl-copy`: For clipboard management on Wayland.
- `notify-send`: For desktop notifications.

## Installation

1. **Clone or Download the script:**
   Save the `stt.sh` file to a convenient location, e.g., `~/stt.sh`.

2. **Make it executable:**
   ```bash
   chmod +x ~/stt.sh
   ```

3. **Configure your API Key:**
   You can either export it as an environment variable or paste it directly into the script:

   **Option A: Environment Variable (Recommended)**
   ```bash
   export GROQ_API_KEY="gsk_your_actual_key_here"
   ```

   **Option B: Edit stt.sh**
   Open `stt.sh` and replace the placeholder:
   ```bash
   API_KEY="${GROQ_API_KEY:-gsk_your_actual_key_here}"
   ```

## Usage

### Terminal
You can run the script manually to test:
- **First Run:** Starts recording.
- **Second Run:** Stops recording and transcribes.

```bash
~/stt.sh
```

### KDE Keyboard Shortcut (Recommended)
To use this as a global STT tool:

1. Open **System Settings** → **Shortcuts** → **Shortcuts**.
2. Scroll to the bottom and click **Add Command**.
3. In the Command field, enter the full path to the script: `/home/quantavil/stt.sh` (or your chosen path).
4. Click the shortcut box and assign a key combo (e.g., `Alt + L`).
5. Click **Apply**.

Now you can press your shortcut to start/stop dictation anywhere!

## Configuration

You can customize the script behavior by editing the variables in the `stt.sh` file:

- `MODEL`: The Whisper model to use (default: `whisper-large-v3-turbo`).
- `LANGUAGE`: The target language for transcription (default: `en`).
- `MAX_DURATION`: Maximum recording time in seconds before auto-stop (default: `60`).

## License
This project is licensed under the [MIT License](LICENSE).
