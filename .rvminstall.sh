#!/usr/bin/env bash

# Load profile configuration if it exists
[[ -s "$HOME/.config/bash/.bash_profile" ]] && source "$HOME/.config/bash/.bash_profile"

# Ensure rvm is available in the current session
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

install_ruby() {
    local version_to_install="$1"
    local openssl_dir libyaml_dir

    # Ensure brew is available
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew is not installed. Please install Homebrew first."
        return 1
    fi

    # Ensure rvm is available
    if ! command -v rvm &>/dev/null; then
        echo "❌ RVM is not installed. Please install RVM first."
        return 1
    fi

    # Ensure Homebrew dependencies are installed
    if ! brew list openssl@3 &>/dev/null; then
        echo "Installing openssl@3 via Homebrew..."
        brew install openssl@3
    fi

    if ! brew list libyaml &>/dev/null; then
        echo "Installing libyaml via Homebrew..."
        brew install libyaml
    fi

    openssl_dir="$(brew --prefix openssl@3)"
    libyaml_dir="$(brew --prefix libyaml)"

    # Configure environment variables for compilation
    export PATH="${openssl_dir}/bin:$PATH"
    export LDFLAGS="-L${openssl_dir}/lib -L${libyaml_dir}/lib"
    export CPPFLAGS="-I${openssl_dir}/include -I${libyaml_dir}/include"
    export PKG_CONFIG_PATH="${openssl_dir}/lib/pkgconfig:${libyaml_dir}/lib/pkgconfig"

    # Flags to handle specific compilation issues on modern macOS/compilers
    export RUBY_CFLAGS="-DUSE_FFI_CLOSURE_ALLOC"
    export optflags="-Wno-error=implicit-function-declaration"

    # Disable RVM autolibs to use our manually specified Homebrew paths
    rvm autolibs disable

    # Attempt to install the specified Ruby version
    if rvm install "${version_to_install}" \
        --with-libyaml-dir="${libyaml_dir}" \
        --with-openssl-dir="${openssl_dir}"; then
        echo ""
        echo "✅ Ruby ${version_to_install} installed successfully!"
        echo "    You can now switch versions using: rvm use ${version_to_install}"
    else
        echo ""
        echo "❌ Ruby ${version_to_install} installation failed."
        echo "    Please check the error logs above."
        return 1
    fi
}

main() {
    # Check if a version argument was provided
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a Ruby version number to install."
        echo "Usage: rvminstall <version>"
        echo "Example: rvminstall 3.3.7"
        return 1
    fi

    install_ruby "$1"
}

main "$@"