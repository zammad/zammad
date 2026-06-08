# Images

## Recreating the Zammad SVG Icon Store

From the repository root you can run:

```sh
(cd public/assets/images && pnpm install --frozen-lockfile && pnpm exec gulp build)

[14:08:17] Using gulpfile zammad/public/assets/images/gulpfile.js
[14:08:17] Starting 'build'...
[14:08:17] Finished 'build' after 7.48 ms
```

## Development Mode

This is useful when developing. Gulp will watch the files for changes and start rebuilds automatically.

```sh
pnpm exec gulp
[14:14:46] Using gulpfile ~/wz/zammad/public/assets/image/gulpfile.js
[14:14:46] Starting 'default'...
```
