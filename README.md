# Smooth Checkout
All the things you need during a Buildkite checkout :butter: :kite:

# Usage

## Repository-less builds
```yml
steps:
  - command: echo "Skips checking out Git project in checkout" 
    plugins:
      - hasura/smooth-checkout#main:
          skip_checkout: true
```
