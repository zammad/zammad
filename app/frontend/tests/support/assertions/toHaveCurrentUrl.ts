// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ExtendedRenderResult } from '../components/renderComponent.ts'

// eslint-disable-next-line sonarjs/cognitive-complexity
export default function toHaveCurrentUrl(
  this: any,
  view: ExtendedRenderResult,
  url: string,
) {
  if (typeof url !== 'string') {
    throw new Error(`"toHaveCurrentUrl" expects a string, got ${typeof url}`)
  }
  if (!view.router) {
    throw new Error(
      `The value passed to "expect" is not a result of "visitView" method because it doesn't provide a "router" property.`,
    )
  }

  const pass = view.router.currentRoute.value.path === url

  return {
    pass,
    message: () =>
      `expected current route${
        this.isNot ? ' not' : ''
      } to be ${url}, but got ${view.router.currentRoute.value.path}`,
  }
}
