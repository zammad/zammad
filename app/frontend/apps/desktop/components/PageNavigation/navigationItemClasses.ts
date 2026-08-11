// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// An entry of the expanded navigation is a link when it opens a page and a
//   button when it opens a group menu, so the shared row styling lives here
//   instead of being repeated per element type.
export const navigationItemClass =
  'flex grow items-center gap-2 rounded-lg px-2 py-3 text-neutral-400 focus-visible-app-default hover:bg-blue-900 hover:text-white!'

// Current page, or an open group menu.
export const navigationItemHighlightClass = 'bg-blue-800! text-white!'
