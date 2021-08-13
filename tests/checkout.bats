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
  export BUILDKITE_BUILD_ID="test-build-id"
  export BUILDKITE_JOB_ID="test-job-id"
  export WORKSPACE="$HOME/buildkite-checkouts/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID"

  stub git
  stub ssh-keyscan
  stub ssh-keygen
  run "$PWD/hooks/checkout"

  assert_success
  assert [ -d "$WORKSPACE" ]
}
