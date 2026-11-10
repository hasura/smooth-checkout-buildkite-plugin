#!/usr/bin/env bash

# clean_checkout is only for disposable CI workspaces below the agent build root.
validate_cleanup_path() {
  local build_root checkout_path
  if [[ "${BUILDKITE_PLUGIN_SMOOTH_CHECKOUT_DELETE_CHECKOUT:-}" != "true" ]]; then
    echo "clean_checkout requires delete_checkout: true" >&2
    return 1
  fi
  if [[ -z "${BUILDKITE_BUILD_PATH:-}" || -z "${BUILDKITE_BUILD_CHECKOUT_PATH:-}" ]]; then
    echo "clean_checkout requires BUILDKITE_BUILD_PATH and BUILDKITE_BUILD_CHECKOUT_PATH" >&2
    return 1
  fi
  if [[ -L "$BUILDKITE_BUILD_CHECKOUT_PATH" ]]; then
    echo "Refusing to clean a symlink checkout: $BUILDKITE_BUILD_CHECKOUT_PATH" >&2
    return 1
  fi
  build_root="$(cd "$BUILDKITE_BUILD_PATH" && pwd -P)" || return 1
  [[ "$build_root" != "/" ]] || return 1
  # Nothing exists to delete on a new worker.
  if [[ ! -e "$BUILDKITE_BUILD_CHECKOUT_PATH" ]]; then
    return 0
  fi
  checkout_path="$(cd "$BUILDKITE_BUILD_CHECKOUT_PATH" && pwd -P)" || return 1
  case "$checkout_path" in
    "$build_root"/*) ;;
    *) echo "Refusing to clean outside the agent build root: $checkout_path" >&2; return 1 ;;
  esac
}

remove_disposable_checkout() {
  local checkout_path="$BUILDKITE_BUILD_CHECKOUT_PATH"
  local errors
  [[ -e "$checkout_path" || -L "$checkout_path" ]] || return 0

  errors="$(mktemp)" || return 1
  echo "Removing disposable checkout: $checkout_path"
  if rm -rf -- "$checkout_path" 2>"$errors" && [[ ! -e "$checkout_path" && ! -L "$checkout_path" ]]; then
    rm -f -- "$errors"
    return 0
  fi

  echo "Removal failed; last errors:" >&2
  tail -n 30 "$errors" >&2
  echo "Repairing owner permissions and retrying checkout removal" >&2
  # Nix and test fixtures can leave read-only directories owned by this user.
  # Recursive chmod does not follow symlinks within the checkout.
  chmod -R u+rwX -- "$checkout_path" 2>"$errors" || tail -n 30 "$errors" >&2
  if rm -rf -- "$checkout_path" 2>"$errors" && [[ ! -e "$checkout_path" && ! -L "$checkout_path" ]]; then
    rm -f -- "$errors"
    return 0
  fi

  echo "Checkout removal still failed; last errors:" >&2
  tail -n 30 "$errors" >&2
  ls -ld -- "$checkout_path" >&2 || true
  rm -f -- "$errors"
  return 1
}

clean_disposable_checkout() {
  # Validate before changing cwd or running either destructive command.
  validate_cleanup_path || return 1
  cd / || return 1
  if ! remove_disposable_checkout; then
    echo "Checkout is unusable; stopping this agent before it can accept another job" >&2
    # This supported agent command requests a graceful stop after the current job.
    # It uses the job's agent access token, not a new credential or sudo grant.
    if ! buildkite-agent stop; then
      echo "ERROR: could not stop the agent; operator intervention is required" >&2
    fi
    return 1
  fi
}
