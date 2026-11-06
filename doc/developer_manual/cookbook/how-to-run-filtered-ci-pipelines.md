# How to Run Filtered CI Pipelines

A push to GitLab can carry CI variables that reduce the pipeline to a single job, for example to rerun one job or to
check whether a flaky test is stable now. Such a pipeline is an extra branch pipeline next to the merge request
pipeline, as push options cannot reach merge request pipelines.

GitLab only creates a pipeline for a push that changes the branch. To filter a branch that is already pushed, add an
empty commit first (`git commit --allow-empty -m "Loop the flaky spec."`) and drop it again afterwards.

## Run a Single Job

`JOB_FILTER` selects one job by its name:

```sh
git push -o ci.variable="JOB_FILTER=frontend:vitest:browser"
```

Jobs split with `parallel` need the full name of the shard, for example `rspec 1/8`.

## Loop a System Test

`BROWSER_TEST_FILTER` runs the given RSpec arguments 50 times in Chromium and in Firefox, until the first failure:

```sh
git push -o ci.variable="BROWSER_TEST_FILTER=spec/system/ticket/zoom_spec.rb:1072"
```

The line number has to be exact. RSpec runs the nearest example or example group declared above it instead of
failing, so a stale line number loops a different example, or every example of a group.

## Loop a Browser Test

`VITEST_BROWSER_TEST_FILTER` runs the matching Vitest browser tests 50 times, until the first failure. It takes the
same file filters as `pnpm test:browser`, so a part of the file name is enough. `VITEST_BROWSER_TEST_NAME_PATTERN`
optionally narrows the run to the tests whose name matches (`-t`):

```sh
git push \
  -o ci.variable="VITEST_BROWSER_TEST_FILTER=editor-mention-user.browser.spec.ts" \
  -o ci.variable="VITEST_BROWSER_TEST_NAME_PATTERN=inserts a user mention"
```

A `file:line` filter does not select a single test here, unlike the line number of a system test above: in browser
mode Vitest answers every line of a spec with `No test found in … in line <n>`.

The screenshots of the failing run end up in the artifacts of the `frontend:vitest:browser:filtered` job.

## Arguments of a Loop Filter

Both loop filters are split on whitespace, so they take a path or several paths, but no quoted argument:
`-t "inserts a user mention"` would reach Vitest as four arguments, and `-e "..."` RSpec the same way. This is what
`VITEST_BROWSER_TEST_NAME_PATTERN` is for, which is passed as a single quoted argument.

## Change the Number of Runs

`BROWSER_TEST_FILTER_LOOP_COUNT` and `VITEST_BROWSER_TEST_FILTER_LOOP_COUNT` change the default of 50 runs:

```sh
git push \
  -o ci.variable="VITEST_BROWSER_TEST_FILTER=editor-basic.browser.spec.ts" \
  -o ci.variable="VITEST_BROWSER_TEST_FILTER_LOOP_COUNT=200"
```
