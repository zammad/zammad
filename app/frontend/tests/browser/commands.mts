// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'

import { defineBrowserCommand } from '@vitest/browser-playwright'

export type RouteResponse =
  | {
      // Relative to `app/frontend/tests/browser/fixtures`.
      fixture: string
      contentType?: string
      status?: number
    }
  // Fails like a dropped connection, `fetch()` rejects with a `TypeError`.
  | { networkError: true }

export const routeRequestCommand = defineBrowserCommand<[url: string, response: RouteResponse]>(
  async ({ page, project }, url, response) => {
    if ('networkError' in response) {
      await page.route(url, (route) => route.abort('failed'))
      return
    }

    const { fixture, contentType, status = 200 } = response
    const body = await readFile(resolve(project.config.root, 'tests/browser/fixtures', fixture))

    await page.route(url, (route) => route.fulfill({ status, contentType, body }))
  },
)

export const unrouteRequestCommand = defineBrowserCommand<[url: string]>(({ page }, url) =>
  page.unroute(url),
)

// The mouse stays where the previous test, also of another file, left it, and its hover styles
//   end up in later screenshots. The bottom right corner is outside the mounted components.
export const moveMouseAwayCommand = defineBrowserCommand(async ({ page }) => {
  const { width, height } = page.viewportSize()!

  await page.mouse.move(width - 1, height - 1)
})
