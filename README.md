# Smooth Checkout
All the things you need during a Buildkite checkout :butter: :kite:

## Usage

### Repository-less builds
```yml
steps:
  - command: echo "Skips checking out Git project in checkout"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          skip_checkout: true
```

### Checking out repo
```yml
steps:
  - command: echo "Checks out repo at given ref"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
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

### Checking out multiple repositories
You can checkout multiple repositories by providing multiple `config` elements:
```yaml
steps:
  - command: echo "Checks out multiple git repositories"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          repos:
            - config:
              - url: git@github.com:<username>/<repo_1>.git
            - config:
              - url: https://github.com/<username>/<repo_2>.git
                ref: <ref>
```
Unlike single repo checkouts, when checking out multiple repos, they will each be checked out in
subdirectories of `$BUILDKITE_BUILD_CHECKOUT_PATH` corresponding to the name of the repository
(based on its URL). In the above example, the contents of the working directory would be `repo_1/`
and `repo_2/`.

You can also explicitly provide the path to an ssh identity file using the `ssh_key_path` config field:
```yaml
steps:
  - command: echo "Checks out multiple git repositories"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          repos:
            - config:
              - url: git@github.com:<username>/<repo_1>.git
                ssh_key_path: .ssh/key_1
            - config:
              - url: git@github.com:<username>/<repo_2>.git
                ref: <ref>
                ssh_key_path: .ssh/key_2
```

If you are using [smooth-secrets](https://github.com/hasura/smooth-secrets-buildkite-plugin) to
configure ssh keys, you can do the following to easily set the `ssh_key_path`:
```yaml
steps:
  - command: echo "Checks out multiple git repositories"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          repos:
            - config:
              - url: git@github.com:<username>/<repo>.git
                ssh_key_path: $$SECRETS_DIR/<key>
```
where `<key>` is the value of
[`key` field](https://github.com/hasura/smooth-secrets-buildkite-plugin#key-required-string) in
smooth-secrets config with any `/` characters replaced by `-`.

### Checking out repo from git mirrors
You can attempt to fetch a git repository from git mirrors and fallback to using the original
source repo in case of a failure while checking out from mirrors.
```yaml
steps:
  - command: echo "Checks out repo from mirror (fall back to github in case of failure)"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          repos:
            - config:
              - url: git@mirror.git.interal:/path/to/git/mirror
              - url: git@github.com:<username>/<reponame>.git
```


## Setup & Cleanup
Smooth Checkout also supports setting custom directories for your jobs and deleting the checkout
directory after the job completes. `BUILDKITE_BUILD_CHECKOUT_PATH` is set to the
directory specified by the `build_checkout_path` option.
```yaml
steps:
  - command: echo "Checks out repo to custom directory"
    plugins:
      - hasura/smooth-checkout#v3.1.0:
          build_checkout_path: /tmp/${BUILDKITE_COMMIT}
          delete_checkout: true
          repos:
            - config:
              - url: git@github.com:<username>/<reponame>.git
```

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
