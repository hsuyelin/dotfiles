# PATH environment
export PATH="$PATH:\
/opt/homebrew/bin:\
/usr/local/sbin:/usr/local/bin:\
/sbin:/bin:/usr/sbin:/usr/bin:\
/root/bin:\
$HOME/.local/bin:\
$HOME/.rvm/bin:\
/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources:\
$ANDROID_SDK/platform-tools:\
$ANDROID_SDK/tools"

# UTF-8 Local
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Stop seeing Apple's warning to use zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# Env
export COCOAPODS_NO_BUNDLER=1
export PYTHONWARNINGS="ignore:NotOpenSSLWarning"

# Load secrets
[[ -f "$HOME/.config/secrets/.env.secrets" ]] && source "$HOME/.config/secrets/.env.secrets"

# Add Cargo
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
