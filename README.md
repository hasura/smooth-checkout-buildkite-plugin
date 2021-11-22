# Smooth Checkout
All the things you need during a Buildkite checkout :butter: :kite:

## Usage

### Repository-less builds
```yml
steps:
  - command: echo "Skips checking out Git project in checkout" 
    plugins:
      - hasura/smooth-checkout#v3.0.0:
          skip_checkout: true
```

### Checking out repo
```yml
steps:
  - command: echo "Checks out repo at given ref"
    plugins:
      - hasura/smooth-checkout#v3.0.0:
          repos:
            - config:
              - url: git@github.com:<username>/<reponame>.git
                ref: <ref>
```

If `ref` is not provided the values of `BUILDKITE_BRANCH` and `BUILDKITE_COMMIT` env vars are used.

Allowed values for `ref`:
- Branch name
- Git tag
- Commit SHA (40 character long hash)

### Checking out multiple repos
You can checkout multiple repositories by providing multiple `config` elements:
```yaml
steps:
  - command: echo "Checks out repo from mirror (fall back to github in case of failure)"
    plugins:
      - hasura/smooth-checkout#v3.0.0:
          repos:
            - config:
              - url: git@github.com:<username>/<repo_1>.git
            - config:
              - url: git@github.com:<username>/<repo_2>.git
                ref: <ref>
```

Unlike single repo checkouts, when checking out multiple repos, the working directory will be set to `$WOKRSPACE`, where all the repo checkouts have been done.
In the above example, the contents of the working directory would be `repo_1/` and `repo_2/`.

### Checking out repo from git mirrors
You can attempt to fetch a git repository from git mirrors and fallback to using the original source repo in case of a failure while checking out from mirrors.
```yaml
steps:
  - command: echo "Checks out repo from mirror (fall back to github in case of failure)"
    plugins:
      - hasura/smooth-checkout#v3.0.0:
          repos:
            - config:
              - url: git@mirror.git.interal:/path/to/git/mirror
              - url: git@github.com:<username>/<reponame>.git
```


## Setup & Cleanup
Smooth Checkout sets up a workspace directory for your jobs in a non-conflicting fashion. Smooth Checkout achieves this by setting up a workspace directory at `$HOME/buildkite-checkouts/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID`. The workspace path is made available as `WORKSPACE` environment variable in command section.

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
