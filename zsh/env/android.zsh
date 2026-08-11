# ============================================================
# Android CLI development environment
# ============================================================

_android_sdk_default="$HOME/Documents/Developer/Android/SDK"
_android_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${ANDROID_SDK:-$_android_sdk_default}}}"

if [[ -x "$_android_sdk/platform-tools/adb" ]]; then
    export ANDROID_SDK="$_android_sdk"
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$_android_sdk}"
    export ANDROID_HOME="${ANDROID_HOME:-$_android_sdk}"

    _android_emulator_root="${ANDROID_EMULATOR_ROOT:-$HOME/Documents/Developer/Android/Emulator}"
    if [[ -d "$_android_emulator_root" ]]; then
        export ANDROID_EMULATOR_ROOT="$_android_emulator_root"
        export ANDROID_EMULATOR_HOME="${ANDROID_EMULATOR_HOME:-$_android_emulator_root/config}"
        export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$_android_emulator_root/avd}"
    fi

    for _android_bin in \
        "$_android_sdk/cmdline-tools/latest/bin" \
        "$_android_sdk/platform-tools" \
        "$_android_sdk/emulator"; do
        [[ -d "$_android_bin" ]] && path+=("$_android_bin")
    done
fi

unset _android_bin _android_emulator_root _android_sdk _android_sdk_default

export PATH
