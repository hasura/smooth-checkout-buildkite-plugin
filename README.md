# Smooth Checkout
All the things you need during a Buildkite checkout :butter: :kite:

## Usage

### Repository-less builds
```yml
steps:
  - command: echo "Skips checking out Git project in checkout" 
    plugins:
      - hasura/smooth-checkout#v1.1.0:
          skip_checkout: true
```

### Checking out repo
```yml
steps:
  - command: echo "Checks out repo at given ref"
    plugins:
      - hasura/smooth-checkout#v1.1.0:
          clone_url: https://github.com/<username>/<reponame>
          ref: <ref>
```
If `clone_url` is not provided, the plugin uses the `BUILDKITE_REPO` env var's value as the target repo. Similarly, if `ref` is not provided the value of `BUILDKITE_BRANCH` env var is used.

Allowed values for `ref`:
- Branch name
- Git tag
- Commit SHA (40 character long hash)

### Checking out from mirrors
You can attempt to fetch a git repository from mirrors and fallback to using the original source repo in case of a failure while checking out from mirrors.
```yaml
steps:
  - command: echo "Checks out repo at given ref"
    plugins:
      - hasura/smooth-checkout#v1.1.0:
          clone_urls:
            - url: git@mirror.git.interal:/path/to/git/mirror
            - url: https://github.com/<username>/<reponame>
          ref: <ref>
```

## Setup & Cleanup
Smooth Checkout setups a workspace directory for your jobs in a non-conflicting fashion. By default, Buildkite uses `HOME/builds/<HOSTNAME>/<PIPELINE_SLUG>` as checkout directory. If `parallelism` is set in the step, then parallel jobs might conflict in the checkout stage if build is running on the same host machine.

Smooth Checkout overcomes this by setting up a workspace directory at `$HOME/buildkite-checkouts/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID`. The workspace path is made available as `WORKSPACE` environment variable in command section.

Smooth Checkout also takes care of cleaning up the workspace directory at the end of the Buildkite job.

## Contributing
  - Fork this repo and clone on your machine:
    ```bash
    git clone https://github.com/<your-username>/smooth-checkout-buildkite-plugin
    ```
  - Make the required changes
  - Run linter
    ```bash
    docker-compose run --rm lint
    ```
  - Run tests (try to add tests for any new features introduced)
    ```bash
    docker-compose run --rm tests
    ```
  - Once linter and tests run successfully, open a pull request on this repo
