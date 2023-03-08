#!/usr/bin/env bats
load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "skips checkout if skip_checkout flag is set" {
  export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_SKIP_CHECKOUT=true

  run "$PWD/hooks/checkout"

  assert_success
  assert_output "--- :fast_forward: Skipping checkout
Because 'skip_checkout' configuration was set as true in pipeline YAML"

  unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_SKIP_CHECKOUT
}

@test "creates checkout dir if skip flag not set" {
  export BUILDKITE_BUILD_CHECKOUT_PATH="$HOME/repo"

  mkdir -p "$HOME"
  stub git
  stub ssh-keyscan
  stub ssh-keygen
  run "$PWD/hooks/checkout"

  assert_success
  assert [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH" ]
  rm -rf $BUILDKITE_BUILD_CHECKOUT_PATH
  unset BUILDKITE_BUILD_CHECKOUT_PATH
}

@test "creates separate dirs for multiple repos" {
  export BUILDKITE_BUILD_CHECKOUT_PATH="$HOME"
  export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_REPOS_0_CONFIG_0_URL="https://github.com/foo/bar.git"
  export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_REPOS_1_CONFIG_0_URL="https://github.com/foo/baz.git"

  mkdir -p "$HOME"
  stub git
  stub ssh-keyscan
  stub ssh-keygen
  run "$PWD/hooks/checkout"

  assert_success
  assert [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH" ]
  assert [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/bar" ]
  assert [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/baz" ]
  rm -rf $BUILDKITE_BUILD_CHECKOUT_PATH
  unset BUILDKITE_BUILD_CHECKOUT_PATH
  unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_REPOS_0_CONFIG_0_URL
  unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_REPOS_1_CONFIG_0_URL
}
