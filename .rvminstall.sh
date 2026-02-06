#!/usr/bin/env zsh

# Load profile configuration if it exists
[[ -s "$HOME/.config/bash/.bash_profile" ]] && source "$HOME/.config/bash/.bash_profile"

install_ruby() {
  local version_to_install="$1"
  local openssl_dir

  # Ensure Homebrew's openssl@3 is installed
  if ! brew list openssl@3 &>/dev/null; then
    echo "Installing openssl@3 via Homebrew..."
    brew install openssl@3
  fi

  openssl_dir=$(brew --prefix openssl@3)

  # Configure environment variables for compilation
  export PATH="${openssl_dir}/bin:$PATH"
  export LDFLAGS="-L${openssl_dir}/lib"
  export CPPFLAGS="-I${openssl_dir}/include"
  export PKG_CONFIG_PATH="${openssl_dir}/lib/pkgconfig"
  
  # Flags to handle specific compilation issues on modern macOS/compilers
  export RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC
  export optflags="-Wno-error=implicit-function-declaration"

  # Disable RVM autolibs to use our manually specified Homebrew paths
  rvm autolibs disable

  # Attempt to install the specified Ruby version
  if rvm install "${version_to_install}" --with-openssl-dir="${openssl_dir}"; then
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
    echo "Example: rvminstall 3.0.0"
    return 1
  fi

  install_ruby "$1"
}

main "$@"