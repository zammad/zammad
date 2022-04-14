// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getElementError } from '@testing-library/vue'

const getElementParent = (el: HTMLElement): HTMLElement => {
  if (el.parentElement) return getElementParent(el.parentElement)
  return el
}

export const getLinkFromElement = (
  container: HTMLElement,
  element: Element,
): HTMLAnchorElement => {
  const link = element.closest('a') as HTMLAnchorElement | null

  if (!link) {
    throw getElementError(
      'Recieved element is not wrapped inside a link',
      container,
    )
  }

  if (!container.contains(link)) {
    const latestParent = getElementParent(container)

    throw getElementError(
      'Link is outside of a component wrapper',
      latestParent,
    )
  }

  return link
}

export default function buildLinksQueries(container: HTMLElement) {
  return {
    getLinkFromElement: getLinkFromElement.bind(null, container),
  }
}
