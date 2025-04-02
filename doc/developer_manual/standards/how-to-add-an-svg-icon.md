# How to Add an SVG Icon

Icons should be added to the [public icons folder](/public/assets/images/icons).

## Graphic Dimensions

You should adjust the SSO graphic dimensions to `29x24` using a vector graphics program so that it fits in with the
other ones.

## Colors

There are two colors that act as variables so that they can get replaced via CSS. The main one is `#50E3C2` that can
get overwritten in CSS via `fill` and the secondary is `#BD0FE1`, that can be overwritten in css via `color`. The SSO
graphics (top right corner) don't use these variables so you probably won't need them either.

## Build Process

See [`public/assets/images/README.md`](/public/assets/images/README.md):

```sh
pnpm install
pnpm exec gulp build
[14:08:17] Using gulpfile zammad/public/assets/images/gulpfile.js
[14:08:17] Starting 'build'...
[14:08:17] Finished 'build' after 7.48 ms
```

Now the icon should be included in `icons.svg`.

## Attribution

Add the author, url and license to `LICENSE-ICONS-3RD-PARTY.json`. If you have a local server running that supports
php, there is a UI for this: `contrib/edit-icon-license-list.php`
