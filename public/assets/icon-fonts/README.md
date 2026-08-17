# Icon Fonts & SVG Assets

Icon libraries that can be selected for a knowledge base (`KnowledgeBase#iconset`).
Each library is present in two forms:

| File         | Used by                                                                        |
| ------------ | ------------------------------------------------------------------------------ |
| `<set>.woff` | Legacy CoffeeScript app and the public knowledge base pages, via `@font-face`  |
| `<set>.svg`  | Desktop view (Vue), via `<use href="…/<set>.svg#icon-<unicode>">`              |
| `<set>.json` | Icon pickers - icon names, ids and search keywords                             |

A single icon is identified by its hex codepoint (unicode), which is what
`KnowledgeBase::Category#category_icon` stores (e.g. `f115`).

## Third Party Libraries

| Library                 | License                  | Copyright                                               |
|-------------------------|--------------------------|---------------------------------------------------------|
| anticon 2.10            | MIT                      | © Copyright 2015-present Ant UED                        |
| FontAwesome 4.7.        | SIL OFL 1.1 (font files) | © Copyright Dave Gandy 2016. All rights reserved.       |
| Ionicons 2.0.1          | MIT                      | © Created by Adam Bradley with FontForge 2.0            |
| material 2.2.0          | SIL OFL 1.1 (font files) | © Copyright (C) 2016 by original authors @ fontello.com |
| simple-line-icons 0.0.1 | MIT                      | Designed by Jamal Jama, Ahmad Firoz                     |
