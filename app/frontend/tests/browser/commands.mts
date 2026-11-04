// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'

import { defineBrowserCommand } from '@vitest/browser-playwright'

export interface RouteResponse {
  // Relative to `app/frontend/tests/browser/fixtures`.
  fixture: string
  contentType?: string
  status?: number
}

export const routeRequestCommand = defineBrowserCommand<[url: string, response: RouteResponse]>(
  async ({ page, project }, url, { fixture, contentType, status = 200 }) => {
    const body = await readFile(resolve(project.config.root, 'tests/browser/fixtures', fixture))

    await page.route(url, (route) => route.fulfill({ status, contentType, body }))
  },
)

export const unrouteRequestCommand = defineBrowserCommand<[url: string]>(({ page }, url) =>
  page.unroute(url),
)
