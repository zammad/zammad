// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The page cache of a section, holding exactly the page on screen.
//
// Why cache at all: a section is a permanent item, so LayoutPage keeps the section itself when the
//   tab is switched - but not its page, which the router unmounts as soon as the URL leaves the
//   section. Without this, coming back rebuilds the page that was open.
//
// Why `include` rather than `max="1"`: a cap of one makes every eviction target the page on screen,
//   and that is the one eviction KeepAlive gets wrong - it deactivates the page instead of
//   unmounting it and drops it from the cache in the same breath, leaving an instance nothing can
//   reactivate and nothing will destroy (measured, in both sections that had it). Pruning by
//   `include` runs from KeepAlive's own post-flush watcher instead, once the outgoing page is
//   already deactivated, which is the eviction it gets right.
//
// Used in the section's own template:
//   <RouterView #default="{ Component }">
//     <KeepAlive :include="cacheOnlyCurrentPage(Component)">
//       <component :is="Component" />
//     </KeepAlive>
//   </RouterView>
export const useSectionPageCache = () => {
  // The last name is kept when the slot has none to offer: that is the URL leaving the section, and
  //   holding on to its page is the whole point. A plain variable rather than a ref - it is written
  //   and read within the same render, and nothing else depends on it.
  let cacheablePage: string[] = []

  return (component: unknown) => {
    const type = (component as { type?: { name?: string; __name?: string } } | null)?.type
    const name = type?.name ?? type?.__name

    if (name) cacheablePage = [name]

    return cacheablePage
  }
}
