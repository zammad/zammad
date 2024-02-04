// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface FocusableOptions {
  ignoreTabindex?: boolean
}

const FOCUSABLE_QUERY =
  'button, a[href]:not([href=""]), input, select, textarea, [tabindex]:not([tabindex="-1"])'

export const isElementVisible = (el: HTMLElement) => {
  // In Vitest, a visibility check is unreliable due to the used JSDOM test environment.
  //   Therefore, we always assume the element is visible.
  if (import.meta.env.VITEST) return true
  return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length) // from jQuery
}

const isNegativeTabIndex = (el: HTMLElement) => {
  const tabIndex = el.getAttribute('tabindex')
  return tabIndex && parseInt(tabIndex, 10) < 0
}

export const getFocusableElements = (
  container?: Maybe<HTMLElement>,
  options: FocusableOptions = {},
) => {
  return Array.from<HTMLElement>(
    container?.querySelectorAll(FOCUSABLE_QUERY) || [],
  ).filter(
    (el) =>
      isElementVisible(el) &&
      (options.ignoreTabindex || !isNegativeTabIndex(el)) &&
      !el.hasAttribute('disabled') &&
      el.getAttribute('aria-disabled') !== 'true',
  )
}

export const getFirstFocusableElement = (container?: Maybe<HTMLElement>) => {
  return getFocusableElements(container)[0]
}

export const getPreviousFocusableElement = (
  currentElement?: Maybe<HTMLElement>,
) => {
  if (!currentElement) return null

  const focusableElements = getFocusableElements(document.body)

  return focusableElements[focusableElements.indexOf(currentElement) - 1]
}
