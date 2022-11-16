// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const FOCUSABLE_QUERY =
  'button, a[href]:not([href=""]), input, select, textarea, [tabindex]:not([tabindex="-1"])'

export const getFocusableElements = (container?: Maybe<HTMLElement>) => {
  return Array.from<HTMLElement>(
    container?.querySelectorAll(FOCUSABLE_QUERY) || [],
  ).filter(
    (el) =>
      !el.hasAttribute('disabled') &&
      el.getAttribute('aria-disabled') !== 'true',
  )
}

export const getFirstFocusableElement = (container?: Maybe<HTMLElement>) => {
  return getFocusableElements(container)[0]
}
