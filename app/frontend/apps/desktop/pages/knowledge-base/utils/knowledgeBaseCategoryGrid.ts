// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The responsive columns of a knowledge base category grid, shared by the browse listing, the
//   category results of a search and the skeletons of both - so a category sits in the same
//   rhythm whether it was found by browsing or by searching.
//
// A class list rather than a component: the browse listing's `<ol>` is the element
//   @formkit/drag-and-drop is attached to (the `dnd-parent` template ref) and carries the
//   keyboard handlers that arrange it, so moving that element into a shared component would hand
//   the ref a component instance instead of the list. Nothing is rearranged in a result list, so
//   the search grid needs none of that - only the same columns.
export const CATEGORY_GRID_CLASSES =
  'grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4'

// Which placeholder tiles a grid of `count` columns hides, so a skeleton never shows more tiles
//   than the viewport has columns. Mirrors the columns above.
export const CATEGORY_GRID_REVEAL = {
  2: 'hidden sm:flex',
  3: 'hidden lg:flex',
  4: 'hidden 2xl:flex',
} as const
