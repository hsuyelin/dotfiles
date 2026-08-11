# ============================================================
# Java fallback for Android tooling
# ============================================================

_android_java_home="$HOME/.local/share/jdks/temurin-17.jdk/Contents/Home"
if [[ -z "${JAVA_HOME:-}" && -x "$_android_java_home/bin/java" ]]; then
    export JAVA_HOME="$_android_java_home"
    # shellcheck disable=SC2206
    path=("$JAVA_HOME/bin" $path)
fi
unset _android_java_home

export PATH
