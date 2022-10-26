# Updating Cypress Visual Snapshots

This command only _updates_ snapshots. Cypress will run only tests with `*-visual.cy` in their name, and will not fail, if snapshot is not correct, but will generate a new snapshot instead.

```sh
# from the root directory
$ yarn cypress:snapshots
```

Please, make sure snapshot is actually correct before pushing your changes.

## Explanation

Cypress doesn't work inside amd64 image, if it's running on ARM processor, even under `--platform=linux/amd64`. So we have two compose files, and based on user processor we run one or the other.

ARM compose file has a custom cache folder, so it doesn't conflict with Mac's usual `~/Library/Cache` folder. It's meant to store cache inside the project folder, but Linux cache can be theoretically shared.
