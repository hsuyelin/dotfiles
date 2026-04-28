# RTK (Rust Token Killer) — reduces LLM token consumption by 60-90% on AI coding sessions.
# Integration: Claude Code PreToolUse hook installed by `rtk init -g` via install.sh.
# Config: ${XDG_CONFIG_HOME}/rtk/config.toml

# Opt out of telemetry by default; run `rtk telemetry enable` to consent.
export RTK_TELEMETRY_DISABLED=1

# One-liner to fully remove RTK from this machine.
rtk-uninstall() {
    rtk init -g --uninstall \
        && brew uninstall rtk \
        && unlink "${HOME}/Library/Application Support/rtk" 2>/dev/null || true
    echo "RTK uninstalled. Remove XDG config with: rm -rf \${XDG_CONFIG_HOME}/rtk"
}
