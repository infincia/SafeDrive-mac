#!/usr/bin/env bash

# `install` phase: install stuff needed for the `script` phase

set -ex

. $(dirname $0)/utils.sh

install_fuse() {
    case "${TRAVIS_OS_NAME}" in
        linux)
            ;;
        osx)
            brew cask install osxfuse
            ;;
    esac
}

install_rustup() {
    RUST_VER=$(<${RUST_VER_FILE})

    echo "Using Rust ${RUST_VER}"
    curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain=${RUST_VER}
    rustup target add ${TARGET} || true
    rustc -V
    cargo -V
    if [ ! -f ${HOME}/.cargo/bin/cheddar ]; then
        cargo install moz-cheddar
    else
        echo "cheddar already installed, skipping"
    fi
}

main() {
    install_fuse
    install_rustup
}

main