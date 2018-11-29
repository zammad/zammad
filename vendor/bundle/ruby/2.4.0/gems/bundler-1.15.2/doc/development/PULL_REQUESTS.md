# Submitting Pull Requests

Before you submit a pull request, please remember to do the following:

1. Check your code format and style
2. Run the test suite
3. Use a meaningful commit message without tags

## Code formatting

Make sure the code formatting and styling adheres to the guidelines. We use RuboCop for this. Lack of formatting adherence will result in automatic Travis build failures.

      $ bin/rubocop -a

## Tests

Prior to submitting your PR, please run the test suite:

      $ bin/rspec

If you are unable to run the entire test suite, please run the unit test suite and at least the integration specs related to the command or domain of Bundler that your code changes relate to.

Ex. For a pull request that changes something with `bundle update`, you might run:

      $ bin/rspec spec/bundler
      $ bin/rspec spec/commands/update_spec.rb

## Commit messages

Please ensure that the commit messages included in the pull request __do not__ have the following:
  - `@tag` GitHub user or team references (ex. `@indirect` or `@bundler/core`)
  - `#id` references to issues or pull requests (ex. `#43` or `bundler/bundler-site#12`)

If you want to use these mechanisms, please instead include them in the pull request description. This prevents multiple notifications or references being created on commit rebases or pull request/branch force pushes.

Additionally, do not use `[ci skip]` or `[skip ci]` mechanisms in your pull request titles/descriptions or commit messages. Every potential commit and pull request should run through Bundler's CI system. This applies to all changes/commits (ex. even a change to just documentation or the removal of a comment).

## CHANGELOG.md

Don't forget to add your changes into the CHANGELOG! If you're submitting documentation, note the changes under the "Documentation" heading.
