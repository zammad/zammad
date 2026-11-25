// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

const SEARCH_FIELD_FOCUS = 'focusSearchField'

/**
 * Router state for a navigation to the search view that asks for its search field to get the
 *   focus: from the quick search, where the search is being typed. Any other way to the view, e.g.
 *   switching taskbar tabs, is to look at the results and keeps the keys with the page.
 */
export const searchFieldFocusState = { [SEARCH_FIELD_FOCUS]: true }

/**
 * Whether the navigation that shows the search view asks for the focus, once: the router keeps
 *   the state in the browser's history entry, which going back or forward later returns to, and
 *   a later navigation copies it over.
 */
export const consumeSearchFieldFocusRequest = () => {
  if (!window.history.state?.[SEARCH_FIELD_FOCUS]) return false

  window.history.replaceState({ ...window.history.state, [SEARCH_FIELD_FOCUS]: undefined }, '')

  return true
}
