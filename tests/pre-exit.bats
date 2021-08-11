#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "deletes checkout directory" {
  export BUILDKITE_BUILD_ID="test-build-id"
  export BUILDKITE_JOB_ID="test-job-id"
  export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_CLONE_URL="https://github.com/test-org/test"

  TEST_WORKSPACE="$HOME/buildkite-checkouts/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID"
  TEST_CLONE_DIR="${TEST_WORKSPACE}/test"

  mkdir -p "$TEST_CLONE_DIR"
  assert [ -d "$TEST_CLONE_DIR" ]

  run "$PWD/hooks/pre-exit"

  assert_success
  assert [ ! -d "$TEST_CLONE_DIR" ]
}

