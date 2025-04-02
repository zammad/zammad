# Rules for Icons in the New Stack

- All icon names must be unique, however you are free to put them in another set (subdirectory).
- All icons must use fill for their elements, but not stroke. In case of outlined design, please expand the stroke into
  a path first.
- All icons must be provided in a monochrome design and any fill values must be removed from the SVG definition. This
  includes `fill="none"` on the root element too. An implicit `fill: currentColor` rule is applied by `CommonIcon`
  component, so it will inherit the color of the surrounding text.
- Attributes `fill-rule` and `clip-rule` can be applied only if the design requires it (no implicit attributes are
  allowed).

## Rules for `desktop` Icon Set

- All icons must have size of `width="16"` and `height="16"`, any further resizing can happen only inside `CommonIcon`
  component. Please make sure that `viewBox` is set to `0 0 16 16`.
- All icons must be put into `app/frontend/apps/desktop/initializer/assets/` directory.
- All third-party icons must be credited properly in `app/frontend/apps/desktop/initializer/3RD-PARTY-ICONS.md`.

## Rules for `mobile` Icon Set

- All icons must have size of `width="24"` and `height="24"`, any further resizing can happen only inside `CommonIcon`
  component. Please make sure that `viewBox` is set to `0 0 24 24`.
- All icons must be put into `app/frontend/apps/mobile/initializer/assets/` directory.
- All third-party icons must be credited properly in `app/frontend/apps/mobile/initializer/3RD-PARTY-ICONS.md`.

## Using Icons in the "shared" Context

All icon names used in shared context should refer to an alias defined in `mobileIconsAliasesMap.ts` and/or
`desktopIconsAliasesMap.ts`. Alias refers to the icon name from `assets` folder depending on the app. Alias name is
always preferred when displaying an icon even if icon with that name already exists.
