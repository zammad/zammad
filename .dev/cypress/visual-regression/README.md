# Cypress Visual Regression Tests

## Updating Image Snapshots

This command only _updates_ snapshots. Cypress will run only tests with `*-visual.cy` in their name, and will not fail,
if snapshot is not correct, but will generate a new snapshot instead.

```sh
# from the root directory
pnpm cypress:snapshots
```

Please, make sure snapshot is actually correct before pushing your changes.

## Running Tests

Although you may run visual tests using `pnpm test:ci:ct` command, this will execute them in your current development
environment. However, stored image snapshots were generated in Docker containers in order to achieve consistent
environment every time. Due to multiple factors (i.e. screen density, font resolution, browser version, etc), your
mileage may vary and you may receive false negatives.

It is therefore advisable to run the visual regression tests in the same environment where the image snapshots are
normally updated. You can do this by setting an environment variable and running the snapshots command:

```sh
# from the root directory
CYPRESS_UPDATE_SNAPSHOTS=false pnpm cypress:snapshots
```

## Multiple Architecture (AMD64 vs ARM)

Cypress doesn't work inside amd64 image, if it's running on ARM processor, even under `--platform=linux/amd64`. So we
have two compose files, and based on user processor we run one or the other.

ARM compose file has a custom cache folder, so it doesn't conflict with Mac's usual `~/Library/Cache` folder. It's
meant to store cache inside the project folder, but Linux cache can be theoretically shared.
