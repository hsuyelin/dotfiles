# PATH environment
export PATH="$PATH:\
/opt/homebrew/bin:\
/usr/local/sbin:/usr/local/bin:\
/sbin:/bin:/usr/sbin:/usr/bin:\
/root/bin:\
"

# Optional paths (only if they exist)
[[ -d "$HOME/.local/bin" ]] && export PATH="$PATH:$HOME/.local/bin"
[[ -d "$HOME/.rvm/bin" ]] && export PATH="$PATH:$HOME/.rvm/bin"

# Xcode DVTFoundation (only if Xcode is installed)
XCODE_DVT="/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources"
[[ -d "$XCODE_DVT" ]] && export PATH="$PATH:$XCODE_DVT"

# Android SDK (only if ANDROID_SDK is set and exists)
if [[ -n "${ANDROID_SDK:-}" ]] && [[ -d "$ANDROID_SDK" ]]; then
    export PATH="$PATH:$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools"
fi

# UTF-8 Local
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Stop seeing Apple's warning to use zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# Env
export COCOAPODS_NO_BUNDLER=1
export PYTHONWARNINGS="ignore:NotOpenSSLWarning"
