// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeAll, beforeEach } from 'vitest'
import { commands, page } from 'vitest/browser'

import { registerBrowserApp } from './app.ts'

import '#shared/components/CommonIcon/injectIcons.ts'
import '../../../../public/assets/frontend/fonts.css'

globalThis.__ = (source) => source

// The app a spec belongs to, by its path: the desktop app under `apps/desktop/`, the mobile app for
//   the mobile app and the shared components. Its modules are loaded only now, once the spec has
//   registered its mocks: a module imported here already would stay the original for them.
// oxlint-disable-next-line no-empty-pattern -- Vitest reads fixtures from a hook's first argument and passes the file second.
beforeAll(async ({}, file) => {
  const isDesktop = 'filepath' in file && file.filepath.includes('/apps/desktop/')

  registerBrowserApp(
    isDesktop
      ? (await import('./apps/desktop.ts')).desktopApp
      : (await import('./apps/mobile.ts')).mobileApp,
  )

  // A small laptop, above the small-screen breakpoint of the desktop view.
  if (isDesktop) await page.viewport(1280, 800)

  // A face is only fetched once some text needs it, possibly after a screenshot was taken.
  await Promise.all([...document.fonts].map((face) => face.load()))
})

beforeEach(() => commands.moveMouseAway())
