// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const FOCUSABLE_QUERY =
  'button, a[href]:not([href=""]), input, select, textarea, [tabindex]:not([tabindex="-1"])'

export const isElementVisible = (el: HTMLElement) => {
  // In Vitest, a visibility check is unreliable due to the used JSDOM test environment.
  //   Therefore, we always assume the element is visible.
  if (import.meta.env.VITEST) return true
  return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length) // from jQuery
}

export const getFocusableElements = (container?: Maybe<HTMLElement>) => {
  return Array.from<HTMLElement>(
    container?.querySelectorAll(FOCUSABLE_QUERY) || [],
  ).filter(
    (el) =>
      isElementVisible(el) &&
      !el.hasAttribute('disabled') &&
      el.getAttribute('aria-disabled') !== 'true',
  )
}

export const getFirstFocusableElement = (container?: Maybe<HTMLElement>) => {
  return getFocusableElements(container)[0]
}
