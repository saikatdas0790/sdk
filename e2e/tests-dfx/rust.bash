#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load ../utils/_

[ -e "${assets:?}/installed/bin/ic-cdk-optimizer" ] || cargo install ic-cdk-optimizer --root "$assets/installed" &> /dev/null

setup() {
    standard_setup
}

teardown() {
    dfx_stop

    standard_teardown
}

@test "rust starter project can build and call" {
    dfx_new_rust hello

    dfx_start
    dfx canister create --all
    assert_command dfx build hello_backend
    assert_match "ic-cdk-optimizer not installed"
    export PATH="$assets/installed/bin/:$PATH"
    assert_command dfx build hello_backend
    assert_match "Executing: ic-cdk-optimizer"
    assert_command dfx canister install hello_backend
    assert_command dfx canister call hello_backend greet dfinity
    assert_match '("Hello, dfinity!")'
}

@test "rust canister can resolve dependencies" {
    dfx_new_rust rust_deps
    install_asset rust_deps
    export PATH="$assets/installed/bin/:$PATH"
    dfx_start
    assert_command dfx deploy
    assert_command dfx canister call multiply_deps read
    assert_match '(1 : nat)'
    assert_command dfx canister call multiply_deps mul '(3)'
    assert_match '(9 : nat)'
    assert_command dfx canister call rust_deps read
    assert_match '(9 : nat)'
}

@test "rust canister can have nonstandard target dir location" {
    dfx_new_rust
    CARGO_TARGET_DIR="$(echo -ne '\x81')"
    export CARGO_TARGET_DIR
    export PATH="$assets/installed/bin/:$PATH"
    dfx_start
    assert_command dfx deploy
    assert_command dfx canister call e2e_project_backend greet dfinity
}
