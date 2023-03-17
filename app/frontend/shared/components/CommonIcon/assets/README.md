# Rules for Icons in the New Stack

* All icon names must be unique, however you are free to put them in another set (subdirectory).
* All icons must have size of `width="24"` and `height="24"`, any further resizing can happen only inside `CommonIcon` component. Please make sure that `viewBox` is set to `0 0 24 24`.
* All icons must use fill for their elements, but not stroke. In case of outlined design, please expand the stroke into a path first.
* All icons must be in provided in a monochrome design and any fill values must be removed from the SVG definition. An implicit `fill: currentColor` rule is applied by `CommonIcon` component.
* Attributes `fill-rule` and `clip-rule` can be applied only if the design requires it (no implicit attributes are allowed).
