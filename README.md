# Smooth Checkout
All the things you need during a Buildkite checkout :butter: :kite:

## Repository-less builds
```yml
steps:
  - command: echo "Skips checking out Git project in checkout" 
    plugins:
      - hasura/smooth-checkout#v1.0.0:
          skip_checkout: true
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
  - Run tests(try to add tests for any new features introduced)
    ```bash
    docker-compose run --rm tests
    ```
  - Once linter and tests run successfully, open a pull request on this repo
