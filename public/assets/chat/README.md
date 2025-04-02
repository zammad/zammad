# Chat

## Recreating the Static Zammad Chat Build

```sh
pnpm install
pnpm exec gulp build
[11:13:03] Using gulpfile zammad/public/assets/chat/gulpfile.js
[11:13:03] Starting 'build'...
[11:13:03] Starting 'js'...
[11:13:03] Starting 'no_jquery'...
[11:13:03] Starting 'css'...
[11:13:03] Finished 'js' after 6.21 ms
[11:13:03] Finished 'no_jquery' after 7.75 ms
[11:13:03] Finished 'css' after 8.81 ms
[11:13:03] Finished 'build' after 9.8 ms
```

## Development Mode

This is useful when developing. Gulp will watch the files for changes and start rebuilds automatically.

```sh
pnpm exec gulp
[11:14:46] Using gulpfile ~/wz/zammad/public/assets/chat/gulpfile.js
[11:14:46] Starting 'default'...
```
