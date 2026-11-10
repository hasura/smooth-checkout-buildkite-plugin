#!/usr/bin/env bash
# Exercise the real hooks and filesystem as the unprivileged CI user.
set -euo pipefail

PLUGIN="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(mktemp -d)"
trap 'chmod -R u+rwX "$ROOT" 2>/dev/null || true; rm -rf "$ROOT"' EXIT
export BUILDKITE_BUILD_PATH="$ROOT/builds"
export BUILDKITE_BUILD_CHECKOUT_PATH="$BUILDKITE_BUILD_PATH/checkout"
export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_DELETE_CHECKOUT=true
export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_CLEAN_CHECKOUT=true
export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_REPOS_0_CONFIG_0_URL=https://example.invalid/repo.git
export BUILDKITE_BRANCH=main BUILDKITE_COMMIT=test BUILDKITE_TAG=""
export COMMAND_LOG="$ROOT/commands"
mkdir -p "$BUILDKITE_BUILD_PATH" "$ROOT/bin"
REAL_RM="$(command -v rm)"
REAL_CHMOD="$(command -v chmod)"
export REAL_RM REAL_CHMOD
cat >"$ROOT/bin/git" <<'SH'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$COMMAND_LOG"
if [[ "$1" == clone ]]; then
  [[ -z "$(ls -A .)" ]] || { echo "clone target was not empty"; exit 1; }
  mkdir .git
fi
SH
cat >"$ROOT/bin/ssh-keygen" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$ROOT/bin/buildkite-agent" <<'SH'
#!/usr/bin/env bash
echo "agent $*" >>"$COMMAND_LOG"
exit "${STOP_RC:-0}"
SH
# Fail both removal attempts to model residue owned by a different user.
cat >"$ROOT/bin/rm" <<'SH'
#!/usr/bin/env bash
if [[ "${FAIL_REMOVE:-}" == true && "$*" == *"$BUILDKITE_BUILD_CHECKOUT_PATH"* ]]; then
  echo "permission denied (fixture)" >&2
  exit 1
fi
exec "$REAL_RM" "$@"
SH
cat >"$ROOT/bin/chmod" <<'SH'
#!/usr/bin/env bash
echo "chmod $*" >>"$COMMAND_LOG"
exec "$REAL_CHMOD" "$@"
SH
chmod +x "$ROOT/bin/"*
export PATH="$ROOT/bin:$PATH"
pass=0

check() {
  echo "ok - $1"
  pass=$((pass + 1))
}
reset() {
  unset FAIL_REMOVE STOP_RC
  "$REAL_CHMOD" -R u+rwX "$BUILDKITE_BUILD_PATH" 2>/dev/null || true
  "$REAL_RM" -rf "$BUILDKITE_BUILD_PATH/checkout"
  : >"$COMMAND_LOG"
}
run_hook() {
  bash "$PLUGIN/hooks/$1" >"$ROOT/output" 2>&1
}
expect_failure() {
  if run_hook "$1"; then
    echo "expected $1 to fail" >&2
    cat "$ROOT/output" >&2
    exit 1
  fi
}

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data/postgres"
touch "$BUILDKITE_BUILD_CHECKOUT_PATH/data/postgres/PG_VERSION"
run_hook checkout
test -d "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"
test ! -e "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
! grep -q 'agent stop' "$COMMAND_LOG"
check "checkout recovers leftover data without .git before cloning"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data/postgres"
touch "$BUILDKITE_BUILD_CHECKOUT_PATH/data/postgres/PG_VERSION"
"$REAL_CHMOD" 500 "$BUILDKITE_BUILD_CHECKOUT_PATH/data/postgres"
"$REAL_CHMOD" 500 "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
run_hook pre-exit
test ! -e "$BUILDKITE_BUILD_CHECKOUT_PATH"
grep -q '^chmod -R u+rwX' "$COMMAND_LOG"
! grep -q 'agent stop' "$COMMAND_LOG"
check "cleanup repairs read-only directories and removes the checkout"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
export FAIL_REMOVE=true
expect_failure checkout
grep -qx 'agent stop' "$COMMAND_LOG"
! grep -q '^git ' "$COMMAND_LOG"
test -d "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
check "unrecoverable checkout stops the agent and does not clone"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
export FAIL_REMOVE=true
expect_failure pre-exit
grep -qx 'agent stop' "$COMMAND_LOG"
grep -q 'permission denied (fixture)' "$ROOT/output"
check "unrecoverable post-job cleanup stops the agent and fails visibly"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
export FAIL_REMOVE=true STOP_RC=1
expect_failure pre-exit
grep -q 'operator intervention is required' "$ROOT/output"
check "failed stop request is reported and does not turn cleanup green"

reset
mkdir -p "$ROOT/outside"
touch "$ROOT/outside/keep"
export BUILDKITE_BUILD_CHECKOUT_PATH="$ROOT/outside"
expect_failure pre-exit
test -f "$ROOT/outside/keep"
test ! -s "$COMMAND_LOG"
check "outside-build-root checkout is never removed or chmodded"

export BUILDKITE_BUILD_CHECKOUT_PATH="$BUILDKITE_BUILD_PATH"
expect_failure pre-exit
test -d "$BUILDKITE_BUILD_PATH"
check "build root itself is never removed"

export BUILDKITE_BUILD_CHECKOUT_PATH="$BUILDKITE_BUILD_PATH/checkout"
ln -s "$ROOT/outside" "$BUILDKITE_BUILD_CHECKOUT_PATH"
expect_failure pre-exit
test -f "$ROOT/outside/keep"
test -L "$BUILDKITE_BUILD_CHECKOUT_PATH"
"$REAL_RM" "$BUILDKITE_BUILD_CHECKOUT_PATH"
check "symlink checkout is rejected"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH"
ln -s "$ROOT/outside" "$BUILDKITE_BUILD_CHECKOUT_PATH/linked"
run_hook pre-exit
test -f "$ROOT/outside/keep"
check "symlink inside checkout does not remove its target"

reset
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_DELETE_CHECKOUT
expect_failure checkout
test -d "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
test ! -s "$COMMAND_LOG"
check "clean checkout requires explicit disposable checkout configuration"

export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_DELETE_CHECKOUT=true
export BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_SKIP_CHECKOUT=true
run_hook checkout
run_hook pre-exit
test -d "$BUILDKITE_BUILD_CHECKOUT_PATH/data"
test ! -s "$COMMAND_LOG"
unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_SKIP_CHECKOUT
check "skip checkout also skips new cleanup"

reset
unset BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_CLEAN_CHECKOUT
mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"
run_hook checkout
grep -q '^git clean ' "$COMMAND_LOG"
! grep -q '^agent ' "$COMMAND_LOG"
check "existing consumers keep checkout reuse unless they opt in"

echo "$pass tests passed"